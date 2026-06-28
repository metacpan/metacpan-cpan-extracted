/*
 * pdfmake_outline.h — Document outline (bookmarks) and destinations.
 *
 * §12.3.2 Destinations — specify view of a page
 * §12.3.3 Document Outline — tree structure for PDF reader sidebars
 *
 * The outline tree appears in PDF readers as "Bookmarks" allowing
 * navigation to specific pages and positions within the document.
 */

#ifndef PDFMAKE_OUTLINE_H
#define PDFMAKE_OUTLINE_H

#include "pdfmake_types.h"
#include "pdfmake_doc.h"

#ifdef __cplusplus
extern "C" {
#endif

/*----------------------------------------------------------------------------
 * Destination types (§12.3.2.2)
 *--------------------------------------------------------------------------*/

typedef enum {
    PDFMAKE_DEST_XYZ,      /* [page /XYZ left top zoom] */
    PDFMAKE_DEST_FIT,      /* [page /Fit] */
    PDFMAKE_DEST_FITH,     /* [page /FitH top] */
    PDFMAKE_DEST_FITV,     /* [page /FitV left] */
    PDFMAKE_DEST_FITR,     /* [page /FitR left bottom right top] */
    PDFMAKE_DEST_FITB,     /* [page /FitB] */
    PDFMAKE_DEST_FITBH,    /* [page /FitBH top] */
    PDFMAKE_DEST_FITBV     /* [page /FitBV left] */
} pdfmake_dest_type_t;

/*
 * Destination structure - specifies a view of a page.
 * The page_index is 0-based; on write, it becomes an indirect reference.
 */
typedef struct pdfmake_dest {
    pdfmake_dest_type_t type;
    size_t              page_index;  /* 0-based page index */
    double              left;        /* For XYZ, FitV, FitR, FitBV */
    double              top;         /* For XYZ, FitH, FitR, FitBH */
    double              right;       /* For FitR */
    double              bottom;      /* For FitR */
    double              zoom;        /* For XYZ (0 = null = unchanged) */
} pdfmake_dest_t;

/*----------------------------------------------------------------------------
 * Destination builders
 *--------------------------------------------------------------------------*/

/* Create XYZ destination: specific position with optional zoom */
pdfmake_dest_t pdfmake_dest_xyz(size_t page_index, double left, double top, double zoom);

/* Create Fit destination: fit entire page in window */
pdfmake_dest_t pdfmake_dest_fit(size_t page_index);

/* Create FitH destination: fit width, position at top */
pdfmake_dest_t pdfmake_dest_fith(size_t page_index, double top);

/* Create FitV destination: fit height, position at left */
pdfmake_dest_t pdfmake_dest_fitv(size_t page_index, double left);

/* Create FitR destination: fit rectangle */
pdfmake_dest_t pdfmake_dest_fitr(size_t page_index, 
                                  double left, double bottom,
                                  double right, double top);

/* Create FitB destination: fit bounding box */
pdfmake_dest_t pdfmake_dest_fitb(size_t page_index);

/* Create FitBH destination: fit bounding box width */
pdfmake_dest_t pdfmake_dest_fitbh(size_t page_index, double top);

/* Create FitBV destination: fit bounding box height */
pdfmake_dest_t pdfmake_dest_fitbv(size_t page_index, double left);

/*----------------------------------------------------------------------------
 * Outline item structure (§12.3.3)
 *--------------------------------------------------------------------------*/

typedef struct pdfmake_outline_item {
    char                          *title;     /* Bookmark title (UTF-8) */
    pdfmake_dest_t                 dest;      /* Navigation destination */
    pdfmake_doc_t                 *doc;       /* Owning document (for arena access) */
    
    /* Tree structure - doubly-linked siblings and children */
    struct pdfmake_outline_item   *parent;
    struct pdfmake_outline_item   *prev;
    struct pdfmake_outline_item   *next;
    struct pdfmake_outline_item   *first;     /* First child */
    struct pdfmake_outline_item   *last;      /* Last child */
    
    int                            count;     /* Number of visible descendants */
    int                            open;      /* Initially expanded (1) or collapsed (0) */
    
    /* For PDF generation */
    uint32_t                       obj_num;   /* Indirect object number when written */
} pdfmake_outline_item_t;

/*----------------------------------------------------------------------------
 * Outline tree management
 *--------------------------------------------------------------------------*/

/*
 * Get the root outline item from a document.
 * Returns NULL if no outline exists.
 */
pdfmake_outline_item_t *pdfmake_doc_get_outline(pdfmake_doc_t *doc);

/*
 * Create the root outline item for a document.
 * The root itself can have a title/dest or be just a container.
 * If title is NULL, creates a container root (no destination).
 * Returns the root item, or NULL on error.
 */
pdfmake_outline_item_t *pdfmake_doc_add_outline_root(pdfmake_doc_t *doc,
                                                      const char *title,
                                                      pdfmake_dest_t dest);

/*
 * Add a child item to an existing outline item.
 * Returns the new child, or NULL on error.
 */
pdfmake_outline_item_t *pdfmake_outline_add_child(pdfmake_outline_item_t *parent,
                                                   const char *title,
                                                   pdfmake_dest_t dest);

/*
 * Set the title of an outline item.
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_outline_set_title(pdfmake_outline_item_t *item,
                                         const char *title);

/*
 * Set the destination of an outline item.
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_outline_set_dest(pdfmake_outline_item_t *item,
                                        pdfmake_dest_t dest);

/*
 * Set whether an outline item is initially open (expanded).
 */
void pdfmake_outline_set_open(pdfmake_outline_item_t *item, int open);

/*
 * Remove an outline item and all its children.
 * The item becomes invalid after this call.
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_outline_remove(pdfmake_outline_item_t *item);

/*
 * Count the total number of items in an outline tree (including root).
 */
size_t pdfmake_outline_count(pdfmake_outline_item_t *root);

/*----------------------------------------------------------------------------
 * Internal: Outline writing
 *--------------------------------------------------------------------------*/

/*
 * Build and emit outline objects during document finalization.
 * Called by pdfmake_doc_finalize().
 * Returns the /Outlines dict object number, or 0 if no outline.
 */
uint32_t pdfmake_outline_finalize(pdfmake_doc_t *doc,
                                   pdfmake_outline_item_t *root);

/*
 * Build a destination array for writing.
 * Returns the array object (not indirect).
 */
pdfmake_obj_t pdfmake_dest_to_obj(pdfmake_arena_t *arena,
                                   pdfmake_doc_t *doc,
                                   pdfmake_dest_t dest);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_OUTLINE_H */
