#ifndef POX_PRESETS_H
#define POX_PRESETS_H

#include "pox_abi.h"

/* Provider presets built in C. Each returns a fresh HV the caller owns.
 * The github preset's identity_map is a CV ref to the named XSUB
 * Punk::OAuth2::_github_identity (defined in xs/presets.xs). */

static void pox_hv_str(pTHX_ HV *h, const char *k, const char *v) {
  (void)hv_store(h, k, (I32)strlen(k), newSVpv(v, 0), 0);
}
static void pox_hv_int(pTHX_ HV *h, const char *k, int v) {
  (void)hv_store(h, k, (I32)strlen(k), newSViv(v), 0);
}

static HV *pox_preset(pTHX_ const char *name) {
  HV *h = newHV();
  if (strcmp(name, "google") == 0) {
    pox_hv_int(aTHX_ h, "oidc", 1);
    pox_hv_str(aTHX_ h, "issuer", "https://accounts.google.com");
    pox_hv_str(aTHX_ h, "authorization_endpoint",
               "https://accounts.google.com/o/oauth2/v2/auth");
    pox_hv_str(aTHX_ h, "token_endpoint",
               "https://oauth2.googleapis.com/token");
    pox_hv_str(aTHX_ h, "jwks_uri",
               "https://www.googleapis.com/oauth2/v3/certs");
    pox_hv_str(aTHX_ h, "userinfo_endpoint",
               "https://openidconnect.googleapis.com/v1/userinfo");
    pox_hv_str(aTHX_ h, "scope", "openid email profile");
    pox_hv_str(aTHX_ h, "auth_method", "body");
  }
  else if (strcmp(name, "github") == 0) {
    CV *cv = get_cv("Punk::OAuth2::_github_identity", 0);
    HV *th = newHV();
    pox_hv_int(aTHX_ h, "oidc", 0);
    pox_hv_str(aTHX_ h, "authorization_endpoint",
               "https://github.com/login/oauth/authorize");
    pox_hv_str(aTHX_ h, "token_endpoint",
               "https://github.com/login/oauth/access_token");
    pox_hv_str(aTHX_ h, "identity_endpoint", "https://api.github.com/user");
    pox_hv_str(aTHX_ h, "emails_endpoint",
               "https://api.github.com/user/emails");
    pox_hv_str(aTHX_ h, "scope", "read:user user:email");
    pox_hv_str(aTHX_ h, "auth_method", "body");
    pox_hv_str(aTHX_ th, "Accept", "application/json");
    (void)hv_stores(h, "token_headers", newRV_noinc((SV *)th));
    if (cv)
      (void)hv_stores(h, "identity_map", newRV_inc((SV *)cv));
  }
  else if (strcmp(name, "oidc") == 0) {
    pox_hv_int(aTHX_ h, "oidc", 1);
    pox_hv_int(aTHX_ h, "discovery", 1);
  }
  else {
    SvREFCNT_dec((SV *)h);
    croak("Punk::OAuth2: unknown preset '%s' (google, github, oidc)", name);
  }
  return h;
}

#endif
