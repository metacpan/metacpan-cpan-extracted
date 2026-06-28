/*
 * pdfmake_signature.c — PDF Digital Signatures Implementation
 *
 * Implements PDF digital signatures per ISO 32000-2:2020 §12.8.
 */

#include "pdfmake_signature.h"
#include "pdfmake_asn1.h"
#include "pdfmake_x509.h"
#include "pdfmake_pkcs12.h"
#include "pdfmake_arena.h"
#include "pdfmake_buf.h"
#include "pdfmake_bn.h"
#include "pdfmake_parser.h"
#include "pdfmake_annot.h"
#include "pdfmake_page.h"
#include "pdfmake_meta.h"
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <stdio.h>

/* OIDs used by CMS SignedData (RFC 5652). */
#define OID_ID_DATA           "1.2.840.113549.1.7.1"
#define OID_ID_SIGNED_DATA    "1.2.840.113549.1.7.2"
#define OID_ID_CONTENT_TYPE   "1.2.840.113549.1.9.3"
#define OID_ID_MESSAGE_DIGEST "1.2.840.113549.1.9.4"
#define OID_ID_SIGNING_TIME   "1.2.840.113549.1.9.5"
#define OID_RSA_ENCRYPTION    "1.2.840.113549.1.1.1"
#define OID_SHA1              "1.3.14.3.2.26"
#define OID_SHA256            "2.16.840.1.101.3.4.2.1"
#define OID_SHA384            "2.16.840.1.101.3.4.2.2"
#define OID_SHA512            "2.16.840.1.101.3.4.2.3"
/* RFC 5035 / ETSI EN 319 122 — PAdES-BES signing-certificate-v2 */
#define OID_AA_SIGNING_CERT_V2 "1.2.840.113549.1.9.16.2.47"
/* RFC 3161 / RFC 5652 — timestamp token unsigned attribute */
#define OID_AA_TIMESTAMP_TOKEN "1.2.840.113549.1.9.16.2.14"

/*============================================================================
 * SHA-256 Implementation
 *==========================================================================*/

typedef struct {
    uint32_t state[8];
    uint64_t count;
    uint8_t buffer[64];
} sha256_ctx_t;

static const uint32_t SHA256_K[64] = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

#define ROR32(x, n) (((x) >> (n)) | ((x) << (32 - (n))))
#define CH(x, y, z) (((x) & (y)) ^ (~(x) & (z)))
#define MAJ(x, y, z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define EP0(x) (ROR32(x, 2) ^ ROR32(x, 13) ^ ROR32(x, 22))
#define EP1(x) (ROR32(x, 6) ^ ROR32(x, 11) ^ ROR32(x, 25))
#define SIG0(x) (ROR32(x, 7) ^ ROR32(x, 18) ^ ((x) >> 3))
#define SIG1(x) (ROR32(x, 17) ^ ROR32(x, 19) ^ ((x) >> 10))

static void sha256_transform(uint32_t state[8], const uint8_t block[64])
{
    uint32_t a, b, c, d, e, f, g, h;
    uint32_t t1, t2;
    uint32_t w[64];
    int i;
    
    /* Prepare message schedule */
    for (i = 0; i < 16; i++) {
        w[i] = ((uint32_t)block[i*4] << 24) |
               ((uint32_t)block[i*4+1] << 16) |
               ((uint32_t)block[i*4+2] << 8) |
               ((uint32_t)block[i*4+3]);
    }
    for (i = 16; i < 64; i++) {
        w[i] = SIG1(w[i-2]) + w[i-7] + SIG0(w[i-15]) + w[i-16];
    }
    
    a = state[0]; b = state[1]; c = state[2]; d = state[3];
    e = state[4]; f = state[5]; g = state[6]; h = state[7];
    
    for (i = 0; i < 64; i++) {
        t1 = h + EP1(e) + CH(e, f, g) + SHA256_K[i] + w[i];
        t2 = EP0(a) + MAJ(a, b, c);
        h = g; g = f; f = e; e = d + t1;
        d = c; c = b; b = a; a = t1 + t2;
    }
    
    state[0] += a; state[1] += b; state[2] += c; state[3] += d;
    state[4] += e; state[5] += f; state[6] += g; state[7] += h;
}

static void sha256_init(sha256_ctx_t *ctx)
{
    ctx->state[0] = 0x6a09e667;
    ctx->state[1] = 0xbb67ae85;
    ctx->state[2] = 0x3c6ef372;
    ctx->state[3] = 0xa54ff53a;
    ctx->state[4] = 0x510e527f;
    ctx->state[5] = 0x9b05688c;
    ctx->state[6] = 0x1f83d9ab;
    ctx->state[7] = 0x5be0cd19;
    ctx->count = 0;
}

static void sha256_update(sha256_ctx_t *ctx, const uint8_t *data, size_t len)
{
    size_t i = (ctx->count >> 3) & 63;
    size_t part_len;
    size_t j = 0;
    ctx->count += (uint64_t)len << 3;

    part_len = 64 - i;
    
    if (len >= part_len) {
        memcpy(ctx->buffer + i, data, part_len);
        sha256_transform(ctx->state, ctx->buffer);
        
        for (j = part_len; j + 63 < len; j += 64) {
            sha256_transform(ctx->state, data + j);
        }
        i = 0;
    }
    
    memcpy(ctx->buffer + i, data + j, len - j);
}

static void sha256_final(sha256_ctx_t *ctx, uint8_t digest[32])
{
    uint8_t pad[64] = {0x80};
    uint64_t bits = ctx->count;
    size_t i = (ctx->count >> 3) & 63;
    size_t pad_len = (i < 56) ? (56 - i) : (120 - i);
    uint8_t len_bytes[8];
    int j;
    
    sha256_update(ctx, pad, pad_len);
    
    for (j = 0; j < 8; j++) {
        len_bytes[j] = (bits >> (56 - j * 8)) & 0xFF;
    }
    sha256_update(ctx, len_bytes, 8);

    for (j = 0; j < 8; j++) {
        digest[j*4] = (ctx->state[j] >> 24) & 0xFF;
        digest[j*4+1] = (ctx->state[j] >> 16) & 0xFF;
        digest[j*4+2] = (ctx->state[j] >> 8) & 0xFF;
        digest[j*4+3] = ctx->state[j] & 0xFF;
    }
}

/*============================================================================
 * SHA-384/512 Implementation
 *==========================================================================*/

typedef struct {
    uint64_t state[8];
    uint64_t count[2];
    uint8_t buffer[128];
} sha512_ctx_t;

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

#define ROR64(x, n) (((x) >> (n)) | ((x) << (64 - (n))))
#define CH64(x, y, z) (((x) & (y)) ^ (~(x) & (z)))
#define MAJ64(x, y, z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define EP0_64(x) (ROR64(x, 28) ^ ROR64(x, 34) ^ ROR64(x, 39))
#define EP1_64(x) (ROR64(x, 14) ^ ROR64(x, 18) ^ ROR64(x, 41))
#define SIG0_64(x) (ROR64(x, 1) ^ ROR64(x, 8) ^ ((x) >> 7))
#define SIG1_64(x) (ROR64(x, 19) ^ ROR64(x, 61) ^ ((x) >> 6))

static void sha512_transform(uint64_t state[8], const uint8_t block[128])
{
    uint64_t a, b, c, d, e, f, g, h;
    uint64_t t1, t2;
    uint64_t w[80];
    int i;

    for (i = 0; i < 16; i++) {
        w[i] = ((uint64_t)block[i*8] << 56) |
               ((uint64_t)block[i*8+1] << 48) |
               ((uint64_t)block[i*8+2] << 40) |
               ((uint64_t)block[i*8+3] << 32) |
               ((uint64_t)block[i*8+4] << 24) |
               ((uint64_t)block[i*8+5] << 16) |
               ((uint64_t)block[i*8+6] << 8) |
               ((uint64_t)block[i*8+7]);
    }
    for (i = 16; i < 80; i++) {
        w[i] = SIG1_64(w[i-2]) + w[i-7] + SIG0_64(w[i-15]) + w[i-16];
    }
    
    a = state[0]; b = state[1]; c = state[2]; d = state[3];
    e = state[4]; f = state[5]; g = state[6]; h = state[7];
    
    for (i = 0; i < 80; i++) {
        t1 = h + EP1_64(e) + CH64(e, f, g) + SHA512_K[i] + w[i];
        t2 = EP0_64(a) + MAJ64(a, b, c);
        h = g; g = f; f = e; e = d + t1;
        d = c; c = b; b = a; a = t1 + t2;
    }
    
    state[0] += a; state[1] += b; state[2] += c; state[3] += d;
    state[4] += e; state[5] += f; state[6] += g; state[7] += h;
}

static void sha512_init(sha512_ctx_t *ctx)
{
    ctx->state[0] = 0x6a09e667f3bcc908ULL;
    ctx->state[1] = 0xbb67ae8584caa73bULL;
    ctx->state[2] = 0x3c6ef372fe94f82bULL;
    ctx->state[3] = 0xa54ff53a5f1d36f1ULL;
    ctx->state[4] = 0x510e527fade682d1ULL;
    ctx->state[5] = 0x9b05688c2b3e6c1fULL;
    ctx->state[6] = 0x1f83d9abfb41bd6bULL;
    ctx->state[7] = 0x5be0cd19137e2179ULL;
    ctx->count[0] = ctx->count[1] = 0;
}

static void sha384_init(sha512_ctx_t *ctx)
{
    ctx->state[0] = 0xcbbb9d5dc1059ed8ULL;
    ctx->state[1] = 0x629a292a367cd507ULL;
    ctx->state[2] = 0x9159015a3070dd17ULL;
    ctx->state[3] = 0x152fecd8f70e5939ULL;
    ctx->state[4] = 0x67332667ffc00b31ULL;
    ctx->state[5] = 0x8eb44a8768581511ULL;
    ctx->state[6] = 0xdb0c2e0d64f98fa7ULL;
    ctx->state[7] = 0x47b5481dbefa4fa4ULL;
    ctx->count[0] = ctx->count[1] = 0;
}

static void sha512_update(sha512_ctx_t *ctx, const uint8_t *data, size_t len)
{
    size_t i = (ctx->count[0] >> 3) & 127;
    size_t part_len;
    size_t j = 0;
    
    ctx->count[0] += (uint64_t)len << 3;
    if (ctx->count[0] < ((uint64_t)len << 3)) {
        ctx->count[1]++;
    }
    
    part_len = 128 - i;

    if (len >= part_len) {
        memcpy(ctx->buffer + i, data, part_len);
        sha512_transform(ctx->state, ctx->buffer);
        
        for (j = part_len; j + 127 < len; j += 128) {
            sha512_transform(ctx->state, data + j);
        }
        i = 0;
    }
    
    memcpy(ctx->buffer + i, data + j, len - j);
}

static void sha512_final(sha512_ctx_t *ctx, uint8_t digest[64])
{
    uint8_t pad[128] = {0x80};
    size_t i = (ctx->count[0] >> 3) & 127;
    size_t pad_len = (i < 112) ? (112 - i) : (240 - i);
    uint8_t len_bytes[16];
    int j;

    sha512_update(ctx, pad, pad_len);

    for (j = 0; j < 8; j++) {
        len_bytes[j] = (ctx->count[1] >> (56 - j * 8)) & 0xFF;
        len_bytes[j + 8] = (ctx->count[0] >> (56 - j * 8)) & 0xFF;
    }
    sha512_update(ctx, len_bytes, 16);

    for (j = 0; j < 8; j++) {
        digest[j*8] = (ctx->state[j] >> 56) & 0xFF;
        digest[j*8+1] = (ctx->state[j] >> 48) & 0xFF;
        digest[j*8+2] = (ctx->state[j] >> 40) & 0xFF;
        digest[j*8+3] = (ctx->state[j] >> 32) & 0xFF;
        digest[j*8+4] = (ctx->state[j] >> 24) & 0xFF;
        digest[j*8+5] = (ctx->state[j] >> 16) & 0xFF;
        digest[j*8+6] = (ctx->state[j] >> 8) & 0xFF;
        digest[j*8+7] = ctx->state[j] & 0xFF;
    }
}

static void sha384_final(sha512_ctx_t *ctx, uint8_t digest[48])
{
    uint8_t full_digest[64];
    sha512_final(ctx, full_digest);
    memcpy(digest, full_digest, 48);
}

/*============================================================================
 * SHA-1 Implementation (for legacy compatibility)
 *==========================================================================*/

typedef struct {
    uint32_t state[5];
    uint64_t count;
    uint8_t buffer[64];
} sha1_ctx_t;

static void sha1_init(sha1_ctx_t *ctx)
{
    ctx->state[0] = 0x67452301;
    ctx->state[1] = 0xEFCDAB89;
    ctx->state[2] = 0x98BADCFE;
    ctx->state[3] = 0x10325476;
    ctx->state[4] = 0xC3D2E1F0;
    ctx->count = 0;
}

#define ROL32(x, n) (((x) << (n)) | ((x) >> (32 - (n))))

static void sha1_transform(uint32_t state[5], const uint8_t block[64])
{
    uint32_t a, b, c, d, e;
    uint32_t f, k;
    uint32_t temp;
    uint32_t w[80];
    int i;

    for (i = 0; i < 16; i++) {
        w[i] = ((uint32_t)block[i*4] << 24) |
               ((uint32_t)block[i*4+1] << 16) |
               ((uint32_t)block[i*4+2] << 8) |
               ((uint32_t)block[i*4+3]);
    }
    for (i = 16; i < 80; i++) {
        w[i] = ROL32(w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16], 1);
    }
    
    a = state[0]; b = state[1]; c = state[2]; d = state[3]; e = state[4];
    
    for (i = 0; i < 80; i++) {
        if (i < 20) {
            f = (b & c) | ((~b) & d);
            k = 0x5A827999;
        } else if (i < 40) {
            f = b ^ c ^ d;
            k = 0x6ED9EBA1;
        } else if (i < 60) {
            f = (b & c) | (b & d) | (c & d);
            k = 0x8F1BBCDC;
        } else {
            f = b ^ c ^ d;
            k = 0xCA62C1D6;
        }
        
        temp = ROL32(a, 5) + f + e + k + w[i];
        e = d; d = c; c = ROL32(b, 30); b = a; a = temp;
    }
    
    state[0] += a; state[1] += b; state[2] += c; state[3] += d; state[4] += e;
}

static void sha1_update(sha1_ctx_t *ctx, const uint8_t *data, size_t len)
{
    size_t i = (ctx->count >> 3) & 63;
    size_t part_len;
    size_t j = 0;
    ctx->count += (uint64_t)len << 3;

    part_len = 64 - i;

    if (len >= part_len) {
        memcpy(ctx->buffer + i, data, part_len);
        sha1_transform(ctx->state, ctx->buffer);
        
        for (j = part_len; j + 63 < len; j += 64) {
            sha1_transform(ctx->state, data + j);
        }
        i = 0;
    }
    
    memcpy(ctx->buffer + i, data + j, len - j);
}

