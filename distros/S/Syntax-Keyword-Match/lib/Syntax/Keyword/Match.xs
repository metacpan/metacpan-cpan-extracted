/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

static OP *newPADSVOP(I32 type, I32 flags, PADOFFSET padix)
{
  OP *op = newOP(type, flags);
  op->op_targ = padix;
  return op;
}

static int build_match(pTHX_ OP **out, XSParseKeywordPiece *args, size_t nargs, void *hookdata)
{
  /* args:
   *   [0]: topic expression
   *   [1]: match type
   *   [2]: count of cases
   *   [3,4]: first case
   *   [4,5]: second case ...
   *   [3+2*ncases]: true if default exists
   *   [LAST]: default case if present
   */
  OP *topic = args[0].op;
  OPCODE matchtype;
  int ncases = args[2].i;
  bool with_default = args[3 + 2*ncases].i;

  switch(args[1].i) {
    case 0: matchtype = OP_SEQ; break;
    case 1: matchtype = OP_EQ;  break;
    /* TODO: consider isa, =~, equ, === */
  }

  I32 floor_ix = block_start(0);
  /* The name is totally meaningless and never used, but if we don't set a
   * name and instead use pad_alloc(SVs_PADTMP) then the peephole optimiser
   * for aassign will crash
   */
  PADOFFSET padix = pad_add_name_pvs("$(Syntax::Keyword::Match/topic)", 0, NULL, NULL);

  topic = op_contextualize(topic, G_SCALAR);

  OP *startop = newBINOP(OP_SASSIGN, 0,
    topic, newPADSVOP(OP_PADSV, OPf_MOD, padix));

  OP *o = NULL;
  if(with_default)
    o = op_scope(args[3 + 2*ncases + 1].op);

  int idx;
  for (idx = 1 + 2*ncases; idx > 2; idx -= 2) {
    /* TODO: forbid the , operator in the case label */
    OP *caseop = op_contextualize(args[idx].op, G_SCALAR);
    OP *block  = op_scope(args[idx+1].op);

    if(caseop->op_type != OP_CONST)
      croak("case expressions must be constant");

    OP *testop = newBINOP(matchtype, 0,
      newPADSVOP(OP_PADSV, 0, padix), caseop);

    if(o)
      o = newCONDOP(0, testop, block, o);
    else
      o = newLOGOP(OP_AND, 0, testop, block);
  }

  *out = block_end(floor_ix, newLISTOP(OP_LINESEQ, 0, startop, o));

  return KEYWORD_PLUGIN_STMT;
}

static const struct XSParseKeywordHooks hooks_match = {
  .permit_hintkey = "Syntax::Keyword::Match/match",

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_PARENSCOPE( /* ( EXPR : OP ) */
      XPK_TERMEXPR,
      XPK_COLON,
      XPK_CHOICE(   /* TODO: relop ? */
        XPK_STRING("eq"),
        XPK_STRING("=="),
        XPK_FAILURE("Expected an equality operator")
      )
    ),
    XPK_BRACESCOPE( /* { cases... } */
      XPK_REPEATED(     /* case (EXPR) {BLOCK} */
        XPK_STRING("case"),
        XPK_PARENSCOPE( XPK_TERMEXPR ),
        XPK_BLOCK
      ),
      XPK_OPTIONAL( /* default { ... } */
        XPK_STRING("default"),
        XPK_BLOCK
      )
    ),
    0,
  },
  .build = &build_match,
};

MODULE = Syntax::Keyword::Match    PACKAGE = Syntax::Keyword::Match

BOOT:
  boot_xs_parse_keyword(0);

  register_xs_parse_keyword("match", &hooks_match, NULL);
