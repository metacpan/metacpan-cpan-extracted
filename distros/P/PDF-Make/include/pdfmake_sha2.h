/*
 * pdfmake_sha2.h — SHA-256, SHA-384, SHA-512 implementations
 *
 * Required for PDF encryption R6 key derivation.
 * Reference: FIPS 180-4
 */

#ifndef PDFMAKE_SHA2_H
#define PDFMAKE_SHA2_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/*============================================================================
 * SHA-256
 *==========================================================================*/

#define PDFMAKE_SHA256_DIGEST_SIZE  32
#define PDFMAKE_SHA256_BLOCK_SIZE   64

typedef struct pdfmake_sha256_ctx {
    uint32_t state[8];
    uint64_t count;
    uint8_t buffer[64];
} pdfmake_sha256_ctx_t;

void pdfmake_sha256_init(pdfmake_sha256_ctx_t *ctx);
void pdfmake_sha256_update(pdfmake_sha256_ctx_t *ctx, const uint8_t *data, size_t len);
void pdfmake_sha256_final(pdfmake_sha256_ctx_t *ctx, uint8_t digest[32]);
void pdfmake_sha256(const uint8_t *data, size_t len, uint8_t digest[32]);

/*============================================================================
 * SHA-384
 *==========================================================================*/

#define PDFMAKE_SHA384_DIGEST_SIZE  48
#define PDFMAKE_SHA384_BLOCK_SIZE   128

typedef struct pdfmake_sha384_ctx {
    uint64_t state[8];
    uint64_t count[2];  /* 128-bit counter */
    uint8_t buffer[128];
} pdfmake_sha384_ctx_t;

void pdfmake_sha384_init(pdfmake_sha384_ctx_t *ctx);
void pdfmake_sha384_update(pdfmake_sha384_ctx_t *ctx, const uint8_t *data, size_t len);
void pdfmake_sha384_final(pdfmake_sha384_ctx_t *ctx, uint8_t digest[48]);
void pdfmake_sha384(const uint8_t *data, size_t len, uint8_t digest[48]);

/*============================================================================
 * SHA-512
 *==========================================================================*/

#define PDFMAKE_SHA512_DIGEST_SIZE  64
#define PDFMAKE_SHA512_BLOCK_SIZE   128

typedef struct pdfmake_sha512_ctx {
    uint64_t state[8];
    uint64_t count[2];  /* 128-bit counter */
    uint8_t buffer[128];
} pdfmake_sha512_ctx_t;

void pdfmake_sha512_init(pdfmake_sha512_ctx_t *ctx);
void pdfmake_sha512_update(pdfmake_sha512_ctx_t *ctx, const uint8_t *data, size_t len);
void pdfmake_sha512_final(pdfmake_sha512_ctx_t *ctx, uint8_t digest[64]);
void pdfmake_sha512(const uint8_t *data, size_t len, uint8_t digest[64]);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_SHA2_H */
