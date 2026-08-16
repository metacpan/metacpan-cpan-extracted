#ifndef POX_UTIL_H
#define POX_UTIL_H

#include "pox_abi.h"

/* RFC 3986 unreserved: A-Z a-z 0-9 - . _ ~ */
static int pox_unreserved(unsigned char c) {
  return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
      || (c >= '0' && c <= '9')
      || c == '-' || c == '.' || c == '_' || c == '~';
}

/* Percent-encode into a fresh mortal SV. */
static SV *pox_uri_escape(pTHX_ const char *s, STRLEN n) {
  SV *out = sv_2mortal(newSV(n * 3 + 1));
  STRLEN i;
  const char *hex = "0123456789ABCDEF";
  SvPOK_on(out);
  SvCUR_set(out, 0);
  for (i = 0; i < n; i++) {
    unsigned char c = (unsigned char)s[i];
    if (pox_unreserved(c)) {
      sv_catpvn(out, (char *)&c, 1);
    }
    else {
      char buf[3];
      buf[0] = '%'; buf[1] = hex[c >> 4]; buf[2] = hex[c & 15];
      sv_catpvn(out, buf, 3);
    }
  }
  return out;
}

/* Percent-decode (with + as space) into a fresh mortal SV. */
static SV *pox_urldecode(pTHX_ const char *s, STRLEN n) {
  SV *out = sv_2mortal(newSV(n + 1));
  STRLEN i;
  SvPOK_on(out);
  SvCUR_set(out, 0);
  for (i = 0; i < n; i++) {
    if (s[i] == '+') { sv_catpvs(out, " "); }
    else if (s[i] == '%' && i + 2 < n && isXDIGIT(s[i+1]) && isXDIGIT(s[i+2])) {
      int hi = (s[i+1] <= '9') ? s[i+1]-'0'
             : (s[i+1] | 0x20) - 'a' + 10;
      int lo = (s[i+2] <= '9') ? s[i+2]-'0'
             : (s[i+2] | 0x20) - 'a' + 10;
      char c = (char)((hi << 4) | lo);
      sv_catpvn(out, &c, 1);
      i += 2;
    }
    else sv_catpvn(out, s + i, 1);
  }
  return out;
}

/* Build a sorted, percent-encoded x-www-form-urlencoded body from a
 * hashref of scalar pairs. Undef values are skipped. */
static SV *pox_form_from_hv(pTHX_ HV *pairs) {
  AV *keys = newAV();
  SV *out = newSV(64);
  SSize_t i, n;
  HE *he;
  SvPOK_on(out);
  SvCUR_set(out, 0);
  sv_2mortal((SV *)keys);
  hv_iterinit(pairs);
  while ((he = hv_iternext(pairs))) {
    SV *v = HeVAL(he);
    STRLEN kl;
    const char *kp;
    if (!SvOK(v)) continue;
    kp = HePV(he, kl);
    av_push(keys, newSVpvn(kp, kl));
  }
  sortsv(AvARRAY(keys), av_count(keys), Perl_sv_cmp);
  n = av_count(keys);
  for (i = 0; i < n; i++) {
    SV *ksv = *av_fetch(keys, i, 0);
    STRLEN kl, vl;
    const char *kp = SvPV_const(ksv, kl);
    SV **vp = hv_fetch(pairs, kp, (I32)kl, 0);
    const char *vv = SvPV_const(*vp, vl);
    if (i) sv_catpvs(out, "&");
    sv_catsv(out, pox_uri_escape(aTHX_ kp, kl));
    sv_catpvs(out, "=");
    sv_catsv(out, pox_uri_escape(aTHX_ vv, vl));
  }
  return out;   /* owned */
}

/* A ?return= destination must be a same-origin relative path: leading
 * slash, not protocol-relative, no CR/LF. Returns the (mortal) path or
 * NULL. */
static SV *pox_same_origin_path(pTHX_ SV *path) {
  STRLEN n;
  const char *p;
  STRLEN i;
  if (!SvOK(path)) return NULL;
  p = SvPV_const(path, n);
  if (n < 1 || p[0] != '/') return NULL;
  if (n >= 2 && p[1] == '/') return NULL;
  for (i = 0; i < n; i++)
    if (p[i] == '\r' || p[i] == '\n') return NULL;
  return path;
}

/* strip a single trailing '/' (not the root) into a mortal SV */
static SV *pox_rstrip_slash(pTHX_ const char *s, STRLEN n) {
  if (n > 1 && s[n - 1] == '/') n--;
  return sv_2mortal(newSVpvn(s, n));
}

#endif
