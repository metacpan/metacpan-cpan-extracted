/*
 * pdfmake_font.h - Font handling (Standard 14, TrueType embed/subset, ToUnicode)
 *
 * Reference: PDF 32000-1:2008
 * - §9.6 Simple fonts (Type 1, TrueType)
 * - §9.7 Composite fonts (CIDFont, Type 0)
 * - §9.8 Font descriptors
 * - §9.10 ToUnicode mapping
 */

#ifndef PDFMAKE_FONT_H
#define PDFMAKE_FONT_H

#include <stddef.h>
#include <stdint.h>
#include "pdfmake_types.h"
#include "pdfmake_buf.h"

#ifdef __cplusplus
extern "C" {
#endif

/*============================================================================
 * Forward declarations
 *==========================================================================*/

#ifndef PDFMAKE_FONT_T_DEFINED
#define PDFMAKE_FONT_T_DEFINED
typedef struct pdfmake_font pdfmake_font_t;
#endif

/*============================================================================
 * Font types
 *==========================================================================*/

typedef enum {
    PDFMAKE_FONT_TYPE1,         /* Standard 14 Type1 fonts */
    PDFMAKE_FONT_TRUETYPE,      /* TrueType font (embedded) */
    PDFMAKE_FONT_CID_TRUETYPE   /* CIDFontType2 (TrueType with CID mapping) */
} pdfmake_font_type_t;

/*============================================================================
 * Standard 14 font IDs
 *==========================================================================*/

typedef enum {
    PDFMAKE_STD14_HELVETICA = 0,
    PDFMAKE_STD14_HELVETICA_BOLD,
    PDFMAKE_STD14_HELVETICA_OBLIQUE,
    PDFMAKE_STD14_HELVETICA_BOLDOBLIQUE,
    PDFMAKE_STD14_TIMES_ROMAN,
    PDFMAKE_STD14_TIMES_BOLD,
    PDFMAKE_STD14_TIMES_ITALIC,
    PDFMAKE_STD14_TIMES_BOLDITALIC,
    PDFMAKE_STD14_COURIER,
    PDFMAKE_STD14_COURIER_BOLD,
    PDFMAKE_STD14_COURIER_OBLIQUE,
    PDFMAKE_STD14_COURIER_BOLDOBLIQUE,
    PDFMAKE_STD14_SYMBOL,
    PDFMAKE_STD14_ZAPFDINGBATS,
    PDFMAKE_STD14_COUNT
} pdfmake_std14_id_t;

/*============================================================================
 * Font flags (§9.8.2 Table 123)
 *==========================================================================*/

#define PDFMAKE_FONT_FLAG_FIXED_PITCH    (1 << 0)   /* All glyphs same width */
#define PDFMAKE_FONT_FLAG_SERIF          (1 << 1)   /* Glyphs have serifs */
#define PDFMAKE_FONT_FLAG_SYMBOLIC       (1 << 2)   /* Non-standard char set */
#define PDFMAKE_FONT_FLAG_SCRIPT         (1 << 3)   /* Script/cursive */
#define PDFMAKE_FONT_FLAG_NONSYMBOLIC    (1 << 5)   /* Adobe standard encoding */
#define PDFMAKE_FONT_FLAG_ITALIC         (1 << 6)   /* Italic/oblique */
#define PDFMAKE_FONT_FLAG_ALLCAP         (1 << 16)  /* No lowercase */
#define PDFMAKE_FONT_FLAG_SMALLCAP       (1 << 17)  /* Lowercase are small caps */
#define PDFMAKE_FONT_FLAG_FORCE_BOLD     (1 << 18)  /* Force bold at small sizes */

/*============================================================================
 * Font metrics structure
 *==========================================================================*/

typedef struct {
    int   ascent;           /* Ascender height (units/1000 em) */
    int   descent;          /* Descender depth (negative, units/1000 em) */
    int   cap_height;       /* Capital letter height */
    int   x_height;         /* Lowercase x height */
    int   stem_v;           /* Vertical stem width */
    int   stem_h;           /* Horizontal stem width */
    int   italic_angle;     /* Italic angle (degrees, negative = right lean) */
    int   bbox[4];          /* Font bounding box [llx, lly, urx, ury] */
    uint32_t flags;         /* Font flags (§9.8.2) */
} pdfmake_font_metrics_t;

/*============================================================================
 * TTF table offsets (for parsed TrueType)
 *==========================================================================*/

typedef struct {
    uint32_t offset;
    uint32_t length;
} pdfmake_ttf_table_loc_t;

/*============================================================================
 * TrueType font data
 *==========================================================================*/

typedef struct {
    const uint8_t *data;        /* Original TTF data (not owned) */
    size_t         data_len;

    /* Table locations */
    pdfmake_ttf_table_loc_t head;
    pdfmake_ttf_table_loc_t hhea;
    pdfmake_ttf_table_loc_t hmtx;
    pdfmake_ttf_table_loc_t maxp;
    pdfmake_ttf_table_loc_t cmap;
    pdfmake_ttf_table_loc_t glyf;
    pdfmake_ttf_table_loc_t loca;
    pdfmake_ttf_table_loc_t name;
    pdfmake_ttf_table_loc_t post;
    pdfmake_ttf_table_loc_t os2;
    pdfmake_ttf_table_loc_t cvt;
    pdfmake_ttf_table_loc_t fpgm;
    pdfmake_ttf_table_loc_t prep;

    /* Parsed header values */
    uint16_t units_per_em;
    uint16_t num_glyphs;
    uint16_t num_h_metrics;
    int16_t  index_to_loc_format;   /* 0 = short, 1 = long */

    /* cmap subtable location */
    uint32_t cmap_offset;           /* Offset to selected subtable */
    uint16_t cmap_format;           /* Subtable format (4, 12, etc.) */

    /* Metrics from head/hhea/OS/2 */
    int16_t  x_min, y_min, x_max, y_max;  /* Font bbox from head */
    int16_t  ascender, descender;         /* From hhea */
    int16_t  line_gap;
    int16_t  mac_style;                   /* From head */

    /* OS/2 table values (if present) */
    int      has_os2;
    uint16_t us_weight_class;
    uint16_t us_width_class;
    int16_t  s_typo_ascender;
    int16_t  s_typo_descender;
    int16_t  s_typo_line_gap;
    int16_t  s_cap_height;
    int16_t  s_x_height;
    uint16_t fs_selection;

    /* Glyph tracking for subsetting */
    uint8_t *used_glyphs;           /* Bitmap: used_glyphs[gid/8] & (1 << (gid%8)) */
    size_t   used_count;            /* Number of used glyphs */
} pdfmake_ttf_t;

/*============================================================================
 * Font structure
 *==========================================================================*/

struct pdfmake_font {
    pdfmake_font_type_t type;
    
    /* For Standard 14 */
    pdfmake_std14_id_t std14_id;
    const char *base_font;          /* PostScript name e.g. "Helvetica" */
    
    /* For TrueType */
    pdfmake_ttf_t *ttf;             /* Parsed TTF data */
    
    /* Common metrics */
    pdfmake_font_metrics_t metrics;
    
    /* Object references (set after writing) */
    pdfmake_ref_t font_ref;         /* /Font dictionary reference */
    pdfmake_ref_t descriptor_ref;   /* /FontDescriptor reference */
    pdfmake_ref_t fontfile_ref;     /* /FontFile2 reference (TrueType) */
    pdfmake_ref_t tounicode_ref;    /* /ToUnicode CMap reference */
    
    /* PDF resource name (e.g. "F1", "F2") */
    char resource_name[16];
    
    /* Arena for allocations */
    pdfmake_arena_t *arena;
};

/*============================================================================
 * Standard 14 width table entry
 *==========================================================================*/

typedef struct {
    uint16_t codepoint;     /* Unicode codepoint (or glyph index for Symbol) */
    int16_t  width;         /* Width in units of 1/1000 em */
} pdfmake_std14_width_t;

/*============================================================================
 * Standard 14 font metrics
 *==========================================================================*/

typedef struct {
    const char *name;                       /* PostScript name */
    const pdfmake_std14_width_t *widths;    /* Width table */
    size_t width_count;                     /* Number of entries */
    pdfmake_font_metrics_t metrics;         /* Font metrics */
} pdfmake_std14_data_t;

/*============================================================================
 * API - Standard 14 fonts
 *==========================================================================*/

/*
 * Get Standard 14 font data by ID.
 * Returns NULL if id is invalid.
 */
const pdfmake_std14_data_t *pdfmake_std14_get(pdfmake_std14_id_t id);

/*
 * Look up Standard 14 font by name (case-insensitive).
 * Returns -1 if not found.
 */
int pdfmake_std14_lookup(const char *name);

/*
 * Get glyph width for Standard 14 font.
 * Returns width in units of 1/1000 em, or 0 if not found.
 */
int pdfmake_std14_width(pdfmake_std14_id_t id, uint32_t codepoint);

/*============================================================================
 * API - Font creation
 *==========================================================================*/

/*
 * Create a Standard 14 font.
 * base_font: One of "Helvetica", "Times-Roman", etc.
 * Returns NULL on error (unknown font name).
 */
pdfmake_font_t *pdfmake_font_standard14(pdfmake_arena_t *arena, const char *base_font);

/*
 * Create a TrueType font from TTF data.
 * The ttf_bytes are copied into the arena.
 * Returns NULL on parse error.
 */
pdfmake_font_t *pdfmake_font_from_ttf(pdfmake_arena_t *arena, 
                                       const uint8_t *ttf_bytes, size_t len);

/*
 * Free font resources (called automatically when arena is freed).
 */
void pdfmake_font_free(pdfmake_font_t *font);

/*============================================================================
 * API - Font metrics
 *==========================================================================*/

/*
 * Get glyph advance width.
 * For Standard 14: codepoint is Unicode.
 * For TrueType: codepoint is Unicode (mapped via cmap).
 * Returns advance in PDF units (scaled by font_size).
 */
double pdfmake_font_advance(const pdfmake_font_t *font, 
                            uint32_t codepoint, double font_size);

/*
 * Get string width in PDF units.
 * utf8: UTF-8 encoded string.
 */
double pdfmake_font_string_width(const pdfmake_font_t *font,
                                  const char *utf8, size_t len,
                                  double font_size);

/*
 * Get font metrics.
 */
const pdfmake_font_metrics_t *pdfmake_font_metrics(const pdfmake_font_t *font);

/*============================================================================
 * API - Text encoding
 *==========================================================================*/

/*
 * Encode UTF-8 string to PDF string bytes.
 * For Standard 14: WinAnsi encoding (single-byte, with fallbacks).
 * For TrueType CID: CID encoding (2-byte big-endian glyph IDs).
 * Also marks used glyphs for subsetting.
 * Returns bytes to put inside (...) in a Tj operator.
 */
pdfmake_err_t pdfmake_font_encode_utf8(pdfmake_font_t *font,
                                        const char *utf8, size_t len,
                                        pdfmake_buf_t *out_bytes);

/*============================================================================
 * API - PDF output
 *==========================================================================*/

/*
 * Write font to PDF document.
 * Creates /Font dict, /FontDescriptor, embedded font data, /ToUnicode.
 * For TrueType: performs subsetting based on used glyphs.
 * Returns the /Font dictionary reference.
 */
pdfmake_ref_t pdfmake_font_write(pdfmake_font_t *font, pdfmake_doc_t *doc);

/*============================================================================
 * API - TrueType parsing
 *==========================================================================*/

/*
 * Parse TrueType font data.
 * Returns NULL on error.
 */
pdfmake_ttf_t *pdfmake_ttf_parse(pdfmake_arena_t *arena,
                                  const uint8_t *data, size_t len);

/*
 * Look up glyph ID for Unicode codepoint.
 * Returns 0 (.notdef) if not found.
 */
uint16_t pdfmake_ttf_cmap_lookup(const pdfmake_ttf_t *ttf, uint32_t codepoint);

/*
 * Get glyph advance width in font units.
 */
uint16_t pdfmake_ttf_glyph_advance(const pdfmake_ttf_t *ttf, uint16_t glyph_id);

/*
 * Mark glyph as used (for subsetting).
 */
void pdfmake_ttf_mark_glyph(pdfmake_ttf_t *ttf, uint16_t glyph_id);

/*
 * Create subset TTF containing only used glyphs.
 * Returns new TTF data in out_buf.
 */
pdfmake_err_t pdfmake_ttf_subset(const pdfmake_ttf_t *ttf,
                                  pdfmake_buf_t *out_buf);

/*============================================================================
 * API - ToUnicode CMap
 *==========================================================================*/

/*
 * Generate ToUnicode CMap stream for font.
 * Maps CID/glyph IDs back to Unicode for text extraction.
 */
pdfmake_err_t pdfmake_tounicode_generate(const pdfmake_font_t *font,
                                          pdfmake_buf_t *out_buf);

/*============================================================================
 * API - CID font helpers
 *==========================================================================*/

/*
 * Generate /W (widths) array for CIDFontType2.
 * Format: [ cid [w1 w2 ...] cid w ... ]
 */
pdfmake_err_t pdfmake_cid_widths(const pdfmake_font_t *font,
                                  pdfmake_buf_t *out_buf);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_FONT_H */
