/*
 * pdfmake_md5.h — MD5 hash implementation
 *
 * Required for PDF encryption key derivation (R2-R4).
 * Reference: RFC 1321
 */

#ifndef PDFMAKE_MD5_H
#define PDFMAKE_MD5_H

#include "pdfmake_types.h"
#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define PDFMAKE_MD5_DIGEST_SIZE  16
#define PDFMAKE_MD5_BLOCK_SIZE   64

typedef struct pdfmake_md5_ctx {
    uint32_t state[4];      /* A, B, C, D */
    uint64_t count;         /* number of bits processed */
    uint8_t buffer[64];     /* input buffer */
} pdfmake_md5_ctx_t;

/* Initialize MD5 context */
void pdfmake_md5_init(pdfmake_md5_ctx_t *ctx);

/* Update with data */
void pdfmake_md5_update(pdfmake_md5_ctx_t *ctx, const uint8_t *data, size_t len);

/* Finalize and output 16-byte digest */
void pdfmake_md5_final(pdfmake_md5_ctx_t *ctx, uint8_t digest[16]);

/* One-shot convenience function */
void pdfmake_md5(const uint8_t *data, size_t len, uint8_t digest[16]);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_MD5_H */
