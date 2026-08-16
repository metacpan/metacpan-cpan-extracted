#ifndef POX_CHECKER_H
#define POX_CHECKER_H

#include "pox_abi.h"
#include "pox_http.h"
#include "pox_verify.h"
#include "pox_jwks.h"
#include "pox_util.h"

/* Resource-server checkers: validate a Bearer credential and return the
 * claims (mortal hashref) or NULL with *reason set to "invalid_token" or
 * "insufficient_scope". A checker is a blessed config HV (kind = "jwt" or
 * "introspect"). */

static HV *pox_chk_hv(pTHX_ SV *self) {
  if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
    croak("Punk::OAuth2::Checker: not a checker");
  return (HV *)SvRV(self);
}
static SV *pox_chk_get(pTHX_ HV *h, const char *k) {
  SV **v = hv_fetch(h, k, (I32)strlen(k), 0);
  return (v && *v && SvOK(*v)) ? *v : NULL;
}

/* The token's scope claim covers every required scope. Accepts a
 * space-separated "scope" string or a "scp" array. required is an AV of
 * scope strings (may be NULL/empty => always satisfied). */
static int pox_scope_ok(pTHX_ HV *claims, AV *required) {
  SSize_t rn = required ? av_count(required) : 0;
  SV **sc;
  HV *have = newHV();
  SSize_t i;
  int ok = 1;
  if (rn == 0) return 1;
  sv_2mortal((SV *)have);

  if ((sc = hv_fetchs(claims, "scope", 0)) && *sc && SvOK(*sc)
      && !SvROK(*sc)) {
    STRLEN sl;
    const char *sp = SvPV_const(*sc, sl);
    STRLEN a = 0, b;
    for (b = 0; b <= sl; b++) {
      if (b == sl || sp[b] == ' ') {
        if (b > a) (void)hv_store(have, sp + a, (I32)(b - a),
                                  &PL_sv_yes, 0);
        a = b + 1;
      }
    }
  }
  else if ((sc = hv_fetchs(claims, "scp", 0)) && *sc && SvROK(*sc)
           && SvTYPE(SvRV(*sc)) == SVt_PVAV) {
    AV *av = (AV *)SvRV(*sc);
    SSize_t n = av_count(av), j;
    for (j = 0; j < n; j++) {
      SV **e = av_fetch(av, j, 0);
      STRLEN el;
      const char *ep;
      if (!e || !*e || !SvOK(*e)) continue;
      ep = SvPV_const(*e, el);
      (void)hv_store(have, ep, (I32)el, &PL_sv_yes, 0);
    }
  }

  for (i = 0; i < rn; i++) {
    SV **r = av_fetch(required, i, 0);
    STRLEN rl;
    const char *rp;
    if (!r || !*r || !SvOK(*r)) continue;
    rp = SvPV_const(*r, rl);
    if (!hv_exists(have, rp, (I32)rl)) { ok = 0; break; }
  }
  return ok;
}

/* Access-token claim checks: iss exact (if configured), aud contains the
 * audience (if configured), exp/nbf with leeway. */
static int pox_at_claims_ok(pTHX_ HV *claims, SV *issuer, SV *audience,
                            int leeway) {
  IV now = (IV)time(NULL);
  SV **v;

  if (SvOK(issuer) && !pox_hv_str_eq(aTHX_ claims, "iss", issuer))
    return 0;

  if (SvOK(audience)) {
    STRLEN al;
    const char *ap = SvPV_const(audience, al);
    int found = 0;
    v = hv_fetchs(claims, "aud", 0);
    if (!v || !*v || !SvOK(*v)) return 0;
    if (SvROK(*v) && SvTYPE(SvRV(*v)) == SVt_PVAV) {
      AV *av = (AV *)SvRV(*v);
      SSize_t i, n = av_count(av);
      for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        STRLEN el;
        const char *ep;
        if (!e || !*e || !SvOK(*e)) continue;
        ep = SvPV_const(*e, el);
        if (el == al && memEQ(ep, ap, al)) found = 1;
      }
    }
    else {
      STRLEN vl;
      const char *vp = SvPV_const(*v, vl);
      found = (vl == al && memEQ(vp, ap, al));
    }
    if (!found) return 0;
  }

  v = hv_fetchs(claims, "exp", 0);
  if (!v || !*v || !SvOK(*v)) return 0;
  if (now >= SvIV(*v) + leeway) return 0;

  v = hv_fetchs(claims, "nbf", 0);
  if (v && *v && SvOK(*v) && SvIV(*v) > now + leeway) return 0;

  return 1;
}

