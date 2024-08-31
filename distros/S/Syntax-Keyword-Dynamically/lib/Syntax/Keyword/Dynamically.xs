/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2018 -- leonerd@leonerd.org.uk
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "AsyncAwait.h"

#include "XSParseKeyword.h"

#ifdef HAVE_DMD_HELPER
#  define WANT_DMD_API_044
#  include "DMD_helper.h"
#endif

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#include "perl-backcompat.c.inc"
#include "perl-additions.c.inc"
#include "newOP_CUSTOM.c.inc"

static bool is_async = FALSE;

#ifdef MULTIPLICITY
#  define dynamicstack  \
    *((AV **)hv_fetchs(PL_modglobal, "Syntax::Keyword::Dynamically/dynamicstack", GV_ADD))
#else
/* without MULTIPLICITY there's only one, so we might as well just store it
 * in a static
 */
static AV *dynamicstack;
#endif

#define ENSURE_HV(sv)  S_ensure_hv(aTHX_ sv)
static HV *S_ensure_hv(pTHX_ SV *sv)
{
  if(SvTYPE(sv) == SVt_PVHV)
    return (HV *)sv;

  croak("Expected HV, got SvTYPE(sv)=%d", SvTYPE(sv));
}

typedef struct {
  SV *var;    /* is HV * if keysv is set; indicates an HELEM */
  SV *keysv;
  SV *oldval; /* is NULL for HELEMs if we should delete at pop time */
  int saveix;
} DynamicVar;

#define newSVdynamicvar(var, key) S_newSVdynamicvar(aTHX_ var, key)
static SV *S_newSVdynamicvar(pTHX_ SV *var, SV *key)
{
  SV *ret = newSV(sizeof(DynamicVar));

#ifdef HAVE_DMD_HELPER
  if(DMD_IS_ACTIVE()) {
    SV *tmpRV = newRV_inc(ret);
    sv_bless(tmpRV, get_hv("Syntax::Keyword::Dynamically::_DynamicVar::", GV_ADD));
    SvREFCNT_dec(tmpRV);
  }
#endif

  DynamicVar *dyn = (void *)SvPVX((SV *)ret);

  dyn->var    = var;
  dyn->keysv  = key;
  dyn->saveix = PL_savestack_ix;

  if(key) {
    HV *hv = ENSURE_HV(var);
    HE *he = hv_fetch_ent(hv, key, 0, 0);
    dyn->oldval = he ? newSVsv(HeVAL(he)) : NULL;
  }
  else {
    dyn->oldval = newSVsv(var);
  }

  return ret;
}

#ifdef HAVE_DMD_HELPER
static int dmd_help_dynamicvar(pTHX_ DMDContext *ctx, const SV *sv)
{
  int ret = 0;

  DynamicVar *dyn = (void *)SvPVX((SV *)sv);

  if(dyn->keysv) {
    ret += DMD_ANNOTATE_SV(sv, dyn->var,    "the helem HV");
    ret += DMD_ANNOTATE_SV(sv, dyn->keysv,  "the helem key");
  }
  else
    ret += DMD_ANNOTATE_SV(sv, dyn->var,    "the variable slot");

  if(dyn->oldval)
    ret += DMD_ANNOTATE_SV(sv, dyn->oldval, "the old value slot");

  return ret;
}
#endif

typedef struct {
  SV *var;    /* is HV * if keysv is set; indicates an HELEM */
  SV *keysv;
  SV *curval; /* is NULL for HELEMs if we should delete at resume time */
  bool is_outer;
} SuspendedDynamicVar;

#define newSVsuspendeddynamicvar(var, key, is_outer) S_newSVsuspendeddynamicvar(aTHX_ var, key, is_outer)
static SV *S_newSVsuspendeddynamicvar(pTHX_ SV *var, SV *key, bool is_outer)
{
  SV *ret = newSV(sizeof(SuspendedDynamicVar));

#ifdef HAVE_DMD_HELPER
  if(DMD_IS_ACTIVE()) {
    SV *tmpRV = newRV_inc(ret);
    sv_bless(tmpRV, get_hv("Syntax::Keyword::Dynamically::_SuspendedDynamicVar::", GV_ADD));
    SvREFCNT_dec(tmpRV);
  }
#endif

  SuspendedDynamicVar *suspdyn = (void *)SvPVX((SV *)ret);

  suspdyn->var   = var;
  suspdyn->keysv = key;

  if(key) {
      HV *hv = ENSURE_HV(var);
      HE *he = hv_fetch_ent(hv, key, 0, 0);
      suspdyn->curval = he ? newSVsv(HeVAL(he)) : NULL;
  }
  else {
      suspdyn->curval = newSVsv(var);
  }

  suspdyn->is_outer = is_outer;

  return ret;
}

