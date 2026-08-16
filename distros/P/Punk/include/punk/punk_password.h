/* punk_password.h - password hashing, in C, over the dist's own crypto.
 *
 * PBKDF2-HMAC-SHA256 on the SHA-256 already bundled for sessions
 * (punk_session.h), salted from the entropy source the build probes
 * (pk_random_bytes, punk_csrf.h). No library dependency.
 *
 * The stored format is MaatSite::Password's, byte for byte, so rows hashed in
 * production verify unchanged:
 *
 *     pbkdf2-sha256$<iterations>$<salt base64>$<key base64>
 *
 * Standard padded base64 (that is what MIME::Base64 wrote), 16-byte salt,
 * 32-byte key. verify() takes the iteration count from the stored string, so
 * cost upgrades need no flag day: needs_rehash() says when, and the caller
 * re-hashes on login with the plaintext in hand.
 *
 * Include after punk_session.h (pk_sha256 / pk_hmac_sha256 / pk_b64url) and
 * punk_csrf.h (pk_random_bytes).
 */

#ifndef PUNK_PASSWORD_H
#define PUNK_PASSWORD_H

#define PWD_SCHEME     "pbkdf2-sha256"
#define PWD_SCHEME_LEN (sizeof(PWD_SCHEME) - 1)
#define PWD_SALT_LEN   16
#define PWD_KEY_LEN    32
#define PWD_DEFAULT_ITERATIONS 60000

/* ---- standard base64 (padded - the MIME::Base64 wire form) ---------------- */