/* Decode a JSON payload SV into a claims hashref (mortal) or NULL. */
static SV *pox_decode_json_hash(pTHX_ SV *bytes) {
  STRLEN bl;
  const char *bp;
  SV *out = NULL;
  dSP;
  int count;
  if (!SvOK(bytes)) return NULL;
  bp = SvPVbyte(bytes, bl);
  ENTER; SAVETMPS; PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVpvn(bp, bl))); PUTBACK;
  count = call_pv("File::Raw::JSON::file_json_decode", G_SCALAR | G_EVAL);
  SPAGAIN;
  if (!SvTRUE(ERRSV) && count > 0) out = SvREFCNT_inc(POPs);
  else if (count > 0) (void)POPs;
  PUTBACK; FREETMPS; LEAVE;
  if (!out || !SvROK(out) || SvTYPE(SvRV(out)) != SVt_PVHV) {
    SvREFCNT_dec(out);
    return NULL;
  }
  return sv_2mortal(out);
}

/* jwt checker. cred is the bearer token. Returns claims (mortal) or NULL
 * with *reason set. */
static SV *pox_checker_jwt(pTHX_ HV *cfg, SV *cred, SV *c, AV *required,
                           const char **reason) {
  SV *algs = pox_chk_get(aTHX_ cfg, "algs");
  SV *key = NULL, *payload = NULL, *claims;
  *reason = "invalid_token";

  if (!SvOK(cred) || !SvCUR(cred)) return NULL;

  /* resolve the verifying key: JWKS by kid, or a static key */
  {
    SV *jwks = pox_chk_get(aTHX_ cfg, "jwks");
    SV *stat = pox_chk_get(aTHX_ cfg, "key");
    if (jwks) {
      SV *header = NULL;
      dSP; int count;
      ENTER; SAVETMPS; PUSHMARK(SP);
      XPUSHs(cred); PUTBACK;
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
        key = pox_jwks_key_for(aTHX_ jwks, c,
                               kid && *kid ? *kid : &PL_sv_undef);
      }
      if (!key) return NULL;
    }
    else if (stat) {
      key = stat;
    }
    else {
      return NULL;
    }
  }

  {
    dSP; int count;
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(cred);
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

  claims = pox_decode_json_hash(aTHX_ payload);
  if (!claims) return NULL;

  if (!pox_at_claims_ok(aTHX_ (HV *)SvRV(claims),
                        pox_chk_get(aTHX_ cfg, "issuer")
                          ? pox_chk_get(aTHX_ cfg, "issuer") : &PL_sv_undef,
                        pox_chk_get(aTHX_ cfg, "audience")
                          ? pox_chk_get(aTHX_ cfg, "audience") : &PL_sv_undef,
                        (int)pox_hv_iv(aTHX_ cfg, "leeway", 60)))
    return NULL;

  if (!pox_scope_ok(aTHX_ (HV *)SvRV(claims), required)) {
    *reason = "insufficient_scope";
    return NULL;
  }
  *reason = NULL;
  return claims;
}

