#ifndef PUNK_PROXY_H
#define PUNK_PROXY_H

/* punk_proxy.h - reverse-proxy trust, in C.
 *
 * The `proxy` keyword freezes a trust policy at to_app; pp_resolve runs once
 * at the top of punk_serve, before routing, and OVERWRITES REMOTE_ADDR with
 * the real client. Everything downstream - rate_limit (punk_ratelimit.h),
 * $c->block_ip, the access log, $c->req->address - then reads the right
 * address without any of them being changed. The mount path already rewrites
 * env keys in place (punk_serve.h), so this is an established move.
 *
 * Why it exists: rate_limit keys on REMOTE_ADDR, and because Hyperman's
 * arena makes a counter exact across the whole worker pool rather than per
 * worker, a limiter behind a proxy puts EVERY client in one bucket - a
 * 100/min rule throttles the whole site at 100/min. block_ip, keyed the same
 * way, bans the load balancer.
 *
 * The hop rule, which is what almost every implementation gets wrong:
 * X-Forwarded-For reads `client, proxy1, proxy2` and each hop APPENDS the
 * address it received the connection FROM. The socket peer is the last
 * proxy and never appears in the header it forwarded. So with N trusted
 * proxies the client sits at index N-1 counting from the RIGHT. Taking the
 * leftmost entry is the spoofable version: the client writes that one.
 *
 * Everything here is prefixed pp_ / PP_. Needs nothing but punk_compat.h;
 * included before punk_serve.h, which calls pp_resolve.
 */

#include <string.h>

/* A chain longer than this is pathological. We keep the RIGHTMOST entries,
 * which is the end the hop walk starts from; 'all' mode scans forward for
 * the leftmost separately and is unaffected. */
#define PP_MAX_HOPS 32

/* Addresses are held as 16 bytes, v4 stored v4-mapped (::ffff:a.b.c.d), so
 * one compare serves both families and a v4 CIDR written by an operator
 * still matches the v4-mapped form a dual-stack listener hands us. */
typedef struct {
    unsigned char addr[16];
    int           bits;        /* prefix length in the 128-bit space */
} pp_cidr;

typedef struct {
    int      hops;             /* >0 fixed count; 0 = use cidrs; -1 = all */
    pp_cidr *cidrs;
    int      ncidrs;
    char    *for_key;          /* pre-built env keys: HTTP_X_FORWARDED_FOR */
    STRLEN   for_len;
    char    *proto_key;
    STRLEN   proto_len;
    char    *host_key;
    STRLEN   host_len;
    char    *port_key;
    STRLEN   port_len;
} pp_policy;

static void pp_free(pTHX_ pp_policy *p);   /* the error path in pp_compile */

/* ---- address parsing ----------------------------------------------------
 * Hand-rolled rather than inet_pton: this runs on attacker-controlled bytes
 * that become a shared-memory key, the grammar wanted here is stricter than
 * the libc one (no octal, no shortened v4), and it keeps the Windows story
 * free of ws2tcpip.h. */

/* Strict dotted quad: four decimal octets, no leading zeros (a leading zero
 * is octal to some resolvers and decimal to others, which is exactly the
 * ambiguity an address filter must not inherit), nothing trailing. */
static int pp_parse_v4(const char *s, STRLEN len, unsigned char out[4]) {
    STRLEN i = 0;
    int oct;
    for (oct = 0; oct < 4; oct++) {
        int v = 0, nd = 0;
        if (oct) {
            if (i >= len || s[i] != '.') return 0;
            i++;
        }
        while (i < len && s[i] >= '0' && s[i] <= '9') {
            if (nd == 0 && s[i] == '0' && i + 1 < len
                && s[i + 1] >= '0' && s[i + 1] <= '9')
                return 0;                       /* leading zero */
            v = v * 10 + (s[i] - '0');
            if (v > 255) return 0;
            nd++; i++;
            if (nd > 3) return 0;
        }
        if (!nd) return 0;
        out[oct] = (unsigned char)v;
    }
    return i == len;
}

