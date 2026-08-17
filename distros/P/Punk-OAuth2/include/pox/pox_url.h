#ifndef POX_URL_H
#define POX_URL_H

#include "pox_abi.h"
#include "pox_util.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <netinet/in.h>
#include <arpa/inet.h>

/* $c->req->env as an HV*, or NULL. */
static HV *pox_req_env(pTHX_ SV *c) {
  SV *req = NULL, *env = NULL;
  dSP;
  int count;
  ENTER; SAVETMPS;
  PUSHMARK(SP); XPUSHs(c); PUTBACK;
  count = call_method("req", G_SCALAR | G_EVAL);
  SPAGAIN;
  if (!SvTRUE(ERRSV) && count > 0) req = SvREFCNT_inc(POPs);
  else if (count > 0) (void)POPs;
  PUTBACK; FREETMPS; LEAVE;
  if (!req) return NULL;
  sv_2mortal(req);
  ENTER; SAVETMPS;
  PUSHMARK(SP); XPUSHs(req); PUTBACK;
  count = call_method("env", G_SCALAR | G_EVAL);
  SPAGAIN;
  if (!SvTRUE(ERRSV) && count > 0) env = SvREFCNT_inc(POPs);
  else if (count > 0) (void)POPs;
  PUTBACK; FREETMPS; LEAVE;
  if (!env) return NULL;
  sv_2mortal(env);
  if (!SvROK(env) || SvTYPE(SvRV(env)) != SVt_PVHV) return NULL;
  return (HV *)SvRV(env);
}

static const char *pox_env_str(pTHX_ HV *env, const char *key) {
  SV **v = hv_fetch(env, key, (I32)strlen(key), 0);
  return (v && *v && SvOK(*v)) ? SvPV_nolen(*v) : NULL;
}

/* base_url($c, $cfg): configured cfg->{base_url} wins (trailing slash
 * stripped); otherwise scheme://host from the env, honoring
 * X-Forwarded-Proto/Host only when cfg->{trust_proxy}. Returns a fresh
 * owned SV; croaks when no host can be determined. */
static SV *pox_base_url(pTHX_ SV *c, SV *cfg) {
  HV *cfgh = (SvROK(cfg) && SvTYPE(SvRV(cfg)) == SVt_PVHV)
    ? (HV *)SvRV(cfg) : NULL;
  SV **bu = cfgh ? hv_fetchs(cfgh, "base_url", 0) : NULL;
  HV *env;
  const char *scheme = NULL, *host = NULL;
  SV *out;
  STRLEN sl;

  if (bu && *bu && SvOK(*bu)) {
    const char *p = SvPV_const(*bu, sl);
    return newSVsv(pox_rstrip_slash(aTHX_ p, sl));
  }
  env = pox_req_env(aTHX_ c);
  if (!env) croak("Punk::OAuth2: cannot read the request env for base_url");
  {
    SV **tp = cfgh ? hv_fetchs(cfgh, "trust_proxy", 0) : NULL;
    if (tp && *tp && SvTRUE(*tp)) {
      scheme = pox_env_str(aTHX_ env, "HTTP_X_FORWARDED_PROTO");
      host   = pox_env_str(aTHX_ env, "HTTP_X_FORWARDED_HOST");
    }
  }
  if (!scheme) scheme = pox_env_str(aTHX_ env, "psgi.url_scheme");
  if (!scheme) scheme = "https";
  if (!host)   host   = pox_env_str(aTHX_ env, "HTTP_HOST");
  if (!host || !*host)
    croak("Punk::OAuth2: cannot derive a base URL - configure base_url "
          "(or trust_proxy behind a proxy)");
  out = newSVpv("", 0);
  {
    const char *s;
    for (s = scheme; *s; s++)
      if (*s >= 'a' && *s <= 'z') sv_catpvn(out, s, 1);
      else if (*s >= 'A' && *s <= 'Z') { char c = *s + 32; sv_catpvn(out, &c, 1); }
  }
  sv_catpvs(out, "://");
  sv_catpv(out, host);
  return out;
}

static int pox_ip_is_private(const char *ip) {
  /* IPv4 dotted */
  unsigned a, b, cc, d;
  if (sscanf(ip, "%u.%u.%u.%u", &a, &b, &cc, &d) == 4) {
    if (a == 10 || a == 127 || a == 0) return 1;
    if (a == 169 && b == 254) return 1;
    if (a == 192 && b == 168) return 1;
    if (a == 172 && b >= 16 && b <= 31) return 1;
    return 0;
  }
  /* IPv6 textual */
  if (strcmp(ip, "::1") == 0) return 1;
  if (strncasecmp(ip, "fe80", 4) == 0) return 1;
  if (strncasecmp(ip, "fc", 2) == 0) return 1;
  if (strncasecmp(ip, "fd", 2) == 0) return 1;
  return 0;
}

