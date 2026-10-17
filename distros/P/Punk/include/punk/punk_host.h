/* punk_host.h - the application's origin, and which request hosts may stand
 * in for it.
 *
 *     host 'https://example.com';
 *     host 'https://example.com', allow => [ '*.example.com', 'shop.tld' ];
 *
 * `host` is one canonical origin, which is the whole story for most
 * applications. One serving several tenants by Host header has an origin
 * per request, and the request's Host is attacker-supplied bytes: anything
 * that reflects it - a sitemap handed to search engines, a redirect, an
 * absolute link in a mail - is a host-header injection waiting for a
 * request that sets it.
 *
 * The allowlist is what turns that header into configuration. $c->origin is
 * the request's scheme and host ONLY when the host is the canonical one or
 * matches an allow entry, and the canonical origin otherwise. The raw header
 * never comes back, so a consumer cannot be handed a hostname nobody
 * configured.
 */

#ifndef PUNK_HOST_H
#define PUNK_HOST_H

/* name[:port] -> name length, and the port if there is one */
static void pk_host_split(const char *p, STRLEN l, STRLEN *nl,
                          const char **port, STRLEN *portl) {
    STRLEN i;
    for (i = 0; i < l; i++) if (p[i] == ':') break;
    *nl = i;
    if (i < l) { *port = p + i + 1; *portl = l - i - 1; }
    else       { *port = NULL;      *portl = 0; }
}

/* An allow entry, already lowercased: labels of [a-z0-9-] joined by '.', an
 * optional leading "*." and no other '*', an optional ":port". Nothing else -
 * an entry is matched with memEQ, not a pattern language, so a typo fails at
 * the keyword rather than never matching. */
static int pk_host_entry_ok(const char *p, STRLEN l) {
    STRLEN i = 0, nl;
    const char *port;
    STRLEN portl;
    if (l >= 2 && p[0] == '*' && p[1] == '.') i = 2;
    pk_host_split(p, l, &nl, &port, &portl);
    if (nl <= i) return 0;
    for (; i < nl; i++) {
        const unsigned char c = (unsigned char)p[i];
        if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')
            || c == '-' || c == '.') continue;
        return 0;
    }
    if (port) {
        if (portl == 0 || portl > 5) return 0;
        for (i = 0; i < portl; i++) if (!isDIGIT(port[i])) return 0;
    }
    return 1;
}

/* Does a request host (lowercased, split) satisfy an entry? An entry naming
 * a port means that port; one without accepts any. A leading "*." matches
 * any host with at least one label in front of the suffix. */
static int pk_host_matches(const char *ent, STRLEN el,
                           const char *host, STRLEN hl,
                           const char *port, STRLEN portl) {
    STRLEN enl;
    const char *eport;
    STRLEN eportl;
    pk_host_split(ent, el, &enl, &eport, &eportl);
    if (eport && !(port && portl == eportl && memEQ(port, eport, portl)))
        return 0;
    if (enl >= 2 && ent[0] == '*' && ent[1] == '.') {
        STRLEN sl = enl - 1;                       /* ".example.com" */
        return hl > sl && memEQ(host + hl - sl, ent + 1, sl);
    }
    return hl == enl && memEQ(host, ent, hl);
}

/* An arrayref of allow entries, validated and lowercased into a new AV (+1).
 * `what` names the caller in the croak ("host allow", "websocket origin"), so
 * one rule about what a hostname is has one implementation and every keyword
 * that takes a list of them refuses the same typos. */
static AV *pk_host_allow_av(pTHX_ SV *v, const char *what) {
    AV *in, *out;
    SSize_t ai, an;
    if (!(v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV))
        croak("Punk: %s needs an arrayref of hostnames", what);
    in  = (AV *)SvRV(v);
    out = newAV();
    an  = av_len(in) + 1;
    for (ai = 0; ai < an; ai++) {
        SV **e = av_fetch(in, ai, 0);
        STRLEN el, j;
        const char *ep;
        SV *low;
        char *lp;
        if (!(e && *e && SvOK(*e) && SvCUR(*e))) {
            SvREFCNT_dec((SV *)out);
            croak("Punk: %s entries are hostnames", what);
        }
        ep  = SvPV_const(*e, el);
        low = newSVpvn(ep, el);
        lp  = SvPVX(low);
        for (j = 0; j < el; j++)
            if (lp[j] >= 'A' && lp[j] <= 'Z') lp[j] += 32;
        if (!pk_host_entry_ok(lp, el)) {
            sv_2mortal(low);                  /* freed with the caller's frame */
            SvREFCNT_dec((SV *)out);
            croak("Punk: %s entry '%.*s' is not a hostname - labels of "
                  "[a-z0-9-], an optional leading *. and an optional :port",
                  what, (int)el, ep);         /* the bytes as they were given */
        }
        av_push(out, low);
    }
    return out;
}

