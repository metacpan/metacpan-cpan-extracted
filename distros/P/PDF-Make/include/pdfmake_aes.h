/*
 * pdfmake_aes.h — AES block cipher header
 *
 * AES-128 and AES-256 in CBC mode with PKCS#7 padding.
 * Used for PDF encryption R4 (AES-128) and R6 (AES-256).
 */

#ifndef PDFMAKE_AES_H
#define PDFMAKE_AES_H

#include "pdfmake_types.h"
#include <stdint.h>
#include <stddef.h>

/*============================================================================
 * Constants
 *==========================================================================*/

#define PDFMAKE_AES_BLOCK_SIZE    16    /* 128 bits */
#define PDFMAKE_AES128_KEY_SIZE   16    /* 128 bits */
#define PDFMAKE_AES256_KEY_SIZE   32    /* 256 bits */
#define PDFMAKE_AES128_ROUNDS     10
#define PDFMAKE_AES256_ROUNDS     14

/*============================================================================
 * AES context
 *==========================================================================*/

typedef struct {
    uint32_t enc_key[60];    /* Expanded encryption key */
    uint32_t dec_key[60];    /* Expanded decryption key */
    int      rounds;         /* Number of rounds (10 or 14) */
    int      key_size;       /* 16 or 32 */
} pdfmake_aes_ctx_t;

/*============================================================================
 * Core AES API
 *==========================================================================*/

/**
 * Initialize AES context with key.
 * key_len: 16 for AES-128, 32 for AES-256
 */
void pdfmake_aes_init(pdfmake_aes_ctx_t *ctx, const uint8_t *key, size_t key_len);

/**
 * Encrypt a single 16-byte block.
 */
void pdfmake_aes_encrypt_block(const pdfmake_aes_ctx_t *ctx, 
                               const uint8_t in[16], 
                               uint8_t out[16]);

/**
 * Decrypt a single 16-byte block.
 */
void pdfmake_aes_decrypt_block(const pdfmake_aes_ctx_t *ctx,
                               const uint8_t in[16],
                               uint8_t out[16]);

/*============================================================================
 * CBC mode with PKCS#7 padding
 *==========================================================================*/

/**
 * Encrypt data with AES-CBC and PKCS#7 padding.
 * 
 * @param key      Encryption key (16 or 32 bytes)
 * @param key_len  Key length
 * @param iv       Initialization vector (16 bytes)
 * @param in       Input plaintext
 * @param in_len   Input length
 * @param out      Output buffer (must be at least in_len + 16 bytes)
 * @return         Output length (always multiple of 16)
 */
size_t pdfmake_aes_cbc_encrypt(const uint8_t *key, size_t key_len,
                               const uint8_t iv[16],
                               const uint8_t *in, size_t in_len,
                               uint8_t *out);

/**
 * Decrypt data with AES-CBC and remove PKCS#7 padding.
 * 
 * @param key      Decryption key (16 or 32 bytes)
 * @param key_len  Key length
 * @param iv       Initialization vector (16 bytes)
 * @param in       Input ciphertext (must be multiple of 16)
 * @param in_len   Input length
 * @param out      Output buffer (at least in_len bytes)
 * @return         Output length after removing padding, or -1 on error
 */
int pdfmake_aes_cbc_decrypt(const uint8_t *key, size_t key_len,
                            const uint8_t iv[16],
                            const uint8_t *in, size_t in_len,
                            uint8_t *out);

/*============================================================================
 * PDF-specific helpers
 *==========================================================================*/

/**
 * Encrypt string/stream for PDF (prepends random IV).
 * Output = IV || AES-CBC(data with PKCS#7)
 * Returns output length, which is 16 + padded_len.
 */
size_t pdfmake_aes_pdf_encrypt(const uint8_t *key, size_t key_len,
                               const uint8_t *in, size_t in_len,
                               uint8_t *out);

/**
 * Decrypt string/stream from PDF (IV is first 16 bytes).
 * Returns plaintext length or -1 on error.
 */
int pdfmake_aes_pdf_decrypt(const uint8_t *key, size_t key_len,
                            const uint8_t *in, size_t in_len,
                            uint8_t *out);

#endif /* PDFMAKE_AES_H */
