#ifndef PSAML_FLOW_H
#define PSAML_FLOW_H

/* The flow cookie: what is remembered between sending an AuthnRequest and
 * receiving the Response.
 *
 * WHY IT IS NOT THE SESSION, which is the whole reason this file exists.
 * The POST to the assertion consumer comes from the provider's origin. It
 * is a cross-site POST, and a cookie with SameSite=Lax IS NOT SENT on
 * one: Lax covers top-level navigations with safe methods only. Punk's
 * session cookie is Lax, as it should be, so at the moment the assertion
 * arrives the session is not there and a flow record kept in it is
 * unreachable. Every login would fail `in_response_to`, and only in
 * browsers new enough to default to Lax, which by now is all of them.
 * The industry spent 2020 learning this.
 *
 * So the record lives in a cookie of the plugin's own, SameSite=None,
 * which browsers only send with Secure, which is why phase 4 croaks
 * unless `host` is https.
 *
 * NOT ENCRYPTED, signed only. There is nothing in a record that was not
 * already in the AuthnRequest the browser carried in a URL a moment ago.
 * The signature is not for secrecy, it is so the record cannot be
 * written by anyone but us.
 *
 * Must be included after psaml_boot.h. */

#include "psaml_abi.h"
#include "psaml_b64.h"
#include "psaml_clos.h"

#define PSAML_FLOW_COOKIE "_saml_flow"
#define PSAML_FLOW_KEEP   5

/* ---- the serialised form ----------------------------------------------- */

/* Records are `id|idp|to|issued` joined by tabs and newline-separated,
 * base64url'd, then `.` and the MAC. The fields cannot contain a tab or a
 * newline: an id is hex, a provider name is a bareword, and `to` has been
 * through safe_path. Anything that did contain one would be a record this
 * dist did not write, and the MAC catches that first. */

PERL_STATIC_INLINE SV *psaml_flow_mac(pTHX_ SV *payload, SV *secret) {
  STRLEN pl, sl;
  const unsigned char *pp = (const unsigned char *)SvPVbyte(payload, pl);
  const unsigned char *sp = (const unsigned char *)SvPVbyte(secret, sl);
  return psaml_jws(aTHX)->hmac_sha256(aTHX_ sp, sl, pp, pl);
}

/* The signing key is the FIRST of a `secret` list, and every one of them
 * verifies. That is what lets a key be rotated with both live: deploy the
 * new one at the front, and the cookies signed by the old one keep
 * working until they expire. */
PERL_STATIC_INLINE SV *psaml_secret_at(pTHX_ SV *secret, SSize_t i) {
  if (psaml_is_array(aTHX_ secret)) {
    AV *av = (AV *)SvRV(secret);
    SV **e = av_fetch(av, i, 0);
    return (e && *e && SvOK(*e)) ? *e : NULL;
  }
  return i == 0 ? secret : NULL;
}

PERL_STATIC_INLINE SV *psaml_flow_serialise(pTHX_ AV *records, SV *secret) {
  SV *payload = sv_2mortal(newSVpvs(""));
  SV *b64, *mac, *out;
  SSize_t i, n = av_len(records) + 1;
  SV *key = psaml_secret_at(aTHX_ secret, 0);

  for (i = 0; i < n; i++) {
    SV **e = av_fetch(records, i, 0);
    HV *r;
    SV *v;
    if (!e || !*e || !SvROK(*e)) continue;
    r = (HV *)SvRV(*e);
    if (SvCUR(payload)) sv_catpvs(payload, "\n");
    v = psaml_hget(aTHX_ r, "id");    if (v) sv_catsv(payload, v);
    sv_catpvs(payload, "\t");
    v = psaml_hget(aTHX_ r, "idp");   if (v) sv_catsv(payload, v);
    sv_catpvs(payload, "\t");
    v = psaml_hget(aTHX_ r, "to");    if (v) sv_catsv(payload, v);
    sv_catpvs(payload, "\t");
    v = psaml_hget(aTHX_ r, "issued");
    sv_catpvf(payload, "%" IVdf, v ? SvIV(v) : 0);
  }

  {
    STRLEN pl;
    const unsigned char *pp = (const unsigned char *)SvPVbyte(payload, pl);
    b64 = sv_2mortal(psaml_jws(aTHX)->b64url(aTHX_ pp, pl));
  }
  if (!key) croak("%s: the flow cookie has no secret to sign with",
                  PSAML_WHO);
  mac = psaml_flow_mac(aTHX_ b64, key);
  if (!mac) croak("%s: the flow cookie MAC failed", PSAML_WHO);
  sv_2mortal(mac);

  out = newSVsv(b64);
  sv_catpvs(out, ".");
  {
    STRLEN ml;
    const unsigned char *mp = (const unsigned char *)SvPVbyte(mac, ml);
    SV *m64 = sv_2mortal(psaml_jws(aTHX)->b64url(aTHX_ mp, ml));
    sv_catsv(out, m64);
  }
  return out;
}

