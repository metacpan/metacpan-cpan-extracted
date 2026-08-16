#ifndef POX_PROVIDER_H
#define POX_PROVIDER_H

#include "pox_abi.h"
#include "pox_http.h"
#include "pox_url.h"
#include "pox_util.h"
#include "pox_verify.h"
#include "pox_tokens.h"
#include "pox_presets.h"
#include "pox_jwks.h"

/* Punk::OAuth2::Provider as a blessed HV of the merged config. */

static HV *pox_prov_hv(pTHX_ SV *self) {
  if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
    croak("Punk::OAuth2::Provider: not an object");
  return (HV *)SvRV(self);
}
static SV *pox_prov_get(pTHX_ HV *h, const char *k) {
  SV **v = hv_fetch(h, k, (I32)strlen(k), 0);
  return (v && *v && SvOK(*v)) ? *v : NULL;
}
static const char *pox_prov_str(pTHX_ HV *h, const char *k) {
  SV *v = pox_prov_get(aTHX_ h, k);
  return v ? SvPV_nolen(v) : NULL;
}
static const char *pox_prov_name(pTHX_ HV *h) {
  const char *n = pox_prov_str(aTHX_ h, "name");
  return n ? n : "?";
}
/* truthiness of a config flag (a defined 0 is false, not "present") */
static int pox_prov_flag(pTHX_ HV *h, const char *k) {
  SV *v = pox_prov_get(aTHX_ h, k);
  return v && SvTRUE(v);
}
static SV *pox_prov_ua(pTHX_ HV *h, SV *c) {
  SV **slot = hv_fetchs(h, "own_ua", 0);
  return pox_resolve_ua(aTHX_ pox_prov_get(aTHX_ h, "ua"), c, slot);
}

/* RFC 8414 / OIDC discovery, once, with issuer-equality + SSRF checks. */
static void pox_prov_ensure_endpoints(pTHX_ SV *self, SV *c) {
  HV *h = pox_prov_hv(aTHX_ self);
  const char *issuer;
  SV *ua, *meta;
  int status = 0;
  char url[1024];
  STRLEN il;
  const char *ip;
  SV *issv;

  if (pox_prov_str(aTHX_ h, "authorization_endpoint")
      && pox_prov_str(aTHX_ h, "token_endpoint"))
    return;
  if (!pox_prov_get(aTHX_ h, "discovery"))
    croak("oauth2 %s: no endpoints and no discovery", pox_prov_name(aTHX_ h));

  issv = pox_prov_get(aTHX_ h, "issuer");
  if (!issv) croak("oauth2 %s: discovery needs an issuer",
                   pox_prov_name(aTHX_ h));
  ip = SvPV_const(issv, il);
  if (il > 1 && ip[il - 1] == '/') il--;
  if (il + 40 >= sizeof url)
    croak("oauth2 %s: issuer too long", pox_prov_name(aTHX_ h));
  memcpy(url, ip, il);
  strcpy(url + il, "/.well-known/openid-configuration");

  ua = pox_prov_ua(aTHX_ h, c);
  if (!ua) croak("oauth2 %s: no user agent for discovery",
                 pox_prov_name(aTHX_ h));
  meta = pox_http_json(aTHX_ ua, "GET", url, NULL, NULL, &status);
  if (status != 200 || !meta || !SvROK(meta)
      || SvTYPE(SvRV(meta)) != SVt_PVHV)
    croak("oauth2 %s: discovery failed (%d)", pox_prov_name(aTHX_ h), status);
  {
    HV *m = (HV *)SvRV(meta);
    SV **mi = hv_fetchs(m, "issuer", 0);
    STRLEN ml;
    const char *mp;
    if (!mi || !*mi || !SvOK(*mi))
      croak("oauth2 %s: discovery has no issuer", pox_prov_name(aTHX_ h));
    mp = SvPV_const(*mi, ml);
    if (ml > 1 && mp[ml - 1] == '/') ml--;
    if (ml != il || memNE(mp, ip, il))
      croak("oauth2 %s: discovery issuer mismatch", pox_prov_name(aTHX_ h));

    {
      const char *fields[] = { "authorization_endpoint", "token_endpoint",
                               "jwks_uri", "userinfo_endpoint", NULL };
      int allow = pox_prov_get(aTHX_ h, "allow_local") ? 1 : 0;
      const char *why;
      int i;
      SV **mv;
      for (i = 0; fields[i]; i++) {
        if (pox_prov_str(aTHX_ h, fields[i])) continue;
        mv = hv_fetch(m, fields[i], (I32)strlen(fields[i]), 0);
        if (!mv || !*mv || !SvOK(*mv)) continue;
        if (!pox_safe_url(aTHX_ *mv, allow, &why))
          croak("oauth2 %s: discovery served an unsafe %s: %s",
                pox_prov_name(aTHX_ h), fields[i], why);
        (void)hv_store(h, fields[i], (I32)strlen(fields[i]),
                       newSVsv(*mv), 0);
      }
      mv = hv_fetchs(m, "authorization_response_iss_parameter_supported", 0);
      if (mv && *mv && SvTRUE(*mv))
        (void)hv_stores(h, "iss_param", newSViv(1));
    }
  }
  if (!pox_prov_str(aTHX_ h, "authorization_endpoint")
      || !pox_prov_str(aTHX_ h, "token_endpoint"))
    croak("oauth2 %s: discovery document is missing endpoints",
          pox_prov_name(aTHX_ h));
}

