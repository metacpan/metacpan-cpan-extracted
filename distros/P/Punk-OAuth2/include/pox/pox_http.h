#ifndef POX_HTTP_H
#define POX_HTTP_H

#include "pox_abi.h"

/* The fetch_abi map callback: shape the settled request into a
 * [status, body] arrayref the caller reads directly. The abi invokes
 * map unconditionally (no NULL guard), so this must always be passed.
 * Must not croak; returns a +1-owned SV. */
static SV *pox_fetch_map(pTHX_ int ok, int status, AV *headers,
                         SV *body, SV *err, void *ud) {
  AV *out = newAV();
  PERL_UNUSED_ARG(headers);
  PERL_UNUSED_ARG(err);
  PERL_UNUSED_ARG(ud);
  av_push(out, newSViv(ok ? status : 0));
  av_push(out, (ok && body && SvOK(body)) ? newSVsv(body) : newSV(0));
  return newRV_noinc((SV *)out);
}

/* Resolve the UA to drive an HTTP call from a stored `ua` slot and the
 * optional request context: a coderef is called with $c; an object is
 * used as-is; else $c->ua; else a lazily-built private Fetch cached in
 * *own_ua_slot. Returns a mortal UA SV, or NULL if none is available. */
static SV *pox_resolve_ua(pTHX_ SV *ua, SV *c, SV **own_ua_slot) {
  if (ua && SvOK(ua)) {
    if (SvROK(ua) && SvTYPE(SvRV(ua)) == SVt_PVCV) {
      dSP;
      int count;
      SV *r = NULL;
      ENTER; SAVETMPS;
      PUSHMARK(SP);
      if (c && SvOK(c)) XPUSHs(c);
      PUTBACK;
      count = call_sv(ua, G_SCALAR | G_EVAL);
      SPAGAIN;
      if (!SvTRUE(ERRSV) && count > 0) r = SvREFCNT_inc(POPs);
      else if (count > 0) (void)POPs;
      PUTBACK; FREETMPS; LEAVE;
      return r ? sv_2mortal(r) : NULL;
    }
    return ua;   /* an object */
  }
  if (c && SvOK(c)) {
    dSP;
    int count;
    SV *r = NULL;
    ENTER; SAVETMPS;
    PUSHMARK(SP); XPUSHs(c); PUTBACK;
    count = call_method("ua", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) r = SvREFCNT_inc(POPs);
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    if (r) return sv_2mortal(r);
  }
  if (own_ua_slot) {
    if (!*own_ua_slot || !SvOK(*own_ua_slot)) {
      dSP;
      int count;
      SV *r = NULL;
      eval_pv("require Fetch;", FALSE);
      ENTER; SAVETMPS;
      PUSHMARK(SP);
      XPUSHs(sv_2mortal(newSVpvs("Fetch")));
      XPUSHs(sv_2mortal(newSVpvs("timeout")));
      XPUSHs(sv_2mortal(newSViv(10)));
      PUTBACK;
      count = call_method("new", G_SCALAR | G_EVAL);
      SPAGAIN;
      if (!SvTRUE(ERRSV) && count > 0) r = SvREFCNT_inc(POPs);
      else if (count > 0) (void)POPs;
      PUTBACK; FREETMPS; LEAVE;
      if (!r) return NULL;
      *own_ua_slot = r;   /* stored, owned by the caller's slot */
    }
    return *own_ua_slot;
  }
  return NULL;
}

/* One HTTP request, returning the decoded JSON body as an SV (mortal)
 * plus the status through *status_out. The UA is either a real Fetch
 * object (driven through fetch_abi->request + res_parts) or any object
 * with get/post/request returning a future (the test seam) - detected
 * once. Body/headers are built in C. Returns NULL (status still set) on
 * a transport error or a non-JSON body.
 *
 * headers is a hashref of scalar values; body may be NULL (GET). */

