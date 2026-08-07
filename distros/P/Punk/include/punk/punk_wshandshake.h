/* punk_wshandshake.h - the WebSocket upgrade handshake, in C.
 *
 * Punk::WebSocket::_dispatch, reached from the dispatcher once a route's
 * guards have passed: validate the upgrade request, negotiate a subprotocol,
 * answer with the RFC 6455 Sec-WebSocket-Accept, then take the socket over
 * (Hyperman's detach ABI, or the blocking psgix.io fallback) and hand the
 * connection to the route's handler. The frame codec and the connection object
 * are already C (punk_ws.h / punk_wsconn.h, xs/websocket.xs); this is the last
 * Perl piece, so lib/Punk/WebSocket.pm becomes documentation only.
 *
 * SHA-1 and base64 are bundled here (a public-domain SHA-1, ~80 lines) rather
 * than pulled from Digest::SHA / OpenSSL: it keeps the dist zero-dependency and
 * takes the two core-module calls off the once-per-connection path.
 *
 * Must be included after punk_context.h (pcx_call_meth / pcx_call2).
 */

#ifndef PUNK_WSHANDSHAKE_H
#define PUNK_WSHANDSHAKE_H

/* the RFC 6455 magic GUID appended to the client key before the digest */
#define PW_GUID "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

/* ---- SHA-1 (public domain) ------------------------------------------------ */

#define PW_ROL(v, b) (((v) << (b)) | ((v) >> (32 - (b))))

static void pw_sha1(const unsigned char *msg, size_t len, unsigned char out[20]) {
    U32 h0 = 0x67452301, h1 = 0xEFCDAB89, h2 = 0x98BADCFE,
        h3 = 0x10325476, h4 = 0xC3D2E1F0;
    size_t total = ((len + 8) / 64 + 1) * 64, off;
    unsigned char *m;
    U32 lo = (U32)(len << 3), hi = (U32)(len >> 29);
    Newxz(m, total, unsigned char);
    memcpy(m, msg, len);
    m[len] = 0x80;
    m[total - 1] = (unsigned char)(lo & 0xff);
    m[total - 2] = (unsigned char)((lo >> 8) & 0xff);
    m[total - 3] = (unsigned char)((lo >> 16) & 0xff);
    m[total - 4] = (unsigned char)((lo >> 24) & 0xff);
    m[total - 5] = (unsigned char)(hi & 0xff);
    m[total - 6] = (unsigned char)((hi >> 8) & 0xff);
    m[total - 7] = (unsigned char)((hi >> 16) & 0xff);
    m[total - 8] = (unsigned char)((hi >> 24) & 0xff);
    for (off = 0; off < total; off += 64) {
        U32 w[80], a, b, c, d, e, f, k, tmp;
        int i;
        for (i = 0; i < 16; i++)
            w[i] = ((U32)m[off + 4*i] << 24) | ((U32)m[off + 4*i + 1] << 16)
                 | ((U32)m[off + 4*i + 2] << 8) | (U32)m[off + 4*i + 3];
        for (i = 16; i < 80; i++)
            w[i] = PW_ROL(w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16], 1);
        a = h0; b = h1; c = h2; d = h3; e = h4;
        for (i = 0; i < 80; i++) {
            if      (i < 20) { f = (b & c) | ((~b) & d);          k = 0x5A827999; }
            else if (i < 40) { f = b ^ c ^ d;                     k = 0x6ED9EBA1; }
            else if (i < 60) { f = (b & c) | (b & d) | (c & d);   k = 0x8F1BBCDC; }
            else             { f = b ^ c ^ d;                     k = 0xCA62C1D6; }
            tmp = PW_ROL(a, 5) + f + e + k + w[i];
            e = d; d = c; c = PW_ROL(b, 30); b = a; a = tmp;
        }
        h0 += a; h1 += b; h2 += c; h3 += d; h4 += e;
    }
    Safefree(m);
    {
        U32 hh[5]; int i;
        hh[0] = h0; hh[1] = h1; hh[2] = h2; hh[3] = h3; hh[4] = h4;
        for (i = 0; i < 5; i++) {
            out[4*i]     = (unsigned char)((hh[i] >> 24) & 0xff);
            out[4*i + 1] = (unsigned char)((hh[i] >> 16) & 0xff);
            out[4*i + 2] = (unsigned char)((hh[i] >> 8) & 0xff);
            out[4*i + 3] = (unsigned char)(hh[i] & 0xff);
        }
    }
}

/* ---- base64 --------------------------------------------------------------- */

