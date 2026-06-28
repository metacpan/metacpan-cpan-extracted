/*
 * pdfmake_sha2.c — SHA-256, SHA-384, SHA-512 implementations
 *
 * Reference implementation per FIPS 180-4.
 * Required for PDF encryption R6 key derivation.
 */

#include "pdfmake_sha2.h"
#include "pdfmake_internal.h"
#include <string.h>

/*============================================================================
 * SHA-256 constants
 *==========================================================================*/

static const uint32_t SHA256_K[64] = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

static const uint32_t SHA256_H0[8] = {
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
};

/*============================================================================
 * SHA-512 constants
 *==========================================================================*/

static const uint64_t SHA512_K[80] = {
    0x428a2f98d728ae22ULL, 0x7137449123ef65cdULL, 0xb5c0fbcfec4d3b2fULL, 0xe9b5dba58189dbbcULL,
    0x3956c25bf348b538ULL, 0x59f111f1b605d019ULL, 0x923f82a4af194f9bULL, 0xab1c5ed5da6d8118ULL,
    0xd807aa98a3030242ULL, 0x12835b0145706fbeULL, 0x243185be4ee4b28cULL, 0x550c7dc3d5ffb4e2ULL,
    0x72be5d74f27b896fULL, 0x80deb1fe3b1696b1ULL, 0x9bdc06a725c71235ULL, 0xc19bf174cf692694ULL,
    0xe49b69c19ef14ad2ULL, 0xefbe4786384f25e3ULL, 0x0fc19dc68b8cd5b5ULL, 0x240ca1cc77ac9c65ULL,
    0x2de92c6f592b0275ULL, 0x4a7484aa6ea6e483ULL, 0x5cb0a9dcbd41fbd4ULL, 0x76f988da831153b5ULL,
    0x983e5152ee66dfabULL, 0xa831c66d2db43210ULL, 0xb00327c898fb213fULL, 0xbf597fc7beef0ee4ULL,
    0xc6e00bf33da88fc2ULL, 0xd5a79147930aa725ULL, 0x06ca6351e003826fULL, 0x142929670a0e6e70ULL,
    0x27b70a8546d22ffcULL, 0x2e1b21385c26c926ULL, 0x4d2c6dfc5ac42aedULL, 0x53380d139d95b3dfULL,
    0x650a73548baf63deULL, 0x766a0abb3c77b2a8ULL, 0x81c2c92e47edaee6ULL, 0x92722c851482353bULL,
    0xa2bfe8a14cf10364ULL, 0xa81a664bbc423001ULL, 0xc24b8b70d0f89791ULL, 0xc76c51a30654be30ULL,
    0xd192e819d6ef5218ULL, 0xd69906245565a910ULL, 0xf40e35855771202aULL, 0x106aa07032bbd1b8ULL,
    0x19a4c116b8d2d0c8ULL, 0x1e376c085141ab53ULL, 0x2748774cdf8eeb99ULL, 0x34b0bcb5e19b48a8ULL,
    0x391c0cb3c5c95a63ULL, 0x4ed8aa4ae3418acbULL, 0x5b9cca4f7763e373ULL, 0x682e6ff3d6b2b8a3ULL,
    0x748f82ee5defb2fcULL, 0x78a5636f43172f60ULL, 0x84c87814a1f0ab72ULL, 0x8cc702081a6439ecULL,
    0x90befffa23631e28ULL, 0xa4506cebde82bde9ULL, 0xbef9a3f7b2c67915ULL, 0xc67178f2e372532bULL,
    0xca273eceea26619cULL, 0xd186b8c721c0c207ULL, 0xeada7dd6cde0eb1eULL, 0xf57d4f7fee6ed178ULL,
    0x06f067aa72176fbaULL, 0x0a637dc5a2c898a6ULL, 0x113f9804bef90daeULL, 0x1b710b35131c471bULL,
    0x28db77f523047d84ULL, 0x32caab7b40c72493ULL, 0x3c9ebe0a15c9bebcULL, 0x431d67c49c100d4cULL,
    0x4cc5d4becb3e42b6ULL, 0x597f299cfc657e2aULL, 0x5fcb6fab3ad6faecULL, 0x6c44198c4a475817ULL
};