#ifdef HAVE_DMD_HELPER
static int dmd_help_suspendeddynamicvar(pTHX_ DMDContext *ctx, const SV *sv)
{
  int ret = 0;

  SuspendedDynamicVar *suspdyn = (void *)SvPVX((SV *)sv);

  if(suspdyn->keysv) {
    ret += DMD_ANNOTATE_SV(sv, suspdyn->var,    "the helem HV");
    ret += DMD_ANNOTATE_SV(sv, suspdyn->keysv,  "the helem key");
  }
  else
    ret += DMD_ANNOTATE_SV(sv, suspdyn->var,    "the variable slot");

  if(suspdyn->curval)
    ret += DMD_ANNOTATE_SV(sv, suspdyn->curval, "the current value slot");

  return ret;
}
#endif

#ifndef av_top_index
#  define av_top_index(av)  AvFILL(av)
#endif

#ifndef hv_deletes
#  define hv_deletes(hv, key, flags) \
    hv_delete((hv), ("" key ""), (sizeof(key)-1), (flags))
#endif

#define hv_setsv_or_delete(hv, key, val)  S_hv_setsv_or_delete(aTHX_ hv, key, val)
static void S_hv_setsv_or_delete(pTHX_ HV *hv, SV *key, SV *val)
{
  if(!val) {
    hv_delete_ent(hv, key, G_DISCARD, 0);
  }
  else
    sv_setsv(HeVAL(hv_fetch_ent(hv, key, 1, 0)), val);
}

static void S_popdyn(pTHX_ void *_data)
{
  AV *stack = dynamicstack;

  IV ix = av_top_index(stack);
  assert(ix > -1);

  SV *dv = AvARRAY(stack)[ix];
  assert(dv);

  DynamicVar *dyn = (void *)SvPVX(dv);
  assert(dyn);
  if(dyn->var != (SV *)_data)
    croak("ARGH: dynamicstack top mismatch");

  SV *sv = av_pop(stack);

  if(dyn->keysv) {
    HV *hv = ENSURE_HV(dyn->var);

    hv_setsv_or_delete(hv, dyn->keysv, dyn->oldval);

    SvREFCNT_dec(dyn->keysv);
  }
  else {
    sv_setsv_mg(dyn->var, dyn->oldval);
  }

  SvREFCNT_dec(dyn->var); dyn->var = NULL;
  SvREFCNT_dec(dyn->oldval); dyn->oldval = NULL;

  SvREFCNT_dec(sv);
}

static void hook_postsuspend(pTHX_ CV *cv, HV *modhookdata, void *hookdata)
{
  AV *stack = dynamicstack;

  IV i, max = av_top_index(stack);
  SV **avp = AvARRAY(stack);
  int height = PL_savestack_ix;
  AV *suspendedvars = NULL;

  for(i = max; i >= 0; i--) {
    DynamicVar *dyn = (void *)SvPVX(avp[i]);

    if(dyn->saveix < height)
      break;

    /* An inner dynamic variable - capture and restore */

    if(!suspendedvars) {
      suspendedvars = newAV();
      hv_stores(modhookdata, "Syntax::Keyword::Dynamically/suspendedvars", (SV *)suspendedvars);
    }

    av_push(suspendedvars,
      newSVsuspendeddynamicvar(dyn->var, dyn->keysv, false));

    if(dyn->keysv) {
      hv_setsv_or_delete(ENSURE_HV(dyn->var), dyn->keysv, dyn->oldval);
    }
    else {
      sv_setsv_mg(dyn->var, dyn->oldval);
    }
    SvREFCNT_dec(dyn->oldval);
  }

  if(i < max)
    /* truncate */
    av_fill(stack, i);

  for( ; i >= 0; i--) {
    DynamicVar *dyn = (void *)SvPVX(avp[i]);
    /* An outer dynamic variable - capture but do not restore */

    if(!suspendedvars) {
      suspendedvars = newAV();
      hv_stores(modhookdata, "Syntax::Keyword::Dynamically/suspendedvars", (SV *)suspendedvars);
    }

    av_push(suspendedvars,
      newSVsuspendeddynamicvar(SvREFCNT_inc(dyn->var), SvREFCNT_inc(dyn->keysv), true));
  }
}

