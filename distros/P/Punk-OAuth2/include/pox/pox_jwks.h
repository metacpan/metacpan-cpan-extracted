#ifndef POX_JWKS_H
#define POX_JWKS_H

#include "pox_abi.h"
#include "pox_http.h"
#include "pox_url.h"

/* Punk::OAuth2::JWKS as a blessed HV: url, ua, allow_local, ttl,
 * min_refetch, keys (HV kid=>Crypt::JWS::Key), negative (HV kid=>time),
 * fetched_at, last_fetch, own_ua. */

static HV *pox_jwks_hv(pTHX_ SV *self) {
  if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
    croak("Punk::OAuth2::JWKS: not an object");
  return (HV *)SvRV(self);
}

static IV pox_hv_iv(pTHX_ HV *h, const char *k, IV dflt) {
  SV **v = hv_fetch(h, k, (I32)strlen(k), 0);
  return (v && *v && SvOK(*v)) ? SvIV(*v) : dflt;
}

static void pox_hv_set_iv(pTHX_ HV *h, const char *k, IV v) {
  (void)hv_store(h, k, (I32)strlen(k), newSViv(v), 0);
}

/* Import a JWK hashref via Crypt::JWS::Key->from_jwk; returns the key
 * object (mortal) or NULL on failure. */
static SV *pox_key_from_jwk(pTHX_ SV *jwk) {
  dSP;
  int count;
  SV *key = NULL;
  ENTER; SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVpvs("Crypt::JWS::Key")));
  XPUSHs(jwk);
  PUTBACK;
  count = call_method("from_jwk", G_SCALAR | G_EVAL);
  SPAGAIN;
  if (!SvTRUE(ERRSV) && count > 0) key = SvREFCNT_inc(POPs);
  else if (count > 0) (void)POPs;
  PUTBACK; FREETMPS; LEAVE;
  return key ? sv_2mortal(key) : NULL;
}

/* Fetch + parse the JWKS document, replacing the key cache. Rate limited
 * by min_refetch. Returns 1 on a successful refresh. */
static int pox_jwks_fetch(pTHX_ SV *self, SV *c) {
  HV *h = pox_jwks_hv(aTHX_ self);
  IV now = (IV)time(NULL);
  SV **ua_slot, **url;
  SV *ua, *data;
  int status = 0;
  HV *newkeys;
  SV **ks;

  if (now - pox_hv_iv(aTHX_ h, "last_fetch", 0)
      < pox_hv_iv(aTHX_ h, "min_refetch", 30))
    return 0;
  pox_hv_set_iv(aTHX_ h, "last_fetch", now);

  url = hv_fetchs(h, "url", 0);
  if (!url || !*url) return 0;
  ua_slot = hv_fetchs(h, "own_ua", 0);
  ua = pox_resolve_ua(aTHX_ hv_fetchs(h, "ua", 0)
                        ? *hv_fetchs(h, "ua", 0) : NULL,
                      c, ua_slot);
  if (!ua) return 0;
  /* own_ua may have been created inside resolve; persist it */
  if (ua_slot && (!*ua_slot || !SvOK(*ua_slot))
      && !(SvROK(ua) && sv_isobject(ua))) { /* nothing */ }

  data = pox_http_json(aTHX_ ua, "GET", SvPV_nolen(*url), NULL, NULL,
                       &status);
  if (status != 200 || !data || !SvROK(data)
      || SvTYPE(SvRV(data)) != SVt_PVHV)
    return 0;
  ks = hv_fetchs((HV *)SvRV(data), "keys", 0);
  if (!ks || !*ks || !SvROK(*ks) || SvTYPE(SvRV(*ks)) != SVt_PVAV)
    return 0;

  newkeys = newHV();
  {
    AV *av = (AV *)SvRV(*ks);
    SSize_t i, n = av_count(av);
    for (i = 0; i < n; i++) {
      SV **e = av_fetch(av, i, 0);
      HV *jh;
      SV **kid, *key;
      if (!e || !*e || !SvROK(*e) || SvTYPE(SvRV(*e)) != SVt_PVHV) continue;
      jh = (HV *)SvRV(*e);
      kid = hv_fetchs(jh, "kid", 0);
      if (!kid || !*kid || !SvOK(*kid)) continue;
      key = pox_key_from_jwk(aTHX_ *e);
      if (key)
        (void)hv_store_ent(newkeys, *kid, SvREFCNT_inc(key), 0);
    }
  }
  if (!HvUSEDKEYS(newkeys)) {
    SvREFCNT_dec((SV *)newkeys);
    return 0;
  }
  (void)hv_stores(h, "keys", newRV_noinc((SV *)newkeys));
  (void)hv_stores(h, "negative", newRV_noinc((SV *)newHV()));
  pox_hv_set_iv(aTHX_ h, "fetched_at", now);
  return 1;
}

