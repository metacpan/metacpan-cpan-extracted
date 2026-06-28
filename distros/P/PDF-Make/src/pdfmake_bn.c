/*
 * pdfmake_bn.c — Minimal big-integer arithmetic for RSA.
 *
 * Schoolbook multiplication + shift-subtract modular reduction +
 * square-and-multiply exponentiation.  Correct and readable; slower
 * than Montgomery but fast enough for RSA signing (one exponentiation
 * per document, 2048-bit keys run in well under a second).
 */

#include "pdfmake_bn.h"
#include <string.h>

/*============================================================================
 * Internal helpers
 *==========================================================================*/

static void bn_zero(pdfmake_bn_t *a) {
    memset(a->w, 0, sizeof(a->w));
    a->n = 0;
}

static void bn_copy(pdfmake_bn_t *dst, const pdfmake_bn_t *src) {
    memcpy(dst->w, src->w, sizeof(src->w));
    dst->n = src->n;
}

static void bn_normalize(pdfmake_bn_t *a) {
    while (a->n > 0 && a->w[a->n - 1] == 0) a->n--;
}

/* Compare a and b: -1 if a<b, 0 if a==b, +1 if a>b. */
static int bn_cmp(const pdfmake_bn_t *a, const pdfmake_bn_t *b) {
    size_t i;
    if (a->n > b->n) return 1;
    if (a->n < b->n) return -1;
    for (i = a->n; i > 0; i--) {
        uint32_t av = a->w[i - 1];
        uint32_t bv = b->w[i - 1];
        if (av > bv) return 1;
        if (av < bv) return -1;
    }
    return 0;
}

/* a -= b  (requires a >= b) */
static void bn_sub(pdfmake_bn_t *a, const pdfmake_bn_t *b) {
    uint64_t borrow = 0;
    size_t n = (a->n > b->n) ? a->n : b->n;
    size_t i;
    for (i = 0; i < n; i++) {
        uint64_t av = (i < a->n) ? a->w[i] : 0;
        uint64_t bv = (i < b->n) ? b->w[i] : 0;
        uint64_t d = av - bv - borrow;
        a->w[i] = (uint32_t)d;
        borrow = (d >> 32) & 1;
    }
    a->n = n;
    bn_normalize(a);
}

/* Shift a left by 1 bit, in place.  Returns the bit shifted out. */
static uint32_t bn_shl1(pdfmake_bn_t *a) {
    uint32_t carry = 0;
    size_t i;
    for (i = 0; i < a->n; i++) {
        uint32_t new_carry = a->w[i] >> 31;
        a->w[i] = (a->w[i] << 1) | carry;
        carry = new_carry;
    }
    if (carry && a->n < PDFMAKE_BN_MAX_WORDS) {
        a->w[a->n++] = carry;
        return 0;
    }
    return carry;
}

/* Schoolbook multiplication: out = a * b.  Caller ensures out has room. */
static int bn_mul(pdfmake_bn_t *out,
                  const pdfmake_bn_t *a, const pdfmake_bn_t *b) {
    size_t i;
    if (a->n + b->n > PDFMAKE_BN_MAX_WORDS) return -1;
    bn_zero(out);
    for (i = 0; i < a->n; i++) {
        uint64_t carry = 0;
        uint64_t av = a->w[i];
        size_t j;
        size_t k;
        for (j = 0; j < b->n; j++) {
            uint64_t cur = (uint64_t)out->w[i + j]
                         + av * (uint64_t)b->w[j]
                         + carry;
            out->w[i + j] = (uint32_t)cur;
            carry = cur >> 32;
        }
        /* Propagate remaining carry. */
        k = i + b->n;
        while (carry) {
            uint64_t cur;
            if (k >= PDFMAKE_BN_MAX_WORDS) return -1;
            cur = (uint64_t)out->w[k] + carry;
            out->w[k] = (uint32_t)cur;
            carry = cur >> 32;
            k++;
        }
    }
    out->n = a->n + b->n;
    bn_normalize(out);
    return 0;
}

/* r = a mod m, using shift-subtract binary long division.
 * Requires a >= 0, m > 0. */