static SV *pox_prov_jwks(pTHX_ SV *self) {
  HV *h = pox_prov_hv(aTHX_ self);
  SV **cached = hv_fetchs(h, "_jwks", 0);
  SV *ju = pox_prov_get(aTHX_ h, "jwks_uri");
  HV *args;
  SV *jwks;
  if (cached && *cached && SvOK(*cached)) return *cached;
  if (!ju) return NULL;
  args = newHV();
  (void)hv_stores(args, "url", newSVsv(ju));
  if (pox_prov_get(aTHX_ h, "allow_local"))
    (void)hv_stores(args, "allow_local",
                    newSVsv(pox_prov_get(aTHX_ h, "allow_local")));
  if (pox_prov_get(aTHX_ h, "ua"))
    (void)hv_stores(args, "ua", newSVsv(pox_prov_get(aTHX_ h, "ua")));
  jwks = pox_jwks_new(aTHX_ args);
  SvREFCNT_dec((SV *)args);
  (void)hv_stores(h, "_jwks", jwks);
  return jwks;
}

/* Build the authorize URL. params: redirect_uri, state, nonce, challenge. */
static SV *pox_prov_authorize_url(pTHX_ SV *self, HV *p) {
  HV *h = pox_prov_hv(aTHX_ self);
  const char *endpoint = pox_prov_str(aTHX_ h, "authorization_endpoint");
  const char *scope = pox_prov_str(aTHX_ h, "scope");
  int oidc = pox_prov_flag(aTHX_ h, "oidc");
  SV *out;
  HV *q = newHV();
  AV *keys = newAV();
  SSize_t i, n;
  SV **v;
  int first = 1;

  sv_2mortal((SV *)q);
  sv_2mortal((SV *)keys);
  (void)hv_stores(q, "response_type", newSVpvs("code"));
  (void)hv_stores(q, "client_id",
                  newSVsv(pox_prov_get(aTHX_ h, "client_id")));
  if ((v = hv_fetchs(p, "redirect_uri", 0)) && *v)
    (void)hv_stores(q, "redirect_uri", newSVsv(*v));
  if ((v = hv_fetchs(p, "state", 0)) && *v)
    (void)hv_stores(q, "state", newSVsv(*v));
  if ((v = hv_fetchs(p, "challenge", 0)) && *v) {
    (void)hv_stores(q, "code_challenge", newSVsv(*v));
    (void)hv_stores(q, "code_challenge_method", newSVpvs("S256"));
  }
  if (scope && *scope)
    (void)hv_stores(q, "scope", newSVpv(scope, 0));
  if (oidc && (v = hv_fetchs(p, "nonce", 0)) && *v)
    (void)hv_stores(q, "nonce", newSVsv(*v));
  /* extra static authorize_params */
  if ((v = hv_fetchs(h, "authorize_params", 0)) && *v && SvROK(*v)
      && SvTYPE(SvRV(*v)) == SVt_PVHV) {
    HV *ap = (HV *)SvRV(*v);
    HE *he;
    hv_iterinit(ap);
    while ((he = hv_iternext(ap))) {
      STRLEN kl; const char *kp = HePV(he, kl);
      (void)hv_store(q, kp, (I32)kl, newSVsv(HeVAL(he)), 0);
    }
  }

  /* sorted query */
  {
    HE *he;
    hv_iterinit(q);
    while ((he = hv_iternext(q))) {
      STRLEN kl; const char *kp = HePV(he, kl);
      av_push(keys, newSVpvn(kp, kl));
    }
  }
  sortsv(AvARRAY(keys), av_count(keys), Perl_sv_cmp);

  out = newSVpv(endpoint, 0);
  sv_catpvn(out, strchr(endpoint, '?') ? "&" : "?", 1);
  n = av_count(keys);
  for (i = 0; i < n; i++) {
    SV *ksv = *av_fetch(keys, i, 0);
    STRLEN kl, vl;
    const char *kp = SvPV_const(ksv, kl);
    SV **vp = hv_fetch(q, kp, (I32)kl, 0);
    const char *vv = SvPV_const(*vp, vl);
    if (!first) sv_catpvs(out, "&");
    first = 0;
    sv_catsv(out, pox_uri_escape(aTHX_ kp, kl));
    sv_catpvs(out, "=");
    sv_catsv(out, pox_uri_escape(aTHX_ vv, vl));
  }
  return out;
}

