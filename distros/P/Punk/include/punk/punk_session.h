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

/* The compression function over whole 64-byte blocks, folded into `h`. Split
 * out so a caller that cannot hold its message in memory (punk_asset.h hashes
 * a file in chunks) shares this loop rather than keeping a second copy of it
 * in step. */
static void ps_sha256_blocks(U32 h[8], const unsigned char *m, size_t nblocks) {
    size_t b;
    int i;
    for (b = 0; b < nblocks; b++) {
        const unsigned char *p = m + b * 64;
        U32 w[64], a, c0, c, d, e, f, g, hh, t1, t2;
        for (i = 0; i < 16; i++)
            w[i] = ((U32)p[4*i]<<24)|((U32)p[4*i+1]<<16)
                 | ((U32)p[4*i+2]<<8)|(U32)p[4*i+3];
        for (i = 16; i < 64; i++) {
            U32 s0 = PS_ROR(w[i-15],7) ^ PS_ROR(w[i-15],18) ^ (w[i-15]>>3);
            U32 s1 = PS_ROR(w[i-2],17) ^ PS_ROR(w[i-2],19) ^ (w[i-2]>>10);
            w[i] = w[i-16] + s0 + w[i-7] + s1;
        }
        a=h[0];c0=h[1];c=h[2];d=h[3];e=h[4];f=h[5];g=h[6];hh=h[7];
        for (i = 0; i < 64; i++) {
            U32 S1 = PS_ROR(e,6)^PS_ROR(e,11)^PS_ROR(e,25);
            U32 ch = (e & f) ^ ((~e) & g);
            U32 S0 = PS_ROR(a,2)^PS_ROR(a,13)^PS_ROR(a,22);
            U32 maj = (a & c0) ^ (a & c) ^ (c0 & c);
            t1 = hh + S1 + ch + ps_sha256_k[i] + w[i];
            t2 = S0 + maj;
            hh=g; g=f; f=e; e=d+t1; d=c; c=c0; c0=a; a=t1+t2;
        }
        h[0]+=a;h[1]+=c0;h[2]+=c;h[3]+=d;h[4]+=e;h[5]+=f;h[6]+=g;h[7]+=hh;
    }
}

static const U32 ps_sha256_iv[8] = { 0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,
                                     0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19 };

/* The final block(s): the 0x80 terminator, the zero padding and the 64-bit
 * bit-count, folded in. `rem` is what is left of the message after the whole
 * blocks, `total` its full byte length. */
static void ps_sha256_final(U32 h[8], const unsigned char *rest, size_t rem,
                            size_t total, unsigned char out[32]) {
    unsigned char tail[128];
    size_t tlen = (rem < 56) ? 64 : 128;
    U32 hi = (U32)(total >> 29), lo = (U32)(total << 3);
    int i;
    memset(tail, 0, sizeof tail);
    if (rem) memcpy(tail, rest, rem);
    tail[rem] = 0x80;
    tail[tlen-1]=(unsigned char)(lo&0xff); tail[tlen-2]=(unsigned char)((lo>>8)&0xff);
    tail[tlen-3]=(unsigned char)((lo>>16)&0xff); tail[tlen-4]=(unsigned char)((lo>>24)&0xff);
    tail[tlen-5]=(unsigned char)(hi&0xff); tail[tlen-6]=(unsigned char)((hi>>8)&0xff);
    tail[tlen-7]=(unsigned char)((hi>>16)&0xff); tail[tlen-8]=(unsigned char)((hi>>24)&0xff);
    ps_sha256_blocks(h, tail, tlen / 64);
    for (i = 0; i < 8; i++) {
        out[4*i]  =(unsigned char)((h[i]>>24)&0xff);
        out[4*i+1]=(unsigned char)((h[i]>>16)&0xff);
        out[4*i+2]=(unsigned char)((h[i]>>8)&0xff);
        out[4*i+3]=(unsigned char)(h[i]&0xff);
    }
}