/* Parse and verify. Returns a +1 AV of records, EMPTY when the cookie is
 * absent, malformed, or does not verify.
 *
 * A tampered cookie reads as no cookie rather than an exception. A
 * browser holding a stale record from a previous deployment, or a cookie
 * somebody edited, should get `unsolicited` and a "sign in again" page,
 * not a 500 and a stack trace in the log. */
PERL_STATIC_INLINE AV *psaml_flow_parse(pTHX_ SV *cookie, SV *secret,
                                        IV now, IV ttl) {
  AV *out = newAV();
  const jws_abi *J;
  STRLEN cl;
  const char *cp;
  const char *dot;
  SV *b64, *given, *want;
  SSize_t k;
  int ok = 0;

  if (!cookie || !SvOK(cookie) || !SvCUR(cookie)) return out;
  J = psaml_jws(aTHX);
  cp = SvPVbyte(cookie, cl);
  dot = (const char *)memchr(cp, '.', cl);
  if (!dot) return out;

  b64   = sv_2mortal(newSVpvn(cp, (STRLEN)(dot - cp)));
  given = sv_2mortal(J->b64url_decode(aTHX_ dot + 1,
                                      cl - (STRLEN)(dot - cp) - 1));
  if (!given) return out;

  /* every configured secret verifies; the first signs. ct_eq because a
   * timing difference here is a byte-at-a-time forgery of the MAC. */
  for (k = 0; !ok; k++) {
    SV *key = psaml_secret_at(aTHX_ secret, k);
    if (!key) break;
    want = psaml_flow_mac(aTHX_ b64, key);
    if (!want) continue;
    sv_2mortal(want);
    {
      STRLEN al, bl;
      const unsigned char *ap = (const unsigned char *)SvPVbyte(want, al);
      const unsigned char *bp = (const unsigned char *)SvPVbyte(given, bl);
      ok = J->ct_eq(aTHX_ ap, al, bp, bl);
    }
  }
  if (!ok) return out;

  {
    SV *plain = sv_2mortal(J->b64url_decode(aTHX_ SvPVX(b64), SvCUR(b64)));
    STRLEN pl;
    const char *pp;
    const char *line, *end;
    if (!plain) return out;
    pp = SvPVbyte(plain, pl);
    line = pp;
    end  = pp + pl;
    while (line < end) {
      const char *nl = (const char *)memchr(line, '\n', (STRLEN)(end - line));
      const char *stop = nl ? nl : end;
      const char *f[4];
      STRLEN fl[4];
      int nf = 0;
      const char *s = line;
      while (nf < 4 && s <= stop) {
        const char *tab = (const char *)memchr(s, '\t', (STRLEN)(stop - s));
        const char *fe = (nf == 3 || !tab) ? stop : tab;
        f[nf] = s;
        fl[nf] = (STRLEN)(fe - s);
        nf++;
        if (fe == stop) break;
        s = fe + 1;
      }
      if (nf == 4) {
        IV issued = 0;
        STRLEN i;
        for (i = 0; i < fl[3]; i++)
          if (f[3][i] >= '0' && f[3][i] <= '9')
            issued = issued * 10 + (f[3][i] - '0');
        /* one older than flow_ttl is dropped on read as well as on
         * write, so a cookie that outlived a deploy cannot resurrect a
         * flow the browser has forgotten about */
        if (!ttl || issued + ttl > now) {
          HV *r = newHV();
          (void)hv_stores(r, "id",     newSVpvn(f[0], fl[0]));
          (void)hv_stores(r, "idp",    newSVpvn(f[1], fl[1]));
          (void)hv_stores(r, "to",     newSVpvn(f[2], fl[2]));
          (void)hv_stores(r, "issued", newSViv(issued));
          av_push(out, newRV_noinc((SV *)r));
        }
      }
      if (!nl) break;
      line = nl + 1;
    }
  }
  return out;
}