static const uint64_t SHA512_H0[8] = {
    0x6a09e667f3bcc908ULL, 0xbb67ae8584caa73bULL, 0x3c6ef372fe94f82bULL, 0xa54ff53a5f1d36f1ULL,
    0x510e527fade682d1ULL, 0x9b05688c2b3e6c1fULL, 0x1f83d9abfb41bd6bULL, 0x5be0cd19137e2179ULL
};

static const uint64_t SHA384_H0[8] = {
    0xcbbb9d5dc1059ed8ULL, 0x629a292a367cd507ULL, 0x9159015a3070dd17ULL, 0x152fecd8f70e5939ULL,
    0x67332667ffc00b31ULL, 0x8eb44a8768581511ULL, 0xdb0c2e0d64f98fa7ULL, 0x47b5481dbefa4fa4ULL
};

/*============================================================================
 * Helper macros - 32-bit
 *==========================================================================*/

#define ROTR32(x, n) (((x) >> (n)) | ((x) << (32 - (n))))
#define SHR32(x, n)  ((x) >> (n))

#define CH32(x, y, z)  (((x) & (y)) ^ ((~(x)) & (z)))
#define MAJ32(x, y, z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))

#define SIGMA0_256(x) (ROTR32(x, 2) ^ ROTR32(x, 13) ^ ROTR32(x, 22))
#define SIGMA1_256(x) (ROTR32(x, 6) ^ ROTR32(x, 11) ^ ROTR32(x, 25))
#define sigma0_256(x) (ROTR32(x, 7) ^ ROTR32(x, 18) ^ SHR32(x, 3))
#define sigma1_256(x) (ROTR32(x, 17) ^ ROTR32(x, 19) ^ SHR32(x, 10))

/*============================================================================
 * Helper macros - 64-bit
 *==========================================================================*/

#define ROTR64(x, n) (((x) >> (n)) | ((x) << (64 - (n))))
#define SHR64(x, n)  ((x) >> (n))

#define CH64(x, y, z)  (((x) & (y)) ^ ((~(x)) & (z)))
#define MAJ64(x, y, z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))

#define SIGMA0_512(x) (ROTR64(x, 28) ^ ROTR64(x, 34) ^ ROTR64(x, 39))
#define SIGMA1_512(x) (ROTR64(x, 14) ^ ROTR64(x, 18) ^ ROTR64(x, 41))
#define sigma0_512(x) (ROTR64(x, 1) ^ ROTR64(x, 8) ^ SHR64(x, 7))
#define sigma1_512(x) (ROTR64(x, 19) ^ ROTR64(x, 61) ^ SHR64(x, 6))

/*============================================================================
 * SHA-256 transform
 *==========================================================================*/

static void sha256_transform(uint32_t state[8], const uint8_t block[64])
{
    uint32_t W[64];
    uint32_t a, b, c, d, e, f, g, h;
    uint32_t T1, T2;
    int t;

    /* Prepare message schedule */
    for (t = 0; t < 16; t++) {
        W[t] = pdfmake_read_be32(block + t * 4);
    }
    for (t = 16; t < 64; t++) {
        W[t] = sigma1_256(W[t-2]) + W[t-7] + sigma0_256(W[t-15]) + W[t-16];
    }
    
    /* Initialize working variables */
    a = state[0]; b = state[1]; c = state[2]; d = state[3];
    e = state[4]; f = state[5]; g = state[6]; h = state[7];
    
    /* 64 rounds */
    for (t = 0; t < 64; t++) {
        T1 = h + SIGMA1_256(e) + CH32(e, f, g) + SHA256_K[t] + W[t];
        T2 = SIGMA0_256(a) + MAJ32(a, b, c);
        h = g; g = f; f = e;
        e = d + T1;
        d = c; c = b; b = a;
        a = T1 + T2;
    }
    
    state[0] += a; state[1] += b; state[2] += c; state[3] += d;
    state[4] += e; state[5] += f; state[6] += g; state[7] += h;
}

