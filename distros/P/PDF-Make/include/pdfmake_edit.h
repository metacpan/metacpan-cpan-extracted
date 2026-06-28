/*
 * pdfmake_edit.h — Page-level editing operations
 *
 * Provides functions to insert, remove, reorder, rotate, and duplicate
 * pages in a PDF document. Also includes document merge capability.
 *
 * Reference: PDF 32000-1:2008
 * - §7.7.3 Page tree
 * - §7.5.6 Incremental updates
 */

#ifndef PDFMAKE_EDIT_H
#define PDFMAKE_EDIT_H

#include "pdfmake_types.h"
#include "pdfmake_doc.h"
#include "pdfmake_page.h"

#ifdef __cplusplus
extern "C" {
#endif

/*============================================================================
 * Page rotation values (clockwise degrees)
 *==========================================================================*/

typedef enum {
    PDFMAKE_ROTATE_0   = 0,
    PDFMAKE_ROTATE_90  = 90,
    PDFMAKE_ROTATE_180 = 180,
    PDFMAKE_ROTATE_270 = 270
} pdfmake_rotation_t;

/*============================================================================
 * Page editing operations
 *==========================================================================*/

/*
 * Insert a page at the specified index.
 * Existing pages at idx and beyond are shifted right.
 * idx must be in range [0, page_count].
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_doc_insert_page(pdfmake_doc_t *doc, size_t idx,
                                       pdfmake_page_t *page);

/*
 * Remove a page at the specified index.
 * Pages beyond idx are shifted left.
 * The removed page is freed.
 * Returns PDFMAKE_OK on success, PDFMAKE_EINVAL if idx out of range.
 */
pdfmake_err_t pdfmake_doc_remove_page(pdfmake_doc_t *doc, size_t idx);

/*
 * Move a page from one index to another.
 * The page at from_idx is removed and inserted at to_idx.
 * After removal, to_idx refers to the adjusted position.
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_doc_move_page(pdfmake_doc_t *doc, size_t from_idx,
                                     size_t to_idx);

/*
 * Rotate a page by the specified degrees.
 * Rotation is stored in /Rotate entry of the page dictionary.
 * The rotation adds to any existing rotation.
 * degrees must be 0, 90, 180, or 270.
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_doc_rotate_page(pdfmake_doc_t *doc, size_t idx,
                                       pdfmake_rotation_t degrees);

/*
 * Duplicate a page at the specified index.
 * Creates a deep copy of the page dictionary and content stream.
 * Shared resources (fonts, images) remain shared to avoid bloat.
 * The duplicate is inserted immediately after the original.
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_doc_duplicate_page(pdfmake_doc_t *doc, size_t idx);

/*============================================================================
 * Document merge
 *==========================================================================*/

/*
 * Merge all pages from src document into dst document.
 * Pages are appended after dst's existing pages.
 * Indirect references in src are renumbered to avoid conflicts.
 * Shared resources are merged (fonts with same name use dst's version).
 * The src document is not modified.
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_doc_merge(pdfmake_doc_t *dst, pdfmake_doc_t *src);

/*============================================================================
 * Save modes
 *==========================================================================*/

typedef enum {
    PDFMAKE_SAVE_FULL,        /* Full rewrite (default) */
    PDFMAKE_SAVE_INCREMENTAL, /* Append changes only */
    PDFMAKE_SAVE_COMPACT      /* Full rewrite with object streams */
} pdfmake_save_mode_t;

/*
 * Save document with specified mode.
 * 
 * PDFMAKE_SAVE_FULL: Standard complete rewrite.
 * PDFMAKE_SAVE_INCREMENTAL: Append-only update with /Prev chain.
 *                           Requires doc to have original_bytes set.
 * PDFMAKE_SAVE_COMPACT: Pack objects into object streams for smaller size.
 *
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_doc_save(pdfmake_doc_t *doc, pdfmake_buf_t *out,
                                pdfmake_save_mode_t mode);

/*============================================================================
 * Incremental update support
 *==========================================================================*/

/*
 * Set the original bytes of the document for incremental updates.
 * The data is copied into the document's arena.
 * Must be called before any modifications if incremental save is desired.
 */
pdfmake_err_t pdfmake_doc_set_original(pdfmake_doc_t *doc,
                                        const uint8_t *data, size_t len);

/*
 * Mark an object as modified for incremental updates.
 * Modified objects will be rewritten in the incremental update.
 */
void pdfmake_doc_mark_modified(pdfmake_doc_t *doc, uint32_t obj_num);

/*============================================================================
 * Encryption hook placeholder (for Phase 16)
 *==========================================================================*/

/* Hook function type for per-object encryption. */
typedef pdfmake_err_t (*pdfmake_encrypt_hook_t)(
    void *ctx,
    uint32_t obj_num,
    uint16_t gen,
    const uint8_t *data,
    size_t len,
    pdfmake_buf_t *out);

/*
 * Set the encryption hook for save operations.
 * When set, the hook is called for each object being written.
 */
void pdfmake_doc_set_encrypt_hook(pdfmake_doc_t *doc,
                                   pdfmake_encrypt_hook_t hook,
                                   void *ctx);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_EDIT_H */
