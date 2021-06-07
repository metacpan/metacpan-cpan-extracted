/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

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

#include "dispatchop.h"

#define newPADSVOP(type, flags, padix)  MY_newPADSVOP(aTHX_ type, flags, padix)
static OP *MY_newPADSVOP(pTHX_ I32 type, I32 flags, PADOFFSET padix)
{
  OP *op = newOP(type, flags);
  op->op_targ = padix;
  return op;
}

static OP *pp_dispatch_numeq(pTHX)
{
  dDISPATCH;
  dTARGET;
  int idx;

  bool has_magic = SvAMAGIC(TARG);

  for(idx = 0; idx < n_cases; idx++) {
    SV *val = values[idx];

    SV *ret;
    if(has_magic &&
        (ret = amagic_call(TARG, val, eq_amg, 0))) {
      if(SvTRUE(ret))
        return dispatch[idx];
    }
    /* stolen from core's pp_hot.c / pp_eq() */
    else if((SvIOK_notUV(TARG) && SvIOK_notUV(val)) ?
        SvIVX(TARG) == SvIVX(val) : (Perl_do_ncmp(aTHX_ TARG, val) == 0))
      return dispatch[idx];
  }

  return cDISPATCHOP->op_other;
}

static OP *pp_dispatch_streq(pTHX)
{
  dDISPATCH;
  dTARGET;
  int idx;

  bool has_magic = SvAMAGIC(TARG);

  for(idx = 0; idx < n_cases; idx++) {
    SV *val = values[idx];

    SV *ret;
    if(has_magic &&
        (ret = amagic_call(TARG, val, seq_amg, 0))) {
      if(SvTRUE(ret))
        return dispatch[idx];
    }
    else if(sv_eq(TARG, val))
      return dispatch[idx];
  }

  return cDISPATCHOP->op_other;
}

#ifdef HAVE_OP_ISA
static OP *pp_dispatch_isa(pTHX)
{
  dDISPATCH;
  dTARGET;
  int idx;

  for(idx = 0; idx < n_cases; idx++)
    if(sv_isa_sv(TARG, values[idx]))
      return dispatch[idx];

  return cDISPATCHOP->op_other;
}
#endif

static OP *build_cases(pTHX_ OPCODE matchtype, PADOFFSET padix, size_t n_cases, XSParseKeywordPiece *args[], OP *elseop)
{
  assert(n_cases);

  if(n_cases == 1) {
    OP *caseop = args[0]->op;
    OP *block  = op_scope(args[1]->op);
    OP *testop = NULL;

    switch(matchtype) {
#ifdef HAVE_OP_ISA
      case OP_ISA:
#endif
      case OP_SEQ:
      case OP_EQ:
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

    if(elseop)
      return newCONDOP(0, testop, block, elseop);
    else
      return newLOGOP(OP_AND, 0, testop, block);
  }

  int idx;
  for(idx = 0; idx < n_cases; idx++)
    assert(args[idx*2]->op->op_type == OP_CONST);
  assert(matchtype != OP_MATCH);

  ENTER;

  SV *valuessv   = newSV(n_cases * sizeof(SV *));
  SV *dispatchsv = newSV(n_cases * sizeof(OP *));
  SAVEFREESV(valuessv);
  SAVEFREESV(dispatchsv);

  SV **values   = (SV **)SvPVX(valuessv);
  OP **dispatch = (OP **)SvPVX(dispatchsv);

  DISPATCHOP *o = alloc_DISPATCHOP();
  o->op_type = OP_CUSTOM;
  o->op_targ = padix;

  switch(matchtype) {
#ifdef HAVE_OP_ISA
    case OP_ISA: o->op_ppaddr = &pp_dispatch_isa; break;
#endif
    case OP_SEQ: o->op_ppaddr = &pp_dispatch_streq; break;
    case OP_EQ:  o->op_ppaddr = &pp_dispatch_numeq; break;
  }

  o->op_first = NULL;

  o->n_cases = n_cases;
  o->values = values;
  o->dispatch = dispatch;

  OP *retop = newUNOP(OP_NULL, 0, (OP *)o);

  for(idx = 0; idx < n_cases; idx++) {
    OP *caseop = args[idx*2]->op;
    OP *block  = op_scope(args[idx*2+1]->op);

    values[idx] = SvREFCNT_inc(cSVOPx(caseop)->op_sv);
    op_free(caseop);

    dispatch[idx] = LINKLIST(block);
    block->op_next = retop;

    /* TODO: link chain of siblings */
  }

  if(elseop) {
    o->op_other = LINKLIST(elseop);
    elseop->op_next = retop;
    /* TODO: sibling linkage */
  }
  else {
    o->op_other = retop;
  }

  /* Steal the SV buffers */
  SvPVX(valuessv) = NULL; SvLEN(valuessv) = 0;
  SvPVX(dispatchsv) = NULL; SvLEN(dispatchsv) = 0;

  LEAVE;

  return retop;
}

static int build_match(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
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
  OP *topic = args[0]->op;
  OPCODE matchtype = args[1]->i;
  int ncases = args[2]->i;
  bool with_default = args[3 + 2*ncases]->i;

  bool use_dispatch = hv_fetchs(GvHV(PL_hintgv), "Syntax::Keyword::Match/experimental(dispatch)", 0);

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
    o = op_scope(args[3 + 2*ncases + 1]->op);

  int n_consts = 0;
  int idx;
  for (idx = 1 + 2*ncases; idx > 2; idx -= 2) {
    /* TODO: forbid the , operator in the case label */
    OP *caseop = args[idx]->op;

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
        args[idx]->op = op_contextualize(caseop, G_SCALAR);
        if(use_dispatch && caseop->op_type == OP_CONST) {
          n_consts++;
          continue;
        }
        if(n_consts) {
          o = build_cases(aTHX_ matchtype, padix, n_consts, args + idx + 2, o);
          n_consts = 0;
        }
        break;
    }

    o = build_cases(aTHX_ matchtype, padix, 1, args + idx, o);
  }

  if(n_consts)
    o = build_cases(aTHX_ matchtype, padix, n_consts, args + idx + 2, o);

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
  boot_xs_parse_keyword(0.04);

  register_xs_parse_keyword("match", &hooks_match, NULL);
