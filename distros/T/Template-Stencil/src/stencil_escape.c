#include "stencil.h"

/* Entity table: each replacement is 8 readable bytes so the write is a
 * single unaligned 8-byte store; the head advances by the real length. */
static const struct stencil_ent {
    char    txt[8];
    uint8_t len;
} ent_tab[5] = {
    { "&quot;",  6 },   /* " 0x22 */
    { "&amp;\0", 5 },   /* & 0x26 */
    { "&#39;\0", 5 },   /* ' 0x27 */
    { "&lt;\0\0", 4 },  /* < 0x3C */
    { "&gt;\0\0", 4 },  /* > 0x3E */
};

/* 0 = clean byte, 1..5 = ent_tab index + 1 */
static const uint8_t ent_idx[256] = {
    [0x22] = 1, [0x26] = 2, [0x27] = 3, [0x3C] = 4, [0x3E] = 5,
};

STENCIL_INLINE char *put_byte(char *out, char c)
{
    uint8_t ix = ent_idx[(uint8_t)c];
    if (STENCIL_LIKELY(!ix)) {
        *out++ = c;
        return out;
    }
    {
        const struct stencil_ent *e = &ent_tab[ix - 1];
        memcpy(out, e->txt, 8);
        return out + e->len;
    }
}

/* ---- SWAR helpers ------------------------------------------------- */

#define STENCIL_B1   0x0101010101010101ULL
#define STENCIL_B80  0x8080808080808080ULL
#define STENCIL_BCAST(c) (STENCIL_B1 * (uint8_t)(c))
/* 0x80 set in each byte of v that is zero */
#define STENCIL_HASZERO(v) (((v) - STENCIL_B1) & ~(v) & STENCIL_B80)

STENCIL_INLINE uint64_t special_mask8(uint64_t v)
{
    return STENCIL_HASZERO(v ^ STENCIL_BCAST('"'))
         | STENCIL_HASZERO(v ^ STENCIL_BCAST('&'))
         | STENCIL_HASZERO(v ^ STENCIL_BCAST('\''))
         | STENCIL_HASZERO(v ^ STENCIL_BCAST('<'))
         | STENCIL_HASZERO(v ^ STENCIL_BCAST('>'));
}

STENCIL_INLINE unsigned popcount64(uint64_t m)
{
#if defined(__GNUC__) || defined(__clang__)
    return (unsigned)__builtin_popcountll(m);
#else
    unsigned c = 0;
    while (m) { m &= m - 1; c++; }
    return c;
#endif
}

size_t stencil_count_specials(const char *src, size_t n)
{
    size_t      count = 0;
    const char *p     = src;
    const char *end   = src + n;
    while ((size_t)(end - p) >= 8) {
        uint64_t v;
        memcpy(&v, p, 8);
        count += popcount64(special_mask8(v));
        p += 8;
    }
    for (; p < end; p++)
        count += ent_idx[(uint8_t)*p] != 0;
    return count;
}

/* Reserve worst case once, then every variant writes unchecked. Small
 * inputs take the single-pass 6x bound; large ones pay a quick SWAR
 * pre-count instead. 32 bytes of slack covers the widest clean block
 * store and the 8-byte entity overhang. */
static void escape_reserve(stencil_buf *b, const char *src, size_t n)
{
    if (n <= 1024)
        stencil_buf_reserve(b, n * 6 + 32);
    else
        stencil_buf_reserve(b, n + stencil_count_specials(src, n) * 5 + 32);
}

size_t stencil_escape_swar(stencil_buf *b, const char *src, size_t n)
{
    const char *p   = src;
    const char *end = src + n;
    char       *out;
    size_t      w;
    escape_reserve(b, src, n);
    out = b->cur;
    while ((size_t)(end - p) >= 8) {
        uint64_t v;
        memcpy(&v, p, 8);
        if (STENCIL_LIKELY(!special_mask8(v))) {
            memcpy(out, &v, 8);
            out += 8;
            p   += 8;
        } else {
            const char *e8 = p + 8;
            for (; p < e8; p++)
                out = put_byte(out, *p);
        }
    }
    for (; p < end; p++)
        out = put_byte(out, *p);
    w = (size_t)(out - b->cur);
    b->cur = out;
    return w;
}