/* RFC 4291 text form, including `::` compression and an embedded v4 tail. */
static int pp_parse_v6(const char *s, STRLEN len, unsigned char out[16]) {
    unsigned char b[16];
    int gi = 0, dc = -1;
    STRLEN i = 0;

    memset(b, 0, sizeof(b));
    if (len < 2) return 0;
    if (s[0] == ':') {
        if (s[1] != ':') return 0;              /* a lone leading ':' */
        dc = 0; i = 2;
        if (i == len) { memcpy(out, b, 16); return 1; }   /* "::" */
    }

    for (;;) {
        STRLEN j = i;
        int hex = 0, nd = 0, isv4 = 0;
        if (gi >= 8) return 0;
        while (j < len && s[j] != ':') {
            if (s[j] == '.') { isv4 = 1; break; }
            j++;
        }
        if (isv4) {
            unsigned char v4[4];
            STRLEN k = i;
            while (k < len && s[k] != ':') k++;
            if (k != len) return 0;             /* the v4 tail must be last */
            if (gi > 6) return 0;
            if (!pp_parse_v4(s + i, len - i, v4)) return 0;
            memcpy(b + gi * 2, v4, 4);
            gi += 2;
            break;
        }
        while (i < j) {
            int c = (unsigned char)s[i], v;
            if      (c >= '0' && c <= '9') v = c - '0';
            else if (c >= 'a' && c <= 'f') v = c - 'a' + 10;
            else if (c >= 'A' && c <= 'F') v = c - 'A' + 10;
            else return 0;
            hex = (hex << 4) | v;
            nd++;
            if (nd > 4) return 0;
            i++;
        }
        if (!nd) return 0;
        b[gi * 2]     = (unsigned char)(hex >> 8);
        b[gi * 2 + 1] = (unsigned char)(hex & 0xff);
        gi++;
        if (i == len) break;
        i++;                                    /* the ':' */
        if (i < len && s[i] == ':') {
            if (dc >= 0) return 0;              /* a second '::' */
            dc = gi;
            i++;
            if (i == len) break;
        } else if (i == len) {
            return 0;                           /* a trailing single ':' */
        }
    }

    if (dc < 0) {
        if (gi != 8) return 0;
        memcpy(out, b, 16);
        return 1;
    }
    if (gi >= 8) return 0;                      /* '::' must cover >= 1 group */
    memset(out, 0, 16);
    memcpy(out, b, (size_t)dc * 2);
    memcpy(out + 16 - (size_t)(gi - dc) * 2, b + dc * 2,
           (size_t)(gi - dc) * 2);
    return 1;
}

/* One address in either family into 16 bytes. Surrounding whitespace is
 * trimmed; a bracketed `[::1]:443` and a `1.2.3.4:5678` port suffix are
 * accepted and dropped, because real proxies emit both and rejecting them
 * would silently fall back to the peer. *is_v4 reports which family was
 * written, which is what a CIDR's prefix length is relative to.
 *
 * `sp`/`sl` report the span actually parsed - the address WITHOUT the
 * brackets, port or padding. Callers that go on to store the value must use
 * that span and not the raw token, or REMOTE_ADDR ends up as
 * "1.2.3.4:5678" and the same client hashes to two rate-limit keys. */
