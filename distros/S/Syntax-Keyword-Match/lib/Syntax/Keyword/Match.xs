/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"
#include "XSParseInfix.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#include "hax/perl-backcompat.c.inc"

#if HAVE_PERL_VERSION(5,32,0)
#  define HAVE_OP_ISA
#endif

#if HAVE_PERL_VERSION(5,18,0)
#  define HAVE_BOOL_SvIV_please_nomg
#endif

#if HAVE_PERL_VERSION(5,35,9)
#  define HAVE_SV_NUMEQ_FLAGS
#endif

#include "dispatchop.h"

#ifndef HAVE_SV_NUMEQ_FLAGS
/* We'd like to call Perl_do_ncmp, except that isn't an exported API function
 * Here's a near-copy of it for num-equality testing purposes */
#define do_numeq(left, right)  S_do_numeq(aTHX_ left, right)
static bool S_do_numeq(pTHX_ SV *left, SV *right)
{
#ifndef HAVE_BOOL_SvIV_please_nomg
  /* Before perl 5.18, SvIV_please_nomg() was void-returning */
  SvIV_please_nomg(left);
  SvIV_please_nomg(right);
#endif

  if(
#ifdef HAVE_BOOL_SvIV_please_nomg
    SvIV_please_nomg(right) && SvIV_please_nomg(left)
#else
    SvIOK(left) && SvIOK(right)
#endif
  ) {
    /* Compare as integers */
    switch((SvUOK(left) ? 1 : 0) | (SvUOK(right) ? 2 : 0)) {
      case 0: /* IV == IV */
        return SvIVX(left) == SvIVX(right);

      case 1: /* UV == IV */
      {
        const IV riv = SvUVX(right);
        if(riv < 0)
          return 0;
        return (SvUVX(left) == riv);
      }

      case 2: /* IV == UV */
      {
        const IV liv = SvUVX(left);
        if(liv < 0)
          return 0;
        return (liv == SvUVX(right));
      }

      case 3: /* UV == UV */
        return SvUVX(left) == SvUVX(right);
    }
  }
  else {
    /* Compare NVs */
    NV const rnv = SvNV_nomg(right);
    NV const lnv = SvNV_nomg(left);

    return lnv == rnv;
  }
}
#endif

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
#ifdef HAVE_SV_NUMEQ_FLAGS
    else if(sv_numeq_flags(TARG, val, SV_SKIP_OVERLOAD))
#else
    /* stolen from core's pp_hot.c / pp_eq() */
    else if((SvIOK_notUV(TARG) && SvIOK_notUV(val)) ?
        SvIVX(TARG) == SvIVX(val) : (do_numeq(TARG, val)))
#endif
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

struct MatchCaseBlock {
  int n_cases;
  struct MatchCase {
    bool is_if;
    OP *expr;
  } *cases;

  OP *op;
};

static OP *build_cases_nondispatch(pTHX_ XSParseInfixInfo *matchinfo, PADOFFSET padix, struct MatchCaseBlock *block, OP *elseop)
{
  size_t n_cases = block->n_cases;

  assert(n_cases);

  OP *testop = NULL;

  U32 i;
  for(i = 0; i < n_cases; i++) {
    bool is_if = block->cases[i].is_if;
    OP *caseop = block->cases[i].expr;

    OP *thistestop;

    if(is_if)
      thistestop = caseop;
    else switch(matchinfo->opcode) {
#ifdef HAVE_OP_ISA
      case OP_ISA:
#endif
      case OP_SEQ:
      case OP_EQ:
        thistestop = newBINOP(matchinfo->opcode, 0,
          newPADSVOP(OP_PADSV, 0, padix), caseop);
        break;

      case OP_MATCH:
        if(caseop->op_type != OP_MATCH || cPMOPx(caseop)->op_first)
          croak("Expected a regexp match");
        thistestop = caseop;
#if HAVE_PERL_VERSION(5,22,0)
        thistestop->op_targ = padix;
#else
        cPMOPx(thistestop)->op_first = newPADSVOP(OP_PADSV, 0, padix);
        thistestop->op_flags |= OPf_KIDS|OPf_STACKED;
#endif
        break;
      case OP_CUSTOM:
        thistestop = xs_parse_infix_new_op(matchinfo, 0,
          newPADSVOP(OP_PADSV, 0, padix), caseop);
        break;
    }

    if(testop)
      testop = newLOGOP(OP_OR, 0, testop, thistestop);
    else
      testop = thistestop;
  }

  assert(testop);

  if(elseop)
    return newCONDOP(0, testop, block->op, elseop);
  else
    return newLOGOP(OP_AND, 0, testop, block->op);
}

