#include "spvm_native.h"

#include <string.h>
#include <assert.h>

const char* FILE_NAME = "SPVM/Digest/MD5.c";

/* 
 * Originally

 * This library is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 * 
 *  Copyright 1998-2000 Gisle Aas.
 *  Copyright 1995-1996 Neil Winton.
 *  Copyright 1991-1992 RSA Data Security, Inc.
 *
 * This code is derived from Neil Winton's MD5-1.7 Perl module, which in
 * turn is derived from the reference implementation in RFC 1321 which
 * comes with this message:
 *
 * Copyright (C) 1991-2, RSA Data Security, Inc. Created 1991. All
 * rights reserved.
 *
 * License to copy and use this software is granted provided that it
 * is identified as the "RSA Data Security, Inc. MD5 Message-Digest
 * Algorithm" in all material mentioning or referencing this software
 * or this function.
 *
 * License is also granted to make and use derivative works provided
 * that such works are identified as "derived from the RSA Data
 * Security, Inc. MD5 Message-Digest Algorithm" in all material
 * mentioning or referencing the derived work.
 *
 * RSA Data Security, Inc. makes no representations concerning either
 * the merchantability of this software or the suitability of this
 * software for any particular purpose. It is provided "as is"
 * without express or implied warranty of any kind.
 *
 * These notices must be retained in any copies of any part of this
 * documentation and/or software.
 */

/* Perl does not guarantee that uint32_t is exactly 32 bits.  Some system
 * has no integral type with exactly 32 bits.  For instance, A Cray has
 * short, int and long all at 64 bits so we need to apply this macro
 * to reduce uint32_t values to 32 bits at appropriate places. If uint32_t
 * really does have 32 bits then this is a no-op.
 */
#if BYTEORDER > 0x4321 || defined(TRUNCATE_uint32_t)
  #define TO32(x)    ((x) &  0xFFFFffff)
  #define TRUNC32(x) ((x) &= 0xFFFFffff)
#else
  #define TO32(x)    (x)
  #define TRUNC32(x) /*nothing*/
#endif

/* The MD5 algorithm is defined in terms of little endian 32-bit
 * values.  The following macros (and functions) allow us to convert
 * between native integers and such values.
 */
static void u2s(uint32_t u, uint8_t* s)
{
    *s++ = (uint8_t)(u         & 0xFF);
    *s++ = (uint8_t)((u >>  8) & 0xFF);
    *s++ = (uint8_t)((u >> 16) & 0xFF);
    *s   = (uint8_t)((u >> 24) & 0xFF);
}

#define s2u(s,u) ((u) =  (uint32_t)(*s)            |  \
                        ((uint32_t)(*(s+1)) << 8)  |  \
                        ((uint32_t)(*(s+2)) << 16) |  \
                        ((uint32_t)(*(s+3)) << 24))

/* This structure keeps the current state of algorithm.
 */
typedef struct {
  uint32_t A, B, C, D;  /* current digest */
  uint32_t bytes_low;   /* counts bytes in message */
  uint32_t bytes_high;  /* turn it into a 64-bit counter */
  uint8_t buffer[128];  /* collect complete 64 byte blocks */
} MD5_CTX;

/* Padding is added at the end of the message in order to fill a
 * complete 64 byte block (- 8 bytes for the message length).  The
 * padding is also the reason the buffer in MD5_CTX have to be
 * 128 bytes.
 */
