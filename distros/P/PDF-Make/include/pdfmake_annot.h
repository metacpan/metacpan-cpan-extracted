/*
 * pdfmake_annot.h — PDF annotation builders
 *
 * Provides functions to create annotation dictionaries for various
 * annotation types defined in PDF 32000-1:2008 §12.5.
 *
 * Reference:
 * - §12.5 Annotations
 * - §12.5.6 Annotation types
 */

#ifndef PDFMAKE_ANNOT_H
#define PDFMAKE_ANNOT_H

#include "pdfmake_types.h"
#include "pdfmake_doc.h"
#include "pdfmake_page.h"

#ifdef __cplusplus
extern "C" {
#endif

/*============================================================================
 * Annotation rectangle
 *==========================================================================*/

typedef struct {
    double x1, y1;  /* Lower-left corner */
    double x2, y2;  /* Upper-right corner */
} pdfmake_rect_t;

/*============================================================================
 * Text annotation (§12.5.6.4)
 *==========================================================================*/

typedef enum {
    PDFMAKE_ANNOT_ICON_NOTE,
    PDFMAKE_ANNOT_ICON_COMMENT,
    PDFMAKE_ANNOT_ICON_KEY,
    PDFMAKE_ANNOT_ICON_HELP,
    PDFMAKE_ANNOT_ICON_PARAGRAPH,
    PDFMAKE_ANNOT_ICON_NEWPARAGRAPH,
    PDFMAKE_ANNOT_ICON_INSERT
} pdfmake_annot_icon_t;

/*
 * Create a text annotation (sticky note).
 * rect: Location on page
 * contents: Note text content
 * icon: Icon type (Note, Comment, etc.)
 * open: Whether note is initially open
 * Returns object number of annotation dict, or 0 on error.
 */
uint32_t pdfmake_annot_text(pdfmake_doc_t *doc,
                            pdfmake_rect_t rect,
                            const char *contents,
                            pdfmake_annot_icon_t icon,
                            int open);

/*============================================================================
 * Highlight annotation (§12.5.6.10)
 *==========================================================================*/

typedef enum {
    PDFMAKE_MARKUP_HIGHLIGHT,
    PDFMAKE_MARKUP_UNDERLINE,
    PDFMAKE_MARKUP_SQUIGGLY,
    PDFMAKE_MARKUP_STRIKEOUT
} pdfmake_markup_type_t;

/*
 * Create a text markup annotation (highlight, underline, etc.)
 * rect: Bounding rectangle
 * quads: Array of QuadPoints (8 numbers per quad: x1,y1,...,x4,y4)
 * quad_count: Number of quads (quads_len = quad_count * 8)
 * type: Markup type
 * color: RGB color (3 values 0.0-1.0) or NULL for default
 * Returns object number of annotation dict, or 0 on error.
 */
uint32_t pdfmake_annot_markup(pdfmake_doc_t *doc,
                               pdfmake_rect_t rect,
                               const double *quads,
                               size_t quad_count,
                               pdfmake_markup_type_t type,
                               const double *color);

/*
 * Convenience: Create highlight annotation
 */
uint32_t pdfmake_annot_highlight(pdfmake_doc_t *doc,
                                  pdfmake_rect_t rect,
                                  const double *quads,
                                  size_t quad_count,
                                  const double *color);

/*============================================================================
 * Link annotation (§12.5.6.5)
 *==========================================================================*/

/*
 * Create a link annotation with URI action.
 * rect: Clickable area
 * uri: Target URI
 * Returns object number of annotation dict, or 0 on error.
 */
uint32_t pdfmake_annot_link_uri(pdfmake_doc_t *doc,
                                 pdfmake_rect_t rect,
                                 const char *uri);

/*
 * Create a link annotation with GoTo action (same document).
 * rect: Clickable area
 * dest_page: Target page index (0-based)
 * Returns object number of annotation dict, or 0 on error.
 */
uint32_t pdfmake_annot_link_goto(pdfmake_doc_t *doc,
                                  pdfmake_rect_t rect,
                                  size_t dest_page);

/*============================================================================
 * Stamp annotation (§12.5.6.12)
 *==========================================================================*/

typedef enum {
    PDFMAKE_STAMP_APPROVED,
    PDFMAKE_STAMP_EXPERIMENTAL,
    PDFMAKE_STAMP_NOTAPPROVED,
    PDFMAKE_STAMP_ASIS,
    PDFMAKE_STAMP_EXPIRED,
    PDFMAKE_STAMP_NOTFORPUBLICRELEASE,
    PDFMAKE_STAMP_CONFIDENTIAL,
    PDFMAKE_STAMP_FINAL,
    PDFMAKE_STAMP_SOLD,
    PDFMAKE_STAMP_DEPARTMENTAL,
    PDFMAKE_STAMP_FORLEGALREVIEW,
    PDFMAKE_STAMP_TOPSECRET,
    PDFMAKE_STAMP_DRAFT,
    PDFMAKE_STAMP_FORCOMMENT
} pdfmake_stamp_type_t;

/*
 * Create a stamp annotation.
 * rect: Stamp location and size
 * type: Predefined stamp type
 * Returns object number of annotation dict, or 0 on error.
 */
uint32_t pdfmake_annot_stamp(pdfmake_doc_t *doc,
                              pdfmake_rect_t rect,
                              pdfmake_stamp_type_t type);

/*============================================================================
 * Ink annotation (§12.5.6.13)
 *==========================================================================*/

/*
 * Create an ink (freehand drawing) annotation.
 * rect: Bounding rectangle
 * paths: Array of path arrays (each path is x,y pairs)
 * path_counts: Array of point counts for each path
 * num_paths: Number of paths
 * color: RGB stroke color or NULL for default
 * width: Stroke width in points
 * Returns object number of annotation dict, or 0 on error.
 */
uint32_t pdfmake_annot_ink(pdfmake_doc_t *doc,
                            pdfmake_rect_t rect,
                            const double **paths,
                            const size_t *path_counts,
                            size_t num_paths,
                            const double *color,
                            double width);

/*============================================================================
 * Page annotation attachment
 *==========================================================================*/

/*
 * Add an annotation to a page.
 * The annotation is appended to the page's /Annots array.
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_page_add_annot(pdfmake_page_t *page, uint32_t annot_num);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_ANNOT_H */
