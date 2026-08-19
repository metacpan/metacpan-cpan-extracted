#ifndef POX_SERVER_H
#define POX_SERVER_H

#include "pox_abi.h"
#include "pox_util.h"
#include "pox_store.h"
#include "pox_checker.h"   /* pox_bearer, request helpers */

/* The authorization server. A blessed config HV holds: issuer, store,
 * key (Crypt::JWS::Key), kid, prefix, at_ttl, rt_ttl, oidc,
 * authenticate, consent. Endpoint handlers build responses as PSGI
 * triplets or via $c helpers. All protocol logic is here in C. */

static HV *pox_srv_hv(pTHX_ SV *self) {
  if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
    croak("Punk::OAuth2::Server: not a server");
  return (HV *)SvRV(self);
}
static SV *pox_srv_get(pTHX_ HV *h, const char *k) {
  SV **v = hv_fetch(h, k, (I32)strlen(k), 0);
  return (v && *v && SvOK(*v)) ? *v : NULL;
}
static const char *pox_srv_str(pTHX_ HV *h, const char *k) {
  SV *v = pox_srv_get(aTHX_ h, k);
  return v ? SvPV_nolen(v) : NULL;
}

/* ---- request helpers ------------------------------------------------------ */

/* $c->req->query as an HV*, or NULL. */
static HV *pox_req_query(pTHX_ SV *c) {
  SV *req = NULL, *q = NULL;
  dSP; int count;
  ENTER; SAVETMPS; PUSHMARK(SP); XPUSHs(c); PUTBACK;
  count = call_method("req", G_SCALAR | G_EVAL); SPAGAIN;
  if (!SvTRUE(ERRSV) && count > 0) req = SvREFCNT_inc(POPs);
  else if (count > 0) (void)POPs;
  PUTBACK; FREETMPS; LEAVE;
  if (!req) return NULL;
  sv_2mortal(req);
  ENTER; SAVETMPS; PUSHMARK(SP); XPUSHs(req); PUTBACK;
  count = call_method("query", G_SCALAR | G_EVAL); SPAGAIN;
  if (!SvTRUE(ERRSV) && count > 0) q = SvREFCNT_inc(POPs);
  else if (count > 0) (void)POPs;
  PUTBACK; FREETMPS; LEAVE;
  if (!q || !SvROK(q) || SvTYPE(SvRV(q)) != SVt_PVHV) { SvREFCNT_dec(q); return NULL; }
  sv_2mortal(q);
  return (HV *)SvRV(q);
}

/* $c->req->body as a mortal SV, or NULL. */
static SV *pox_req_body(pTHX_ SV *c) {
  SV *req = NULL, *b = NULL;
  dSP; int count;
  ENTER; SAVETMPS; PUSHMARK(SP); XPUSHs(c); PUTBACK;
  count = call_method("req", G_SCALAR | G_EVAL); SPAGAIN;
  if (!SvTRUE(ERRSV) && count > 0) req = SvREFCNT_inc(POPs);
  else if (count > 0) (void)POPs;
  PUTBACK; FREETMPS; LEAVE;
  if (!req) return NULL;
  sv_2mortal(req);
  ENTER; SAVETMPS; PUSHMARK(SP); XPUSHs(req); PUTBACK;
  count = call_method("body", G_SCALAR | G_EVAL); SPAGAIN;
  if (!SvTRUE(ERRSV) && count > 0) b = SvREFCNT_inc(POPs);
  else if (count > 0) (void)POPs;
  PUTBACK; FREETMPS; LEAVE;
  if (!b) return NULL;
  return sv_2mortal(b);
}

/* Parse an x-www-form-urlencoded body into a fresh HV (mortal). */
static HV *pox_parse_form(pTHX_ SV *bodysv) {
  HV *out = newHV();
  STRLEN n;
  const char *s;
  STRLEN i, kstart = 0, eq = 0;
  int have_eq = 0;
  sv_2mortal((SV *)out);
  if (!bodysv || !SvOK(bodysv)) return out;
  s = SvPV_const(bodysv, n);
  for (i = 0; i <= n; i++) {
    if (i == n || s[i] == '&') {
      if (i > kstart) {
        STRLEN klen = have_eq ? eq - kstart : i - kstart;
        const char *vp = have_eq ? s + eq + 1 : "";
        STRLEN vlen = have_eq ? i - eq - 1 : 0;
        SV *kd = pox_urldecode(aTHX_ s + kstart, klen);
        SV *vd = pox_urldecode(aTHX_ vp, vlen);
        (void)hv_store_ent(out, kd, SvREFCNT_inc(vd), 0);
      }
      kstart = i + 1; have_eq = 0;
    }
    else if (s[i] == '=' && !have_eq) { eq = i; have_eq = 1; }
  }
  return out;
}

/* form field or query field as a mortal SV, or NULL. */
static SV *pox_field(pTHX_ HV *h, const char *k) {
  SV **v = h ? hv_fetch(h, k, (I32)strlen(k), 0) : NULL;
  return (v && *v && SvOK(*v)) ? *v : NULL;
}

/* ---- responses ------------------------------------------------------------ */

/* A JSON PSGI triplet (owned) with Cache-Control: no-store. */
static SV *pox_json_response(pTHX_ int status, SV *data) {
  SV *body;
  AV *hdrs = newAV(), *barr = newAV(), *trip = newAV();
  dSP; int count; SV *ret;
  ENTER; SAVETMPS; PUSHMARK(SP); XPUSHs(data); PUTBACK;
  count = call_pv("File::Raw::JSON::file_json_encode", G_SCALAR | G_EVAL);
  SPAGAIN;
  ret = count > 0 ? POPs : NULL;   /* always balance the stack */
  body = (ret && !SvTRUE(ERRSV)) ? SvREFCNT_inc(ret) : newSVpvs("{}");
  PUTBACK; FREETMPS; LEAVE;
  av_push(hdrs, newSVpvs("Content-Type"));
  av_push(hdrs, newSVpvs("application/json"));
  av_push(hdrs, newSVpvs("Cache-Control"));
  av_push(hdrs, newSVpvs("no-store"));
  av_push(hdrs, newSVpvs("Pragma"));
  av_push(hdrs, newSVpvs("no-cache"));
  av_push(barr, body);
  av_push(trip, newSViv(status));
  av_push(trip, newRV_noinc((SV *)hdrs));
  av_push(trip, newRV_noinc((SV *)barr));
  return newRV_noinc((SV *)trip);
}