/* scheme://host[:port] of a stored origin, path dropped: the part that is
 * an origin in the browser's sense, which is what $c->origin promises. */
/* Where the host sits in a stored origin, and where the origin ends. No
 * allocation: this runs on every request that asks for its origin. */
static STRLEN pk_origin_span(const char *o, STRLEN ol, STRLEN *hostoff,
                             STRLEN *hostlen) {
    STRLEN i = 0, start, end;
    while (i + 2 < ol && !(o[i] == ':' && o[i+1] == '/' && o[i+2] == '/')) i++;
    start = (i + 2 < ol) ? i + 3 : 0;
    end = start;
    while (end < ol && o[end] != '/') end++;
    if (hostoff) *hostoff = start;
    if (hostlen) *hostlen = end - start;
    return end;
}

static SV *pk_origin_bare(pTHX_ const char *o, STRLEN ol, STRLEN *hostoff,
                          STRLEN *hostlen) {
    return newSVpvn(o, pk_origin_span(o, ol, hostoff, hostlen));
}

/* The origin a request may be told it has.
 *
 * Returns a new SV (+1), or NULL when the application declared no `host` -
 * in which case there is nothing safe to say, and the caller says undef.
 * *state is 0 when the request's Host was unknown or malformed and the
 * canonical origin is being returned instead; 1 when it is the canonical
 * host itself; 2 when it matched an allow entry. A consumer that renders
 * per tenant wants 2; one that only needs a trustworthy absolute URL wants
 * the string. */