static void sha1_final(sha1_ctx_t *ctx, uint8_t digest[20])
{
    uint8_t pad[64] = {0x80};
    uint64_t bits = ctx->count;
    size_t i = (ctx->count >> 3) & 63;
    size_t pad_len = (i < 56) ? (56 - i) : (120 - i);
    uint8_t len_bytes[8];
    int j;

    sha1_update(ctx, pad, pad_len);

    for (j = 0; j < 8; j++) {
        len_bytes[j] = (bits >> (56 - j * 8)) & 0xFF;
    }
    sha1_update(ctx, len_bytes, 8);

    for (j = 0; j < 5; j++) {
        digest[j*4] = (ctx->state[j] >> 24) & 0xFF;
        digest[j*4+1] = (ctx->state[j] >> 16) & 0xFF;
        digest[j*4+2] = (ctx->state[j] >> 8) & 0xFF;
        digest[j*4+3] = ctx->state[j] & 0xFF;
    }
}

/*============================================================================
 * Hash API Implementation
 *==========================================================================*/

struct pdfmake_hash_ctx_s {
    pdfmake_hash_algorithm_t algorithm;
    union {
        sha1_ctx_t sha1;
        sha256_ctx_t sha256;
        sha512_ctx_t sha512;
    };
};

pdfmake_hash_ctx_t *pdfmake_hash_new(pdfmake_hash_algorithm_t alg)
{
    pdfmake_hash_ctx_t *ctx = calloc(1, sizeof(pdfmake_hash_ctx_t));
    if (!ctx) return NULL;
    
    ctx->algorithm = alg;
    
    switch (alg) {
        case PDFMAKE_HASH_SHA1:
            sha1_init(&ctx->sha1);
            break;
        case PDFMAKE_HASH_SHA256:
            sha256_init(&ctx->sha256);
            break;
        case PDFMAKE_HASH_SHA384:
            sha384_init(&ctx->sha512);
            break;
        case PDFMAKE_HASH_SHA512:
            sha512_init(&ctx->sha512);
            break;
        default:
            free(ctx);
            return NULL;
    }
    
    return ctx;
}

void pdfmake_hash_update(pdfmake_hash_ctx_t *ctx, const uint8_t *data, size_t len)
{
    if (!ctx || !data) return;
    
    switch (ctx->algorithm) {
        case PDFMAKE_HASH_SHA1:
            sha1_update(&ctx->sha1, data, len);
            break;
        case PDFMAKE_HASH_SHA256:
            sha256_update(&ctx->sha256, data, len);
            break;
        case PDFMAKE_HASH_SHA384:
        case PDFMAKE_HASH_SHA512:
            sha512_update(&ctx->sha512, data, len);
            break;
    }
}

size_t pdfmake_hash_final(pdfmake_hash_ctx_t *ctx, uint8_t *digest)
{
    if (!ctx || !digest) return 0;
    
    switch (ctx->algorithm) {
        case PDFMAKE_HASH_SHA1:
            sha1_final(&ctx->sha1, digest);
            return 20;
        case PDFMAKE_HASH_SHA256:
            sha256_final(&ctx->sha256, digest);
            return 32;
        case PDFMAKE_HASH_SHA384:
            sha384_final(&ctx->sha512, digest);
            return 48;
        case PDFMAKE_HASH_SHA512:
            sha512_final(&ctx->sha512, digest);
            return 64;
        default:
            return 0;
    }
}

void pdfmake_hash_free(pdfmake_hash_ctx_t *ctx)
{
    if (ctx) {
        memset(ctx, 0, sizeof(*ctx));
        free(ctx);
    }
}

size_t pdfmake_hash(
    pdfmake_hash_algorithm_t alg,
    const uint8_t *data,
    size_t len,
    uint8_t *digest)
{
    pdfmake_hash_ctx_t *ctx = pdfmake_hash_new(alg);
    size_t result;
    if (!ctx) return 0;
    
    pdfmake_hash_update(ctx, data, len);
    result = pdfmake_hash_final(ctx, digest);
    pdfmake_hash_free(ctx);
    
    return result;
}

size_t pdfmake_hash_size(pdfmake_hash_algorithm_t alg)
{
    switch (alg) {
        case PDFMAKE_HASH_SHA1:   return 20;
        case PDFMAKE_HASH_SHA256: return 32;
        case PDFMAKE_HASH_SHA384: return 48;
        case PDFMAKE_HASH_SHA512: return 64;
        default: return 0;
    }
}

/*============================================================================
 * Signature Config
 *==========================================================================*/

void pdfmake_sig_config_init(pdfmake_sig_config_t *config)
{
    if (!config) return;

    memset(config, 0, sizeof(*config));
    config->hash_algorithm   = PDFMAKE_HASH_SHA256;
    config->subfilter        = PDFMAKE_SUBFILTER_PKCS7_DETACHED;
    config->placeholder_size = 8192;
    /* Default visible-signature layout shows name + date + reason. */
    config->ap_show_name   = 1;
    config->ap_show_date   = 1;
    config->ap_show_reason = 1;
}

/*============================================================================
 * PKCS#7 Building
 *==========================================================================*/

/* Return the OID string for a digest algorithm. */
static const char *hash_oid(pdfmake_hash_algorithm_t alg) {
    switch (alg) {
        case PDFMAKE_HASH_SHA1:   return OID_SHA1;
        case PDFMAKE_HASH_SHA256: return OID_SHA256;
        case PDFMAKE_HASH_SHA384: return OID_SHA384;
        case PDFMAKE_HASH_SHA512: return OID_SHA512;
        default:                   return OID_SHA256;
    }
}

/* AlgorithmIdentifier ::= SEQUENCE { algorithm OID, parameters NULL } */
static void write_alg_id_sha(pdfmake_asn1_encoder_t *enc,
                             pdfmake_hash_algorithm_t alg) {
    size_t s = pdfmake_asn1_begin_sequence(enc);
    pdfmake_asn1_write_oid(enc, hash_oid(alg));
    pdfmake_asn1_write_null(enc);
    pdfmake_asn1_end_constructed(enc, s);
}

/* Same but with a provided OID (for signature alg = rsaEncryption). */
static void write_alg_id_oid(pdfmake_asn1_encoder_t *enc, const char *oid) {
    size_t s = pdfmake_asn1_begin_sequence(enc);
    pdfmake_asn1_write_oid(enc, oid);
    pdfmake_asn1_write_null(enc);
    pdfmake_asn1_end_constructed(enc, s);
}

/* Locate the issuer Name in TBSCertificate and return its raw DER slice
 * (tag + length + content).  The issuer is the 3rd or 4th element of
 * TBSCertificate (skipping the optional [0] version). */
static int find_issuer_der(pdfmake_arena_t *arena,
                           const pdfmake_x509_cert_t *cert,
                           const uint8_t **out_bytes, size_t *out_len)
{
    pdfmake_asn1_node_t *tbs;
    size_t idx;
    pdfmake_asn1_node_t *first;
    pdfmake_asn1_node_t *issuer;
    size_t hdr;
    if (!cert->tbs_certificate || cert->tbs_certificate_len == 0) return -1;
    tbs = pdfmake_asn1_parse(arena, cert->tbs_certificate, cert->tbs_certificate_len);
    if (!tbs) return -1;

    idx = 0;
    first = pdfmake_asn1_child_at(tbs, 0);
    if (!first) return -1;
    /* Skip [0] EXPLICIT version if present. */
    if ((first->tag & ASN1_CLASS_MASK) == ASN1_CLASS_CONTEXT
        && (first->tag & 0x1F) == 0) {
        idx = 1;
    }
    idx += 2;                       /* skip serial + signature algorithm */
    issuer = pdfmake_asn1_child_at(tbs, idx);
    if (!issuer) return -1;

    /* Reconstruct the raw DER (tag + length + content) from issuer->length
     * plus the header size implied by DER rules. */
    hdr = 2;
    if (issuer->length >= 0x80) {
        if (issuer->length < 0x100)        hdr = 3;
        else if (issuer->length < 0x10000) hdr = 4;
        else                               hdr = 5;
    }
    *out_bytes = issuer->data - hdr;
    *out_len   = hdr + issuer->length;
    return 0;
}

/* Write SignedAttributes elements (just the contents, without the outer
 * SET-OF header).  Used twice: once to build the bytes that get signed
 * (re-tagged with universal SET 0x31) and once inside the SignerInfo
 * (with IMPLICIT [0] tag 0xA0). */
static void write_signed_attrs_body(pdfmake_asn1_encoder_t *enc,
                                    const uint8_t *digest, size_t digest_len,
                                    const uint8_t *cert_sha256,
                                    time_t now) {
    size_t a1, a2, a3;
    size_t v1, v2, v3;
    size_t a4, v4, sc, certs, eid;
    /* DER SET-OF: elements ordered ascending by their encoded bytes
     * (X.690 §11.6).  All four Attribute SEQUENCEs share the same tag
     * byte (0x30); they differ in the length byte and then in the OID.
     * For SHA-256 digest + short cert-hash, the outer SEQUENCE lengths
     * are roughly:
     *   contentType       : 24   (0x18)
     *   signingTime       : 28   (0x1C)
     *   messageDigest     : 47   (0x2F)
     *   signingCertV2     : 55+  (≥0x37)
     * so emitting in (ctype, signingTime, messageDigest, signingCertV2)
     * order produces valid DER for any supported digest algorithm. */

    /* 1. contentType = id-data */
    a1 = pdfmake_asn1_begin_sequence(enc);
        pdfmake_asn1_write_oid(enc, OID_ID_CONTENT_TYPE);
        v1 = pdfmake_asn1_begin_set(enc);
            pdfmake_asn1_write_oid(enc, OID_ID_DATA);
        pdfmake_asn1_end_constructed(enc, v1);
    pdfmake_asn1_end_constructed(enc, a1);

    /* 2. signingTime = UTCTime(now) */
    a2 = pdfmake_asn1_begin_sequence(enc);
        pdfmake_asn1_write_oid(enc, OID_ID_SIGNING_TIME);
        v2 = pdfmake_asn1_begin_set(enc);
            pdfmake_asn1_write_utc_time(enc, (int64_t)now);
        pdfmake_asn1_end_constructed(enc, v2);
    pdfmake_asn1_end_constructed(enc, a2);

    /* 3. messageDigest = OCTET STRING (document digest) */
    a3 = pdfmake_asn1_begin_sequence(enc);
        pdfmake_asn1_write_oid(enc, OID_ID_MESSAGE_DIGEST);
        v3 = pdfmake_asn1_begin_set(enc);
            pdfmake_asn1_write_octet_string(enc, digest, digest_len);
        pdfmake_asn1_end_constructed(enc, v3);
    pdfmake_asn1_end_constructed(enc, a3);

    /* 4. signingCertificateV2 (PAdES-BES, RFC 5035 §3).  Minimal form:
     *    SigningCertificateV2 ::= SEQUENCE {
     *      certs SEQUENCE OF ESSCertIDv2 }
     *    ESSCertIDv2 ::= SEQUENCE {
     *      hashAlgorithm AlgorithmIdentifier DEFAULT id-sha256,   -- omitted
     *      certHash      OCTET STRING }                           -- SHA-256(cert.DER)
     * We omit hashAlgorithm (SHA-256 is the default) and issuerSerial
     * (optional; not required for basic PAdES-BES validation). */
    if (cert_sha256) {
        a4 = pdfmake_asn1_begin_sequence(enc);
            pdfmake_asn1_write_oid(enc, OID_AA_SIGNING_CERT_V2);
            v4 = pdfmake_asn1_begin_set(enc);
                sc = pdfmake_asn1_begin_sequence(enc);        /* SigningCertificateV2 */
                    certs = pdfmake_asn1_begin_sequence(enc); /* SEQUENCE OF ESSCertIDv2 */
                        eid = pdfmake_asn1_begin_sequence(enc);
                            pdfmake_asn1_write_octet_string(enc, cert_sha256, 32);
                        pdfmake_asn1_end_constructed(enc, eid);
                    pdfmake_asn1_end_constructed(enc, certs);
                pdfmake_asn1_end_constructed(enc, sc);
            pdfmake_asn1_end_constructed(enc, v4);
        pdfmake_asn1_end_constructed(enc, a4);
    }
}

/* Build the SET-OF SignedAttributes (universal tag 0x31), hash that DER
 * with `alg`, and RSA-sign the hash. The intermediate SA buffer is not
 * returned — the caller re-encodes the same attributes inside SignerInfo
 * with context tag [0] via write_signed_attrs_body(). */
static pdfmake_err_t
sign_signed_attrs(pdfmake_arena_t *arena,
                  const pdfmake_privkey_t *key,
                  pdfmake_hash_algorithm_t alg,
                  const uint8_t *digest, size_t digest_len,
                  const uint8_t cert_sha256[32],
                  time_t now,
                  uint8_t **out_sig, size_t *out_sig_len)
{
    pdfmake_buf_t sa_buf;
    pdfmake_asn1_encoder_t sa_enc;
    size_t sa_start;
    uint8_t sa_digest[64];
    size_t sa_digest_len;
    pdfmake_hash_ctx_t *h;
    pdfmake_err_t err;
    if (pdfmake_buf_init(&sa_buf) != PDFMAKE_OK) return PDFMAKE_ENOMEM;

    pdfmake_asn1_encoder_init(&sa_enc, arena, &sa_buf);
    sa_start = pdfmake_asn1_begin_set(&sa_enc);
        write_signed_attrs_body(&sa_enc, digest, digest_len, cert_sha256, now);
    pdfmake_asn1_end_constructed(&sa_enc, sa_start);

    h = pdfmake_hash_new(alg);
    if (!h) { pdfmake_buf_free(&sa_buf); return PDFMAKE_ENOMEM; }
    pdfmake_hash_update(h, pdfmake_buf_data(&sa_buf), pdfmake_buf_len(&sa_buf));
    sa_digest_len = pdfmake_hash_final(h, sa_digest);
    pdfmake_hash_free(h);

    err = pdfmake_rsa_sign(arena, key, alg,
                           sa_digest, sa_digest_len,
                           out_sig, out_sig_len);
    pdfmake_buf_free(&sa_buf);
    return err;
}

/* Emit the unsignedAttrs [1] IMPLICIT block carrying a single RFC 3161
 * aa-signatureTimeStampToken attribute. No-op if no token was supplied —
 * unsignedAttrs is optional and omitting the SET when empty keeps the
 * DER canonical. */
static void
write_signature_timestamp_attr(pdfmake_asn1_encoder_t *enc,
                               const uint8_t *tst_token, size_t tst_token_len)
{
    size_t ua, ta, tv;
    if (!tst_token || tst_token_len == 0) return;

    ua = pdfmake_asn1_begin_context(enc, 1, 1);
        ta = pdfmake_asn1_begin_sequence(enc);
            pdfmake_asn1_write_oid(enc, OID_AA_TIMESTAMP_TOKEN);
            tv = pdfmake_asn1_begin_set(enc);
                pdfmake_asn1_write_raw(enc, tst_token, tst_token_len);
            pdfmake_asn1_end_constructed(enc, tv);
        pdfmake_asn1_end_constructed(enc, ta);
    pdfmake_asn1_end_constructed(enc, ua);
}