static SV *pox_error_json(pTHX_ int status, const char *error,
                          const char *desc) {
  HV *e = newHV();
  sv_2mortal((SV *)e);
  (void)hv_stores(e, "error", newSVpv(error, 0));
  if (desc) (void)hv_stores(e, "error_description", newSVpv(desc, 0));
  return pox_json_response(aTHX_ status, sv_2mortal(newRV_inc((SV *)e)));
}

/* A plain-text error page (for /authorize failures that must NOT
 * redirect). */
static SV *pox_text_response(pTHX_ int status, const char *text) {
  AV *hdrs = newAV(), *barr = newAV(), *trip = newAV();
  av_push(hdrs, newSVpvs("Content-Type"));
  av_push(hdrs, newSVpvs("text/plain; charset=utf-8"));
  av_push(barr, newSVpv(text, 0));
  av_push(trip, newSViv(status));
  av_push(trip, newRV_noinc((SV *)hdrs));
  av_push(trip, newRV_noinc((SV *)barr));
  return newRV_noinc((SV *)trip);
}

/* A 302 redirect triplet to url (owned). */
static SV *pox_redirect_response(pTHX_ SV *url) {
  AV *hdrs = newAV(), *barr = newAV(), *trip = newAV();
  av_push(hdrs, newSVpvs("Location"));
  av_push(hdrs, SvREFCNT_inc(url));
  av_push(hdrs, newSVpvs("Content-Length"));
  av_push(hdrs, newSVpvs("0"));
  av_push(trip, newSViv(302));
  av_push(trip, newRV_noinc((SV *)hdrs));
  av_push(trip, newRV_noinc((SV *)barr));
  return newRV_noinc((SV *)trip);
}

/* ---- store method calls --------------------------------------------------- */

static SV *pox_store_call(pTHX_ SV *store, const char *meth,
                          SV **args, int nargs) {
  dSP; int count, i; SV *r = NULL;
  ENTER; SAVETMPS; PUSHMARK(SP);
  EXTEND(SP, nargs + 1);
  PUSHs(store);
  for (i = 0; i < nargs; i++) PUSHs(args[i]);
  PUTBACK;
  count = call_method(meth, G_SCALAR | G_EVAL);
  SPAGAIN;
  if (!SvTRUE(ERRSV) && count > 0) r = SvREFCNT_inc(POPs);
  else if (count > 0) (void)POPs;
  PUTBACK; FREETMPS; LEAVE;
  return r ? sv_2mortal(r) : NULL;
}

/* ---- JWT access token ----------------------------------------------------- */

/* Mint a JWT access token (Crypt::JWS::sign) with the standard claims. */
static SV *pox_mint_at(pTHX_ HV *srv, SV *client_id, SV *user_id,
                       const char *scope) {
  HV *claims = newHV();
  IV now = (IV)time(NULL);
  IV ttl = pox_hv_iv(aTHX_ srv, "at_ttl", 600);
  SV *jti = pox_random_b64(aTHX_ 16);
  SV *key = pox_srv_get(aTHX_ srv, "key");
  SV *kid = pox_srv_get(aTHX_ srv, "kid");
  SV *payload, *token = NULL;
  sv_2mortal((SV *)claims);
  (void)hv_stores(claims, "iss", newSVsv(pox_srv_get(aTHX_ srv, "issuer")));
  (void)hv_stores(claims, "sub",
                  user_id && SvOK(user_id) ? newSVsv(user_id)
                                           : newSVsv(client_id));
  (void)hv_stores(claims, "aud", newSVsv(pox_srv_get(aTHX_ srv, "issuer")));
  (void)hv_stores(claims, "client_id", newSVsv(client_id));
  (void)hv_stores(claims, "exp", newSViv(now + ttl));
  (void)hv_stores(claims, "iat", newSViv(now));
  (void)hv_stores(claims, "jti", newSVsv(jti));
  if (scope && *scope) (void)hv_stores(claims, "scope", newSVpv(scope, 0));

  /* payload = File::Raw::JSON::file_json_encode(\%claims) */
  {
    dSP; int count;
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(sv_2mortal(newRV_inc((SV *)claims))); PUTBACK;
    count = call_pv("File::Raw::JSON::file_json_encode", G_SCALAR | G_EVAL);
    SPAGAIN;
    payload = (!SvTRUE(ERRSV) && count > 0) ? SvREFCNT_inc(POPs) : NULL;
    if (count > 0 && !payload) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
  }
  if (!payload) croak("Punk::OAuth2::Server: failed to encode AT claims");
  sv_2mortal(payload);

  /* Crypt::JWS::sign($key, $payload, alg=>?, kid=>?, typ=>'at+jwt') */
  {
    dSP; int count;
    const char *alg = pox_srv_str(aTHX_ srv, "alg");
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(key);
    XPUSHs(payload);
    XPUSHs(sv_2mortal(newSVpvs("alg")));
    XPUSHs(sv_2mortal(newSVpv(alg ? alg : "ES256", 0)));
    XPUSHs(sv_2mortal(newSVpvs("kid")));
    XPUSHs(kid ? kid : &PL_sv_undef);
    XPUSHs(sv_2mortal(newSVpvs("typ")));
    XPUSHs(sv_2mortal(newSVpvs("at+jwt")));
    PUTBACK;
    count = call_pv("Crypt::JWS::sign", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) token = SvREFCNT_inc(POPs);
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
  }
  if (!token) croak("Punk::OAuth2::Server: AT signing failed: %s",
                    SvPV_nolen(ERRSV));
  return sv_2mortal(token);
}

/* Exact-string redirect_uri match against a client's registered set.
 * The row's redirect_uris may be a JSON array string (the shipped DBI
 * store) or already an arrayref (a custom store) - both are accepted. */
