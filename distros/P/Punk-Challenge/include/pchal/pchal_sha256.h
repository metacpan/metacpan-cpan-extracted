#ifndef PCHAL_SHA256_H
#define PCHAL_SHA256_H

/* SHA-256 (FIPS 180-4) and HMAC-SHA256 (RFC 2104), bundled.
 *
 * Bundled rather than borrowed because nothing else offers them to C: Punk
 * has its own for sessions but keeps it private, and the Perl-level
 * Digest::SHA would cost a Perl frame on every cleared request. The
 * streaming form is what HMAC needs to avoid copying the message into a
 * buffer beside its padded key; the one-shot form is for the puzzle hash.
 *
 * Needs nothing before it but the perl headers (U32, memcpy).
 */

#define PCHAL_ROR(x, n) (((x) >> (n)) | ((x) << (32 - (n))))

static const U32 pchal_sha256_k[64] = {
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

static const U32 pchal_sha256_iv[8] = {
    0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,
    0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19
};

typedef struct {
    U32 h[8];
    unsigned char buf[64];
    size_t buflen;      /* bytes waiting in buf, always < 64 */
    size_t total;       /* bytes seen so far */
} pchal_sha256_ctx;

/* The compression function over whole 64-byte blocks, folded into `h`. */
static void pchal_sha256_blocks(U32 h[8], const unsigned char *m, size_t nblocks)
{
    size_t b;
    int i;
    for (b = 0; b < nblocks; b++) {
        const unsigned char *p = m + b * 64;
        U32 w[64], a, bb, c, d, e, f, g, hh, t1, t2;
        for (i = 0; i < 16; i++)
            w[i] = ((U32)p[4*i] << 24) | ((U32)p[4*i+1] << 16)
                 | ((U32)p[4*i+2] << 8) | (U32)p[4*i+3];
        for (i = 16; i < 64; i++) {
            U32 s0 = PCHAL_ROR(w[i-15], 7) ^ PCHAL_ROR(w[i-15], 18) ^ (w[i-15] >> 3);
            U32 s1 = PCHAL_ROR(w[i-2], 17) ^ PCHAL_ROR(w[i-2], 19) ^ (w[i-2] >> 10);
            w[i] = w[i-16] + s0 + w[i-7] + s1;
        }
        a = h[0]; bb = h[1]; c = h[2]; d = h[3];
        e = h[4]; f = h[5]; g = h[6]; hh = h[7];
        for (i = 0; i < 64; i++) {
            U32 S1  = PCHAL_ROR(e, 6) ^ PCHAL_ROR(e, 11) ^ PCHAL_ROR(e, 25);
            U32 ch  = (e & f) ^ ((~e) & g);
            U32 S0  = PCHAL_ROR(a, 2) ^ PCHAL_ROR(a, 13) ^ PCHAL_ROR(a, 22);
            U32 maj = (a & bb) ^ (a & c) ^ (bb & c);
            t1 = hh + S1 + ch + pchal_sha256_k[i] + w[i];
            t2 = S0 + maj;
            hh = g; g = f; f = e; e = d + t1;
            d = c; c = bb; bb = a; a = t1 + t2;
        }
        h[0] += a; h[1] += bb; h[2] += c; h[3] += d;
        h[4] += e; h[5] += f; h[6] += g; h[7] += hh;
    }
}

static void pchal_sha256_init(pchal_sha256_ctx *ctx)
{
    memcpy(ctx->h, pchal_sha256_iv, sizeof ctx->h);
    ctx->buflen = 0;
    ctx->total = 0;
}

static void pchal_sha256_update(pchal_sha256_ctx *ctx, const unsigned char *p,
                                size_t n)
{
    ctx->total += n;
    if (ctx->buflen) {
        size_t room = 64 - ctx->buflen;
        size_t take = n < room ? n : room;
        memcpy(ctx->buf + ctx->buflen, p, take);
        ctx->buflen += take;
        p += take;
        n -= take;
        if (ctx->buflen < 64) return;
        pchal_sha256_blocks(ctx->h, ctx->buf, 1);
        ctx->buflen = 0;
    }
    if (n >= 64) {
        size_t whole = n / 64;
        pchal_sha256_blocks(ctx->h, p, whole);
        p += whole * 64;
        n -= whole * 64;
    }
    if (n) {
        memcpy(ctx->buf, p, n);
        ctx->buflen = n;
    }
}

/* The 0x80 terminator, the zero padding to 56 mod 64, and the 64-bit
 * bit-count big-endian: one block, or two when fewer than nine bytes of the
 * current one are free. */
static void pchal_sha256_final(pchal_sha256_ctx *ctx, unsigned char out[32])
{
    unsigned char tail[72];
    size_t total = ctx->total;
    size_t padlen = (ctx->buflen < 56) ? 56 - ctx->buflen : 120 - ctx->buflen;
    U32 hi = (U32)(total >> 29), lo = (U32)(total << 3);
    int i;

    memset(tail, 0, sizeof tail);
    tail[0] = 0x80;
    tail[padlen]     = (unsigned char)((hi >> 24) & 0xff);
    tail[padlen + 1] = (unsigned char)((hi >> 16) & 0xff);
    tail[padlen + 2] = (unsigned char)((hi >> 8) & 0xff);
    tail[padlen + 3] = (unsigned char)(hi & 0xff);
    tail[padlen + 4] = (unsigned char)((lo >> 24) & 0xff);
    tail[padlen + 5] = (unsigned char)((lo >> 16) & 0xff);
    tail[padlen + 6] = (unsigned char)((lo >> 8) & 0xff);
    tail[padlen + 7] = (unsigned char)(lo & 0xff);
    pchal_sha256_update(ctx, tail, padlen + 8);

    for (i = 0; i < 8; i++) {
        out[4*i]   = (unsigned char)((ctx->h[i] >> 24) & 0xff);
        out[4*i+1] = (unsigned char)((ctx->h[i] >> 16) & 0xff);
        out[4*i+2] = (unsigned char)((ctx->h[i] >> 8) & 0xff);
        out[4*i+3] = (unsigned char)(ctx->h[i] & 0xff);
    }
}

static void pchal_sha256(const unsigned char *msg, size_t len,
                         unsigned char out[32])
{
    pchal_sha256_ctx ctx;
    pchal_sha256_init(&ctx);
    pchal_sha256_update(&ctx, msg, len);
    pchal_sha256_final(&ctx, out);
}

/* HMAC over a message of any length with no allocation: the padded key is
 * fed to the streaming hash ahead of the message rather than concatenated
 * with it. A key longer than a block is hashed first, as the RFC says. */
static void pchal_hmac_sha256(const unsigned char *key, size_t klen,
                              const unsigned char *msg, size_t mlen,
                              unsigned char out[32])
{
    unsigned char k[64], pad[64], inner[32];
    pchal_sha256_ctx ctx;
    int i;

    memset(k, 0, sizeof k);
    if (klen > 64) pchal_sha256(key, klen, k);
    else if (klen) memcpy(k, key, klen);

    for (i = 0; i < 64; i++) pad[i] = k[i] ^ 0x36;
    pchal_sha256_init(&ctx);
    pchal_sha256_update(&ctx, pad, 64);
    if (mlen) pchal_sha256_update(&ctx, msg, mlen);
    pchal_sha256_final(&ctx, inner);

    for (i = 0; i < 64; i++) pad[i] = k[i] ^ 0x5c;
    pchal_sha256_init(&ctx);
    pchal_sha256_update(&ctx, pad, 64);
    pchal_sha256_update(&ctx, inner, 32);
    pchal_sha256_final(&ctx, out);
}

/* How many leading zero bits a digest has, which is what a solution is
 * judged on. Not constant time and does not need to be: the digest is over
 * a string the client chose and already holds. */
static int pchal_zero_bits(const unsigned char *d, size_t len)
{
    int n = 0;
    size_t i;
    for (i = 0; i < len; i++) {
        unsigned char b = d[i];
        if (b == 0) { n += 8; continue; }
        while (!(b & 0x80)) { b = (unsigned char)(b << 1); n++; }
        break;
    }
    return n;
}

#endif /* PCHAL_SHA256_H */
