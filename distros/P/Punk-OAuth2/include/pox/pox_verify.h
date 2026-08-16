#ifndef POX_VERIFY_H
#define POX_VERIFY_H

#include "pox_abi.h"
#include "pox_util.h"

/* OIDC id_token claim validation over a decoded claims HV. Signature is
 * already checked by the caller (Crypt::JWS::verify); this enforces
 * iss (exact, trailing slash normalized), aud (must contain client_id),
 * azp (required when multiple audiences), exp/iat with leeway, and
 * nonce (constant-time) when one was issued. Returns 1 valid, 0 not. */

static int pox_hv_str_eq(pTHX_ HV *hv, const char *key, SV *want) {
  SV **v = hv_fetch(hv, key, (I32)strlen(key), 0);
  STRLEN al, bl;
  const char *a, *b;
  if (!v || !*v || !SvOK(*v) || SvROK(*v)) return 0;
  a = SvPV_const(*v, al);
  b = SvPV_const(want, bl);
  /* normalize a single trailing slash on both sides */
  if (al > 1 && a[al - 1] == '/') al--;
  if (bl > 1 && b[bl - 1] == '/') bl--;
  return al == bl && memEQ(a, b, al);
}

static int pox_verify_claims(pTHX_ HV *claims, SV *issuer, SV *client_id,
                             SV *nonce, int leeway) {
  IV now = (IV)time(NULL);
  SV **v;

  if (SvOK(issuer) && !pox_hv_str_eq(aTHX_ claims, "iss", issuer))
    return 0;

  /* aud: scalar or array; must contain client_id. Count for azp rule. */
  {
    STRLEN cidl;
    const char *cid = SvPV_const(client_id, cidl);
    int found = 0, naud = 0;
    v = hv_fetchs(claims, "aud", 0);
    if (!v || !*v || !SvOK(*v)) return 0;
    if (SvROK(*v) && SvTYPE(SvRV(*v)) == SVt_PVAV) {
      AV *av = (AV *)SvRV(*v);
      SSize_t i, n = av_count(av);
      naud = (int)n;
      for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        STRLEN el;
        const char *ep;
        if (!e || !*e || !SvOK(*e)) continue;
        ep = SvPV_const(*e, el);
        if (el == cidl && memEQ(ep, cid, cidl)) found = 1;
      }
    }
    else {
      STRLEN al;
      const char *ap = SvPV_const(*v, al);
      naud = 1;
      found = (al == cidl && memEQ(ap, cid, cidl));
    }
    if (!found) return 0;
    if (naud > 1) {
      SV **azp = hv_fetchs(claims, "azp", 0);
      if (!azp || !*azp || !SvOK(*azp)) return 0;
      {
        STRLEN zl;
        const char *zp = SvPV_const(*azp, zl);
        if (zl != cidl || !memEQ(zp, cid, cidl)) return 0;
      }
    }
  }

  /* exp required, with leeway */
  v = hv_fetchs(claims, "exp", 0);
  if (!v || !*v || !SvOK(*v)) return 0;
  if (now >= SvIV(*v) + leeway) return 0;

  /* iat optional; if present must not be in the future beyond leeway */
  v = hv_fetchs(claims, "iat", 0);
  if (v && *v && SvOK(*v) && SvIV(*v) > now + leeway) return 0;

  /* nonce constant-time when we issued one */
  if (SvOK(nonce)) {
    v = hv_fetchs(claims, "nonce", 0);
    if (!v || !*v || !SvOK(*v)) return 0;
    if (!pox_ct_eq_sv(aTHX_ *v, nonce)) return 0;
  }
  return 1;
}

#endif
