#ifndef POX_RUN_H
#define POX_RUN_H

#include "pox_abi.h"
#include "pox_provider.h"
#include "pox_url.h"

#define POX_FLOW_TTL 600
#define POX_FLOW_MAX 3

/* $c->session as an HV*, or croak. */
static HV *pox_session(pTHX_ SV *c) {
  SV *sess = NULL;
  dSP;
  int count;
  ENTER; SAVETMPS;
  PUSHMARK(SP); XPUSHs(c); PUTBACK;
  count = call_method("session", G_SCALAR | G_EVAL);
  SPAGAIN;
  if (!SvTRUE(ERRSV) && count > 0) sess = SvREFCNT_inc(POPs);
  else if (count > 0) (void)POPs;
  PUTBACK; FREETMPS; LEAVE;
  if (!sess || !SvROK(sess) || SvTYPE(SvRV(sess)) != SVt_PVHV) {
    SvREFCNT_dec(sess);
    croak("Punk::OAuth2: the login flow needs a session (add a "
          "`session` keyword)");
  }
  sv_2mortal(sess);
  return (HV *)SvRV(sess);
}

/* The per-session flow table session->{_oauth2}, autovivified. */
static HV *pox_flows(pTHX_ SV *c) {
  HV *sess = pox_session(aTHX_ c);
  SV **slot = hv_fetchs(sess, "_oauth2", 1);
  if (!*slot || !SvROK(*slot) || SvTYPE(SvRV(*slot)) != SVt_PVHV) {
    SvREFCNT_dec(*slot);
    *slot = newRV_noinc((SV *)newHV());
  }
  return (HV *)SvRV(*slot);
}

/* Drop expired flows and, if at the cap, the oldest. */
static void pox_purge_flows(pTHX_ HV *flows) {
  IV now = (IV)time(NULL);
  HE *he;
  I32 klen;
  char *key;
  /* expire */
  hv_iterinit(flows);
  {
    AV *dead = newAV();
    SSize_t i, n;
    sv_2mortal((SV *)dead);
    while ((he = hv_iternext(flows))) {
      SV *rec = HeVAL(he);
      IV t = 0;
      if (SvROK(rec) && SvTYPE(SvRV(rec)) == SVt_PVHV) {
        SV **tp = hv_fetchs((HV *)SvRV(rec), "t", 0);
        if (tp && *tp) t = SvIV(*tp);
      }
      if (t < now - POX_FLOW_TTL)
        av_push(dead, newSVpvn(HePV(he, PL_na), HeKLEN(he) < 0
                               ? strlen(HePV(he, PL_na)) : (STRLEN)HeKLEN(he)));
    }
    n = av_count(dead);
    for (i = 0; i < n; i++) {
      STRLEN dl;
      const char *dp = SvPV_const(*av_fetch(dead, i, 0), dl);
      (void)hv_delete(flows, dp, (I32)dl, G_DISCARD);
    }
  }
  /* cap: evict oldest while over POX_FLOW_MAX */
  while (HvUSEDKEYS(flows) >= POX_FLOW_MAX) {
    char *oldest = NULL;
    STRLEN oldest_len = 0;
    IV oldest_t = 0;
    int first = 1;
    hv_iterinit(flows);
    while ((he = hv_iternext(flows))) {
      SV *rec = HeVAL(he);
      IV t = 0;
      if (SvROK(rec) && SvTYPE(SvRV(rec)) == SVt_PVHV) {
        SV **tp = hv_fetchs((HV *)SvRV(rec), "t", 0);
        if (tp && *tp) t = SvIV(*tp);
      }
      key = HePV(he, PL_na);
      klen = HeKLEN(he);
      if (first || t < oldest_t) {
        oldest = key;
        oldest_len = klen < 0 ? strlen(key) : (STRLEN)klen;
        oldest_t = t;
        first = 0;
      }
    }
    if (!oldest) break;
    (void)hv_delete(flows, oldest, (I32)oldest_len, G_DISCARD);
  }
}

