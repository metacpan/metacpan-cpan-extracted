/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2018 -- leonerd@leonerd.org.uk
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "AsyncAwait.h"

#ifdef HAVE_DMD_HELPER
#  include "DMD_helper.h"
#endif

#ifndef wrap_keyword_plugin
#  include "wrap_keyword_plugin.c.inc"
#endif

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

typedef struct {
  SV *var;    /* is HV * if keysv is set; indicates an HELEM */
  SV *keysv;
  SV *oldval; /* is NULL for HELEMs if we should delete at pop time */
  int saveix;
} DynamicVar;

#define newSVdynamicvar() S_newSVdynamicvar(aTHX)
static SV *S_newSVdynamicvar(pTHX)
{
  SV *ret = newSV(sizeof(DynamicVar));

#ifdef HAVE_DMD_HELPER
  if(DMD_IS_ACTIVE()) {
    SV *tmpRV = newRV_inc(ret);
    sv_bless(tmpRV, get_hv("Syntax::Keyword::Dynamically::_DynamicVar::", GV_ADD));
    SvREFCNT_dec(tmpRV);
  }
#endif

  return ret;
}

#ifdef HAVE_DMD_HELPER
static int dmd_help_dynamicvar(pTHX_ const SV *sv)
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

#define newSVsuspendeddynamicvar() S_newSVsuspendeddynamicvar(aTHX)
static SV *S_newSVsuspendeddynamicvar(pTHX)
{
  SV *ret = newSV(sizeof(SuspendedDynamicVar));

#ifdef HAVE_DMD_HELPER
  if(DMD_IS_ACTIVE()) {
    SV *tmpRV = newRV_inc(ret);
    sv_bless(tmpRV, get_hv("Syntax::Keyword::Dynamically::_SuspendedDynamicVar::", GV_ADD));
    SvREFCNT_dec(tmpRV);
  }
#endif

  return ret;
}

#ifdef HAVE_DMD_HELPER
static int dmd_help_suspendeddynamicvar(pTHX_ const SV *sv)
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

static SV *av_top(AV *av)
{
  return AvARRAY(av)[av_top_index(av)];
}

static SV *av_push_r(AV *av, SV *sv)
{
  av_push(av, sv);
  return sv;
}

#ifndef hv_deletes
#  define hv_deletes(hv, key, flags) \
    hv_delete((hv), ("" key ""), (sizeof(key)-1), (flags))
#endif

#define hv_store_or_delete(hv, key, val)  S_hv_store_or_delete(aTHX_ hv, key, val)
static void S_hv_store_or_delete(pTHX_ HV *hv, SV *key, SV *val)
{
  if(!val) {
    hv_delete_ent(hv, key, G_DISCARD, 0);
  }
  else
    hv_store_ent(hv, key, val, 0);
}

#define ENSURE_HV(sv)  S_ensure_hv(aTHX_ sv)
static HV *S_ensure_hv(pTHX_ SV *sv)
{
  if(SvTYPE(sv) == SVt_PVHV)
    return (HV *)sv;

  croak("Expected HV, got SvTYPE(sv)=%d", SvTYPE(sv));
}

#define pushdyn(var)  S_pushdyn(aTHX_ var)
static void S_pushdyn(pTHX_ SV *var)
{
  DynamicVar *dyn = (void *)SvPVX(
    av_push_r(dynamicstack, newSVdynamicvar())
  );

  dyn->var    = var;
  dyn->keysv  = NULL;
  dyn->oldval = newSVsv(var);
  dyn->saveix = PL_savestack_ix;
}

#define pushdynhelem(hv,keysv,curval)  S_pushdynhelem(aTHX_ hv,keysv,curval)
static void S_pushdynhelem(pTHX_ HV *hv, SV *keysv, SV *curval)
{
  DynamicVar *dyn = (void *)SvPVX(
    av_push_r(dynamicstack, newSVdynamicvar())
  );

  dyn->var    = (SV *)hv;
  dyn->keysv  = keysv;
  dyn->oldval = newSVsv(curval);
  dyn->saveix = PL_savestack_ix;
}

static void S_popdyn(pTHX_ void *_data)
{
  DynamicVar *dyn = (void *)SvPVX(av_top(dynamicstack));
  if(dyn->var != (SV *)_data)
    croak("ARGH: dynamicstack top mismatch");

  SV *sv = av_pop(dynamicstack);

  if(dyn->keysv) {
    HV *hv = ENSURE_HV(dyn->var);

    hv_store_or_delete(hv, dyn->keysv, dyn->oldval);
    /* hv now owns oldval; no need to dec refcount */

    SvREFCNT_dec(dyn->keysv);
  }
  else {
    sv_setsv_mg(dyn->var, dyn->oldval);
    SvREFCNT_dec(dyn->oldval);
  }

  SvREFCNT_dec(dyn->var);

  SvREFCNT_dec(sv);
}