static SV *pk_origin_of(pTHX_ SV *c, int *state) {
    AV *av = pcx_av(aTHX_ c);
    SV *appsv = pcx_get(aTHX_ av, PCX_APP);
    SV *envsv = pcx_get(aTHX_ av, PCX_ENV);
    HV *h, *env = NULL;
    SV *canon, *allow;
    const char *cp;
    STRLEN cl, choff, chlen;
    SV *hostsv = NULL, *schemesv = NULL;

    *state = 0;
    if (!(appsv && SvROK(appsv) && SvTYPE(SvRV(appsv)) == SVt_PVHV))
        return NULL;
    h = (HV *)SvRV(appsv);
    canon = app_get(aTHX_ h, "host");
    if (!(canon && SvOK(canon) && SvCUR(canon))) return NULL;
    cp = SvPV_const(canon, cl);

    if (envsv && SvROK(envsv) && SvTYPE(SvRV(envsv)) == SVt_PVHV) {
        SV **e;
        env = (HV *)SvRV(envsv);
        e = hv_fetchs(env, "HTTP_HOST", 0);
        if (e && *e && SvOK(*e) && SvCUR(*e)) hostsv = *e;
        e = hv_fetchs(env, "psgi.url_scheme", 0);
        if (e && *e && SvOK(*e)) schemesv = *e;
    }

    if (hostsv) {
        STRLEN rl, i, nl;
        const char *rp = SvPV_const(hostsv, rl);
        SV *norm = sv_2mortal(newSVpvn(rp, rl));
        char *np = SvPVX(norm);
        const char *port;
        STRLEN portl;
        int valid = 1, ok = 0;

        /* lowercase, and refuse anything that is not a hostname: the
         * header is attacker-supplied, and a byte that is not [a-z0-9.-]
         * or a :port has no business in an origin */
        for (i = 0; i < rl; i++) {
            unsigned char ch = (unsigned char)np[i];
            if (ch >= 'A' && ch <= 'Z') { np[i] = (char)(ch + 32); continue; }
            if ((ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9')
                || ch == '-' || ch == '.' || ch == ':') continue;
            valid = 0; break;
        }
        pk_host_split(np, rl, &nl, &port, &portl);
        if (valid && nl == 0) valid = 0;
        if (valid && port) {
            if (portl == 0 || portl > 5) valid = 0;
            for (i = 0; valid && i < portl; i++)
                if (!isDIGIT(port[i])) valid = 0;
            /* five digits still has to be a port */
            if (valid && portl == 5 && memcmp(port, "65535", 5) > 0) valid = 0;
        }
        /* a second ':' would have ended up inside the port and failed */

        if (valid) {
            /* the canonical host is always its own origin */
            (void)pk_origin_span(cp, cl, &choff, &chlen);
            {
                STRLEN cnl; const char *cport; STRLEN cportl;
                pk_host_split(cp + choff, chlen, &cnl, &cport, &cportl);
                if (cnl == nl && memEQ(cp + choff, np, nl)) ok = 1;
            }
            allow = ok ? NULL : app_get(aTHX_ h, "host_allow");
            if (!ok && allow && SvROK(allow)
                && SvTYPE(SvRV(allow)) == SVt_PVAV) {
                AV *list = (AV *)SvRV(allow);
                SSize_t ai, an = av_len(list) + 1;
                for (ai = 0; ai < an && !ok; ai++) {
                    SV **e = av_fetch(list, ai, 0);
                    STRLEN el;
                    const char *ep;
                    if (!(e && *e && SvOK(*e))) continue;
                    ep = SvPV_const(*e, el);
                    if (pk_host_matches(ep, el, np, nl, port, portl)) ok = 2;
                }
            }
        }

        if (ok) {
            SV *out;
            STRLEN sl = 0;
            const char *sp = schemesv ? SvPV_const(schemesv, sl) : NULL;
            if (sp && sl == 5 && memEQ(sp, "https", 5))     out = newSVpvs("https://");
            else if (sp && sl == 4 && memEQ(sp, "http", 4)) out = newSVpvs("http://");
            else {
                /* no usable scheme on the request: the canonical's */
                STRLEN k = 0;
                while (k + 2 < cl && !(cp[k] == ':' && cp[k+1] == '/'
                                       && cp[k+2] == '/')) k++;
                out = newSVpvn(cp, k + 3);
            }
            sv_catpvn(out, np, rl);
            *state = ok;
            return out;
        }
    }

    /* unknown, malformed or absent: the canonical origin, never the header */
    return pk_origin_bare(aTHX_ cp, cl, NULL, NULL);
}

/* May a page at this Origin talk to this application?
 *
 * A WebSocket upgrade is a GET that carries the user's cookies, gets no
 * preflight, and is not covered by the same-origin policy: the browser sends
 * it and delivers the answer whatever the page's origin. CORS cannot stand in
 * for this - CORS refuses nothing, it omits headers and leaves the decision
 * to the browser, which the browser does not make for ws://. So the check
 * belongs here, and the default has to be safe without configuration.
 *
 * What counts as this application's own origin, in order:
 *
 *   - the request's own Host. That is what "same origin" means, it needs no
 *     configuration, and it is sound against the attack: a page cannot set
 *     Host, the browser sends the target's. Compared on host and port and NOT
 *     on scheme, because an application behind a TLS terminator that was
 *     never declared to `proxy` sees psgi.url_scheme 'http' under an https
 *     Origin, and refusing every socket there is a worse failure than
 *     accepting a plaintext page on a host an attacker would already have to
 *     own to serve.
 *   - the canonical `host`, scheme included: that one was declared.
 *   - its `allow` entries, the other hosts this application answers as. The
 *     pages it serves are the pages that may talk back to it.
 *   - `extra`, the route's own `origin` list.
 *
 * Returns 1 for allowed, 0 for refused. "null" - a sandboxed frame, a data:
 * URL, a page reached through a redirect - has no "://" and is refused with
 * everything else that is not an origin.
 */
static int pk_origin_ok(pTHX_ SV *c, const char *o, STRLEN ol, AV *extra) {
    AV *av = pcx_av(aTHX_ c);
    SV *appsv = pcx_get(aTHX_ av, PCX_APP);
    SV *envsv = pcx_get(aTHX_ av, PCX_ENV);
    STRLEN i, j, hoff, hl, nl, portl;
    const char *port;
    SV *low;
    char *lp;

    for (i = 0; i + 2 < ol; i++)
        if (o[i] == ':' && o[i+1] == '/' && o[i+2] == '/') break;
    if (i + 2 >= ol) return 0;
    hoff = i + 3;
    if (hoff >= ol) return 0;
    hl = ol - hoff;

    /* the same rule pk_origin_of applies to a Host header: a byte that is not
     * [a-z0-9.-] or a :port has no business in an origin, and a '/' here
     * means a URL was sent where an origin was asked for */
    low = sv_2mortal(newSVpvn(o + hoff, hl));
    lp  = SvPVX(low);
    for (j = 0; j < hl; j++) {
        unsigned char ch = (unsigned char)lp[j];
        if (ch >= 'A' && ch <= 'Z') { lp[j] = (char)(ch + 32); continue; }
        if ((ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9')
            || ch == '-' || ch == '.' || ch == ':') continue;
        return 0;
    }
    pk_host_split(lp, hl, &nl, &port, &portl);
    if (nl == 0) return 0;
    if (port) {
        if (portl == 0 || portl > 5) return 0;
        for (j = 0; j < portl; j++) if (!isDIGIT(port[j])) return 0;
    }

    if (envsv && SvROK(envsv) && SvTYPE(SvRV(envsv)) == SVt_PVHV) {
        SV **e = hv_fetchs((HV *)SvRV(envsv), "HTTP_HOST", 0);
        if (e && *e && SvOK(*e) && SvCUR(*e)) {
            STRLEN rl;
            const char *rp = SvPV_const(*e, rl);
            if (rl == hl) {
                for (j = 0; j < rl; j++) {
                    unsigned char a = (unsigned char)rp[j];
                    if (a >= 'A' && a <= 'Z') a = (unsigned char)(a + 32);
                    if (a != (unsigned char)lp[j]) break;
                }
                if (j == rl) return 1;
            }
        }
    }

    if (appsv && SvROK(appsv) && SvTYPE(SvRV(appsv)) == SVt_PVHV) {
        HV *h = (HV *)SvRV(appsv);
        SV *canon = app_get(aTHX_ h, "host");
        SV *allow;
        if (canon && SvOK(canon) && SvCUR(canon)) {
            STRLEN cl;
            const char *cp = SvPV_const(canon, cl);
            SV *bare = sv_2mortal(pk_origin_bare(aTHX_ cp, cl, NULL, NULL));
            STRLEN bl;
            const char *bp = SvPV_const(bare, bl);
            if (bl == ol) {
                for (j = 0; j < bl; j++) {
                    unsigned char a = (unsigned char)bp[j];
                    unsigned char b = (unsigned char)o[j];
                    if (a >= 'A' && a <= 'Z') a = (unsigned char)(a + 32);
                    if (b >= 'A' && b <= 'Z') b = (unsigned char)(b + 32);
                    if (a != b) break;
                }
                if (j == bl) return 1;
            }
        }
        allow = app_get(aTHX_ h, "host_allow");
        if (allow && SvROK(allow) && SvTYPE(SvRV(allow)) == SVt_PVAV) {
            AV *list = (AV *)SvRV(allow);
            SSize_t ai, an = av_len(list) + 1;
            for (ai = 0; ai < an; ai++) {
                SV **e = av_fetch(list, ai, 0);
                STRLEN el;
                const char *ep;
                if (!(e && *e && SvOK(*e))) continue;
                ep = SvPV_const(*e, el);
                if (pk_host_matches(ep, el, lp, nl, port, portl)) return 1;
            }
        }
    }

    if (extra) {
        SSize_t ai, an = av_len(extra) + 1;
        for (ai = 0; ai < an; ai++) {
            SV **e = av_fetch(extra, ai, 0);
            STRLEN el;
            const char *ep;
            if (!(e && *e && SvOK(*e))) continue;
            ep = SvPV_const(*e, el);
            if (pk_host_matches(ep, el, lp, nl, port, portl)) return 1;
        }
    }
    return 0;
}

#endif /* PUNK_HOST_H */