/*============================================================================
 * SHA-256 public API
 *==========================================================================*/

void pdfmake_sha256_init(pdfmake_sha256_ctx_t *ctx)
{
    memcpy(ctx->state, SHA256_H0, sizeof(SHA256_H0));
    ctx->count = 0;
    memset(ctx->buffer, 0, sizeof(ctx->buffer));
}

void pdfmake_sha256_update(pdfmake_sha256_ctx_t *ctx, const uint8_t *data, size_t len)
{
    size_t buf_pos = (ctx->count / 8) % 64;
    ctx->count += (uint64_t)len * 8;
    
    if (buf_pos > 0) {
        size_t space = 64 - buf_pos;
        if (len >= space) {
            memcpy(ctx->buffer + buf_pos, data, space);
            sha256_transform(ctx->state, ctx->buffer);
            data += space;
            len -= space;
            buf_pos = 0;
        } else {
            memcpy(ctx->buffer + buf_pos, data, len);
            return;
        }
    }
    
    while (len >= 64) {
        sha256_transform(ctx->state, data);
        data += 64;
        len -= 64;
    }
    
    if (len > 0) {
        memcpy(ctx->buffer, data, len);
    }
}

void pdfmake_sha256_final(pdfmake_sha256_ctx_t *ctx, uint8_t digest[32])
{
    uint64_t bits = ctx->count;
    size_t buf_pos = (bits / 8) % 64;
    uint8_t pad[64];
    size_t pad_len;
    uint8_t len_bytes[8];
    int i;

    memset(pad, 0, sizeof(pad));
    pad[0] = 0x80;

    pad_len = (buf_pos < 56) ? (56 - buf_pos) : (120 - buf_pos);
    pdfmake_sha256_update(ctx, pad, pad_len);

    pdfmake_write_be64(len_bytes, bits);
    pdfmake_sha256_update(ctx, len_bytes, 8);

    for (i = 0; i < 8; i++) {
        pdfmake_write_be32(digest + i * 4, ctx->state[i]);
    }
}

void pdfmake_sha256(const uint8_t *data, size_t len, uint8_t digest[32])
{
    pdfmake_sha256_ctx_t ctx;
    pdfmake_sha256_init(&ctx);
    pdfmake_sha256_update(&ctx, data, len);
    pdfmake_sha256_final(&ctx, digest);
}

/*============================================================================
 * SHA-512 transform
 *==========================================================================*/

static void sha512_transform(uint64_t state[8], const uint8_t block[128])
{
    uint64_t W[80];
    uint64_t a, b, c, d, e, f, g, h;
    uint64_t T1, T2;
    int t;

    /* Prepare message schedule */
    for (t = 0; t < 16; t++) {
        W[t] = pdfmake_read_be64(block + t * 8);
    }
    for (t = 16; t < 80; t++) {
        W[t] = sigma1_512(W[t-2]) + W[t-7] + sigma0_512(W[t-15]) + W[t-16];
    }
    
    /* Initialize working variables */
    a = state[0]; b = state[1]; c = state[2]; d = state[3];
    e = state[4]; f = state[5]; g = state[6]; h = state[7];
    
    /* 80 rounds */
    for (t = 0; t < 80; t++) {
        T1 = h + SIGMA1_512(e) + CH64(e, f, g) + SHA512_K[t] + W[t];
        T2 = SIGMA0_512(a) + MAJ64(a, b, c);
        h = g; g = f; f = e;
        e = d + T1;
        d = c; c = b; b = a;
        a = T1 + T2;
    }
    
    state[0] += a; state[1] += b; state[2] += c; state[3] += d;
    state[4] += e; state[5] += f; state[6] += g; state[7] += h;
}

/*============================================================================
 * SHA-512 public API
 *==========================================================================*/

void pdfmake_sha512_init(pdfmake_sha512_ctx_t *ctx)
{
    memcpy(ctx->state, SHA512_H0, sizeof(SHA512_H0));
    ctx->count[0] = 0;
    ctx->count[1] = 0;
    memset(ctx->buffer, 0, sizeof(ctx->buffer));
}