static int pox_redirect_ok(pTHX_ HV *client, SV *redirect_uri) {
  SV *uris = pox_row_get(aTHX_ client, "redirect_uris");
  SV *decoded = NULL;
  STRLEN want_l;
  const char *want;
  int ok = 0;
  if (!uris || !SvOK(redirect_uri)) return 0;
  want = SvPV_const(redirect_uri, want_l);
  if (SvROK(uris) && SvTYPE(SvRV(uris)) == SVt_PVAV) {
    decoded = SvREFCNT_inc(uris);   /* already an arrayref */
  }
  else {
    STRLEN jl;
    const char *jp = SvPV_const(uris, jl);
    dSP; int count;
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvn(jp, jl))); PUTBACK;
    count = call_pv("File::Raw::JSON::file_json_decode", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) decoded = SvREFCNT_inc(POPs);
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
  }
  if (decoded && SvROK(decoded) && SvTYPE(SvRV(decoded)) == SVt_PVAV) {
    AV *av = (AV *)SvRV(decoded);
    SSize_t i, n = av_count(av);
    for (i = 0; i < n; i++) {
      SV **e = av_fetch(av, i, 0);
      STRLEN el;
      const char *ep;
      if (!e || !*e || !SvOK(*e)) continue;
      ep = SvPV_const(*e, el);
      if (el == want_l && memEQ(ep, want, want_l)) { ok = 1; break; }
    }
  }
  SvREFCNT_dec(decoded);
  return ok;
}

/* Read a registered list off a client row into a fresh mortal AV.
 *
 * The column is documented as space-separated, custom stores may hand back
 * an arrayref, and redirect_uris has always been allowed to be a JSON array,
 * so all three are accepted here. Returns NULL when the client registered
 * nothing at all, which the callers read as "nothing is allowed" - the same
 * way an empty redirect_uris matches no redirect_uri. */
static AV *pox_client_list(pTHX_ HV *client, const char *field, I32 flen) {
  SV **sp = hv_fetch(client, field, flen, 0);
  SV *v = sp ? *sp : NULL;
  AV *out;
  if (!v || !SvOK(v)) return NULL;
  out = (AV *)sv_2mortal((SV *)newAV());
  if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV) {
    AV *src = (AV *)SvRV(v);
    SSize_t i, n = av_count(src);
    for (i = 0; i < n; i++) {
      SV **e = av_fetch(src, i, 0);
      if (e && *e && SvOK(*e)) av_push(out, newSVsv(*e));
    }
    return av_count(out) ? out : NULL;
  }
  {
    STRLEN sl;
    const char *s = SvPV_const(v, sl);
    STRLEN a = 0, b;
    if (sl && s[0] == '[') {                      /* a JSON array of names */
      dSP; int count; SV *dec = NULL;
      ENTER; SAVETMPS; PUSHMARK(SP);
      XPUSHs(sv_2mortal(newSVpvn(s, sl))); PUTBACK;
      count = call_pv("File::Raw::JSON::file_json_decode", G_SCALAR | G_EVAL);
      SPAGAIN;
      if (!SvTRUE(ERRSV) && count > 0) dec = SvREFCNT_inc(POPs);
      else if (count > 0) (void)POPs;
      PUTBACK; FREETMPS; LEAVE;
      if (dec) {
        sv_2mortal(dec);
        if (SvROK(dec) && SvTYPE(SvRV(dec)) == SVt_PVAV) {
          AV *src = (AV *)SvRV(dec);
          SSize_t i, n = av_count(src);
          for (i = 0; i < n; i++) {
            SV **e = av_fetch(src, i, 0);
            if (e && *e && SvOK(*e)) av_push(out, newSVsv(*e));
          }
          return av_count(out) ? out : NULL;
        }
      }
    }
    for (b = 0; b <= sl; b++)                     /* space or comma separated */
      if (b == sl || s[b] == ' ' || s[b] == ',' || s[b] == '\t') {
        if (b > a) av_push(out, newSVpvn(s + a, b - a));
        a = b + 1;
      }
  }
  return av_count(out) ? out : NULL;
}

/* exact membership of a registered list */
static int pox_list_has(pTHX_ AV *av, const char *want, STRLEN wl) {
  SSize_t i, n;
  if (!av) return 0;
  n = av_count(av);
  for (i = 0; i < n; i++) {
    SV **e = av_fetch(av, i, 0);
    STRLEN el;
    const char *ep;
    if (!e || !*e || !SvOK(*e)) continue;
    ep = SvPV_const(*e, el);
    if (el == wl && memEQ(ep, want, wl)) return 1;
  }
  return 0;
}

/* Is this client registered for this grant type? A client registered for
 * nothing may use nothing: the token endpoint dispatches on a grant_type the
 * client puts in the request body, so without this a client registered for
 * authorization_code alone can ask for client_credentials and be handed a
 * signed token for it. */
static int pox_grant_ok(pTHX_ HV *client, const char *gt) {
  AV *av = pox_client_list(aTHX_ client, "grant_types", 11);
  return pox_list_has(aTHX_ av, gt, strlen(gt));
}

/* Is every space-separated token of `scope` registered to this client?
 * An absent or empty request scope is always fine; it asks for nothing. */
static int pox_client_scope_ok(pTHX_ HV *client, SV *scope) {
  AV *av;
  STRLEN sl, a = 0, b;
  const char *s;
  if (!scope || !SvOK(scope)) return 1;
  s = SvPV_const(scope, sl);
  av = pox_client_list(aTHX_ client, "scopes", 6);
  for (b = 0; b <= sl; b++)
    if (b == sl || s[b] == ' ') {
      if (b > a && !pox_list_has(aTHX_ av, s + a, b - a)) return 0;
      a = b + 1;
    }
  return 1;
}

/* Redirect back to the client with error+state (RFC 6749). */
static SV *pox_authorize_error(pTHX_ SV *redirect_uri, const char *error,
                               SV *state, SV *iss) {
  SV *url = newSVsv(redirect_uri);
  STRLEN ul;
  const char *up = SvPV_const(url, ul);
  sv_catpvn(url, memchr(up, '?', ul) ? "&" : "?", 1);
  sv_catpvs(url, "error=");
  sv_catpv(url, error);
  if (state && SvOK(state)) {
    STRLEN sl; const char *sp = SvPV_const(state, sl);
    sv_catpvs(url, "&state=");
    sv_catsv(url, pox_uri_escape(aTHX_ sp, sl));
  }
  if (iss && SvOK(iss)) {
    STRLEN il; const char *ip = SvPV_const(iss, il);
    sv_catpvs(url, "&iss=");
    sv_catsv(url, pox_uri_escape(aTHX_ ip, il));
  }
  sv_2mortal(url);
  return pox_redirect_response(aTHX_ url);
}