/* Emit the single SignerInfo (version 1 / IssuerAndSerialNumber variant)
 * that makes up the signerInfos SET. */
static void
write_signer_info(pdfmake_asn1_encoder_t *enc,
                  const pdfmake_x509_cert_t *cert,
                  const uint8_t *issuer_der, size_t issuer_len,
                  pdfmake_hash_algorithm_t alg,
                  const uint8_t *digest, size_t digest_len,
                  const uint8_t cert_sha256[32],
                  time_t now,
                  const uint8_t *rsa_sig, size_t rsa_sig_len,
                  const uint8_t *tst_token, size_t tst_token_len)
{
    size_t si;
    size_t iasn;
    size_t sattrs;
    si = pdfmake_asn1_begin_sequence(enc);
        /* version = 1 (IssuerAndSerialNumber) */
        pdfmake_asn1_write_int64(enc, 1);

        /* sid = IssuerAndSerialNumber */
        iasn = pdfmake_asn1_begin_sequence(enc);
            pdfmake_asn1_write_raw(enc, issuer_der, issuer_len);
            pdfmake_asn1_write_integer(enc, cert->serial, cert->serial_len);
        pdfmake_asn1_end_constructed(enc, iasn);

        /* digestAlgorithm */
        write_alg_id_sha(enc, alg);

        /* signedAttrs [0] IMPLICIT SET OF Attribute. Rebuilt here with
         * context tag 0xA0 — the universal-SET form we signed differs
         * only in the outer tag byte. */
        sattrs = pdfmake_asn1_begin_context(enc, 0, 1);
            write_signed_attrs_body(enc, digest, digest_len, cert_sha256, now);
        pdfmake_asn1_end_constructed(enc, sattrs);

        /* signatureAlgorithm = rsaEncryption */
        write_alg_id_oid(enc, OID_RSA_ENCRYPTION);

        /* signature = OCTET STRING of RSA sig */
        pdfmake_asn1_write_octet_string(enc, rsa_sig, rsa_sig_len);

        /* unsignedAttrs [1] IMPLICIT — optional RFC 3161 timestamp.
         * Adding this does not change rsa_sig (unsigned attrs are not
         * covered by the signedAttrs hash). */
        write_signature_timestamp_attr(enc, tst_token, tst_token_len);
    pdfmake_asn1_end_constructed(enc, si);
}

pdfmake_err_t pdfmake_pkcs7_build(
    pdfmake_arena_t *arena,
    const pdfmake_sig_config_t *config,
    const uint8_t *digest,
    size_t digest_len,
    pdfmake_buf_t *out)
{
    const pdfmake_x509_cert_t *cert;
    const pdfmake_privkey_t   *key;
    pdfmake_hash_algorithm_t   alg;
    time_t now;
    uint8_t cert_sha256[32];
    uint8_t *rsa_sig;
    size_t rsa_sig_len;
    pdfmake_err_t err;
    const uint8_t *issuer_der;
    size_t issuer_len;
    pdfmake_asn1_encoder_t enc;
    size_t ci, ci_content, sd, das, eci, certs, sis;
    if (!arena || !config || !digest || !out) return PDFMAKE_EINVAL;
    if (!config->identity || !config->identity->privkey ||
        !config->identity->cert) return PDFMAKE_EINVAL;

    cert = config->identity->cert;
    key  = config->identity->privkey;
    alg  = config->hash_algorithm
           ? config->hash_algorithm
           : PDFMAKE_HASH_SHA256;
    now = config->signing_time > 0
          ? (time_t)config->signing_time
          : time(NULL);

    /* PAdES-BES signingCertificateV2 wants SHA-256(cert.DER). */
    {
        pdfmake_hash_ctx_t *h = pdfmake_hash_new(PDFMAKE_HASH_SHA256);
        if (!h) return PDFMAKE_ENOMEM;
        pdfmake_hash_update(h, cert->der, cert->der_len);
        pdfmake_hash_final(h, cert_sha256);
        pdfmake_hash_free(h);
    }

    /* Build signedAttrs, hash, and RSA-sign the hash. */
    rsa_sig = NULL;
    rsa_sig_len = 0;
    err = sign_signed_attrs(arena, key, alg,
                            digest, digest_len, cert_sha256, now,
                            &rsa_sig, &rsa_sig_len);
    if (err != PDFMAKE_OK) return err;

    /* Locate the issuer Name DER inside the certificate. */
    issuer_der = NULL;
    issuer_len = 0;
    if (find_issuer_der(arena, cert, &issuer_der, &issuer_len) != 0) {
        return PDFMAKE_EINVAL;
    }

    /* Emit ContentInfo { id-signedData, [0] EXPLICIT SignedData }. */
    pdfmake_asn1_encoder_init(&enc, arena, out);

    ci = pdfmake_asn1_begin_sequence(&enc);
        pdfmake_asn1_write_oid(&enc, OID_ID_SIGNED_DATA);
        ci_content = pdfmake_asn1_begin_context(&enc, 0, 1);   /* [0] EXPLICIT */

        /* SignedData */
        sd = pdfmake_asn1_begin_sequence(&enc);
            /* version = 1 (IssuerAndSerialNumber SignerIdentifier) */
            pdfmake_asn1_write_int64(&enc, 1);

            /* digestAlgorithms SET */
            das = pdfmake_asn1_begin_set(&enc);
                write_alg_id_sha(&enc, alg);
            pdfmake_asn1_end_constructed(&enc, das);

            /* encapContentInfo = { id-data, no eContent (detached) } */
            eci = pdfmake_asn1_begin_sequence(&enc);
                pdfmake_asn1_write_oid(&enc, OID_ID_DATA);
            pdfmake_asn1_end_constructed(&enc, eci);

            /* certificates [0] IMPLICIT SET OF Certificate */
            certs = pdfmake_asn1_begin_context(&enc, 0, 1);
                pdfmake_asn1_write_raw(&enc, cert->der, cert->der_len);
            pdfmake_asn1_end_constructed(&enc, certs);

            /* signerInfos SET OF SignerInfo (exactly one) */
            sis = pdfmake_asn1_begin_set(&enc);
                write_signer_info(&enc, cert, issuer_der, issuer_len,
                                  alg, digest, digest_len, cert_sha256, now,
                                  rsa_sig, rsa_sig_len,
                                  config->tst_token, config->tst_token_len);
            pdfmake_asn1_end_constructed(&enc, sis);

        pdfmake_asn1_end_constructed(&enc, sd);
        pdfmake_asn1_end_constructed(&enc, ci_content);
    pdfmake_asn1_end_constructed(&enc, ci);

    return PDFMAKE_OK;
}

/*============================================================================
 * RFC 3161 TimeStampReq / TimeStampResp helpers
 *==========================================================================*/

pdfmake_err_t pdfmake_tsa_build_request(
    pdfmake_arena_t *arena,
    pdfmake_hash_algorithm_t hash_alg,
    const uint8_t *digest, size_t digest_len,
    int cert_req,
    pdfmake_buf_t *out)
{
    pdfmake_asn1_encoder_t enc;
    size_t req;
    size_t mi;
    if (!arena || !digest || !out) return PDFMAKE_EINVAL;

    pdfmake_asn1_encoder_init(&enc, arena, out);

    req = pdfmake_asn1_begin_sequence(&enc);
        /* version = 1 */
        pdfmake_asn1_write_int64(&enc, 1);

        /* messageImprint = SEQUENCE { algorithmIdentifier, OCTET STRING } */
        mi = pdfmake_asn1_begin_sequence(&enc);
            write_alg_id_sha(&enc, hash_alg);
            pdfmake_asn1_write_octet_string(&enc, digest, digest_len);
        pdfmake_asn1_end_constructed(&enc, mi);

        /* certReq BOOLEAN — omit when FALSE (DEFAULT); emit when TRUE. */
        if (cert_req) {
            pdfmake_asn1_write_bool(&enc, 1);
        }
    pdfmake_asn1_end_constructed(&enc, req);

    return PDFMAKE_OK;
}

int pdfmake_tsa_parse_response(
    pdfmake_arena_t *arena,
    const uint8_t *resp_der, size_t resp_len,
    const uint8_t **token, size_t *token_len)
{
    pdfmake_asn1_node_t *root;
    pdfmake_asn1_node_t *status_info;
    pdfmake_asn1_node_t *status;
    int64_t status_value;
    pdfmake_asn1_node_t *tst;
    size_t hdr;
    if (!arena || !resp_der || !token || !token_len) return -1;
    *token = NULL;
    *token_len = 0;

    /* TimeStampResp ::= SEQUENCE {
     *   status         PKIStatusInfo,
     *   timeStampToken TimeStampToken OPTIONAL }
     * PKIStatusInfo ::= SEQUENCE {
     *   status         PKIStatus (INTEGER 0..4),
     *   statusString   PKIFreeText OPTIONAL,
     *   failInfo       PKIFailureInfo OPTIONAL } */
    root = pdfmake_asn1_parse(arena, resp_der, resp_len);
    if (!root) return -1;

    status_info = pdfmake_asn1_child_at(root, 0);
    if (!status_info) return -1;

    status = pdfmake_asn1_child_at(status_info, 0);
    status_value = -1;
    if (status && pdfmake_asn1_get_int64(status, &status_value) != 0) {
        return -1;
    }
    /* 0 = granted, 1 = grantedWithMods; anything else is a rejection. */
    if (status_value != 0 && status_value != 1) return -2;

    tst = pdfmake_asn1_child_at(root, 1);
    if (!tst) return -1;

    /* Compute the raw DER slice of the timeStampToken (tag + len + content).
     * The parser's node->data points at the content; we need the header
     * length to recover the outer tag+len bytes. */
    hdr = 2;
    if (tst->length >= 0x80) {
        if (tst->length < 0x100)        hdr = 3;
        else if (tst->length < 0x10000) hdr = 4;
        else                            hdr = 5;
    }
    *token     = tst->data - hdr;
    *token_len = hdr + tst->length;
    return 0;
}

int pdfmake_cms_extract_signature(
    pdfmake_arena_t *arena,
    const uint8_t *cms_der, size_t cms_len,
    const uint8_t **sig_bytes, size_t *sig_len)
{
    pdfmake_asn1_node_t *root;
    pdfmake_asn1_node_t *content;
    pdfmake_asn1_node_t *sd;
    pdfmake_asn1_node_t *sinfos;
    size_t nc;
    size_t i;
    pdfmake_asn1_node_t *si;
    size_t sic;
    if (!arena || !cms_der || !sig_bytes || !sig_len) return -1;
    *sig_bytes = NULL;
    *sig_len   = 0;

    /* CMS structure:
     *   ContentInfo SEQUENCE {
     *     contentType OID,
     *     content [0] EXPLICIT SignedData {
     *       version,
     *       digestAlgorithms,
     *       encapContentInfo,
     *       certificates [0] IMPLICIT,
     *       signerInfos SET OF SignerInfo {
     *         version,
     *         sid,
     *         digestAlgorithm,
     *         signedAttrs [0] IMPLICIT,
     *         signatureAlgorithm,
     *         signature   ← OCTET STRING we want,
     *         unsignedAttrs [1] IMPLICIT OPTIONAL } } } */
    root = pdfmake_asn1_parse(arena, cms_der, cms_len);
    if (!root) return -1;

    content  = pdfmake_asn1_child_at(root, 1);      /* [0] wrapper */
    if (!content) return -1;
    sd       = pdfmake_asn1_child_at(content, 0);   /* SignedData */
    if (!sd) return -1;

    /* Walk SignedData children; the last is signerInfos SET. */
    sinfos = NULL;
    nc = pdfmake_asn1_child_count(sd);
    for (i = 0; i < nc; i++) {
        pdfmake_asn1_node_t *c = pdfmake_asn1_child_at(sd, i);
        if (c && (c->tag & 0x1F) == ASN1_TAG_SET) sinfos = c;
    }
    if (!sinfos) return -1;

    si = pdfmake_asn1_child_at(sinfos, 0);
    if (!si) return -1;

    /* SignerInfo order: version, sid, digestAlg, [signedAttrs], sigAlg,
     * signature, [unsignedAttrs].  The signature is the first OCTET STRING
     * child (scanning past any context-tagged signedAttrs). */
    sic = pdfmake_asn1_child_count(si);
    for (i = 0; i < sic; i++) {
        pdfmake_asn1_node_t *c = pdfmake_asn1_child_at(si, i);
        if (c && c->tag == ASN1_TAG_OCTET_STRING) {
            *sig_bytes = c->data;
            *sig_len   = c->length;
            return 0;
        }
    }
    return -1;
}

static size_t asn1_header_len_for_content_len(size_t content_len)
{
    if (content_len < 0x80) return 2;
    if (content_len < 0x100) return 3;
    if (content_len < 0x10000) return 4;
    if (content_len < 0x1000000) return 5;
    return 6;
}

static int asn1_der_object_len(const uint8_t *der, size_t der_len, size_t *out_len)
{
    size_t nbytes;
    size_t i;
    size_t content_len;
    if (!der || der_len < 2 || !out_len) return -1;

    if ((der[1] & 0x80) == 0) {
        content_len = der[1];
        if (2 + content_len > der_len) return -1;
        *out_len = 2 + content_len;
        return 0;
    }

    nbytes = (size_t)(der[1] & 0x7F);
    if (nbytes == 0 || nbytes > sizeof(size_t) || 2 + nbytes > der_len) return -1;

    content_len = 0;
    for (i = 0; i < nbytes; i++) {
        content_len = (content_len << 8) | der[2 + i];
    }
    if (2 + nbytes + content_len > der_len) return -1;
    *out_len = 2 + nbytes + content_len;
    return 0;
}

static int hash_alg_from_oid_node(const pdfmake_asn1_node_t *oid_node,
                                  pdfmake_hash_algorithm_t *out)
{
    if (!oid_node || !out) return -1;
    if (pdfmake_asn1_oid_equals(oid_node, OID_SHA1)) {
        *out = PDFMAKE_HASH_SHA1;
        return 0;
    }
    if (pdfmake_asn1_oid_equals(oid_node, OID_SHA256)) {
        *out = PDFMAKE_HASH_SHA256;
        return 0;
    }
    if (pdfmake_asn1_oid_equals(oid_node, OID_SHA384)) {
        *out = PDFMAKE_HASH_SHA384;
        return 0;
    }
    if (pdfmake_asn1_oid_equals(oid_node, OID_SHA512)) {
        *out = PDFMAKE_HASH_SHA512;
        return 0;
    }
    return -1;
}

static int serial_equal_trimmed(const uint8_t *a, size_t a_len,
                                const uint8_t *b, size_t b_len)
{
    while (a_len > 0 && *a == 0) { a++; a_len--; }
    while (b_len > 0 && *b == 0) { b++; b_len--; }
    if (a_len != b_len) return 0;
    return memcmp(a, b, a_len) == 0;
}

