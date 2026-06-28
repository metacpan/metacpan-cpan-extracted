/*
 * pdfmake_font_widths.h — Glyph-advance widths + descriptor metrics.
 *
 * Resolves:
 *   - Simple font /Widths  (§9.2.4) keyed by /FirstChar … /LastChar
 *   - CID font /W array    (§9.7.4.3) using format 1 (start [w w w]) and
 *                          format 2 (first last w) entries
 *   - /FontDescriptor /Ascent, /Descent, /CapHeight, /XHeight, /MissingWidth
 *
 * Advance-width lookup returns values in 1/1000 em; callers scale by
 * (font_size / 1000) to get user-space width.
 */

#ifndef PDFMAKE_FONT_WIDTHS_H
#define PDFMAKE_FONT_WIDTHS_H

#include "pdfmake_types.h"
#include "pdfmake_arena.h"

/* Forward declarations */
struct pdfmake_reader;

#ifdef __cplusplus
extern "C" {
#endif

/*============================================================================
 * Types
 *==========================================================================*/

/* A range [lo, hi] where every code has the same width (used for CID
 * format-2 entries and for uniform default ranges). */
typedef struct {
    uint32_t lo;
    uint32_t hi;
    int16_t  width;   /* 1/1000 em */
} pdfmake_width_range_t;

typedef struct {
    /* Direct lookup table for simple fonts (indexed by (code - first_char)).
     * NULL for CID fonts or simple fonts with no /Widths array. */
    int16_t *table;
    uint16_t first_char;
    uint16_t last_char;

    /* Range list for CID fonts or sparse codes (sorted by lo). */
    pdfmake_width_range_t *ranges;
    size_t                 range_count;

    /* Fallback width when a code is unmapped */
    int16_t default_width;

    /* Font descriptor metrics (1/1000 em). 0 means "not set"; the caller
     * should apply its own fallback. */
    int16_t ascent;
    int16_t descent;
    int16_t cap_height;
    int16_t x_height;
} pdfmake_font_widths_t;

/*============================================================================
 * Parsers
 *==========================================================================*/

/*
 * Initialize a widths struct to an empty state.
 */
void pdfmake_font_widths_init(pdfmake_font_widths_t *w);

/*
 * Populate `out` from a simple font dictionary.
 * Reads /FirstChar, /LastChar, /Widths. Also reads /FontDescriptor for
 * /Ascent, /Descent, /CapHeight, /XHeight, /MissingWidth.
 *
 * Returns 0 on success, -1 if the font dict is missing /Widths or otherwise
 * malformed (in which case out retains its init state).
 */
int pdfmake_font_widths_from_simple(
    pdfmake_arena_t       *arena,
    pdfmake_obj_t         *font_dict,
    pdfmake_font_widths_t *out);

/*
 * Populate `out` from a Type0/CID font dictionary.
 * Walks /DescendantFonts[0] for /W, /DW, and the descendant's /FontDescriptor.
 */
int pdfmake_font_widths_from_cid(
    pdfmake_arena_t       *arena,
    pdfmake_obj_t         *font_dict,
    pdfmake_font_widths_t *out);

/*
 * Phase 6: enhance an existing widths struct by pulling per-glyph advances
 * and descriptor metrics out of the embedded /FontFile2 TrueType stream.
 *
 * For simple fonts: `byte_to_unicode` is a 256-entry table (from the
 * resolved /Encoding) used to route charcode -> Unicode -> glyph-id.
 * Pass NULL for CID fonts.
 *
 * For CID fonts: callers should pass NULL for byte_to_unicode; the function
 * uses /CIDToGIDMap (Identity or stream) from the font dict.
 *
 * Returns 0 on success (out may have been overlaid with TTF data), -1 when
 * no /FontFile2 is present or parsing failed (out is left unchanged).
 */
int pdfmake_font_widths_enhance_with_ttf(
    pdfmake_arena_t         *arena,
    struct pdfmake_reader   *reader,
    pdfmake_obj_t           *font_dict,
    int                      is_cid,
    const uint32_t          *byte_to_unicode,   /* 256 entries, NULL for CID */
    pdfmake_font_widths_t   *out);

/*============================================================================
 * Lookup
 *==========================================================================*/

/*
 * Return the advance width in 1/1000 em for the given character code.
 * Returns w->default_width if no explicit mapping is found.
 */
int16_t pdfmake_font_widths_lookup(const pdfmake_font_widths_t *w,
                                    uint32_t code);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_FONT_WIDTHS_H */