static int pp_parse_addr(const char *s, STRLEN len, unsigned char out[16],
                         int *is_v4, const char **sp, STRLEN *sl) {
    unsigned char v4[4];
    int dots = 0, colons = 0;
    STRLEN i;

    while (len && (*s == ' ' || *s == '\t')) { s++; len--; }
    while (len && (s[len - 1] == ' ' || s[len - 1] == '\t')) len--;

    if (len > 1 && *s == '[') {                 /* [addr] or [addr]:port */
        const char *close = (const char *)memchr(s, ']', len);
        if (!close) return 0;
        s++;
        len = (STRLEN)(close - s);
    }
    if (!len || len > 45) return 0;

    for (i = 0; i < len; i++) {
        if (s[i] == '.') dots++;
        else if (s[i] == ':') colons++;
    }
    if (dots == 3 && colons == 1) {             /* v4:port */
        while (len && s[len - 1] != ':') len--;
        if (len) len--;
    }
    if (!len) return 0;

    if (sp) *sp = s;
    if (sl) *sl = len;

    if (pp_parse_v4(s, len, v4)) {
        memset(out, 0, 10);
        out[10] = 0xff; out[11] = 0xff;
        memcpy(out + 12, v4, 4);
        if (is_v4) *is_v4 = 1;
        return 1;
    }
    if (is_v4) *is_v4 = 0;
    return pp_parse_v6(s, len, out);
}

/* `addr` or `addr/prefixlen`. A v4 prefix is taken in the v4 space and
 * lifted into the mapped range, so 10.0.0.0/8 is stored as /104 and an
 * operator never has to know that. Returns 0 on anything malformed, which
 * the keyword turns into a boot croak - a mistyped CIDR must not become a
 * policy that quietly trusts nothing. */
static int pp_parse_cidr(const char *s, STRLEN len, pp_cidr *out) {
    const char *slash = (const char *)memchr(s, '/', len);
    STRLEN alen = slash ? (STRLEN)(slash - s) : len;
    int is_v4 = 0, bits;

    if (!pp_parse_addr(s, alen, out->addr, &is_v4, NULL, NULL)) return 0;

    if (!slash) {
        out->bits = 128;                        /* a bare address is a host */
        return 1;
    }
    {
        STRLEN i = alen + 1;
        int v = 0, nd = 0;
        while (i < len && s[i] >= '0' && s[i] <= '9') {
            v = v * 10 + (s[i] - '0');
            if (v > 128) return 0;
            nd++; i++;
            if (nd > 3) return 0;
        }
        if (!nd || i != len) return 0;
        bits = v;
    }
    if (is_v4) {
        if (bits > 32) return 0;
        bits += 96;                             /* into the mapped range */
    }
    out->bits = bits;
    return 1;
}

static int pp_cidr_match(const pp_cidr *c, const unsigned char a[16]) {
    int full = c->bits >> 3, rem = c->bits & 7;
    if (full && memcmp(c->addr, a, (size_t)full) != 0) return 0;
    if (rem) {
        unsigned char m = (unsigned char)(0xff << (8 - rem));
        if ((c->addr[full] & m) != (a[full] & m)) return 0;
    }
    return 1;
}

static int pp_trusted(const pp_policy *p, const unsigned char a[16]) {
    int i;
    for (i = 0; i < p->ncidrs; i++)
        if (pp_cidr_match(&p->cidrs[i], a)) return 1;
    return 0;
}

/* ---- the header walk ---------------------------------------------------- */

/* The leftmost comma-separated entry, trimmed. */
static const char *pp_first_token(const char *s, STRLEN len, STRLEN *outlen) {
    const char *comma = (const char *)memchr(s, ',', len);
    STRLEN l = comma ? (STRLEN)(comma - s) : len;
    while (l && (*s == ' ' || *s == '\t')) { s++; l--; }
    while (l && (s[l - 1] == ' ' || s[l - 1] == '\t')) l--;
    *outlen = l;
    return s;
}

/* The rightmost entries, trimmed, tok[0] being the last one on the line.
 * Empty entries are KEPT rather than skipped: dropping them would shift the
 * hop count, and a malformed entry must end the walk, not shorten it. */