static void pw_base64(const unsigned char *in, size_t len, char *out) {
    static const char B64[] =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    size_t i = 0, o = 0;
    for (; i + 3 <= len; i += 3) {
        U32 n = ((U32)in[i] << 16) | ((U32)in[i+1] << 8) | in[i+2];
        out[o++] = B64[(n >> 18) & 63]; out[o++] = B64[(n >> 12) & 63];
        out[o++] = B64[(n >> 6) & 63];  out[o++] = B64[n & 63];
    }
    if (i < len) {
        int rem = (int)(len - i);
        U32 n = (U32)in[i] << 16;
        if (rem == 2) n |= (U32)in[i+1] << 8;
        out[o++] = B64[(n >> 18) & 63];
        out[o++] = B64[(n >> 12) & 63];
        out[o++] = rem == 2 ? B64[(n >> 6) & 63] : '=';
        out[o++] = '=';
    }
    out[o] = '\0';
}

/* ---- request helpers ------------------------------------------------------ */

static const char *pw_env(pTHX_ HV *env, const char *k, STRLEN *len) {
    SV **e = hv_fetch(env, k, (I32)strlen(k), 0);
    if (e && *e && SvOK(*e)) return SvPV_const(*e, *len);
    *len = 0; return "";
}

/* case-insensitive substring test (needle is already lowercase) */
static int pw_ci_has(const char *hay, STRLEN hlen, const char *needle) {
    STRLEN nl = strlen(needle), i, j;
    if (nl == 0) return 1;
    for (i = 0; i + nl <= hlen; i++) {
        for (j = 0; j < nl; j++) {
            char ch = hay[i + j];
            if (ch >= 'A' && ch <= 'Z') ch = (char)(ch + 32);
            if (ch != needle[j]) break;
        }
        if (j == nl) return 1;
    }
    return 0;
}