/* base_url(c, login) + login->{path} + "/" + provider + "/callback" */
static SV *pox_redirect_uri(pTHX_ SV *c, SV *login, const char *provider) {
  HV *lh = (SvROK(login) && SvTYPE(SvRV(login)) == SVt_PVHV)
    ? (HV *)SvRV(login) : NULL;
  SV *base = sv_2mortal(pox_base_url(aTHX_ c, login));
  SV **pathv = lh ? hv_fetchs(lh, "path", 0) : NULL;
  STRLEN pl;
  const char *pp = (pathv && *pathv && SvOK(*pathv))
    ? SvPV_const(*pathv, pl) : "/auth";
  if (!(pathv && *pathv && SvOK(*pathv))) pl = 5;
  if (pl > 1 && pp[pl - 1] == '/') pl--;
  {
    SV *out = newSVsv(base);
    sv_catpvn(out, pp, pl);
    sv_catpvs(out, "/");
    sv_catpv(out, provider);
    sv_catpvs(out, "/callback");
    return out;   /* owned */
  }
}

/* Begin a login: mint the flow, record it in the session, return the
 * authorization URL (owned). return_to may be NULL. */
static SV *pox_flow_begin(pTHX_ SV *c, SV *provider, SV *login,
                          SV *return_to) {
  HV *ph = pox_prov_hv(aTHX_ provider);
  const char *name = pox_prov_name(aTHX_ ph);
  SV *verifier, *digest, *challenge, *state, *nonce, *url, *redirect_uri;
  HV *flows, *rec;
  STRLEN vl, dl;
  const char *vp;
  const unsigned char *dp;
  HV *params;

  pox_prov_ensure_endpoints(aTHX_ provider, c);

  verifier  = pox_random_b64(aTHX_ 32);
  vp        = SvPVbyte(verifier, vl);
  digest    = pox_sha256(aTHX_ (const unsigned char *)vp, vl);
  dp        = (const unsigned char *)SvPVbyte(digest, dl);
  challenge = pox_b64url(aTHX_ dp, dl);
  state     = pox_random_b64(aTHX_ 32);
  nonce     = pox_random_b64(aTHX_ 32);

  flows = pox_flows(aTHX_ c);
  pox_purge_flows(aTHX_ flows);
  rec = newHV();
  (void)hv_stores(rec, "p", newSVpv(name, 0));
  (void)hv_stores(rec, "v", newSVsv(verifier));
  (void)hv_stores(rec, "n", newSVsv(nonce));
  (void)hv_stores(rec, "t", newSViv((IV)time(NULL)));
  if (return_to && SvOK(return_to))
    (void)hv_stores(rec, "r", newSVsv(return_to));
  {
    STRLEN sl;
    const char *sp = SvPV_const(state, sl);
    (void)hv_store(flows, sp, (I32)sl, newRV_noinc((SV *)rec), 0);
  }

  redirect_uri = sv_2mortal(pox_redirect_uri(aTHX_ c, login, name));
  params = newHV();
  sv_2mortal((SV *)params);
  (void)hv_stores(params, "redirect_uri", newSVsv(redirect_uri));
  (void)hv_stores(params, "state", newSVsv(state));
  (void)hv_stores(params, "nonce", newSVsv(nonce));
  (void)hv_stores(params, "challenge", newSVsv(challenge));
  url = pox_prov_authorize_url(aTHX_ provider, params);
  return url;   /* owned */
}

/* Complete a callback: validate the returned state against the session,
 * exchange the code, normalize identity. Pushes (identity, tokens) on
 * success; on any failure croaks with a short reason (the caller renders
 * the generic error page and logs the detail). query is the request
 * query HV. */