/* The token endpoint call. extra_fields is an HV of grant-specific
 * fields; client auth is added per auth_method. Returns a Tokens object
 * or dies. */
static SV *pox_prov_token_call(pTHX_ SV *self, SV *c, HV *fields) {
  HV *h = pox_prov_hv(aTHX_ self);
  HV *headers = newHV();
  SV *secret = pox_prov_get(aTHX_ h, "client_secret");
  SV *ua, *body, *data;
  int status = 0;

  sv_2mortal((SV *)headers);
  (void)hv_stores(headers, "Content-Type",
                  newSVpvs("application/x-www-form-urlencoded"));
  if ((secret = pox_prov_get(aTHX_ h, "token_headers")) && SvROK(secret)
      && SvTYPE(SvRV(secret)) == SVt_PVHV) {
    HV *th = (HV *)SvRV(secret);
    HE *he;
    hv_iterinit(th);
    while ((he = hv_iternext(th))) {
      STRLEN kl; const char *kp = HePV(he, kl);
      (void)hv_store(headers, kp, (I32)kl, newSVsv(HeVAL(he)), 0);
    }
  }
  secret = pox_prov_get(aTHX_ h, "client_secret");
  if (secret) {
    const char *am = pox_prov_str(aTHX_ h, "auth_method");
    if (am && strcmp(am, "basic") == 0) {
      SV *id = pox_prov_get(aTHX_ h, "client_id");
      STRLEN il, sl;
      const char *ip = SvPV_const(id, il);
      const char *sp = SvPV_const(secret, sl);
      SV *raw = newSVsv(pox_uri_escape(aTHX_ ip, il));
      SV *b64;
      sv_catpvs(raw, ":");
      sv_catsv(raw, pox_uri_escape(aTHX_ sp, sl));
      sv_2mortal(raw);
      {
        STRLEN rl;
        const char *rp = SvPVbyte(raw, rl);
        eval_pv("require MIME::Base64;", FALSE);
        {
          dSP; int count; SV *enc = NULL;
          ENTER; SAVETMPS; PUSHMARK(SP);
          XPUSHs(sv_2mortal(newSVpvn(rp, rl)));
          XPUSHs(sv_2mortal(newSVpvs("")));
          PUTBACK;
          count = call_pv("MIME::Base64::encode_base64", G_SCALAR | G_EVAL);
          SPAGAIN;
          if (!SvTRUE(ERRSV) && count > 0) enc = SvREFCNT_inc(POPs);
          else if (count > 0) (void)POPs;
          PUTBACK; FREETMPS; LEAVE;
          if (enc) {
            b64 = newSVpvs("Basic ");
            sv_catsv(b64, enc);
            SvREFCNT_dec(enc);
            (void)hv_stores(headers, "Authorization", b64);
          }
        }
      }
    }
    else {
      (void)hv_stores(fields, "client_id",
                      newSVsv(pox_prov_get(aTHX_ h, "client_id")));
      (void)hv_stores(fields, "client_secret", newSVsv(secret));
    }
  }
  else {
    (void)hv_stores(fields, "client_id",
                    newSVsv(pox_prov_get(aTHX_ h, "client_id")));
  }

  ua = pox_prov_ua(aTHX_ h, c);
  if (!ua) croak("oauth2 %s: no user agent", pox_prov_name(aTHX_ h));
  body = pox_form_from_hv(aTHX_ fields);
  sv_2mortal(body);
  data = pox_http_json(aTHX_ ua, "POST",
                       pox_prov_str(aTHX_ h, "token_endpoint"),
                       headers, body, &status);
  if (status != 200 || !data || !SvROK(data)
      || SvTYPE(SvRV(data)) != SVt_PVHV
      || !hv_fetchs((HV *)SvRV(data), "access_token", 0)
      || !SvOK(*hv_fetchs((HV *)SvRV(data), "access_token", 0))) {
    const char *err = "invalid response";
    if (data && SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV) {
      SV **e = hv_fetchs((HV *)SvRV(data), "error", 0);
      if (e && *e && SvOK(*e)) err = SvPV_nolen(*e);
    }
    croak("oauth2 %s: token endpoint refused (%d: %s)",
          pox_prov_name(aTHX_ h), status, err);
  }
  {
    HV *args = newHV();
    static const char *k[] = { "access_token", "token_type", "expires_in",
                               "refresh_token", "id_token", "scope", NULL };
    HV *dh = (HV *)SvRV(data);
    int i;
    SV *tok;
    for (i = 0; k[i]; i++) {
      SV **v = hv_fetch(dh, k[i], (I32)strlen(k[i]), 0);
      if (v && *v) (void)hv_store(args, k[i], (I32)strlen(k[i]),
                                  newSVsv(*v), 0);
    }
    (void)hv_stores(args, "raw", newSVsv(data));
    tok = pox_tokens_new(aTHX_ args);
    SvREFCNT_dec((SV *)args);
    return tok;
  }
}

