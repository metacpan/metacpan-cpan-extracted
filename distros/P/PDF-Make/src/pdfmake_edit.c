/*
 * pdfmake_edit.c — Page-level editing operations
 */

#include "pdfmake_edit.h"
#include "pdfmake_arena.h"
#include "pdfmake_writer.h"
#include <string.h>
#include <stdlib.h>

/*============================================================================
 * Page editing operations
 *==========================================================================*/

pdfmake_err_t pdfmake_doc_insert_page(pdfmake_doc_t *doc, size_t idx,
                                       pdfmake_page_t *page) {
    if (!doc || !page) return PDFMAKE_EINVAL;
    if (idx > doc->page_count) return PDFMAKE_EINVAL;
    
    /* Grow array if needed */
    if (doc->page_count >= doc->page_cap) {
        size_t new_cap = doc->page_cap == 0 ? 4 : doc->page_cap * 2;
        pdfmake_page_t **new_pages = realloc(doc->pages, 
                                              new_cap * sizeof(pdfmake_page_t *));
        if (!new_pages) return PDFMAKE_ENOMEM;
        doc->pages = new_pages;
        doc->page_cap = new_cap;
    }
    
    /* Shift pages to make room */
    if (idx < doc->page_count) {
        memmove(&doc->pages[idx + 1], &doc->pages[idx],
                (doc->page_count - idx) * sizeof(pdfmake_page_t *));
    }
    
    doc->pages[idx] = page;
    doc->page_count++;
    
    /* Document needs re-finalization */
    doc->finalized = 0;
    
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_doc_remove_page(pdfmake_doc_t *doc, size_t idx) {
    if (!doc) return PDFMAKE_EINVAL;
    if (idx >= doc->page_count) return PDFMAKE_EINVAL;
    
    /* The page is arena-allocated, so no need to free */
    
    /* Shift remaining pages left */
    if (idx < doc->page_count - 1) {
        memmove(&doc->pages[idx], &doc->pages[idx + 1],
                (doc->page_count - idx - 1) * sizeof(pdfmake_page_t *));
    }
    
    doc->page_count--;
    doc->finalized = 0;
    
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_doc_move_page(pdfmake_doc_t *doc, size_t from_idx,
                                     size_t to_idx) {
    pdfmake_page_t *page;

    if (!doc) return PDFMAKE_EINVAL;
    if (from_idx >= doc->page_count) return PDFMAKE_EINVAL;
    if (to_idx >= doc->page_count) return PDFMAKE_EINVAL;
    if (from_idx == to_idx) return PDFMAKE_OK;

    page = doc->pages[from_idx];
    
    if (from_idx < to_idx) {
        /* Moving forward: shift elements left */
        memmove(&doc->pages[from_idx], &doc->pages[from_idx + 1],
                (to_idx - from_idx) * sizeof(pdfmake_page_t *));
    } else {
        /* Moving backward: shift elements right */
        memmove(&doc->pages[to_idx + 1], &doc->pages[to_idx],
                (from_idx - to_idx) * sizeof(pdfmake_page_t *));
    }
    
    doc->pages[to_idx] = page;
    doc->finalized = 0;
    
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_doc_rotate_page(pdfmake_doc_t *doc, size_t idx,
                                       pdfmake_rotation_t degrees) {
    pdfmake_page_t *page;
    int current_rotation;
    int new_rotation;

    if (!doc) return PDFMAKE_EINVAL;
    if (idx >= doc->page_count) return PDFMAKE_EINVAL;

    /* Validate rotation value */
    if (degrees != PDFMAKE_ROTATE_0 && 
        degrees != PDFMAKE_ROTATE_90 &&
        degrees != PDFMAKE_ROTATE_180 &&
        degrees != PDFMAKE_ROTATE_270) {
        return PDFMAKE_EINVAL;
    }

    page = doc->pages[idx];
    if (!page) return PDFMAKE_EINVAL;

    /* Store rotation in the page structure.
     * This is applied when building the page dict at finalize time. */
    current_rotation = page->rotation;
    new_rotation = (current_rotation + (int)degrees) % 360;
    if (new_rotation < 0) new_rotation += 360;
    
    page->rotation = new_rotation;
    doc->finalized = 0;
    
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_doc_duplicate_page(pdfmake_doc_t *doc, size_t idx) {
    pdfmake_page_t *src_page;
    pdfmake_page_t *new_page;

    if (!doc) return PDFMAKE_EINVAL;
    if (idx >= doc->page_count) return PDFMAKE_EINVAL;

    src_page = doc->pages[idx];
    if (!src_page) return PDFMAKE_EINVAL;

    /* Create new page structure */
    new_page = pdfmake_arena_calloc(doc->arena, sizeof(pdfmake_page_t));
    if (!new_page) return PDFMAKE_ENOMEM;
    
    new_page->doc = doc;
    new_page->width = src_page->width;
    new_page->height = src_page->height;
    new_page->rotation = src_page->rotation;
    
    /* Copy font resources (shared - same object numbers) */
    memcpy(new_page->fonts, src_page->fonts, sizeof(src_page->fonts));
    new_page->font_count = src_page->font_count;
    
    /* Copy image resources (shared) */
    memcpy(new_page->images, src_page->images, sizeof(src_page->images));
    new_page->image_count = src_page->image_count;
    
    /* Share content stream reference - the /Contents will point to same stream */
    new_page->contents_num = src_page->contents_num;
    new_page->has_content = src_page->has_content;
    
    /* page_num will be assigned during finalize */
    new_page->page_num = 0;
    
    /* Insert the new page after the source */
    return pdfmake_doc_insert_page(doc, idx + 1, new_page);
}

/*============================================================================
 * Document merge
 *==========================================================================*/

pdfmake_err_t pdfmake_doc_merge(pdfmake_doc_t *dst, pdfmake_doc_t *src) {
    size_t i;

    if (!dst || !src) return PDFMAKE_EINVAL;
    if (src->page_count == 0) return PDFMAKE_OK;  /* Nothing to merge */
    
    /* For now, merge simply copies page structures from src to dst.
     * This works for pre-finalize documents where pages just hold
     * dimensions and resource references.
     * 
     * A full implementation would handle:
     * - Cloning indirect objects with renumbered refs
     * - Merging resource pools (fonts, images)
     * - Handling finalized documents
     */
    
    for (i = 0; i < src->page_count; i++) {
        pdfmake_page_t *src_page = src->pages[i];
        pdfmake_page_t *new_page;
        pdfmake_err_t err;

        /* Create new page with same dimensions */
        new_page = pdfmake_arena_calloc(dst->arena,
                                        sizeof(pdfmake_page_t));
        if (!new_page) return PDFMAKE_ENOMEM;

        new_page->doc = dst;
        new_page->width = src_page->width;
        new_page->height = src_page->height;
        new_page->page_num = 0;  /* Will be assigned at finalize */

        /* Note: For a complete merge we would need to:
         * 1. Clone font objects from src to dst
         * 2. Clone content streams from src to dst  
         * 3. Update references accordingly
         * 
         * For now, pages are added without content/resources
         * A proper implementation requires object cloning infrastructure.
         */

        new_page->font_count = 0;
        new_page->image_count = 0;
        new_page->has_content = 0;
        new_page->contents_num = 0;

        /* Insert into dst */
        err = pdfmake_doc_insert_page(dst, dst->page_count, new_page);
        if (err != PDFMAKE_OK) return err;
    }
    
    dst->finalized = 0;
    
    return PDFMAKE_OK;
}

/*============================================================================
 * Save operations
 *==========================================================================*/

pdfmake_err_t pdfmake_doc_save(pdfmake_doc_t *doc, pdfmake_buf_t *out,
                                pdfmake_save_mode_t mode) {
    if (!doc || !out) return PDFMAKE_EINVAL;
    
    switch (mode) {
        case PDFMAKE_SAVE_FULL:
            return pdfmake_doc_write(doc, out);
            
        case PDFMAKE_SAVE_INCREMENTAL:
            /* TODO: Implement incremental save */
            return PDFMAKE_EINVAL;
            
        case PDFMAKE_SAVE_COMPACT:
            /* TODO: Implement object stream packing */
            return pdfmake_doc_write(doc, out);
            
        default:
            return PDFMAKE_EINVAL;
    }
}

pdfmake_err_t pdfmake_doc_set_original(pdfmake_doc_t *doc,
                                        const uint8_t *data, size_t len) {
    /* TODO: Store original bytes for incremental updates */
    (void)doc;
    (void)data;
    (void)len;
    return PDFMAKE_OK;
}

void pdfmake_doc_mark_modified(pdfmake_doc_t *doc, uint32_t obj_num) {
    /* TODO: Track modified objects for incremental updates */
    (void)doc;
    (void)obj_num;
}

void pdfmake_doc_set_encrypt_hook(pdfmake_doc_t *doc,
                                   pdfmake_encrypt_hook_t hook,
                                   void *ctx) {
    /* Placeholder for Phase 16 encryption */
    (void)doc;
    (void)hook;
    (void)ctx;
}