/* kid => Crypt::JWS::Key, or NULL. TTL refetch, one refetch on an
 * unknown kid, negative cache against probing. Returns a mortal key. */
static SV *pox_jwks_key_for(pTHX_ SV *self, SV *c, SV *kidsv) {
  HV *h = pox_jwks_hv(aTHX_ self);
  IV now = (IV)time(NULL);
  IV ttl = pox_hv_iv(aTHX_ h, "ttl", 6 * 3600);
  STRLEN kl;
  const char *kid;
  HV *keys, *neg;
  SV **hit, **nv;

  if (!SvOK(kidsv)) return NULL;
  kid = SvPV_const(kidsv, kl);

  if (now - pox_hv_iv(aTHX_ h, "fetched_at", 0) >= ttl)
    pox_jwks_fetch(aTHX_ self, c);

  keys = (hv_fetchs(h, "keys", 0) && SvROK(*hv_fetchs(h, "keys", 0)))
    ? (HV *)SvRV(*hv_fetchs(h, "keys", 0)) : NULL;
  if (keys && (hit = hv_fetch(keys, kid, (I32)kl, 0)) && *hit)
    return sv_2mortal(SvREFCNT_inc(*hit));

  neg = (hv_fetchs(h, "negative", 0) && SvROK(*hv_fetchs(h, "negative", 0)))
    ? (HV *)SvRV(*hv_fetchs(h, "negative", 0)) : NULL;
  if (neg && (nv = hv_fetch(neg, kid, (I32)kl, 0)) && *nv
      && now - SvIV(*nv) < ttl)
    return NULL;

  pox_jwks_fetch(aTHX_ self, c);
  keys = (hv_fetchs(h, "keys", 0) && SvROK(*hv_fetchs(h, "keys", 0)))
    ? (HV *)SvRV(*hv_fetchs(h, "keys", 0)) : NULL;
  if (keys && (hit = hv_fetch(keys, kid, (I32)kl, 0)) && *hit)
    return sv_2mortal(SvREFCNT_inc(*hit));

  neg = (hv_fetchs(h, "negative", 0) && SvROK(*hv_fetchs(h, "negative", 0)))
    ? (HV *)SvRV(*hv_fetchs(h, "negative", 0)) : NULL;
  if (neg) (void)hv_store(neg, kid, (I32)kl, newSViv(now), 0);
  return NULL;
}

static SV *pox_jwks_new(pTHX_ HV *args) {
  HV *self = newHV();
  SV **v;
  SV *obj;
  const char *why = NULL;

  v = hv_fetchs(args, "url", 0);
  if (!v || !*v || !SvOK(*v))
    croak("Punk::OAuth2::JWKS: a url is required");
  {
    SV **al = hv_fetchs(args, "allow_local", 0);
    int allow = al && *al && SvTRUE(*al);
    if (!pox_safe_url(aTHX_ *v, allow, &why))
      croak("Punk::OAuth2::JWKS: unsafe JWKS url: %s", why);
  }
  (void)hv_stores(self, "url", newSVsv(*v));
  v = hv_fetchs(args, "ua", 0);
  (void)hv_stores(self, "ua", v && *v ? newSVsv(*v) : newSV(0));
  v = hv_fetchs(args, "allow_local", 0);
  (void)hv_stores(self, "allow_local", v && *v ? newSVsv(*v) : newSViv(0));
  pox_hv_set_iv(aTHX_ self, "ttl",
                (v = hv_fetchs(args, "ttl", 0)) && *v && SvOK(*v)
                  ? SvIV(*v) : 6 * 3600);
  pox_hv_set_iv(aTHX_ self, "min_refetch",
                (v = hv_fetchs(args, "min_refetch", 0)) && *v && SvOK(*v)
                  ? SvIV(*v) : 30);
  (void)hv_stores(self, "keys", newRV_noinc((SV *)newHV()));
  (void)hv_stores(self, "negative", newRV_noinc((SV *)newHV()));
  pox_hv_set_iv(aTHX_ self, "fetched_at", 0);
  pox_hv_set_iv(aTHX_ self, "last_fetch", 0);
  (void)hv_stores(self, "own_ua", newSV(0));

  obj = newRV_noinc((SV *)self);
  sv_bless(obj, gv_stashpvs("Punk::OAuth2::JWKS", GV_ADD));
  return obj;
}

#endif