static int pw_is_b64_key(const char *k, STRLEN kl) {
    STRLEN i;
    if (kl != 24 || k[22] != '=' || k[23] != '=') return 0;
    for (i = 0; i < 22; i++) {
        char ch = k[i];
        if (!((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z')
              || (ch >= '0' && ch <= '9') || ch == '+' || ch == '/'))
            return 0;
    }
    return 1;
}

/* A short text error response (the Perl $ERR), with an optional header. */
static SV *pw_err(pTHX_ IV status, const char *msg, const char *hk, const char *hv) {
    AV *resp = newAV(), *headers = newAV(), *body = newAV();
    STRLEN len = strlen(msg);
    av_push(headers, newSVpvs("Content-Type"));
    av_push(headers, newSVpvs("text/plain; charset=utf-8"));
    av_push(headers, newSVpvs("Content-Length"));
    av_push(headers, newSViv((IV)len));
    if (hk) { av_push(headers, newSVpv(hk, 0)); av_push(headers, newSVpv(hv, 0)); }
    av_push(body, newSVpvn(msg, len));
    av_push(resp, newSViv(status));
    av_push(resp, newRV_noinc((SV *)headers));
    av_push(resp, newRV_noinc((SV *)body));
    return newRV_noinc((SV *)resp);
}

/* an empty [ status, [], [] ] the server discards after the upgrade */
static SV *pw_empty(pTHX_ IV status) {
    AV *resp = newAV();
    av_push(resp, newSViv(status));
    av_push(resp, newRV_noinc((SV *)newAV()));
    av_push(resp, newRV_noinc((SV *)newAV()));
    return newRV_noinc((SV *)resp);
}

/* Call a Punk::WebSocket class method (_attach / _attach_blocking); +1. */
static SV *pw_class_call(pTHX_ const char *meth, SV **argv, int n) {
    return pcx_call_meth(aTHX_ sv_2mortal(newSVpvs(PK_WEBSOCKET)), meth, argv, n, 1);
}

/* Run the route handler ($code->($c, $ws)); on death close 1011 and rethrow. */
static void pw_run_handler(pTHX_ SV *code, SV *c, SV *ws) {
    int died = 0;
    SV *r = pcx_call2(aTHX_ code, c, ws, &died);
    if (r) SvREFCNT_dec(r);
    if (died) {
        SV *e = sv_2mortal(newSVsv(ERRSV));
        SV *ca[2], *cr;
        ca[0] = sv_2mortal(newSViv(1011));
        ca[1] = sv_2mortal(newSVpvs("handler error"));
        cr = pcx_call_meth(aTHX_ ws, "close", ca, 2, 0);
        if (cr) SvREFCNT_dec(cr);
        croak_sv(e);
    }
    { SV *o = pcx_call_meth(aTHX_ ws, "_open", NULL, 0, 0);
      if (o) SvREFCNT_dec(o); }
}

/* ---- the upgrade ---------------------------------------------------------- */

static SV *punk_ws_dispatch(pTHX_ SV *c, SV *rec, SV *env) {
    HV *envh = (SvROK(env) && SvTYPE(SvRV(env)) == SVt_PVHV) ? (HV *)SvRV(env) : NULL;
    HV *rech = (SvROK(rec) && SvTYPE(SvRV(rec)) == SVt_PVHV) ? (HV *)SvRV(rec) : NULL;
    HV *opts = NULL;
    SV **x, *code = NULL, *protocol = NULL;
    const char *method, *upg, *conn, *key, *ver;
    STRLEN mlen, ul, cl, kl, vl;
    unsigned char digest[20];
    char accept[30];
    SV *hs, *attach_rv;
    HV *attach;

    if (!envh || !rech) return pw_err(aTHX_ 500, "bad websocket dispatch\n", NULL, NULL);
    x = hv_fetchs(rech, K_WS, 0);
    if (x && *x && SvROK(*x) && SvTYPE(SvRV(*x)) == SVt_PVHV) opts = (HV *)SvRV(*x);
    x = hv_fetchs(rech, K_CODE, 0);
    code = (x && *x) ? *x : &PL_sv_undef;

    method = pw_env(aTHX_ envh, "REQUEST_METHOD", &mlen);
    if (!(mlen == 3 && memEQ(method, "GET", 3)))
        return pw_err(aTHX_ 405, "websocket routes are GET\n", "Allow", "GET");

    upg  = pw_env(aTHX_ envh, "HTTP_UPGRADE", &ul);
    conn = pw_env(aTHX_ envh, "HTTP_CONNECTION", &cl);
    if (!(pw_ci_has(upg, ul, "websocket") && pw_ci_has(conn, cl, "upgrade")))
        return pw_err(aTHX_ 400, "not a websocket upgrade\n", NULL, NULL);

    key = pw_env(aTHX_ envh, "HTTP_SEC_WEBSOCKET_KEY", &kl);
    if (!pw_is_b64_key(key, kl))
        return pw_err(aTHX_ 400, "bad Sec-WebSocket-Key\n", NULL, NULL);

    ver = pw_env(aTHX_ envh, "HTTP_SEC_WEBSOCKET_VERSION", &vl);
    if (!(vl == 2 && memEQ(ver, "13", 2)))
        return pw_err(aTHX_ 426, "unsupported websocket version\n",
                      "Sec-WebSocket-Version", "13");

    /* subprotocol: only when the route declares a list. First offered value
     * that the route accepts wins; a declared list with no match is a 400. */
    if (opts && (x = hv_fetchs(opts, "protocols", 0))
        && *x && SvROK(*x) && SvTYPE(SvRV(*x)) == SVt_PVAV) {
        AV *want = (AV *)SvRV(*x);
        STRLEN pl; const char *ps = pw_env(aTHX_ envh, "HTTP_SEC_WEBSOCKET_PROTOCOL", &pl);
        int saw_offer = 0;
        STRLEN i = 0;
        while (i < pl && !protocol) {
            STRLEN s, e2, j; SSize_t wi, wn;
            while (i < pl && (ps[i] == ' ' || ps[i] == '\t' || ps[i] == ',')) i++;
            s = i;
            while (i < pl && ps[i] != ',') i++;
            e2 = i;
            while (e2 > s && (ps[e2-1] == ' ' || ps[e2-1] == '\t')) e2--;
            if (e2 == s) continue;
            saw_offer = 1;
            wn = av_len(want) + 1;
            for (wi = 0; wi < wn; wi++) {
                SV **wp = av_fetch(want, wi, 0);
                STRLEN wl; const char *ws2;
                if (!wp || !*wp) continue;
                ws2 = SvPV_const(*wp, wl);
                if (wl == e2 - s) {
                    for (j = 0; j < wl && ws2[j] == ps[s + j]; j++) ;
                    if (j == wl) { protocol = sv_2mortal(newSVpvn(ps + s, wl)); break; }
                }
            }
        }
        if (saw_offer && !protocol)
            return pw_err(aTHX_ 400, "no acceptable subprotocol\n", NULL, NULL);
    }

    /* Sec-WebSocket-Accept = base64(sha1(key . GUID)) */
    {
        unsigned char kg[24 + sizeof(PW_GUID) - 1];
        memcpy(kg, key, 24);
        memcpy(kg + 24, PW_GUID, sizeof(PW_GUID) - 1);
        pw_sha1(kg, sizeof(kg), digest);
        pw_base64(digest, 20, accept);
    }

    hs = sv_2mortal(newSVpvs(
        "HTTP/1.1 101 Switching Protocols\r\n"
        "Upgrade: websocket\r\n"
        "Connection: Upgrade\r\n"
        "Sec-WebSocket-Accept: "));
    sv_catpv(hs, accept);
    sv_catpvs(hs, "\r\n");
    if (protocol) {
        sv_catpvs(hs, "Sec-WebSocket-Protocol: ");
        sv_catsv(hs, protocol);
        sv_catpvs(hs, "\r\n");
    }
    sv_catpvs(hs, "\r\n");

    /* the attach options: the route opts minus `protocols`, plus the
     * negotiated `protocol` (the connection object reads these). */
    attach = newHV();
    if (opts) {
        HE *he;
        hv_iterinit(opts);
        while ((he = hv_iternext(opts))) {
            STRLEN hkl; const char *hk = HePV(he, hkl);
            if (hkl == 9 && memEQ(hk, "protocols", 9)) continue;
            (void)hv_store(attach, hk, (I32)hkl, newSVsv(hv_iterval(opts, he)), 0);
        }
    }
    if (protocol) (void)hv_stores(attach, "protocol", newSVsv(protocol));
    attach_rv = sv_2mortal(newRV_noinc((SV *)attach));

    /* Hyperman: detach the socket and drive it on the worker loop. */
    x = hv_fetchs(envh, "psgix.hyperman.conn", 0);
    if (x && *x && SvTRUE(*x)) {
        int ok;
        {   /* _hm_available() - a no-arg function, not a method */
            dSP; int count;
            ENTER; SAVETMPS;
            PUSHMARK(SP); PUTBACK;
            count = call_pv(PK_WEBSOCKET "::_hm_available", G_SCALAR);
            SPAGAIN;
            ok = count > 0 ? SvTRUE(TOPs) : 0;
            if (count > 0) (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
        }
        if (ok) {
            IV fd; int died = 0;
            SV *ws, *argv[3];
            {
                dSP; int count;
                ENTER; SAVETMPS;
                PUSHMARK(SP); EXTEND(SP, 1); PUSHs(env); PUTBACK;
                count = call_pv(PK_WEBSOCKET "::_hm_detach", G_SCALAR | G_EVAL);
                SPAGAIN;
                died = SvTRUE(ERRSV) ? 1 : 0;
                fd = (count > 0) ? (died ? (POPs, 0) : POPi) : 0;
                PUTBACK; FREETMPS; LEAVE;
            }
            if (died) {
                const char *em = SvPV_nolen(ERRSV);
                if (strstr(em, "draining") || strstr(em, "already detached"))
                    return pw_err(aTHX_ 400, "cannot upgrade this connection\n",
                                  NULL, NULL);
                croak_sv(ERRSV);
            }
            argv[0] = sv_2mortal(newSViv(fd));
            argv[1] = hs;
            argv[2] = attach_rv;
            ws = pw_class_call(aTHX_ "_attach", argv, 3);
            pw_run_handler(aTHX_ code, c, ws ? ws : &PL_sv_undef);
            if (ws) SvREFCNT_dec(ws);
            return pw_empty(aTHX_ 101);        /* discarded by Hyperman */
        }
    }

    /* Blocking fallback: own the socket inside the handler (pins a worker). */
    x = opts ? hv_fetchs(opts, K_BLOCKING, 0) : NULL;
    if (x && *x && SvTRUE(*x)) {
        SV **iop = hv_fetchs(envh, "psgix.io", 0);
        if (iop && *iop && SvOK(*iop)) {
            IO *io = sv_2io(*iop);
            IV fd = (io && IoIFP(io)) ? (IV)PerlIO_fileno(IoIFP(io)) : -1;
            SV *ws, *argv[3], *rb;
            argv[0] = sv_2mortal(newSViv(fd));
            argv[1] = hs;                       /* _attach_blocking flushes it */
            argv[2] = attach_rv;
            ws = pw_class_call(aTHX_ "_attach_blocking", argv, 3);
            pw_run_handler(aTHX_ code, c, ws ? ws : &PL_sv_undef);
            rb = pcx_call_meth(aTHX_ ws ? ws : &PL_sv_undef, "_run_blocking",
                               NULL, 0, 0);
            if (rb) SvREFCNT_dec(rb);
            if (ws) SvREFCNT_dec(ws);
            return pw_empty(aTHX_ 200);         /* the socket is gone */
        }
    }

    return pw_err(aTHX_ 501,
        "this server cannot upgrade websockets (needs Hyperman 0.11+, "
        "or blocking => 1 with psgix.io)\n", NULL, NULL);
}

#endif /* PUNK_WSHANDSHAKE_H */