#ifdef STENCIL_HAVE_SSE2
#include <emmintrin.h>
size_t stencil_escape_sse2(stencil_buf *b, const char *src, size_t n)
{
    const char *p   = src;
    const char *end = src + n;
    char       *out;
    size_t      w;
    const __m128i q = _mm_set1_epi8(0x22), am = _mm_set1_epi8(0x26),
                  ap = _mm_set1_epi8(0x27), lt = _mm_set1_epi8(0x3C),
                  gt = _mm_set1_epi8(0x3E);
    escape_reserve(b, src, n);
    out = b->cur;
    while ((size_t)(end - p) >= 16) {
        __m128i v = _mm_loadu_si128((const __m128i *)p);
        __m128i m = _mm_or_si128(
            _mm_or_si128(_mm_cmpeq_epi8(v, q),  _mm_cmpeq_epi8(v, am)),
            _mm_or_si128(_mm_cmpeq_epi8(v, ap),
                _mm_or_si128(_mm_cmpeq_epi8(v, lt),
                             _mm_cmpeq_epi8(v, gt))));
        if (STENCIL_LIKELY(!_mm_movemask_epi8(m))) {
            _mm_storeu_si128((__m128i *)out, v);
            out += 16;
            p   += 16;
        } else {
            const char *e16 = p + 16;
            for (; p < e16; p++)
                out = put_byte(out, *p);
        }
    }
    for (; p < end; p++)
        out = put_byte(out, *p);
    w = (size_t)(out - b->cur);
    b->cur = out;
    return w;
}
#endif /* STENCIL_HAVE_SSE2 */

#ifdef STENCIL_HAVE_AVX2
#include <immintrin.h>
__attribute__((target("avx2")))
size_t stencil_escape_avx2(stencil_buf *b, const char *src, size_t n)
{
    const char *p   = src;
    const char *end = src + n;
    char       *out;
    size_t      w;
    const __m256i q = _mm256_set1_epi8(0x22), am = _mm256_set1_epi8(0x26),
                  ap = _mm256_set1_epi8(0x27), lt = _mm256_set1_epi8(0x3C),
                  gt = _mm256_set1_epi8(0x3E);
    escape_reserve(b, src, n);
    out = b->cur;
    while ((size_t)(end - p) >= 32) {
        __m256i v = _mm256_loadu_si256((const __m256i *)p);
        __m256i m = _mm256_or_si256(
            _mm256_or_si256(_mm256_cmpeq_epi8(v, q),
                            _mm256_cmpeq_epi8(v, am)),
            _mm256_or_si256(_mm256_cmpeq_epi8(v, ap),
                _mm256_or_si256(_mm256_cmpeq_epi8(v, lt),
                                _mm256_cmpeq_epi8(v, gt))));
        if (STENCIL_LIKELY(!_mm256_movemask_epi8(m))) {
            _mm256_storeu_si256((__m256i *)out, v);
            out += 32;
            p   += 32;
        } else {
            const char *e32 = p + 32;
            for (; p < e32; p++)
                out = put_byte(out, *p);
        }
    }
    for (; p < end; p++)
        out = put_byte(out, *p);
    w = (size_t)(out - b->cur);
    b->cur = out;
    return w;
}
#endif /* STENCIL_HAVE_AVX2 */

#ifdef STENCIL_HAVE_NEON
#include <arm_neon.h>
size_t stencil_escape_neon(stencil_buf *b, const char *src, size_t n)
{
    const char *p   = src;
    const char *end = src + n;
    char       *out;
    size_t      w;
    const uint8x16_t q  = vdupq_n_u8(0x22), am = vdupq_n_u8(0x26),
                     ap = vdupq_n_u8(0x27), lt = vdupq_n_u8(0x3C),
                     gt = vdupq_n_u8(0x3E);
    escape_reserve(b, src, n);
    out = b->cur;
    while ((size_t)(end - p) >= 16) {
        uint8x16_t v = vld1q_u8((const uint8_t *)p);
        uint8x16_t m = vorrq_u8(
            vorrq_u8(vceqq_u8(v, q),  vceqq_u8(v, am)),
            vorrq_u8(vceqq_u8(v, ap),
                vorrq_u8(vceqq_u8(v, lt), vceqq_u8(v, gt))));
        if (STENCIL_LIKELY(vmaxvq_u8(m) == 0)) {
            vst1q_u8((uint8_t *)out, v);
            out += 16;
            p   += 16;
        } else {
            const char *e16 = p + 16;
            for (; p < e16; p++)
                out = put_byte(out, *p);
        }
    }
    for (; p < end; p++)
        out = put_byte(out, *p);
    w = (size_t)(out - b->cur);
    b->cur = out;
    return w;
}
#endif /* STENCIL_HAVE_NEON */