static OP *build_cases_dispatch(pTHX_ OPCODE matchtype, PADOFFSET padix, size_t n_cases, struct MatchCaseBlock *blocks, OP *elseop)
{
  assert(n_cases);
  assert(matchtype != OP_MATCH);

  U32 blocki;

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

  U32 idx = 0;
  blocki = 0;
  while(n_cases) {
    struct MatchCaseBlock *block = &blocks[blocki];

    U32 this_n_cases = block->n_cases;

    OP *blockop = block->op;
    OP *blockstart = LINKLIST(blockop);
    blockop->op_next = retop;

    n_cases -= this_n_cases;

    for(U32 casei = 0; casei < this_n_cases; casei++) {
      bool is_if = block->cases[casei].is_if;
      OP *caseop = block->cases[casei].expr;

      if(is_if)
        croak("TODO: case if dispatch");

      assert(caseop->op_type == OP_CONST);
      values[idx] = SvREFCNT_inc(cSVOPx(caseop)->op_sv);
      op_free(caseop);

      dispatch[idx] = blockstart;

      idx++;
    }

    /* TODO: link chain of siblings */

    blocki++;
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
   *   [2]: count of blocks
   *     [3]: count of case exprs = $N
   *     [4,5...]: $N * [if, case expr]s
   *     []: block
   *   [LAST]: default case if present
   */
  U32 argi = 0;

  OP *topic = args[argi++]->op;
  XSParseInfixInfo *matchinfo = args[argi++]->infix;
  int n_blocks = args[argi++]->i;

  /* Extract the raw args into a better data structure we can work with */
  struct MatchCaseBlock *blocks;

  Newx(blocks, n_blocks, struct MatchCaseBlock);
  SAVEFREEPV(blocks);

  int blocki;
  for(blocki = 0; blocki < n_blocks; blocki++) {
    struct MatchCaseBlock *block = &blocks[blocki];

    int n_cases = args[argi++]->i;

    block->n_cases = n_cases;

    Newx(block->cases, n_cases, struct MatchCase);
    SAVEFREEPV(block->cases);

    for(int i = 0; i < n_cases; i++) {
      block->cases[i].is_if = args[argi++]->i;
      block->cases[i].expr  = args[argi++]->op;
    }

    block->op = args[argi++]->op;
  }

  bool has_default = args[argi]->i;
  OP *o = NULL;
  if(has_default)
    o = args[argi + 1]->op;

  bool use_dispatch = hv_fetchs(GvHV(PL_hintgv), "Syntax::Keyword::Match/experimental(dispatch)", 0);

  /* The name is totally meaningless and never used, but if we don't set a
   * name and instead use pad_alloc(SVs_PADTMP) then the peephole optimiser
   * for aassign will crash
   */
  PADOFFSET padix = pad_add_name_pvs("$(Syntax::Keyword::Match/topic)", 0, NULL, NULL);
  intro_my();

  OP *startop = newBINOP(OP_SASSIGN, 0,
    topic, newPADSVOP(OP_PADSV, OPf_MOD|OPf_REF|(OPpLVAL_INTRO << 8), padix));
  PL_hints |= HINT_BLOCK_SCOPE; /* ensures that op_scope() creates a full ENTER+LEAVE pair */

  int n_dispatch = 0;

  blocki = n_blocks-1;

  /* Roll up the blocks backwards, from end to beginning */
  while(blocki >= 0) {
    struct MatchCaseBlock *block = &blocks[blocki--];

    int n_cases = block->n_cases;

    /* perl expects a strict optree, where each block appears exactly once.
     * We can't reüse the block between dispatch and non-dispatch ops, so
     * we'll have to decide which strategy to use here
     */
    bool this_block_dispatch = use_dispatch;

    for(U32 casei = 0; casei < n_cases; casei++) {
      if(block->cases[casei].is_if) {
        this_block_dispatch = false;
        continue;
      }

      /* TODO: forbid the , operator in the case label */
      OP *caseop = block->cases[casei].expr;

      switch(matchinfo->opcode) {
#ifdef HAVE_OP_ISA
        case OP_ISA:
          /* bareword class names are permitted */
          if(caseop->op_type == OP_CONST && caseop->op_private & OPpCONST_BARE)
            caseop->op_private &= ~(OPpCONST_BARE|OPpCONST_STRICT);
          /* FALLTHROUGH */
#endif
        case OP_SEQ:
        case OP_EQ:
          if(use_dispatch && caseop->op_type == OP_CONST)
            continue;

          /* FALLTHROUGH */
        case OP_MATCH:
        case OP_CUSTOM:
          this_block_dispatch = false;
          break;
      }
    }

    if(this_block_dispatch) {
      n_dispatch += n_cases;
      continue;
    }

    if(n_dispatch) {
      o = build_cases_dispatch(aTHX_ matchinfo->opcode, padix,
          n_dispatch, block + 1, o);
      n_dispatch = 0;
    }

    o = build_cases_nondispatch(aTHX_ matchinfo, padix, block, o);
  }

  if(n_dispatch)
    o = build_cases_dispatch(aTHX_ matchinfo->opcode, padix,
        n_dispatch, blocks, o);

  *out = newLISTOP(OP_LINESEQ, 0, startop, o);

  return KEYWORD_PLUGIN_STMT;
}

static const struct XSParseKeywordHooks hooks_match = {
  .flags = XPK_FLAG_BLOCKSCOPE,
  .permit_hintkey = "Syntax::Keyword::Match/match",

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_PARENS(     /* ( EXPR : OP ) */
      XPK_TERMEXPR_SCALARCTX,
      XPK_COLON,
      XPK_INFIX_MATCH_NOSMART
    ),
    XPK_INTRO_MY,
    XPK_BRACES(     /* { blocks... } */
      XPK_REPEATED(     /* case (EXPR) {BLOCK} */
        XPK_COMMALIST(
          XPK_KEYWORD("case"),
          XPK_OPTIONAL( XPK_KEYWORD("if") ),
          XPK_PARENS( XPK_TERMEXPR_SCALARCTX )
        ),
        XPK_BLOCK
      ),
      XPK_OPTIONAL(     /* default { ... } */
        XPK_KEYWORD("default"),
        XPK_BLOCK
      )
    ),
    0,
  },
  .build = &build_match,
};