static SV *pox_http_json(pTHX_ SV *ua, const char *method,
                         const char *url, HV *headers, SV *body,
                         int *status_out) {
  int is_fetch = SvROK(ua) && sv_isobject(ua)
              && sv_derived_from(ua, "Fetch");
  SV *future = NULL, *res = NULL, *bodysv = NULL;
  int status = 0;
  *status_out = 0;

  if (is_fetch) {
    const fetch_abi *F = pox_fetch(aTHX);
    fetch_hdr hdrs[16];
    int nh = 0;
    HE *he;
    STRLEN blen = 0;
    const char *bp = body && SvOK(body) ? SvPVbyte(body, blen) : NULL;
    if (headers) {
      hv_iterinit(headers);
      while ((he = hv_iternext(headers)) && nh < 16) {
        SV *v = HeVAL(he);
        STRLEN vl;
        const char *vp;
        if (!SvOK(v)) continue;
        vp = SvPV_const(v, vl);
        hdrs[nh].name = HePV(he, hdrs[nh].nlen);
        hdrs[nh].val  = vp;
        hdrs[nh].vlen = vl;
        nh++;
      }
    }
    future = F->request(aTHX_ ua, method, url, hdrs, nh, bp, blen,
                        0.0, -1, pox_fetch_map, NULL);
  }
  else {
    /* test seam: $ua->get($url) / $ua->post($url, headers=>.., body=>..) */
    dSP;
    int count;
    char meth[8];
    STRLEN i;
    for (i = 0; method[i] && i < 7; i++) meth[i] = toLOWER(method[i]);
    meth[i] = '\0';
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(ua);
    XPUSHs(sv_2mortal(newSVpv(url, 0)));
    if (headers || body) {
      XPUSHs(sv_2mortal(newSVpvs("headers")));
      XPUSHs(sv_2mortal(newRV_inc((SV *)(headers ? headers : newHV()))));
      if (body && SvOK(body)) {
        XPUSHs(sv_2mortal(newSVpvs("body")));
        XPUSHs(body);
      }
    }
    PUTBACK;
    count = call_method(meth, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) {
      future = POPs;
      SvREFCNT_inc_simple_void_NN(future);
    }
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    if (SvTRUE(ERRSV) || !future) { SvREFCNT_dec(future); return NULL; }
    sv_2mortal(future);
  }
  if (is_fetch) sv_2mortal(future);

  /* resolve the future: ->get */
  {
    dSP;
    int count;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(future);
    PUTBACK;
    count = call_method("get", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) {
      res = POPs;
      SvREFCNT_inc_simple_void_NN(res);
    }
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    if (SvTRUE(ERRSV) || !res) { SvREFCNT_dec(res); return NULL; }
    sv_2mortal(res);
  }

  /* status + body */
  if (is_fetch && SvROK(res) && SvTYPE(SvRV(res)) == SVt_PVAV) {
    /* our map shaped it into [status, body] */
    AV *pair = (AV *)SvRV(res);
    SV **s = av_fetch(pair, 0, 0);
    SV **b = av_fetch(pair, 1, 0);
    status = (s && *s) ? (int)SvIV(*s) : 0;
    bodysv = (b && *b) ? *b : NULL;
  }
  else {
    dSP;
    int count;
    ENTER; SAVETMPS;
    PUSHMARK(SP); XPUSHs(res); PUTBACK;
    count = call_method("status", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) status = (int)POPi;
    else if (count > 0) (void)POPs;
    PUTBACK;
    PUSHMARK(SP); XPUSHs(res); PUTBACK;
    count = call_method("content", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) {
      bodysv = POPs;
      SvREFCNT_inc_simple_void_NN(bodysv);
    }
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    if (bodysv) sv_2mortal(bodysv);
  }
  *status_out = status;
  if (!bodysv || !SvOK(bodysv)) return NULL;

  /* decode JSON via frj, tolerating malformed bodies */
  {
    STRLEN jl;
    const char *jp = SvPVbyte(bodysv, jl);
    SV *decoded;
    dSP;
    int count;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvn(jp, jl)));
    PUTBACK;
    count = call_pv("File::Raw::JSON::file_json_decode",
                    G_SCALAR | G_EVAL);
    SPAGAIN;
    decoded = NULL;
    if (!SvTRUE(ERRSV) && count > 0) {
      SV *d = POPs;
      decoded = SvREFCNT_inc_simple_NN(d);
    }
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    return decoded ? sv_2mortal(decoded) : NULL;
  }
}

#endif