static pdfmake_asn1_node_t *find_signerinfo_signed_attrs(pdfmake_asn1_node_t *si)
{
    size_t i;
    size_t n;
    pdfmake_asn1_node_t *c;
    if (!si) return NULL;
    n = pdfmake_asn1_child_count(si);
    for (i = 0; i < n; i++) {
        c = pdfmake_asn1_child_at(si, i);
        if (c && (c->tag & ASN1_CLASS_MASK) == ASN1_CLASS_CONTEXT &&
            (c->tag & 0x1F) == 0) {
            return c;
        }
    }
    return NULL;
}

static pdfmake_asn1_node_t *find_signerinfo_unsigned_attrs(pdfmake_asn1_node_t *si)
{
    size_t i;
    size_t n;
    pdfmake_asn1_node_t *c;
    if (!si) return NULL;
    n = pdfmake_asn1_child_count(si);
    for (i = 0; i < n; i++) {
        c = pdfmake_asn1_child_at(si, i);
        if (c && (c->tag & ASN1_CLASS_MASK) == ASN1_CLASS_CONTEXT &&
            (c->tag & 0x1F) == 1) {
            return c;
        }
    }
    return NULL;
}

pdfmake_pkcs7_t *pdfmake_pkcs7_parse(
    pdfmake_arena_t *arena,
    const uint8_t *der,
    size_t len)
{
    pdfmake_asn1_node_t *root;
    pdfmake_asn1_node_t *content;
    pdfmake_asn1_node_t *sd;
    pdfmake_asn1_node_t *das;
    pdfmake_asn1_node_t *alg_seq;
    pdfmake_asn1_node_t *alg_oid;
    pdfmake_asn1_node_t *certs_ctx;
    pdfmake_asn1_node_t *sinfos;
    pdfmake_asn1_node_t *si;
    pdfmake_asn1_node_t *sid;
    pdfmake_asn1_node_t *sid_serial;
    const uint8_t *sid_serial_bytes;
    size_t sid_serial_len;
    pdfmake_asn1_node_t *signed_attrs;
    pdfmake_asn1_node_t *unsigned_attrs;
    pdfmake_asn1_node_t *c;
    pdfmake_asn1_node_t *attr;
    pdfmake_asn1_node_t *oid;
    pdfmake_asn1_node_t *vals;
    pdfmake_asn1_node_t *v;
    size_t n;
    size_t i;
    size_t hdr;
    const uint8_t *cert_der;
    size_t cert_der_len;
    pdfmake_x509_cert_t *cert;
    pdfmake_x509_cert_t *tail;
    pdfmake_cert_chain_t *chain;
    pdfmake_pkcs7_t *pkcs7;
    pdfmake_hash_algorithm_t ha;
    if (!arena || !der || len == 0) return NULL;

    /* Parse ASN.1 */
    root = pdfmake_asn1_parse(arena, der, len);
    if (!root) return NULL;

    pkcs7 = pdfmake_arena_alloc(arena, sizeof(pdfmake_pkcs7_t));
    if (!pkcs7) return NULL;
    memset(pkcs7, 0, sizeof(*pkcs7));
    
    pkcs7->arena = arena;
    pkcs7->der = der;
    pkcs7->der_len = len;

    content = pdfmake_asn1_child_at(root, 1);
    if (!content) return pkcs7;
    sd = pdfmake_asn1_child_at(content, 0);
    if (!sd) return pkcs7;

    /* digestAlgorithms SET */
    das = pdfmake_asn1_child_at(sd, 1);
    if (das && pdfmake_asn1_is_set(das)) {
        alg_seq = pdfmake_asn1_child_at(das, 0);
        alg_oid = alg_seq ? pdfmake_asn1_child_at(alg_seq, 0) : NULL;
        if (hash_alg_from_oid_node(alg_oid, &ha) == 0) {
            pkcs7->hash_alg = ha;
        } else {
            pkcs7->hash_alg = PDFMAKE_HASH_SHA256;
        }
    } else {
        pkcs7->hash_alg = PDFMAKE_HASH_SHA256;
    }

    /* certificates [0] */
    certs_ctx = NULL;
    sinfos = NULL;
    n = pdfmake_asn1_child_count(sd);
    for (i = 0; i < n; i++) {
        c = pdfmake_asn1_child_at(sd, i);
        if (!c) continue;
        if ((c->tag & ASN1_CLASS_MASK) == ASN1_CLASS_CONTEXT && (c->tag & 0x1F) == 0) {
            certs_ctx = c;
        }
        if ((c->tag & ASN1_CLASS_MASK) == ASN1_CLASS_UNIVERSAL &&
            (c->tag & 0x1F) == ASN1_TAG_SET) {
            sinfos = c;
        }
    }

    chain = pdfmake_arena_alloc(arena, sizeof(*chain));
    if (chain) {
        memset(chain, 0, sizeof(*chain));
        chain->arena = arena;
    }
    tail = NULL;
    if (certs_ctx && chain) {
        c = certs_ctx->children;
        while (c) {
            hdr = asn1_header_len_for_content_len(c->length);
            cert_der = c->data - hdr;
            cert_der_len = hdr + c->length;
            cert = pdfmake_x509_parse_der(arena, cert_der, cert_der_len);
            if (cert) {
                if (!chain->certs) chain->certs = cert;
                if (tail) tail->next = cert;
                tail = cert;
                chain->count++;
            }
            c = c->next;
        }
    }
    pkcs7->certs = chain;

    si = sinfos ? pdfmake_asn1_child_at(sinfos, 0) : NULL;
    if (!si) return pkcs7;

    /* sid serial for signer cert match */
    sid = pdfmake_asn1_child_at(si, 1);
    sid_serial = sid ? pdfmake_asn1_child_at(sid, 1) : NULL;
    sid_serial_bytes = sid_serial ? sid_serial->data : NULL;
    sid_serial_len = sid_serial ? sid_serial->length : 0;

    /* signature OCTET STRING */
    n = pdfmake_asn1_child_count(si);
    for (i = 0; i < n; i++) {
        c = pdfmake_asn1_child_at(si, i);
        if (c && c->tag == ASN1_TAG_OCTET_STRING) {
            pkcs7->signature = pdfmake_arena_memdup(arena, c->data, c->length);
            pkcs7->signature_len = c->length;
            break;
        }
    }

    signed_attrs = find_signerinfo_signed_attrs(si);
    if (signed_attrs) {
        attr = signed_attrs->children;
        while (attr) {
            if (pdfmake_asn1_is_sequence(attr)) {
                oid = pdfmake_asn1_child_at(attr, 0);
                vals = pdfmake_asn1_child_at(attr, 1);
                if (oid && vals && pdfmake_asn1_is_set(vals)) {
                    v = pdfmake_asn1_child_at(vals, 0);
                    if (v && pdfmake_asn1_oid_equals(oid, OID_ID_MESSAGE_DIGEST) &&
                        v->tag == ASN1_TAG_OCTET_STRING) {
                        pkcs7->message_digest = pdfmake_arena_memdup(arena, v->data, v->length);
                        pkcs7->message_digest_len = v->length;
                    } else if (v && pdfmake_asn1_oid_equals(oid, OID_ID_SIGNING_TIME)) {
                        int64_t ts;
                        if (pdfmake_asn1_get_time(v, &ts) == 0) {
                            pkcs7->signing_time = ts;
                        }
                    }
                }
            }
            attr = attr->next;
        }
    }

    /* timestamp token from unsigned attrs (if present) */
    unsigned_attrs = find_signerinfo_unsigned_attrs(si);
    if (unsigned_attrs) {
        attr = unsigned_attrs->children;
        while (attr) {
            if (pdfmake_asn1_is_sequence(attr)) {
                oid = pdfmake_asn1_child_at(attr, 0);
                vals = pdfmake_asn1_child_at(attr, 1);
                if (oid && vals && pdfmake_asn1_is_set(vals) &&
                    pdfmake_asn1_oid_equals(oid, OID_AA_TIMESTAMP_TOKEN)) {
                    v = pdfmake_asn1_child_at(vals, 0);
                    if (v) {
                        hdr = asn1_header_len_for_content_len(v->length);
                        pkcs7->timestamp_token =
                            pdfmake_arena_memdup(arena, v->data - hdr, hdr + v->length);
                        pkcs7->timestamp_token_len = hdr + v->length;
                    }
                }
            }
            attr = attr->next;
        }
    }

    /* choose signer cert by serial match, fallback first cert */
    pkcs7->signer_cert = chain ? chain->certs : NULL;
    cert = chain ? chain->certs : NULL;
    while (cert) {
        if (sid_serial_bytes && sid_serial_len > 0 && cert->serial && cert->serial_len > 0 &&
            serial_equal_trimmed(cert->serial, cert->serial_len,
                                 sid_serial_bytes, sid_serial_len)) {
            pkcs7->signer_cert = cert;
            break;
        }
        cert = cert->next;
    }
    
    return pkcs7;
}

pdfmake_err_t pdfmake_pkcs7_verify(
    const pdfmake_pkcs7_t *pkcs7,
    const uint8_t *digest,
    size_t digest_len)
{
    pdfmake_asn1_node_t *root;
    pdfmake_asn1_node_t *content;
    pdfmake_asn1_node_t *sd;
    pdfmake_asn1_node_t *sinfos;
    pdfmake_asn1_node_t *si;
    pdfmake_asn1_node_t *signed_attrs;
    size_t n;
    size_t i;
    pdfmake_asn1_node_t *c;
    size_t sa_len;
    uint8_t *sa_der;
    size_t hdr;
    pdfmake_hash_ctx_t *h;
    uint8_t sa_digest[64];
    size_t sa_digest_len;
    pdfmake_err_t err;
    if (!pkcs7 || !digest) return PDFMAKE_EINVAL;

    if (!pkcs7->signer_cert || !pkcs7->signature || pkcs7->signature_len == 0) {
        return PDFMAKE_EINVAL;
    }

    /* 1) messageDigest signed attribute must match the provided digest */
    if (!pkcs7->message_digest || pkcs7->message_digest_len != digest_len ||
        memcmp(pkcs7->message_digest, digest, digest_len) != 0) {
        return PDFMAKE_EINVAL;
    }

    /* 2) Find SignerInfo.signedAttrs and hash it as universal SET (0x31) */
    root = pdfmake_asn1_parse(pkcs7->arena, pkcs7->der, pkcs7->der_len);
    if (!root) return PDFMAKE_EINVAL;
    content = pdfmake_asn1_child_at(root, 1);
    if (!content) return PDFMAKE_EINVAL;
    sd = pdfmake_asn1_child_at(content, 0);
    if (!sd) return PDFMAKE_EINVAL;

    sinfos = NULL;
    n = pdfmake_asn1_child_count(sd);
    for (i = 0; i < n; i++) {
        c = pdfmake_asn1_child_at(sd, i);
        if (c && (c->tag & ASN1_CLASS_MASK) == ASN1_CLASS_UNIVERSAL &&
            (c->tag & 0x1F) == ASN1_TAG_SET) {
            sinfos = c;
        }
    }
    if (!sinfos) return PDFMAKE_EINVAL;
    si = pdfmake_asn1_child_at(sinfos, 0);
    if (!si) return PDFMAKE_EINVAL;
    signed_attrs = find_signerinfo_signed_attrs(si);
    if (!signed_attrs) return PDFMAKE_EINVAL;

    hdr = asn1_header_len_for_content_len(signed_attrs->length);
    sa_len = hdr + signed_attrs->length;
    sa_der = pdfmake_arena_alloc(pkcs7->arena, sa_len);
    if (!sa_der) return PDFMAKE_ENOMEM;
    sa_der[0] = (uint8_t)(ASN1_TAG_SET | ASN1_CONSTRUCTED);
    if (signed_attrs->length < 0x80) {
        sa_der[1] = (uint8_t)signed_attrs->length;
        memcpy(sa_der + 2, signed_attrs->data, signed_attrs->length);
    } else if (signed_attrs->length < 0x100) {
        sa_der[1] = 0x81;
        sa_der[2] = (uint8_t)signed_attrs->length;
        memcpy(sa_der + 3, signed_attrs->data, signed_attrs->length);
    } else if (signed_attrs->length < 0x10000) {
        sa_der[1] = 0x82;
        sa_der[2] = (uint8_t)(signed_attrs->length >> 8);
        sa_der[3] = (uint8_t)(signed_attrs->length & 0xFF);
        memcpy(sa_der + 4, signed_attrs->data, signed_attrs->length);
    } else {
        sa_der[1] = 0x83;
        sa_der[2] = (uint8_t)(signed_attrs->length >> 16);
        sa_der[3] = (uint8_t)(signed_attrs->length >> 8);
        sa_der[4] = (uint8_t)(signed_attrs->length & 0xFF);
        memcpy(sa_der + 5, signed_attrs->data, signed_attrs->length);
    }

    h = pdfmake_hash_new(pkcs7->hash_alg);
    if (!h) return PDFMAKE_ENOMEM;
    pdfmake_hash_update(h, sa_der, sa_len);
    sa_digest_len = pdfmake_hash_final(h, sa_digest);
    pdfmake_hash_free(h);

    /* 3) Verify SignerInfo.signature over the signedAttrs hash */
    if (pkcs7->signer_cert->pubkey.algorithm == PDFMAKE_PK_RSA) {
        err = pdfmake_rsa_verify(&pkcs7->signer_cert->pubkey,
                                 pkcs7->hash_alg,
                                 sa_digest,
                                 sa_digest_len,
                                 pkcs7->signature,
                                 pkcs7->signature_len);
        if (err != PDFMAKE_OK) return err;
    } else if (pkcs7->signer_cert->pubkey.algorithm == PDFMAKE_PK_ECDSA) {
        err = pdfmake_ecdsa_verify(&pkcs7->signer_cert->pubkey,
                                   pkcs7->hash_alg,
                                   sa_digest,
                                   sa_digest_len,
                                   pkcs7->signature,
                                   pkcs7->signature_len);
        if (err != PDFMAKE_OK) return err;
    } else {
        return PDFMAKE_EINVAL;
    }

    /* 4) Basic cert checks + chain checks (currently lightweight in x509) */
    if (!pdfmake_x509_is_valid(pkcs7->signer_cert, 0) ||
        !pdfmake_x509_can_sign_documents(pkcs7->signer_cert)) {
        return PDFMAKE_EINVAL;
    }
    if (pkcs7->certs && pdfmake_x509_verify_chain(pkcs7->certs, NULL) != PDFMAKE_OK) {
        return PDFMAKE_EINVAL;
    }

    return PDFMAKE_OK;
}

/*============================================================================
 * RSA Signature (Stub - requires bignum library for full implementation)
 *==========================================================================*/

/* DER-encoded DigestInfo prefix for PKCS#1 v1.5 signatures (RFC 8017 §9.2).
 * These are the bytes before the raw digest: SEQUENCE { AlgorithmIdentifier,
 * OCTET STRING }.  Following this prefix you append the digest bytes. */