static int pp_collect_right(const char *s, STRLEN len,
                            const char **tok, STRLEN *tlen, int max) {
    int n = 0;
    STRLEN end = len;
    for (;;) {
        STRLEN start = end;
        const char *p;
        STRLEN l;
        if (n >= max) break;
        while (start > 0 && s[start - 1] != ',') start--;
        p = s + start;
        l = end - start;
        while (l && (*p == ' ' || *p == '\t')) { p++; l--; }
        while (l && (p[l - 1] == ' ' || p[l - 1] == '\t')) l--;
        tok[n] = p;
        tlen[n] = l;
        n++;
        if (start == 0) break;
        end = start - 1;
    }
    return n;
}

/* The real client, as a pointer into `xff` or into `peer`. Never returns
 * NULL: with nothing trustworthy to say, the answer is the socket peer,
 * which is the address that is true by construction. */
static const char *pp_xff_client(const char *xff, STRLEN len,
                                 const pp_policy *p,
                                 const char *peer, STRLEN plen,
                                 STRLEN *outlen) {
    const char *tok[PP_MAX_HOPS];
    STRLEN tlen[PP_MAX_HOPS];
    unsigned char a[16];
    const char *sp;
    STRLEN sl;
    int n, i, isv4;

    *outlen = plen;
    if (!xff || !len) return peer;

    if (p->hops < 0) {                          /* trust => 'all' */
        STRLEN l;
        const char *t = pp_first_token(xff, len, &l);
        if (l && pp_parse_addr(t, l, a, &isv4, &sp, &sl)) {
            *outlen = sl;
            return sp;
        }
        return peer;
    }

    n = pp_collect_right(xff, len, tok, tlen, PP_MAX_HOPS);
    if (n <= 0) return peer;

    if (p->hops > 0) {
        /* N trusted proxies: the client is at index N-1 from the right. A
         * chain shorter than declared is a misconfiguration or a client
         * that sent nothing - either way the peer is the honest answer, and
         * reaching for the leftmost entry here is precisely the bug. */
        i = p->hops - 1;
        if (i >= n) return peer;
        if (!pp_parse_addr(tok[i], tlen[i], a, &isv4, &sp, &sl)) return peer;
        *outlen = sl;
        return sp;
    }

    /* CIDR mode. The peer must itself be a trusted proxy, or the header is
     * not ours to believe at all. */
    if (!(pp_parse_addr(peer, plen, a, &isv4, NULL, NULL) && pp_trusted(p, a)))
        return peer;
    for (i = 0; i < n; i++) {
        if (!pp_parse_addr(tok[i], tlen[i], a, &isv4, &sp, &sl)) return peer;
        if (!pp_trusted(p, a)) { *outlen = sl; return sp; }
    }
    /* every entry was a trusted proxy: the leftmost is the client */
    if (!pp_parse_addr(tok[n - 1], tlen[n - 1], a, &isv4, &sp, &sl))
        return peer;
    *outlen = sl;
    return sp;
}

/* ---- the boot-time build ------------------------------------------------- */

/* A header name into the PSGI env key it arrives as: uppercased, '-' to '_',
 * HTTP_ prefixed. Done once at to_app so a request is a hash lookup on a
 * string we already own. */
static char *pp_env_key(pTHX_ const char *name, STRLEN nlen, STRLEN *outlen) {
    char *k;
    STRLEN i;
    Newx(k, nlen + 6, char);
    memcpy(k, "HTTP_", 5);
    for (i = 0; i < nlen; i++) {
        char c = name[i];
        k[5 + i] = (c == '-') ? '_' : (char)toUPPER((unsigned char)c);
    }
    k[5 + nlen] = '\0';
    *outlen = nlen + 5;
    return k;
}

static char *pp_key_opt(pTHX_ HV *cfg, const char *opt, const char *dflt,
                        STRLEN *outlen) {
    SV **v = hv_fetch(cfg, opt, (I32)strlen(opt), 0);
    STRLEN nl;
    const char *n;
    if (v && *v && !SvOK(*v)) return NULL;      /* undef switches it off */
    n = (v && *v) ? SvPV_const(*v, nl) : (nl = strlen(dflt), dflt);
    if (!nl) return NULL;
    return pp_env_key(aTHX_ n, nl, outlen);
}

