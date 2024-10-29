/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

static bool permit_begin(pTHX_ void *hookdata)
{
  /* Evil hackery. We don't want to take over perl's BEGIN { ... } syntax, so
   * lets peek to see if the next token is a '{'
   */
  lex_read_space(0);
  if(lex_peek_unichar(0) == '{')
    return false;

  return true;
}

static int build_begin(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
  assert(nargs >= 1);
  OP *expr = args[0]->op;

  OP *start = LINKLIST(expr);
  expr->op_next = NULL;

  /* We CANNOT use an ENTER/LEAVE pair in this function while invoking the
   * optree. If we do that, then any `my ...` declarations in the expression
   * will call saveclearsv() inside that scope, which will then get cleared
   * when we LEAVE, and subsequent code will see an unavailable undef in those
   * lexical variables.
   *
   * It might be nice to find a better solution for that, so that we can use
   * the SAVE* macros here as normal. But currently it appears to work without
   * that.
   */

  //ENTER;
  //SAVEVPTR(PL_op);
  PL_op = start;

  //SAVESPTR(PL_curpad);
  PL_curpad = PadARRAY(PL_comppad);

  U32 mark = PL_stack_sp - PL_stack_base;

  CALLRUNOPS(aTHX);

  U32 height = PL_stack_sp - PL_stack_base - mark;
  if(height) {
    dSP;
    /* TODO: Think about list-context */
    SV *ret = POPs;

    if(height > 1)
      warn("TODO: need to pop %d more items from the staack", height - 1);

    *out = newSVOP(OP_CONST, 0, SvREFCNT_inc(ret));
    /* Set this flag so it doesn't warn about being useless in void context */
    (*out)->op_private |= OPpCONST_SHORTCIRCUIT;
    PUTBACK;
  }
  else
    *out = newOP(OP_NULL, 0);

  //LEAVE;

  return KEYWORD_PLUGIN_EXPR;
}

static const struct XSParseKeywordHooks hooks_begin = {
  .flags = XPK_FLAG_EXPR,

  .permit = &permit_begin,

  .pieces = (const struct XSParseKeywordPieceType[]){
    XPK_TERMEXPR,
    0,
  },
  .build  = &build_begin,
};

MODULE = Syntax::Keyword::PhaserExpression    PACKAGE = Syntax::Keyword::PhaserExpression

BOOT:
  boot_xs_parse_keyword(0.13);

  register_xs_parse_keyword("BEGIN", &hooks_begin, NULL);