/* id_token verification: signature (JWKS or HS secret) + claims. Returns
 * a claims hashref (mortal) or NULL. */
static SV *pox_prov_verify_id_token(pTHX_ SV *self, SV *c, SV *id_token,
                                    SV *nonce) {
  HV *h = pox_prov_hv(aTHX_ self);
  SV *jwks = pox_prov_jwks(aTHX_ self);
  SV *key = NULL, *payload = NULL, *claims = NULL;
  SV *algs = pox_prov_get(aTHX_ h, "algs");

  if (!SvOK(id_token)) return NULL;

  if (jwks) {
    /* peek unverified header for kid, resolve key from the set */
    SV *header = NULL;
    dSP; int count;
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(id_token); PUTBACK;
    count = call_pv("Crypt::JWS::peek", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) header = SvREFCNT_inc(POPs);
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    if (!header || !SvROK(header) || SvTYPE(SvRV(header)) != SVt_PVHV) {
      SvREFCNT_dec(header);
      return NULL;
    }
    sv_2mortal(header);
    {
      SV **kid = hv_fetchs((HV *)SvRV(header), "kid", 0);
      key = pox_jwks_key_for(aTHX_ jwks, c, kid && *kid ? *kid : &PL_sv_undef);
    }
    if (!key) return NULL;
  }
  else if (pox_prov_get(aTHX_ h, "client_secret")) {
    /* HS only when the allowlist includes it */
    int hs = 0;
    if (algs && SvROK(algs) && SvTYPE(SvRV(algs)) == SVt_PVAV) {
      AV *a = (AV *)SvRV(algs);
      SSize_t i, n = av_count(a);
      for (i = 0; i < n; i++) {
        SV **e = av_fetch(a, i, 0);
        if (e && *e && strnEQ(SvPV_nolen(*e), "HS", 2)) hs = 1;
      }
    }
    if (!hs) return NULL;
    {
      dSP; int count; SV *k = NULL;
      ENTER; SAVETMPS; PUSHMARK(SP);
      XPUSHs(sv_2mortal(newSVpvs("Crypt::JWS::Key")));
      XPUSHs(pox_prov_get(aTHX_ h, "client_secret"));
      PUTBACK;
      count = call_method("from_secret", G_SCALAR | G_EVAL);
      SPAGAIN;
      if (!SvTRUE(ERRSV) && count > 0) k = SvREFCNT_inc(POPs);
      else if (count > 0) (void)POPs;
      PUTBACK; FREETMPS; LEAVE;
      if (!k) return NULL;
      key = sv_2mortal(k);
    }
  }
  else {
    return NULL;
  }

  /* Crypt::JWS::verify($token, $key, algs => \@algs) */
  {
    dSP; int count;
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(id_token);
    XPUSHs(key);
    XPUSHs(sv_2mortal(newSVpvs("algs")));
    XPUSHs(algs ? algs : sv_2mortal(newRV_noinc((SV *)newAV())));
    PUTBACK;
    count = call_pv("Crypt::JWS::verify", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) payload = SvREFCNT_inc(POPs);
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
  }
  if (!payload || !SvOK(payload)) { SvREFCNT_dec(payload); return NULL; }
  sv_2mortal(payload);

  {
    STRLEN pl;
    const char *pp = SvPVbyte(payload, pl);
    dSP; int count;
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvn(pp, pl))); PUTBACK;
    count = call_pv("File::Raw::JSON::file_json_decode", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) claims = SvREFCNT_inc(POPs);
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
  }
  if (!claims || !SvROK(claims) || SvTYPE(SvRV(claims)) != SVt_PVHV) {
    SvREFCNT_dec(claims);
    return NULL;
  }
  sv_2mortal(claims);
  if (!pox_verify_claims(aTHX_ (HV *)SvRV(claims),
                         pox_prov_get(aTHX_ h, "issuer")
                           ? pox_prov_get(aTHX_ h, "issuer") : &PL_sv_undef,
                         pox_prov_get(aTHX_ h, "client_id"),
                         nonce ? nonce : &PL_sv_undef,
                         (int)pox_hv_iv(aTHX_ h, "leeway", 60)))
    return NULL;
  return claims;
}