static void pk_sha256(const unsigned char *msg, size_t len, unsigned char out[32]) {
    U32 h[8];
    size_t whole = len / 64;
    memcpy(h, ps_sha256_iv, sizeof h);
    if (whole) ps_sha256_blocks(h, msg, whole);
    ps_sha256_final(h, msg + whole * 64, len - whole * 64, len, out);
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

static IV ps_cfg_iv(pTHX_ HV *cfg, const char *k, IV def) {
    SV **e = hv_fetch(cfg, k, (I32)strlen(k), 0);
    return (e && *e && SvOK(*e)) ? SvIV(*e) : def;
}

/* The absolute expiry stamped into the signed payload, under a reserved key
 * the application never sees (the same trick flash plays with punk.flash).
 *
 * Without it `expires` was only the browser's Max-Age: a hint to a client
 * that is free to ignore it. The signature carries no time, so a cookie
 * captured once stayed valid for as long as the secret did, and session_expire
 * only asked the browser to forget a value that still authenticated. Stamping
 * the expiry inside the signature is what makes the lifetime the server's to
 * decide.
 *
 * A session cookie with no `expires` is still bounded here, because "until the
 * browser closes" is the client's promise and not a limit on the value. */
#define PK_SESSION_EXP     "punk.exp"
#define PK_SESSION_EXP_LEN 8
#define PK_SESSION_MAX_LIFETIME (30 * 86400)

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

/* The options `session` understands.
 *
 * It used to copy every pair it was given straight into the config, so a typo
 * was silent: `htponly => 1` looked configured and was not. That was survivable
 * while every option was a cookie attribute with a safe default. It stopped
 * being survivable with `store`, where the typo's failure is "everything works
 * and the store stays empty" - a cookie session, at the 4KB ceiling, wearing
 * the configuration of a server-side one.
 *
 * `max_age` is here as well as `expires` because it is what the frozen config
 * actually holds: reading one back and passing it in again should not croak. */
static const char *const PS_KEYS[] = {
    "secret", "cookie", "expires", "max_age", "path", "domain", "secure",
    "httponly", "samesite", "store", "allow_unshared", "sliding", "tier", NULL
};

/* `cfg` is the half-built config to release first: this croak is catchable
 * (a test, an eval around to_app), so leaking it on the way out would be a
 * leak per attempt rather than one on a process that is about to die. */
static void ps_check_key(pTHX_ const char *k, STRLEN kl, HV *cfg) {
    int i;
    for (i = 0; PS_KEYS[i]; i++)
        if (strlen(PS_KEYS[i]) == kl && memEQ(k, PS_KEYS[i], kl)) return;
    if (cfg) SvREFCNT_dec((SV *)cfg);
    croak("Punk: `session` does not understand `%.*s`. It takes secret, "
          "cookie, expires, path, domain, secure, httponly, samesite, store, "
          "sliding, tier and allow_unshared", (int)kl, k);
}

/* ---- the server-side store, when there is one ------------------------------ *
 *
 * `session store => ...` moves the payload off the client: the cookie carries a
 * signed id and the session itself lives in a Punk::Cache. The seam is narrow
 * on purpose - three method calls, get / set / delete - so any backend that
 * satisfies that contract can hold a session, including one from outside this
 * distribution.
 *
 * The id helpers are declared and not defined here. They need punk_entropy.h,
 * which needs punk_csrf.h, which needs this file, so they live in
 * punk_sessionstore.h and are reached from here by declaration. The compiler
 * still checks the signatures; the ordering is the only thing being worked
 * around. */
static SV *ps_new_id(pTHX);
static SV *ps_id_seal(pTHX_ SV *id, const char *key, STRLEN kl, IV ttl);
static SV *ps_id_unseal(pTHX_ const char *cv, STRLEN cvl,
                        const char *key, STRLEN kl);
/* the one read that has to know about the memory tier - see punk_sessionstore.h
 * for why a session goes round it unless asked not to */
static SV *ps_store_get(pTHX_ SV *store, SV *key, int use_tier);

/* The id this request arrived with, kept beside the session it named so the
 * write-back knows whether the client already has it. */
#define PK_SESSION_SID     "punk.session.id"
#define PK_SESSION_SID_LEN 15

/* Set by session_rotate: the id to retire once the new one is written. */
#define PK_SESSION_ROT     "punk.session.rotate"
#define PK_SESSION_ROT_LEN 19

/* When the entry was last written, stamped inside the stored payload under a
 * reserved key the application never sees - the same trick the cookie plays
 * with punk.exp, and flash with punk.flash.
 *
 * It exists for the sliding expiry, which has to answer "how much of this
 * session's life is left" and cannot ask the store: `get` returns bytes, and
 * a contract that also reported an entry's expiry would be a sixth thing for
 * every backend to implement. One integer in the payload answers it for all
 * of them. */
#define PK_SESSION_AT      "punk.at"
#define PK_SESSION_AT_LEN  7
#define PK_SESSION_AT_STASH     "punk.session.at"
#define PK_SESSION_AT_STASH_LEN 15

/* What a stored session may weigh.
 *
 * The cookie's ~4KB ceiling was the wire format's, and it goes: a basket in a
 * session stops being a croak. Unbounded is not what replaces it, because a
 * session an application can grow without limit is a way to fill somebody's
 * store from a login form. A megabyte is far past any legitimate session and
 * far below anything that threatens a store. */
#define PK_SESSION_STORE_MAX (1024 * 1024)

/* the store the resolution put on the config at to_app, or NULL for a cookie
 * session - which is every application that did not ask for one */
static SV *ps_cfg_store(pTHX_ HV *cfg) {
    SV **s = hv_fetchs(cfg, "punk.store", 0);
    return (s && *s && SvROK(*s)) ? *s : NULL;
}

/* The id this request arrived with (+1), unsealed from the cookie, or NULL.
 *
 * Separate from ps_load because a logout may never have read the session:
 * `post '/logout' => sub { $_[0]->session_expire }` touches nothing, and the
 * entry still has to be deleted. Revocation that depends on the handler
 * having looked at the session first would be revocation that usually does
 * not happen. */
static SV *ps_req_id(pTHX_ SV *c, HV *cfg) {
    AV *av = pcx_av(aTHX_ c);
    STRLEN nl, kl, cvl;
    const char *cookie_name = ps_cfg_str(aTHX_ cfg, "cookie", "punk.sid", &nl);
    const char *key = ps_cfg_str(aTHX_ cfg, "secret", "", &kl);
    SV *req, *cargv[1], *cval;
    req = pcx_force(aTHX_ av, PCX_REQ, "Punk::Request", pcx_get(aTHX_ av, PCX_ENV));
    cargv[0] = sv_2mortal(newSVpvn(cookie_name, nl));
    cval = pcx_call_meth(aTHX_ req, "cookie", cargv, 1, 1);
    if (!cval) return NULL;
    sv_2mortal(cval);
    if (!(SvOK(cval) && SvCUR(cval))) return NULL;
    /* The SvPV goes in its OWN statement, and the length is read after it.
     *
     * `ps_id_unseal(aTHX_ SvPV_const(cval, cvl), cvl, ...)` is the same bug as
     * a multi-eval Sv macro around POPs: the macro assigns cvl and the sibling
     * argument reads it, and C does not say which happens first. clang went
     * left to right and worked; gcc goes right to left, read cvl before it was
     * ever assigned, and handed a garbage length to the verifier - which
     * walked off the buffer. It crashed on every request carrying a cookie,
     * on every non-threaded smoker, and on nothing here. */
    {
        const char *cv = SvPV_const(cval, cvl);
        return ps_id_unseal(aTHX_ cv, cvl, key, kl);
    }
}

/* $c->session: load (once) from the signed cookie and cache the hashref (+1) */
static SV *ps_load(pTHX_ SV *c) {
    AV *av = pcx_av(aTHX_ c);
    HV *stash = ps_stash(aTHX_ av);
    SV **cached = hv_fetchs(stash, "punk.session", 0);
    HV *cfg, *sess = NULL;
    STRLEN nl, kl;
    const char *cookie_name, *key;
    SV *req, *cargv[1], *cval, *rv, *store;
    if (cached && *cached && SvROK(*cached)) return newSVsv(*cached);
    cfg = ps_cfg(aTHX_ c);
    if (!cfg) croak("Punk: no session configured (add a `session` keyword)");
    cookie_name = ps_cfg_str(aTHX_ cfg, "cookie", "punk.sid", &nl);
    key = ps_cfg_str(aTHX_ cfg, "secret", "", &kl);
    req = pcx_force(aTHX_ av, PCX_REQ, "Punk::Request", pcx_get(aTHX_ av, PCX_ENV));
    cargv[0] = sv_2mortal(newSVpvn(cookie_name, nl));
    cval = pcx_call_meth(aTHX_ req, "cookie", cargv, 1, 1);
    if (cval) sv_2mortal(cval);
    store = ps_cfg_store(aTHX_ cfg);
    if (store) {
        /* THE STORE ROUND TRIP HAPPENS HERE, and only here - which is why
         * $c->session is loaded on demand rather than per request. A route
         * that never asks for the session never pays for it: a static asset,
         * a health check, an API route on a bearer token. The consequence to
         * remember is the other way round - a request that never touches the
         * session does not extend it either. */
        /* A forged, tampered or expired cookie yields no id, and no id means
         * no lookup: a guess never reaches the backend. */
        SV *id = ps_req_id(aTHX_ c, cfg);
        if (id) {
            SV *raw;
            sv_2mortal(id);
            raw = ps_store_get(aTHX_ store, id,
                               ps_cfg_iv(aTHX_ cfg, "tier", 0) ? 1 : 0);
            if (raw) sv_2mortal(raw);
            if (raw && SvOK(raw)) {
                STRLEN rl;
                const char *rb = SvPV_const(raw, rl);
                SV *decoded = punk_frj(aTHX)->decode(aTHX_ rb, rl, NULL);
                if (decoded) sv_2mortal(decoded);
                if (decoded && SvROK(decoded)
                    && SvTYPE(SvRV(decoded)) == SVt_PVHV) {
                    SV **atp;
                    SV *rvs;
                    sess = newHVhv((HV *)SvRV(decoded));
                    /* the write stamp is ours, not the application's: it is
                     * lifted into the stash and stripped before anything sees
                     * the hash, so the dirty check compares like with like */
                    atp = hv_fetch(sess, PK_SESSION_AT, PK_SESSION_AT_LEN, 0);
                    if (atp && *atp && SvOK(*atp))
                        (void)hv_store(stash, PK_SESSION_AT_STASH,
                                       PK_SESSION_AT_STASH_LEN,
                                       newSVsv(*atp), 0);
                    (void)hv_delete(sess, PK_SESSION_AT, PK_SESSION_AT_LEN,
                                    G_DISCARD);
                    rvs = sv_2mortal(newRV_inc((SV *)sess));
                    (void)hv_stores(stash, "punk.session.orig",
                                    ps_encode(aTHX_ rvs));
                    (void)hv_store(stash, PK_SESSION_SID, PK_SESSION_SID_LEN,
                                   newSVsv(id), 0);
                }
            }
            /* An id whose entry has gone - expired, evicted, or deleted by a
             * logout - is NOT carried forward. The session starts empty and
             * the write-back mints a fresh id, so a revoked id can never come
             * back to life as the name of a new session. */
        }
    }
    else if (cval && SvOK(cval) && SvCUR(cval)) {
        STRLEN cvl; const char *cv = SvPV_const(cval, cvl);
        SV *payload = pk_session_verify(aTHX_ cv, cvl, key, kl);
        if (payload) {
            SV *decoded;
            sv_2mortal(payload);
            decoded = punk_frj(aTHX)->decode(aTHX_ SvPVX(payload), SvCUR(payload), NULL);
            if (decoded) sv_2mortal(decoded);
            if (decoded && SvROK(decoded) && SvTYPE(SvRV(decoded)) == SVt_PVHV) {
                HV *dh = (HV *)SvRV(decoded);
                SV **ep = hv_fetch(dh, PK_SESSION_EXP, PK_SESSION_EXP_LEN, 0);
                /* A payload past its stamped expiry is not a session. It is
                 * left to fall through to the empty one below, so an expired
                 * cookie logs the user out rather than half-loading. */
                if (!ep || !*ep || !SvOK(*ep) || SvIV(*ep) > (IV)time(NULL)) {
                    SV *rvs;
                    sess = newHVhv(dh);                    /* a fresh copy */
                    /* the expiry is ours, not the application's: strip it
                     * before anything sees the hash, and take the dirty-check
                     * baseline from the stripped copy so it compares like
                     * with like against what the write-back encodes */
                    (void)hv_delete(sess, PK_SESSION_EXP, PK_SESSION_EXP_LEN,
                                    G_DISCARD);
                    rvs = sv_2mortal(newRV_inc((SV *)sess));
                    (void)hv_stores(stash, "punk.session.orig",
                                    ps_encode(aTHX_ rvs));
                }
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

/* The store half of the write-back: put the session where it lives, and hand
 * back a Set-Cookie (+1) only when the client has something new to be told -
 * which is on creation, and otherwise never.
 *
 * That asymmetry is the point. On a cookie session every write is a
 * Set-Cookie, because the cookie IS the session. Here an ordinary write
 * touches the store and leaves the response headers alone: the id in the
 * client's cookie still names the same session, whatever the session now
 * contains. */
static SV *ps_store_writeback(pTHX_ HV *cfg, HV *stash, SV *store,
                              SV *sess, SV *cname) {
    SV **origp = hv_fetchs(stash, "punk.session.orig", 0);
    SV **idp   = hv_fetch(stash, PK_SESSION_SID, PK_SESSION_SID_LEN, 0);
    SV **rotp  = hv_fetch(stash, PK_SESSION_ROT, PK_SESSION_ROT_LEN, 0);
    SV *cur    = sv_2mortal(ps_encode(aTHX_ sess));
    IV  ttl    = ps_cfg_iv(aTHX_ cfg, "max_age", 0);
    IV  now    = (IV)time(NULL);
    STRLEN kl;
    const char *key;
    SV *id, *argv[3], *ok;
    int fresh, rotating = (rotp && *rotp) ? 1 : 0, sliding = 0;

    if (ttl <= 0) ttl = PK_SESSION_MAX_LIFETIME;

    /* Unchanged is the common case, and change detection stops being an
     * optimisation here: it is what keeps a read-mostly application off the
     * store's write path entirely.
     *
     * Two things override it. A rotation has to write even when the session
     * is identical, because the point is that it now lives under a different
     * name. And a sliding expiry has to write to move the expiry - but only
     * once the session is far enough through its life to need it, or sliding
     * would be a store write on every request, which is the cost the read
     * path was designed to avoid. */
    if (origp && *origp && sv_eq(cur, *origp) && !rotating) {
        SV **atp;
        if (!ps_cfg_iv(aTHX_ cfg, "sliding", 0)) return NULL;
        atp = hv_fetch(stash, PK_SESSION_AT_STASH, PK_SESSION_AT_STASH_LEN, 0);
        if (!(atp && *atp && SvOK(*atp)))            return NULL;
        if (now - SvIV(*atp) <= ttl / 2)             return NULL;
        sliding = 1;
    }

    key = ps_cfg_str(aTHX_ cfg, "secret", "", &kl);
    if (!kl) {
        /* checked before the store is touched, not after: a session written
         * under an id that can never be sealed into a cookie is an orphan */
        warn("Punk: session has no secret; not saved - the id would ride in "
             "a cookie signed with an empty key, which anyone can forge");
        return NULL;
    }

    if (SvCUR(cur) > PK_SESSION_STORE_MAX) {
        /* the write-back is a trapped after-hook, so croaking would vanish */
        warn("Punk: session is %d bytes, over the %d-byte limit; not saved - "
             "a session is a name for what a user is doing, not a place to "
             "keep what they are doing it to",
             (int)SvCUR(cur), (int)PK_SESSION_STORE_MAX);
        return NULL;
    }

    /* A rotation always gets a new name; otherwise the one the request
     * arrived with, if it had one.
     *
     * A COPY of that one, not the stash's SV. Storing the id back into the
     * stash below frees whatever was under the key, so holding the stash's
     * own SV here left `id` dangling and the seal below reading freed memory.
     * It surfaced as a missing Set-Cookie rather than a crash, because this
     * runs on a trapped after-hook: the croak vanished with the response
     * going out perfectly formed and one header short. */
    fresh = rotating || !(idp && *idp && SvOK(*idp));
    id    = sv_2mortal(fresh ? ps_new_id(aTHX) : newSVsv(*idp));

    /* What goes into the store is the session plus the write stamp - never
     * the hash the application holds, which keeps its own contents and keeps
     * the dirty check comparing stripped serializations. */
    {
        HV *payload = newHVhv((HV *)SvRV(sess));
        SV *prv;
        (void)hv_store(payload, PK_SESSION_AT, PK_SESSION_AT_LEN,
                       newSViv(now), 0);
        prv = sv_2mortal(newRV_noinc((SV *)payload));
        argv[1] = sv_2mortal(ps_encode(aTHX_ prv));
    }
    argv[0] = id;
    argv[2] = sv_2mortal(newSViv(ttl));
    ok = pcx_call_meth(aTHX_ store, "set", argv, 3, 1);
    if (ok) sv_2mortal(ok);
    if (!(ok && SvTRUE(ok))) {
        /* A store may refuse: the file store refuses a value too large for its
         * budget rather than evicting everything else to fit, and a backend
         * from outside this distribution may refuse for reasons of its own.
         * Say so. A refusal that returns quietly is a login that appeared to
         * work and a user who is not logged in. */
        warn("Punk: the session store refused the write; the session was NOT "
             "saved - check the store's budget and its `refused` count");
        return NULL;
    }

    /* The old entry goes AFTER the new one is safely written, and the order
     * matters in one direction only. A failed delete leaves an id naming the
     * session as it was BEFORE this request - which in the attack this
     * defends against is the attacker's own empty session, and which expires
     * on its own TTL. A failed write after a delete would be a user logged
     * out at the moment they logged in. */
    if (rotating && SvOK(*rotp)) {
        SV *old = *rotp;
        SV *d = pcx_call_meth(aTHX_ store, "delete", &old, 1, 1);
        if (d) SvREFCNT_dec(d);
    }
    (void)hv_delete(stash, PK_SESSION_ROT, PK_SESSION_ROT_LEN, G_DISCARD);
    (void)hv_store(stash, PK_SESSION_SID, PK_SESSION_SID_LEN, newSVsv(id), 0);

    /* Nothing to tell the client unless the id changed - or the expiry did,
     * because a cookie that runs out while its entry lives is a logout the
     * sliding expiry exists to prevent. */
    if (!fresh && !sliding) return NULL;
    return pk_build_cookie(aTHX_ cname,
                           sv_2mortal(ps_id_seal(aTHX_ id, key, kl, ttl)), cfg);
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
    SV *cname, *store, *setcookie = NULL;
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
    store = ps_cfg_store(aTHX_ cfg);
    if (expp && *expp && SvTRUE(*expp)) {
        /* Logging out of a stored session is a DELETE, and that is the whole
         * difference. A signed cookie is good until it expires no matter what
         * the server thinks, so session_expire could only ever ask the browser
         * in front of it to forget - never reach a copy somebody had already
         * taken. With an entry to remove, the stolen cookie is dead on its
         * next request.
         *
         * The id comes from the cookie rather than the stash, because a
         * logout route usually never touched $c->session at all. */
        if (store) {
            SV *id = ps_req_id(aTHX_ c, cfg);
            if (id) {
                SV *d;
                sv_2mortal(id);
                d = pcx_call_meth(aTHX_ store, "delete", &id, 1, 1);
                if (d) SvREFCNT_dec(d);
            }
        }
        setcookie = pk_build_cookie(aTHX_ cname, &PL_sv_undef, cfg);
    }
    else if (store) {
        setcookie = ps_store_writeback(aTHX_ cfg, stash, store, *sessp, cname);
        if (!setcookie) return;           /* stored, or refused, or unchanged */
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
        /* Sign an expiry-stamped copy, not the hash itself: the application
         * keeps the session it was handed, and the dirty check above stays on
         * the stripped serialization, so a request that changed nothing still
         * writes no cookie. The stamp refreshes every time the session is
         * written, which is what makes `expires` a lifetime rather than a
         * countdown from first login. */
        {
            HV *payload = newHVhv((HV *)SvRV(*sessp));
            IV ttl = ps_cfg_iv(aTHX_ cfg, "max_age", 0);
            SV *prv;
            if (ttl <= 0) ttl = PK_SESSION_MAX_LIFETIME;
            (void)hv_store(payload, PK_SESSION_EXP, PK_SESSION_EXP_LEN,
                           newSViv((IV)time(NULL) + ttl), 0);
            prv = sv_2mortal(newRV_noinc((SV *)payload));
            cur = sv_2mortal(ps_encode(aTHX_ prv));
        }
        key = ps_cfg_str(aTHX_ cfg, "secret", "", &kl);
        if (!kl) {
            /* the `session` keyword refuses an empty secret at boot, so this
             * is only reachable by writing the config by hand. Signing with a
             * zero-length key is a forgeable cookie, so drop it here too -
             * same shape as the oversize case, since croaking in a trapped
             * after-hook would vanish */
            warn("Punk: session has no secret; not saved - a cookie signed "
                 "with an empty key can be forged by anyone");
            return;
        }
        signed_val = sv_2mortal(pk_session_sign(aTHX_ cur, key, kl));
        setcookie = pk_build_cookie(aTHX_ cname, signed_val, cfg);
    }
    av_push(headers, newSVpvs("Set-Cookie"));
    av_push(headers, setcookie);                           /* +1, list takes it */
}

#endif /* PUNK_SESSION_H */
