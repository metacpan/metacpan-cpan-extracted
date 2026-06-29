/*
 * pdfmake_text.h - Text rendering types and API
 *
 * Bridges fonts (pdfmake_font.h) with path rendering (pdfmake_render.h)
 * to render text characters as filled/stroked glyph outlines.
 *
 * Reference: PDF 32000-1:2008
 * - §9.3 Text state
 * - §9.4 Text objects
 * - §9.5 Introduction to Font Data Structures
 */

#ifndef PDFMAKE_TEXT_H
#define PDFMAKE_TEXT_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Forward declarations
 */
#ifndef PDFMAKE_FONT_T_DEFINED
#define PDFMAKE_FONT_T_DEFINED
typedef struct pdfmake_font pdfmake_font_t;
#endif
#ifndef PDFMAKE_PATH_T_DEFINED
#define PDFMAKE_PATH_T_DEFINED
typedef struct pdfmake_path pdfmake_path_t;
#endif
#ifndef PDFMAKE_RENDER_CTX_T_DEFINED
#define PDFMAKE_RENDER_CTX_T_DEFINED
typedef struct pdfmake_render_ctx pdfmake_render_ctx_t;
#endif
#ifndef PDFMAKE_ARENA_T_DEFINED
#define PDFMAKE_ARENA_T_DEFINED
typedef struct pdfmake_arena pdfmake_arena_t;
#endif

/*============================================================================
 * Error codes
 *==========================================================================*/

typedef enum {
    PDFMAKE_TEXT_OK = 0,
    PDFMAKE_TEXT_ERR_NULL,
    PDFMAKE_TEXT_ERR_MEMORY,
    PDFMAKE_TEXT_ERR_INVALID_FONT,
    PDFMAKE_TEXT_ERR_GLYPH_NOT_FOUND,
    PDFMAKE_TEXT_ERR_PARSE_ERROR,
    PDFMAKE_TEXT_ERR_UNSUPPORTED,
} pdfmake_text_err_t;

/*============================================================================
 * Text render modes (§9.3.6)
 *==========================================================================*/

typedef enum {
    PDFMAKE_TEXT_FILL           = 0,    /* Fill text */
    PDFMAKE_TEXT_STROKE         = 1,    /* Stroke text */
    PDFMAKE_TEXT_FILL_STROKE    = 2,    /* Fill then stroke */
    PDFMAKE_TEXT_INVISIBLE      = 3,    /* Neither fill nor stroke (invisible) */
    PDFMAKE_TEXT_FILL_CLIP      = 4,    /* Fill and add to clip path */
    PDFMAKE_TEXT_STROKE_CLIP    = 5,    /* Stroke and add to clip path */
    PDFMAKE_TEXT_FILL_STROKE_CLIP = 6,  /* Fill, stroke, and clip */
    PDFMAKE_TEXT_CLIP           = 7,    /* Add to clip path only */
} pdfmake_text_render_mode_t;

/*============================================================================
 * Glyph outline - cached path data for a glyph
 *==========================================================================*/

typedef struct pdfmake_glyph_outline {
    uint16_t glyph_id;
    int16_t advance_width;      /* Advance width in font units */
    int16_t lsb;                /* Left side bearing */
    
    /* Bounding box in font units */
    int16_t x_min;
    int16_t y_min;
    int16_t x_max;
    int16_t y_max;
    
    /* Path outline (normalized to font units, y-up) */
    pdfmake_path_t *path;
    
    /* Flags */
    uint8_t loaded;             /* 1 if outline has been loaded */
    uint8_t composite;          /* 1 if glyph is composite */
} pdfmake_glyph_outline_t;

/*============================================================================
 * Glyph cache - per-font outline storage
 *==========================================================================*/

typedef struct pdfmake_glyph_cache {
    pdfmake_glyph_outline_t *glyphs; /* Array indexed by glyph_id */
    size_t glyph_count;              /* Number of glyphs (from maxp) */
    size_t loaded_count;             /* Number of loaded outlines */
    pdfmake_arena_t *arena;          /* Arena for path allocations */
} pdfmake_glyph_cache_t;

/*============================================================================
 * Text state - current text rendering parameters (§9.3)
 *==========================================================================*/