/* Authorization-code exchange: token call, then id_token verification
 * for OIDC providers (setting id_claims on the tokens). Returns a Tokens
 * object (mortal) or dies. */
static SV *pox_prov_exchange(pTHX_ SV *self, SV *c, SV *code,
                             SV *redirect_uri, SV *verifier, SV *nonce) {
  HV *h = pox_prov_hv(aTHX_ self);
  HV *fields = newHV();
  SV *tokens;
  sv_2mortal((SV *)fields);
  (void)hv_stores(fields, "grant_type", newSVpvs("authorization_code"));
  if (SvOK(code))         (void)hv_stores(fields, "code", newSVsv(code));
  if (SvOK(redirect_uri)) (void)hv_stores(fields, "redirect_uri",
                                          newSVsv(redirect_uri));
  if (SvOK(verifier))     (void)hv_stores(fields, "code_verifier",
                                          newSVsv(verifier));
  tokens = pox_prov_token_call(aTHX_ self, c, fields);
  sv_2mortal(tokens);
  if (pox_prov_flag(aTHX_ h, "oidc")) {
    SV *idt = sv_2mortal(pox_tokens_get(aTHX_ tokens, "id_token"));
    SV *claims = pox_prov_verify_id_token(aTHX_ self, c, idt, nonce);
    if (!claims)
      croak("oauth2 %s: id_token verification failed", pox_prov_name(aTHX_ h));
    (void)hv_stores((HV *)SvRV(tokens), "id_claims", newSVsv(claims));
  }
  return tokens;
}

/* Normalized identity: OIDC from verified id_token claims, plain OAuth2
 * from the provider's user API. Returns a hashref (mortal) or dies. */
