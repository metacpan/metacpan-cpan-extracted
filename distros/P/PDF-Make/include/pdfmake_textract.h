/*
 * pdfmake_textract.h — Text extraction with coordinates.
 *
 * Hooks into the content stream interpreter via a visitor to capture
 * text-show events, decode font bytes to Unicode, compute per-glyph
 * bounding boxes in user space, and aggregate into words/lines/blocks.
 *
 * §9.4 Text objects, §9.10 Extraction of text content
 */

#ifndef PDFMAKE_TEXTRACT_H
#define PDFMAKE_TEXTRACT_H

#include "pdfmake_types.h"
#include "pdfmake_arena.h"
#include "pdfmake_interpreter.h"
#include "pdfmake_font.h"
#include "pdfmake_cmap.h"
#include "pdfmake_font_encoding.h"
#include "pdfmake_font_widths.h"

/* Forward declaration to avoid circular include */
struct pdfmake_reader;

#ifdef __cplusplus
extern "C" {
#endif

/*============================================================================
 * Extracted text structures
 *==========================================================================*/

/* A single glyph with bounding box in user space */
typedef struct {
    uint32_t unicode;          /* Unicode codepoint (U+FFFD if unknown) */
    double   x0, y0, x1, y1;   /* Bounding box in user space */
    double   advance;          /* Glyph advance width in user space */
    double   font_size;        /* Font size at rendering time */
    uint8_t  reliable_advance; /* 1 if advance came from /Widths or Std14;
                                * 0 if a 0.5-em fallback was used. Used by
                                * the word-boundary heuristic to decide how
                                * strictly to treat horizontal gaps. */
    int32_t  mcid;             /* Phase 12: active /MCID from enclosing
                                * BDC marked-content dict, or -1 if none. */
    uint8_t  vertical;         /* Phase 14: 1 if rendered in WMode 1 (top-
                                * to-bottom). Changes how the aggregator
                                * groups glyphs into "lines" (columns). */
} pdfmake_text_glyph_t;

/* A word: sequence of glyphs with no significant gap */
typedef struct {
    pdfmake_text_glyph_t *glyphs;
    size_t                len;
    size_t                cap;
    double                x0, y0, x1, y1;  /* Bounding box (union of glyphs) */
    int32_t               mcid;            /* Phase 12: dominant MCID of
                                            * constituent glyphs, or -1 if
                                            * none. Set during aggregation. */
} pdfmake_text_word_t;

/* A line: sequence of words on the same baseline */
typedef struct {
    pdfmake_text_word_t  *words;
    size_t                len;
    size_t                cap;
    double                x0, y0, x1, y1;
    double                baseline_y;
} pdfmake_text_line_t;

/* A block: sequence of lines with consistent alignment */
typedef struct {
    pdfmake_text_line_t  *lines;
    size_t                len;
    size_t                cap;
    double                x0, y0, x1, y1;
} pdfmake_text_block_t;

/* Per-font resolution cache.
 * Populated lazily the first time a font dict is seen during extraction. */
typedef struct pdfmake_resolved_font {
    pdfmake_obj_t          *font_dict;       /* identity key (pointer compare) */
    pdfmake_cmap_t         *to_unicode;      /* NULL if no /ToUnicode stream */
    pdfmake_font_encoding_t encoding;        /* byte -> Unicode fallback */
    pdfmake_font_widths_t   widths;          /* code -> advance (1/1000 em) */
    int                     is_cid;          /* 1 if Type0/CID font */
    int                     std14_id;        /* -1 if not Std14 */
    int                     to_unicode_tried; /* 1 once resolution attempted */
    int                     encoding_resolved; /* 1 once encoding populated */
    int                     widths_resolved;  /* 1 once widths populated */

    /* Phase 14: 1 = WMode 1 (vertical), 0 = WMode 0 (horizontal).
     * Derived from the Type0 /Encoding name: a trailing "-V" implies
     * vertical; CMap streams with /WMode 1 also flip this. */
    int                     wmode;
    /* Default vertical advance in 1/1000 em (/DW2 second element, defaults
     * to -1000 per PDF spec). Only meaningful when wmode == 1. */
    int16_t                 default_v_advance;
} pdfmake_resolved_font_t;

/* Phase 12: mapping from MCID (per-page) to a structure-element role.
 * One entry per marked-content item encountered while walking
 * /StructTreeRoot for the page being extracted. */
typedef struct {
    int32_t  mcid;
    uint32_t role_id;           /* interned name id of /S (e.g. "H1", "P") */
} pdfmake_struct_map_entry_t;

/* Extraction result */
typedef struct {
    pdfmake_text_block_t *blocks;
    size_t                len;
    size_t                cap;

    /* Raw glyph list (before aggregation) */
    pdfmake_text_glyph_t *raw_glyphs;
    size_t                raw_len;
    size_t                raw_cap;

    /* Arena for name interning during font resolution */
    pdfmake_arena_t      *arena;

    /* Optional reader pointer (lets us resolve /ToUnicode streams).
     * May be NULL when extraction runs without a reader context. */
    struct pdfmake_reader *reader;

    /* Per-font cache (small linear array; typical page has 1-5 fonts) */
    pdfmake_resolved_font_t *font_cache;
    size_t                   font_cache_len;
    size_t                   font_cache_cap;

    /* Phase 10: column reading order.
     * column_splits[] holds ascending x-coordinates (in user space) that
     * partition the page into columns. Glyph column index = number of
     * splits with split <= glyph.x0. When column_split_count == 0 the
     * page is single-column. */
    double                   column_splits[8];
    int                      column_split_count;

    /* Phase 11: when 0, the visitor drops glyphs drawn with Tr=3 (invisible
     * text typically laid under images by OCR tools). Default = 1 (emit
     * all, since OCR text is usually what you want for search). */
    int                      include_invisible;

    /* Phase 12: marked-content tracking. Updated by on_marked_content_begin
     * / on_marked_content_end. Each glyph emitted while current_mcid >= 0
     * is stamped with it so the aggregator can propagate structure tags up
     * to the word/line level. */
    int32_t                  mcid_stack[16];
    int                      mcid_depth;
    int32_t                  current_mcid;

    /* Phase 12: parsed structure tree — flat mcid → role map, populated by
     * pdfmake_textract_resolve_struct_tree() before running extraction. */
    pdfmake_struct_map_entry_t *struct_map;
    size_t                      struct_map_len;
    size_t                      struct_map_cap;
} pdfmake_textract_result_t;

/* Extraction options */
typedef struct {
    double word_gap_factor;    /* Gap > factor × font_size = new word (default 0.3) */
    double line_tolerance;     /* Baseline y diff < tolerance × font_size = same line (default 0.5) */
    double block_leading;      /* Line gap < factor × leading = same block (default 1.5) */

    /* Phase 11: whether to include text rendered with Tr=3 (invisible).
     * OCR'd PDFs layer invisible text under a rasterized image to enable
     * search. Default 1 = include (preserves search). Set to 0 for clean
     * extraction of only human-visible text. */
    int    include_invisible;
} pdfmake_textract_options_t;

/*============================================================================
 * WinAnsi encoding table (byte → Unicode)
 *==========================================================================*/

/* Decode a single WinAnsi byte to Unicode codepoint */
uint32_t pdfmake_winansi_to_unicode(uint8_t byte);

/*============================================================================
 * Text extraction API
 *==========================================================================*/

/* Create default extraction options */
pdfmake_textract_options_t pdfmake_textract_default_options(void);

/* Allocate a result structure */
pdfmake_textract_result_t *pdfmake_textract_new(pdfmake_arena_t *arena);

/* Attach a reader so /ToUnicode streams can be resolved.
 * Must be called before pdfmake_textract_run / pdfmake_interpret. */
void pdfmake_textract_set_reader(pdfmake_textract_result_t *result,
                                  struct pdfmake_reader *reader);

/* Free a result structure */
void pdfmake_textract_free(pdfmake_textract_result_t *result);

/* Get a visitor that collects text events into the result.
 * The visitor's ctx is the result pointer.
 * The font_resolver is called to look up pdfmake_font_t from the font dict. */
pdfmake_visitor_t pdfmake_textract_visitor(pdfmake_textract_result_t *result);

/* After interpretation, aggregate raw glyphs into words/lines/blocks */
pdfmake_err_t pdfmake_textract_aggregate(
    pdfmake_textract_result_t *result,
    const pdfmake_textract_options_t *options);

/* Convenience: extract text from a content stream in one call.
 * Requires an interpreter (with resources set) and extraction options. */
pdfmake_err_t pdfmake_textract_run(
    pdfmake_interp_t *interp,
    const uint8_t *content, size_t content_len,
    const pdfmake_textract_options_t *options,
    pdfmake_textract_result_t *result);

/* Get concatenated Unicode text from result (for simple use cases) */
size_t pdfmake_textract_to_utf8(
    const pdfmake_textract_result_t *result,
    char *buf, size_t buf_cap);

/*============================================================================
 * Phase 12: Structure tree (tagged PDFs)
 *==========================================================================*/

/* Walk a /StructTreeRoot subtree rooted at struct_root for the given page,
 * filling result->struct_map with (mcid → role) entries.
 *
 * Safe to call with a NULL struct_root (becomes a no-op).
 * Requires result->arena and result->reader to be set. */
pdfmake_err_t pdfmake_textract_resolve_struct_tree(
    pdfmake_textract_result_t *result,
    pdfmake_obj_t             *struct_root,
    pdfmake_obj_t             *page_dict);

/* Look up the structure role for an MCID (as an interned name id).
 * Returns 0 if the MCID is not mapped. */
uint32_t pdfmake_textract_role_for_mcid(
    const pdfmake_textract_result_t *result,
    int32_t mcid);

/*============================================================================
 * Phase 13 — Annotation + form field text extraction
 *
 * Annotations (sticky notes, free-text, markup comments) and form field
 * values don't appear in the page content stream but carry real user text.
 * pdfmake_textract_annotations walks each page's /Annots array plus the
 * document's /AcroForm /Fields tree and returns a flat list of records.
 *==========================================================================*/

typedef struct {
    const char *kind;       /* "Text", "FreeText", "Highlight", "Popup",
                             * "FormField", ... (interned statically) */
    size_t      page_index; /* 0-based page index; SIZE_MAX for form fields
                             * that are not page-anchored */
    double      rect[4];    /* [llx, lly, urx, ury] (zeros if absent) */
    const char *text;       /* UTF-8, arena-allocated; may be "" */
    const char *author;     /* Annot /T, may be NULL */
    const char *subject;    /* Annot /Subj, may be NULL */
    const char *field_name; /* Form field /T (dot-joined for /Kids), may be NULL */
} pdfmake_annot_text_t;

typedef struct {
    pdfmake_annot_text_t *items;
    size_t                len;
    size_t                cap;
    pdfmake_arena_t      *arena;  /* borrowed; strings owned here */
} pdfmake_annot_text_list_t;

/* Allocate an empty annotation list whose strings live in arena. */
pdfmake_annot_text_list_t *pdfmake_annot_text_list_new(pdfmake_arena_t *arena);

/* Free the list (does not touch the arena). */
void pdfmake_annot_text_list_free(pdfmake_annot_text_list_t *list);

/* Walk /Annots on every page plus /AcroForm /Fields, appending records to
 * out. Returns PDFMAKE_OK even when the document has no annotations. */
pdfmake_err_t pdfmake_textract_annotations(
    struct pdfmake_reader     *reader,
    pdfmake_annot_text_list_t *out);

/*============================================================================
 * Phase 15 — Table detection
 *
 * Post-processes aggregated words into rectangular tables inferred from
 * geometric alignment: rows are clusters of words sharing a baseline,
 * columns are x-positions repeating across ≥ min_rows rows.
 *==========================================================================*/

typedef struct {
    double  x0, y0, x1, y1;   /* table bbox (union of all cells) */
    size_t  rows;
    size_t  cols;
    /* rows × cols flat array, row-major; each cell is a UTF-8 string
     * (arena-allocated, may be "" for empty cells) */
    const char **cells;
    /* Per-cell bounding boxes (rows × cols, row-major). NULL means empty. */
    double     *cell_x0;
    double     *cell_y0;
    double     *cell_x1;
    double     *cell_y1;
} pdfmake_textract_table_t;

typedef struct {
    pdfmake_textract_table_t *items;
    size_t                    len;
    size_t                    cap;
    pdfmake_arena_t          *arena;
} pdfmake_textract_table_list_t;

typedef struct {
    size_t min_rows;            /* min rows for a region to qualify (default 3) */
    size_t min_cols;            /* min cols for a region to qualify (default 2) */
    double x_tolerance;         /* column-alignment tolerance in pt (default 5) */
    double row_tolerance;       /* within-row y tolerance × font_size (default 0.5) */
} pdfmake_textract_table_opts_t;

/* Default table-detection options. */
pdfmake_textract_table_opts_t pdfmake_textract_table_default_opts(void);

/* Allocate / free a table list. */
pdfmake_textract_table_list_t *pdfmake_textract_table_list_new(pdfmake_arena_t *arena);
void pdfmake_textract_table_list_free(pdfmake_textract_table_list_t *list);

/* Detect tables from an already-aggregated textract result.  The caller is
 * responsible for running pdfmake_textract_aggregate first. */
pdfmake_err_t pdfmake_textract_detect_tables(
    const pdfmake_textract_result_t     *result,
    const pdfmake_textract_table_opts_t *opts,   /* NULL = defaults */
    pdfmake_textract_table_list_t       *out);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_TEXTRACT_H */