/* Add a record, keeping the newest PSAML_FLOW_KEEP.
 *
 * Several coexist because a user opens two tabs and starts two logins,
 * and the second must not evict the first. Five is enough for that and
 * small enough that the cookie stays well inside every browser's
 * per-cookie limit. */
PERL_STATIC_INLINE void psaml_flow_add(pTHX_ AV *records, SV *rec) {
  av_push(records, rec);
  while (av_len(records) + 1 > PSAML_FLOW_KEEP) {
    SV *old = av_shift(records);
    SvREFCNT_dec(old);
  }
}

/* Remove the record with this id and return it (+1), or NULL.
 *
 * The ACS calls this and writes the cookie back BEFORE verifying
 * anything: one flow answers once, whichever way the verification goes.
 * A record left in place on failure would let an attacker retry a
 * tampered assertion against the same flow until something got through. */
PERL_STATIC_INLINE SV *psaml_flow_take(pTHX_ AV *records, SV *id) {
  SSize_t i, n = av_len(records) + 1;
  for (i = 0; i < n; i++) {
    SV **e = av_fetch(records, i, 0);
    HV *r;
    SV *rid;
    if (!e || !*e || !SvROK(*e)) continue;
    r = (HV *)SvRV(*e);
    rid = psaml_hget(aTHX_ r, "id");
    if (rid && sv_eq(rid, id)) {
      /* +1 first, then G_DISCARD.
       *
       * av_delete WITHOUT G_DISCARD hands the element back already
       * mortalised: it takes the array's reference and puts it on the
       * temps stack. Incrementing as well and then mortalising in the
       * caller decrements it twice, which surfaces as "Attempt to free
       * unreferenced scalar" one request later. G_DISCARD drops the
       * array's reference and mortalises nothing, so this returns a
       * clean +1 the caller owns. */
      SV *found = SvREFCNT_inc_simple_NN(*e);
      (void)av_delete(records, i, G_DISCARD);
      return found;
    }
  }
  return NULL;
}

/* The Set-Cookie value.
 *
 * Every attribute here is load-bearing:
 *   SameSite=None  the only value a browser sends on the cross-site POST
 *                  from the provider. Lax is not sent; Strict is not sent.
 *   Secure         which None REQUIRES, or the browser drops the cookie
 *                  silently. This is why host must be https.
 *   Path=<mount>   so it travels on the two requests that need it, and no
 *                  other request in the application carries it.
 *   HttpOnly       nothing in the page needs it. */
PERL_STATIC_INLINE SV *psaml_flow_cookie(pTHX_ SV *value, SV *mount, IV ttl) {
  SV *out = newSVpvs(PSAML_FLOW_COOKIE "=");
  if (value && SvOK(value)) sv_catsv(out, value);
  sv_catpvs(out, "; Path=");
  if (mount && SvOK(mount) && SvCUR(mount)) sv_catsv(out, mount);
  else sv_catpvs(out, "/");
  sv_catpvf(out, "; Max-Age=%" IVdf, ttl);
  sv_catpvs(out, "; HttpOnly; Secure; SameSite=None");
  return out;
}

#endif /* PSAML_FLOW_H */
