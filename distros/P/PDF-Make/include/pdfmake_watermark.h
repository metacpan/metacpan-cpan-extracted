/*
 * pdfmake_watermark.h — Watermarks and stamps.
 *
 * Provides APIs for adding watermarks and stamps to PDF pages:
 * - Text watermarks (DRAFT, CONFIDENTIAL, etc.)
 * - Image watermarks (logos, signatures)
 * - Page stamps (Bates numbering, headers/footers)
 * - Positioning (diagonal, centered, tiled, custom)
 * - Opacity control via ExtGState
 *
 * Implementation uses Form XObjects for efficiency and content stream
 * manipulation for underlay/overlay placement.
 *
 * Reference: ISO 32000-2:2020
 *   §8.4.5 Graphics State (transparency)
 *   §8.10 Form XObjects
 *   §14.11.6 Watermark Annotations
 */

#ifndef PDFMAKE_WATERMARK_H
#define PDFMAKE_WATERMARK_H

#include "pdfmake_types.h"
#include "pdfmake_doc.h"
#include "pdfmake_page.h"
#include "pdfmake_image.h"

#ifdef __cplusplus
extern "C" {
#endif

/*----------------------------------------------------------------------------
 * Position types
 *--------------------------------------------------------------------------*/

typedef enum {
    PDFMAKE_WM_POS_CENTER = 0,      /* Centered on page */
    PDFMAKE_WM_POS_DIAGONAL,        /* Diagonal from corner to corner */
    PDFMAKE_WM_POS_TILE,            /* Tiled across page */
    PDFMAKE_WM_POS_CUSTOM,          /* Custom x, y position */
    PDFMAKE_WM_POS_TOP_LEFT,
    PDFMAKE_WM_POS_TOP_CENTER,
    PDFMAKE_WM_POS_TOP_RIGHT,
    PDFMAKE_WM_POS_BOTTOM_LEFT,
    PDFMAKE_WM_POS_BOTTOM_CENTER,
    PDFMAKE_WM_POS_BOTTOM_RIGHT,
    PDFMAKE_WM_POS_LEFT_CENTER,
    PDFMAKE_WM_POS_RIGHT_CENTER
} pdfmake_wm_position_t;

/*----------------------------------------------------------------------------
 * Watermark options
 *--------------------------------------------------------------------------*/

typedef struct {
    pdfmake_wm_position_t position;   /* Positioning mode */
    double rotation;                   /* Rotation in degrees */
    double opacity;                    /* 0.0 (transparent) to 1.0 (opaque) */
    double scale;                      /* Scale factor (1.0 = original) */
    double x_offset;                   /* X offset from computed position */
    double y_offset;                   /* Y offset from computed position */
    int    as_overlay;                 /* 1 = on top, 0 = behind content */
    
    /* Text-specific options */
    const char *font_name;             /* Font name (e.g., "Helvetica-Bold") */
    double      font_size;             /* Font size in points */
    double      color[3];              /* RGB color (0.0-1.0 each) */
    
    /* Tile-specific options */
    double tile_spacing_x;             /* Horizontal spacing between tiles */
    double tile_spacing_y;             /* Vertical spacing between tiles */
} pdfmake_watermark_opts_t;

/*----------------------------------------------------------------------------
 * Stamp position type (alias for watermark position)
 *--------------------------------------------------------------------------*/

typedef pdfmake_wm_position_t pdfmake_stamp_position_t;

/*----------------------------------------------------------------------------
 * Stamp options
 *--------------------------------------------------------------------------*/

typedef struct {
    pdfmake_stamp_position_t position;  /* Position on page */
    double margin_x;                     /* Horizontal margin from edge */
    double margin_y;                     /* Vertical margin from edge */
    const char *font_name;               /* Font name */
    double font_size;                    /* Font size in points */
    double color[3];                     /* RGB color */
} pdfmake_stamp_opts_t;

/*----------------------------------------------------------------------------
 * Watermark structure
 *--------------------------------------------------------------------------*/

typedef enum {
    PDFMAKE_WM_TYPE_TEXT = 0,
    PDFMAKE_WM_TYPE_IMAGE
} pdfmake_wm_type_t;

typedef struct pdfmake_watermark {
    pdfmake_wm_type_t type;
    pdfmake_watermark_opts_t opts;
    
    union {
        struct {
            char *text;                /* Text content (owned) */
            double text_width;         /* Computed text width */
            double text_height;        /* Computed text height */
        } text;
        struct {
            uint32_t image_obj;        /* Image XObject number */
            double   width;            /* Image width */
            double   height;           /* Image height */
        } image;
    } data;
    
    uint32_t xobject_num;              /* Form XObject number (if created) */
    uint32_t extgstate_num;            /* ExtGState number for opacity */
} pdfmake_watermark_t;

/*----------------------------------------------------------------------------
 * Stamp structure
 *--------------------------------------------------------------------------*/

typedef enum {
    PDFMAKE_WM_STAMP_TEXT = 0,
    PDFMAKE_WM_STAMP_BATES
} pdfmake_wm_stamp_type_t;

typedef struct pdfmake_stamp {
    pdfmake_wm_stamp_type_t type;
    pdfmake_stamp_opts_t opts;
    
    union {
        struct {
            char *format;              /* Format string (owned) */
        } text;
        struct {
            char *prefix;              /* Bates prefix (owned) */
            char *suffix;              /* Bates suffix (owned) */
            int   start_number;        /* Starting number */
            int   digits;              /* Number of digits (zero-padded) */
            int   current_number;      /* Current number (for iteration) */
        } bates;
    } data;
} pdfmake_stamp_t;

/*----------------------------------------------------------------------------
 * Default options initialization
 *--------------------------------------------------------------------------*/

/* Initialize watermark options with sensible defaults */
void pdfmake_watermark_opts_init(pdfmake_watermark_opts_t *opts);

/* Initialize stamp options with sensible defaults */
void pdfmake_stamp_opts_init(pdfmake_stamp_opts_t *opts);

/*----------------------------------------------------------------------------
 * Watermark creation
 *--------------------------------------------------------------------------*/

/*
 * Create a text watermark.
 * The text string is copied internally.
 * Returns NULL on error.
 */
pdfmake_watermark_t *pdfmake_watermark_text(
    pdfmake_doc_t *doc,
    const char *text,
    const pdfmake_watermark_opts_t *opts
);

/*
 * Create an image watermark.
 * The image must already be added to the document.
 * Returns NULL on error.
 */
pdfmake_watermark_t *pdfmake_watermark_image(
    pdfmake_doc_t *doc,
    uint32_t image_obj_num,
    double image_width,
    double image_height,
    const pdfmake_watermark_opts_t *opts
);

/*
 * Free a watermark.
 */
void pdfmake_watermark_free(pdfmake_watermark_t *wm);

/*----------------------------------------------------------------------------
 * Watermark application
 *--------------------------------------------------------------------------*/

/*
 * Add watermark to a single page.
 * Creates necessary resources (ExtGState, Form XObject) if not already created.
 */
pdfmake_err_t pdfmake_page_add_watermark(
    pdfmake_page_t *page,
    pdfmake_watermark_t *wm
);

/*
 * Add watermark to all pages in document.
 */
pdfmake_err_t pdfmake_doc_add_watermark(
    pdfmake_doc_t *doc,
    pdfmake_watermark_t *wm
);

/*
 * Add watermark to a range of pages (0-indexed, inclusive).
 */
pdfmake_err_t pdfmake_doc_add_watermark_range(
    pdfmake_doc_t *doc,
    pdfmake_watermark_t *wm,
    int start_page,
    int end_page
);

/*----------------------------------------------------------------------------
 * Stamp creation
 *--------------------------------------------------------------------------*/

/*
 * Create a text stamp with format string.
 * Format specifiers:
 *   %p - current page number (1-based)
 *   %P - total page count
 *   %d - date (YYYY-MM-DD)
 *   %t - time (HH:MM)
 *   %f - filename
 *   %% - literal %
 */
pdfmake_stamp_t *pdfmake_stamp_text(
    pdfmake_doc_t *doc,
    const char *format,
    const pdfmake_stamp_opts_t *opts
);

/*
 * Create a Bates number stamp.
 * Format: {prefix}{number:digits}{suffix}
 * Example: prefix="DOC", start=1, digits=6, suffix="-2026"
 *          produces "DOC000001-2026", "DOC000002-2026", etc.
 */
pdfmake_stamp_t *pdfmake_stamp_bates(
    pdfmake_doc_t *doc,
    const char *prefix,
    int start_number,
    int digits,
    const char *suffix,
    const pdfmake_stamp_opts_t *opts
);

/*
 * Free a stamp.
 */
void pdfmake_stamp_free(pdfmake_stamp_t *stamp);

/*----------------------------------------------------------------------------
 * Stamp application
 *--------------------------------------------------------------------------*/

/*
 * Add stamp to all pages.
 * For page numbers and Bates, the number increments per page.
 */
pdfmake_err_t pdfmake_doc_add_stamp(
    pdfmake_doc_t *doc,
    pdfmake_stamp_t *stamp
);

/*
 * Add stamp to a range of pages (0-indexed, inclusive).
 */
pdfmake_err_t pdfmake_doc_add_stamp_range(
    pdfmake_doc_t *doc,
    pdfmake_stamp_t *stamp,
    int start_page,
    int end_page
);

/*----------------------------------------------------------------------------
 * Positioning helpers (internal, but exposed for testing)
 *--------------------------------------------------------------------------*/

/*
 * Calculate watermark position for a page.
 * Returns the transformation matrix to apply.
 */
void pdfmake_watermark_calc_position(
    const pdfmake_watermark_t *wm,
    double page_width,
    double page_height,
    double *out_x,
    double *out_y,
    double *out_rotation
);

/*
 * Calculate stamp position for a page.
 */
void pdfmake_stamp_calc_position(
    const pdfmake_stamp_t *stamp,
    double page_width,
    double page_height,
    double text_width,
    double text_height,
    double *out_x,
    double *out_y
);

/*----------------------------------------------------------------------------
 * Format string expansion
 *--------------------------------------------------------------------------*/

/*
 * Expand a format string for the given page.
 * Result is allocated and must be freed by caller.
 * Returns NULL on error.
 */
char *pdfmake_stamp_expand_format(
    const char *format,
    int page_number,         /* 1-based current page */
    int total_pages,
    const char *filename
);

/*
 * Expand Bates number to string.
 * Result is allocated and must be freed by caller.
 */
char *pdfmake_stamp_expand_bates(
    const char *prefix,
    int number,
    int digits,
    const char *suffix
);

/*----------------------------------------------------------------------------
 * Text metrics (approximate, for Standard 14 fonts)
 *--------------------------------------------------------------------------*/

/*
 * Get approximate width of text in a Standard 14 font.
 * This is used for centering calculations.
 */
double pdfmake_text_width_approx(
    const char *text,
    const char *font_name,
    double font_size
);

/*----------------------------------------------------------------------------
 * ExtGState for transparency
 *--------------------------------------------------------------------------*/

/*
 * Create or get an ExtGState object for the given opacity.
 * Returns the object number, or 0 on error.
 */
uint32_t pdfmake_doc_get_opacity_extgstate(
    pdfmake_doc_t *doc,
    double opacity
);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_WATERMARK_H */
