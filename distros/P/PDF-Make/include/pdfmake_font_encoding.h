/*
 * pdfmake_font_encoding.h — Resolved per-font encoding for text extraction.
 *
 * Wraps a base encoding table (WinAnsi / MacRoman / Standard / MacExpert /
 * Symbol / ZapfDingbats) with a /Differences overlay, producing a 256-entry
 * byte -> Unicode map for simple (1-byte) fonts.
 *
 * For CID / Type0 fonts this module is not used; decoding goes through
 * pdfmake_cmap instead.
 *
 * Reference: §9.6.5 (PDF 32000), §9.6.6, §D.1-D.4 (base encodings).
 */

#ifndef PDFMAKE_FONT_ENCODING_H
#define PDFMAKE_FONT_ENCODING_H

#include "pdfmake_types.h"
#include "pdfmake_arena.h"

#ifdef __cplusplus
extern "C" {
#endif

/*============================================================================
 * Types
 *==========================================================================*/

/* A resolved encoding: byte -> Unicode codepoint for all 256 byte values.
 * Undefined bytes map to 0 (caller should treat 0 as unmapped). */
typedef struct {
    uint32_t map[256];
} pdfmake_font_encoding_t;

/*============================================================================
 * Base encoding initializers
 *==========================================================================*/

/* Populate `enc` with the given base encoding. */
void pdfmake_font_encoding_init_standard   (pdfmake_font_encoding_t *enc);
void pdfmake_font_encoding_init_winansi    (pdfmake_font_encoding_t *enc);
void pdfmake_font_encoding_init_macroman   (pdfmake_font_encoding_t *enc);
void pdfmake_font_encoding_init_macexpert  (pdfmake_font_encoding_t *enc);
void pdfmake_font_encoding_init_symbol     (pdfmake_font_encoding_t *enc);
void pdfmake_font_encoding_init_zapfdingbats(pdfmake_font_encoding_t *enc);

/* Look up a base encoding by PostScript name. Returns 1 if known,
 * 0 otherwise (enc is set to WinAnsi as a safe default when unknown). */
int pdfmake_font_encoding_init_by_name(pdfmake_font_encoding_t *enc,
                                        const char *name);

/*============================================================================
 * /Encoding dict resolution
 *==========================================================================*/

/*
 * Resolve a font's /Encoding entry into `out`.
 *
 * encoding_obj may be:
 *   - NULL              -> StandardEncoding (spec default for Type1 fonts)
 *   - a name object     -> base encoding lookup
 *   - a dict with:
 *       /BaseEncoding <name>          (optional; defaults to StandardEncoding)
 *       /Differences  [code /glyph /glyph ... code /glyph ...]
 *
 * arena is used to intern name keys. Returns 0 on success, -1 on error.
 * On error, `out` is still populated with a WinAnsi fallback.
 */
int pdfmake_font_encoding_from_dict(
    pdfmake_arena_t       *arena,
    pdfmake_obj_t         *encoding_obj,
    pdfmake_font_encoding_t *out);

/*============================================================================
 * Lookup
 *==========================================================================*/

/* Decode a single byte. Returns 0 for unmapped. */
static PDFMAKE_INLINE uint32_t pdfmake_font_encoding_lookup(
    const pdfmake_font_encoding_t *enc, uint8_t byte)
{
    return enc->map[byte];
}

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_FONT_ENCODING_H */