/* Freeze the keyword's config into the policy a request reads. Croaks on
 * anything malformed - a mistyped CIDR or a nonsense hop count must fail at
 * boot, where it is one line of output, not per request where it is a
 * silently wrong address in a rate-limit key. `appenv` is $app->env. */
static pp_policy *pp_compile(pTHX_ HV *cfg, const char *appenv) {
    pp_policy *p;
    SV **t = hv_fetchs(cfg, "trust", 0);

    Newxz(p, 1, pp_policy);
    p->hops = 1;                                /* bare `proxy` = one hop */

    if (t && *t && SvOK(*t)) {
        if (SvROK(*t) && SvTYPE(SvRV(*t)) == SVt_PVAV) {
            AV *av = (AV *)SvRV(*t);
            SSize_t i, n = av_len(av) + 1;
            if (n <= 0) {
                pp_free(aTHX_ p);
                croak("Punk: proxy: trust => [] trusts nothing - drop the "
                      "keyword instead, or name the proxy networks");
            }
            Newxz(p->cidrs, (int)n, pp_cidr);
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(av, i, 0);
                STRLEN sl;
                const char *s;
                if (!(e && *e && SvOK(*e))) {
                    pp_free(aTHX_ p);
                    croak("Punk: proxy: trust list entry %d is undef",
                          (int)i);
                }
                s = SvPV_const(*e, sl);
                if (!pp_parse_cidr(s, sl, &p->cidrs[i])) {
                    SV *msg = sv_2mortal(newSVpvf(
                        "Punk: proxy: '%.*s' is not an address or CIDR",
                        (int)sl, s));
                    pp_free(aTHX_ p);
                    croak("%s", SvPV_nolen(msg));
                }
            }
            p->ncidrs = (int)n;
            p->hops = 0;
        }
        else if (!SvROK(*t) && !looks_like_number(*t)) {
            STRLEN sl;
            const char *s = SvPV_const(*t, sl);
            if (sl == 3 && memEQ(s, "all", 3)) {
                if (!(appenv && strEQ(appenv, "development"))) {
                    pp_free(aTHX_ p);
                    croak("Punk: proxy: trust => 'all' believes any "
                          "X-Forwarded-For from anyone, so with no proxy in "
                          "front it is a total bypass - it is allowed only "
                          "under PUNK_ENV=development. Name a hop count or "
                          "the proxy networks instead");
                }
                p->hops = -1;
            } else {
                SV *msg = sv_2mortal(newSVpvf(
                    "Punk: proxy: trust must be a hop count, an arrayref of "
                    "CIDRs, or 'all' - not '%.*s'", (int)sl, s));
                pp_free(aTHX_ p);
                croak("%s", SvPV_nolen(msg));
            }
        }
        else if (SvROK(*t)) {
            pp_free(aTHX_ p);
            croak("Punk: proxy: trust must be a hop count, an arrayref of "
                  "CIDRs, or 'all'");
        }
        else {
            IV n = SvIV(*t);
            if (n < 1 || n > PP_MAX_HOPS) {
                pp_free(aTHX_ p);
                croak("Punk: proxy: trust => %" IVdf " is not a usable hop "
                      "count (1..%d)", n, PP_MAX_HOPS);
            }
            p->hops = (int)n;
        }
    }

    p->for_key   = pp_key_opt(aTHX_ cfg, "for_header",
                              "X-Forwarded-For",   &p->for_len);
    p->proto_key = pp_key_opt(aTHX_ cfg, "proto_header",
                              "X-Forwarded-Proto", &p->proto_len);
    p->host_key  = pp_key_opt(aTHX_ cfg, "host_header",
                              "X-Forwarded-Host",  &p->host_len);
    p->port_key  = pp_key_opt(aTHX_ cfg, "port_header",
                              "X-Forwarded-Port",  &p->port_len);
    return p;
}

