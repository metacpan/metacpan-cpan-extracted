/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#if HAVE_PERL_VERSION(5,32,0)
#  define HAVE_OP_ISA
#endif

#ifndef block_start
#  define block_start(flags)  Perl_block_start(aTHX_ flags)
#endif

#ifndef block_end
#  define block_end(floor, op)  Perl_block_end(aTHX_ floor, op)
#endif

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
  OPCODE matchtype = args[1].i;
  int ncases = args[2].i;
  bool with_default = args[3 + 2*ncases].i;

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
    OP *caseop = args[idx].op;
    OP *block  = op_scope(args[idx+1].op);

    OP *testop = NULL;

    switch(matchtype) {
#ifdef HAVE_OP_ISA
      case OP_ISA:
        /* bareword class names are permitted */
        if(caseop->op_type == OP_CONST && caseop->op_private & OPpCONST_BARE)
          caseop->op_private &= ~(OPpCONST_BARE|OPpCONST_STRICT);
        /* FALLTHROUGH */
#endif
      case OP_SEQ:
      case OP_EQ:
        caseop = op_contextualize(caseop, G_SCALAR);
        /* TODO:
         * if(caseop->op_type != OP_CONST) then turn sections of cases into DISPATCHOP
         */

        testop = newBINOP(matchtype, 0,
          newPADSVOP(OP_PADSV, 0, padix), caseop);
        break;

      case OP_MATCH:
        if(caseop->op_type != OP_MATCH || cPMOPx(caseop)->op_first)
          croak("Expected a regexp match");
        testop = caseop;
#if HAVE_PERL_VERSION(5,22,0)
        testop->op_targ = padix;
#else
        cPMOPx(testop)->op_first = newPADSVOP(OP_PADSV, 0, padix);
        testop->op_flags |= OPf_KIDS|OPf_STACKED;
#endif
        break;
    }

    assert(testop);

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
      XPK_TAGGEDCHOICE(   /* TODO: relop ? */
        XPK_STRING("eq"), XPK_TAG(OP_SEQ),
        XPK_STRING("=="), XPK_TAG(OP_EQ),
        XPK_STRING("=~"), XPK_TAG(OP_MATCH),
#ifdef HAVE_OP_ISA
        XPK_STRING("isa"), XPK_TAG(OP_ISA),
#endif
        XPK_FAILURE("Expected a comparison operator")
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
