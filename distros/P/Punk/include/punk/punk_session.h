/* punk_session.h - signed cookie sessions, in C.
 *
 * The session is the handler's hashref, JSON-encoded (punk_frj) and carried in
 * a cookie as base64url(payload).base64url(HMAC-SHA256(payload, key)) - the
 * client can read it but cannot forge it. A bundled public-domain SHA-256 (as
 * SHA-1 was bundled for the WS handshake) keeps the dist zero-dependency.
 *
 * Must be included after punk_context.h (frj / pcx_*), punk_cookie.h
 * (pk_build_cookie) and punk_names.h.
 */

#ifndef PUNK_SESSION_H
#define PUNK_SESSION_H

/* ---- SHA-256 (public domain) ---------------------------------------------- */

#define PS_ROR(x, n) (((x) >> (n)) | ((x) << (32 - (n))))

static const U32 ps_sha256_k[64] = {
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

static void pk_sha256(const unsigned char *msg, size_t len, unsigned char out[32]) {
    U32 h[8] = { 0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,
                 0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19 };
    size_t total = ((len + 8) / 64 + 1) * 64, off;
    unsigned char *m;
    U32 hi = (U32)(len >> 29), lo = (U32)(len << 3);
    int i;
    Newxz(m, total, unsigned char);
    memcpy(m, msg, len);
    m[len] = 0x80;
    m[total-1]=(unsigned char)(lo&0xff); m[total-2]=(unsigned char)((lo>>8)&0xff);
    m[total-3]=(unsigned char)((lo>>16)&0xff); m[total-4]=(unsigned char)((lo>>24)&0xff);
    m[total-5]=(unsigned char)(hi&0xff); m[total-6]=(unsigned char)((hi>>8)&0xff);
    m[total-7]=(unsigned char)((hi>>16)&0xff); m[total-8]=(unsigned char)((hi>>24)&0xff);
    for (off = 0; off < total; off += 64) {
        U32 w[64], a, b, c, d, e, f, g, hh, t1, t2;
        for (i = 0; i < 16; i++)
            w[i] = ((U32)m[off+4*i]<<24)|((U32)m[off+4*i+1]<<16)
                 | ((U32)m[off+4*i+2]<<8)|(U32)m[off+4*i+3];
        for (i = 16; i < 64; i++) {
            U32 s0 = PS_ROR(w[i-15],7) ^ PS_ROR(w[i-15],18) ^ (w[i-15]>>3);
            U32 s1 = PS_ROR(w[i-2],17) ^ PS_ROR(w[i-2],19) ^ (w[i-2]>>10);
            w[i] = w[i-16] + s0 + w[i-7] + s1;
        }
        a=h[0];b=h[1];c=h[2];d=h[3];e=h[4];f=h[5];g=h[6];hh=h[7];
        for (i = 0; i < 64; i++) {
            U32 S1 = PS_ROR(e,6)^PS_ROR(e,11)^PS_ROR(e,25);
            U32 ch = (e & f) ^ ((~e) & g);
            U32 S0 = PS_ROR(a,2)^PS_ROR(a,13)^PS_ROR(a,22);
            U32 maj = (a & b) ^ (a & c) ^ (b & c);
            t1 = hh + S1 + ch + ps_sha256_k[i] + w[i];
            t2 = S0 + maj;
            hh=g; g=f; f=e; e=d+t1; d=c; c=b; b=a; a=t1+t2;
        }
        h[0]+=a;h[1]+=b;h[2]+=c;h[3]+=d;h[4]+=e;h[5]+=f;h[6]+=g;h[7]+=hh;
    }
    Safefree(m);
    for (i = 0; i < 8; i++) {
        out[4*i]  =(unsigned char)((h[i]>>24)&0xff);
        out[4*i+1]=(unsigned char)((h[i]>>16)&0xff);
        out[4*i+2]=(unsigned char)((h[i]>>8)&0xff);
        out[4*i+3]=(unsigned char)(h[i]&0xff);
    }
}

static void pk_hmac_sha256(const unsigned char *key, size_t klen,
                           const unsigned char *msg, size_t mlen,
                           unsigned char out[32]) {
    unsigned char k[64], ipad[64], opad[64], ihash[32], ob[96];
    unsigned char *ibuf;
    int i;
    if (klen > 64) { pk_sha256(key, klen, k); memset(k+32, 0, 32); }
    else { memcpy(k, key, klen); if (klen < 64) memset(k+klen, 0, 64-klen); }
    for (i = 0; i < 64; i++) { ipad[i] = k[i]^0x36; opad[i] = k[i]^0x5c; }
    Newx(ibuf, 64 + mlen, unsigned char);
    memcpy(ibuf, ipad, 64);
    if (mlen) memcpy(ibuf+64, msg, mlen);
    pk_sha256(ibuf, 64+mlen, ihash);
    Safefree(ibuf);
    memcpy(ob, opad, 64);
    memcpy(ob+64, ihash, 32);
    pk_sha256(ob, 96, out);
}

/* ---- base64url (no padding, cookie-safe) ---------------------------------- */

static const char PS_B64U[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

static SV *pk_b64url(pTHX_ const unsigned char *in, size_t len) {
    SV *out = newSVpvs("");
    size_t i = 0;
    for (; i + 3 <= len; i += 3) {
        U32 n = ((U32)in[i]<<16)|((U32)in[i+1]<<8)|in[i+2];
        char c[4] = { PS_B64U[(n>>18)&63], PS_B64U[(n>>12)&63],
                      PS_B64U[(n>>6)&63], PS_B64U[n&63] };
        sv_catpvn(out, c, 4);
    }
    if (i < len) {
        int rem = (int)(len - i), cn = 2;
        U32 n = (U32)in[i]<<16;
        char c[3];
        if (rem == 2) n |= (U32)in[i+1]<<8;
        c[0] = PS_B64U[(n>>18)&63];
        c[1] = PS_B64U[(n>>12)&63];
        if (rem == 2) c[cn++] = PS_B64U[(n>>6)&63];
        sv_catpvn(out, c, cn);
    }
    return out;
}

static int ps_b64u_val(unsigned char c) {
    if (c>='A'&&c<='Z') return c-'A';
    if (c>='a'&&c<='z') return c-'a'+26;
    if (c>='0'&&c<='9') return c-'0'+52;
    if (c=='-') return 62;
    if (c=='_') return 63;
    return -1;
}

static SV *pk_b64url_decode(pTHX_ const char *in, size_t len) {
    SV *out = newSVpvs("");
    U32 acc = 0; int bits = 0; size_t i;
    for (i = 0; i < len; i++) {
        int v = ps_b64u_val((unsigned char)in[i]);
        if (v < 0) { SvREFCNT_dec(out); return NULL; }
        acc = (acc << 6) | (U32)v; bits += 6;
        if (bits >= 8) { unsigned char b; bits -= 8; b = (acc >> bits) & 0xff;
                         sv_catpvn(out, (char *)&b, 1); }
    }
    return out;
}

/* ---- sign / verify -------------------------------------------------------- */

/* payload -> "base64url(payload).base64url(HMAC(base64url(payload)))" (+1) */
static SV *pk_session_sign(pTHX_ SV *payload, const char *key, STRLEN klen) {
    STRLEN pl; const char *p = SvPV_const(payload, pl);
    unsigned char mac[32];
    SV *b64p = pk_b64url(aTHX_ (const unsigned char *)p, pl);
    SV *out;
    pk_hmac_sha256((const unsigned char *)key, klen,
                   (const unsigned char *)SvPVX(b64p), SvCUR(b64p), mac);
    out = newSVsv(b64p);
    SvREFCNT_dec(b64p);
    sv_catpvs(out, ".");
    { SV *b64m = pk_b64url(aTHX_ mac, 32); sv_catsv(out, b64m); SvREFCNT_dec(b64m); }
    return out;
}

/* verify a cookie value; on a good signature return the decoded payload (+1),
 * else NULL. Constant-time signature compare. */
static SV *pk_session_verify(pTHX_ const char *cookie, STRLEN clen,
                             const char *key, STRLEN klen) {
    STRLEN i, dot = clen;
    const char *b64p, *sig;
    STRLEN b64pl, sigl;
    unsigned char mac[32];
    SV *expsig;
    for (i = clen; i > 0; i--) if (cookie[i-1] == '.') { dot = i-1; break; }
    if (dot >= clen) return NULL;
    b64p = cookie; b64pl = dot;
    sig = cookie + dot + 1; sigl = clen - dot - 1;
    pk_hmac_sha256((const unsigned char *)key, klen,
                   (const unsigned char *)b64p, b64pl, mac);
    expsig = pk_b64url(aTHX_ mac, 32);
    if (SvCUR(expsig) != sigl) { SvREFCNT_dec(expsig); return NULL; }
    {
        const char *e = SvPVX(expsig);
        unsigned char diff = 0;
        STRLEN j;
        for (j = 0; j < sigl; j++) diff |= (unsigned char)(e[j] ^ sig[j]);
        SvREFCNT_dec(expsig);
        if (diff) return NULL;
    }
    return pk_b64url_decode(aTHX_ b64p, b64pl);
}

/* ---- the session lifecycle ------------------------------------------------ *
 * $c->session is a hashref cached in the stash under `punk.session` alongside
 * the canonical serialization it loaded with (`punk.session.orig`); the after-
 * dispatch write-back re-signs a Set-Cookie only when that serialization
 * changed, or deletes the cookie when session_expire set `punk.session.expire`. */

/* the session config the `session` keyword froze on the app, or NULL */
static HV *ps_cfg(pTHX_ SV *c) {
    SV *app = pcx_get(aTHX_ pcx_av(aTHX_ c), PCX_APP);
    SV **s;
    if (!(app && SvROK(app) && SvTYPE(SvRV(app)) == SVt_PVHV)) return NULL;
    s = hv_fetchs((HV *)SvRV(app), "session", 0);
    return (s && *s && SvROK(*s) && SvTYPE(SvRV(*s)) == SVt_PVHV)
        ? (HV *)SvRV(*s) : NULL;
}

static const char *ps_cfg_str(pTHX_ HV *cfg, const char *k, const char *def,
                              STRLEN *len) {
    SV **e = hv_fetch(cfg, k, (I32)strlen(k), 0);
    if (e && *e && SvOK(*e)) return SvPV_const(*e, *len);
    *len = strlen(def);
    return def;
}

static HV *ps_stash(pTHX_ AV *av) {
    SV *st = pcx_get(aTHX_ av, PCX_STASH);
    if (!st) { st = newRV_noinc((SV *)newHV()); (void)av_store(av, PCX_STASH, st); }
    return (HV *)SvRV(st);
}

/* canonical JSON of an SV (+1) - stable across key order for the dirty check */
static SV *ps_encode(pTHX_ SV *data) {
    frj_opts o;
    Zero(&o, 1, frj_opts);
    o.canonical = 1;
    return punk_frj(aTHX)->encode(aTHX_ data, &o);
}

/* "7d" / "1h" / "30m" / "3600" -> seconds */
static IV ps_parse_duration(pTHX_ SV *v) {
    STRLEN l; const char *s;
    IV n = 0; STRLEN i = 0;
    if (SvIOK(v) || looks_like_number(v)) {
        /* a bare number with no unit is seconds unless a unit follows */
    }
    s = SvPV_const(v, l);
    while (i < l && s[i] >= '0' && s[i] <= '9') { n = n * 10 + (s[i] - '0'); i++; }
    if (i < l) {
        switch (s[i]) {
            case 's': break;
            case 'm': n *= 60; break;
            case 'h': n *= 3600; break;
            case 'd': n *= 86400; break;
            case 'w': n *= 604800; break;
            default: break;
        }
    }
    return n;
}

/* $c->session: load (once) from the signed cookie and cache the hashref (+1) */
static SV *ps_load(pTHX_ SV *c) {
    AV *av = pcx_av(aTHX_ c);
    HV *stash = ps_stash(aTHX_ av);
    SV **cached = hv_fetchs(stash, "punk.session", 0);
    HV *cfg, *sess = NULL;
    STRLEN nl, kl;
    const char *cookie_name, *key;
    SV *req, *cargv[1], *cval, *rv;
    if (cached && *cached && SvROK(*cached)) return newSVsv(*cached);
    cfg = ps_cfg(aTHX_ c);
    if (!cfg) croak("Punk: no session configured (add a `session` keyword)");
    cookie_name = ps_cfg_str(aTHX_ cfg, "cookie", "punk.sid", &nl);
    key = ps_cfg_str(aTHX_ cfg, "secret", "", &kl);
    req = pcx_force(aTHX_ av, PCX_REQ, "Punk::Request", pcx_get(aTHX_ av, PCX_ENV));
    cargv[0] = sv_2mortal(newSVpvn(cookie_name, nl));
    cval = pcx_call_meth(aTHX_ req, "cookie", cargv, 1, 1);
    if (cval) sv_2mortal(cval);
    if (cval && SvOK(cval) && SvCUR(cval)) {
        STRLEN cvl; const char *cv = SvPV_const(cval, cvl);
        SV *payload = pk_session_verify(aTHX_ cv, cvl, key, kl);
        if (payload) {
            SV *decoded;
            sv_2mortal(payload);
            decoded = punk_frj(aTHX)->decode(aTHX_ SvPVX(payload), SvCUR(payload), NULL);
            if (decoded) sv_2mortal(decoded);
            if (decoded && SvROK(decoded) && SvTYPE(SvRV(decoded)) == SVt_PVHV) {
                sess = newHVhv((HV *)SvRV(decoded));       /* a fresh copy */
                (void)hv_stores(stash, "punk.session.orig", ps_encode(aTHX_ decoded));
            }
        }
    }
    if (!sess) {
        sess = newHV();
        (void)hv_stores(stash, "punk.session.orig", newSVpvs(""));
    }
    rv = newRV_noinc((SV *)sess);
    (void)hv_stores(stash, "punk.session", rv);            /* the stash owns rv */
    return newRV_inc((SV *)sess);                          /* a second ref, +1 */
}

/* the after-dispatch write-back: add a Set-Cookie to the triplet when the
 * session changed, or a deletion cookie when it was expired */
static void ps_writeback(pTHX_ SV *c, SV *resp) {
    AV *av = pcx_av(aTHX_ c);
    HV *cfg = ps_cfg(aTHX_ c);
    SV *st = pcx_get(aTHX_ av, PCX_STASH);
    HV *stash;
    SV **sessp, **origp, **expp, **hp;
    AV *r, *headers;
    STRLEN nl;
    const char *cookie_name;
    SV *cname, *setcookie = NULL;
    if (!cfg || !st || !SvROK(st)) return;
    stash = (HV *)SvRV(st);
    sessp = hv_fetchs(stash, "punk.session", 0);
    if (!(sessp && *sessp && SvROK(*sessp))) return;       /* never accessed */
    if (!(SvROK(resp) && SvTYPE(SvRV(resp)) == SVt_PVAV)) return;
    r = (AV *)SvRV(resp);
    hp = av_fetch(r, 1, 0);
    if (!(hp && *hp && SvROK(*hp) && SvTYPE(SvRV(*hp)) == SVt_PVAV)) return;
    headers = (AV *)SvRV(*hp);
    cookie_name = ps_cfg_str(aTHX_ cfg, "cookie", "punk.sid", &nl);
    cname = sv_2mortal(newSVpvn(cookie_name, nl));
    expp = hv_fetchs(stash, "punk.session.expire", 0);
    if (expp && *expp && SvTRUE(*expp)) {
        setcookie = pk_build_cookie(aTHX_ cname, &PL_sv_undef, cfg);
    }
    else {
        SV *cur = sv_2mortal(ps_encode(aTHX_ *sessp));
        STRLEN kl; const char *key;
        SV *signed_val;
        origp = hv_fetchs(stash, "punk.session.orig", 0);
        if (origp && *origp && sv_eq(cur, *origp)) return; /* unchanged */
        if (SvCUR(cur) > 4000) {
            /* the write-back is a trapped after-hook, so croaking would vanish;
             * warn and drop the cookie rather than silently truncate it */
            warn("Punk: session is too large for a signed cookie (%d bytes); "
                 "not saved - a server-side store is needed", (int)SvCUR(cur));
            return;
        }
        key = ps_cfg_str(aTHX_ cfg, "secret", "", &kl);
        signed_val = sv_2mortal(pk_session_sign(aTHX_ cur, key, kl));
        setcookie = pk_build_cookie(aTHX_ cname, signed_val, cfg);
    }
    av_push(headers, newSVpvs("Set-Cookie"));
    av_push(headers, setcookie);                           /* +1, list takes it */
}

#endif /* PUNK_SESSION_H */
