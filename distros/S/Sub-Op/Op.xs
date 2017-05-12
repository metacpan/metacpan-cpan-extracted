/* This file is part of the Sub::Op Perl module.
 * See http://search.cpan.org/dist/Sub-Op/ */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define __PACKAGE__     "Sub::Op"
#define __PACKAGE_LEN__ (sizeof(__PACKAGE__)-1)

/* --- Compatibility wrappers ---------------------------------------------- */

#define SO_HAS_PERL(R, V, S) (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

/* ... Thread safety and multiplicity ...................................... */

#ifndef SO_MULTIPLICITY
# if defined(MULTIPLICITY) || defined(PERL_IMPLICIT_CONTEXT)
#  define SO_MULTIPLICITY 1
# else
#  define SO_MULTIPLICITY 0
# endif
#endif
#if SO_MULTIPLICITY && !defined(tTHX)
# define tTHX PerlInterpreter*
#endif

#if SO_MULTIPLICITY && defined(USE_ITHREADS) && defined(dMY_CXT) && defined(MY_CXT) && defined(START_MY_CXT) && defined(MY_CXT_INIT) && (defined(MY_CXT_CLONE) || defined(dMY_CXT_SV))
# define SO_THREADSAFE 1
# ifndef MY_CXT_CLONE
#  define MY_CXT_CLONE \
    dMY_CXT_SV;                                                      \
    my_cxt_t *my_cxtp = (my_cxt_t*)SvPVX(newSV(sizeof(my_cxt_t)-1)); \
    Copy(INT2PTR(my_cxt_t*, SvUV(my_cxt_sv)), my_cxtp, 1, my_cxt_t); \
    sv_setuv(my_cxt_sv, PTR2UV(my_cxtp))
# endif
#else
# define SO_THREADSAFE 0
# undef  dMY_CXT
# define dMY_CXT      dNOOP
# undef  MY_CXT
# define MY_CXT       indirect_globaldata
# undef  START_MY_CXT
# define START_MY_CXT STATIC my_cxt_t MY_CXT;
# undef  MY_CXT_INIT
# define MY_CXT_INIT  NOOP
# undef  MY_CXT_CLONE
# define MY_CXT_CLONE NOOP
#endif

/* --- Global data --------------------------------------------------------- */

#define MY_CXT_KEY __PACKAGE__ "::_guts" XS_VERSION

typedef struct {
 HV  *map;
 CV  *placeholder;
#if SO_THREADSAFE
 tTHX owner;
#endif /* SO_THREADSAFE */
} my_cxt_t;

START_MY_CXT

#if SO_THREADSAFE

STATIC SV *so_clone(pTHX_ SV *sv, tTHX owner) {
#define so_clone(S, O) so_clone(aTHX_ (S), (O))
 CLONE_PARAMS  param;
 AV           *stashes = NULL;
 SV           *dupsv;

 if (SvTYPE(sv) == SVt_PVHV && HvNAME_get(sv))
  stashes = newAV();

 param.stashes    = stashes;
 param.flags      = 0;
 param.proto_perl = owner;

 dupsv = sv_dup(sv, &param);

 if (stashes) {
  av_undef(stashes);
  SvREFCNT_dec(stashes);
 }

 return SvREFCNT_inc(dupsv);
}

#endif /* SO_THREADSAFE */

#define PTABLE_NAME        ptable
#define PTABLE_VAL_FREE(V) PerlMemShared_free(V)

#include "ptable.h"

/* PerlMemShared_free() needs the [ap]PTBLMS_? default values */
#define ptable_store(T, K, V) ptable_store(aPTBLMS_ (T), (K), (V))

STATIC ptable *so_op_name = NULL;

#ifdef USE_ITHREADS
STATIC perl_mutex so_op_name_mutex;
#endif

typedef struct {
 STRLEN len;
 char   buf;
} so_op_name_t;

/* --- Public API ---------------------------------------------------------- */

#include "sub_op.h"