/* safe_url($url, allow_local): https-only (http allowed to loopback
 * under allow_local), no credentials, host must resolve to public
 * addresses. Returns 1 (ok) or 0 with *why set to a static reason. */
static int pox_safe_url(pTHX_ SV *urlsv, int allow_local, const char **why) {
  STRLEN ul;
  const char *u = SvOK(urlsv) ? SvPV_const(urlsv, ul) : NULL;
  char scheme[8];
  const char *p, *authority_end, *host_start, *host_end;
  char host[256];
  size_t hlen;
  int is_https, is_local;
  struct addrinfo hints, *res = NULL, *ai;

  *why = "not an absolute URL";
  if (!u) return 0;

  if (strncasecmp(u, "https://", 8) == 0) { is_https = 1; p = u + 8; }
  else if (strncasecmp(u, "http://", 7) == 0) { is_https = 0; p = u + 7; }
  else return 0;
  (void)scheme;

  /* authority ends at / ? # or end */
  authority_end = p;
  while (*authority_end && *authority_end != '/'
         && *authority_end != '?' && *authority_end != '#')
    authority_end++;
  /* credentials? */
  {
    const char *at;
    for (at = p; at < authority_end; at++)
      if (*at == '@') { *why = "credentials in URL"; return 0; }
  }
  /* host: strip optional [..]  and :port */
  host_start = p;
  if (*host_start == '[') {
    host_start++;
    host_end = host_start;
    while (host_end < authority_end && *host_end != ']') host_end++;
  }
  else {
    host_end = host_start;
    while (host_end < authority_end && *host_end != ':') host_end++;
  }
  hlen = (size_t)(host_end - host_start);
  if (hlen == 0 || hlen >= sizeof host) { *why = "no host"; return 0; }
  memcpy(host, host_start, hlen);
  host[hlen] = '\0';

  is_local = (strcmp(host, "localhost") == 0
              || strncmp(host, "127.", 4) == 0
              || strcmp(host, "::1") == 0
              || strcmp(host, "0.0.0.0") == 0);

  if (allow_local) {
    if (is_local || is_https) return 1;
    *why = "http is only allowed to loopback";
    return 0;
  }
  if (!is_https) { *why = "https required"; return 0; }
  if (is_local)  { *why = "loopback host"; return 0; }

  memset(&hints, 0, sizeof hints);
  hints.ai_socktype = SOCK_STREAM;
  if (getaddrinfo(host, NULL, &hints, &res) != 0 || !res) {
    *why = "unresolvable host";
    return 0;
  }
  for (ai = res; ai; ai = ai->ai_next) {
    char ip[INET6_ADDRSTRLEN] = "";
    void *addr = NULL;
    if (ai->ai_family == AF_INET)
      addr = &((struct sockaddr_in *)ai->ai_addr)->sin_addr;
    else if (ai->ai_family == AF_INET6)
      addr = &((struct sockaddr_in6 *)ai->ai_addr)->sin6_addr;
    if (addr && inet_ntop(ai->ai_family, addr, ip, sizeof ip)
        && pox_ip_is_private(ip)) {
      freeaddrinfo(res);
      *why = "private address";
      return 0;
    }
  }
  freeaddrinfo(res);
  return 1;
}

/* await($c, $value): $c->await for a Punk::Future (parks under
 * Hyperman); ->get for any other future; passthrough otherwise.
 * Returns a fresh owned SV. */
static SV *pox_await(pTHX_ SV *c, SV *value) {
  int is_future = SvROK(value) && sv_isobject(value);
  int has_get = 0;
  if (is_future) {
    dSP;
    int count;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(value);
    XPUSHs(sv_2mortal(newSVpvs("get")));
    PUTBACK;
    count = call_method("can", G_SCALAR | G_EVAL);
    SPAGAIN;
    /* POP first: SvTRUE multi-evaluates its argument on older perls. */
    if (!SvTRUE(ERRSV) && count > 0) { SV *r = POPs; has_get = SvTRUE(r); }
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
  }
  if (!has_get) return newSVsv(value);

  if (SvOK(c) && sv_derived_from(value, "Punk::Future")) {
    SV *r = NULL;
    dSP;
    int count;
    ENTER; SAVETMPS;
    PUSHMARK(SP); XPUSHs(c); XPUSHs(value); PUTBACK;
    count = call_method("await", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) r = SvREFCNT_inc(POPs);
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    if (r) return r;
  }
  {
    SV *r = NULL;
    dSP;
    int count;
    ENTER; SAVETMPS;
    PUSHMARK(SP); XPUSHs(value); PUTBACK;
    count = call_method("get", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) r = SvREFCNT_inc(POPs);
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    return r ? r : newSV(0);
  }
}

#endif