static void pox_flow_complete(pTHX_ SV *c, SV *provider, SV *login,
                              SV **out_identity, SV **out_tokens) {
  HV *ph = pox_prov_hv(aTHX_ provider);
  const char *name = pox_prov_name(aTHX_ ph);
  HV *flows = pox_flows(aTHX_ c);
  HV *query;
  HV *rec;
  SV *statev, *recsv, *redirect_uri, *tokens, *identity;
  IV t;

  /* $c->req->query */
  {
    SV *q = NULL;
    dSP; int count;
    SV *req = NULL;
    ENTER; SAVETMPS; PUSHMARK(SP); XPUSHs(c); PUTBACK;
    count = call_method("req", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) req = SvREFCNT_inc(POPs);
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    if (!req) croak("no request");
    sv_2mortal(req);
    ENTER; SAVETMPS; PUSHMARK(SP); XPUSHs(req); PUTBACK;
    count = call_method("query", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) q = SvREFCNT_inc(POPs);
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    if (!q || !SvROK(q) || SvTYPE(SvRV(q)) != SVt_PVHV)
      { SvREFCNT_dec(q); croak("no query"); }
    sv_2mortal(q);
    query = (HV *)SvRV(q);
  }

  statev = (hv_fetchs(query, "state", 0) && SvOK(*hv_fetchs(query, "state", 0)))
    ? *hv_fetchs(query, "state", 0) : NULL;
  recsv = NULL;
  if (statev) {
    STRLEN sl;
    const char *sp = SvPV_const(statev, sl);
    SV *got = hv_delete(flows, sp, (I32)sl, 0);  /* delete-on-use */
    if (got) recsv = got;   /* mortal, owned by delete */
  }
  if (!recsv || !SvROK(recsv) || SvTYPE(SvRV(recsv)) != SVt_PVHV)
    croak("login expired or state mismatch");
  rec = (HV *)SvRV(recsv);
  {
    SV **pp = hv_fetchs(rec, "p", 0);
    SV **tp = hv_fetchs(rec, "t", 0);
    t = (tp && *tp) ? SvIV(*tp) : 0;
    if (!pp || !*pp || strNE(SvPV_nolen(*pp), name))
      croak("login expired or state mismatch");
    if (t < (IV)time(NULL) - POX_FLOW_TTL)
      croak("login expired or state mismatch");
  }

  if (hv_fetchs(query, "error", 0)
      && SvOK(*hv_fetchs(query, "error", 0)))
    croak("provider returned an error");

  /* iss mix-up defense */
  {
    SV **iss = hv_fetchs(query, "iss", 0);
    SV *pi = pox_prov_get(aTHX_ ph, "issuer");
    if (iss && *iss && SvOK(*iss) && pi) {
      STRLEN al, bl;
      const char *a = SvPV_const(*iss, al);
      const char *b = SvPV_const(pi, bl);
      if (al > 1 && a[al - 1] == '/') al--;
      if (bl > 1 && b[bl - 1] == '/') bl--;
      if (al != bl || memNE(a, b, al)) croak("issuer mismatch");
    }
  }

  if (!hv_fetchs(query, "code", 0)
      || !SvOK(*hv_fetchs(query, "code", 0)))
    croak("no authorization code");

  redirect_uri = sv_2mortal(pox_redirect_uri(aTHX_ c, login, name));
  tokens = pox_prov_exchange(aTHX_ provider, c,
      *hv_fetchs(query, "code", 0), redirect_uri,
      (hv_fetchs(rec, "v", 0) ? *hv_fetchs(rec, "v", 0) : &PL_sv_undef),
      (hv_fetchs(rec, "n", 0) ? *hv_fetchs(rec, "n", 0) : &PL_sv_undef));
  identity = pox_prov_identity(aTHX_ provider, c, tokens);

  /* return_to travels back so the caller can honor it */
  {
    SV **r = hv_fetchs(rec, "r", 0);
    if (r && *r && SvOK(*r))
      (void)hv_stores((HV *)SvRV(identity), "_return_to", newSVsv(*r));
  }

  *out_identity = SvREFCNT_inc(identity);
  *out_tokens   = SvREFCNT_inc(tokens);
}

#endif
