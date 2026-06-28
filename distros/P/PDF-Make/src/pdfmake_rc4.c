/*
 * pdfmake_rc4.c — RC4 stream cipher implementation
 *
 * Standard RC4 (ARC4) for PDF encryption R2/R3.
 */

#include "pdfmake_rc4.h"
#include <string.h>

/*============================================================================
 * RC4 Key Scheduling Algorithm (KSA)
 *==========================================================================*/

void pdfmake_rc4_init(pdfmake_rc4_ctx_t *ctx, const uint8_t *key, size_t key_len)
{
    int i;
    uint8_t j;

    /* Initialize identity permutation */
    for (i = 0; i < 256; i++) {
        ctx->S[i] = (uint8_t)i;
    }

    /* Key scheduling */
    j = 0;
    for (i = 0; i < 256; i++) {
        uint8_t tmp;
        j = j + ctx->S[i] + key[i % key_len];
        /* Swap S[i] and S[j] */
        tmp = ctx->S[i];
        ctx->S[i] = ctx->S[j];
        ctx->S[j] = tmp;
    }

    ctx->i = 0;
    ctx->j = 0;
}

/*============================================================================
 * RC4 Pseudo-Random Generation Algorithm (PRGA)
 *==========================================================================*/

void pdfmake_rc4_crypt(pdfmake_rc4_ctx_t *ctx, uint8_t *data, size_t len)
{
    uint8_t i = ctx->i;
    uint8_t j = ctx->j;
    uint8_t *S = ctx->S;
    size_t n;

    for (n = 0; n < len; n++) {
        uint8_t tmp;
        uint8_t k;
        i++;
        j = j + S[i];

        /* Swap S[i] and S[j] */
        tmp = S[i];
        S[i] = S[j];
        S[j] = tmp;

        /* Generate keystream byte and XOR with data */
        k = S[(S[i] + S[j]) & 0xFF];
        data[n] ^= k;
    }

    ctx->i = i;
    ctx->j = j;
}

/*============================================================================
 * One-shot convenience function
 *==========================================================================*/

void pdfmake_rc4(const uint8_t *key, size_t key_len, uint8_t *data, size_t data_len)
{
    pdfmake_rc4_ctx_t ctx;
    pdfmake_rc4_init(&ctx, key, key_len);
    pdfmake_rc4_crypt(&ctx, data, data_len);
}
