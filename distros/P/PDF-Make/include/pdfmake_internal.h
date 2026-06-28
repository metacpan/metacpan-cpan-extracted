/*
 * pdfmake_internal.h — private cross-module helpers.
 *
 * NOT part of the public API. Do not install. Callers are restricted to
 * translation units under src/ in this library. The intent is a single place
 * for small `static PDFMAKE_INLINE` utilities and macros that are shared by two or
 * more .c files but too trivial to deserve their own module header.
 *
 * Rules for additions:
 *   - Two or more callers, identical semantics. One-shot helpers stay
 *     file-local.
 *   - `static PDFMAKE_INLINE` whenever possible — this header is included from
 *     multiple TUs, so non-inline definitions would multiply-define.
 *   - No allocation. No global state. Leaf functions only.
 *   - Zero dependencies beyond <stdint.h>, <stddef.h>, <string.h>.
 */

#ifndef PDFMAKE_INTERNAL_H
#define PDFMAKE_INTERNAL_H

#include "pdfmake_types.h"

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/*----------------------------------------------------------------------------
 * Big-endian byte readers / writers.
 *
 * Every binary parser in the library (TTF, CFF, PNG, SHA-2, ASN.1 length
 * fields, xref streams, etc.) needs to pull multi-byte integers out of a
 * byte buffer in network/big-endian order. Rather than redefining the
 * same 3-line helpers in each .c file (we had five near-identical
 * copies pre-Phase-4), they live here.
 *---------------------------------------------------------------------------*/

static PDFMAKE_INLINE uint16_t pdfmake_read_be16(const uint8_t *p) {
    return ((uint16_t)p[0] << 8) | p[1];
}

static PDFMAKE_INLINE int16_t pdfmake_read_sbe16(const uint8_t *p) {
    return (int16_t)pdfmake_read_be16(p);
}

static PDFMAKE_INLINE uint32_t pdfmake_read_be32(const uint8_t *p) {
    return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) |
           ((uint32_t)p[2] <<  8) | (uint32_t)p[3];
}

static PDFMAKE_INLINE uint64_t pdfmake_read_be64(const uint8_t *p) {
    return ((uint64_t)p[0] << 56) | ((uint64_t)p[1] << 48) |
           ((uint64_t)p[2] << 40) | ((uint64_t)p[3] << 32) |
           ((uint64_t)p[4] << 24) | ((uint64_t)p[5] << 16) |
           ((uint64_t)p[6] <<  8) | (uint64_t)p[7];
}

static PDFMAKE_INLINE void pdfmake_write_be16(uint8_t *p, uint16_t x) {
    p[0] = (uint8_t)(x >> 8);
    p[1] = (uint8_t)(x);
}

static PDFMAKE_INLINE void pdfmake_write_be32(uint8_t *p, uint32_t x) {
    p[0] = (uint8_t)(x >> 24);
    p[1] = (uint8_t)(x >> 16);
    p[2] = (uint8_t)(x >>  8);
    p[3] = (uint8_t)(x);
}

static PDFMAKE_INLINE void pdfmake_write_be64(uint8_t *p, uint64_t x) {
    p[0] = (uint8_t)(x >> 56);
    p[1] = (uint8_t)(x >> 48);
    p[2] = (uint8_t)(x >> 40);
    p[3] = (uint8_t)(x >> 32);
    p[4] = (uint8_t)(x >> 24);
    p[5] = (uint8_t)(x >> 16);
    p[6] = (uint8_t)(x >>  8);
    p[7] = (uint8_t)(x);
}

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_INTERNAL_H */
