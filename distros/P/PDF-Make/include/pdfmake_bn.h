/*
 * pdfmake_bn.h — Minimal big-integer arithmetic for RSA.
 *
 * Provides just enough to compute modular exponentiation for RSA
 * signing (PKCS#1 v1.5) with keys up to 8192 bits.  Numbers are
 * stored as little-endian arrays of uint32_t words.
 *
 * Not a general-purpose bignum library — no primes, no gcd, no
 * negative values; just non-negative integers and the arithmetic
 * needed for RSA: compare, add, subtract, multiply, modulo,
 * modular exponentiation.
 */

#ifndef PDFMAKE_BN_H
#define PDFMAKE_BN_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* 256 * 32 = 8192 bits max — enough for RSA-8192. */
#define PDFMAKE_BN_MAX_WORDS 256

typedef struct pdfmake_bn {
    uint32_t w[PDFMAKE_BN_MAX_WORDS];  /* little-endian words */
    size_t   n;                         /* count of significant words */
} pdfmake_bn_t;

/* Load a big-endian byte string into a bignum.  Returns 0 on success,
 * -1 if the input exceeds PDFMAKE_BN_MAX_WORDS * 4 bytes. */
int pdfmake_bn_from_bytes(pdfmake_bn_t *a, const uint8_t *bytes, size_t len);

/* Emit a bignum as a big-endian byte string into `bytes` of length
 * `out_len`.  Pads with leading zeros if the number is smaller.
 * Returns 0 on success, -1 if the number does not fit in `out_len`. */
int pdfmake_bn_to_bytes(const pdfmake_bn_t *a, uint8_t *bytes, size_t out_len);

/* Compute r = base^exp mod mod.  Returns 0 on success, -1 on error. */
int pdfmake_bn_mod_exp(pdfmake_bn_t *r,
                       const pdfmake_bn_t *base,
                       const pdfmake_bn_t *exp,
                       const pdfmake_bn_t *mod);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_BN_H */
