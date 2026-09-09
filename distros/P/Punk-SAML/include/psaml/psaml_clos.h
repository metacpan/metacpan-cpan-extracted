#ifndef PSAML_CLOS_H
#define PSAML_CLOS_H

/* Closures, and the small predicates the rest of this distribution reads
 * options with.
 *
 * This is Punk-Feed's pfeed_closure, which is Punk-Authorisation's
 * pau_closure, which is Punk-TOTP's pp_closure, which is a copy of
 * Punk's private punk_closure: a CV built with newXS carrying captured
 * SVs in PERL_MAGIC_ext. Punk does not export it - pk_abi.h is an
 * observer interface and says so - so a plugin that wants a body with
 * state carries its own.
 *
 * The capture is an AV rather than a fixed pair, because the bodies here
 * capture [app], [app, idp] and [app, idp, opts]. */

#include "psaml_compat.h"

typedef struct { AV *cap; } psaml_clos_t;

static int psaml_clos_free(pTHX_ SV *sv, MAGIC *mg) {
  psaml_clos_t *c = (psaml_clos_t *)mg->mg_ptr;
  PERL_UNUSED_ARG(sv);
  if (c) {
    if (c->cap) SvREFCNT_dec((SV *)c->cap);
    Safefree(c);
  }
  return 0;
}

static MGVTBL psaml_clos_vtbl = { NULL, NULL, NULL, NULL, psaml_clos_free,
                                  NULL, NULL, NULL };

/* Takes ownership of cap. */
PERL_STATIC_INLINE SV *psaml_closure(pTHX_ XSUBADDR_t body, AV *cap) {
  CV *cv = (CV *)newXS(NULL, body, (char *)__FILE__);
  psaml_clos_t *c;
  Newxz(c, 1, psaml_clos_t);
  c->cap = cap;
  sv_magicext((SV *)cv, NULL, PERL_MAGIC_ext, &psaml_clos_vtbl, (char *)c, 0);
  return newRV_noinc((SV *)cv);
}

PERL_STATIC_INLINE AV *psaml_cap_of(pTHX_ CV *cv) {
  MAGIC *mg = mg_findext((SV *)cv, PERL_MAGIC_ext, &psaml_clos_vtbl);
  AV *cap = mg ? ((psaml_clos_t *)mg->mg_ptr)->cap : NULL;
  if (!cap) croak("Punk::Plugin::SAML: a closure lost its capture");
  return cap;
}

/* One capture slot, borrowed. */
PERL_STATIC_INLINE SV *psaml_cap_slot(pTHX_ CV *cv, SSize_t i) {
  AV *cap = psaml_cap_of(aTHX_ cv);
  SV **e = av_fetch(cap, i, 0);
  return (e && *e) ? *e : NULL;
}

/* ---- option predicates ----------------------------------------------- */

/* A defined, non-empty string option, borrowed, or NULL.
 *
 * SvPV is taken once into a named variable rather than called twice,
 * because a caller writing f(SvPV(sv, l), l) reads l before SvPV has set
 * it: the two arguments are siblings and their evaluation order is not
 * ordered by anything. */
PERL_STATIC_INLINE const char *psaml_opt_str(pTHX_ HV *o, const char *key, STRLEN *len) {
  SV **e = hv_fetch(o, key, (I32)strlen(key), 0);
  const char *p;
  STRLEN n;
  if (!e || !*e || !SvOK(*e)) return NULL;
  p = SvPV_const(*e, n);
  if (!n) return NULL;
  if (len) *len = n;
  return p;
}

/* A boolean option with a stated default.
 *
 * SvTRUE is a multi-evaluating macro, so the fetched SV goes into a
 * variable first. Around a POPs it corrupts the stack; here it would
 * merely fetch twice, but the habit is the point: this family has been
 * bitten by SvTRUE and SvIV on expressions with side effects more than
 * once. */
PERL_STATIC_INLINE int psaml_opt_bool(pTHX_ HV *o, const char *key, int dflt) {
  SV **e = hv_fetch(o, key, (I32)strlen(key), 0);
  SV *sv;
  if (!e || !*e || !SvOK(*e)) return dflt;
  sv = *e;
  return SvTRUE(sv) ? 1 : 0;
}

PERL_STATIC_INLINE IV psaml_opt_iv(pTHX_ HV *o, const char *key, IV dflt) {
  SV **e = hv_fetch(o, key, (I32)strlen(key), 0);
  SV *sv;
  if (!e || !*e || !SvOK(*e)) return dflt;
  sv = *e;
  return SvIV(sv);
}

/* ---- small readers ---------------------------------------------------- */

PERL_STATIC_INLINE SV *psaml_hget(pTHX_ HV *h, const char *k) {
  SV **e = h ? hv_fetch(h, k, (I32)strlen(k), 0) : NULL;
  return (e && *e) ? *e : NULL;
}

PERL_STATIC_INLINE int psaml_is_code(pTHX_ SV *sv) {
  return sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV;
}

PERL_STATIC_INLINE int psaml_is_hash(pTHX_ SV *sv) {
  return sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV;
}

PERL_STATIC_INLINE int psaml_is_array(pTHX_ SV *sv) {
  return sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV;
}

/* A non-negative integer option with a default. A negative skew or ttl is
 * not a smaller one, it is a comparison that runs backwards. */
PERL_STATIC_INLINE IV psaml_opt_uv(pTHX_ HV *in, const char *k, IV dflt) {
  SV *v = psaml_hget(aTHX_ in, k);
  IV n;
  if (!v || !SvOK(v)) return dflt;
  n = SvIV(v);
  if (n < 0)
    croak("%s: `%s` must be zero or more, not %" IVdf, PSAML_WHO, k, n);
  return n;
}

#endif /* PSAML_CLOS_H */
