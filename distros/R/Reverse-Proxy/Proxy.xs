#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "rp_compat.h"   /* pre-5.16 perl shims (XS_INTERNAL, mg_findext) */
#include "fetch_abi.h"   /* vendored copy; runtime version-checked in BOOT */

/* Raw sockets for the WebSocket/Upgrade tunnel (Unix). On Windows the tunnel
 * is unsupported and returns 501 (Hyperman, which provides psgix.io, is
 * Unix-first anyway). */
#ifndef WIN32
#  include <sys/types.h>
#  include <sys/socket.h>
#  include <netdb.h>
#  include <unistd.h>
#  include <errno.h>
#  include <fcntl.h>
#endif

/* Resolved once at boot from Fetch::_abi_ptr and version-checked. NULL means
 * the running Fetch is too old to provide the ABI; Reverse::Proxy.pm treats
 * that as a hard load-time error (there is no pure-Perl fallback). */
static const fetch_abi *FETCH = NULL;

/* ---- a tiny closure: a coderef carrying captured SVs -------------------- *
 * Lets to_app and the psgi.streaming app be built in C rather than Perl. The
 * captured args live in an AV attached to an anonymous CV by magic. */
typedef struct rp_clos { AV *cap; } rp_clos;

static int rp_clos_free(pTHX_ SV *sv, MAGIC *mg) {
    rp_clos *c = (rp_clos *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (c) { if (c->cap) SvREFCNT_dec((SV *)c->cap); Safefree(c); }
    return 0;
}
static MGVTBL rp_clos_vtbl = { NULL, NULL, NULL, NULL, rp_clos_free,
                               NULL, NULL, NULL };

static SV *rp_closure(pTHX_ XSUBADDR_t body, AV *cap) {
    CV *cv = (CV *)newXS(NULL, body, __FILE__);
    rp_clos *c;
    Newxz(c, 1, rp_clos);
    c->cap = cap;                                   /* takes ownership */
    sv_magicext((SV *)cv, NULL, PERL_MAGIC_ext, &rp_clos_vtbl, (char *)c, 0);
    return newRV_noinc((SV *)cv);
}
static AV *rp_clos_cap(pTHX_ CV *cv) {
    MAGIC *mg = mg_findext((SV *)cv, PERL_MAGIC_ext, &rp_clos_vtbl);
    return mg ? ((rp_clos *)mg->mg_ptr)->cap : NULL;
}

/* ---- hop-by-hop and X-Forwarded-* name sets (lowercased) ---------------- */

static int rp_is_hop(const char *s, STRLEN n) {
    switch (n) {
        case 2:  return memEQ(s, "te", 2);
        case 7:  return memEQ(s, "upgrade", 7) || memEQ(s, "trailer", 7);
        case 10: return memEQ(s, "connection", 10) || memEQ(s, "keep-alive", 10);
        case 17: return memEQ(s, "transfer-encoding", 17);
        case 18: return memEQ(s, "proxy-authenticate", 18);
        case 19: return memEQ(s, "proxy-authorization", 19);
        default: return 0;
    }
}

static int rp_is_xfwd(const char *s, STRLEN n) {
    switch (n) {
        case 15: return memEQ(s, "x-forwarded-for", 15);
        case 16: return memEQ(s, "x-forwarded-host", 16);
        case 17: return memEQ(s, "x-forwarded-proto", 17);
        default: return 0;
    }
}

/* Lowercase into caller buffer (len n, no NUL needed by callers here). */
static void rp_lc(const char *src, STRLEN n, char *dst) {
    STRLEN i;
    for (i = 0; i < n; i++) dst[i] = (char)toLOWER((U8)src[i]);
}

/* Push a header name+value pair (as mortal SVs) onto the flat AV. name/val are
 * copied. */
static void rp_push(pTHX_ AV *av, const char *name, STRLEN nl,
                    const char *val, STRLEN vl) {
    av_push(av, newSVpvn(name, nl));
    av_push(av, newSVpvn(val, vl));
}

/* Env string field, or NULL if missing/empty; sets *len. */
static const char *rp_env(pTHX_ HV *env, const char *key, STRLEN klen, STRLEN *len) {
    SV **e = hv_fetch(env, key, (I32)klen, 0);
    if (e && *e && SvOK(*e)) {
        STRLEN l;
        const char *p = SvPV_const(*e, l);
        if (l) { *len = l; return p; }
    }
    *len = 0;
    return NULL;
}

/* ---- response shaper: Fetch response -> PSGI [status,\@hdrs,\@body] ------ */

static SV *rp_map(pTHX_ int ok, int status, AV *headers, SV *body, SV *err,
                  void *ud) {
    AV *resp = newAV();
    PERL_UNUSED_ARG(ud);

    if (!ok) {                          /* 502, mirroring PP _bad_gateway */
        AV *h = newAV();
        AV *b = newAV();
        SV *msg;
        av_push(h, newSVpvs("Content-Type"));
        av_push(h, newSVpvs("text/plain"));
        if (err && SvOK(err)) {
            STRLEN el; const char *ep = SvPV_const(err, el);
            while (el && isSPACE((U8)ep[el - 1])) el--;   /* rstrip */
            msg = newSVpvs("502 Bad Gateway: ");
            sv_catpvn(msg, ep, el);
        } else {
            msg = newSVpvs("502 Bad Gateway: upstream request failed");
        }
        av_push(b, msg);
        av_push(resp, newSViv(502));
        av_push(resp, newRV_noinc((SV *)h));
        av_push(resp, newRV_noinc((SV *)b));
        return newRV_noinc((SV *)resp);
    }

    {
        AV *out = newAV();
        AV *b   = newAV();
        SSize_t n = headers ? av_len(headers) + 1 : 0, i;
        for (i = 0; i + 1 < n; i += 2) {
            SV **k = av_fetch(headers, i, 0);
            SV **v = av_fetch(headers, i + 1, 0);
            if (k && *k) {
                STRLEN kl; const char *ks = SvPV_const(*k, kl);
                char stackbuf[64], *lc = stackbuf;
                int drop;
                if (kl > sizeof(stackbuf)) Newx(lc, kl, char);
                rp_lc(ks, kl, lc);
                drop = rp_is_hop(lc, kl);
                if (lc != stackbuf) Safefree(lc);
                if (drop) continue;
                av_push(out, newSVsv(*k));
                av_push(out, (v && *v) ? newSVsv(*v) : newSVpvs(""));
            }
        }
        av_push(b, body ? newSVsv(body) : newSVpvs(""));
        av_push(resp, newSViv(status));
        av_push(resp, newRV_noinc((SV *)out));
        av_push(resp, newRV_noinc((SV *)b));
        return newRV_noinc((SV *)resp);
    }
}

/* ---- build the outbound header list from the PSGI env (== _req_headers) -- */

static AV *rp_req_headers(pTHX_ HV *env, int preserve_host, SV *via) {
    AV *hav = (AV *)sv_2mortal((SV *)newAV());
    HV *conn_hop = (HV *)sv_2mortal((SV *)newHV());
    HE *he;
    STRLEN l;
    const char *p;

    /* extra hop-by-hop names named in the client's own Connection header */
    p = rp_env(aTHX_ env, "HTTP_CONNECTION", 15, &l);
    if (p) {
        const char *s = p, *end = p + l;
        while (s < end) {
            const char *t = s;
            while (t < end && *t != ',') t++;
            {   /* trim token [s,t) */
                const char *a = s, *b = t;
                char buf[64], *lc = buf; STRLEN tn;
                while (a < b && isSPACE((U8)*a)) a++;
                while (b > a && isSPACE((U8)b[-1])) b--;
                tn = (STRLEN)(b - a);
                if (tn) {
                    if (tn > sizeof(buf)) Newx(lc, tn, char);
                    rp_lc(a, tn, lc);
                    (void)hv_store(conn_hop, lc, (I32)tn, &PL_sv_yes, 0);
                    if (lc != buf) Safefree(lc);
                }
            }
            s = t + 1;
        }
    }

    /* forward each HTTP_* header (skip Host, hop-by-hop, X-Forwarded-*) */
    hv_iterinit(env);
    while ((he = hv_iternext(env))) {
        I32 kl;
        const char *k = hv_iterkey(he, &kl);
        char namebuf[128], lcbuf[128];
        char *name = namebuf, *lc = lcbuf;
        STRLEN nl;
        SV *val;
        STRLEN i;
        if (kl < 6 || memNE(k, "HTTP_", 5)) continue;
        nl = (STRLEN)(kl - 5);
        if (nl > sizeof(namebuf)) { Newx(name, nl, char); Newx(lc, nl, char); }
        for (i = 0; i < nl; i++) {
            char c = k[5 + i];
            if (c == '_') c = '-';
            name[i] = c;
            lc[i]   = (char)toLOWER((U8)c);
        }
        do {
            if (nl == 4 && memEQ(lc, "host", 4)) break;         /* handled below */
            if (rp_is_hop(lc, nl) || rp_is_xfwd(lc, nl)) break;
            if (hv_exists(conn_hop, lc, (I32)nl)) break;
            /* titlecase name in place: Upper after start/'-', lower else */
            {
                int at_start = 1; STRLEN j;
                for (j = 0; j < nl; j++) {
                    if (name[j] == '-') { at_start = 1; }
                    else { name[j] = at_start ? (char)toUPPER((U8)name[j])
                                              : (char)toLOWER((U8)name[j]);
                           at_start = 0; }
                }
            }
            val = hv_iterval(env, he);
            {
                STRLEN vl; const char *vp = SvPV_const(val, vl);
                rp_push(aTHX_ hav, name, nl, vp, vl);
            }
        } while (0);
        if (name != namebuf) { Safefree(name); Safefree(lc); }
    }

    /* Content-Type (Content-Length is added by Fetch from the body) */
    p = rp_env(aTHX_ env, "CONTENT_TYPE", 12, &l);
    if (p) rp_push(aTHX_ hav, "Content-Type", 12, p, l);

    /* Host, only when preserving it */
    if (preserve_host) {
        p = rp_env(aTHX_ env, "HTTP_HOST", 9, &l);
        if (p) rp_push(aTHX_ hav, "Host", 4, p, l);
    }

    /* X-Forwarded-For: chain REMOTE_ADDR onto any existing value */
    {
        STRLEN cl; const char *client = rp_env(aTHX_ env, "REMOTE_ADDR", 11, &cl);
        if (client) {
            STRLEN xl; const char *xff = rp_env(aTHX_ env, "HTTP_X_FORWARDED_FOR", 20, &xl);
            SV *v = newSVpvs("");
            if (xff) { sv_catpvn(v, xff, xl); sv_catpvs(v, ", "); }
            sv_catpvn(v, client, cl);
            av_push(hav, newSVpvs("X-Forwarded-For"));
            av_push(hav, v);
        }
    }

    /* X-Forwarded-Proto: existing, else psgi.url_scheme, else http */
    {
        STRLEN pl; const char *proto = rp_env(aTHX_ env, "HTTP_X_FORWARDED_PROTO", 22, &pl);
        if (!proto) proto = rp_env(aTHX_ env, "psgi.url_scheme", 15, &pl);
        av_push(hav, newSVpvs("X-Forwarded-Proto"));
        av_push(hav, proto ? newSVpvn(proto, pl) : newSVpvs("http"));
    }

    /* X-Forwarded-Host: existing, else client Host */
    {
        STRLEN hl; const char *xfh = rp_env(aTHX_ env, "HTTP_X_FORWARDED_HOST", 21, &hl);
        if (!xfh) xfh = rp_env(aTHX_ env, "HTTP_HOST", 9, &hl);
        if (xfh) rp_push(aTHX_ hav, "X-Forwarded-Host", 16, xfh, hl);
    }

    /* Via */
    if (via && SvOK(via)) {
        STRLEN vl; const char *vp = SvPV_const(via, vl);
        if (vl) rp_push(aTHX_ hav, "Via", 3, vp, vl);
    }

    return hav;
}

/* ---- $self field helpers ------------------------------------------------ */

static SV *rp_self(pTHX_ HV *self, const char *k, STRLEN kl) {
    SV **e = hv_fetch(self, k, (I32)kl, 0);
    return (e && *e) ? *e : NULL;
}
static int rp_self_bool(pTHX_ HV *self, const char *k, STRLEN kl) {
    SV *v = rp_self(aTHX_ self, k, kl);
    return (v && SvTRUE(v)) ? 1 : 0;
}

/* case-insensitive: does the comma/space token list contain `tok`? */
static int rp_ci_token(const char *hay, STRLEN hl, const char *tok, STRLEN tl) {
    STRLEN i = 0;
    while (i < hl) {
        STRLEN s, e, j;
        while (i < hl && (hay[i] == ',' || isSPACE((U8)hay[i]))) i++;
        s = i;
        while (i < hl && hay[i] != ',') i++;
        e = i;
        while (e > s && isSPACE((U8)hay[e - 1])) e--;
        if (e - s == tl) {
            for (j = 0; j < tl; j++)
                if (toLOWER((U8)hay[s + j]) != (U8)tok[j]) break;
            if (j == tl) return 1;
        }
    }
    return 0;
}

/* this request asks for an HTTP Upgrade (WebSocket et al) */
static int rp_is_upgrade(pTHX_ HV *env) {
    STRLEN ul, cl;
    const char *u = rp_env(aTHX_ env, "HTTP_UPGRADE", 12, &ul);
    const char *c;
    if (!u) return 0;
    c = rp_env(aTHX_ env, "HTTP_CONNECTION", 15, &cl);
    return (c && rp_ci_token(c, cl, "upgrade", 7)) ? 1 : 0;
}

/* $path is under $prefix (equal, prefix is '/', or a '/' follows the prefix) */
static int rp_prefix_match(const char *path, STRLEN pl, const char *pre, STRLEN prl) {
    if (prl == 1 && pre[0] == '/') return 1;
    if (pl == prl && memEQ(path, pre, pl)) return 1;
    if (pl > prl && memEQ(path, pre, prl) && path[prl] == '/') return 1;
    return 0;
}

/* Resolve the upstream ($base) and forward path ($path) for this request.
 * Returns a mortal base SV (or NULL for "no target"); *path_out gets a mortal
 * forward-path SV. self_sv is the blessed proxy for the resolver callback. */
static SV *rp_resolve(pTHX_ SV *self_sv, HV *self, HV *env, SV **path_out) {
    STRLEN pil;
    const char *pi = rp_env(aTHX_ env, "PATH_INFO", 9, &pil);
    SV *path = pi ? newSVpvn(pi, pil) : newSVpvs("/");
    SV *up   = rp_self(aTHX_ self, "upstream", 8);
    sv_2mortal(path);
    *path_out = path;

    if (up && SvOK(up)) return sv_2mortal(newSVsv(up));

    {
        SV *routes = rp_self(aTHX_ self, "routes", 6);
        if (routes && SvROK(routes) && SvTYPE(SvRV(routes)) == SVt_PVAV) {
            AV *ra = (AV *)SvRV(routes);
            SSize_t n = av_len(ra) + 1, i;
            STRLEN pl2; const char *ps = SvPV_const(path, pl2);
            for (i = 0; i < n; i++) {
                SV **rp = av_fetch(ra, i, 0);
                AV *pair; SV **pre, **tgt;
                if (!rp || !*rp || !SvROK(*rp)) continue;
                pair = (AV *)SvRV(*rp);
                pre = av_fetch(pair, 0, 0);
                tgt = av_fetch(pair, 1, 0);
                if (pre && *pre && tgt && *tgt) {
                    STRLEN prl; const char *pres = SvPV_const(*pre, prl);
                    if (rp_prefix_match(ps, pl2, pres, prl)) {
                        SV *fwd = newSVpvn(ps + prl, pl2 - prl);
                        if (!SvCUR(fwd) || *SvPVX(fwd) != '/')
                            sv_insert(fwd, 0, 0, "/", 1);
                        *path_out = sv_2mortal(fwd);
                        return sv_2mortal(newSVsv(*tgt));
                    }
                }
            }
            return NULL;
        }
    }

    {   /* resolver coderef */
        SV *rv = rp_self(aTHX_ self, "resolver", 8);
        if (rv && SvROK(rv) && SvTYPE(SvRV(rv)) == SVt_PVCV) {
            dSP; int n; SV *ret = NULL;
            ENTER; SAVETMPS; PUSHMARK(SP);
            EXTEND(SP, 1); PUSHs(sv_2mortal(newRV_inc((SV *)env)));
            PUTBACK;
            n = call_sv(rv, G_SCALAR);
            SPAGAIN;
            if (n > 0) { SV *t = POPs; if (SvOK(t) && SvCUR(t)) ret = newSVsv(t); }
            PUTBACK; FREETMPS; LEAVE;
            return ret ? sv_2mortal(ret) : NULL;
        }
    }
    return NULL;
}

/* base + path + ?query -> mortal URL SV */
static SV *rp_target_url(pTHX_ SV *base, SV *path, HV *env) {
    STRLEN bl; const char *bp = SvPV_const(base, bl);
    STRLEN pl; const char *pp;
    STRLEN ql; const char *qp;
    SV *url;
    while (bl > 0 && bp[bl - 1] == '/') bl--;         /* trim trailing '/' */
    url = newSVpvn(bp, bl);
    pp = SvPV_const(path, pl);
    if (!pl || pp[0] != '/') sv_catpvs(url, "/");
    sv_catpvn(url, pp, pl);
    qp = rp_env(aTHX_ env, "QUERY_STRING", 12, &ql);
    if (qp) { sv_catpvs(url, "?"); sv_catpvn(url, qp, ql); }
    return sv_2mortal(url);
}

/* Read CONTENT_LENGTH bytes from psgi.input; mortal body SV or NULL. */
static SV *rp_read_body(pTHX_ HV *env) {
    STRLEN ll; const char *lp = rp_env(aTHX_ env, "CONTENT_LENGTH", 14, &ll);
    SV **inp;
    IV len, off = 0;
    SV *body, *in;
    if (!lp) return NULL;
    len = (IV)atol(lp);
    if (len <= 0) return NULL;
    inp = hv_fetchs(env, "psgi.input", 0);
    if (!inp || !*inp || !SvOK(*inp)) return NULL;
    in = *inp;
    body = sv_2mortal(newSVpvs(""));
    while (off < len) {
        dSP; int n; IV got;
        ENTER; SAVETMPS; PUSHMARK(SP);
        EXTEND(SP, 4);
        PUSHs(in);
        PUSHs(body);                       /* aliased: read() fills it */
        PUSHs(sv_2mortal(newSViv(len - off)));
        PUSHs(sv_2mortal(newSViv(off)));
        PUTBACK;
        n = call_method("read", G_SCALAR);
        SPAGAIN;
        got = n > 0 ? POPi : 0;
        PUTBACK; FREETMPS; LEAVE;
        if (got <= 0) break;
        off += got;
    }
    return body;
}

/* One Fetch UA per loop (async) or per process (blocking), cached in
 * $self->{_ua}; built in C via the ABI ua_new on a miss. Borrowed. */
static SV *rp_get_ua(pTHX_ SV *self_sv, HV *self, HV *env, int *async) {
    SV **loopp = hv_fetchs(env, "psgix.loop", 0);
    SV **nbp   = hv_fetchs(env, "psgi.nonblocking", 0);
    SV  *loop  = (loopp && *loopp && SvOK(*loopp)) ? *loopp : NULL;
    int  nb    = (nbp && *nbp && SvTRUE(*nbp)) ? 1 : 0;
    SV **cp    = hv_fetchs(self, "_ua", 0);
    HV  *cache = (cp && *cp && SvROK(*cp)) ? (HV *)SvRV(*cp) : NULL;
    char key[32]; STRLEN kl = 0;
    SV **uap, *ua;
    PERL_UNUSED_ARG(self_sv);

    if (nb && loop) { *async = 1; kl = (STRLEN)my_snprintf(key, sizeof(key),
                        "%" UVuf, PTR2UV(SvRV(loop))); }
    else            { *async = 0; loop = NULL; key[0] = '\0'; }

    if (cache && (uap = hv_fetch(cache, key, (I32)kl, 0)) && *uap && SvOK(*uap))
        return *uap;

    {   /* miss: build the UA in C (ABI ua_new) with the proxy's options, cache it */
        SV *kv[6]; int nkv = 0;
        SV *ps = rp_self(aTHX_ self, "pool_size", 9);
        SV *tv = rp_self(aTHX_ self, "tls_verify", 10);
        if (loop) { kv[nkv++] = sv_2mortal(newSVpvs("loop"));       kv[nkv++] = loop; }
        kv[nkv++] = sv_2mortal(newSVpvs("pool_size"));
        kv[nkv++] = ps ? ps : sv_2mortal(newSViv(64));
        kv[nkv++] = sv_2mortal(newSVpvs("tls_verify"));
        kv[nkv++] = tv ? tv : sv_2mortal(newSViv(1));
        ua = FETCH->ua_new(aTHX_ kv, nkv);          /* +1 owned */
        if (cache) { (void)hv_store(cache, key, (I32)kl, ua, 0); return ua; }
        return sv_2mortal(ua);
    }
}

/* Build headers, issue the request and shape the PSGI response, all in C. */
static SV *rp_dispatch(pTHX_ SV *ua_sv, HV *self, HV *env,
                       const char *method, SV *url, SV *body) {
    int preserve = rp_self_bool(aTHX_ self, "preserve_host", 13);
    SV *via = rp_self(aTHX_ self, "via", 3);
    double timeout = 0;
    SV *tv = rp_self(aTHX_ self, "timeout", 7);
    AV *hav = rp_req_headers(aTHX_ env, preserve, via);
    fetch_hdr *hdrs = NULL;
    int nhdrs = 0;
    const char *bp = NULL; STRLEN blen = 0;
    STRLEN ul; const char *us = SvPV_const(url, ul);
    SV *f;
    if (tv && SvOK(tv)) timeout = SvNV(tv);
    {
        SSize_t n = av_len(hav) + 1, i;
        nhdrs = (int)(n / 2);
        if (nhdrs > 0) {
            Newx(hdrs, nhdrs, fetch_hdr);
            for (i = 0; i + 1 < n; i += 2) {
                SV **k = av_fetch(hav, i, 0);
                SV **v = av_fetch(hav, i + 1, 0);
                hdrs[i / 2].name = SvPV_const(*k, hdrs[i / 2].nlen);
                hdrs[i / 2].val  = SvPV_const(*v, hdrs[i / 2].vlen);
            }
        }
    }
    if (body && SvOK(body)) bp = SvPV_const(body, blen);
    f = FETCH->request(aTHX_ ua_sv, method, us, hdrs, nhdrs,
                       bp, blen, timeout, -1, rp_map, NULL);
    if (hdrs) Safefree(hdrs);
    return f;   /* +1 owned */
}

/* ---- streaming: drive a psgi.streaming writer from the Fetch callbacks --- */

typedef struct rp_sctx { SV *responder; SV *writer; } rp_sctx;

/* headers arrived: open the writer via $responder->([status, \@stripped]) */
static void rp_stream_on_headers(pTHX_ int status, AV *headers, void *ud) {
    rp_sctx *s = (rp_sctx *)ud;
    AV *out = newAV();
    AV *pr;
    SSize_t n = headers ? av_len(headers) + 1 : 0, i;
    dSP; int cnt;
    for (i = 0; i + 1 < n; i += 2) {
        SV **k = av_fetch(headers, i, 0);
        SV **v = av_fetch(headers, i + 1, 0);
        if (k && *k) {
            STRLEN kl; const char *ks = SvPV_const(*k, kl);
            char sb[64], *lc = sb; int drop;
            if (kl > sizeof(sb)) Newx(lc, kl, char);
            rp_lc(ks, kl, lc); drop = rp_is_hop(lc, kl);
            if (lc != sb) Safefree(lc);
            if (drop) continue;
            av_push(out, newSVsv(*k));
            av_push(out, (v && *v) ? newSVsv(*v) : newSVpvs(""));
        }
    }
    pr = newAV();
    av_push(pr, newSViv(status));
    av_push(pr, newRV_noinc((SV *)out));
    ENTER; SAVETMPS; PUSHMARK(SP);
    EXTEND(SP, 1); PUSHs(sv_2mortal(newRV_noinc((SV *)pr)));
    PUTBACK;
    cnt = call_sv(s->responder, G_SCALAR);
    SPAGAIN;
    if (cnt > 0) { SV *w = POPs; if (SvOK(w)) s->writer = SvREFCNT_inc(w); }
    PUTBACK; FREETMPS; LEAVE;
}

/* a body chunk arrived: $writer->write($chunk) */
static void rp_stream_on_body(pTHX_ const char *chunk, STRLEN len, void *ud) {
    rp_sctx *s = (rp_sctx *)ud;
    dSP;
    if (!s->writer) return;
    ENTER; SAVETMPS; PUSHMARK(SP);
    EXTEND(SP, 2); PUSHs(s->writer); PUSHs(sv_2mortal(newSVpvn(chunk, len)));
    PUTBACK;
    call_method("write", G_VOID | G_DISCARD);
    FREETMPS; LEAVE;
}

/* completion: close the writer, or (if nothing was sent yet) emit a 502 */
static void rp_stream_on_done(pTHX_ int ok, SV *err, void *ud) {
    rp_sctx *s = (rp_sctx *)ud;
    dSP;
    PERL_UNUSED_ARG(ok);
    if (s->writer) {
        ENTER; SAVETMPS; PUSHMARK(SP); EXTEND(SP, 1); PUSHs(s->writer);
        PUTBACK; call_method("close", G_VOID | G_DISCARD); FREETMPS; LEAVE;
    } else {
        AV *h = newAV(), *pr = newAV();
        SV *w = NULL; int cnt;
        av_push(h, newSVpvs("Content-Type")); av_push(h, newSVpvs("text/plain"));
        av_push(pr, newSViv(502)); av_push(pr, newRV_noinc((SV *)h));
        ENTER; SAVETMPS; PUSHMARK(SP);
        EXTEND(SP, 1); PUSHs(sv_2mortal(newRV_noinc((SV *)pr)));
        PUTBACK; cnt = call_sv(s->responder, G_SCALAR); SPAGAIN;
        if (cnt > 0) { SV *r = POPs; if (SvOK(r)) w = SvREFCNT_inc(r); }
        PUTBACK; FREETMPS; LEAVE;
        if (w) {
            SV *msg = newSVpvs("502 Bad Gateway: ");
            if (err && SvOK(err)) { STRLEN el; const char *ep = SvPV_const(err, el);
                                    sv_catpvn(msg, ep, el); }
            else sv_catpvs(msg, "upstream request failed");
            ENTER; SAVETMPS; PUSHMARK(SP);
            EXTEND(SP, 2); PUSHs(w); PUSHs(sv_2mortal(msg));
            PUTBACK; call_method("write", G_VOID | G_DISCARD); FREETMPS; LEAVE;
            ENTER; SAVETMPS; PUSHMARK(SP); EXTEND(SP, 1); PUSHs(w);
            PUTBACK; call_method("close", G_VOID | G_DISCARD); FREETMPS; LEAVE;
            SvREFCNT_dec(w);
        }
    }
    if (s->responder) SvREFCNT_dec(s->responder);
    if (s->writer)    SvREFCNT_dec(s->writer);
    Safefree(s);
}

/* ---- plain PSGI responses (built in C) ---------------------------------- */

static SV *rp_plain(pTHX_ int code, const char *msg, STRLEN mlen) {
    AV *h = newAV(), *b = newAV(), *r = newAV();
    av_push(h, newSVpvs("Content-Type"));
    av_push(h, newSVpvs("text/plain"));
    av_push(b, newSVpvn(msg, mlen));
    av_push(r, newSViv(code));
    av_push(r, newRV_noinc((SV *)h));
    av_push(r, newRV_noinc((SV *)b));
    return newRV_noinc((SV *)r);
}

static SV *rp_no_upstream(pTHX_ HV *env) {
    STRLEN pil; const char *pi = rp_env(aTHX_ env, "PATH_INFO", 9, &pil);
    SV *m = newSVpvs("No upstream for ");
    sv_catpvn(m, pi ? pi : "/", pi ? pil : 1);
    { STRLEN l; const char *p = SvPV_const(m, l); SV *r = rp_plain(aTHX_ 404, p, l);
      SvREFCNT_dec(m); return r; }
}

/* ---- WebSocket / Upgrade transparent byte tunnel (C) -------------------- */

#ifndef WIN32
/* scheme://host[:port] -> host/port/tls; returns 1 on success */
static int rp_parse_base(const char *b, STRLEN bl, char *host, size_t hostsz,
                         int *port, int *tls) {
    const char *end = b + bl, *p = b, *sep = NULL, *q, *hs, *he, *colon = NULL;
    int is_tls = 0;
    for (q = b; q + 2 < end; q++)
        if (q[0] == ':' && q[1] == '/' && q[2] == '/') { sep = q; break; }
    if (sep) {
        size_t sl = (size_t)(sep - b);
        if      (sl == 5 && memEQ(b, "https", 5)) is_tls = 1;
        else if (sl == 3 && memEQ(b, "wss", 3))   is_tls = 1;
        p = sep + 3;
    }
    hs = he = p;
    while (he < end && *he != ':' && *he != '/') he++;
    if (he < end && *he == ':') colon = he;
    if ((size_t)(he - hs) == 0 || (size_t)(he - hs) >= hostsz) return 0;
    memcpy(host, hs, (size_t)(he - hs));
    host[he - hs] = '\0';
    if (colon) { *port = atoi(colon + 1); if (*port <= 0) *port = is_tls ? 443 : 80; }
    else       { *port = is_tls ? 443 : 80; }
    *tls = is_tls;
    return 1;
}

static ssize_t rp_read(int fd, char *b, size_t n) {
    ssize_t r;
    do { r = read(fd, b, n); } while (r < 0 && errno == EINTR);
    return r;
}
static int rp_write_all(int fd, const char *b, size_t n) {
    size_t off = 0;
    while (off < n) {
        ssize_t w = write(fd, b + off, n - off);
        if (w < 0) { if (errno == EINTR) continue; return -1; }
        if (w == 0) return -1;
        off += (size_t)w;
    }
    return 0;
}

/* Serialize the raw Upgrade request: client headers verbatim (Upgrade/
 * Connection/Sec-WebSocket-* survive), Host adjusted, X-Forwarded-* added. */
static SV *rp_raw_request(pTHX_ HV *env, SV *path, const char *host, int port,
                          int preserve, SV *via) {
    SV *req = newSVpvs("");
    SV **mp = hv_fetchs(env, "REQUEST_METHOD", 0);
    STRLEN ml, pl, ql; const char *pp, *qp; HE *he;
    char pb[16];
    if (mp && *mp && SvOK(*mp)) { const char *m = SvPV_const(*mp, ml); sv_catpvn(req, m, ml); }
    else sv_catpvs(req, "GET");
    sv_catpvs(req, " ");
    pp = SvPV_const(path, pl); sv_catpvn(req, pp, pl);
    qp = rp_env(aTHX_ env, "QUERY_STRING", 12, &ql);
    if (qp) { sv_catpvs(req, "?"); sv_catpvn(req, qp, ql); }
    sv_catpvs(req, " HTTP/1.1\r\nHost: ");
    {
        STRLEN hl; const char *hh = preserve ? rp_env(aTHX_ env, "HTTP_HOST", 9, &hl) : NULL;
        if (hh) sv_catpvn(req, hh, hl);
        else {
            sv_catpv(req, host);
            if (port != 80 && port != 443)
                { sv_catpvs(req, ":"); sv_catpvn(req, pb, (STRLEN)my_snprintf(pb, sizeof pb, "%d", port)); }
        }
    }
    sv_catpvs(req, "\r\n");
    hv_iterinit(env);
    while ((he = hv_iternext(env))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        char nb[128], lb[128]; char *name = nb, *lc = lb; STRLEN nl, i;
        if (kl < 6 || memNE(k, "HTTP_", 5)) continue;
        nl = (STRLEN)(kl - 5);
        if (nl > sizeof(nb)) { Newx(name, nl, char); Newx(lc, nl, char); }
        for (i = 0; i < nl; i++) { char c = k[5 + i]; if (c == '_') c = '-';
            name[i] = c; lc[i] = (char)toLOWER((U8)c); }
        if (!((nl == 4 && memEQ(lc, "host", 4)) || rp_is_xfwd(lc, nl))) {
            int at = 1; STRLEN j; SV *val;
            for (j = 0; j < nl; j++) { if (name[j] == '-') at = 1;
                else { name[j] = at ? (char)toUPPER((U8)name[j]) : (char)toLOWER((U8)name[j]); at = 0; } }
            val = hv_iterval(env, he);
            { STRLEN vl; const char *vp = SvPV_const(val, vl);
              sv_catpvn(req, name, nl); sv_catpvs(req, ": "); sv_catpvn(req, vp, vl);
              sv_catpvs(req, "\r\n"); }
        }
        if (name != nb) { Safefree(name); Safefree(lc); }
    }
    {
        STRLEN cl; const char *client = rp_env(aTHX_ env, "REMOTE_ADDR", 11, &cl);
        if (client) {
            STRLEN xl; const char *xff = rp_env(aTHX_ env, "HTTP_X_FORWARDED_FOR", 20, &xl);
            sv_catpvs(req, "X-Forwarded-For: ");
            if (xff) { sv_catpvn(req, xff, xl); sv_catpvs(req, ", "); }
            sv_catpvn(req, client, cl); sv_catpvs(req, "\r\n");
        }
    }
    {
        STRLEN pl2; const char *proto = rp_env(aTHX_ env, "HTTP_X_FORWARDED_PROTO", 22, &pl2);
        if (!proto) proto = rp_env(aTHX_ env, "psgi.url_scheme", 15, &pl2);
        sv_catpvs(req, "X-Forwarded-Proto: ");
        if (proto) sv_catpvn(req, proto, pl2); else sv_catpvs(req, "http");
        sv_catpvs(req, "\r\n");
    }
    if (via && SvOK(via)) { STRLEN vl; const char *vp = SvPV_const(via, vl);
        if (vl) { sv_catpvs(req, "Via: "); sv_catpvn(req, vp, vl); sv_catpvs(req, "\r\n"); } }
    sv_catpvs(req, "\r\n");
    return req;
}
#endif /* !WIN32 */

/* Hijack psgix.io, connect to the upstream, relay the Upgrade handshake, then
 * splice bytes both ways until either side closes. Returns a PSGI triplet
 * (200 after a handled hijack; 501/502 on error). */
static SV *rp_tunnel(pTHX_ HV *self, HV *env, SV *base, SV *path) {
#ifdef WIN32
    PERL_UNUSED_ARG(self); PERL_UNUSED_ARG(env);
    PERL_UNUSED_ARG(base); PERL_UNUSED_ARG(path);
    return rp_plain(aTHX_ 501, "Upgrade tunnel unsupported on this platform", 43);
#else
    SV **iop = hv_fetchs(env, "psgix.io", 0);
    SV  *io  = (iop && *iop && SvOK(*iop)) ? *iop : NULL;
    SV  *via = rp_self(aTHX_ self, "via", 3);
    int  preserve = rp_self_bool(aTHX_ self, "preserve_host", 13);
    int  verify   = rp_self_bool(aTHX_ self, "tls_verify", 10);
    int  cfd = -1, ufd, port, tls, seen = 0, fl;
    char host[256], buf[65536];
    STRLEN bl; const char *bp;
    void *uc;                 /* Fetch-owned upstream connection (plain or TLS) */
    SV *req, *resp; ssize_t n;

    if (!io) return rp_plain(aTHX_ 501, "Upgrade requires a server that provides psgix.io", 48);
    { IO *iio = sv_2io(io); if (iio && IoIFP(iio)) cfd = PerlIO_fileno(IoIFP(iio)); }
    if (cfd < 0) return rp_plain(aTHX_ 501, "psgix.io has no file descriptor", 31);

    bp = SvPV_const(base, bl);
    if (!rp_parse_base(bp, bl, host, sizeof host, &port, &tls))
        return rp_plain(aTHX_ 502, "cannot parse upstream base", 26);

    /* connect through Fetch's ABI: it does the TCP connect and, for a
     * wss/https upstream, the TLS handshake with Fetch's own OpenSSL. */
    uc = FETCH->tunnel_connect(host, port, tls, verify);
    if (!uc) return rp_plain(aTHX_ 502, "cannot connect to upstream", 26);
    ufd = FETCH->tunnel_fd(uc);

    /* client socket may be non-blocking (Hyperman); make it blocking to splice */
    fl = fcntl(cfd, F_GETFL, 0);
    if (fl != -1) fcntl(cfd, F_SETFL, fl & ~O_NONBLOCK);

    req = sv_2mortal(rp_raw_request(aTHX_ env, path, host, port, preserve, via));
    { STRLEN rl; const char *rb = SvPV_const(req, rl);
      if (FETCH->tunnel_write_all(uc, rb, (IV)rl) < 0) { FETCH->tunnel_close(uc);
          return rp_plain(aTHX_ 502, "write to upstream failed", 24); } }

    /* read the response header block (may carry first frame bytes), relay it */
    resp = sv_2mortal(newSVpvs(""));
    while (!seen) {
        static const char crlf2[] = "\r\n\r\n";
        n = (ssize_t)FETCH->tunnel_read(uc, buf, (IV)sizeof buf);
        if (n <= 0) break;
        sv_catpvn(resp, buf, n);
        if (ninstr(SvPVX(resp), SvPVX(resp) + SvCUR(resp), crlf2, crlf2 + 4))
            seen = 1;
    }
    if (SvCUR(resp) == 0) { FETCH->tunnel_close(uc);
        return rp_plain(aTHX_ 502, "no response from upstream", 25); }
    { STRLEN rl; const char *rb = SvPV_const(resp, rl);
      if (rp_write_all(cfd, rb, rl) < 0) { FETCH->tunnel_close(uc); return rp_plain(aTHX_ 200, "", 0); } }

    /* splice both directions until one end closes. Drain any TLS-buffered
     * upstream bytes first (select would not report them). */
    for (;;) {
        fd_set rfds; struct timeval tv; int r, mx = (cfd > ufd ? cfd : ufd) + 1;
        if (FETCH->tunnel_pending(uc) > 0) {
            n = (ssize_t)FETCH->tunnel_read(uc, buf, (IV)sizeof buf);
            if (n <= 0) break;
            if (rp_write_all(cfd, buf, n) < 0) break;
            continue;
        }
        FD_ZERO(&rfds); FD_SET(cfd, &rfds); FD_SET(ufd, &rfds);
        tv.tv_sec = 60; tv.tv_usec = 0;
        r = select(mx, &rfds, NULL, NULL, &tv);
        if (r <= 0) break;
        if (FD_ISSET(cfd, &rfds)) { n = rp_read(cfd, buf, sizeof buf);
            if (n <= 0) break; if (FETCH->tunnel_write_all(uc, buf, (IV)n) < 0) break; }
        if (FD_ISSET(ufd, &rfds)) { n = (ssize_t)FETCH->tunnel_read(uc, buf, (IV)sizeof buf);
            if (n <= 0) break; if (rp_write_all(cfd, buf, n) < 0) break; }
    }
    FETCH->tunnel_close(uc);
    return rp_plain(aTHX_ 200, "", 0);
#endif
}

/* ---- streaming: build headers, stream the request, pump the writer ------ */
static void rp_stream_run(pTHX_ SV *ua_sv, const char *method, const char *url,
                          HV *env, SV *body, int preserve_host, SV *via,
                          double timeout, int async, SV *responder) {
    AV *hav = rp_req_headers(aTHX_ env, preserve_host, via);
    fetch_hdr *hdrs = NULL;
    int nhdrs = 0;
    const char *bp = NULL; STRLEN blen = 0;
    rp_sctx *s;
    SV *f;
    {
        SSize_t n = av_len(hav) + 1, i;
        nhdrs = (int)(n / 2);
        if (nhdrs > 0) {
            Newx(hdrs, nhdrs, fetch_hdr);
            for (i = 0; i + 1 < n; i += 2) {
                SV **k = av_fetch(hav, i, 0);
                SV **v = av_fetch(hav, i + 1, 0);
                hdrs[i / 2].name = SvPV_const(*k, hdrs[i / 2].nlen);
                hdrs[i / 2].val  = SvPV_const(*v, hdrs[i / 2].vlen);
            }
        }
    }
    if (body && SvOK(body)) bp = SvPV_const(body, blen);
    Newxz(s, 1, rp_sctx);
    s->responder = SvREFCNT_inc(responder);
    s->writer    = NULL;
    f = FETCH->request_stream(aTHX_ ua_sv, method, url, hdrs, nhdrs,
                              bp, blen, timeout, -1,
                              rp_stream_on_headers, rp_stream_on_body,
                              rp_stream_on_done, s);
    if (hdrs) Safefree(hdrs);
    if (async) {
        SvREFCNT_dec(f);                 /* the loop pumps it; callbacks fire */
    } else {                             /* blocking: pump to completion now */
        dSP;
        ENTER; SAVETMPS; PUSHMARK(SP); EXTEND(SP, 1); PUSHs(sv_2mortal(f));
        PUTBACK;
        call_method("get", G_VOID | G_DISCARD);
        SPAGAIN; PUTBACK; FREETMPS; LEAVE;
    }
}

/* the psgi.streaming coderef body: unpack the captures, run the stream */
XS_INTERNAL(rp_stream_cb);
XS_INTERNAL(rp_stream_cb) {
    dXSARGS;
    AV *cap = rp_clos_cap(aTHX_ cv);
    SV *responder = items >= 1 ? ST(0) : &PL_sv_undef;
    SV *self_sv, *ua, *msv, *usv, *env_rv, *body, *tv;
    HV *self;
    if (!cap) XSRETURN_EMPTY;
    self_sv = *av_fetch(cap, 0, 0);
    ua      = *av_fetch(cap, 1, 0);
    msv     = *av_fetch(cap, 2, 0);
    usv     = *av_fetch(cap, 3, 0);
    env_rv  = *av_fetch(cap, 4, 0);
    body    = *av_fetch(cap, 5, 0);
    self    = (HV *)SvRV(self_sv);
    tv      = rp_self(aTHX_ self, "timeout", 7);
    rp_stream_run(aTHX_ ua, SvPV_nolen(msv), SvPV_nolen(usv),
                  (HV *)SvRV(env_rv), SvOK(body) ? body : NULL,
                  rp_self_bool(aTHX_ self, "preserve_host", 13),
                  rp_self(aTHX_ self, "via", 3),
                  (tv && SvOK(tv)) ? SvNV(tv) : 0,
                  (int)SvIV(*av_fetch(cap, 6, 0)), responder);
    XSRETURN_EMPTY;
}

/* the whole request path in C: resolve, then tunnel / stream / buffer */
static SV *rp_serve(pTHX_ SV *self_sv, SV *env_rv) {
    HV *self, *env;
    SV *path = NULL, *base;
    if (!FETCH) croak("Reverse::Proxy: Fetch C ABI unavailable");
    if (!SvROK(self_sv) || SvTYPE(SvRV(self_sv)) != SVt_PVHV)
        croak("Reverse::Proxy: self must be a hashref");
    if (!SvROK(env_rv) || SvTYPE(SvRV(env_rv)) != SVt_PVHV)
        croak("Reverse::Proxy: env must be a hashref");
    self = (HV *)SvRV(self_sv);
    env  = (HV *)SvRV(env_rv);

    base = rp_resolve(aTHX_ self_sv, self, env, &path);
    if (!base) return rp_no_upstream(aTHX_ env);
    if (rp_is_upgrade(aTHX_ env)) return rp_tunnel(aTHX_ self, env, base, path);
    {
        SV **mp = hv_fetchs(env, "REQUEST_METHOD", 0);
        const char *method = (mp && *mp && SvOK(*mp)) ? SvPV_nolen(*mp) : "GET";
        SV *url  = rp_target_url(aTHX_ base, path, env);
        SV *body = rp_read_body(aTHX_ env);
        int async;
        SV *ua   = rp_get_ua(aTHX_ self_sv, self, env, &async);
        if (rp_self_bool(aTHX_ self, "stream", 6)) {
            AV *cap = newAV();                       /* built and run in C */
            av_push(cap, SvREFCNT_inc(self_sv));
            av_push(cap, SvREFCNT_inc(ua));
            av_push(cap, newSVpv(method, 0));
            av_push(cap, SvREFCNT_inc(url));
            av_push(cap, SvREFCNT_inc(env_rv));
            av_push(cap, body ? SvREFCNT_inc(body) : newSV(0));
            av_push(cap, newSViv(async));
            return rp_closure(aTHX_ rp_stream_cb, cap);
        }
        {
            SV *f = rp_dispatch(aTHX_ ua, self, env, method, url, body);
            if (async) return f;                     /* hand the Future over */
            {                                        /* blocking: await triplet */
                dSP; int n; SV *r;
                ENTER; SAVETMPS; PUSHMARK(SP);
                EXTEND(SP, 1); PUSHs(sv_2mortal(f));
                PUTBACK;
                n = call_method("get", G_SCALAR);
                SPAGAIN;
                r = n > 0 ? SvREFCNT_inc(POPs) : &PL_sv_undef;
                PUTBACK; FREETMPS; LEAVE;
                return r;
            }
        }
    }
}

/* the PSGI app coderef body (to_app): call rp_serve($self, $env) */
XS_INTERNAL(rp_app_cb);
XS_INTERNAL(rp_app_cb) {
    dXSARGS;
    AV *cap = rp_clos_cap(aTHX_ cv);
    SV *self_sv = cap ? *av_fetch(cap, 0, 0) : NULL;
    SV *env = items >= 1 ? ST(0) : &PL_sv_undef;
    SV *resp;
    if (!self_sv) XSRETURN_EMPTY;
    resp = rp_serve(aTHX_ self_sv, env);
    ST(0) = sv_2mortal(resp);
    XSRETURN(1);
}

MODULE = Reverse::Proxy		PACKAGE = Reverse::Proxy

PROTOTYPES: DISABLE

BOOT:
{
    IV p = 0;
    dSP;
    PUSHMARK(SP);
    PUTBACK;
    if (call_pv("Fetch::_abi_ptr", G_SCALAR) > 0) {
        SPAGAIN;
        p = POPi;
        PUTBACK;
    }
    if (p) {
        const fetch_abi *a = INT2PTR(const fetch_abi *, p);
        if (a && a->abi_version == FETCH_ABI_VERSION) FETCH = a;
    }
    sv_setiv(get_sv("Reverse::Proxy::_HAVE_XS", GV_ADD), FETCH ? 1 : 0);
}

# True when the Fetch C ABI resolved and matched our vendored version.
int
_abi_ok()
    CODE:
        RETVAL = FETCH ? 1 : 0;
    OUTPUT:
        RETVAL

# The whole request path, in C (rp_serve): resolve the target, then tunnel
# (Upgrade), stream (stream => 1), or buffer through the Fetch ABI. Returns a
# Fetch::Future (async servers) or the PSGI triplet (blocking). to_app's app
# coderef calls the same rp_serve.
SV *
_serve(self_sv, env_rv)
        SV *self_sv
        SV *env_rv
    CODE:
        RETVAL = rp_serve(aTHX_ self_sv, env_rv);
    OUTPUT:
        RETVAL

# Reverse::Proxy->new(%opt): validate exactly one target selector, normalise
# routes (longest prefix first) and bless the config hash - all in C.
SV *
new(class, ...)
        SV *class
    CODE:
    {
        const char *cls = (SvROK(class) && SvOBJECT(SvRV(class)))
                        ? HvNAME(SvSTASH(SvRV(class))) : SvPV_nolen(class);
        HV *self = newHV();
        SV *upstream = NULL, *routes_arg = NULL, *resolver = NULL, *via = NULL;
        SV *preserve = NULL, *stream = NULL, *pool = NULL, *timeout = NULL, *tlsv = NULL;
        int i, nsel, have_via = 0;
        for (i = 1; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            SV *v = ST(i + 1);
            if      (strEQ(k, "upstream"))      { if (SvOK(v)) upstream = v; }
            else if (strEQ(k, "routes"))        { if (SvOK(v)) routes_arg = v; }
            else if (strEQ(k, "resolver"))      { if (SvOK(v)) resolver = v; }
            else if (strEQ(k, "preserve_host")) preserve = v;
            else if (strEQ(k, "stream"))        stream = v;
            else if (strEQ(k, "pool_size"))     pool = v;
            else if (strEQ(k, "timeout"))        timeout = v;
            else if (strEQ(k, "tls_verify"))    tlsv = v;
            else if (strEQ(k, "via"))           { via = v; have_via = 1; }
        }
        nsel = (upstream ? 1 : 0) + (routes_arg ? 1 : 0) + (resolver ? 1 : 0);
        if (nsel != 1)
            croak("Reverse::Proxy->new: give exactly one of 'upstream', 'routes', 'resolver'");
        if (upstream) (void)hv_stores(self, "upstream", newSVsv(upstream));
        if (resolver) (void)hv_stores(self, "resolver", newSVsv(resolver));
        if (routes_arg) {
            AV *src, *pairs; SSize_t n, j;
            if (!SvROK(routes_arg) || SvTYPE(SvRV(routes_arg)) != SVt_PVAV)
                croak("Reverse::Proxy->new: routes must be [ prefix => url, ... ]");
            src = (AV *)SvRV(routes_arg); n = av_len(src) + 1;
            if (n % 2) croak("Reverse::Proxy->new: routes must be [ prefix => url, ... ]");
            pairs = newAV();
            for (j = 0; j + 1 < n; j += 2) {
                SV **p = av_fetch(src, j, 0), **u = av_fetch(src, j + 1, 0);
                AV *pair = newAV();
                av_push(pair, (p && *p) ? newSVsv(*p) : newSV(0));
                av_push(pair, (u && *u) ? newSVsv(*u) : newSV(0));
                av_push(pairs, newRV_noinc((SV *)pair));
            }
            {   /* longest prefix first (selection sort; routes are few) */
                SSize_t m = av_len(pairs) + 1, a, b;
                SV **arr = AvARRAY(pairs);
                for (a = 0; a + 1 < m; a++) {
                    SSize_t best = a;
                    STRLEN bl = SvCUR(*av_fetch((AV *)SvRV(arr[a]), 0, 0));
                    for (b = a + 1; b < m; b++) {
                        STRLEN l = SvCUR(*av_fetch((AV *)SvRV(arr[b]), 0, 0));
                        if (l > bl) { best = b; bl = l; }
                    }
                    if (best != a) { SV *t = arr[a]; arr[a] = arr[best]; arr[best] = t; }
                }
            }
            (void)hv_stores(self, "routes", newRV_noinc((SV *)pairs));
        }
        (void)hv_stores(self, "preserve_host", newSViv(preserve && SvTRUE(preserve) ? 1 : 0));
        (void)hv_stores(self, "stream",        newSViv(stream && SvTRUE(stream) ? 1 : 0));
        (void)hv_stores(self, "pool_size",     newSViv((pool && SvOK(pool)) ? SvIV(pool) : 64));
        (void)hv_stores(self, "timeout",       newSVnv((timeout && SvOK(timeout)) ? SvNV(timeout) : 30));
        (void)hv_stores(self, "tls_verify",    newSViv((tlsv && SvOK(tlsv)) ? (SvTRUE(tlsv) ? 1 : 0) : 1));
        (void)hv_stores(self, "via", have_via ? newSVsv(via) : newSVpvs("Reverse::Proxy"));
        (void)hv_stores(self, "_ua", newRV_noinc((SV *)newHV()));
        RETVAL = sv_bless(newRV_noinc((SV *)self), gv_stashpv(cls, GV_ADD));
    }
    OUTPUT:
        RETVAL

# to_app: the PSGI app coderef, built in C (captures $self, calls rp_serve).
SV *
to_app(self_sv)
        SV *self_sv
    CODE:
    {
        AV *cap = newAV();
        av_push(cap, SvREFCNT_inc(self_sv));
        RETVAL = rp_closure(aTHX_ rp_app_cb, cap);
    }
    OUTPUT:
        RETVAL