static void hook_preresume(pTHX_ CV *cv, HV *modhookdata, void *hookdata)
{
  AV *suspendedvars = (AV *)hv_deletes(modhookdata, "Syntax::Keyword::Dynamically/suspendedvars", 0);
  if(!suspendedvars)
    return;

  SV **avp = AvARRAY(suspendedvars);
  IV i, max = av_top_index(suspendedvars);

  for(i = max; i >= 0; i--) {
    SuspendedDynamicVar *suspdyn = (void *)SvPVX(avp[i]);

    SV *var = suspdyn->var;
    av_push(dynamicstack,
      newSVdynamicvar(var, suspdyn->keysv));

    if(suspdyn->keysv) {
      hv_setsv_or_delete((HV *)var, suspdyn->keysv, suspdyn->curval);
    }
    else {
      sv_setsv_mg(var, suspdyn->curval);
    }
    SvREFCNT_dec(suspdyn->curval);

    if(suspdyn->is_outer) {
      SAVEDESTRUCTOR_X(&S_popdyn, suspdyn->var);
    }
    else {
      /* Don't SAVEDESTRUCTOR_X a second time because F-AA restored it */
    }
  }
}

static const struct AsyncAwaitHookFuncs faa_hooks = {
  .post_suspend = &hook_postsuspend,
  .pre_resume   = &hook_preresume,
};

/* STARTDYN is the primary op that makes this work. It is used in two ways:
 *   With OPf_STACKED it takes an optree, which pushes an SV to the stack.
 *   Without OPf_STACKED it uses op->op_targ to select a lexical
 * Either way, it saves the current value of the SV and arranges for that
 * value to be assigned back in on scope exit
 *
 * This op is _not_ used for dynamic assignments to hash elements; for that
 * see HELEMDYN
 */

static XOP xop_startdyn;

static OP *pp_startdyn(pTHX)
{
  dSP;
  SV *var = (PL_op->op_flags & OPf_STACKED) ? TOPs : PAD_SV(PL_op->op_targ);

  if(is_async) {
    av_push(dynamicstack,
      newSVdynamicvar(SvREFCNT_inc(var), NULL));
    SAVEDESTRUCTOR_X(&S_popdyn, var);
  }
  else {
    save_freesv(SvREFCNT_inc(var));
    /* When save_item() is restored it won't reset the SvPADMY flag properly.
     * This upsets -DDEBUGGING perls, so we'll have to save the flags too */
    if(SvFLAGS(var) & SVs_PADMY)
      save_set_svflags(var, SvFLAGS(var), SvFLAGS(var));
    save_item(var);
  }

  return cUNOP->op_next;
}

/* HELEMDYN is a variant of core's HELEM op which arranges for the existing
 * value (or absence of) the key in the hash to be restored again on scope
 * exit. It copes with missing keys by deleting them again to "restore".
 */

static void S_restore(pTHX_ void *_data)
{
  DynamicVar *dyn = _data;

  if(dyn->keysv) {
    hv_setsv_or_delete(ENSURE_HV(dyn->var), dyn->keysv, dyn->oldval);

    SvREFCNT_dec(dyn->var);
    SvREFCNT_dec(dyn->keysv);
    SvREFCNT_dec(dyn->oldval);
  }
  else
    croak("ARGH: Expected a keysv");

  Safefree(dyn);
}

static XOP xop_helemdyn;

static OP *pp_helemdyn(pTHX)
{
  /* Contents inspired by core's pp_helem */
  dSP;
  SV * keysv = POPs;
  HV * const hv = MUTABLE_HV(POPs);

  /* Take a long-lived copy of keysv */
  keysv = newSVsv(keysv);

  bool preexisting = hv_exists_ent(hv, keysv, 0);
  HE *he;

  if(is_async) {
    SvREFCNT_inc((SV *)hv);

    av_push(dynamicstack,
      newSVdynamicvar((SV *)hv, keysv));
    SAVEDESTRUCTOR_X(&S_popdyn, (SV *)hv);

    /* must fetch -after- calling newSVdynamicvar() */
    he = hv_fetch_ent(hv, keysv, 1, 0);
  }
  else {
    DynamicVar *dyn;
    Newx(dyn, 1, DynamicVar);

    he = hv_fetch_ent(hv, keysv, 1, 0);

    dyn->var   = SvREFCNT_inc(hv);
    dyn->keysv = SvREFCNT_inc(keysv);
    dyn->oldval = preexisting ? newSVsv(HeVAL(he)) : NULL;
    SAVEDESTRUCTOR_X(&S_restore, dyn);
  }

  PUSHs(HeVAL(he));

  RETURN;
}

