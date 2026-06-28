/*
 * pdfmake_rc4.h — RC4 stream cipher header
 *
 * Used for PDF encryption R2 (40-bit) and R3 (40-128 bit).
 */

#ifndef PDFMAKE_RC4_H
#define PDFMAKE_RC4_H

#include <stdint.h>
#include <stddef.h>

/*============================================================================
 * RC4 context
 *==========================================================================*/

typedef struct {
    uint8_t S[256];    /* State array */
    uint8_t i;         /* Index i */
    uint8_t j;         /* Index j */
} pdfmake_rc4_ctx_t;

/*============================================================================
 * RC4 API
 *==========================================================================*/

/**
 * Initialize RC4 context with key.
 * key_len: 5 for 40-bit, 16 for 128-bit
 */
void pdfmake_rc4_init(pdfmake_rc4_ctx_t *ctx, const uint8_t *key, size_t key_len);

/**
 * Encrypt/decrypt data in-place.
 * RC4 is symmetric - same operation for encrypt and decrypt.
 */
void pdfmake_rc4_crypt(pdfmake_rc4_ctx_t *ctx, uint8_t *data, size_t len);

/**
 * One-shot convenience function.
 * Initializes context, encrypts/decrypts, and discards context.
 */
void pdfmake_rc4(const uint8_t *key, size_t key_len, uint8_t *data, size_t data_len);

#endif /* PDFMAKE_RC4_H */
