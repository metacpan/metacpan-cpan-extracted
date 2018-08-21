/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2018 -- leonerd@leonerd.org.uk
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef OP_CHECK_MUTEX_LOCK /* < 5.15.8 */
#define OP_CHECK_MUTEX_LOCK ((void)0)
#define OP_CHECK_MUTEX_UNLOCK ((void)0)
#endif

#define lex_consume(s)  MY_lex_consume(aTHX_ s)
static int MY_lex_consume(pTHX_ char *s)
{
  /* I want strprefix() */
  size_t i;
  for(i = 0; s[i]; i++) {
    if(s[i] != PL_parser->bufptr[i])
      return 0;
  }

  lex_read_to(PL_parser->bufptr + i);
  return i;
}

static XOP xop_saveitem;

static OP *pp_saveitem(pTHX)
{
  dSP;
  save_freesv(SvREFCNT_inc(TOPs));
  save_item(TOPs);
  return cUNOP->op_next;
}

#define newSAVEITEMOP(expr)  MY_newSAVEITEMOP(aTHX_ expr)
static OP *MY_newSAVEITEMOP(pTHX_ OP *expr)
{
  OP *ret = newUNOP(OP_CUSTOM, 0, expr);
  cUNOPx(ret)->op_ppaddr = &pp_saveitem;
  return ret;
}

static int dynamically_keyword(pTHX_ OP **op)
{
  OP *aop = NULL;
  OP *lvalop = NULL, *rvalop = NULL;

  lex_read_space(0);

  aop = parse_termexpr(0);

  if(aop->op_type != OP_SASSIGN)
    croak("Expected scalar assignment for 'dynamically'");

  /* Steal the lvalue / rvalue optrees from the op and destroy it */
  rvalop = cBINOPx(aop)->op_first; cBINOPx(aop)->op_first = NULL;
  lvalop = cBINOPx(aop)->op_last; cBINOPx(aop)->op_last = NULL;
  op_free(aop);

  *op = newBINOP(OP_SASSIGN, 0,
    rvalop,
    newSAVEITEMOP(lvalop));

  return KEYWORD_PLUGIN_EXPR;
}

static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

static int my_keyword_plugin(pTHX_ char *kw, STRLEN kwlen, OP **op)
{
  HV *hints;
  if(PL_parser && PL_parser->error_count)
    return (*next_keyword_plugin)(aTHX_ kw, kwlen, op);

  if(!(hints = GvHV(PL_hintgv)))
    return (*next_keyword_plugin)(aTHX_ kw, kwlen, op);

  if(kwlen == 11 && strEQ(kw, "dynamically") &&
      hv_fetchs(hints, "Syntax::Keyword::Dynamically/dynamically", 0))
    return dynamically_keyword(aTHX_ op);

  return (*next_keyword_plugin)(aTHX_ kw, kwlen, op);
}

MODULE = Syntax::Keyword::Dynamically    PACKAGE = Syntax::Keyword::Dynamically

BOOT:
  /* BOOT can potentially race with other threads (RT123547) */

  /* Perl doesn't really provide us a nice mutex for doing this so this is the
   * best we can find. See also
   *   https://rt.perl.org/Public/Bug/Display.html?id=132413
   */
  OP_CHECK_MUTEX_LOCK;
  if(!next_keyword_plugin) {
    next_keyword_plugin = PL_keyword_plugin;
    PL_keyword_plugin = &my_keyword_plugin;

    XopENTRY_set(&xop_saveitem, xop_name, "saveitem");
    XopENTRY_set(&xop_saveitem, xop_desc,
      "saves the current value of the SV to the savestack");
    XopENTRY_set(&xop_saveitem, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ &pp_saveitem, &xop_saveitem);
  }
  OP_CHECK_MUTEX_UNLOCK;
