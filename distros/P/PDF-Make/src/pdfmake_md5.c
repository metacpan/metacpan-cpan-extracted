/*
 * pdfmake_md5.c — MD5 hash implementation
 *
 * Reference implementation per RFC 1321.
 * Required for PDF encryption key derivation (R2-R4).
 */

#include "pdfmake_md5.h"
#include <string.h>

/*============================================================================
 * MD5 constants
 *==========================================================================*/

/* Initial hash values */
#define MD5_A0 0x67452301
#define MD5_B0 0xefcdab89
#define MD5_C0 0x98badcfe
#define MD5_D0 0x10325476

/* Per-round shift amounts */
static const uint8_t S[64] = {
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
    5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20,
    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
};

/* Pre-computed K values: floor(2^32 * abs(sin(i+1))) */
static const uint32_t K[64] = {
    0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
    0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
    0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
    0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
    0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
    0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
    0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
    0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
    0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
    0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
    0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
    0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
    0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
    0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
    0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
    0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
};

/*============================================================================
 * Helper macros
 *==========================================================================*/

#define ROTL32(x, n) (((x) << (n)) | ((x) >> (32 - (n))))

#define F(x, y, z) (((x) & (y)) | ((~(x)) & (z)))
#define G(x, y, z) (((x) & (z)) | ((y) & (~(z))))
#define H(x, y, z) ((x) ^ (y) ^ (z))
#define I(x, y, z) ((y) ^ ((x) | (~(z))))

static PDFMAKE_INLINE uint32_t read_le32(const uint8_t *p)
{
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) |
           ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

static PDFMAKE_INLINE void write_le32(uint8_t *p, uint32_t x)
{
    p[0] = (uint8_t)(x);
    p[1] = (uint8_t)(x >> 8);
    p[2] = (uint8_t)(x >> 16);
    p[3] = (uint8_t)(x >> 24);
}

static PDFMAKE_INLINE void write_le64(uint8_t *p, uint64_t x)
{
    p[0] = (uint8_t)(x);
    p[1] = (uint8_t)(x >> 8);
    p[2] = (uint8_t)(x >> 16);
    p[3] = (uint8_t)(x >> 24);
    p[4] = (uint8_t)(x >> 32);
    p[5] = (uint8_t)(x >> 40);
    p[6] = (uint8_t)(x >> 48);
    p[7] = (uint8_t)(x >> 56);
}

/*============================================================================
 * MD5 transform (process one 64-byte block)
 *==========================================================================*/

static void md5_transform(uint32_t state[4], const uint8_t block[64])
{
    uint32_t a = state[0];
    uint32_t b = state[1];
    uint32_t c = state[2];
    uint32_t d = state[3];
    uint32_t M[16];
    int i;

    /* Decode 64 bytes into 16 little-endian 32-bit words */
    for (i = 0; i < 16; i++) {
        M[i] = read_le32(block + i * 4);
    }

    /* 64 rounds */
    for (i = 0; i < 64; i++) {
        uint32_t f, g;

        if (i < 16) {
            f = F(b, c, d);
            g = i;
        } else if (i < 32) {
            f = G(b, c, d);
            g = (5 * i + 1) % 16;
        } else if (i < 48) {
            f = H(b, c, d);
            g = (3 * i + 5) % 16;
        } else {
            f = I(b, c, d);
            g = (7 * i) % 16;
        }

        f = f + a + K[i] + M[g];
        a = d;
        d = c;
        c = b;
        b = b + ROTL32(f, S[i]);
    }

    state[0] += a;
    state[1] += b;
    state[2] += c;
    state[3] += d;
}

/*============================================================================
 * Public API
 *==========================================================================*/

void pdfmake_md5_init(pdfmake_md5_ctx_t *ctx)
{
    ctx->state[0] = MD5_A0;
    ctx->state[1] = MD5_B0;
    ctx->state[2] = MD5_C0;
    ctx->state[3] = MD5_D0;
    ctx->count = 0;
    memset(ctx->buffer, 0, sizeof(ctx->buffer));
}

void pdfmake_md5_update(pdfmake_md5_ctx_t *ctx, const uint8_t *data, size_t len)
{
    size_t buf_pos = (ctx->count / 8) % 64;
    ctx->count += (uint64_t)len * 8;
    
    /* If we have buffered data and new data fills the buffer */
    if (buf_pos > 0) {
        size_t space = 64 - buf_pos;
        if (len >= space) {
            memcpy(ctx->buffer + buf_pos, data, space);
            md5_transform(ctx->state, ctx->buffer);
            data += space;
            len -= space;
            buf_pos = 0;
        } else {
            memcpy(ctx->buffer + buf_pos, data, len);
            return;
        }
    }
    
    /* Process full blocks */
    while (len >= 64) {
        md5_transform(ctx->state, data);
        data += 64;
        len -= 64;
    }
    
    /* Buffer remaining data */
    if (len > 0) {
        memcpy(ctx->buffer, data, len);
    }
}

void pdfmake_md5_final(pdfmake_md5_ctx_t *ctx, uint8_t digest[16])
{
    uint64_t bits = ctx->count;
    size_t buf_pos = (bits / 8) % 64;
    size_t pad_len;
    uint8_t pad[64];
    uint8_t len_bytes[8];

    /* Padding: append 0x80 then zeros, leaving 8 bytes for length */
    memset(pad, 0, sizeof(pad));
    pad[0] = 0x80;

    pad_len = (buf_pos < 56) ? (56 - buf_pos) : (120 - buf_pos);
    pdfmake_md5_update(ctx, pad, pad_len);

    /* Append original length in bits as 64-bit little-endian */
    write_le64(len_bytes, bits);
    pdfmake_md5_update(ctx, len_bytes, 8);

    /* Output digest */
    write_le32(digest + 0, ctx->state[0]);
    write_le32(digest + 4, ctx->state[1]);
    write_le32(digest + 8, ctx->state[2]);
    write_le32(digest + 12, ctx->state[3]);
}

void pdfmake_md5(const uint8_t *data, size_t len, uint8_t digest[16])
{
    pdfmake_md5_ctx_t ctx;
    pdfmake_md5_init(&ctx);
    pdfmake_md5_update(&ctx, data, len);
    pdfmake_md5_final(&ctx, digest);
}