typedef struct pdfmake_text_state {
    /* Font and size */
    pdfmake_font_t *font;
    double font_size;           /* Tf operand */
    
    /* Spacing */
    double char_spacing;        /* Tc - extra spacing after each char */
    double word_spacing;        /* Tw - extra spacing for ASCII space */
    double horiz_scale;         /* Th - horizontal scaling (1.0 = 100%) */
    double leading;             /* TL - line spacing for T* and ' */
    double text_rise;           /* Ts - baseline shift (superscript/subscript) */
    
    /* Render mode */
    pdfmake_text_render_mode_t render_mode; /* Tr */
    
    /* Text matrix (Tm) - transforms text space to user space */
    double tm[6];               /* [a b c d e f] */
    
    /* Text line matrix (Tlm) - start of line for T* */
    double tlm[6];
    
    /* Glyph cache for current font */
    pdfmake_glyph_cache_t *cache;
} pdfmake_text_state_t;

/*============================================================================
 * Text element for TJ operator (positioned text array)
 *==========================================================================*/

typedef enum {
    PDFMAKE_TEXT_ELEM_STRING,   /* Text string */
    PDFMAKE_TEXT_ELEM_ADJUST,   /* Numeric adjustment */
} pdfmake_text_elem_type_t;

typedef struct pdfmake_text_element {
    pdfmake_text_elem_type_t type;
    union {
        struct {
            const uint8_t *data;
            size_t len;
        } string;
        double adjust;          /* Negative = move right (in 1/1000 em) */
    } u;
} pdfmake_text_element_t;

/*============================================================================
 * API - Text State Management
 *==========================================================================*/

/*
 * Initialize text state with defaults.
 */
void pdfmake_text_state_init(pdfmake_text_state_t *ts);

/*
 * Reset text state to defaults.
 */
void pdfmake_text_state_reset(pdfmake_text_state_t *ts);

/*
 * Set font and size (Tf operator).
 * Creates glyph cache if needed.
 */
pdfmake_text_err_t pdfmake_text_set_font(
    pdfmake_text_state_t *ts,
    pdfmake_font_t *font,
    double size,
    pdfmake_arena_t *arena);

/*
 * Set text matrix (Tm operator).
 */
void pdfmake_text_set_matrix(pdfmake_text_state_t *ts, 
                              double a, double b, double c, double d,
                              double e, double f);

/*
 * Move to next line (T* operator).
 * Uses leading (TL) for vertical offset.
 */
void pdfmake_text_next_line(pdfmake_text_state_t *ts);

/*
 * Move to position relative to line start (Td/TD operators).
 */
void pdfmake_text_move(pdfmake_text_state_t *ts, double tx, double ty);

/*============================================================================
 * API - Glyph Outline Access
 *==========================================================================*/

/*
 * Create glyph cache for a font.
 */
pdfmake_glyph_cache_t *pdfmake_glyph_cache_create(
    pdfmake_font_t *font,
    pdfmake_arena_t *arena);

/*
 * Free glyph cache.
 * If using arena, this is optional.
 */
void pdfmake_glyph_cache_free(pdfmake_glyph_cache_t *cache);

/*
 * Get glyph outline, loading if necessary.
 * Returns NULL if glyph_id is invalid.
 */
pdfmake_glyph_outline_t *pdfmake_glyph_get(
    pdfmake_glyph_cache_t *cache,
    pdfmake_font_t *font,
    uint16_t glyph_id);

/*
 * Load glyph outline from font.
 * Called automatically by pdfmake_glyph_get.
 * For TrueType: parses glyf table, converts quadratic to cubic.
 * For CFF: parses Type2 charstrings.
 */
pdfmake_text_err_t pdfmake_glyph_load(
    pdfmake_glyph_cache_t *cache,
    pdfmake_font_t *font,
    uint16_t glyph_id);

/*============================================================================
 * API - TrueType Glyph Parsing
 *==========================================================================*/

/*
 * Parse TrueType glyph outline from glyf table.
 * Converts quadratic Bezier to cubic.
 * 
 * Quadratic (P0,P1,P2) -> Cubic (P0,C1,C2,P3):
 *   C1 = P0 + 2/3 * (P1 - P0)
 *   C2 = P2 + 2/3 * (P1 - P2)
 */
pdfmake_text_err_t pdfmake_ttf_load_glyph(
    pdfmake_glyph_outline_t *outline,
    pdfmake_font_t *font,
    uint16_t glyph_id,
    pdfmake_arena_t *arena);

/*
 * Parse composite glyph (references other glyphs).
 */
pdfmake_text_err_t pdfmake_ttf_load_composite_glyph(
    pdfmake_glyph_outline_t *outline,
    pdfmake_font_t *font,
    uint16_t glyph_id,
    pdfmake_glyph_cache_t *cache,
    pdfmake_arena_t *arena);