/* introspection checker. POSTs the token, caches by sha256(token). */
static SV *pox_checker_introspect(pTHX_ HV *cfg, SV *cred, SV *c,
                                  AV *required, const char **reason) {
  SV *url = pox_chk_get(aTHX_ cfg, "url");
  SV *ua, *data;
  HV *headers, *fields, *cache;
  int status = 0;
  IV ttl = pox_hv_iv(aTHX_ cfg, "cache_ttl", 0);
  SV *digest = NULL, *ckey = NULL;
  *reason = "invalid_token";

  if (!SvOK(cred) || !SvCUR(cred) || !url) return NULL;

  /* cache lookup keyed by sha256(token) */
  if (ttl > 0) {
    STRLEN tl;
    const char *tp = SvPVbyte(cred, tl);
    digest = pox_sha256(aTHX_ (const unsigned char *)tp, tl);
    ckey = pox_b64url(aTHX_ (const unsigned char *)SvPVX(digest),
                      SvCUR(digest));
    cache = (pox_chk_get(aTHX_ cfg, "_cache")
             && SvROK(pox_chk_get(aTHX_ cfg, "_cache")))
      ? (HV *)SvRV(pox_chk_get(aTHX_ cfg, "_cache")) : NULL;
    if (!cache) {
      cache = newHV();
      (void)hv_stores(cfg, "_cache", newRV_noinc((SV *)cache));
    }
    {
      STRLEN kl;
      const char *kp = SvPV_const(ckey, kl);
      SV **hit = hv_fetch(cache, kp, (I32)kl, 0);
      if (hit && *hit && SvROK(*hit)
          && SvTYPE(SvRV(*hit)) == SVt_PVAV) {
        AV *ent = (AV *)SvRV(*hit);
        SV **exp = av_fetch(ent, 0, 0);
        SV **cl  = av_fetch(ent, 1, 0);
        if (exp && *exp && SvIV(*exp) > (IV)time(NULL) && cl && *cl) {
          if (!pox_scope_ok(aTHX_ (HV *)SvRV(*cl), required)) {
            *reason = "insufficient_scope";
            return NULL;
          }
          *reason = NULL;
          return sv_2mortal(SvREFCNT_inc(*cl));
        }
      }
    }
  }

  headers = newHV();
  fields = newHV();
  sv_2mortal((SV *)headers);
  sv_2mortal((SV *)fields);
  (void)hv_stores(headers, "Content-Type",
                  newSVpvs("application/x-www-form-urlencoded"));
  (void)hv_stores(headers, "Accept", newSVpvs("application/json"));
  {
    SV *id = pox_chk_get(aTHX_ cfg, "client_id");
    SV *sec = pox_chk_get(aTHX_ cfg, "client_secret");
    if (id && sec) {
      STRLEN il, sl;
      const char *ip = SvPV_const(id, il);
      const char *sp = SvPV_const(sec, sl);
      SV *raw = newSVsv(pox_uri_escape(aTHX_ ip, il));
      sv_catpvs(raw, ":");
      sv_catsv(raw, pox_uri_escape(aTHX_ sp, sl));
      sv_2mortal(raw);
      {
        STRLEN rl; const char *rp = SvPVbyte(raw, rl);
        dSP; int count; SV *enc = NULL;
        eval_pv("require MIME::Base64;", FALSE);
        ENTER; SAVETMPS; PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvn(rp, rl)));
        XPUSHs(sv_2mortal(newSVpvs(""))); PUTBACK;
        count = call_pv("MIME::Base64::encode_base64", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (!SvTRUE(ERRSV) && count > 0) enc = SvREFCNT_inc(POPs);
        else if (count > 0) (void)POPs;
        PUTBACK; FREETMPS; LEAVE;
        if (enc) {
          SV *a = newSVpvs("Basic ");
          sv_catsv(a, enc);
          SvREFCNT_dec(enc);
          (void)hv_stores(headers, "Authorization", a);
        }
      }
    }
  }
  (void)hv_stores(fields, "token", newSVsv(cred));
  (void)hv_stores(fields, "token_type_hint", newSVpvs("access_token"));

  {
    SV **slot = hv_fetchs(cfg, "own_ua", 0);
    ua = pox_resolve_ua(aTHX_ pox_chk_get(aTHX_ cfg, "ua"), c, slot);
  }
  if (!ua) return NULL;
  {
    SV *body = sv_2mortal(pox_form_from_hv(aTHX_ fields));
    data = pox_http_json(aTHX_ ua, "POST", SvPV_nolen(url), headers, body,
                         &status);
  }
  if (status != 200 || !data || !SvROK(data)
      || SvTYPE(SvRV(data)) != SVt_PVHV)
    return NULL;
  {
    SV **active = hv_fetchs((HV *)SvRV(data), "active", 0);
    if (!active || !*active || !SvTRUE(*active)) return NULL;
  }

  if (ttl > 0 && ckey) {
    AV *ent = newAV();
    STRLEN kl;
    const char *kp = SvPV_const(ckey, kl);
    av_push(ent, newSViv((IV)time(NULL) + ttl));
    av_push(ent, SvREFCNT_inc(data));
    (void)hv_store((HV *)SvRV(*hv_fetchs(cfg, "_cache", 0)),
                   kp, (I32)kl, newRV_noinc((SV *)ent), 0);
  }

  if (!pox_scope_ok(aTHX_ (HV *)SvRV(data), required)) {
    *reason = "insufficient_scope";
    return NULL;
  }
  *reason = NULL;
  return data;   /* already mortal from pox_http_json */
}