/* ---- the per-request resolution ----------------------------------------- */

static void pp_free(pTHX_ pp_policy *p) {
    if (!p) return;
    Safefree(p->cidrs);
    Safefree(p->for_key);
    Safefree(p->proto_key);
    Safefree(p->host_key);
    Safefree(p->port_key);
    Safefree(p);
}

/* Called once per request from the top of punk_serve, and only when a
 * policy was declared - an app without `proxy` pays one predictable
 * branch and nothing else. */
static void pp_resolve(pTHX_ const pp_policy *p, HV *env) {
    SV **e;
    SV *peersv;
    const char *peer;
    STRLEN plen = 0;

    e = hv_fetchs(env, "REMOTE_ADDR", 0);
    peersv = (e && *e && SvOK(*e)) ? *e : NULL;
    peer = peersv ? SvPV_const(peersv, plen) : "";

    /* the socket peer, kept before anything is rewritten, so an edge ban
     * still has the address the connection actually came from */
    (void)hv_stores(env, "punk.peer_addr",
                    peersv ? newSVsv(peersv) : newSVpvs(""));

    e = p->for_key ? hv_fetch(env, p->for_key, (I32)p->for_len, 0) : NULL;
    if (e && *e && SvOK(*e)) {
        STRLEN xl, clen;
        const char *x = SvPV_const(*e, xl);
        const char *client = pp_xff_client(x, xl, p, peer, plen, &clen);
        if (clen != plen || (clen && memNE(client, peer, clen))) {
            /* copy before the store: `peer` points into the SV it frees */
            SV *newsv = newSVpvn(client, clen);
            (void)hv_stores(env, "REMOTE_ADDR", newsv);
            /* the port described the proxy's socket and is now a lie */
            (void)hv_delete(env, "REMOTE_PORT", 11, G_DISCARD);
        }
    }

    if (p->proto_key) {
        e = hv_fetch(env, p->proto_key, (I32)p->proto_len, 0);
        if (e && *e && SvOK(*e)) {
            STRLEN vl, l;
            const char *v = SvPV_const(*e, vl);
            const char *t = pp_first_token(v, vl, &l);
            if (l == 5 && foldEQ(t, "https", 5)) {
                (void)hv_stores(env, "psgi.url_scheme", newSVpvs("https"));
                (void)hv_stores(env, "HTTPS", newSVpvs("on"));
            } else if (l == 4 && foldEQ(t, "http", 4)) {
                (void)hv_stores(env, "psgi.url_scheme", newSVpvs("http"));
                (void)hv_delete(env, "HTTPS", 5, G_DISCARD);
            }
        }
    }

    if (p->host_key) {
        e = hv_fetch(env, p->host_key, (I32)p->host_len, 0);
        if (e && *e && SvOK(*e)) {
            STRLEN vl, l;
            const char *v = SvPV_const(*e, vl);
            const char *t = pp_first_token(v, vl, &l);
            if (l) (void)hv_stores(env, "HTTP_HOST", newSVpvn(t, l));
        }
    }

    if (p->port_key) {
        e = hv_fetch(env, p->port_key, (I32)p->port_len, 0);
        if (e && *e && SvOK(*e)) {
            STRLEN vl, l;
            const char *v = SvPV_const(*e, vl);
            const char *t = pp_first_token(v, vl, &l);
            STRLEN i;
            int ok = l > 0 && l <= 5;
            for (i = 0; ok && i < l; i++)
                if (t[i] < '0' || t[i] > '9') ok = 0;
            if (ok) (void)hv_stores(env, "SERVER_PORT", newSVpvn(t, l));
        }
    }
}

#endif /* PUNK_PROXY_H */
