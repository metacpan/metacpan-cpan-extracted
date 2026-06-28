/*
 * pdfmake_cmap.h — PDF ToUnicode CMap parser.
 *
 * Parses the PostScript CMap format used in /ToUnicode streams to map
 * character codes (1- or 2-byte) to Unicode codepoints. Implements the
 * subset of CMap syntax actually used for text extraction:
 *
 *   beginbfchar <code> <uni> endbfchar
 *   beginbfrange <lo> <hi> <uni> endbfrange
 *   beginbfrange <lo> <hi> [<uni1> <uni2> ...] endbfrange
 *   begincidchar ... endcidchar     (rare, same shape as bfchar)
 *   begincidrange ... endcidrange   (rare, same shape as bfrange)
 *
 * codespacerange is noted (for byte-width detection) but not enforced.
 *
 * Reference: Adobe Tech Note #5411, §9.10.3 (PDF 32000).
 */

#ifndef PDFMAKE_CMAP_H
#define PDFMAKE_CMAP_H

#include "pdfmake_types.h"
#include "pdfmake_arena.h"

#ifdef __cplusplus
extern "C" {
#endif

/*============================================================================
 * Types
 *==========================================================================*/

typedef struct pdfmake_cmap pdfmake_cmap_t;

/*============================================================================
 * Parsing
 *==========================================================================*/

/*
 * Parse a ToUnicode CMap from raw bytes (after FlateDecode).
 * Returns NULL on parse failure or allocation failure.
 * The returned CMap is allocated in the arena; do not free separately.
 */
pdfmake_cmap_t *pdfmake_cmap_parse(pdfmake_arena_t *arena,
                                    const uint8_t *data, size_t len);

/*============================================================================
 * Lookup
 *==========================================================================*/

/* Maximum number of Unicode codepoints a single code can map to.
 * ToUnicode allows ligatures like "ffi" (3 codepoints) and surrogate pairs. */
#define PDFMAKE_CMAP_MAX_UNI 4

/*
 * Look up a character code.
 *
 * code      - Character code (1- or 2-byte; callers pass the full value).
 * out       - Buffer to receive Unicode codepoints (must have PDFMAKE_CMAP_MAX_UNI slots).
 * out_count - Receives number of codepoints written.
 *
 * Returns 1 if found, 0 if unmapped.
 */
int pdfmake_cmap_lookup(const pdfmake_cmap_t *cmap,
                        uint32_t code,
                        uint32_t *out,
                        size_t   *out_count);

/*============================================================================
 * Introspection
 *==========================================================================*/

/* Get the detected code byte width (1 or 2). Returns 0 if not detected. */
int pdfmake_cmap_code_width(const pdfmake_cmap_t *cmap);

/* Get total number of mappings (for diagnostics). */
size_t pdfmake_cmap_size(const pdfmake_cmap_t *cmap);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_CMAP_H */