void pdfmake_sha512_update(pdfmake_sha512_ctx_t *ctx, const uint8_t *data, size_t len)
{
    size_t buf_pos = (size_t)(ctx->count[0] / 8) % 128;
    
    /* Update bit count */
    uint64_t add_bits = (uint64_t)len * 8;
    ctx->count[0] += add_bits;
    if (ctx->count[0] < add_bits) {
        ctx->count[1]++;  /* Carry */
    }
    
    if (buf_pos > 0) {
        size_t space = 128 - buf_pos;
        if (len >= space) {
            memcpy(ctx->buffer + buf_pos, data, space);
            sha512_transform(ctx->state, ctx->buffer);
            data += space;
            len -= space;
            buf_pos = 0;
        } else {
            memcpy(ctx->buffer + buf_pos, data, len);
            return;
        }
    }
    
    while (len >= 128) {
        sha512_transform(ctx->state, data);
        data += 128;
        len -= 128;
    }
    
    if (len > 0) {
        memcpy(ctx->buffer, data, len);
    }
}

void pdfmake_sha512_final(pdfmake_sha512_ctx_t *ctx, uint8_t digest[64])
{
    /* Snapshot the bit count BEFORE padding (update() will mutate it). */
    uint64_t bits_lo = ctx->count[0];
    uint64_t bits_hi = ctx->count[1];
    size_t buf_pos = (size_t)(bits_lo / 8) % 128;
    uint8_t pad[128];
    size_t pad_len;
    uint8_t len_bytes[16];
    int i;

    memset(pad, 0, sizeof(pad));
    pad[0] = 0x80;

    /* Pad to 112 mod 128 bytes (leaving 16 bytes for 128-bit length) */
    pad_len = (buf_pos < 112) ? (112 - buf_pos) : (240 - buf_pos);
    pdfmake_sha512_update(ctx, pad, pad_len);

    /* Append 128-bit length (high 64 bits, then low 64 bits) */
    pdfmake_write_be64(len_bytes,     bits_hi);
    pdfmake_write_be64(len_bytes + 8, bits_lo);
    pdfmake_sha512_update(ctx, len_bytes, 16);

    for (i = 0; i < 8; i++) {
        pdfmake_write_be64(digest + i * 8, ctx->state[i]);
    }
}

void pdfmake_sha512(const uint8_t *data, size_t len, uint8_t digest[64])
{
    pdfmake_sha512_ctx_t ctx;
    pdfmake_sha512_init(&ctx);
    pdfmake_sha512_update(&ctx, data, len);
    pdfmake_sha512_final(&ctx, digest);
}

/*============================================================================
 * SHA-384 (SHA-512 with different IV and truncated output)
 *==========================================================================*/

void pdfmake_sha384_init(pdfmake_sha384_ctx_t *ctx)
{
    memcpy(ctx->state, SHA384_H0, sizeof(SHA384_H0));
    ctx->count[0] = 0;
    ctx->count[1] = 0;
    memset(ctx->buffer, 0, sizeof(ctx->buffer));
}

void pdfmake_sha384_update(pdfmake_sha384_ctx_t *ctx, const uint8_t *data, size_t len)
{
    /* SHA-384 uses same update logic as SHA-512 */
    pdfmake_sha512_update((pdfmake_sha512_ctx_t *)ctx, data, len);
}

void pdfmake_sha384_final(pdfmake_sha384_ctx_t *ctx, uint8_t digest[48])
{
    uint8_t full_digest[64];
    pdfmake_sha512_final((pdfmake_sha512_ctx_t *)ctx, full_digest);
    memcpy(digest, full_digest, 48);  /* Truncate to 384 bits */
}

void pdfmake_sha384(const uint8_t *data, size_t len, uint8_t digest[48])
{
    pdfmake_sha384_ctx_t ctx;
    pdfmake_sha384_init(&ctx);
    pdfmake_sha384_update(&ctx, data, len);
    pdfmake_sha384_final(&ctx, digest);
}