/*============================================================================
 * API - CFF Glyph Parsing
 *==========================================================================*/

/*
 * Parse CFF CharString to path outline.
 * CFF uses cubic Bezier directly (no conversion needed).
 */
pdfmake_text_err_t pdfmake_cff_load_glyph(
    pdfmake_glyph_outline_t *outline,
    const uint8_t *cff_data,
    size_t cff_len,
    uint16_t glyph_id,
    pdfmake_arena_t *arena);

/*============================================================================
 * API - Text Rendering
 *==========================================================================*/

/*
 * Render a text string (Tj operator).
 * Decodes bytes using font's encoding, renders each glyph.
 */
pdfmake_text_err_t pdfmake_render_text(
    pdfmake_render_ctx_t *ctx,
    pdfmake_text_state_t *ts,
    const uint8_t *text,
    size_t len);

/*
 * Render UTF-8 text string.
 * Converts to font encoding internally.
 */
pdfmake_text_err_t pdfmake_render_text_utf8(
    pdfmake_render_ctx_t *ctx,
    pdfmake_text_state_t *ts,
    const char *text,
    size_t len);

/*
 * Render positioned text (TJ operator).
 * Array of strings and position adjustments.
 */
pdfmake_text_err_t pdfmake_render_text_positioned(
    pdfmake_render_ctx_t *ctx,
    pdfmake_text_state_t *ts,
    const pdfmake_text_element_t *elements,
    size_t count);

/*
 * Render single glyph at current position.
 * Updates text position after rendering.
 */
pdfmake_text_err_t pdfmake_render_glyph(
    pdfmake_render_ctx_t *ctx,
    pdfmake_text_state_t *ts,
    uint16_t glyph_id);

/*============================================================================
 * API - Encoding and Character Mapping
 *==========================================================================*/

/*
 * Map character code to glyph ID using font's encoding.
 * For TrueType: uses cmap table.
 * For Standard 14: uses built-in WinAnsi or Symbol encoding.
 */
uint16_t pdfmake_text_char_to_glyph(
    pdfmake_font_t *font,
    uint32_t charcode);

/*
 * Map Unicode codepoint to glyph ID.
 * Uses font's cmap (TrueType) or encoding tables.
 */
uint16_t pdfmake_text_unicode_to_glyph(
    pdfmake_font_t *font,
    uint32_t unicode);

/*
 * Get glyph advance width in text space units.
 * Accounts for font size but not char_spacing or horiz_scale.
 */
double pdfmake_text_glyph_advance(
    pdfmake_font_t *font,
    uint16_t glyph_id,
    double font_size);

/*
 * Calculate text width for a string.
 * Includes char_spacing, word_spacing, and horiz_scale.
 */
double pdfmake_text_string_width(
    pdfmake_text_state_t *ts,
    const uint8_t *text,
    size_t len);

/*============================================================================
 * API - Encoding Tables
 *==========================================================================*/

/*
 * Standard encoding tables (256 entries each).
 * Maps char code (0-255) to Unicode codepoint.
 * 0xFFFF indicates undefined character.
 */
extern const uint16_t pdfmake_encoding_standard[256];
extern const uint16_t pdfmake_encoding_winansi[256];
extern const uint16_t pdfmake_encoding_macroman[256];
extern const uint16_t pdfmake_encoding_symbol[256];
extern const uint16_t pdfmake_encoding_zapfdingbats[256];

/*
 * Get encoding table by name.
 * Names: "StandardEncoding", "WinAnsiEncoding", "MacRomanEncoding",
 *        "MacExpertEncoding", "SymbolEncoding", "ZapfDingbatsEncoding"
 */
const uint16_t *pdfmake_encoding_get(const char *name);

/*============================================================================
 * Utility Functions
 *==========================================================================*/

/*
 * Transform a path by a matrix.
 * Modifies path in place.
 */
void pdfmake_path_transform(pdfmake_path_t *path, const double m[6]);

/*
 * Copy a path with transformation.
 * Returns new path in arena.
 */
pdfmake_path_t *pdfmake_path_transform_copy(
    pdfmake_path_t *src,
    const double m[6],
    pdfmake_arena_t *arena);

/*
 * Get combined text matrix: text_matrix * CTM
 * Result transforms from glyph space to device space.
 */
void pdfmake_text_combined_matrix(
    pdfmake_text_state_t *ts,
    pdfmake_render_ctx_t *ctx,
    double out[6]);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_TEXT_H */