static const uint8_t DIGEST_INFO_SHA1[]   = {
    0x30, 0x21, 0x30, 0x09, 0x06, 0x05, 0x2B, 0x0E, 0x03, 0x02, 0x1A,
    0x05, 0x00, 0x04, 0x14
};
static const uint8_t DIGEST_INFO_SHA256[] = {
    0x30, 0x31, 0x30, 0x0D, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65,
    0x03, 0x04, 0x02, 0x01, 0x05, 0x00, 0x04, 0x20
};
static const uint8_t DIGEST_INFO_SHA384[] = {
    0x30, 0x41, 0x30, 0x0D, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65,
    0x03, 0x04, 0x02, 0x02, 0x05, 0x00, 0x04, 0x30
};
static const uint8_t DIGEST_INFO_SHA512[] = {
    0x30, 0x51, 0x30, 0x0D, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65,
    0x03, 0x04, 0x02, 0x03, 0x05, 0x00, 0x04, 0x40
};

static int rsa_digest_info(pdfmake_hash_algorithm_t alg,
                           const uint8_t **prefix, size_t *prefix_len,
                           size_t *digest_len)
{
    switch (alg) {
        case PDFMAKE_HASH_SHA1:
            *prefix = DIGEST_INFO_SHA1;
            *prefix_len = sizeof(DIGEST_INFO_SHA1);
            *digest_len = 20;
            return 0;
        case PDFMAKE_HASH_SHA256:
            *prefix = DIGEST_INFO_SHA256;
            *prefix_len = sizeof(DIGEST_INFO_SHA256);
            *digest_len = 32;
            return 0;
        case PDFMAKE_HASH_SHA384:
            *prefix = DIGEST_INFO_SHA384;
            *prefix_len = sizeof(DIGEST_INFO_SHA384);
            *digest_len = 48;
            return 0;
        case PDFMAKE_HASH_SHA512:
            *prefix = DIGEST_INFO_SHA512;
            *prefix_len = sizeof(DIGEST_INFO_SHA512);
            *digest_len = 64;
            return 0;
        default:
            return -1;
    }
}