static void bn_mod_inplace(pdfmake_bn_t *a, const pdfmake_bn_t *m) {
    size_t top_word;
    uint32_t top;
    int top_bit;
    size_t a_bits;
    size_t m_top_word;
    uint32_t m_top;
    int m_top_bit;
    size_t m_bits;
    pdfmake_bn_t shifted;
    size_t shift;
    size_t i;
    if (bn_cmp(a, m) < 0) return;

    /* Compute the highest set bit of `a`. */
    if (a->n == 0) return;
    top_word = a->n - 1;
    top = a->w[top_word];
    top_bit = 31;
    while ((top & ((uint32_t)1 << top_bit)) == 0) top_bit--;
    a_bits = top_word * 32 + (size_t)top_bit + 1;

    /* m bit length. */
    if (m->n == 0) return;
    m_top_word = m->n - 1;
    m_top = m->w[m_top_word];
    m_top_bit = 31;
    while ((m_top & ((uint32_t)1 << m_top_bit)) == 0) m_top_bit--;
    m_bits = m_top_word * 32 + (size_t)m_top_bit + 1;

    if (a_bits < m_bits) return;  /* already < m */

    /* Shift m left so the top bits align with a's top bits, then
     * repeatedly subtract if a >= shifted_m, then shift right. */
    bn_copy(&shifted, m);
    shift = a_bits - m_bits;
    for (i = 0; i < shift; i++) bn_shl1(&shifted);

    for (i = 0; i <= shift; i++) {
        uint32_t carry;
        size_t j;
        if (bn_cmp(a, &shifted) >= 0) {
            bn_sub(a, &shifted);
        }
        /* Shift shifted right by 1 bit. */
        if (shifted.n == 0) break;
        carry = 0;
        for (j = shifted.n; j > 0; j--) {
            uint32_t new_carry = shifted.w[j - 1] & 1;
            shifted.w[j - 1] = (shifted.w[j - 1] >> 1) | (carry << 31);
            carry = new_carry;
        }
        bn_normalize(&shifted);
    }
}

/*============================================================================
 * Public API
 *==========================================================================*/

int pdfmake_bn_from_bytes(pdfmake_bn_t *a, const uint8_t *bytes, size_t len) {
    size_t nw;
    size_t i;
    if (!a || (!bytes && len > 0)) return -1;
    bn_zero(a);

    /* Skip leading zero bytes to minimize work. */
    while (len > 0 && bytes[0] == 0) { bytes++; len--; }
    if (len == 0) return 0;

    nw = (len + 3) / 4;
    if (nw > PDFMAKE_BN_MAX_WORDS) return -1;

    /* bytes are big-endian; words[0] is LSB. */
    for (i = 0; i < len; i++) {
        size_t byte_from_end = len - 1 - i;
        size_t word = byte_from_end / 4;
        size_t shift = (byte_from_end % 4) * 8;
        a->w[word] |= (uint32_t)bytes[i] << shift;
    }
    a->n = nw;
    bn_normalize(a);
    return 0;
}

int pdfmake_bn_to_bytes(const pdfmake_bn_t *a, uint8_t *bytes, size_t out_len) {
    size_t need;
    uint32_t top;
    size_t i;
    if (!a || !bytes) return -1;
    memset(bytes, 0, out_len);

    /* Check the number fits. */
    if (a->n == 0) return 0;
    need = a->n * 4;
    /* Trim leading zero bytes. */
    top = a->w[a->n - 1];
    if ((top >> 24) == 0) need--;
    if ((top >> 16) == 0 && need > 0) need--;
    if ((top >> 8)  == 0 && need > 0) need--;
    if (need > out_len) return -1;

    for (i = 0; i < a->n; i++) {
        uint32_t v = a->w[i];
        int b;
        for (b = 0; b < 4; b++) {
            size_t byte_from_end = i * 4 + (size_t)b;
            if (byte_from_end >= out_len) continue;
            bytes[out_len - 1 - byte_from_end] = (uint8_t)(v >> (b * 8));
        }
    }
    return 0;
}

int pdfmake_bn_mod_exp(pdfmake_bn_t *r,
                       const pdfmake_bn_t *base,
                       const pdfmake_bn_t *exp,
                       const pdfmake_bn_t *mod) {
    pdfmake_bn_t b;
    pdfmake_bn_t result;
    if (!r || !base || !exp || !mod) return -1;
    if (mod->n == 0) return -1;

    /* Reduce base mod m up front. */
    bn_copy(&b, base);
    bn_mod_inplace(&b, mod);

    /* result = 1 */
    bn_zero(&result);
    result.w[0] = 1;
    result.n = 1;

    /* Square-and-multiply from MSB to LSB. */
    if (exp->n > 0) {
        size_t top_word = exp->n - 1;
        uint32_t top = exp->w[top_word];
        int top_bit = 31;
        size_t e_bits;
        size_t i;
        while ((top & ((uint32_t)1 << top_bit)) == 0) top_bit--;
        e_bits = top_word * 32 + (size_t)top_bit + 1;

        for (i = e_bits; i > 0; i--) {
            size_t bi  = i - 1;
            size_t wi  = bi / 32;
            uint32_t bit = (exp->w[wi] >> (bi % 32)) & 1;
            pdfmake_bn_t tmp;

            /* result = result^2 mod m */
            if (bn_mul(&tmp, &result, &result) != 0) return -1;
            bn_mod_inplace(&tmp, mod);
            bn_copy(&result, &tmp);

            if (bit) {
                /* result = result * b mod m */
                if (bn_mul(&tmp, &result, &b) != 0) return -1;
                bn_mod_inplace(&tmp, mod);
                bn_copy(&result, &tmp);
            }
        }
    }

    bn_copy(r, &result);
    return 0;
}