static void hook_postsuspend(pTHX_ HV *modhookdata)
{
  IV i, max = av_top_index(dynamicstack);
  SV **avp = AvARRAY(dynamicstack);
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

    SuspendedDynamicVar *suspdyn = (void *)SvPVX(
      av_push_r(suspendedvars, newSVsuspendeddynamicvar())
    );

    suspdyn->var   = dyn->var;   /* steal */
    suspdyn->keysv = dyn->keysv; /* steal */
    suspdyn->is_outer = FALSE;

    if(dyn->keysv) {
      HV *hv = ENSURE_HV(dyn->var);
      HE *he = hv_fetch_ent(hv, dyn->keysv, 0, 0);
      suspdyn->curval = he ? newSVsv(HeVAL(he)) : NULL;

      hv_store_or_delete(hv, dyn->keysv, dyn->oldval);
      /* hv now owns oldval; no need to dec refcount */
    }
    else {
      suspdyn->curval = newSVsv(dyn->var);

      sv_setsv_mg(dyn->var, dyn->oldval);
      SvREFCNT_dec(dyn->oldval);
    }
  }

  if(i < max)
    /* truncate */
    av_fill(dynamicstack, i);

  for( ; i >= 0; i--) {
    DynamicVar *dyn = (void *)SvPVX(avp[i]);
    /* An outer dynamic variable - capture but do not restore */

    if(!suspendedvars) {
      suspendedvars = newAV();
      hv_stores(modhookdata, "Syntax::Keyword::Dynamically/suspendedvars", (SV *)suspendedvars);
    }

    SuspendedDynamicVar *suspdyn = (void *)SvPVX(
      av_push_r(suspendedvars, newSVsuspendeddynamicvar())
    );

    suspdyn->var = SvREFCNT_inc(dyn->var);
    suspdyn->is_outer = TRUE;

    if(dyn->keysv) {
      HV *hv = ENSURE_HV(dyn->var);
      HE *he = hv_fetch_ent(hv, dyn->keysv, 0, 0);
      suspdyn->keysv = SvREFCNT_inc(dyn->keysv);
      suspdyn->curval = he ? newSVsv(HeVAL(he)) : NULL;
    }
    else {
      suspdyn->keysv = NULL;
      suspdyn->curval = newSVsv(dyn->var);
    }
  }
}

static void hook_preresume(pTHX_ HV *modhookdata)
{
  AV *suspendedvars = (AV *)hv_deletes(modhookdata, "Syntax::Keyword::Dynamically/suspendedvars", 0);
  if(!suspendedvars)
    return;

  SV **avp = AvARRAY(suspendedvars);
  IV i, max = av_top_index(suspendedvars);

  for(i = max; i >= 0; i--) {
    SuspendedDynamicVar *suspdyn = (void *)SvPVX(avp[i]);

    if(suspdyn->keysv) {
      HV *hv = ENSURE_HV(suspdyn->var);
      HE *he = hv_fetch_ent(hv, suspdyn->keysv, 0, 0);
      pushdynhelem(hv, suspdyn->keysv, he ? HeVAL(he) : NULL);

      hv_store_or_delete(hv, suspdyn->keysv, suspdyn->curval);
      /* hv now owns curval; no need to dec refcount */
    }
    else {
      SV *var = suspdyn->var;
      pushdyn(var);

      sv_setsv_mg(var, suspdyn->curval);
      SvREFCNT_dec(suspdyn->curval);
    }

    if(suspdyn->is_outer) {
      SAVEDESTRUCTOR_X(&S_popdyn, suspdyn->var);
    }
    else {
      /* Don't SAVEDESTRUCTOR_X a second time because F-AA restored it */
    }
  }
}

static SuspendHookFunc *nexthook;

static void S_suspendhook(pTHX_ U8 phase, CV *cv, HV *modhookdata)
{
  switch(phase) {
    case FAA_PHASE_POSTSUSPEND:
      (*nexthook)(aTHX_ phase, cv, modhookdata);

      hook_postsuspend(aTHX_ modhookdata);
      break;

    case FAA_PHASE_PRERESUME:
      hook_preresume(aTHX_ modhookdata);

      (*nexthook)(aTHX_ phase, cv, modhookdata);
      break;

    default:
      (*nexthook)(aTHX_ phase, cv, modhookdata);
      break;
  }
}