void sub_op_register(pTHX_ const sub_op_config_t *c) {
 SV *key = newSViv(PTR2IV(c->pp));

 if (!PL_custom_op_names)
  PL_custom_op_names = newHV();
 (void) hv_store_ent(PL_custom_op_names, key, newSVpv(c->name, c->namelen), 0);

 if (!PL_custom_op_descs)
  PL_custom_op_descs = newHV();
 (void) hv_store_ent(PL_custom_op_descs, key, newSVpv(c->name, c->namelen), 0);

 if (c->check) {
  SV *check = newSViv(PTR2IV(c->check));
  sv_magicext(key, check, PERL_MAGIC_ext, NULL, c->ud, 0);
  SvREFCNT_dec(check);
 }

 {
  dMY_CXT;
  (void) hv_store(MY_CXT.map, c->name, c->namelen, key, 0);
 }
}

/* --- Private helpers ----------------------------------------------------- */

STATIC IV so_hint(pTHX) {
#define so_hint() so_hint(aTHX)
 SV *hint;

#if SO_HAS_PERL(5, 9, 5)
 hint = Perl_refcounted_he_fetch(aTHX_ PL_curcop->cop_hints_hash,
                                       NULL,
                                       __PACKAGE__, __PACKAGE_LEN__,
                                       0,
                                       0);
#else
 {
  SV **val = hv_fetch(GvHV(PL_hintgv), __PACKAGE__, __PACKAGE_LEN__, 0);
  if (!val)
   return 0;
  hint = *val;
 }
#endif

 return (SvOK(hint) && SvIOK(hint)) ? SvIVX(hint) : 0;
}

STATIC OP *(*so_old_ck_entersub)(pTHX_ OP *) = 0;

STATIC OP *so_ck_entersub(pTHX_ OP *o) {
 o = CALL_FPTR(so_old_ck_entersub)(aTHX_ o);

 if (so_hint()) {
  OP *ex_list, *rv2cv, *gvop, *last_arg = NULL;
  GV *gv;

  if (o->op_type != OP_ENTERSUB)
   goto skip;
  if (o->op_private & OPpENTERSUB_AMPER) /* hopefully \&foo */
   goto skip;

  ex_list = cUNOPo->op_first;
  /* pushmark when a method call */
  if (!ex_list || ex_list->op_type != OP_NULL)
   goto skip;

  rv2cv = cUNOPx(ex_list)->op_first;
  if (!rv2cv)
   goto skip;

  while (1) {
   OP *next = rv2cv->op_sibling;
   if (!next)
    break;
   last_arg = rv2cv;
   rv2cv    = next;
  }

  if (!(rv2cv->op_flags & OPf_KIDS))
   goto skip;

  gvop = cUNOPx(rv2cv)->op_first;
  if (!gvop || gvop->op_type != OP_GV)
   goto skip;

  gv = cGVOPx_gv(gvop);

  {
   SV *pp_sv, **svp;
   CV *cv = NULL;
   const char *name = GvNAME(gv);
   I32         len  = GvNAMELEN(gv);
   dMY_CXT;

   svp = hv_fetch(MY_CXT.map, name, len, 0);
   if (!svp)
    goto skip;

   pp_sv = *svp;
   if (!pp_sv || !SvOK(pp_sv))
    goto skip;

   if (gv && SvTYPE(gv) >= SVt_PVGV && (cv = GvCV(gv)) == MY_CXT.placeholder) {
    SvREFCNT_dec(cv);
    GvCV(gv) = NULL;
   }

   o->op_type   = OP_CUSTOM;
   o->op_ppaddr = INT2PTR(Perl_ppaddr_t, SvIVX(pp_sv));

   if (last_arg)
    last_arg->op_sibling = NULL;

   op_free(rv2cv);

   {
    MAGIC *mg = mg_find(pp_sv, PERL_MAGIC_ext);
    if (mg) {
     sub_op_check_t check = INT2PTR(sub_op_check_t, SvIVX(mg->mg_obj));
     o = CALL_FPTR(check)(aTHX_ o, mg->mg_ptr);
    }
   }

   {
    so_op_name_t *on = PerlMemShared_malloc(sizeof(*on) + len);
    Copy(name, &on->buf, len, char);
    (&on->buf)[len] = '\0';
    on->len = len;
#ifdef USE_ITHREADS
    MUTEX_LOCK(&so_op_name_mutex);
#endif /* USE_ITHREADS */
    ptable_store(so_op_name, o, on);
#ifdef USE_ITHREADS
    MUTEX_UNLOCK(&so_op_name_mutex);
#endif /* USE_ITHREADS */
   }
  }
 }

skip:
 return o;
}

