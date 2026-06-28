/*
 * pdfmake_filter.h — Stream filter encode/decode API
 *
 * PDF §7.4 filters: FlateDecode, ASCIIHexDecode, ASCII85Decode, etc.
 * This header provides a unified interface for encoding and decoding
 * stream data through filter chains.
 */

#ifndef PDFMAKE_FILTER_H
#define PDFMAKE_FILTER_H

#include "pdfmake_types.h"
#include "pdfmake_buf.h"
#include "pdfmake_arena.h"

#ifdef __cplusplus
extern "C" {
#endif

/*----------------------------------------------------------------------------
 * Error codes for filter operations
 *--------------------------------------------------------------------------*/

/* Filter-specific error codes (in addition to base pdfmake_err_t) */
#define PDFMAKE_EFILTER      10   /* Generic filter error */
#define PDFMAKE_EUNSUPPORTED 11   /* Unsupported filter */
#define PDFMAKE_ECORRUPT     12   /* Corrupt/invalid data */
#define PDFMAKE_ECHECKSUM    13   /* Checksum mismatch */

/*----------------------------------------------------------------------------
 * Filter decode parameters (§7.4.4.3)
 *--------------------------------------------------------------------------*/

typedef struct pdfmake_flate_params {
    int predictor;      /* 1=none, 2=TIFF, 10-15=PNG (default 1) */
    int colors;         /* Components per sample (default 1) */
    int bits_per_comp;  /* Bits per component (default 8) */
    int columns;        /* Samples per row (default 1) */
    int early_change;   /* LZW only: early code size change (default 1) */
} pdfmake_flate_params_t;

/* Initialize params to defaults */
void pdfmake_flate_params_init(pdfmake_flate_params_t *params);

/* Parse params from a PDF dictionary object */
pdfmake_err_t pdfmake_flate_params_from_dict(pdfmake_flate_params_t *params,
                                             const pdfmake_obj_t *dict);

/*----------------------------------------------------------------------------
 * Single filter encode/decode
 *--------------------------------------------------------------------------*/

/*
 * Encode data through a named filter.
 *
 * name     - Filter name (e.g., "FlateDecode", "ASCIIHexDecode")
 * in       - Input data
 * in_len   - Input length
 * params   - Optional decode params dict (may be NULL)
 * out      - Output buffer (must be initialized)
 *
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_filter_encode(const char *name,
                                    const uint8_t *in, size_t in_len,
                                    const pdfmake_obj_t *params,
                                    pdfmake_buf_t *out);

/*
 * Decode data through a named filter.
 *
 * Same parameters as encode. Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_filter_decode(const char *name,
                                    const uint8_t *in, size_t in_len,
                                    const pdfmake_obj_t *params,
                                    pdfmake_buf_t *out);

/*----------------------------------------------------------------------------
 * Filter chain encode/decode
 *--------------------------------------------------------------------------*/

/*
 * Decode data through a chain of filters.
 *
 * arena    - Arena containing interned name data
 * filters  - Array of filter names, or single name
 * params   - Array of param dicts, or single dict (may be NULL)
 * in       - Encoded input data
 * in_len   - Input length
 * out      - Output buffer (must be initialized)
 *
 * Filters are applied in reverse order (last filter in array is decoded first).
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_filter_chain_decode(pdfmake_arena_t *arena,
                                          const pdfmake_obj_t *filters,
                                          const pdfmake_obj_t *params,
                                          const uint8_t *in, size_t in_len,
                                          pdfmake_buf_t *out);

/*
 * Encode data through a chain of filters.
 *
 * Filters are applied in order (first filter in array is applied first).
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_filter_chain_encode(pdfmake_arena_t *arena,
                                          const pdfmake_obj_t *filters,
                                          const pdfmake_obj_t *params,
                                          const uint8_t *in, size_t in_len,
                                          pdfmake_buf_t *out);

/*----------------------------------------------------------------------------
 * FlateDecode (DEFLATE + zlib) — §7.4.4
 *--------------------------------------------------------------------------*/

/*
 * Decode FlateDecode data (zlib-wrapped DEFLATE).
 *
 * in       - zlib-compressed data (CMF + FLG header, Adler-32 trailer)
 * in_len   - Input length
 * params   - Optional DecodeParms dict for predictors
 * out      - Output buffer
 */
pdfmake_err_t pdfmake_flate_decode(const uint8_t *in, size_t in_len,
                                   const pdfmake_flate_params_t *params,
                                   pdfmake_buf_t *out);

/*
 * Encode data with FlateDecode (zlib-wrapped DEFLATE).
 *
 * in       - Uncompressed data
 * in_len   - Input length
 * params   - Optional DecodeParms dict for predictors
 * out      - Output buffer for compressed data
 */
pdfmake_err_t pdfmake_flate_encode(const uint8_t *in, size_t in_len,
                                   const pdfmake_flate_params_t *params,
                                   pdfmake_buf_t *out);

/*----------------------------------------------------------------------------
 * Raw DEFLATE (RFC 1951) — without zlib wrapper
 *--------------------------------------------------------------------------*/

/*
 * Decode raw DEFLATE data (no zlib header/trailer).
 */
pdfmake_err_t pdfmake_deflate_decode(const uint8_t *in, size_t in_len,
                                     pdfmake_buf_t *out);

/*
 * Encode data with raw DEFLATE (no zlib header/trailer).
 * level: 0=store, 1-4=fast, 5-9=better compression
 */
pdfmake_err_t pdfmake_deflate_encode(const uint8_t *in, size_t in_len,
                                     int level,
                                     pdfmake_buf_t *out);

/*----------------------------------------------------------------------------
 * Adler-32 checksum (RFC 1950)
 *--------------------------------------------------------------------------*/

/* Compute Adler-32 checksum of data. */
uint32_t pdfmake_adler32(const uint8_t *data, size_t len);

/* Update running Adler-32 with more data. */
uint32_t pdfmake_adler32_update(uint32_t adler, const uint8_t *data, size_t len);

/*----------------------------------------------------------------------------
 * Predictor functions (§7.4.4.4)
 *--------------------------------------------------------------------------*/

/*
 * Apply PNG predictor to encode data.
 * predictor: 10=None, 11=Sub, 12=Up, 13=Average, 14=Paeth, 15=Optimum
 */
pdfmake_err_t pdfmake_predictor_encode(int predictor,
                                       int colors, int bits_per_comp, int columns,
                                       const uint8_t *in, size_t in_len,
                                       pdfmake_buf_t *out);

/*
 * Remove PNG predictor from decoded data.
 */
pdfmake_err_t pdfmake_predictor_decode(int predictor,
                                       int colors, int bits_per_comp, int columns,
                                       const uint8_t *in, size_t in_len,
                                       pdfmake_buf_t *out);

/*
 * Apply TIFF predictor 2 (horizontal differencing).
 */
pdfmake_err_t pdfmake_tiff_predictor_encode(int colors, int bits_per_comp, int columns,
                                            const uint8_t *in, size_t in_len,
                                            pdfmake_buf_t *out);

/*
 * Remove TIFF predictor 2.
 */
pdfmake_err_t pdfmake_tiff_predictor_decode(int colors, int bits_per_comp, int columns,
                                            const uint8_t *in, size_t in_len,
                                            pdfmake_buf_t *out);

/*----------------------------------------------------------------------------
 * CCITTFaxDecode — fax compression (Group 3 / Group 4)
 *--------------------------------------------------------------------------*/

/* CCITTFaxDecode — ITU-T T.4 and T.6 fax compression */
pdfmake_err_t pdfmake_ccitt_decode(const uint8_t *in, size_t in_len,
                                   const pdfmake_obj_t *params,
                                   pdfmake_buf_t *out);

/*----------------------------------------------------------------------------
 * Stub filters (return PDFMAKE_EUNSUPPORTED)
 *--------------------------------------------------------------------------*/

/* JBIG2Decode — not implemented */
pdfmake_err_t pdfmake_jbig2_decode(const uint8_t *in, size_t in_len,
                                   const pdfmake_obj_t *params,
                                   pdfmake_buf_t *out);

/* JPXDecode — passthrough (JPEG 2000 data used as-is) */
pdfmake_err_t pdfmake_jpx_decode(const uint8_t *in, size_t in_len,
                                 const pdfmake_obj_t *params,
                                 pdfmake_buf_t *out);

/*----------------------------------------------------------------------------
 * ASCIIHexDecode — §7.4.2
 *--------------------------------------------------------------------------*/

/*
 * Decode ASCIIHex data: pairs of hex digits → bytes.
 * Whitespace is ignored. '>' marks end of data.
 * Odd final digit is padded with 0.
 */
pdfmake_err_t pdfmake_asciihex_decode(const uint8_t *in, size_t in_len,
                                      pdfmake_buf_t *out);

/*
 * Encode data as ASCIIHex: bytes → uppercase hex pairs + '>'.
 */
pdfmake_err_t pdfmake_asciihex_encode(const uint8_t *in, size_t in_len,
                                      pdfmake_buf_t *out);

/*----------------------------------------------------------------------------
 * ASCII85Decode — §7.4.3
 *--------------------------------------------------------------------------*/

/*
 * Decode ASCII85 data: 5 ASCII chars (33-117) → 4 bytes.
 * 'z' is shorthand for 4 zero bytes. '~>' marks end of data.
 * Final group may be 2-5 chars → 1-4 bytes.
 */
pdfmake_err_t pdfmake_ascii85_decode(const uint8_t *in, size_t in_len,
                                     pdfmake_buf_t *out);

/*
 * Encode data as ASCII85: 4 bytes → 5 ASCII chars + '~>'.
 * Uses 'z' shorthand for 4 zero bytes.
 */
pdfmake_err_t pdfmake_ascii85_encode(const uint8_t *in, size_t in_len,
                                     pdfmake_buf_t *out);

/*----------------------------------------------------------------------------
 * LZWDecode — §7.4.4
 *--------------------------------------------------------------------------*/

/*
 * Decode LZW data with variable-width codes (9-12 bits).
 * early_change: 1 (default) = increase code size before adding to table
 *               0 = increase after adding
 * Supports predictor params like FlateDecode.
 */
pdfmake_err_t pdfmake_lzw_decode(const uint8_t *in, size_t in_len,
                                 const pdfmake_flate_params_t *params,
                                 pdfmake_buf_t *out);

/*----------------------------------------------------------------------------
 * RunLengthDecode — §7.4.5
 *--------------------------------------------------------------------------*/

/*
 * Decode run-length encoded data.
 * Length byte N: 0-127 = copy N+1 bytes, 129-255 = repeat next byte 257-N times.
 * 128 = end of data.
 */
pdfmake_err_t pdfmake_rle_decode(const uint8_t *in, size_t in_len,
                                 pdfmake_buf_t *out);

/*
 * Encode data with run-length encoding.
 */
pdfmake_err_t pdfmake_rle_encode(const uint8_t *in, size_t in_len,
                                 pdfmake_buf_t *out);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_FILTER_H */