static SV *pox_checker_check(pTHX_ SV *self, SV *cred, SV *c, AV *required,
                             const char **reason) {
  HV *cfg = pox_chk_hv(aTHX_ self);
  const char *kind = pox_chk_get(aTHX_ cfg, "kind")
    ? SvPV_nolen(pox_chk_get(aTHX_ cfg, "kind")) : "jwt";
  if (strEQ(kind, "introspect"))
    return pox_checker_introspect(aTHX_ cfg, cred, c, required, reason);
  return pox_checker_jwt(aTHX_ cfg, cred, c, required, reason);
}

/* The Bearer credential from $c->req->header('Authorization'), or NULL. */
static SV *pox_bearer(pTHX_ SV *c) {
  SV *req = NULL, *auth = NULL;
  dSP; int count;
  ENTER; SAVETMPS; PUSHMARK(SP); XPUSHs(c); PUTBACK;
  count = call_method("req", G_SCALAR | G_EVAL);
  SPAGAIN;
  if (!SvTRUE(ERRSV) && count > 0) req = SvREFCNT_inc(POPs);
  else if (count > 0) (void)POPs;
  PUTBACK; FREETMPS; LEAVE;
  if (!req) return NULL;
  sv_2mortal(req);
  ENTER; SAVETMPS; PUSHMARK(SP);
  XPUSHs(req);
  XPUSHs(sv_2mortal(newSVpvs("Authorization")));
  PUTBACK;
  count = call_method("header", G_SCALAR | G_EVAL);
  SPAGAIN;
  if (!SvTRUE(ERRSV) && count > 0) auth = SvREFCNT_inc(POPs);
  else if (count > 0) (void)POPs;
  PUTBACK; FREETMPS; LEAVE;
  if (!auth) return NULL;
  sv_2mortal(auth);
  if (!SvOK(auth)) return NULL;
  {
    STRLEN al;
    const char *ap = SvPV_const(auth, al);
    if (al > 7 && (ap[0] == 'B' || ap[0] == 'b')
        && strnEQ(ap + 1, "earer ", 6))
      return sv_2mortal(newSVpvn(ap + 7, al - 7));
  }
  return NULL;
}