/* GET /authorize: validate client + exact redirect_uri (no redirect on
 * failure), require PKCE S256, run authenticate + consent hooks, mint a
 * code, 302 back with code+state+iss. */
static SV *pox_srv_authorize(pTHX_ SV *self, SV *c) {
  HV *srv = pox_srv_hv(aTHX_ self);
  SV *store = pox_srv_get(aTHX_ srv, "store");
  HV *q = pox_req_query(aTHX_ c);
  SV *client_id = pox_field(aTHX_ q, "client_id");
  SV *redirect_uri = pox_field(aTHX_ q, "redirect_uri");
  SV *state = pox_field(aTHX_ q, "state");
  SV *scope = pox_field(aTHX_ q, "scope");
  SV *nonce = pox_field(aTHX_ q, "nonce");
  SV *challenge = pox_field(aTHX_ q, "code_challenge");
  SV *method = pox_field(aTHX_ q, "code_challenge_method");
  SV *rtype = pox_field(aTHX_ q, "response_type");
  SV *iss = pox_srv_get(aTHX_ srv, "issuer");
  SV *client, *user_id;

  if (!client_id)
    return pox_text_response(aTHX_ 400, "missing client_id");
  { SV *a[1]; a[0] = client_id;
    client = pox_store_call(aTHX_ store, "client_get", a, 1); }
  if (!client || !SvROK(client))
    return pox_text_response(aTHX_ 400, "unknown client");

  /* exact redirect_uri match, or a single registered URI as default */
  if (!redirect_uri)
    return pox_text_response(aTHX_ 400, "missing redirect_uri");
  if (!pox_redirect_ok(aTHX_ (HV *)SvRV(client), redirect_uri))
    return pox_text_response(aTHX_ 400, "redirect_uri mismatch");

  /* from here, errors go back to the client via redirect */
  if (!rtype || strNE(SvPV_nolen(rtype), "code"))
    return pox_authorize_error(aTHX_ redirect_uri, "unsupported_response_type",
                               state, iss);
  if (!challenge || !method || strNE(SvPV_nolen(method), "S256"))
    return pox_authorize_error(aTHX_ redirect_uri, "invalid_request",
                               state, iss);

  /* The registration decides what this client may ask for. Without these
   * two the query string did: a client registered for nothing but
   * authorization_code could name any scope it liked and have it copied into
   * the code record and signed into the access token, with the optional
   * consent hook the only thing in the way. */
  if (!pox_grant_ok(aTHX_ (HV *)SvRV(client), "authorization_code"))
    return pox_authorize_error(aTHX_ redirect_uri, "unauthorized_client",
                               state, iss);
  if (!pox_client_scope_ok(aTHX_ (HV *)SvRV(client), scope))
    return pox_authorize_error(aTHX_ redirect_uri, "invalid_scope",
                               state, iss);

  /* authenticate hook: returns a user id, or a reference (a login
   * redirect) that short-circuits */
  {
    SV *hook = pox_srv_get(aTHX_ srv, "authenticate");
    dSP; int count; SV *r = NULL;
    if (!hook) return pox_text_response(aTHX_ 500, "no authenticate hook");
    ENTER; SAVETMPS; PUSHMARK(SP); XPUSHs(c); PUTBACK;
    count = call_sv(hook, G_SCALAR | G_EVAL); SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) r = SvREFCNT_inc(POPs);
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    if (SvTRUE(ERRSV)) { SvREFCNT_dec(r);
      return pox_text_response(aTHX_ 500, "authenticate failed"); }
    if (r && SvROK(r)) return r;   /* a response (login redirect) */
    if (!r || !SvOK(r)) { SvREFCNT_dec(r);
      return pox_authorize_error(aTHX_ redirect_uri, "access_denied",
                                 state, iss); }
    user_id = sv_2mortal(r);
  }

  /* consent hook (optional): 1 approve / 0 deny / reference render */
  {
    SV *hook = pox_srv_get(aTHX_ srv, "consent");
    if (hook) {
      SV *prev = NULL;
      /* skip if already consented for this client */
      { SV *a[2]; a[0] = user_id; a[1] = client_id;
        prev = pox_store_call(aTHX_ store, "consent_get", a, 2); }
      if (!prev || !SvROK(prev)) {
        dSP; int count; SV *r = NULL;
        AV *scopes = newAV();
        sv_2mortal((SV *)scopes);
        if (scope) {
          STRLEN sl; const char *sp = SvPV_const(scope, sl);
          STRLEN a2 = 0, b;
          for (b = 0; b <= sl; b++)
            if (b == sl || sp[b] == ' ') {
              if (b > a2) av_push(scopes, newSVpvn(sp + a2, b - a2));
              a2 = b + 1;
            }
        }
        ENTER; SAVETMPS; PUSHMARK(SP);
        XPUSHs(c); XPUSHs(client); XPUSHs(sv_2mortal(newRV_inc((SV *)scopes)));
        PUTBACK;
        count = call_sv(hook, G_SCALAR | G_EVAL); SPAGAIN;
        if (!SvTRUE(ERRSV) && count > 0) r = SvREFCNT_inc(POPs);
        else if (count > 0) (void)POPs;
        PUTBACK; FREETMPS; LEAVE;
        if (r && SvROK(r)) return sv_2mortal(r);   /* render consent */
        if (!r || !SvTRUE(r)) { SvREFCNT_dec(r);
          return pox_authorize_error(aTHX_ redirect_uri, "access_denied",
                                     state, iss); }
        SvREFCNT_dec(r);
        { SV *a[3]; a[0] = user_id; a[1] = client_id;
          a[2] = scope ? scope : sv_2mortal(newSVpvs(""));
          (void)pox_store_call(aTHX_ store, "consent_put", a, 3); }
      }
    }
  }

  /* mint the code */
  {
    SV *code = pox_random_b64(aTHX_ 32);
    HV *rec = newHV();
    sv_2mortal((SV *)rec);
    (void)hv_stores(rec, "client_id", newSVsv(client_id));
    (void)hv_stores(rec, "user_id", newSVsv(user_id));
    (void)hv_stores(rec, "redirect_uri", newSVsv(redirect_uri));
    if (scope) (void)hv_stores(rec, "scope", newSVsv(scope));
    if (nonce) (void)hv_stores(rec, "nonce", newSVsv(nonce));
    (void)hv_stores(rec, "code_challenge", newSVsv(challenge));
    (void)hv_stores(rec, "expires", newSViv((IV)time(NULL) + 600));
    { SV *a[2]; a[0] = code; a[1] = sv_2mortal(newRV_inc((SV *)rec));
      (void)pox_store_call(aTHX_ store, "code_put", a, 2); }
    {
      SV *url = newSVsv(redirect_uri);
      STRLEN ul; const char *up = SvPV_const(url, ul);
      STRLEN cl; const char *cp = SvPV_const(code, cl);
      sv_catpvn(url, memchr(up, '?', ul) ? "&" : "?", 1);
      sv_catpvs(url, "code=");
      sv_catsv(url, pox_uri_escape(aTHX_ cp, cl));
      if (state) { STRLEN sl; const char *sp = SvPV_const(state, sl);
        sv_catpvs(url, "&state="); sv_catsv(url, pox_uri_escape(aTHX_ sp, sl)); }
      if (iss) { STRLEN il; const char *ip = SvPV_const(iss, il);
        sv_catpvs(url, "&iss="); sv_catsv(url, pox_uri_escape(aTHX_ ip, il)); }
      sv_2mortal(url);
      return pox_redirect_response(aTHX_ url);
    }
  }
}