static SV *pox_prov_identity(pTHX_ SV *self, SV *c, SV *tokens) {
  HV *h = pox_prov_hv(aTHX_ self);
  HV *out = newHV();

  if (pox_prov_flag(aTHX_ h, "oidc")) {
    SV *claims = pox_tokens_get(aTHX_ tokens, "id_claims");
    HV *cl;
    sv_2mortal(claims);
    if (!SvROK(claims) || SvTYPE(SvRV(claims)) != SVt_PVHV) {
      SvREFCNT_dec((SV *)out);
      croak("oauth2 %s: no verified id_token claims", pox_prov_name(aTHX_ h));
    }
    cl = (HV *)SvRV(claims);
    (void)hv_stores(out, "provider", newSVpv(pox_prov_name(aTHX_ h), 0));
    {
      static const char *m[] = { "sub", "email", "name", "picture", NULL };
      int i;
      for (i = 0; m[i]; i++) {
        SV **v = hv_fetch(cl, m[i], (I32)strlen(m[i]), 0);
        (void)hv_store(out, m[i], (I32)strlen(m[i]),
                       v && *v ? newSVsv(*v) : newSV(0), 0);
      }
      {
        SV **ev = hv_fetchs(cl, "email_verified", 0);
        (void)hv_stores(out, "email_verified",
                        newSViv(ev && *ev && SvTRUE(*ev) ? 1 : 0));
      }
    }
    (void)hv_stores(out, "raw", newSVsv(claims));
    return sv_2mortal(newRV_noinc((SV *)out));
  }

  /* plain OAuth2: fetch the user API with the access token */
  {
    const char *endpoint = pox_prov_str(aTHX_ h, "identity_endpoint");
    HV *headers = newHV();
    SV *access = pox_tokens_get(aTHX_ tokens, "access_token");
    SV *ua, *user, *emails = NULL, *mapped = NULL;
    int status = 0;

    sv_2mortal(access);
    sv_2mortal((SV *)headers);
    if (!endpoint) {
      SvREFCNT_dec((SV *)out);
      croak("oauth2 %s: no identity endpoint", pox_prov_name(aTHX_ h));
    }
    {
      SV *auth = newSVpvs("Bearer ");
      sv_catsv(auth, access);
      (void)hv_stores(headers, "Authorization", auth);
    }
    (void)hv_stores(headers, "Accept", newSVpvs("application/json"));

    ua = pox_prov_ua(aTHX_ h, c);
    user = pox_http_json(aTHX_ ua, "GET", endpoint, headers, NULL, &status);
    if (status != 200 || !user || !SvROK(user)
        || SvTYPE(SvRV(user)) != SVt_PVHV) {
      SvREFCNT_dec((SV *)out);
      croak("oauth2 %s: identity endpoint refused (%d)",
            pox_prov_name(aTHX_ h), status);
    }
    if (pox_prov_str(aTHX_ h, "emails_endpoint")) {
      int es = 0;
      emails = pox_http_json(aTHX_ ua, "GET",
                             pox_prov_str(aTHX_ h, "emails_endpoint"),
                             headers, NULL, &es);
      if (es != 200) emails = NULL;
    }

    {
      SV **mapcv = hv_fetchs(h, "identity_map", 0);
      if (mapcv && *mapcv && SvROK(*mapcv)
          && SvTYPE(SvRV(*mapcv)) == SVt_PVCV) {
        dSP; int count;
        ENTER; SAVETMPS; PUSHMARK(SP);
        XPUSHs(user);
        XPUSHs(emails ? emails : &PL_sv_undef);
        PUTBACK;
        count = call_sv(*mapcv, G_SCALAR | G_EVAL);
        SPAGAIN;
        if (!SvTRUE(ERRSV) && count > 0) mapped = SvREFCNT_inc(POPs);
        else if (count > 0) (void)POPs;
        PUTBACK; FREETMPS; LEAVE;
      }
    }
    (void)hv_stores(out, "provider", newSVpv(pox_prov_name(aTHX_ h), 0));
    if (mapped && SvROK(mapped) && SvTYPE(SvRV(mapped)) == SVt_PVHV) {
      HV *mh = (HV *)SvRV(mapped);
      HE *he;
      hv_iterinit(mh);
      while ((he = hv_iternext(mh))) {
        STRLEN kl; const char *kp = HePV(he, kl);
        (void)hv_store(out, kp, (I32)kl, newSVsv(HeVAL(he)), 0);
      }
    }
    else {
      HV *uh = (HV *)SvRV(user);
      SV **s = hv_fetchs(uh, "sub", 0);
      if (!s || !*s) s = hv_fetchs(uh, "id", 0);
      (void)hv_stores(out, "sub", s && *s ? newSVsv(*s) : newSV(0));
      {
        SV **e = hv_fetchs(uh, "email", 0);
        (void)hv_stores(out, "email", e && *e ? newSVsv(*e) : newSV(0));
      }
      {
        SV **nm = hv_fetchs(uh, "name", 0);
        (void)hv_stores(out, "name", nm && *nm ? newSVsv(*nm) : newSV(0));
      }
    }
    SvREFCNT_dec(mapped);
    (void)hv_stores(out, "raw", newSVsv(user));
    return sv_2mortal(newRV_noinc((SV *)out));
  }
}