static const unsigned char PADDING[64] = {
  0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

/* Constants for MD5Transform routine.
 */
#define S11 7
#define S12 12
#define S13 17
#define S14 22
#define S21 5
#define S22 9
#define S23 14
#define S24 20
#define S31 4
#define S32 11
#define S33 16
#define S34 23
#define S41 6
#define S42 10
#define S43 15
#define S44 21

/* F, G, H and I are basic MD5 functions.
 */
#define F(x, y, z) ((((x) & ((y) ^ (z))) ^ (z)))
#define G(x, y, z) F(z, x, y)
#define H(x, y, z) ((x) ^ (y) ^ (z))
#define I(x, y, z) ((y) ^ ((x) | (~z)))

/* ROTATE_LEFT rotates x left n bits.
 */
#define ROTATE_LEFT(x, n) (((x) << (n) | ((x) >> (32-(n)))))

/* FF, GG, HH, and II transformations for rounds 1, 2, 3, and 4.
 * Rotation is separate from addition to prevent recomputation.
 */
#define FF(a, b, c, d, s, ac)                    \
 (a) += F ((b), (c), (d)) + (NEXTx) + (uint32_t)(ac); \
 TRUNC32((a));                                   \
 (a) = ROTATE_LEFT ((a), (s));                   \
 (a) += (b);                                     \
 TRUNC32((a));

#define GG(a, b, c, d, x, s, ac)                 \
 (a) += G ((b), (c), (d)) + X[x] + (uint32_t)(ac);    \
 TRUNC32((a));                                   \
 (a) = ROTATE_LEFT ((a), (s));                   \
 (a) += (b);                                     \
 TRUNC32((a));

#define HH(a, b, c, d, x, s, ac)                 \
 (a) += H ((b), (c), (d)) + X[x] + (uint32_t)(ac);    \
 TRUNC32((a));                                   \
 (a) = ROTATE_LEFT ((a), (s));                   \
 (a) += (b);                                     \
 TRUNC32((a));

#define II(a, b, c, d, x, s, ac)                 \
 (a) += I ((b), (c), (d)) + X[x] + (uint32_t)(ac);    \
 TRUNC32((a));                                   \
 (a) = ROTATE_LEFT ((a), (s));                   \
 (a) += (b);                                     \
 TRUNC32((a));


static void
MD5Init(MD5_CTX *ctx)
{
  /* Start state */
  ctx->A = 0x67452301;
  ctx->B = 0xefcdab89;
  ctx->C = 0x98badcfe;
  ctx->D = 0x10325476;

  /* message length */
  ctx->bytes_low = ctx->bytes_high = 0;
}


static void
MD5Transform(MD5_CTX* ctx, const uint8_t* buf, int32_t blocks)
{
#ifdef SPVM_DIGEST_MD5_DEBUG
    static int tcount = 0;
#endif

    uint32_t A = ctx->A;
    uint32_t B = ctx->B;
    uint32_t C = ctx->C;
    uint32_t D = ctx->D;

    do {
        uint32_t a = A;
        uint32_t b = B;
        uint32_t c = C;
        uint32_t d = D;

        uint32_t X[16];      /* little-endian values, used in round 2-4 */
        uint32_t *uptr = X;
        uint32_t tmp;
        #define NEXTx  (s2u(buf,tmp), buf += 4, *uptr++ = tmp)

#ifdef SPVM_DIGEST_MD5_DEBUG
        if (buf == ctx->buffer)
            fprintf(stderr,"%5d: Transform ctx->buffer", ++tcount);
        else 
            fprintf(stderr,"%5d: Transform %p (%d)", ++tcount, buf, blocks);

        {
            int i;
            fprintf(stderr,"[");
            for (i = 0; i < 16; i++) {
                fprintf(stderr,"%x,", x[i]); /* FIXME */
            }
            fprintf(stderr,"]\n");
        }
#endif

        /* Round 1 */
        FF (a, b, c, d, S11, 0xd76aa478); /* 1 */
        FF (d, a, b, c, S12, 0xe8c7b756); /* 2 */
        FF (c, d, a, b, S13, 0x242070db); /* 3 */
        FF (b, c, d, a, S14, 0xc1bdceee); /* 4 */
        FF (a, b, c, d, S11, 0xf57c0faf); /* 5 */
        FF (d, a, b, c, S12, 0x4787c62a); /* 6 */
        FF (c, d, a, b, S13, 0xa8304613); /* 7 */
        FF (b, c, d, a, S14, 0xfd469501); /* 8 */
        FF (a, b, c, d, S11, 0x698098d8); /* 9 */
        FF (d, a, b, c, S12, 0x8b44f7af); /* 10 */
        FF (c, d, a, b, S13, 0xffff5bb1); /* 11 */
        FF (b, c, d, a, S14, 0x895cd7be); /* 12 */
        FF (a, b, c, d, S11, 0x6b901122); /* 13 */
        FF (d, a, b, c, S12, 0xfd987193); /* 14 */
        FF (c, d, a, b, S13, 0xa679438e); /* 15 */
        FF (b, c, d, a, S14, 0x49b40821); /* 16 */

        /* Round 2 */
        GG (a, b, c, d,  1, S21, 0xf61e2562); /* 17 */
        GG (d, a, b, c,  6, S22, 0xc040b340); /* 18 */
        GG (c, d, a, b, 11, S23, 0x265e5a51); /* 19 */
        GG (b, c, d, a,  0, S24, 0xe9b6c7aa); /* 20 */
        GG (a, b, c, d,  5, S21, 0xd62f105d); /* 21 */
        GG (d, a, b, c, 10, S22,  0x2441453); /* 22 */
        GG (c, d, a, b, 15, S23, 0xd8a1e681); /* 23 */
        GG (b, c, d, a,  4, S24, 0xe7d3fbc8); /* 24 */
        GG (a, b, c, d,  9, S21, 0x21e1cde6); /* 25 */
        GG (d, a, b, c, 14, S22, 0xc33707d6); /* 26 */
        GG (c, d, a, b,  3, S23, 0xf4d50d87); /* 27 */
        GG (b, c, d, a,  8, S24, 0x455a14ed); /* 28 */
        GG (a, b, c, d, 13, S21, 0xa9e3e905); /* 29 */
        GG (d, a, b, c,  2, S22, 0xfcefa3f8); /* 30 */
        GG (c, d, a, b,  7, S23, 0x676f02d9); /* 31 */
        GG (b, c, d, a, 12, S24, 0x8d2a4c8a); /* 32 */

        /* Round 3 */
        HH (a, b, c, d,  5, S31, 0xfffa3942); /* 33 */
        HH (d, a, b, c,  8, S32, 0x8771f681); /* 34 */
        HH (c, d, a, b, 11, S33, 0x6d9d6122); /* 35 */
        HH (b, c, d, a, 14, S34, 0xfde5380c); /* 36 */
        HH (a, b, c, d,  1, S31, 0xa4beea44); /* 37 */
        HH (d, a, b, c,  4, S32, 0x4bdecfa9); /* 38 */
        HH (c, d, a, b,  7, S33, 0xf6bb4b60); /* 39 */
        HH (b, c, d, a, 10, S34, 0xbebfbc70); /* 40 */
        HH (a, b, c, d, 13, S31, 0x289b7ec6); /* 41 */
        HH (d, a, b, c,  0, S32, 0xeaa127fa); /* 42 */
        HH (c, d, a, b,  3, S33, 0xd4ef3085); /* 43 */
        HH (b, c, d, a,  6, S34,  0x4881d05); /* 44 */
        HH (a, b, c, d,  9, S31, 0xd9d4d039); /* 45 */
        HH (d, a, b, c, 12, S32, 0xe6db99e5); /* 46 */
        HH (c, d, a, b, 15, S33, 0x1fa27cf8); /* 47 */
        HH (b, c, d, a,  2, S34, 0xc4ac5665); /* 48 */

        /* Round 4 */
        II (a, b, c, d,  0, S41, 0xf4292244); /* 49 */
        II (d, a, b, c,  7, S42, 0x432aff97); /* 50 */
        II (c, d, a, b, 14, S43, 0xab9423a7); /* 51 */
        II (b, c, d, a,  5, S44, 0xfc93a039); /* 52 */
        II (a, b, c, d, 12, S41, 0x655b59c3); /* 53 */
        II (d, a, b, c,  3, S42, 0x8f0ccc92); /* 54 */
        II (c, d, a, b, 10, S43, 0xffeff47d); /* 55 */
        II (b, c, d, a,  1, S44, 0x85845dd1); /* 56 */
        II (a, b, c, d,  8, S41, 0x6fa87e4f); /* 57 */
        II (d, a, b, c, 15, S42, 0xfe2ce6e0); /* 58 */
        II (c, d, a, b,  6, S43, 0xa3014314); /* 59 */
        II (b, c, d, a, 13, S44, 0x4e0811a1); /* 60 */
        II (a, b, c, d,  4, S41, 0xf7537e82); /* 61 */
        II (d, a, b, c, 11, S42, 0xbd3af235); /* 62 */
        II (c, d, a, b,  2, S43, 0x2ad7d2bb); /* 63 */
        II (b, c, d, a,  9, S44, 0xeb86d391); /* 64 */

        A += a;  TRUNC32(A);
        B += b;  TRUNC32(B);
        C += c;  TRUNC32(C);
        D += d;  TRUNC32(D);

    } while (--blocks);
    ctx->A = A;
    ctx->B = B;
    ctx->C = C;
    ctx->D = D;
}


#ifdef SPVM_DIGEST_MD5_DEBUG
static char*
ctx_dump(MD5_CTX* ctx)
{
    static char buf[1024];
    sprintf(buf, "{A=%x,B=%x,C=%x,D=%x,%d,%d(%d)}",
            ctx->A, ctx->B, ctx->C, ctx->D,
            ctx->bytes_low, ctx->bytes_high, (ctx->bytes_low&0x3F));
    return buf;
}
#endif


static void
MD5Update(MD5_CTX* ctx, const uint8_t* buf, int32_t len)
{
    int32_t blocks;
    int32_t fill = ctx->bytes_low & 0x3F;

#ifdef SPVM_DIGEST_MD5_DEBUG  
    static int ucount = 0;
    fprintf(stderr,"%5i: Update(%s, %p, %d)\n", ++ucount, ctx_dump(ctx),
                                                buf, len);
#endif

    ctx->bytes_low += len;
    if (ctx->bytes_low < len) /* wrap around */
        ctx->bytes_high++;

    if (fill) {
        int32_t missing = 64 - fill;
        if (len < missing) {
            memcpy(ctx->buffer + fill, buf, len * sizeof(uint8_t));
            return;
        }
        memcpy(ctx->buffer + fill, buf, missing * sizeof(uint8_t));
        MD5Transform(ctx, ctx->buffer, 1);
        buf += missing;
        len -= missing;
    }

    blocks = len >> 6;
    if (blocks)
        MD5Transform(ctx, buf, blocks);
    if ( (len &= 0x3F)) {
        memcpy(ctx->buffer, buf + (blocks << 6), len * sizeof(uint8_t));
    }
}


static void
MD5Final(uint8_t* digest, MD5_CTX *ctx)
{
    int32_t fill = ctx->bytes_low & 0x3F;
    int32_t padlen = (fill < 56 ? 56 : 120) - fill;
    uint32_t bits_low, bits_high;
#ifdef SPVM_DIGEST_MD5_DEBUG
    fprintf(stderr,"       Final:  %s\n", ctx_dump(ctx));
#endif
    memcpy(ctx->buffer + fill, PADDING, padlen * sizeof(uint8_t));
    fill += padlen;

    bits_low = ctx->bytes_low << 3;
    bits_high = (ctx->bytes_high << 3) | (ctx->bytes_low  >> 29);
    u2s(bits_low,  ctx->buffer + fill);   fill += 4;
    u2s(bits_high, ctx->buffer + fill);   fill += 4;

    MD5Transform(ctx, ctx->buffer, fill >> 6);
#ifdef SPVM_DIGEST_MD5_DEBUG
    fprintf(stderr,"       Result: %s\n", ctx_dump(ctx));
#endif

    u2s(ctx->A, digest);
    u2s(ctx->B, digest+4);
    u2s(ctx->C, digest+8);
    u2s(ctx->D, digest+12);
}

static char* hex_16(const unsigned char* from, char* to)
{
    static const char hexdigits[] = "0123456789abcdef";
    const unsigned char *end = from + 16;
    char *d = to;

    while (from < end) {
        *d++ = hexdigits[(*from >> 4)];
        *d++ = hexdigits[(*from & 0x0F)];
        from++;
    }
    *d = '\0';
    return to;
}

static char* base64_16(const unsigned char* from, char* to)
{
    static const char base64[] =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    const unsigned char *end = from + 16;
    unsigned char c1, c2, c3;
    char *d = to;

    while (1) {
        c1 = *from++;
        *d++ = base64[c1>>2];
        if (from == end) {
            *d++ = base64[(c1 & 0x3) << 4];
            break;
        }
        c2 = *from++;
        c3 = *from++;
        *d++ = base64[((c1 & 0x3) << 4) | ((c2 & 0xF0) >> 4)];
        *d++ = base64[((c2 & 0xF) << 2) | ((c3 & 0xC0) >>6)];
        *d++ = base64[c3 & 0x3F];
    }
    *d = '\0';
    return to;
}

/* Formats */
#define F_BIN 0
#define F_HEX 1
#define F_B64 2

static void* make_output(SPVM_ENV* env, SPVM_VALUE* stack, const unsigned char *src, int type)
{
    int32_t len;
    char result[33];
    char *ret;
    
    switch (type) {
    case F_BIN:
        ret = (char*)src;
        len = 16;
        break;
    case F_HEX:
        ret = hex_16(src, result);
        len = 32;
        break;
    case F_B64:
        ret = base64_16(src, result);
        len = 22;
        break;
    default:
        assert(0);
        break;
    }
    
    void* obj_ret = env->new_string(env, stack, ret, len);
    
    return obj_ret;
}

int32_t SPVM__Digest__MD5__md5(SPVM_ENV* env, SPVM_VALUE* stack) {
        MD5_CTX ctx;
        int i;
        unsigned char *data;
        int32_t len;
        unsigned char digeststr[16];

        void* obj_string = stack[0].oval;
        
        if (!obj_string) {
          return env->die(env, stack, "The input must be defined", FILE_NAME, __LINE__);
        }
        
        data = (unsigned char *)env->get_chars(env, stack, obj_string);
        len = env->length(env, stack, obj_string);
        
        MD5Init(&ctx);
        MD5Update(&ctx, data, len);
        MD5Final(digeststr, &ctx);
        void* output = make_output(env, stack, digeststr, F_BIN);
        stack[0].oval = output;
        return 0;
}

int32_t SPVM__Digest__MD5__md5_hex(SPVM_ENV* env, SPVM_VALUE* stack) {
        MD5_CTX ctx;
        int i;
        unsigned char *data;
        int32_t len;
        unsigned char digeststr[16];
        void* obj_string = stack[0].oval;
        
        if (!obj_string) {
          return env->die(env, stack, "The input must be defined", FILE_NAME, __LINE__);
        }
        
        data = (unsigned char *)env->get_chars(env, stack, obj_string);
        len = env->length(env, stack, obj_string);
        
        MD5Init(&ctx);
        MD5Update(&ctx, data, len);
        MD5Final(digeststr, &ctx);
        void* output = make_output(env, stack, digeststr, F_HEX);
        stack[0].oval = output;
        return 0;
}

int32_t SPVM__Digest__MD5__md5_base64(SPVM_ENV* env, SPVM_VALUE* stack) {
        MD5_CTX ctx;
        int i;
        unsigned char *data;
        int32_t len;
        unsigned char digeststr[16];
        void* obj_string = stack[0].oval;
        
        if (!obj_string) {
          return env->die(env, stack, "The input must be defined", FILE_NAME, __LINE__);
        }
        
        data = (unsigned char *)env->get_chars(env, stack, obj_string);
        len = env->length(env, stack, obj_string);
        
        MD5Init(&ctx);
        MD5Update(&ctx, data, len);
        MD5Final(digeststr, &ctx);
        void* output = make_output(env, stack, digeststr, F_B64);
        stack[0].oval = output;
        
        return 0;
}

int32_t SPVM__Digest__MD5__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e;
  
  void* obj_self = env->new_object_by_name(env, stack, "Digest::MD5", &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  MD5_CTX* ctx = env->alloc_memory_block_zero(env, sizeof(MD5_CTX));

  MD5Init(ctx);
  
  void* obj_ctx = env->new_object_by_name(env, stack, "Digest::MD5::Context", &e, FILE_NAME, __LINE__);
  
  env->set_pointer(env, stack, obj_ctx, ctx);
  
  env->set_field_object_by_name_v2(env, stack, obj_self, "Digest::MD5", "context", obj_ctx, &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_self;
  
  return 0;
}

int32_t SPVM__Digest__MD5__add(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e;
  void* obj_self = stack[0].oval;

  void* obj_string = stack[1].oval;
  
  if (!obj_string) {
    return env->die(env, stack, "The input must be defined", FILE_NAME, __LINE__);
  }

  const char* data = (unsigned char *)env->get_chars(env, stack, obj_string);
  int32_t len = env->length(env, stack, obj_string);
  
  void* obj_ctx = env->get_field_object_by_name_v2(env, stack, obj_self, "Digest::MD5", "context", &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  MD5_CTX* ctx = env->get_pointer(env, stack, obj_ctx);

  MD5Update(ctx, data, len);
  
  stack[0].oval = obj_self;
  
  return 0;
}

int32_t SPVM__Digest__MD5__digest(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t e;
  void* obj_self = stack[0].oval;
  
  void* obj_ctx = env->get_field_object_by_name_v2(env, stack, obj_self, "Digest::MD5", "context", &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  MD5_CTX* ctx = env->get_pointer(env, stack, obj_ctx);
  
  unsigned char digeststr[16];
  MD5Final(digeststr, ctx);
  void* output = make_output(env, stack, digeststr, F_BIN);
  stack[0].oval = output;
  return 0;
}

int32_t SPVM__Digest__MD5__hexdigest(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t e;
  void* obj_self = stack[0].oval;
  
  void* obj_ctx = env->get_field_object_by_name_v2(env, stack, obj_self, "Digest::MD5", "context", &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  MD5_CTX* ctx = env->get_pointer(env, stack, obj_ctx);
  
  unsigned char digeststr[16];
  MD5Final(digeststr, ctx);
  void* output = make_output(env, stack, digeststr, F_HEX);
  stack[0].oval = output;
  return 0;
}

int32_t SPVM__Digest__MD5__b64digest(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t e;
  void* obj_self = stack[0].oval;
  
  void* obj_ctx = env->get_field_object_by_name_v2(env, stack, obj_self, "Digest::MD5", "context", &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  MD5_CTX* ctx = env->get_pointer(env, stack, obj_ctx);
  
  unsigned char digeststr[16];
  MD5Final(digeststr, ctx);
  void* output = make_output(env, stack, digeststr, F_B64);
  stack[0].oval = output;
  
  return 0;
}

int32_t SPVM__Digest__MD5__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t e;
  
  void* obj_self = stack[0].oval;
  
  void* obj_ctx = env->get_field_object_by_name_v2(env, stack, obj_self, "Digest::MD5", "context", &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  MD5_CTX* ctx = env->get_pointer(env, stack, obj_ctx);
  assert(ctx);
  
  env->free_memory_block(env, ctx);
  
  return 0;
}