/* Client authentication for the token/revoke/introspect endpoints:
 * Basic header or body client_id/client_secret. Returns the client row
 * (mortal) on success, NULL on failure. For a public client (no secret
 * registered), body client_id alone authenticates. */
static HV *pox_client_auth(pTHX_ HV *srv, SV *c, HV *form) {
  SV *store = pox_srv_get(aTHX_ srv, "store");
  SV *cid = NULL, *csecret = NULL;
  SV *client;
  SV *auth;

  /* Basic header */
  { SV *req = NULL, *hv = NULL;
    dSP; int count;
    ENTER; SAVETMPS; PUSHMARK(SP); XPUSHs(c); PUTBACK;
    count = call_method("req", G_SCALAR | G_EVAL); SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) req = SvREFCNT_inc(POPs);
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    if (req) { sv_2mortal(req);
      ENTER; SAVETMPS; PUSHMARK(SP); XPUSHs(req);
      XPUSHs(sv_2mortal(newSVpvs("Authorization"))); PUTBACK;
      count = call_method("header", G_SCALAR | G_EVAL); SPAGAIN;
      if (!SvTRUE(ERRSV) && count > 0) hv = SvREFCNT_inc(POPs);
      else if (count > 0) (void)POPs;
      PUTBACK; FREETMPS; LEAVE;
      if (hv) sv_2mortal(hv);
    }
    auth = hv;
  }
  if (auth && SvOK(auth)) {
    STRLEN al; const char *ap = SvPV_const(auth, al);
    if (al > 6 && strnEQ(ap, "Basic ", 6)) {
      dSP; int count; SV *dec = NULL;
      ENTER; SAVETMPS; PUSHMARK(SP);
      XPUSHs(sv_2mortal(newSVpvn(ap + 6, al - 6))); PUTBACK;
      count = call_pv("MIME::Base64::decode_base64", G_SCALAR | G_EVAL);
      SPAGAIN;
      if (!SvTRUE(ERRSV) && count > 0) dec = SvREFCNT_inc(POPs);
      else if (count > 0) (void)POPs;
      PUTBACK; FREETMPS; LEAVE;
      if (dec) { sv_2mortal(dec);
        STRLEN dl; const char *dp = SvPV_const(dec, dl);
        const char *colon = memchr(dp, ':', dl);
        if (colon) {
          /* pox_urldecode already returns a mortal SV */
          cid = pox_urldecode(aTHX_ dp, colon - dp);
          csecret = pox_urldecode(aTHX_ colon + 1, dl - (colon - dp) - 1);
        }
      }
    }
  }
  if (!cid) {
    cid = pox_field(aTHX_ form, "client_id");
    csecret = pox_field(aTHX_ form, "client_secret");
  }
  if (!cid) return NULL;

  { SV *a[1]; a[0] = cid;
    client = pox_store_call(aTHX_ store, "client_get", a, 1); }
  if (!client || !SvROK(client)) return NULL;
  {
    HV *ch = (HV *)SvRV(client);
    SV *digest = pox_row_get(aTHX_ ch, "secret_digest");
    if (!digest || !SvOK(digest) || !SvCUR(digest)) {
      /* public client: no secret required */
      return ch;
    }
    if (!csecret) return NULL;
    {
      SV *given = pox_digest(aTHX_ csecret);
      if (!pox_ct_eq_sv(aTHX_ given, digest)) return NULL;
    }
    return ch;
  }
}

/* Build a token response hash (access_token/token_type/expires_in/
 * refresh_token/scope) and issue a rotated refresh token. */
static SV *pox_token_success(pTHX_ HV *srv, SV *client_id, SV *user_id,
                             const char *scope, int with_refresh) {
  SV *store = pox_srv_get(aTHX_ srv, "store");
  HV *resp = newHV();
  SV *at = pox_mint_at(aTHX_ srv, client_id, user_id, scope);
  IV at_ttl = pox_hv_iv(aTHX_ srv, "at_ttl", 600);
  sv_2mortal((SV *)resp);
  (void)hv_stores(resp, "access_token", newSVsv(at));
  (void)hv_stores(resp, "token_type", newSVpvs("Bearer"));
  (void)hv_stores(resp, "expires_in", newSViv(at_ttl));
  if (scope && *scope) (void)hv_stores(resp, "scope", newSVpv(scope, 0));
  if (with_refresh) {
    SV *rt = pox_random_b64(aTHX_ 32);
    SV *family = pox_random_b64(aTHX_ 16);
    HV *rec = newHV();
    sv_2mortal((SV *)rec);
    (void)hv_stores(rec, "family_id", newSVsv(family));
    (void)hv_stores(rec, "client_id", newSVsv(client_id));
    if (user_id && SvOK(user_id))
      (void)hv_stores(rec, "user_id", newSVsv(user_id));
    if (scope && *scope) (void)hv_stores(rec, "scope", newSVpv(scope, 0));
    (void)hv_stores(rec, "expires",
      newSViv((IV)time(NULL) + pox_hv_iv(aTHX_ srv, "rt_ttl", 30*86400)));
    { SV *a[2]; a[0] = rt; a[1] = sv_2mortal(newRV_inc((SV *)rec));
      (void)pox_store_call(aTHX_ store, "refresh_put", a, 2); }
    (void)hv_stores(resp, "refresh_token", newSVsv(rt));
  }
  return pox_json_response(aTHX_ 200, sv_2mortal(newRV_inc((SV *)resp)));
}

