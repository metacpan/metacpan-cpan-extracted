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

#if HAVE_PERL_VERSION(5,18,0)
#  define HAVE_BOOL_SvIV_please_nomg
#endif

#ifndef block_start
#  define block_start(flags)  Perl_block_start(aTHX_ flags)
#endif

#ifndef block_end
#  define block_end(floor, op)  Perl_block_end(aTHX_ floor, op)
#endif

#include "dispatchop.h"

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
        SvIVX(TARG) == SvIVX(val) : (do_numeq(TARG, val)))
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

static OP *build_cases_nondispatch(pTHX_ OPCODE matchtype, PADOFFSET padix, size_t n_cases, XSParseKeywordPiece *caseargs[], OP *block, OP *elseop)
{
  assert(n_cases);

  OP *testop = NULL;

  U32 argi;
  for(argi = 0; argi < n_cases; argi++) {
    OP *caseop = caseargs[argi]->op;

    OP *thistestop;

    switch(matchtype) {
#ifdef HAVE_OP_ISA
      case OP_ISA:
#endif
      case OP_SEQ:
      case OP_EQ:
        thistestop = newBINOP(matchtype, 0,
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
    }

    if(testop)
      testop = newLOGOP(OP_OR, 0, testop, thistestop);
    else
      testop = thistestop;
  }

  assert(testop);

  if(elseop)
    return newCONDOP(0, testop, block, elseop);
  else
    return newLOGOP(OP_AND, 0, testop, block);
}

static OP *build_cases_dispatch(pTHX_ OPCODE matchtype, PADOFFSET padix, size_t n_cases, XSParseKeywordPiece *args[], OP *elseop)
{
  assert(n_cases);
  assert(matchtype != OP_MATCH);

  U32 argi;

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
  argi = 0;
  while(n_cases) {
    U32 this_n_cases = args[argi++]->i;
    OP *block = args[argi + this_n_cases]->op;
    OP *blockstart = LINKLIST(block);
    block->op_next = retop;

    n_cases -= this_n_cases;

    while(this_n_cases) {
      OP *caseop = args[argi++]->op;
      assert(caseop->op_type == OP_CONST);
      values[idx] = SvREFCNT_inc(cSVOPx(caseop)->op_sv);
      op_free(caseop);

      dispatch[idx] = blockstart;

      idx++;
      this_n_cases--;
    }

    /* TODO: link chain of siblings */

    argi++; /* block */
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
   *     [4...]: $N * case exprs
   *     []: block
   *   [LAST]: default case if present
   */
  U32 argi = 0;

  OP *topic = args[argi++]->op;
  OPCODE matchtype = args[argi++]->i;
  int n_blocks = args[argi++]->i;

  /* Since we're going to fold up the blocks into an optree in reverse order,
   * starting from the end, it's a lot easier if we exchange the count and
   * block args so we can count backwards
   */
  while(n_blocks) {
    U32 count_argi = argi;
    int n_cases = args[argi++]->i;

    argi += n_cases;
    XSParseKeywordPiece *count_arg = args[count_argi];
    args[count_argi] = args[argi];
    args[argi] = count_arg;

    argi++;
    n_blocks--;
  }

  bool has_default = args[argi]->i;
  OP *o = NULL;
  if(has_default)
    o = args[argi + 1]->op;

  bool use_dispatch = hv_fetchs(GvHV(PL_hintgv), "Syntax::Keyword::Match/experimental(dispatch)", 0);

  I32 floor_ix = block_start(0);
  /* The name is totally meaningless and never used, but if we don't set a
   * name and instead use pad_alloc(SVs_PADTMP) then the peephole optimiser
   * for aassign will crash
   */
  PADOFFSET padix = pad_add_name_pvs("$(Syntax::Keyword::Match/topic)", 0, NULL, NULL);

  OP *startop = newBINOP(OP_SASSIGN, 0,
    topic, newPADSVOP(OP_PADSV, OPf_MOD, padix));

  int n_dispatch = 0;
  argi--;

  while(argi > 2) {
    int n_cases = args[argi--]->i;

    /* for build_cases we'd best put the args back into the right order
     * again */
    U32 block_argi = argi - n_cases;
    XSParseKeywordPiece *block_arg = args[block_argi];
    args[block_argi] = args[argi+1];
    args[argi+1] = block_arg;

    /* perl expects a strict optree, where each block appears exactly once.
     * We can't reüse the block between dispatch and non-dispatch ops, so
     * we'll have to decide which strategy to use here
     */
    bool this_block_dispatch = use_dispatch;

    for( ; argi > block_argi; argi--) {
      /* TODO: forbid the , operator in the case label */
      OP *caseop = args[argi]->op;

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
          if(use_dispatch && caseop->op_type == OP_CONST)
            continue;

          /* FALLTHROUGH */
        case OP_MATCH:
          this_block_dispatch = false;
          break;
      }
    }

    argi--;

    if(this_block_dispatch) {
      n_dispatch += n_cases;
      continue;
    }

    if(n_dispatch) {
      o = build_cases_dispatch(aTHX_ matchtype, padix,
          n_dispatch, args + argi + n_cases + 3, o);
      n_dispatch = 0;
    }

    o = build_cases_nondispatch(aTHX_ matchtype, padix,
      n_cases, args + argi + 2, block_arg->op, o);
  }

  if(n_dispatch)
    o = build_cases_dispatch(aTHX_ matchtype, padix,
        n_dispatch, args + argi + 1, o);

  *out = block_end(floor_ix, newLISTOP(OP_LINESEQ, 0, startop, o));

  return KEYWORD_PLUGIN_STMT;
}

static const struct XSParseKeywordHooks hooks_match = {
  .permit_hintkey = "Syntax::Keyword::Match/match",

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_PARENSCOPE( /* ( EXPR : OP ) */
      XPK_TERMEXPR_SCALARCTX,
      XPK_COLON,
      XPK_TAGGEDCHOICE(   /* TODO: relop ? */
        XPK_LITERAL("eq"), XPK_TAG(OP_SEQ),
        XPK_LITERAL("=="), XPK_TAG(OP_EQ),
        XPK_LITERAL("=~"), XPK_TAG(OP_MATCH),
#ifdef HAVE_OP_ISA
        XPK_LITERAL("isa"), XPK_TAG(OP_ISA),
#endif
        XPK_FAILURE("Expected a comparison operator")
      )
    ),
    XPK_BRACESCOPE( /* { blocks... } */
      XPK_REPEATED(     /* case (EXPR) {BLOCK} */
        XPK_COMMALIST(
          XPK_LITERAL("case"),
          XPK_PARENSCOPE( XPK_TERMEXPR_SCALARCTX )
        ),
        XPK_BLOCK
      ),
      XPK_OPTIONAL( /* default { ... } */
        XPK_LITERAL("default"),
        XPK_BLOCK
      )
    ),
    0,
  },
  .build = &build_match,
};

MODULE = Syntax::Keyword::Match    PACKAGE = Syntax::Keyword::Match

BOOT:
  boot_xs_parse_keyword(0.12);

  register_xs_parse_keyword("match", &hooks_match, NULL);