#ifndef HAVE_OP_ISA
#include "hax/newOP_CUSTOM.c.inc"

/* Can't use sv_isa_sv() because that was only added in 5.32 */
static bool S_sv_isa_sv(pTHX_ SV *sv, SV *namesv)
{
  if(!SvROK(sv) || !SvOBJECT(SvRV(sv)))
    return FALSE;

  /* Also can't use GV_NOUNIVERSAL here because that also only turned up in 5.32 */
  GV *isagv = gv_fetchmeth_pvn(SvSTASH(SvRV(sv)), "isa", 3, -1, 0);
  /* This probably finds UNIVERSAL::isa; if so we can avoid it and just do it
   * directly ourselves by calling sv_derived_from_sv()
   */
  if(isagv && !strEQ(HvNAME(GvSTASH(isagv)), "UNIVERSAL")) {
    dSP;
    CV *isacv = isGV(isagv) ? GvCV(isagv) : MUTABLE_CV(isagv);

    PUTBACK;

    ENTER;
    SAVETMPS;

    EXTEND(SP, 2);
    PUSHMARK(SP);
    PUSHs(sv);
    PUSHs(namesv);
    PUTBACK;

    call_sv((SV *)isacv, G_SCALAR);

    SPAGAIN;
    SV *retsv = POPs;
    bool ret = SvTRUE(retsv);
    PUTBACK;

    FREETMPS;
    LEAVE;

    return ret;
  }

  return sv_derived_from_sv(sv, namesv, 0);
}

static OP *pp_isa(pTHX)
{
  dSP;
  SV *rhs = POPs;
  SV *lhs = TOPs;

  SETs(boolSV(S_sv_isa_sv(aTHX_ lhs, rhs)));
  RETURN;
}

static OP *newop_isa(pTHX_ U32 flags, OP *lhs, OP *rhs, SV **parsedata, void *hookdata)
{
  /* Avoid strictness failure on bareword RHS */
  if(rhs->op_type == OP_CONST && rhs->op_private & OPpCONST_BARE)
    rhs->op_private &= ~(OPpCONST_BARE|OPpCONST_STRICT);

  return newBINOP_CUSTOM(&pp_isa, flags, lhs, rhs);
}

static const struct XSParseInfixHooks hooks_isa = {
  .flags = 0,
  .cls   = XPI_CLS_ISA,

  .new_op = &newop_isa,
};
#endif

MODULE = Syntax::Keyword::Match    PACKAGE = Syntax::Keyword::Match

BOOT:
  boot_xs_parse_keyword(0.36);
  boot_xs_parse_infix(0);

  register_xs_parse_keyword("match", &hooks_match, NULL);
#ifndef HAVE_OP_ISA
  register_xs_parse_infix("isa", &hooks_isa, NULL);
#endif