/* POST /token: the three grants. */
static SV *pox_srv_token(pTHX_ SV *self, SV *c) {
  HV *srv = pox_srv_hv(aTHX_ self);
  SV *store = pox_srv_get(aTHX_ srv, "store");
  HV *form = pox_parse_form(aTHX_ pox_req_body(aTHX_ c));
  HV *client = pox_client_auth(aTHX_ srv, c, form);
  SV *grant = pox_field(aTHX_ form, "grant_type");
  const char *gt;

  if (!client)
    return pox_error_json(aTHX_ 401, "invalid_client", NULL);
  gt = grant ? SvPV_nolen(grant) : "";
  /* The grant type arrives in the request body, so it is the client's choice
   * of arm, not the registration's, unless this says otherwise. */
  if (*gt && !pox_grant_ok(aTHX_ client, gt))
    return pox_error_json(aTHX_ 400, "unauthorized_client", NULL);
  {
    SV *cid = pox_row_get(aTHX_ client, "client_id");

    if (strEQ(gt, "authorization_code")) {
      SV *code = pox_field(aTHX_ form, "code");
      SV *ruri = pox_field(aTHX_ form, "redirect_uri");
      SV *verifier = pox_field(aTHX_ form, "code_verifier");
      SV *rec;
      if (!code) return pox_error_json(aTHX_ 400, "invalid_request", NULL);
      { SV *a[1]; a[0] = code;
        rec = pox_store_call(aTHX_ store, "code_take", a, 1); }
      if (!rec || !SvROK(rec))
        return pox_error_json(aTHX_ 400, "invalid_grant", NULL);
      {
        HV *rh = (HV *)SvRV(rec);
        SV *rcid = pox_row_get(aTHX_ rh, "client_id");
        SV *rruri = pox_row_get(aTHX_ rh, "redirect_uri");
        SV *chal = pox_row_get(aTHX_ rh, "code_challenge");
        SV *exp = pox_row_get(aTHX_ rh, "expires");
        SV *scope = pox_row_get(aTHX_ rh, "scope");
        SV *uid = pox_row_get(aTHX_ rh, "user_id");
        /* bindings must match */
        if (!rcid || sv_cmp(rcid, cid) != 0)
          return pox_error_json(aTHX_ 400, "invalid_grant", NULL);
        if (exp && SvIV(exp) < (IV)time(NULL))
          return pox_error_json(aTHX_ 400, "invalid_grant", NULL);
        if (!ruri || !rruri || sv_cmp(ruri, rruri) != 0)
          return pox_error_json(aTHX_ 400, "invalid_grant", NULL);
        /* PKCE: S256(verifier) == stored challenge (constant time) */
        if (!verifier) return pox_error_json(aTHX_ 400, "invalid_grant", NULL);
        {
          STRLEN vl; const char *vp = SvPVbyte(verifier, vl);
          SV *dig = pox_sha256(aTHX_ (const unsigned char *)vp, vl);
          SV *got = pox_b64url(aTHX_ (const unsigned char *)SvPVX(dig),
                               SvCUR(dig));
          if (!chal || !pox_ct_eq_sv(aTHX_ got, chal))
            return pox_error_json(aTHX_ 400, "invalid_grant", NULL);
        }
        /* the scope was checked when the code was minted; check it again in
         * case the registration has been narrowed since */
        if (!pox_client_scope_ok(aTHX_ client, scope))
          return pox_error_json(aTHX_ 400, "invalid_scope", NULL);
        return pox_token_success(aTHX_ srv, cid, uid,
                                 scope ? SvPV_nolen(scope) : "", 1);
      }
    }

    if (strEQ(gt, "refresh_token")) {
      SV *rt = pox_field(aTHX_ form, "refresh_token");
      SV *rec;
      if (!rt) return pox_error_json(aTHX_ 400, "invalid_request", NULL);
      { SV *a[1]; a[0] = rt;
        rec = pox_store_call(aTHX_ store, "refresh_take", a, 1); }
      if (!rec || !SvROK(rec))
        return pox_error_json(aTHX_ 400, "invalid_grant", NULL);
      {
        HV *rh = (HV *)SvRV(rec);
        SV *revoked = pox_row_get(aTHX_ rh, "revoked");
        SV *rotated = pox_row_get(aTHX_ rh, "rotated_to");
        SV *family = pox_row_get(aTHX_ rh, "family_id");
        SV *rcid = pox_row_get(aTHX_ rh, "client_id");
        SV *uid = pox_row_get(aTHX_ rh, "user_id");
        SV *scope = pox_row_get(aTHX_ rh, "scope");
        SV *exp = pox_row_get(aTHX_ rh, "expires");
        if (!rcid || sv_cmp(rcid, cid) != 0)
          return pox_error_json(aTHX_ 400, "invalid_grant", NULL);
        if (revoked && SvTRUE(revoked))
          return pox_error_json(aTHX_ 400, "invalid_grant", NULL);
        /* reuse detection: an already-rotated token means theft ->
         * revoke the whole family */
        if (rotated && SvOK(rotated) && SvCUR(rotated)) {
          if (family) { SV *a[1]; a[0] = family;
            (void)pox_store_call(aTHX_ store, "refresh_revoke_family", a, 1); }
          return pox_error_json(aTHX_ 400, "invalid_grant", NULL);
        }
        if (exp && SvIV(exp) < (IV)time(NULL))
          return pox_error_json(aTHX_ 400, "invalid_grant", NULL);
        /* a refresh token outlives a registration change, so the scope it
         * carries has to be re-checked rather than trusted */
        if (!pox_client_scope_ok(aTHX_ client, scope))
          return pox_error_json(aTHX_ 400, "invalid_scope", NULL);
        /* rotate: mint a new refresh in the same family, mark old
         * rotated */
        {
          SV *newrt = pox_random_b64(aTHX_ 32);
          HV *nrec = newHV();
          HV *resp = newHV();
          SV *at = pox_mint_at(aTHX_ srv, cid, uid,
                               scope ? SvPV_nolen(scope) : "");
          sv_2mortal((SV *)nrec);
          sv_2mortal((SV *)resp);
          (void)hv_stores(nrec, "family_id", newSVsv(family));
          (void)hv_stores(nrec, "client_id", newSVsv(cid));
          if (uid && SvOK(uid)) (void)hv_stores(nrec, "user_id", newSVsv(uid));
          if (scope) (void)hv_stores(nrec, "scope", newSVsv(scope));
          (void)hv_stores(nrec, "expires",
            newSViv((IV)time(NULL) + pox_hv_iv(aTHX_ srv, "rt_ttl", 30*86400)));
          { SV *a[2]; a[0] = newrt; a[1] = sv_2mortal(newRV_inc((SV *)nrec));
            (void)pox_store_call(aTHX_ store, "refresh_put", a, 2); }
          { SV *nd = pox_digest(aTHX_ newrt);
            SV *a[2]; a[0] = rt; a[1] = nd;
            (void)pox_store_call(aTHX_ store, "refresh_rotate", a, 2); }
          (void)hv_stores(resp, "access_token", newSVsv(at));
          (void)hv_stores(resp, "token_type", newSVpvs("Bearer"));
          (void)hv_stores(resp, "expires_in",
                          newSViv(pox_hv_iv(aTHX_ srv, "at_ttl", 600)));
          if (scope) (void)hv_stores(resp, "scope", newSVsv(scope));
          (void)hv_stores(resp, "refresh_token", newSVsv(newrt));
          return pox_json_response(aTHX_ 200,
                                   sv_2mortal(newRV_inc((SV *)resp)));
        }
      }
    }

    if (strEQ(gt, "client_credentials")) {
      SV *scope = pox_field(aTHX_ form, "scope");
      /* RFC 6749 4.4: this grant is for a confidential client. A public
       * client authenticates on a client_id anyone can read out of a browser,
       * so it must not be able to trade one for a token of its own. */
      SV *digest = pox_row_get(aTHX_ client, "secret_digest");
      SV *pub = pox_row_get(aTHX_ client, "is_public");
      if (!digest || !SvOK(digest) || !SvCUR(digest) || (pub && SvTRUE(pub)))
        return pox_error_json(aTHX_ 401, "invalid_client", NULL);
      if (!pox_client_scope_ok(aTHX_ client, scope))
        return pox_error_json(aTHX_ 400, "invalid_scope", NULL);
      return pox_token_success(aTHX_ srv, cid, &PL_sv_undef,
                               scope ? SvPV_nolen(scope) : "", 0);
    }

    return pox_error_json(aTHX_ 400, "unsupported_grant_type", NULL);
  }
}

