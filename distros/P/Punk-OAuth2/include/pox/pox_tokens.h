#ifndef POX_TOKENS_H
#define POX_TOKENS_H

#include "pox_abi.h"

/* Punk::OAuth2::Tokens as a blessed HV. expires_in from the wire becomes
 * an absolute expires_at at construction. */

static SV *pox_tokens_new(pTHX_ HV *data) {
  HV *self = newHV();
  SV **v;
  SV *obj;

  v = hv_fetchs(data, "access_token", 0);
  (void)hv_stores(self, "access_token", v && *v ? newSVsv(*v) : newSV(0));
  v = hv_fetchs(data, "token_type", 0);
  (void)hv_stores(self, "token_type",
                  v && *v && SvOK(*v) ? newSVsv(*v) : newSVpvs("Bearer"));
  v = hv_fetchs(data, "refresh_token", 0);
  (void)hv_stores(self, "refresh_token", v && *v ? newSVsv(*v) : newSV(0));
  v = hv_fetchs(data, "id_token", 0);
  (void)hv_stores(self, "id_token", v && *v ? newSVsv(*v) : newSV(0));
  v = hv_fetchs(data, "scope", 0);
  (void)hv_stores(self, "scope", v && *v ? newSVsv(*v) : newSV(0));
  (void)hv_stores(self, "id_claims", newSV(0));

  {
    SV **ea = hv_fetchs(data, "expires_at", 0);
    SV **ei = hv_fetchs(data, "expires_in", 0);
    if (ea && *ea && SvOK(*ea))
      (void)hv_stores(self, "expires_at", newSVsv(*ea));
    else if (ei && *ei && SvOK(*ei))
      (void)hv_stores(self, "expires_at", newSViv((IV)time(NULL) + SvIV(*ei)));
    else
      (void)hv_stores(self, "expires_at", newSV(0));
  }

  {
    SV **raw = hv_fetchs(data, "raw", 0);
    (void)hv_stores(self, "raw", raw && *raw ? newSVsv(*raw) : newSV(0));
  }

  obj = newRV_noinc((SV *)self);
  sv_bless(obj, gv_stashpvs("Punk::OAuth2::Tokens", GV_ADD));
  return obj;
}

static HV *pox_tokens_hv(pTHX_ SV *self) {
  if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
    croak("Punk::OAuth2::Tokens: not an object");
  return (HV *)SvRV(self);
}

static SV *pox_tokens_get(pTHX_ SV *self, const char *key) {
  HV *h = pox_tokens_hv(aTHX_ self);
  SV **v = hv_fetch(h, key, (I32)strlen(key), 0);
  return (v && *v) ? SvREFCNT_inc(*v) : newSV(0);
}

#endif