static XOP xop_startdyn;

static OP *pp_startdyn(pTHX)
{
  dSP;
  SV *var = TOPs;

  if(is_async) {
    pushdyn(SvREFCNT_inc(var));
    SAVEDESTRUCTOR_X(&S_popdyn, var);
  }
  else {
    save_freesv(SvREFCNT_inc(var));
    save_item(var);
  }

  return cUNOP->op_next;
}

#define newSTARTDYNOP(expr)  MY_newSTARTDYNOP(aTHX_ expr)
static OP *MY_newSTARTDYNOP(pTHX_ OP *expr)
{
  OP *ret = newUNOP(OP_CUSTOM, 0, expr);
  cUNOPx(ret)->op_ppaddr = &pp_startdyn;
  return ret;
}

static XOP xop_helemdyn;

static OP *pp_helemdyn(pTHX)
{
  /* Contents inspired by core's pp_helem */
  dSP;
  SV * keysv = POPs;
  HV * const hv = MUTABLE_HV(POPs);
  bool preexisting;
  HE *he;
  SV **svp;

  /* Take a long-lived copy of keysv */
  keysv = newSVsv(keysv);

  preexisting = hv_exists_ent(hv, keysv, 0);
  he = hv_fetch_ent(hv, keysv, 1, 0);
  svp = &HeVAL(he);

  if(is_async) {
    SvREFCNT_inc((SV *)hv);

    if(preexisting)
      pushdynhelem(hv, keysv, *svp);
    else
      pushdynhelem(hv, keysv, NULL);
    SAVEDESTRUCTOR_X(&S_popdyn, (SV *)hv);
  }
  else {
    /* Basically identical to `local $hv{keysv}` at this point */
    if(preexisting) {
      save_helem_flags(hv, keysv, svp, SAVEf_SETMAGIC);
    }
    else {
      SAVEHDELETE(hv, keysv);
    }
  }

  PUSHs(*svp);

  RETURN;
}

static int dynamically_keyword(pTHX_ OP **op)
{
  OP *aop = NULL;
  OP *lvalop = NULL, *rvalop = NULL;

  lex_read_space(0);

  aop = parse_termexpr(0);

  if(aop->op_type != OP_SASSIGN)
    croak("Expected scalar assignment for 'dynamically'");

  rvalop = cBINOPx(aop)->op_first;
  lvalop = cBINOPx(aop)->op_last;

  if(lvalop->op_type == OP_HELEM) {
    /* In order to handle with the added complexities around delete $h{key}
     * we need to use our special version of OP_HELEM here instead of simply
     * calling STARTDYN on the fetched SV
     */

    /* Change the OP_HELEM into our custom one.
     * To ensure the peephole optimiser doesn't turn this into multideref we
     * have to change the op_type too */
    lvalop->op_type = OP_CUSTOM;
    lvalop->op_ppaddr = &pp_helemdyn;
    *op = aop;
  }
  else {
    /* Steal the lvalue / rvalue optrees from the op and destroy it, creating
     * a new tree instead */
    /* op_free will destroy the entire optree so replace the child ops first */
    cBINOPx(aop)->op_first = newOP(OP_NULL, 0);
    cBINOPx(aop)->op_last = newOP(OP_NULL, 0);
    op_free(aop);

    *op = newBINOP(OP_SASSIGN, 0,
      rvalop,
      newSTARTDYNOP(lvalop));
  }

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

void
_enable_async_mode()
  CODE:
    if(is_async)
      XSRETURN(0);

    is_async = TRUE;
    dynamicstack = newAV();
    av_extend(dynamicstack, 50);

    future_asyncawait_wrap_suspendhook(&S_suspendhook, &nexthook);

BOOT:
  XopENTRY_set(&xop_startdyn, xop_name, "startdyn");
  XopENTRY_set(&xop_startdyn, xop_desc,
    "starts a dynamic variable scope");
  XopENTRY_set(&xop_startdyn, xop_class, OA_UNOP);
  Perl_custom_op_register(aTHX_ &pp_startdyn, &xop_startdyn);

  wrap_keyword_plugin(&my_keyword_plugin, &next_keyword_plugin);
#ifdef HAVE_DMD_HELPER
  DMD_SET_PACKAGE_HELPER("Syntax::Keyword::Dynamically::_DynamicVar", &dmd_help_dynamicvar);
  DMD_SET_PACKAGE_HELPER("Syntax::Keyword::Dynamically::_SuspendedDynamicVar", &dmd_help_suspendeddynamicvar);
#endif