/* POST /revoke (RFC 7009): always 200; a refresh token revokes its
 * family. */
static SV *pox_srv_revoke(pTHX_ SV *self, SV *c) {
  HV *srv = pox_srv_hv(aTHX_ self);
  SV *store = pox_srv_get(aTHX_ srv, "store");
  HV *form = pox_parse_form(aTHX_ pox_req_body(aTHX_ c));
  HV *client = pox_client_auth(aTHX_ srv, c, form);
  SV *token = pox_field(aTHX_ form, "token");
  if (!client) return pox_error_json(aTHX_ 401, "invalid_client", NULL);
  if (token) {
    SV *rec;
    { SV *a[1]; a[0] = token;
      rec = pox_store_call(aTHX_ store, "refresh_take", a, 1); }
    if (rec && SvROK(rec)) {
      SV *family = pox_row_get(aTHX_ (HV *)SvRV(rec), "family_id");
      if (family) { SV *a[1]; a[0] = family;
        (void)pox_store_call(aTHX_ store, "refresh_revoke_family", a, 1); }
    }
  }
  { HV *e = newHV(); sv_2mortal((SV *)e);
    return pox_json_response(aTHX_ 200, sv_2mortal(newRV_inc((SV *)e))); }
}

/* POST /introspect (RFC 7662): client-authenticated; uniform
 * {"active":false} for anything not live. */