/* $c->stash as an HV*, or NULL. */
static HV *pox_stash(pTHX_ SV *c) {
  SV *st = NULL;
  dSP; int count;
  ENTER; SAVETMPS; PUSHMARK(SP); XPUSHs(c); PUTBACK;
  count = call_method("stash", G_SCALAR | G_EVAL);
  SPAGAIN;
  if (!SvTRUE(ERRSV) && count > 0) st = SvREFCNT_inc(POPs);
  else if (count > 0) (void)POPs;
  PUTBACK; FREETMPS; LEAVE;
  if (!st || !SvROK(st) || SvTYPE(SvRV(st)) != SVt_PVHV) {
    SvREFCNT_dec(st);
    return NULL;
  }
  sv_2mortal(st);
  return (HV *)SvRV(st);
}

/* RFC 6750 WWW-Authenticate value for a denial. */
static SV *pox_www_authenticate(pTHX_ const char *realm, const char *error,
                                AV *scopes) {
  SV *out = newSVpvs("Bearer realm=\"");
  sv_catpv(out, realm ? realm : "api");
  sv_catpvs(out, "\"");
  if (error) {
    sv_catpvs(out, ", error=\"");
    sv_catpv(out, error);
    sv_catpvs(out, "\"");
    if (strEQ(error, "insufficient_scope") && scopes && av_count(scopes)) {
      SSize_t i, n = av_count(scopes);
      sv_catpvs(out, ", scope=\"");
      for (i = 0; i < n; i++) {
        SV **e = av_fetch(scopes, i, 0);
        if (!e || !*e) continue;
        if (i) sv_catpvs(out, " ");
        sv_catsv(out, *e);
      }
      sv_catpvs(out, "\"");
    }
  }
  return out;
}

/* The checker body: validate, stash claims under auth.<scheme> on
 * success or the reason under punk.oauth2.error on failure. Returns a
 * mortal claims hashref or &PL_sv_no. This is what a checker coderef
 * runs. */
static SV *pox_do_check(pTHX_ SV *self, SV *cred, SV *c, AV *required) {
  const char *reason = NULL;
  SV *claims = pox_checker_check(aTHX_ self, cred, c, required, &reason);
  HV *stash = pox_stash(aTHX_ c);
  if (claims) {
    if (stash) {
      SV **au = hv_fetchs(stash, "auth", 1);
      HV *auth;
      const char *scheme = SvPV_nolen(
        *hv_fetchs(pox_chk_hv(aTHX_ self), "scheme", 0));
      if (!*au || !SvROK(*au) || SvTYPE(SvRV(*au)) != SVt_PVHV) {
        SvREFCNT_dec(*au);
        *au = newRV_noinc((SV *)newHV());
      }
      auth = (HV *)SvRV(*au);
      (void)hv_store(auth, scheme, (I32)strlen(scheme),
                     SvREFCNT_inc(claims), 0);
    }
    return claims;
  }
  if (stash)
    (void)hv_stores(stash, "punk.oauth2.error",
                    newSVpv(reason ? reason : "invalid_token", 0));
  return &PL_sv_no;
}

/* The guard body: extract Bearer, invoke the checker coderef, return
 * undef (pass) or an RFC 6750 denial triplet (owned). */
