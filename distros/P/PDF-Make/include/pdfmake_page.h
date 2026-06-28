/*
 * pdfmake_page.h — Page and catalog construction.
 *
 * Provides functions to create pages, manage the page tree, and build
 * the document catalog. This is the core structure for producing
 * valid multi-page PDF documents.
 *
 * Standard 14 fonts (§9.6.2.2) are supported without embedding.
 */

#ifndef PDFMAKE_PAGE_H
#define PDFMAKE_PAGE_H

#include "pdfmake_types.h"
#include "pdfmake_doc.h"

#ifdef __cplusplus
extern "C" {
#endif

/*----------------------------------------------------------------------------
 * Standard page sizes (points, 1 point = 1/72 inch)
 *--------------------------------------------------------------------------*/

#define PDFMAKE_PAGE_LETTER_WIDTH   612.0   /* 8.5 x 11 inches */
#define PDFMAKE_PAGE_LETTER_HEIGHT  792.0
#define PDFMAKE_PAGE_A4_WIDTH       595.0   /* 210 x 297 mm */
#define PDFMAKE_PAGE_A4_HEIGHT      842.0

/*----------------------------------------------------------------------------
 * Standard 14 font names (§9.6.2.2)
 *--------------------------------------------------------------------------*/

/* Standard 14 fonts that every PDF reader must support. */
typedef enum {
    PDFMAKE_FONT_HELVETICA = 0,
    PDFMAKE_FONT_HELVETICA_BOLD,
    PDFMAKE_FONT_HELVETICA_OBLIQUE,
    PDFMAKE_FONT_HELVETICA_BOLD_OBLIQUE,
    PDFMAKE_FONT_TIMES_ROMAN,
    PDFMAKE_FONT_TIMES_BOLD,
    PDFMAKE_FONT_TIMES_ITALIC,
    PDFMAKE_FONT_TIMES_BOLD_ITALIC,
    PDFMAKE_FONT_COURIER,
    PDFMAKE_FONT_COURIER_BOLD,
    PDFMAKE_FONT_COURIER_OBLIQUE,
    PDFMAKE_FONT_COURIER_BOLD_OBLIQUE,
    PDFMAKE_FONT_SYMBOL,
    PDFMAKE_FONT_ZAPF_DINGBATS,
    PDFMAKE_FONT_COUNT
} pdfmake_std14_font_t;

/* Get the BaseFont name for a Standard 14 font. */
const char *pdfmake_std14_name(pdfmake_std14_font_t font);

/* Look up a Standard 14 font by BaseFont name. Returns -1 if not found. */
int pdfmake_std14_lookup(const char *name);

/*----------------------------------------------------------------------------
 * Page structure
 *--------------------------------------------------------------------------*/

/* Maximum fonts per page (can be increased if needed). */
#define PDFMAKE_MAX_PAGE_FONTS 16

/* Maximum images (XObjects) per page. */
#define PDFMAKE_MAX_PAGE_IMAGES 64

/* Maximum properties (OCG) per page. */
#define PDFMAKE_MAX_PAGE_PROPERTIES 32

/* Maximum ExtGState resources per page. */
#define PDFMAKE_MAX_PAGE_EXTGSTATES 32

/* Properties resource entry (for OCG). */
typedef struct {
    char      name[32];    /* Resource name (e.g., "MC0") */
    uint32_t  prop_num;    /* Indirect object number of OCG dict */
} pdfmake_prop_entry_t;

/* Font resource entry. */
typedef struct {
    char      name[32];    /* Resource name (e.g., "F1") */
    uint32_t  font_num;    /* Indirect object number of /Font dict */
} pdfmake_font_entry_t;

/* Image XObject resource entry. */
typedef struct {
    char      name[32];    /* Resource name (e.g., "Im0") */
    uint32_t  image_num;   /* Indirect object number of /Image XObject */
} pdfmake_image_entry_t;

/* ExtGState resource entry. */
typedef struct {
    char      name[32];       /* Resource name (e.g., "GS1") */
    uint32_t  extgstate_num;  /* Indirect object number of /ExtGState dict */
} pdfmake_extgstate_entry_t;

/* Page structure - tracks page dict and resources. */
struct pdfmake_page {
    pdfmake_doc_t       *doc;           /* Owning document */
    uint32_t             page_num;      /* Indirect object number of /Page dict */
    double               width;         /* MediaBox width (points) */
    double               height;        /* MediaBox height (points) */
    int                  rotation;      /* Page rotation in degrees (0, 90, 180, 270) */

    /* Font resources */
    pdfmake_font_entry_t fonts[PDFMAKE_MAX_PAGE_FONTS];
    size_t               font_count;

    /* Image XObject resources */
    pdfmake_image_entry_t images[PDFMAKE_MAX_PAGE_IMAGES];
    size_t                image_count;

    /* Properties resources (OCG) */
    pdfmake_prop_entry_t  properties[PDFMAKE_MAX_PAGE_PROPERTIES];
    size_t                prop_count;

    /* ExtGState resources */
    pdfmake_extgstate_entry_t extgstates[PDFMAKE_MAX_PAGE_EXTGSTATES];
    size_t                    extgstate_count;

    /* Redaction marks */
    void                 *redactions;   /* Array of pdfmake_redact_t pointers */
    size_t                redact_count;
    size_t                redact_cap;

    /* Annotations (widget annotations, links, etc.) */
    uint32_t            *annots;        /* Array of annotation object numbers */
    size_t               annot_count;
    size_t               annot_cap;

    /* Content stream */
    uint32_t             contents_num;  /* Indirect object number of contents stream */
    int                  has_content;   /* Whether content has been set */

    /* When non-NULL, the finalizer writes this dict as /Resources verbatim
     * instead of composing one from fonts[]/images[]/... arrays.  Used by
     * page-import so every resource category (including /ColorSpace,
     * /Pattern, /Shading) survives the copy. */
    pdfmake_dict_t      *imported_resources;
};

/*----------------------------------------------------------------------------
 * Page creation
 *--------------------------------------------------------------------------*/

/*
 * Add a new page to the document.
 * Creates /Page dict with MediaBox [0 0 width height].
 * Returns pointer to page structure, or NULL on error.
 * The page is owned by the document and freed with pdfmake_doc_free.
 */
pdfmake_page_t *pdfmake_doc_add_page(pdfmake_doc_t *doc, double width, double height);

/*
 * Get the number of pages in the document.
 */
size_t pdfmake_doc_page_count(pdfmake_doc_t *doc);

/*
 * Get a page by index (0-based).
 * Returns NULL if index is out of range.
 */
pdfmake_page_t *pdfmake_doc_get_page(pdfmake_doc_t *doc, size_t index);

/*----------------------------------------------------------------------------
 * Page resources
 *--------------------------------------------------------------------------*/

/*
 * Add a Standard 14 font to the page's resources.
 * `name` is the resource name (e.g., "F1") used in content streams.
 * `base_font` is the BaseFont name (e.g., "Helvetica").
 * Returns the font's indirect object number, or 0 on error.
 */
uint32_t pdfmake_page_add_font(pdfmake_page_t *page,
                               const char *name,
                               const char *base_font);

/*
 * Add a Standard 14 font by enum.
 */
uint32_t pdfmake_page_add_std14_font(pdfmake_page_t *page,
                                      const char *name,
                                      pdfmake_std14_font_t font);

/*----------------------------------------------------------------------------
 * Content stream
 *--------------------------------------------------------------------------*/

/*
 * Add an image XObject to the page's resources.
 * `name` is the resource name (e.g., "Im0") used in content streams.
 * `img_obj_num` is the indirect object number of the /Image XObject.
 * Returns the resource index, or -1 on error.
 */
int pdfmake_page_add_image(pdfmake_page_t *page,
                           const char *name,
                           uint32_t img_obj_num);

/*
 * Add an ExtGState dictionary to the page's resources.
 * `name` is the resource name (e.g., "GS1") used by the `gs` operator.
 * `extgstate_obj_num` is the indirect object number of the /ExtGState dict.
 * Returns resource index, or -1 on error.
 */
int pdfmake_page_add_extgstate(pdfmake_page_t *page,
                               const char *name,
                               uint32_t extgstate_obj_num);

/*
 * Set the page's content stream from raw bytes.
 * For phase 05, this is a hand-written PDF content stream.
 * Phase 06 will add a content builder API.
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_page_set_content(pdfmake_page_t *page,
                                        const uint8_t *data,
                                        size_t len);

/*
 * Set the page's content stream from a null-terminated string.
 * Convenience wrapper for ASCII content streams.
 */
pdfmake_err_t pdfmake_page_set_content_str(pdfmake_page_t *page,
                                            const char *content);

/*
 * Append content bytes to the page's existing content stream.  Wraps the
 * existing content in `q .. Q` and concatenates the new bytes afterwards
 * so overlay drawing starts from a clean graphics state.  When the page
 * has no prior content, this is equivalent to pdfmake_page_set_content.
 */
pdfmake_err_t pdfmake_page_append_content(pdfmake_page_t *page,
                                           const uint8_t *data,
                                           size_t len);

/*----------------------------------------------------------------------------
 * Catalog and page tree
 *--------------------------------------------------------------------------*/

/*
 * Finalize the document structure.
 * Builds the /Catalog and /Pages dictionaries, wires Root in trailer.
 * Called automatically by pdfmake_doc_write if not already called.
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_doc_finalize(pdfmake_doc_t *doc);

/*
 * Check if the document has been finalized.
 */
int pdfmake_doc_is_finalized(pdfmake_doc_t *doc);

/*----------------------------------------------------------------------------
 * Default page sizes (in points, 72 points = 1 inch)
 *--------------------------------------------------------------------------*/

#define PDFMAKE_PAGE_A4_WIDTH   595.0
#define PDFMAKE_PAGE_A4_HEIGHT  842.0

#define PDFMAKE_PAGE_LETTER_WIDTH  612.0
#define PDFMAKE_PAGE_LETTER_HEIGHT 792.0

#define PDFMAKE_PAGE_LEGAL_WIDTH   612.0
#define PDFMAKE_PAGE_LEGAL_HEIGHT  1008.0

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_PAGE_H */