static const char pwd_b64_alpha[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

static SV *pwd_b64(pTHX_ const unsigned char *in, size_t len) {
    SV *out = newSVpvs("");
    size_t i;
    for (i = 0; i + 2 < len; i += 3) {
        U32 v = ((U32)in[i] << 16) | ((U32)in[i+1] << 8) | in[i+2];
        char c[4] = { pwd_b64_alpha[(v >> 18) & 63], pwd_b64_alpha[(v >> 12) & 63],
                      pwd_b64_alpha[(v >> 6) & 63],  pwd_b64_alpha[v & 63] };
        sv_catpvn(out, c, 4);
    }
    if (len - i == 1) {
        U32 v = (U32)in[i] << 16;
        char c[4] = { pwd_b64_alpha[(v >> 18) & 63], pwd_b64_alpha[(v >> 12) & 63],
                      '=', '=' };
        sv_catpvn(out, c, 4);
    }
    else if (len - i == 2) {
        U32 v = ((U32)in[i] << 16) | ((U32)in[i+1] << 8);
        char c[4] = { pwd_b64_alpha[(v >> 18) & 63], pwd_b64_alpha[(v >> 12) & 63],
                      pwd_b64_alpha[(v >> 6) & 63],  '=' };
        sv_catpvn(out, c, 4);
    }
    return out;
}

static int pwd_b64_val(unsigned char c) {
    if (c >= 'A' && c <= 'Z') return c - 'A';
    if (c >= 'a' && c <= 'z') return c - 'a' + 26;
    if (c >= '0' && c <= '9') return c - '0' + 52;
    if (c == '+') return 62;
    if (c == '/') return 63;
    return -1;
}

/* Decode into out (caps outmax); returns the byte count or -1 on any
 * malformation. Padding optional - both padded and stripped forms decode. */
static SSize_t pwd_b64_decode(const char *in, size_t len,
                              unsigned char *out, size_t outmax) {
    U32 acc = 0;
    int bits = 0;
    size_t i, n = 0;
    while (len && in[len - 1] == '=') len--;
    for (i = 0; i < len; i++) {
        int v = pwd_b64_val((unsigned char)in[i]);
        if (v < 0) return -1;
        acc = (acc << 6) | (U32)v;
        bits += 6;
        if (bits >= 8) {
            bits -= 8;
            if (n >= outmax) return -1;
            out[n++] = (unsigned char)((acc >> bits) & 0xff);
        }
    }
    return (SSize_t)n;
}

/* ---- PBKDF2-HMAC-SHA256 --------------------------------------------------- */

/* The full block loop, although 32-byte keys make it a single block today -
 * the day the key length changes must not be the day the loop appears. */
static void pwd_pbkdf2(const unsigned char *pass, size_t plen,
                       const unsigned char *salt, size_t slen,
                       U32 iterations, unsigned char *key, size_t keylen) {
    /* 64 matches the parse buffers below - a stored salt can never be
     * longer, and the default is PWD_SALT_LEN */
    unsigned char block[64 + 4];
    unsigned char u[32], t[32];
    size_t off = 0;
    U32 b = 1;
    if (slen > 64) { memset(key, 0, keylen); return; }   /* unreachable via
                                                            parse; fail closed */
    while (off < keylen) {
        size_t take = keylen - off < 32 ? keylen - off : 32;
        U32 i;
        memcpy(block, salt, slen);
        block[slen]     = (unsigned char)((b >> 24) & 0xff);
        block[slen + 1] = (unsigned char)((b >> 16) & 0xff);
        block[slen + 2] = (unsigned char)((b >> 8) & 0xff);
        block[slen + 3] = (unsigned char)(b & 0xff);
        pk_hmac_sha256(pass, plen, block, slen + 4, u);
        memcpy(t, u, 32);
        for (i = 1; i < iterations; i++) {
            unsigned char u2[32];
            int j;
            pk_hmac_sha256(pass, plen, u, 32, u2);
            memcpy(u, u2, 32);
            for (j = 0; j < 32; j++) t[j] ^= u[j];
        }
        memcpy(key + off, t, take);
        off += take;
        b++;
    }
}

/* ---- the stored string ---------------------------------------------------- */

static SV *pwd_hash(pTHX_ const unsigned char *pass, STRLEN plen,
                    U32 iterations) {
    unsigned char salt[PWD_SALT_LEN], key[PWD_KEY_LEN];
    SV *out, *b64;
    if (!iterations) iterations = PWD_DEFAULT_ITERATIONS;
    pk_random_bytes(aTHX_ salt, sizeof salt);
    pwd_pbkdf2(pass, plen, salt, sizeof salt, iterations, key, sizeof key);
    out = newSVpvf(PWD_SCHEME "$%u$", (unsigned)iterations);
    b64 = pwd_b64(aTHX_ salt, sizeof salt);
    sv_catsv(out, b64); SvREFCNT_dec(b64);
    sv_catpvs(out, "$");
    b64 = pwd_b64(aTHX_ key, sizeof key);
    sv_catsv(out, b64); SvREFCNT_dec(b64);
    return out;
}

/* Parse a stored string into its parts. Returns 1 and fills the outputs, or
 * 0 for anything that does not parse - which verify treats as a mismatch and
 * needs_rehash treats as "rehash". */
static int pwd_parse(const char *s, STRLEN len, U32 *iterations,
                     unsigned char *salt, size_t saltmax, size_t *saltlen,
                     unsigned char *key, size_t keymax, size_t *keylen) {
    const char *end = s + len, *p, *q;
    U32 it = 0;
    SSize_t n;
    if (len <= PWD_SCHEME_LEN + 1) return 0;
    if (memcmp(s, PWD_SCHEME "$", PWD_SCHEME_LEN + 1) != 0) return 0;
    p = s + PWD_SCHEME_LEN + 1;
    q = p;
    while (q < end && *q >= '0' && *q <= '9') {
        U32 nit = it * 10 + (U32)(*q - '0');
        if (nit < it) return 0;                       /* overflow */
        it = nit; q++;
    }
    if (q == p || !it || q >= end || *q != '$') return 0;
    p = q + 1;
    q = (const char *)memchr(p, '$', (size_t)(end - p));
    if (!q || q == p || q + 1 >= end) return 0;
    n = pwd_b64_decode(p, (size_t)(q - p), salt, saltmax);
    if (n <= 0) return 0;
    *saltlen = (size_t)n;
    n = pwd_b64_decode(q + 1, (size_t)(end - q - 1), key, keymax);
    if (n <= 0) return 0;
    *keylen = (size_t)n;
    *iterations = it;
    return 1;
}

/* Constant-time over the derived key; the length check leaks only the length,
 * which the format fixes anyway. */
static int pwd_verify(pTHX_ const unsigned char *pass, STRLEN plen,
                      const char *stored, STRLEN slen) {
    unsigned char salt[64], want[64], got[64];
    size_t saltlen, keylen, i;
    U32 iterations;
    unsigned char diff = 0;
    if (!pwd_parse(stored, slen, &iterations,
                   salt, sizeof salt, &saltlen,
                   want, sizeof want, &keylen))
        return 0;
    pwd_pbkdf2(pass, plen, salt, saltlen, iterations, got, keylen);
    for (i = 0; i < keylen; i++) diff |= (unsigned char)(want[i] ^ got[i]);
    return diff == 0;
}

/* Burn the same work as a real verify without a stored hash to compare - the
 * unknown-email path of a login must cost what the wrong-password path costs,
 * or response time says which emails exist. */
static void pwd_dummy_verify(pTHX_ const unsigned char *pass, STRLEN plen,
                             U32 iterations) {
    static const unsigned char salt[PWD_SALT_LEN] = "punk.dummy.salt!";
    unsigned char key[PWD_KEY_LEN];
    if (!iterations) iterations = PWD_DEFAULT_ITERATIONS;
    pwd_pbkdf2(pass, plen, salt, sizeof salt, iterations, key, sizeof key);
}

static int pwd_needs_rehash(pTHX_ const char *stored, STRLEN slen,
                            U32 current) {
    unsigned char salt[64], key[64];
    size_t saltlen, keylen;
    U32 iterations;
    if (!current) current = PWD_DEFAULT_ITERATIONS;
    if (!pwd_parse(stored, slen, &iterations,
                   salt, sizeof salt, &saltlen,
                   key, sizeof key, &keylen))
        return 1;                                     /* fail toward rehash */
    return iterations < current;
}

/* ---- single-use token material -------------------------------------------- */

/* 32 random bytes, base64url unpadded - 43 characters, cookie- and URL-safe. */
static SV *pwd_token(pTHX) {
    unsigned char raw[32];
    pk_random_bytes(aTHX_ raw, sizeof raw);
    return pk_b64url(aTHX_ raw, sizeof raw);
}

/* Lowercase sha256 hex of the token - the only form storage ever sees. */
static SV *pwd_token_digest(pTHX_ const unsigned char *tok, STRLEN len) {
    static const char hex[] = "0123456789abcdef";
    unsigned char d[32];
    char out[64];
    int i;
    pk_sha256(tok, len, d);
    for (i = 0; i < 32; i++) {
        out[i * 2]     = hex[d[i] >> 4];
        out[i * 2 + 1] = hex[d[i] & 15];
    }
    return newSVpvn(out, 64);
}

#endif /* PUNK_PASSWORD_H */