static SV *pox_do_guard(pTHX_ SV *checker, SV *c, AV *scav,
                        const char *realm) {
  SV *cred = pox_bearer(aTHX_ c);
  SV *result = NULL;

  if (!cred) {
    SV *wa = sv_2mortal(pox_www_authenticate(aTHX_ realm, NULL, NULL));
    AV *hdrs = newAV(), *body = newAV(), *trip = newAV();
    av_push(hdrs, newSVpvs("Content-Type"));
    av_push(hdrs, newSVpvs("application/json"));
    av_push(hdrs, newSVpvs("WWW-Authenticate"));
    av_push(hdrs, SvREFCNT_inc(wa));
    av_push(body, newSVpvs("{\"error\":\"invalid_request\"}"));
    av_push(trip, newSViv(401));
    av_push(trip, newRV_noinc((SV *)hdrs));
    av_push(trip, newRV_noinc((SV *)body));
    return newRV_noinc((SV *)trip);
  }
  {
    dSP; int count;
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(cred);
    XPUSHs(c);
    XPUSHs(&PL_sv_undef);
    XPUSHs(scav ? sv_2mortal(newRV_inc((SV *)scav)) : &PL_sv_undef);
    PUTBACK;
    count = call_sv(checker, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) result = SvREFCNT_inc(POPs);
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
  }
  if (result && SvTRUE(result)) { SvREFCNT_dec(result); return &PL_sv_undef; }
  SvREFCNT_dec(result);
  {
    HV *stash = pox_stash(aTHX_ c);
    SV **er = stash ? hv_fetchs(stash, "punk.oauth2.error", 0) : NULL;
    const char *reason = (er && *er && SvOK(*er))
      ? SvPV_nolen(*er) : "invalid_token";
    int insufficient = strEQ(reason, "insufficient_scope");
    SV *wa = sv_2mortal(pox_www_authenticate(aTHX_ realm, reason, scav));
    AV *hdrs = newAV(), *body = newAV(), *trip = newAV();
    SV *jb = newSVpvs("{\"error\":\"");
    sv_catpv(jb, reason);
    sv_catpvs(jb, "\"}");
    av_push(hdrs, newSVpvs("Content-Type"));
    av_push(hdrs, newSVpvs("application/json"));
    av_push(hdrs, newSVpvs("WWW-Authenticate"));
    av_push(hdrs, SvREFCNT_inc(wa));
    av_push(body, jb);
    av_push(trip, newSViv(insufficient ? 403 : 401));
    av_push(trip, newRV_noinc((SV *)hdrs));
    av_push(trip, newRV_noinc((SV *)body));
    return newRV_noinc((SV *)trip);
  }
}

/* ---- closures: real coderefs that capture the checker config -----------
 * A checker and a guard are coderefs the OpenAPI map and the router call.
 * Each is an anonymous XS CV whose CvXSUBANY holds the captured SV; the
 * capture lives for the process (checkers are built at boot), matching
 * the house pattern for process-lifetime callbacks. */

XS_INTERNAL(pox_check_cb);
XS_INTERNAL(pox_check_cb) {
  dXSARGS;
  SV *self = (SV *)CvXSUBANY(cv).any_ptr;
  SV *cred = items > 0 ? ST(0) : &PL_sv_undef;
  SV *c    = items > 1 ? ST(1) : &PL_sv_undef;
  AV *required = (items > 3 && SvROK(ST(3))
                  && SvTYPE(SvRV(ST(3))) == SVt_PVAV)
    ? (AV *)SvRV(ST(3)) : NULL;
  SV *r = pox_do_check(aTHX_ self, cred, c, required);
  ST(0) = r;   /* mortal claims or &PL_sv_no */
  XSRETURN(1);
}

XS_INTERNAL(pox_guard_cb);
XS_INTERNAL(pox_guard_cb) {
  dXSARGS;
  HV *cap = (HV *)CvXSUBANY(cv).any_ptr;
  SV *c = items > 0 ? ST(0) : &PL_sv_undef;
  SV **chk = hv_fetchs(cap, "checker", 0);
  SV **sc  = hv_fetchs(cap, "scopes", 0);
  SV **rl  = hv_fetchs(cap, "realm", 0);
  AV *scav = (sc && *sc && SvROK(*sc) && SvTYPE(SvRV(*sc)) == SVt_PVAV)
    ? (AV *)SvRV(*sc) : NULL;
  const char *realm = (rl && *rl && SvOK(*rl)) ? SvPV_nolen(*rl) : "api";
  SV *r = pox_do_guard(aTHX_ chk ? *chk : &PL_sv_undef, c, scav, realm);
  ST(0) = sv_2mortal(r);
  XSRETURN(1);
}

static SV *pox_make_closure(pTHX_ XSUBADDR_t fn, void *capture) {
  CV *cv = newXS(NULL, fn, __FILE__);
  CvXSUBANY(cv).any_ptr = capture;   /* process-lifetime capture */
  return newRV_noinc((SV *)cv);
}

#endif