static SV *pox_srv_introspect(pTHX_ SV *self, SV *c) {
  HV *srv = pox_srv_hv(aTHX_ self);
  SV *store = pox_srv_get(aTHX_ srv, "store");
  HV *form = pox_parse_form(aTHX_ pox_req_body(aTHX_ c));
  HV *client = pox_client_auth(aTHX_ srv, c, form);
  SV *token = pox_field(aTHX_ form, "token");
  HV *out = newHV();
  sv_2mortal((SV *)out);
  if (!client) return pox_error_json(aTHX_ 401, "invalid_client", NULL);
  if (token) {
    /* JWT access token: verify locally */
    SV *key = pox_srv_get(aTHX_ srv, "key");
    SV *payload = NULL;
    AV *algs = newAV();
    sv_2mortal((SV *)algs);
    av_push(algs, newSVpv(pox_srv_str(aTHX_ srv, "alg")
                          ? pox_srv_str(aTHX_ srv, "alg") : "ES256", 0));
    {
      dSP; int count;
      ENTER; SAVETMPS; PUSHMARK(SP);
      XPUSHs(token); XPUSHs(key);
      XPUSHs(sv_2mortal(newSVpvs("algs")));
      XPUSHs(sv_2mortal(newRV_inc((SV *)algs)));
      PUTBACK;
      count = call_pv("Crypt::JWS::verify", G_SCALAR | G_EVAL); SPAGAIN;
      if (!SvTRUE(ERRSV) && count > 0) payload = SvREFCNT_inc(POPs);
      else if (count > 0) (void)POPs;
      PUTBACK; FREETMPS; LEAVE;
    }
    if (payload && SvOK(payload)) {
      SV *claims = pox_decode_json_hash(aTHX_ sv_2mortal(payload));
      if (claims) {
        HV *ch = (HV *)SvRV(claims);
        SV *exp = pox_row_get(aTHX_ ch, "exp");
        if (!exp || SvIV(exp) > (IV)time(NULL)) {
          (void)hv_stores(out, "active", newRV_noinc(newSViv(1)));
          { SV *v = pox_row_get(aTHX_ ch, "sub");
            if (v) (void)hv_stores(out, "sub", newSVsv(v)); }
          { SV *v = pox_row_get(aTHX_ ch, "scope");
            if (v) (void)hv_stores(out, "scope", newSVsv(v)); }
          { SV *v = pox_row_get(aTHX_ ch, "client_id");
            if (v) (void)hv_stores(out, "client_id", newSVsv(v)); }
          if (exp) (void)hv_stores(out, "exp", newSVsv(exp));
          return pox_json_response(aTHX_ 200,
                                   sv_2mortal(newRV_inc((SV *)out)));
        }
      }
    }
    else {
      /* maybe an opaque refresh token */
      SV *rec;
      { SV *a[1]; a[0] = token;
        rec = pox_store_call(aTHX_ store, "refresh_take", a, 1); }
      if (rec && SvROK(rec)) {
        HV *rh = (HV *)SvRV(rec);
        SV *revoked = pox_row_get(aTHX_ rh, "revoked");
        SV *exp = pox_row_get(aTHX_ rh, "expires");
        SV *rotated = pox_row_get(aTHX_ rh, "rotated_to");
        if ((!revoked || !SvTRUE(revoked))
            && (!rotated || !SvOK(rotated) || !SvCUR(rotated))
            && (!exp || SvIV(exp) > (IV)time(NULL))) {
          (void)hv_stores(out, "active", newRV_noinc(newSViv(1)));
          { SV *v = pox_row_get(aTHX_ rh, "client_id");
            if (v) (void)hv_stores(out, "client_id", newSVsv(v)); }
          { SV *v = pox_row_get(aTHX_ rh, "scope");
            if (v) (void)hv_stores(out, "scope", newSVsv(v)); }
          return pox_json_response(aTHX_ 200,
                                   sv_2mortal(newRV_inc((SV *)out)));
        }
      }
    }
  }
  (void)hv_stores(out, "active", newRV_noinc(newSViv(0)));
  return pox_json_response(aTHX_ 200, sv_2mortal(newRV_inc((SV *)out)));
}

/* GET /jwks.json: the active public key. */
static SV *pox_srv_jwks(pTHX_ SV *self, SV *c) {
  HV *srv = pox_srv_hv(aTHX_ self);
  SV *key = pox_srv_get(aTHX_ srv, "key");
  SV *kid = pox_srv_get(aTHX_ srv, "kid");
  HV *doc = newHV();
  AV *keys = newAV();
  SV *jwk = NULL;
  PERL_UNUSED_ARG(c);
  sv_2mortal((SV *)doc);
  /* $key->to_jwk(kid => $kid, use => 'sig', alg => $alg) */
  {
    dSP; int count;
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(key);
    XPUSHs(sv_2mortal(newSVpvs("kid")));
    XPUSHs(kid ? kid : &PL_sv_undef);
    XPUSHs(sv_2mortal(newSVpvs("use")));
    XPUSHs(sv_2mortal(newSVpvs("sig")));
    XPUSHs(sv_2mortal(newSVpvs("alg")));
    XPUSHs(sv_2mortal(newSVpv(pox_srv_str(aTHX_ srv, "alg")
                             ? pox_srv_str(aTHX_ srv, "alg") : "ES256", 0)));
    PUTBACK;
    count = call_method("to_jwk", G_SCALAR | G_EVAL); SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) jwk = SvREFCNT_inc(POPs);
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
  }
  if (jwk) av_push(keys, jwk);
  (void)hv_stores(doc, "keys", newRV_noinc((SV *)keys));
  {
    /* jwks.json is public, cacheable */
    SV *r = pox_json_response(aTHX_ 200, sv_2mortal(newRV_inc((SV *)doc)));
    return r;
  }
}

/* GET /.well-known metadata (RFC 8414). */
static SV *pox_srv_metadata(pTHX_ SV *self, SV *c) {
  HV *srv = pox_srv_hv(aTHX_ self);
  const char *iss = pox_srv_str(aTHX_ srv, "issuer");
  const char *prefix = pox_srv_str(aTHX_ srv, "prefix");
  HV *m = newHV();
  AV *grants = newAV(), *methods = newAV(), *rtypes = newAV(), *algs = newAV();
  SV *base;
  PERL_UNUSED_ARG(c);
  sv_2mortal((SV *)m);
  base = sv_2mortal(newSVpv(iss ? iss : "", 0));
  { STRLEN bl; const char *bp = SvPV_const(base, bl);
    if (bl > 1 && bp[bl-1] == '/') SvCUR_set(base, bl - 1); }
  (void)hv_stores(m, "issuer", newSVsv(base));
#define POX_EP(name, path) do { \
    SV *u = newSVsv(base); sv_catpv(u, prefix ? prefix : ""); \
    sv_catpv(u, path); (void)hv_stores(m, name, u); } while (0)
  POX_EP("authorization_endpoint", "/authorize");
  POX_EP("token_endpoint", "/token");
  POX_EP("revocation_endpoint", "/revoke");
  POX_EP("introspection_endpoint", "/introspect");
  POX_EP("jwks_uri", "/jwks.json");
#undef POX_EP
  av_push(grants, newSVpvs("authorization_code"));
  av_push(grants, newSVpvs("refresh_token"));
  av_push(grants, newSVpvs("client_credentials"));
  (void)hv_stores(m, "grant_types_supported", newRV_noinc((SV *)grants));
  av_push(methods, newSVpvs("S256"));
  (void)hv_stores(m, "code_challenge_methods_supported",
                  newRV_noinc((SV *)methods));
  av_push(rtypes, newSVpvs("code"));
  (void)hv_stores(m, "response_types_supported", newRV_noinc((SV *)rtypes));
  av_push(algs, newSVpv(pox_srv_str(aTHX_ srv, "alg")
                        ? pox_srv_str(aTHX_ srv, "alg") : "ES256", 0));
  (void)hv_stores(m, "id_token_signing_alg_values_supported",
                  newRV_noinc((SV *)algs));
  return pox_json_response(aTHX_ 200, sv_2mortal(newRV_inc((SV *)m)));
}

#endif