static int build_dynamically(pTHX_ OP **out, XSParseKeywordPiece *arg0, void *hookdata)
{
  OP *aop = arg0->op;
  OP *lvalop = NULL, *rvalop = NULL;

  /* While most scalar assignments become OP_SASSIGN, some cases of assignment
   * from a binary operator into a pad lexical instead set OPpTARGET_MY and use
   * op->op_targ instead.
   */
  if((PL_opargs[aop->op_type] & OA_TARGLEX) && (aop->op_private & OPpTARGET_MY)) {
    /* dynamically LEXVAR = EXPR */

    /* Since LEXVAR is a pad lexical we can generate a non-stacked STARTDYN
     * and set the same targ on it, then perform that just before the
     * otherwise-unmodified op
     */
    OP *dynop = newUNOP_CUSTOM(&pp_startdyn, 0, newOP(OP_NULL, 0));
    dynop->op_targ = aop->op_targ;

    *out = op_prepend_elem(OP_LINESEQ,
      dynop, aop);

    return KEYWORD_PLUGIN_EXPR;
  }

  if(aop->op_type != OP_SASSIGN)
    croak("Expected scalar assignment for 'dynamically'");

  rvalop = cBINOPx(aop)->op_first;
  lvalop = cBINOPx(aop)->op_last;

  if(lvalop->op_type == OP_HELEM) {
    /* dynamically $h{key} = EXPR */

    /* In order to handle with the added complexities around delete $h{key}
     * we need to use our special version of OP_HELEM here instead of simply
     * calling STARTDYN on the fetched SV
     */

    /* Change the OP_HELEM into our custom one.
     * To ensure the peephole optimiser doesn't turn this into multideref we
     * have to change the op_type too */
    lvalop->op_type = OP_CUSTOM;
    lvalop->op_ppaddr = &pp_helemdyn;
    *out = aop;
  }
  else {
    /* dynamimcally LEXPR = EXPR */

    /* Rather than splicing in STARTDYN op, we'll just make a new optree */
    *out = newBINOP(aop->op_type, aop->op_flags,
      rvalop,
      newUNOP_CUSTOM(&pp_startdyn, aop->op_flags & OPf_STACKED, lvalop));

    /* op_free will destroy the entire optree so replace the child ops first */
    cBINOPx(aop)->op_first = NULL;
    cBINOPx(aop)->op_last = NULL;
    aop->op_flags &= ~OPf_KIDS;
    op_free(aop);
  }

  return KEYWORD_PLUGIN_EXPR;
}

static const struct XSParseKeywordHooks hooks_dynamically = {
  .permit_hintkey = "Syntax::Keyword::Dynamically/dynamically",
  .piece1 = XPK_TERMEXPR,
  .build1 = &build_dynamically,
};

static void enable_async_mode(pTHX_ void *_unused)
{
  if(is_async)
    return;

  is_async = TRUE;
  AV *stack = dynamicstack = newAV();
  av_extend(stack, 50);

  boot_future_asyncawait(0.60);
  register_future_asyncawait_hook(&faa_hooks, NULL);
}

MODULE = Syntax::Keyword::Dynamically    PACKAGE = Syntax::Keyword::Dynamically

void
_enable_async_mode()
  CODE:
    enable_async_mode(aTHX_ NULL);

BOOT:
  XopENTRY_set(&xop_startdyn, xop_name, "startdyn");
  XopENTRY_set(&xop_startdyn, xop_desc,
    "starts a dynamic variable scope");
  XopENTRY_set(&xop_startdyn, xop_class, OA_UNOP);
  Perl_custom_op_register(aTHX_ &pp_startdyn, &xop_startdyn);

  boot_xs_parse_keyword(0.13);

  register_xs_parse_keyword("dynamically", &hooks_dynamically, NULL);
#ifdef HAVE_DMD_HELPER
  DMD_SET_PACKAGE_HELPER("Syntax::Keyword::Dynamically::_DynamicVar", &dmd_help_dynamicvar);
  DMD_SET_PACKAGE_HELPER("Syntax::Keyword::Dynamically::_SuspendedDynamicVar", &dmd_help_suspendeddynamicvar);
#endif

  future_asyncawait_on_activate(&enable_async_mode, NULL);