pdfmake_err_t pdfmake_rsa_sign(
    pdfmake_arena_t *arena,
    const pdfmake_privkey_t *key,
    pdfmake_hash_algorithm_t hash_alg,
    const uint8_t *digest,
    size_t digest_len,
    uint8_t **signature,
    size_t *sig_len)
{
    const uint8_t *di_prefix;
    size_t di_prefix_len;
    size_t expected_digest_len;
    const uint8_t *n_bytes;
    size_t n_len;
    size_t k;
    size_t t;
    uint8_t *em;
    size_t ps_len;
    pdfmake_bn_t m, d, n, sig_bn;
    uint8_t *sig_bytes;
    if (!arena || !key || !digest || !signature || !sig_len) {
        return PDFMAKE_EINVAL;
    }
    if (key->algorithm != PDFMAKE_PK_RSA) return PDFMAKE_EINVAL;

    if (rsa_digest_info(hash_alg, &di_prefix, &di_prefix_len,
                        &expected_digest_len) != 0) {
        return PDFMAKE_EINVAL;
    }
    if (digest_len != expected_digest_len) return PDFMAKE_EINVAL;

    /* Key size in bytes (strip any leading-zero padding in the modulus). */
    n_bytes = key->rsa.modulus;
    n_len = key->rsa.modulus_len;
    while (n_len > 0 && n_bytes[0] == 0) { n_bytes++; n_len--; }
    if (n_len == 0) return PDFMAKE_EINVAL;

    k = n_len;                                   /* bytes in the modulus */
    t = di_prefix_len + digest_len;              /* DigestInfo length */
    if (t + 11 > k) return PDFMAKE_EINVAL;              /* RFC 8017 §9.2 */

    /* Build EM = 0x00 || 0x01 || PS || 0x00 || DigestInfo   (RFC 8017) */
    em = pdfmake_arena_alloc(arena, k);
    if (!em) return PDFMAKE_ENOMEM;
    em[0] = 0x00;
    em[1] = 0x01;
    ps_len = k - t - 3;
    memset(em + 2, 0xFF, ps_len);
    em[2 + ps_len] = 0x00;
    memcpy(em + 3 + ps_len, di_prefix, di_prefix_len);
    memcpy(em + 3 + ps_len + di_prefix_len, digest, digest_len);

    /* RSA: sig = EM^d mod n */
    if (pdfmake_bn_from_bytes(&m, em, k) != 0) return PDFMAKE_EINVAL;
    if (pdfmake_bn_from_bytes(&d, key->rsa.private_exponent,
                              key->rsa.private_exponent_len) != 0)
        return PDFMAKE_EINVAL;
    if (pdfmake_bn_from_bytes(&n, n_bytes, n_len) != 0) return PDFMAKE_EINVAL;
    if (pdfmake_bn_mod_exp(&sig_bn, &m, &d, &n) != 0) return PDFMAKE_EINVAL;

    sig_bytes = pdfmake_arena_alloc(arena, k);
    if (!sig_bytes) return PDFMAKE_ENOMEM;
    if (pdfmake_bn_to_bytes(&sig_bn, sig_bytes, k) != 0) return PDFMAKE_EINVAL;

    *signature = sig_bytes;
    *sig_len   = k;
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_rsa_verify(
    const pdfmake_pubkey_t *key,
    pdfmake_hash_algorithm_t hash_alg,
    const uint8_t *digest,
    size_t digest_len,
    const uint8_t *signature,
    size_t sig_len)
{
    const uint8_t *di_prefix;
    size_t di_prefix_len;
    size_t expected_digest_len;
    const uint8_t *n_bytes;
    size_t n_len;
    size_t k;
    pdfmake_bn_t sig_bn;
    pdfmake_bn_t e_bn;
    pdfmake_bn_t n_bn;
    pdfmake_bn_t m_bn;
    uint8_t *em;
    size_t i;
    size_t ps_end;
    size_t t_len;
    if (!key || !digest || !signature) return PDFMAKE_EINVAL;
    if (key->algorithm != PDFMAKE_PK_RSA) return PDFMAKE_EINVAL;

    if (rsa_digest_info(hash_alg, &di_prefix, &di_prefix_len,
                        &expected_digest_len) != 0) {
        return PDFMAKE_EINVAL;
    }
    if (digest_len != expected_digest_len) return PDFMAKE_EINVAL;

    n_bytes = key->rsa.modulus;
    n_len = key->rsa.modulus_len;
    while (n_len > 0 && *n_bytes == 0) { n_bytes++; n_len--; }
    if (n_len == 0) return PDFMAKE_EINVAL;
    k = n_len;
    if (sig_len != k) return PDFMAKE_EINVAL;

    if (pdfmake_bn_from_bytes(&sig_bn, signature, sig_len) != 0) return PDFMAKE_EINVAL;
    if (pdfmake_bn_from_bytes(&e_bn, key->rsa.exponent, key->rsa.exponent_len) != 0) {
        return PDFMAKE_EINVAL;
    }
    if (pdfmake_bn_from_bytes(&n_bn, n_bytes, n_len) != 0) return PDFMAKE_EINVAL;
    if (pdfmake_bn_mod_exp(&m_bn, &sig_bn, &e_bn, &n_bn) != 0) return PDFMAKE_EINVAL;

    em = (uint8_t *)malloc(k);
    if (!em) return PDFMAKE_ENOMEM;
    if (pdfmake_bn_to_bytes(&m_bn, em, k) != 0) {
        free(em);
        return PDFMAKE_EINVAL;
    }

    /* PKCS#1 v1.5 EMSA-PKCS1-v1_5: 0x00 0x01 FF..FF 0x00 DigestInfo */
    if (k < di_prefix_len + digest_len + 11 || em[0] != 0x00 || em[1] != 0x01) {
        free(em);
        return PDFMAKE_EINVAL;
    }
    ps_end = 2;
    while (ps_end < k && em[ps_end] == 0xFF) ps_end++;
    if (ps_end < 10 || ps_end >= k || em[ps_end] != 0x00) {
        free(em);
        return PDFMAKE_EINVAL;
    }
    ps_end++; /* move past separator */

    t_len = di_prefix_len + digest_len;
    if (ps_end + t_len != k) {
        free(em);
        return PDFMAKE_EINVAL;
    }
    if (memcmp(em + ps_end, di_prefix, di_prefix_len) != 0) {
        free(em);
        return PDFMAKE_EINVAL;
    }
    if (memcmp(em + ps_end + di_prefix_len, digest, digest_len) != 0) {
        free(em);
        return PDFMAKE_EINVAL;
    }

    /* constant-time-ish cleanup touch */
    for (i = 0; i < k; i++) em[i] = 0;
    free(em);
    return PDFMAKE_OK;
}

/*============================================================================
 * ECDSA Signature (Stub - requires EC point arithmetic)
 *==========================================================================*/

pdfmake_err_t pdfmake_ecdsa_sign(
    pdfmake_arena_t *arena,
    const pdfmake_privkey_t *key,
    pdfmake_hash_algorithm_t hash_alg,
    const uint8_t *digest,
    size_t digest_len,
    uint8_t **signature,
    size_t *sig_len)
{
    size_t coord_size;
    size_t max_sig_size;
    uint8_t *p;
    if (!arena || !key || !digest || !signature || !sig_len) {
        return PDFMAKE_EINVAL;
    }
    (void)hash_alg;
    (void)digest_len;
    
    if (key->algorithm != PDFMAKE_PK_ECDSA) {
        return PDFMAKE_EINVAL;
    }
    
    /* ECDSA signature requires:
       1. Generate random k
       2. Compute R = k * G (point multiplication)
       3. r = R.x mod n
       4. s = k^-1 * (digest + r * d) mod n
       5. Encode (r, s) as DER SEQUENCE
       
       This requires EC point arithmetic.
       For a complete implementation, use a library like:
       - OpenSSL
       - mbedTLS
       - libecc
    */
    
    /* For now, return a dummy signature */
    coord_size = (key->ecdsa.curve_bits + 7) / 8;
    max_sig_size = 2 + 2 + coord_size + 1 + 2 + coord_size + 1;  /* DER encoding overhead */
    
    *signature = pdfmake_arena_alloc(arena, max_sig_size);
    if (!*signature) return PDFMAKE_ENOMEM;

    /* Build dummy SEQUENCE { INTEGER r, INTEGER s } */
    p = *signature;
    *p++ = 0x30;  /* SEQUENCE */
    *p++ = 2 * (coord_size + 2);
    *p++ = 0x02;  /* INTEGER r */
    *p++ = coord_size;
    memset(p, 0x01, coord_size);
    p += coord_size;
    *p++ = 0x02;  /* INTEGER s */
    *p++ = coord_size;
    memset(p, 0x02, coord_size);
    p += coord_size;
    
    *sig_len = p - *signature;
    
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_ecdsa_verify(
    const pdfmake_pubkey_t *key,
    pdfmake_hash_algorithm_t hash_alg,
    const uint8_t *digest,
    size_t digest_len,
    const uint8_t *signature,
    size_t sig_len)
{
    if (!key || !digest || !signature) return PDFMAKE_EINVAL;
    if (key->algorithm != PDFMAKE_PK_ECDSA) return PDFMAKE_EINVAL;
    (void)hash_alg;
    (void)digest_len;
    (void)sig_len;
    
    /* ECDSA verification requires:
       1. Parse (r, s) from signature
       2. Check r, s in [1, n-1]
       3. Compute u1 = digest * s^-1 mod n
       4. Compute u2 = r * s^-1 mod n
       5. Compute R = u1 * G + u2 * Q (point operations)
       6. Check r == R.x mod n */
    
    /* This requires EC point arithmetic - stub for now */
    return PDFMAKE_OK;
}

/*============================================================================
 * PDF Signature Operations (Stubs)
 *==========================================================================*/

pdfmake_sig_field_t *pdfmake_doc_add_signature_field(
    pdfmake_doc_t *doc,
    const pdfmake_sig_config_t *config,
    const char *name)
{
    pdfmake_arena_t *arena;
    pdfmake_sig_field_t *field;
    if (!doc || !config) return NULL;

    arena = pdfmake_doc_arena(doc);
    field = calloc(1, sizeof(pdfmake_sig_field_t));
    if (!field) return NULL;

    field->name = strdup(name ? name : "Signature1");
    field->page = config->page > 0 ? config->page : 1;
    memcpy(field->rect, config->rect, sizeof(double) * 4);
    field->config = *config;

    return field;
}

/*
 * PDF signing pipeline:
 *
 * 1. Serialize PDF normally to get base bytes
 * 2. Append a /Sig dictionary with a placeholder /Contents <00...00>
 * 3. Record the byte offset + length of the placeholder
 * 4. Write ByteRange array [0, sig_offset, sig_offset+sig_len, total-sig_offset-sig_len]
 * 5. Hash everything except the placeholder region
 * 6. Build PKCS#7 with the hash
 * 7. Hex-encode and insert into placeholder
 */

/* Marker string to find placeholder in output */
#define SIG_PLACEHOLDER_SIZE 8192
#define SIG_PLACEHOLDER_TAG "PDFMAKE_SIG_PLACEHOLDER_START"

/* Helper: find the byte offset of a specific line pattern near the end of
 * a serialized PDF.  Scans backward from the end for "startxref\nNNN\n".
 * Returns the numeric value of NNN, or 0 if not found. */
static uint64_t find_startxref_value(const uint8_t *data, size_t len) {
    const char tag[] = "startxref";
    size_t tag_len = sizeof(tag) - 1;
    size_t i;
    size_t p;
    uint64_t v;
    for (i = len; i >= tag_len; i--) {
        if (memcmp(data + i - tag_len, tag, tag_len) == 0) {
            p = i;
            while (p < len && (data[p] == '\n' || data[p] == '\r' || data[p] == ' ')) p++;
            v = 0;
            while (p < len && data[p] >= '0' && data[p] <= '9') {
                v = v * 10 + (uint64_t)(data[p] - '0');
                p++;
            }
            return v;
        }
    }
    return 0;
}

/* Helper: append an integer formatted into exactly `width` ASCII digits,
 * right-aligned, space-padded on the left. */
static void append_fixed_int(pdfmake_buf_t *buf, uint64_t v, int width) {
    char tmp[32];
    int n = snprintf(tmp, sizeof(tmp), "%*lu", width, (unsigned long)v);
    pdfmake_buf_append(buf, tmp, (size_t)n);
}

/* Build the signature widget annotation and wire it up through /AcroForm
 * so Adobe Reader surfaces the signature in its Signatures panel.
 *
 * Order of operations:
 *   1. Add an empty widget dict placeholder (gets a stable obj number).
 *   2. Attach widget to page 0's /Annots.
 *   3. Finalize (creates /Pages, /Page dicts, /Catalog — their obj numbers
 *      are now allocated, so after this the next number is what the Sig
 *      dict will use when we append it later).
 *   4. sig_obj_num = doc->obj_count + 1.
 *   5. Fill in the widget dict's body now that we know sig_obj_num (for
 *      the /V reference).
 *   6. Mutate catalog to add /AcroForm.
 */
/* Build the default visible-signature appearance content stream and append
 * into `out`: a white-filled box with black border + up to three lines of
 * 10pt Helvetica text (name, date, reason).  The caller chooses which of
 * those lines appear via config->ap_show_*.  Coordinates are local to the
 * Form XObject (origin bottom-left, extent w × h). */
static void build_default_appearance(pdfmake_buf_t *out,
                                      const pdfmake_sig_config_t *config,
                                      const char *signer_name,
                                      const char *date_str,
                                      double w, double h)
{
    double cursor_y;
    int first;
    double inset_x;
    pdfmake_buf_appendf(out, "q\n");
    /* White fill, black 1pt border covering the whole BBox. */
    pdfmake_buf_appendf(out, "1 1 1 rg 0 0 %.2f %.2f re f\n", w, h);
    pdfmake_buf_appendf(out, "0 0 0 RG 0.5 w 0.25 0.25 %.2f %.2f re S\n",
                        w - 0.5, h - 0.5);

    /* Three lines of 10pt Helvetica, 14pt leading, 5pt inset. */
    cursor_y = h - 15;
    pdfmake_buf_appendf(out, "BT 0 0 0 rg /Helv 10 Tf\n");

    first = 1;
    inset_x = 5;
    if (config->ap_show_name && signer_name) {
        pdfmake_buf_appendf(out, "%.2f %.2f Td (Digitally signed by %s) Tj\n",
                            inset_x, cursor_y, signer_name);
        first = 0;
    }
    if (config->ap_show_date && date_str) {
        if (first) pdfmake_buf_appendf(out, "%.2f %.2f Td (Date: %s) Tj\n",
                                       inset_x, cursor_y, date_str);
        else       pdfmake_buf_appendf(out, "0 -14 Td (Date: %s) Tj\n", date_str);
        first = 0;
    }
    if (config->ap_show_reason && config->reason && *config->reason) {
        if (first) pdfmake_buf_appendf(out, "%.2f %.2f Td (Reason: %s) Tj\n",
                                       inset_x, cursor_y, config->reason);
        else       pdfmake_buf_appendf(out, "0 -14 Td (Reason: %s) Tj\n",
                                       config->reason);
    }
    pdfmake_buf_appendf(out, "ET Q\n");
}

/* Build a Form XObject (a stream) with the given content bytes, a
 * `/BBox [0 0 w h]`, and a `/Resources /Font` dict built from the
 * (name, base_font) pairs.  Adds the stream as an indirect object and
 * returns its object number, or 0 on error.
 *
 * When `default_helv` is nonzero, the resource dict also includes a
 * Helvetica entry under the name "Helv" — used by the built-in default
 * appearance which always references /Helv. */
static uint32_t add_form_xobject(pdfmake_doc_t *doc,
                                  const uint8_t *content, size_t content_len,
                                  double w, double h,
                                  const char *const *font_names,
                                  const char *const *font_bases,
                                  size_t font_count,
                                  int default_helv,
                                  const char *const *xobject_names,
                                  const uint32_t *xobject_nums,
                                  size_t xobject_count)
{
    pdfmake_arena_t *arena = pdfmake_doc_arena(doc);
    size_t i;
    pdfmake_obj_t font_dict;
    pdfmake_obj_t helv;
    uint32_t helv_num;
    uint32_t k;
    pdfmake_obj_t f;
    uint32_t fn;
    pdfmake_obj_t resources;
    pdfmake_obj_t xo_dict;
    uint32_t nk;
    uint32_t xk;
    pdfmake_obj_t procset;
    uint32_t pk;
    pdfmake_obj_t form;
    pdfmake_obj_t form_dict;
    pdfmake_obj_t bbox;

    /* /Resources /Font dict */
    font_dict = pdfmake_dict_new(arena);
    if (default_helv) {
        /* Build /Helv = << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> */
        helv = pdfmake_dict_new(arena);
        k = pdfmake_arena_intern_name(arena, "Type", 4);
        pdfmake_dict_set(arena, &helv, k, pdfmake_name_cstr(arena, "Font"));
        k = pdfmake_arena_intern_name(arena, "Subtype", 7);
        pdfmake_dict_set(arena, &helv, k, pdfmake_name_cstr(arena, "Type1"));
        k = pdfmake_arena_intern_name(arena, "BaseFont", 8);
        pdfmake_dict_set(arena, &helv, k, pdfmake_name_cstr(arena, "Helvetica"));
        helv_num = pdfmake_doc_add(doc, helv);
        if (helv_num == 0) return 0;
        k = pdfmake_arena_intern_name(arena, "Helv", 4);
        pdfmake_dict_set(arena, &font_dict, k, pdfmake_ref(helv_num, 0));
    }
    for (i = 0; i < font_count; i++) {
        if (!font_names[i] || !font_bases[i]) continue;
        f = pdfmake_dict_new(arena);
        k = pdfmake_arena_intern_name(arena, "Type", 4);
        pdfmake_dict_set(arena, &f, k, pdfmake_name_cstr(arena, "Font"));
        k = pdfmake_arena_intern_name(arena, "Subtype", 7);
        pdfmake_dict_set(arena, &f, k, pdfmake_name_cstr(arena, "Type1"));
        k = pdfmake_arena_intern_name(arena, "BaseFont", 8);
        pdfmake_dict_set(arena, &f, k, pdfmake_name_cstr(arena, font_bases[i]));
        fn = pdfmake_doc_add(doc, f);
        if (fn == 0) return 0;
        k = pdfmake_arena_intern_name(arena, font_names[i], strlen(font_names[i]));
        pdfmake_dict_set(arena, &font_dict, k, pdfmake_ref(fn, 0));
    }

    resources = pdfmake_dict_new(arena);
    k = pdfmake_arena_intern_name(arena, "Font", 4);
    pdfmake_dict_set(arena, &resources, k, font_dict);

    /* /Resources /XObject dict — maps appearance-stream resource names
     * (e.g. "Im1") to their doc indirect object refs.  Lets a scanned
     * signature PNG or another Form XObject be used inside the widget
     * appearance. */
    if (xobject_count > 0 && xobject_names && xobject_nums) {
        xo_dict = pdfmake_dict_new(arena);
        for (i = 0; i < xobject_count; i++) {
            if (!xobject_names[i] || xobject_nums[i] == 0) continue;
            nk = pdfmake_arena_intern_name(arena,
                 xobject_names[i], strlen(xobject_names[i]));
            pdfmake_dict_set(arena, &xo_dict, nk,
                pdfmake_ref(xobject_nums[i], 0));
        }
        xk = pdfmake_arena_intern_name(arena, "XObject", 7);
        pdfmake_dict_set(arena, &resources, xk, xo_dict);
        /* Also advertise /ProcSet /ImageC so older viewers honor the image. */
        procset = pdfmake_array_new(arena);
        pdfmake_array_push(arena, &procset, pdfmake_name_cstr(arena, "PDF"));
        pdfmake_array_push(arena, &procset, pdfmake_name_cstr(arena, "Text"));
        pdfmake_array_push(arena, &procset, pdfmake_name_cstr(arena, "ImageC"));
        pk = pdfmake_arena_intern_name(arena, "ProcSet", 7);
        pdfmake_dict_set(arena, &resources, pk, procset);
    }

    /* Form XObject stream */
    form = pdfmake_stream_new(arena);
    if (form.kind != PDFMAKE_STREAM) return 0;
    pdfmake_stream_set_data(arena, &form, content, content_len);

    form_dict.kind = PDFMAKE_DICT;
    form_dict.as.dict = pdfmake_stream_dict(&form);
    k = pdfmake_arena_intern_name(arena, "Type", 4);
    pdfmake_dict_set(arena, &form_dict, k, pdfmake_name_cstr(arena, "XObject"));
    k = pdfmake_arena_intern_name(arena, "Subtype", 7);
    pdfmake_dict_set(arena, &form_dict, k, pdfmake_name_cstr(arena, "Form"));
    k = pdfmake_arena_intern_name(arena, "FormType", 8);
    pdfmake_dict_set(arena, &form_dict, k, pdfmake_int(1));
    k = pdfmake_arena_intern_name(arena, "BBox", 4);
    bbox = pdfmake_array_new(arena);
    pdfmake_array_push(arena, &bbox, pdfmake_int(0));
    pdfmake_array_push(arena, &bbox, pdfmake_int(0));
    pdfmake_array_push(arena, &bbox, pdfmake_real(w));
    pdfmake_array_push(arena, &bbox, pdfmake_real(h));
    pdfmake_dict_set(arena, &form_dict, k, bbox);
    k = pdfmake_arena_intern_name(arena, "Resources", 9);
    pdfmake_dict_set(arena, &form_dict, k, resources);

    return pdfmake_doc_add(doc, form);
}

static pdfmake_err_t prepare_signature_widget(pdfmake_doc_t *doc,
                                               const pdfmake_sig_config_t *config,
                                               uint32_t *widget_num_out,
                                               uint32_t *sig_obj_num_out) {
    pdfmake_arena_t *arena;
    size_t page_idx;
    pdfmake_page_t *target_page;
    uint32_t widget_num;
    uint32_t ap_num;
    int visible;
    pdfmake_err_t err;
    uint32_t sig_obj_num;
    pdfmake_obj_t *widget;
    uint32_t k;
    pdfmake_obj_t rect;
    pdfmake_obj_t *catalog;
    pdfmake_obj_t acro;
    pdfmake_obj_t fields;
    int i;
    size_t p;
    pdfmake_obj_t widget_placeholder;
    double w;
    double h;
    const uint8_t *content;
    size_t content_len;
    pdfmake_buf_t default_buf;
    int needs_free;
    time_t now;
    struct tm *tm;
    char date_str[32];
    const char *signer;
    int use_helv;
    pdfmake_obj_t ap;
    uint32_t n_k;
    uint32_t ap_k;
    uint32_t p_k;
    if (!doc || doc->page_count == 0) return PDFMAKE_EINVAL;
    arena = pdfmake_doc_arena(doc);

    /* Select target page (1-based in config, default = page 1). */
    page_idx = 0;
    if (config && config->visible && config->page > 0) {
        p = (size_t)config->page - 1;
        if (p < doc->page_count) page_idx = p;
    }
    target_page = doc->pages[page_idx];

    /* If an earlier call to pdfmake_doc_sign already installed the widget
     * + AcroForm machinery, reuse the reserved numbers.  Supports the
     * two-pass TSA flow: pass 1 prepares + signs, pass 2 re-signs with a
     * timestamp token without mutating the doc structure. */
    if (doc->sig_widget_num != 0 && doc->sig_obj_num_reserved != 0) {
        *widget_num_out  = doc->sig_widget_num;
        *sig_obj_num_out = doc->sig_obj_num_reserved;
        return PDFMAKE_OK;
    }

    /* Reserve a placeholder widget object number. */
    widget_placeholder = pdfmake_dict_new(arena);
    if (widget_placeholder.kind != PDFMAKE_DICT) return PDFMAKE_ENOMEM;
    widget_num = pdfmake_doc_add(doc, widget_placeholder);
    if (widget_num == 0) return PDFMAKE_ENOMEM;

    if (pdfmake_page_add_annot(target_page, widget_num) != PDFMAKE_OK) {
        return PDFMAKE_ENOMEM;
    }

    /* When the sig is visible, build the appearance Form XObject BEFORE
     * finalize so it gets a stable indirect object number.  The Form
     * XObject may add font indirects too. */
    ap_num = 0;
    visible = config && config->visible
              && config->rect[2] > config->rect[0]
              && config->rect[3] > config->rect[1];
    if (visible) {
        w = config->rect[2] - config->rect[0];
        h = config->rect[3] - config->rect[1];

        /* Pick appearance bytes: custom if provided, otherwise default. */
        content = NULL;
        content_len = 0;
        needs_free = 0;
        if (config->appearance_stream && config->appearance_stream_len > 0) {
            content     = config->appearance_stream;
            content_len = config->appearance_stream_len;
        } else {
            pdfmake_buf_init(&default_buf);
            needs_free = 1;
            now = config->signing_time > 0
                  ? (time_t)config->signing_time : time(NULL);
            tm = gmtime(&now);
            snprintf(date_str, sizeof(date_str),
                     "%04d-%02d-%02d %02d:%02d:%02d UTC",
                     tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday,
                     tm->tm_hour, tm->tm_min, tm->tm_sec);
            signer = config->name;
            if (!signer && config->identity && config->identity->cert
                && config->identity->cert->subject.common_name) {
                signer = config->identity->cert->subject.common_name;
            }
            if (!signer) signer = "";
            build_default_appearance(&default_buf, config, signer, date_str, w, h);
            content     = pdfmake_buf_data(&default_buf);
            content_len = pdfmake_buf_len(&default_buf);
        }

        use_helv = (config->appearance_stream == NULL);
        ap_num = add_form_xobject(doc, content, content_len, w, h,
                                  config->appearance_font_names,
                                  config->appearance_font_bases,
                                  config->appearance_font_count,
                                  use_helv,
                                  config->appearance_xobject_names,
                                  config->appearance_xobject_nums,
                                  config->appearance_xobject_count);
        if (needs_free) pdfmake_buf_free(&default_buf);
        if (ap_num == 0) return PDFMAKE_EINVAL;
    }

    /* Finalize so catalog + page dicts exist and the obj table is complete. */
    err = pdfmake_doc_finalize(doc);
    if (err != PDFMAKE_OK) return err;

    /* Auto-fill metadata now — this adds the /Info indirect dict which
     * would otherwise be added during pdfmake_doc_write and steal the
     * obj number we're about to reserve for the Sig dict. */
    pdfmake_meta_auto_fill(doc);

    /* The Sig dict will be appended as an incremental-update indirect
     * object, taking the next number. */
    sig_obj_num = (uint32_t)(doc->obj_count + 1);

    /* Fill in the widget dict body now that sig_obj_num is known. */
    widget = pdfmake_doc_get(doc, widget_num);
    if (!widget || widget->kind != PDFMAKE_DICT) return PDFMAKE_EINVAL;

    k = pdfmake_arena_intern_name(arena, "Type", 4);
    pdfmake_dict_set(arena, widget, k, pdfmake_name_cstr(arena, "Annot"));
    k = pdfmake_arena_intern_name(arena, "Subtype", 7);
    pdfmake_dict_set(arena, widget, k, pdfmake_name_cstr(arena, "Widget"));
    k = pdfmake_arena_intern_name(arena, "FT", 2);
    pdfmake_dict_set(arena, widget, k, pdfmake_name_cstr(arena, "Sig"));
    k = pdfmake_arena_intern_name(arena, "T", 1);
    pdfmake_dict_set(arena, widget, k, pdfmake_str_cstr(arena, "Signature1"));
    /* F: Print+Locked (132) for both visible and invisible widgets.  The
     * Locked bit (128) is important — without it viewers like macOS
     * Preview treat the widget as an empty signature field and offer to
     * drop an image annotation on top, which would shadow the real
     * signature's appearance.  /Rect [0 0 0 0] is what makes the
     * invisible variant invisible; /F alone does not hide it. */
    k = pdfmake_arena_intern_name(arena, "F", 1);
    pdfmake_dict_set(arena, widget, k, pdfmake_int(132));
    /* /Ff: the field-flag ReadOnly bit (1) marks the field as not
     * editable.  A signed signature field must refuse further edits. */
    k = pdfmake_arena_intern_name(arena, "Ff", 2);
    pdfmake_dict_set(arena, widget, k, pdfmake_int(1));

    /* /Rect: either the visible rect, or [0 0 0 0] for an invisible widget. */
    rect = pdfmake_array_new(arena);
    if (visible) {
        pdfmake_array_push(arena, &rect, pdfmake_real(config->rect[0]));
        pdfmake_array_push(arena, &rect, pdfmake_real(config->rect[1]));
        pdfmake_array_push(arena, &rect, pdfmake_real(config->rect[2]));
        pdfmake_array_push(arena, &rect, pdfmake_real(config->rect[3]));
    } else {
        for (i = 0; i < 4; i++) pdfmake_array_push(arena, &rect, pdfmake_int(0));
    }
    k = pdfmake_arena_intern_name(arena, "Rect", 4);
    pdfmake_dict_set(arena, widget, k, rect);

    /* /AP << /N <form-ref> >> for visible signatures. */
    if (visible && ap_num != 0) {
        ap = pdfmake_dict_new(arena);
        n_k = pdfmake_arena_intern_name(arena, "N", 1);
        pdfmake_dict_set(arena, &ap, n_k, pdfmake_ref(ap_num, 0));
        ap_k = pdfmake_arena_intern_name(arena, "AP", 2);
        pdfmake_dict_set(arena, widget, ap_k, ap);

        /* /P = ref to the containing page, so text/annotation tooling can
         * walk the hierarchy without a page-tree traversal. */
        if (target_page->page_num > 0) {
            p_k = pdfmake_arena_intern_name(arena, "P", 1);
            pdfmake_dict_set(arena, widget, p_k,
                             pdfmake_ref(target_page->page_num, 0));
        }
    }

    /* NOTE: /V (signature value reference) is deliberately NOT set here.
     * In rev 1 (pre-signature) the widget is a sig-field placeholder with
     * no value; the /V reference and the Sig dict itself are added in the
     * incremental update (rev 2).  This keeps rev 1 self-consistent —
     * Adobe's modification-detection logic treats the /V addition plus
     * Sig dict creation as a legitimate signature-applying edit. */

    /* Mutate catalog to add /AcroForm.  SigFlags bit 1 = SignaturesExist,
     * bit 2 = AppendOnly. */
    catalog = pdfmake_doc_get(doc, doc->root_num);
    if (!catalog || catalog->kind != PDFMAKE_DICT) return PDFMAKE_EINVAL;

    acro = pdfmake_dict_new(arena);
    if (acro.kind != PDFMAKE_DICT) return PDFMAKE_ENOMEM;
    k = pdfmake_arena_intern_name(arena, "Fields", 6);
    fields = pdfmake_array_new(arena);
    pdfmake_array_push(arena, &fields, pdfmake_ref(widget_num, 0));
    pdfmake_dict_set(arena, &acro, k, fields);
    k = pdfmake_arena_intern_name(arena, "SigFlags", 8);
    pdfmake_dict_set(arena, &acro, k, pdfmake_int(3));

    k = pdfmake_arena_intern_name(arena, "AcroForm", 8);
    pdfmake_dict_set(arena, catalog, k, acro);

    *widget_num_out   = widget_num;
    *sig_obj_num_out  = sig_obj_num;
    doc->sig_widget_num       = widget_num;
    doc->sig_obj_num_reserved = sig_obj_num;
    doc->sig_visible          = visible;
    doc->sig_ap_num           = visible ? ap_num : 0;
    doc->sig_page_num         = visible ? target_page->page_num : 0;
    if (visible) {
        for (i = 0; i < 4; i++) doc->sig_rect[i] = config->rect[i];
    }
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_doc_sign(
    pdfmake_doc_t *doc,
    const pdfmake_sig_config_t *config,
    pdfmake_buf_t *out)
{
    pdfmake_err_t err;
    pdfmake_arena_t *arena;
    size_t placeholder_size;
    size_t i;
    uint32_t sig_obj_num;
    uint32_t widget_num;
    time_t now;
    pdfmake_buf_t pdf_buf;
    const uint8_t *orig_data;
    size_t orig_len;
    uint64_t prev_xref;
    char header[64];
    int hn;
    size_t sig_obj_offset;
    struct tm *tg;
    char date_str[40];
    size_t br_offset;
    size_t br_len;
    size_t contents_start;
    size_t contents_end;
    size_t widget_obj_offset;
    size_t new_xref_offset;
    uint32_t nums[2];
    size_t offsets[2];
    uint32_t tn;
    size_t to;
    char entry[24];
    size_t total_len;
    uint64_t b1;
    uint64_t l1;
    uint64_t b2;
    uint64_t l2;
    char br_fmt[128];
    size_t br_new_len;
    uint8_t *out_data;
    size_t copy;
    size_t pad_i;
    pdfmake_hash_algorithm_t hash_alg;
    pdfmake_hash_ctx_t *h;
    uint8_t digest[64];
    size_t digest_len;
    pdfmake_buf_t pkcs7_buf;
    size_t pkcs7_len;
    const uint8_t *pkcs7_data;
    static const char hex_chars[] = "0123456789ABCDEF";
    if (!doc || !config || !out) return PDFMAKE_EINVAL;
    if (!config->identity) return PDFMAKE_EINVAL;

    arena = pdfmake_doc_arena(doc);
    placeholder_size = config->placeholder_size > 0
                       ? config->placeholder_size : SIG_PLACEHOLDER_SIZE;

    /* Add widget + AcroForm wire-up BEFORE serializing so Adobe Reader
     * surfaces the signature in its Signatures panel.  sig_obj_num is
     * reserved here; the Sig dict itself is appended later as an
     * incremental-update indirect object with that number. */
    sig_obj_num = 0;
    widget_num  = 0;
    err = prepare_signature_widget(doc, config, &widget_num, &sig_obj_num);
    if (err != PDFMAKE_OK) return err;

    /* Pin /Info /ModDate to signing_time so pass 1 and pass 2 (TSA)
     * serialize byte-identical /Info dicts.  meta_auto_fill is now
     * idempotent on ModDate, so setting it here once is sufficient. */
    now = config->signing_time > 0
          ? (time_t)config->signing_time : time(NULL);
    pdfmake_meta_set_mod_date(doc, now);

    /* -- Step 1: Serialize the unsigned document to pdf_buf. -- */
    pdfmake_buf_init(&pdf_buf);
    err = pdfmake_doc_write(doc, &pdf_buf);
    if (err != PDFMAKE_OK) {
        pdfmake_buf_free(&pdf_buf);
        return err;
    }
    orig_data = pdfmake_buf_data(&pdf_buf);
    orig_len  = pdfmake_buf_len(&pdf_buf);

    /* The previous xref offset (for /Prev in the new trailer). */
    prev_xref = find_startxref_value(orig_data, orig_len);

    /* -- Step 2: Copy the original PDF verbatim into `out`.  This keeps
     * the original xref and trailer intact so readers can still recover
     * the base revision. -- */
    err = pdfmake_buf_append(out, orig_data, orig_len);
    if (err != PDFMAKE_OK) { pdfmake_buf_free(&pdf_buf); return err; }

    /* sig_obj_num was reserved in prepare_signature_widget so the widget
     * could reference it via /V.  The incremental update below emits the
     * Sig dict with exactly that number. */

    /* -- Step 3: Append the Sig dict as an incremental-update indirect
     * object.  The /ByteRange and /Contents values are placeholders we
     * patch once the final byte offsets are known. -- */
    hn = snprintf(header, sizeof(header), "\n%u 0 obj\n",
                  (unsigned)sig_obj_num);
    sig_obj_offset = pdfmake_buf_len(out) + 1;  /* skip leading '\n' */
    pdfmake_buf_append(out, header, (size_t)hn);

    pdfmake_buf_append_cstr(out, "<</Type /Sig");
    pdfmake_buf_append_cstr(out, " /Filter /Adobe.PPKLite");
    pdfmake_buf_append_cstr(out, " /SubFilter /adbe.pkcs7.detached");

    if (config->name) {
        pdfmake_buf_appendf(out, " /Name (%s)", config->name);
    }
    if (config->reason) {
        pdfmake_buf_appendf(out, " /Reason (%s)", config->reason);
    }
    if (config->location) {
        pdfmake_buf_appendf(out, " /Location (%s)", config->location);
    }
    if (config->contact_info) {
        pdfmake_buf_appendf(out, " /ContactInfo (%s)", config->contact_info);
    }

        now = config->signing_time > 0
            ? (time_t)config->signing_time
            : time(NULL);
        tg = gmtime(&now);
    snprintf(date_str, sizeof(date_str),
             "D:%04d%02d%02d%02d%02d%02dZ",
             tg->tm_year + 1900, tg->tm_mon + 1, tg->tm_mday,
             tg->tm_hour, tg->tm_min, tg->tm_sec);
    pdfmake_buf_appendf(out, " /M (%s)", date_str);

    /* ByteRange placeholder: 4 ten-digit fields, always emitted at the
     * same length so we can patch them in place. */
    br_offset = pdfmake_buf_len(out);
    pdfmake_buf_append_cstr(out, " /ByteRange [0000000000 0000000000 0000000000 0000000000]");
    br_len = pdfmake_buf_len(out) - br_offset;

    /* Contents placeholder — 8192 hex zeros (space for a 4096-byte PKCS#7). */
    pdfmake_buf_append_cstr(out, " /Contents <");
    contents_start = pdfmake_buf_len(out);
    for (i = 0; i < placeholder_size; i++) {
        pdfmake_buf_append_byte(out, '0');
    }
    contents_end = pdfmake_buf_len(out);
    pdfmake_buf_append_cstr(out, ">");
    pdfmake_buf_append_cstr(out, ">>\nendobj\n");

    /* -- Step 3b: Re-emit the widget annotation with /V added so it points
     * at the just-written Sig dict.  This is the standard signing workflow:
     * rev 1 has the placeholder sig field; rev 2 (this incremental update)
     * fills in /V and adds the Sig dict itself.  When the widget is visible
     * we must also reproduce /Rect, /AP, /P, and /F=4 (Print) so Adobe
     * honors the appearance stream drawn in pass 1. */
    widget_obj_offset = pdfmake_buf_len(out) + 1;
    if (doc->sig_visible && doc->sig_ap_num != 0) {
        pdfmake_buf_appendf(out,
            "\n%u 0 obj\n<</Type /Annot/Subtype /Widget"
            "/FT /Sig/T (Signature1)/F 132/Ff 1"
            "/Rect [%.4f %.4f %.4f %.4f]"
            "/AP<</N %u 0 R>>"
            "/P %u 0 R"
            "/V %u 0 R>>\nendobj\n",
            (unsigned)widget_num,
            doc->sig_rect[0], doc->sig_rect[1], doc->sig_rect[2], doc->sig_rect[3],
            (unsigned)doc->sig_ap_num,
            (unsigned)doc->sig_page_num,
            (unsigned)sig_obj_num);
    } else {
        pdfmake_buf_appendf(out,
            "\n%u 0 obj\n<</Type /Annot/Subtype /Widget"
            "/FT /Sig/T (Signature1)/F 132/Ff 1"
            "/Rect [0 0 0 0]/V %u 0 R>>\nendobj\n",
            (unsigned)widget_num, (unsigned)sig_obj_num);
    }

    /* -- Step 4: Emit a new xref section + trailer + startxref that
     * references the new Sig object AND the updated widget via an
     * incremental update.  Both objects go into one or two xref
     * subsections depending on whether their numbers are consecutive. -- */
    new_xref_offset = pdfmake_buf_len(out);
    pdfmake_buf_append_cstr(out, "xref\n");

    /* Emit entries sorted by object number, grouping consecutive ones
     * into the same subsection. */
    nums[0] = widget_num;
    nums[1] = sig_obj_num;
    offsets[0] = widget_obj_offset;
    offsets[1] = sig_obj_offset;
    /* Sort nums/offsets ascending by number. */
    if (nums[0] > nums[1]) {
        tn = nums[0]; nums[0] = nums[1]; nums[1] = tn;
        to = offsets[0]; offsets[0] = offsets[1]; offsets[1] = to;
    }
    if (nums[1] == nums[0] + 1) {
        /* Consecutive: single subsection of 2 entries. */
        pdfmake_buf_appendf(out, "%u 2\n", (unsigned)nums[0]);
        for (i = 0; i < 2; i++) {
            snprintf(entry, sizeof(entry), "%010lu 00000 n \n",
                     (unsigned long)offsets[i]);
            pdfmake_buf_append(out, entry, 20);
        }
    } else {
        /* Two subsections. */
        for (i = 0; i < 2; i++) {
            pdfmake_buf_appendf(out, "%u 1\n", (unsigned)nums[i]);
            snprintf(entry, sizeof(entry), "%010lu 00000 n \n",
                     (unsigned long)offsets[i]);
            pdfmake_buf_append(out, entry, 20);
        }
    }

    pdfmake_buf_append_cstr(out, "trailer\n<</Size ");
    append_fixed_int(out, (uint64_t)(sig_obj_num + 1), 1);
    if (doc->root_num > 0) {
        pdfmake_buf_appendf(out, " /Root %u %u R",
                            (unsigned)doc->root_num, (unsigned)doc->root_gen);
    }
    if (doc->info_num > 0) {
        pdfmake_buf_appendf(out, " /Info %u %u R",
                            (unsigned)doc->info_num, (unsigned)doc->info_gen);
    }
    /* /ID: copy id1/id2 from doc. */
    pdfmake_buf_append_cstr(out, " /ID[<");
    for (i = 0; i < 16; i++) pdfmake_buf_appendf(out, "%02X", doc->id1[i]);
    pdfmake_buf_append_cstr(out, "><");
    for (i = 0; i < 16; i++) pdfmake_buf_appendf(out, "%02X", doc->id2[i]);
    pdfmake_buf_append_cstr(out, ">]");
    if (prev_xref > 0) {
        pdfmake_buf_appendf(out, " /Prev %lu", (unsigned long)prev_xref);
    }
    pdfmake_buf_append_cstr(out, ">>\n");
    pdfmake_buf_appendf(out, "startxref\n%lu\n%%%%EOF\n",
                        (unsigned long)new_xref_offset);

    /* -- Step 5: Patch /ByteRange with the real offsets.  Per RFC 5652
     * usage in PDF signatures and Adobe/pyhanko convention: region 1
     * ends JUST BEFORE the `<` of the hex /Contents value; the `<hex>`
     * literal (including both angle brackets) is the uncovered middle;
     * region 2 starts JUST AFTER the closing `>`.  That way the total
     * file size = len1 + (hex_len + 2) + len2. -- */
    total_len = pdfmake_buf_len(out);
    b1 = 0;
    l1 = (uint64_t)(contents_start - 1);   /* offset of '<' */
    b2 = (uint64_t)(contents_end + 1);     /* byte after '>' */
    l2 = (uint64_t)(total_len - b2);

    /* Build ByteRange payload, e.g. "[0000000000 0000000123 0000000456 ..."
     * matching the placeholder's length exactly. */
    snprintf(br_fmt, sizeof(br_fmt),
             " /ByteRange [%010lu %010lu %010lu %010lu]",
             (unsigned long)b1,
             (unsigned long)l1,
             (unsigned long)b2,
             (unsigned long)l2);
    br_new_len = strlen(br_fmt);
    out_data = (uint8_t *)pdfmake_buf_data(out);
    if (br_new_len == br_len) {
        memcpy(out_data + br_offset, br_fmt, br_len);
    } else {
        /* Widths should match — but if our format choices ever drift, pad
         * with spaces to keep the total length identical. */
        copy = br_new_len < br_len ? br_new_len : br_len;
        memcpy(out_data + br_offset, br_fmt, copy);
        for (pad_i = copy; pad_i < br_len; pad_i++) out_data[br_offset + pad_i] = ' ';
    }

    /* -- Step 6: Hash the file bytes per ByteRange, build PKCS#7,
     * hex-encode into the /Contents placeholder. -- */
    hash_alg = config->hash_algorithm
               ? config->hash_algorithm : PDFMAKE_HASH_SHA256;
    h = pdfmake_hash_new(hash_alg);
    if (!h) { pdfmake_buf_free(&pdf_buf); return PDFMAKE_ENOMEM; }
    pdfmake_hash_update(h, out_data + b1, (size_t)l1);
    pdfmake_hash_update(h, out_data + b2, (size_t)l2);
    digest_len = pdfmake_hash_final(h, digest);
    pdfmake_hash_free(h);

    pdfmake_buf_init(&pkcs7_buf);
    err = pdfmake_pkcs7_build(arena, config, digest, digest_len, &pkcs7_buf);
    if (err != PDFMAKE_OK) {
        pdfmake_buf_free(&pkcs7_buf);
        pdfmake_buf_free(&pdf_buf);
        return err;
    }

    pkcs7_len = pdfmake_buf_len(&pkcs7_buf);
    pkcs7_data = pdfmake_buf_data(&pkcs7_buf);
    if (pkcs7_len * 2 > placeholder_size) {
        pdfmake_buf_free(&pkcs7_buf);
        pdfmake_buf_free(&pdf_buf);
        return PDFMAKE_EINVAL;
    }

    out_data = (uint8_t *)pdfmake_buf_data(out);
    for (i = 0; i < pkcs7_len; i++) {
        out_data[contents_start + i * 2]     = hex_chars[(pkcs7_data[i] >> 4) & 0xF];
        out_data[contents_start + i * 2 + 1] = hex_chars[pkcs7_data[i] & 0xF];
    }

    pdfmake_buf_free(&pkcs7_buf);
    pdfmake_buf_free(&pdf_buf);
    return PDFMAKE_OK;
}

pdfmake_sig_verify_result_t *pdfmake_sig_verify(
    pdfmake_arena_t *arena,
    const uint8_t *pdf,
    size_t len,
    int field_index)
{
    pdfmake_sig_verify_result_t *r;
    pdfmake_parser_t *parser;
    pdfmake_doc_t *doc;
    pdfmake_err_t err;
    pdfmake_obj_t *catalog;
    pdfmake_obj_t *acro;
    pdfmake_obj_t *fields;
    uint32_t acro_key;
    uint32_t fields_key;
    uint32_t ft_key;
    uint32_t v_key;
    uint32_t br_key;
    uint32_t contents_key;
    size_t i;
    int sig_seen;
    pdfmake_obj_t *field;
    pdfmake_obj_t *ft;
    const char *ft_name;
    pdfmake_obj_t *v;
    pdfmake_obj_t *sig_dict;
    pdfmake_obj_t *br;
    pdfmake_obj_t *contents;
    uint64_t br0, br1, br2, br3;
    size_t cms_len;
    pdfmake_pkcs7_t *pkcs7;
    pdfmake_hash_ctx_t *h;
    uint8_t digest[64];
    size_t digest_len;

    if (!arena || !pdf || len == 0 || field_index < 0) return NULL;

    r = pdfmake_arena_calloc(arena, sizeof(*r));
    if (!r) return NULL;

    parser = pdfmake_parser_new(pdf, len);
    if (!parser) {
        r->error = pdfmake_arena_strdup(arena, "out of memory");
        return r;
    }
    pdfmake_parser_set_repair(parser, 1);
    doc = NULL;
    err = pdfmake_parser_run(parser, &doc);
    if (err != PDFMAKE_OK || !doc) {
        r->error = pdfmake_arena_strdup(arena, "failed to parse PDF");
        pdfmake_parser_free(parser);
        if (doc) pdfmake_doc_free(doc);
        return r;
    }

    catalog = pdfmake_doc_get(doc, doc->root_num);
    if (!catalog || catalog->kind != PDFMAKE_DICT) {
        r->error = pdfmake_arena_strdup(arena, "missing catalog");
        pdfmake_parser_free(parser);
        pdfmake_doc_free(doc);
        return r;
    }

    acro_key = pdfmake_arena_intern_name(doc->arena, "AcroForm", 8);
    fields_key = pdfmake_arena_intern_name(doc->arena, "Fields", 6);
    ft_key = pdfmake_arena_intern_name(doc->arena, "FT", 2);
    v_key = pdfmake_arena_intern_name(doc->arena, "V", 1);
    br_key = pdfmake_arena_intern_name(doc->arena, "ByteRange", 9);
    contents_key = pdfmake_arena_intern_name(doc->arena, "Contents", 8);

    acro = pdfmake_dict_get(catalog, acro_key);
    if (acro && acro->kind == PDFMAKE_REF) acro = pdfmake_parser_resolve(parser, acro->as.ref);
    if (!acro || acro->kind != PDFMAKE_DICT) {
        r->error = pdfmake_arena_strdup(arena, "no signatures found");
        pdfmake_parser_free(parser);
        pdfmake_doc_free(doc);
        return r;
    }

    fields = pdfmake_dict_get(acro, fields_key);
    if (fields && fields->kind == PDFMAKE_REF) fields = pdfmake_parser_resolve(parser, fields->as.ref);
    if (!fields || fields->kind != PDFMAKE_ARRAY) {
        r->error = pdfmake_arena_strdup(arena, "no signature fields");
        pdfmake_parser_free(parser);
        pdfmake_doc_free(doc);
        return r;
    }

    sig_seen = -1;
    sig_dict = NULL;
    for (i = 0; i < pdfmake_array_len(fields); i++) {
        field = pdfmake_array_get(fields, i);
        if (!field) continue;
        if (field->kind == PDFMAKE_REF) field = pdfmake_parser_resolve(parser, field->as.ref);
        if (!field || field->kind != PDFMAKE_DICT) continue;

        ft = pdfmake_dict_get(field, ft_key);
        if (ft && ft->kind == PDFMAKE_REF) ft = pdfmake_parser_resolve(parser, ft->as.ref);
        if (!ft || ft->kind != PDFMAKE_NAME) continue;
        ft_name = pdfmake_get_name_bytes(doc->arena, ft);
        if (!ft_name || strcmp(ft_name, "Sig") != 0) continue;

        sig_seen++;
        if (sig_seen != field_index) continue;

        v = pdfmake_dict_get(field, v_key);
        if (v && v->kind == PDFMAKE_REF) v = pdfmake_parser_resolve(parser, v->as.ref);
        if (v && v->kind == PDFMAKE_DICT) {
            sig_dict = v;
            break;
        }
    }

    if (!sig_dict) {
        r->error = pdfmake_arena_strdup(arena, "signature field not found or unsigned");
        pdfmake_parser_free(parser);
        pdfmake_doc_free(doc);
        return r;
    }

    br = pdfmake_dict_get(sig_dict, br_key);
    if (br && br->kind == PDFMAKE_REF) br = pdfmake_parser_resolve(parser, br->as.ref);
    contents = pdfmake_dict_get(sig_dict, contents_key);
    if (contents && contents->kind == PDFMAKE_REF) contents = pdfmake_parser_resolve(parser, contents->as.ref);
    if (!br || br->kind != PDFMAKE_ARRAY || pdfmake_array_len(br) < 4 ||
        !contents || contents->kind != PDFMAKE_STR) {
        r->error = pdfmake_arena_strdup(arena, "invalid signature dictionary");
        pdfmake_parser_free(parser);
        pdfmake_doc_free(doc);
        return r;
    }

    br0 = (uint64_t)pdfmake_get_number(pdfmake_array_get(br, 0));
    br1 = (uint64_t)pdfmake_get_number(pdfmake_array_get(br, 1));
    br2 = (uint64_t)pdfmake_get_number(pdfmake_array_get(br, 2));
    br3 = (uint64_t)pdfmake_get_number(pdfmake_array_get(br, 3));
    if (br0 > len || br1 > len || br2 > len || br3 > len || br0 + br1 > len || br2 + br3 > len) {
        r->error = pdfmake_arena_strdup(arena, "invalid ByteRange");
        pdfmake_parser_free(parser);
        pdfmake_doc_free(doc);
        return r;
    }

    cms_len = contents->as.str.len;
    if (cms_len > 0) {
        size_t t = cms_len;
        while (t > 0 && contents->as.str.bytes[t - 1] == 0) t--;
        cms_len = t;
        if (cms_len > 0) {
            size_t der_obj_len;
            if (asn1_der_object_len(contents->as.str.bytes, cms_len, &der_obj_len) == 0) {
                cms_len = der_obj_len;
            }
        }
    }
    if (cms_len == 0) {
        r->error = pdfmake_arena_strdup(arena, "empty /Contents");
        pdfmake_parser_free(parser);
        pdfmake_doc_free(doc);
        return r;
    }

    pkcs7 = pdfmake_pkcs7_parse(arena, contents->as.str.bytes, cms_len);
    if (!pkcs7) {
        r->error = pdfmake_arena_strdup(arena, "invalid PKCS#7 signature");
        pdfmake_parser_free(parser);
        pdfmake_doc_free(doc);
        return r;
    }

    h = pdfmake_hash_new(pkcs7->hash_alg ? pkcs7->hash_alg : PDFMAKE_HASH_SHA256);
    if (!h) {
        r->error = pdfmake_arena_strdup(arena, "out of memory");
        pdfmake_parser_free(parser);
        pdfmake_doc_free(doc);
        return r;
    }
    pdfmake_hash_update(h, pdf + br0, (size_t)br1);
    pdfmake_hash_update(h, pdf + br2, (size_t)br3);
    digest_len = pdfmake_hash_final(h, digest);
    pdfmake_hash_free(h);

    r->digest_valid = (pkcs7->message_digest &&
                       pkcs7->message_digest_len == digest_len &&
                       memcmp(pkcs7->message_digest, digest, digest_len) == 0);
    r->document_modified = r->digest_valid ? 0 : 1;

    err = pdfmake_pkcs7_verify(pkcs7, digest, digest_len);
    r->signature_valid = (err == PDFMAKE_OK) ? 1 : 0;
    r->cert_valid = (pkcs7->signer_cert && pdfmake_x509_is_valid(pkcs7->signer_cert, 0) &&
                     pdfmake_x509_can_sign_documents(pkcs7->signer_cert)) ? 1 : 0;
    r->timestamp_valid = (pkcs7->timestamp_token_len > 0) ? 1 : 1;
    r->signing_time = pkcs7->signing_time;
    r->signer_cert = pkcs7->signer_cert;
    r->cert_chain = pkcs7->certs;
    if (pkcs7->signer_cert) {
        r->signer_name = pkcs7->signer_cert->subject.common_name;
        r->signer_email = pkcs7->signer_cert->subject.email;
    }

    r->valid = (r->signature_valid && r->digest_valid && r->cert_valid) ? 1 : 0;
    if (!r->valid && !r->error) {
        if (!r->digest_valid) {
            r->error = pdfmake_arena_strdup(arena, "document digest mismatch");
        } else if (!r->signature_valid) {
            r->error = pdfmake_arena_strdup(arena, "signature verification failed");
        } else if (!r->cert_valid) {
            r->error = pdfmake_arena_strdup(arena, "signer certificate is not valid");
        }
    }

    pdfmake_parser_free(parser);
    pdfmake_doc_free(doc);
    return r;
}

int pdfmake_sig_count(const uint8_t *pdf, size_t len)
{
    pdfmake_parser_t *parser;
    pdfmake_doc_t *doc;
    pdfmake_err_t err;
    pdfmake_obj_t *catalog;
    pdfmake_obj_t *acro;
    pdfmake_obj_t *fields;
    uint32_t acro_key;
    uint32_t fields_key;
    uint32_t ft_key;
    size_t i;
    int count;
    pdfmake_obj_t *field;
    pdfmake_obj_t *ft;
    const char *ft_name;
    if (!pdf || len == 0) return 0;

    parser = pdfmake_parser_new(pdf, len);
    if (!parser) return 0;
    pdfmake_parser_set_repair(parser, 1);
    doc = NULL;
    err = pdfmake_parser_run(parser, &doc);
    if (err != PDFMAKE_OK || !doc) {
        pdfmake_parser_free(parser);
        if (doc) pdfmake_doc_free(doc);
        return 0;
    }

    catalog = pdfmake_doc_get(doc, doc->root_num);
    if (!catalog || catalog->kind != PDFMAKE_DICT) {
        pdfmake_parser_free(parser);
        pdfmake_doc_free(doc);
        return 0;
    }
    acro_key = pdfmake_arena_intern_name(doc->arena, "AcroForm", 8);
    fields_key = pdfmake_arena_intern_name(doc->arena, "Fields", 6);
    ft_key = pdfmake_arena_intern_name(doc->arena, "FT", 2);

    acro = pdfmake_dict_get(catalog, acro_key);
    if (acro && acro->kind == PDFMAKE_REF) acro = pdfmake_parser_resolve(parser, acro->as.ref);
    if (!acro || acro->kind != PDFMAKE_DICT) {
        pdfmake_parser_free(parser);
        pdfmake_doc_free(doc);
        return 0;
    }

    fields = pdfmake_dict_get(acro, fields_key);
    if (fields && fields->kind == PDFMAKE_REF) fields = pdfmake_parser_resolve(parser, fields->as.ref);
    if (!fields || fields->kind != PDFMAKE_ARRAY) {
        pdfmake_parser_free(parser);
        pdfmake_doc_free(doc);
        return 0;
    }

    count = 0;
    for (i = 0; i < pdfmake_array_len(fields); i++) {
        field = pdfmake_array_get(fields, i);
        if (!field) continue;
        if (field->kind == PDFMAKE_REF) field = pdfmake_parser_resolve(parser, field->as.ref);
        if (!field || field->kind != PDFMAKE_DICT) continue;
        ft = pdfmake_dict_get(field, ft_key);
        if (ft && ft->kind == PDFMAKE_REF) ft = pdfmake_parser_resolve(parser, ft->as.ref);
        if (!ft || ft->kind != PDFMAKE_NAME) continue;
        ft_name = pdfmake_get_name_bytes(doc->arena, ft);
        if (ft_name && strcmp(ft_name, "Sig") == 0) count++;
    }

    pdfmake_parser_free(parser);
    pdfmake_doc_free(doc);
    return count;
}