/* Constructor: merge preset + config, validate, set defaults. */
static SV *pox_prov_new(pTHX_ const char *name, HV *cfg) {
  HV *self = newHV();
  HV *preset = NULL;
  SV *obj;
  SV **v;
  const char *why;

  v = hv_fetchs(cfg, "preset", 0);
  if (v && *v && SvOK(*v))
    preset = pox_preset(aTHX_ SvPV_nolen(*v));
  if (preset) {
    HE *he;
    hv_iterinit(preset);
    while ((he = hv_iternext(preset))) {
      STRLEN kl; const char *kp = HePV(he, kl);
      (void)hv_store(self, kp, (I32)kl, newSVsv(HeVAL(he)), 0);
    }
    SvREFCNT_dec((SV *)preset);
  }
  {
    HE *he;
    hv_iterinit(cfg);
    while ((he = hv_iternext(cfg))) {
      STRLEN kl; const char *kp = HePV(he, kl);
      if (kl == 6 && memEQ(kp, "preset", 6)) continue;
      (void)hv_store(self, kp, (I32)kl, newSVsv(HeVAL(he)), 0);
    }
  }
  (void)hv_stores(self, "name", newSVpv(name, 0));
  if (!pox_prov_str(aTHX_ self, "scope"))
    (void)hv_stores(self, "scope", newSVpvs(""));
  if (!pox_prov_str(aTHX_ self, "auth_method"))
    (void)hv_stores(self, "auth_method", newSVpvs("basic"));
  if (!pox_prov_get(aTHX_ self, "algs")) {
    AV *a = newAV();
    av_push(a, newSVpvs("RS256"));
    av_push(a, newSVpvs("ES256"));
    (void)hv_stores(self, "algs", newRV_noinc((SV *)a));
  }
  if (!pox_prov_get(aTHX_ self, "leeway"))
    (void)hv_stores(self, "leeway", newSViv(60));
  if (!pox_prov_get(aTHX_ self, "discovery"))
    (void)hv_stores(self, "discovery", newSViv(0));
  (void)hv_stores(self, "own_ua", newSV(0));

  if (!pox_prov_str(aTHX_ self, "client_id"))
    croak("oauth2 %s: a client_id is required", name);

  if (pox_prov_flag(aTHX_ self, "discovery")) {
    SV *iss = pox_prov_get(aTHX_ self, "issuer");
    if (!iss) croak("oauth2 %s: discovery needs an issuer", name);
    if (!pox_safe_url(aTHX_ iss,
                      pox_prov_get(aTHX_ self, "allow_local") ? 1 : 0, &why))
      croak("oauth2 %s: unsafe issuer: %s", name, why);
  }
  else {
    if (!pox_prov_str(aTHX_ self, "authorization_endpoint"))
      croak("oauth2 %s: an authorization_endpoint is required "
            "(or preset/discovery)", name);
    if (!pox_prov_str(aTHX_ self, "token_endpoint"))
      croak("oauth2 %s: a token_endpoint is required", name);
  }
  if (pox_prov_flag(aTHX_ self, "oidc")
      && !pox_prov_get(aTHX_ self, "client_secret")
      && !pox_prov_get(aTHX_ self, "public"))
    croak("oauth2 %s: oidc providers need a client_secret or a public "
          "client declaration", name);

  obj = newRV_noinc((SV *)self);
  sv_bless(obj, gv_stashpvs("Punk::OAuth2::Provider", GV_ADD));
  return obj;
}

#endif