STATIC OP *(*so_old_ck_gelem)(pTHX_ OP *) = 0;

STATIC OP *so_ck_gelem(pTHX_ OP *o) {
 o = CALL_FPTR(so_old_ck_entersub)(aTHX_ o);

 if (so_hint()) {
  OP *rv2gv, *gvop;
  GV *gv;

  rv2gv = cUNOPo->op_first;
  if (!rv2gv)
   goto skip;

  gvop = cUNOPx(rv2gv)->op_first;
  if (!gvop || gvop->op_type != OP_GV)
   goto skip;

  gv = cGVOPx_gv(gvop);
  if (!gv)
   goto skip;

  {
   CV *cv;
   dMY_CXT;

   if (gv && SvTYPE(gv) >= SVt_PVGV && (cv = GvCV(gv)) == MY_CXT.placeholder) {
    SvREFCNT_dec(cv);
    GvCV(gv) = NULL;
   }
  }
 }

skip:
 return o;
}

/* --- XS ------------------------------------------------------------------ */

MODULE = Sub::Op      PACKAGE = Sub::Op

PROTOTYPES: ENABLE

BOOT:
{
 so_op_name = ptable_new();
#ifdef USE_ITHREADS
 MUTEX_INIT(&so_op_name_mutex);
#endif

 MY_CXT_INIT;
 MY_CXT.map         = newHV();
 MY_CXT.placeholder = NULL;
#if SO_THREADSAFE
 MY_CXT.owner       = aTHX;
#endif /* SO_THREADSAFE */

 so_old_ck_entersub    = PL_check[OP_ENTERSUB];
 PL_check[OP_ENTERSUB] = so_ck_entersub;
 so_old_ck_gelem       = PL_check[OP_GELEM];
 PL_check[OP_GELEM]    = so_ck_gelem;
}

#if SO_THREADSAFE

void
CLONE(...)
PROTOTYPE: DISABLE
PREINIT:
 HV  *map;
 CV  *placeholder;
 tTHX owner;
PPCODE:
 {
  dMY_CXT;
  owner       = MY_CXT.owner;
  map         = (HV *) so_clone((SV *) MY_CXT.map,         owner);
  placeholder = (CV *) so_clone((SV *) MY_CXT.placeholder, owner);
 }
 {
  MY_CXT_CLONE;
  MY_CXT.map         = map;
  MY_CXT.placeholder = placeholder;
  MY_CXT.owner       = aTHX;
 }
 XSRETURN(0);

#endif /* SO_THREADSAFE */

void
_placeholder(SV *sv)
PROTOTYPE: $
PPCODE:
 if (SvROK(sv)) {
  sv = SvRV(sv);
  if (SvTYPE(sv) >= SVt_PVCV) {
   dMY_CXT;
   SvREFCNT_dec(MY_CXT.placeholder);
   MY_CXT.placeholder = (CV *) SvREFCNT_inc(sv);
  }
 }
 XSRETURN(0);

void
_custom_name(SV *op)
PROTOTYPE: $
PREINIT:
 OP *o;
 so_op_name_t *on;
PPCODE:
 if (!SvROK(op))
  XSRETURN_UNDEF;
 o = INT2PTR(OP *, SvIV(SvRV(op)));
 if (!o || o->op_type != OP_CUSTOM)
  XSRETURN_UNDEF;
#ifdef USE_ITHREADS
 MUTEX_LOCK(&so_op_name_mutex);
#endif /* USE_ITHREADS */
 on = ptable_fetch(so_op_name, o);
#ifdef USE_ITHREADS
 MUTEX_UNLOCK(&so_op_name_mutex);
#endif /* USE_ITHREADS */
 if (!on)
  XSRETURN_UNDEF;
 ST(0) = sv_2mortal(newSVpvn(&on->buf, on->len));
 XSRETURN(1);

void
_constant_sub(SV *sv)
PROTOTYPE: $
PPCODE:
 if (!SvROK(sv))
  XSRETURN_UNDEF;
 sv = SvRV(sv);
 if (SvTYPE(sv) < SVt_PVCV)
  XSRETURN_UNDEF;
 ST(0) = sv_2mortal(newSVuv(CvCONST(sv)));
 XSRETURN(1);
