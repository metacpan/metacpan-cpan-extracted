/*
 * pdfmake_outline.c — Document outline (bookmarks) implementation.
 *
 * Creates and manages the outline tree structure that appears as
 * bookmarks in PDF reader sidebars.
 */

#include "pdfmake_outline.h"
#include "pdfmake_arena.h"
#include "pdfmake_page.h"
#include "pdfmake.h"
#include <string.h>
#include <stdlib.h>

/*----------------------------------------------------------------------------
 * Destination builders
 *--------------------------------------------------------------------------*/

pdfmake_dest_t pdfmake_dest_xyz(size_t page_index, double left, double top, double zoom)
{
    pdfmake_dest_t dest = {0};
    dest.type = PDFMAKE_DEST_XYZ;
    dest.page_index = page_index;
    dest.left = left;
    dest.top = top;
    dest.zoom = zoom;
    return dest;
}

pdfmake_dest_t pdfmake_dest_fit(size_t page_index)
{
    pdfmake_dest_t dest = {0};
    dest.type = PDFMAKE_DEST_FIT;
    dest.page_index = page_index;
    return dest;
}

pdfmake_dest_t pdfmake_dest_fith(size_t page_index, double top)
{
    pdfmake_dest_t dest = {0};
    dest.type = PDFMAKE_DEST_FITH;
    dest.page_index = page_index;
    dest.top = top;
    return dest;
}

pdfmake_dest_t pdfmake_dest_fitv(size_t page_index, double left)
{
    pdfmake_dest_t dest = {0};
    dest.type = PDFMAKE_DEST_FITV;
    dest.page_index = page_index;
    dest.left = left;
    return dest;
}

pdfmake_dest_t pdfmake_dest_fitr(size_t page_index,
                                  double left, double bottom,
                                  double right, double top)
{
    pdfmake_dest_t dest = {0};
    dest.type = PDFMAKE_DEST_FITR;
    dest.page_index = page_index;
    dest.left = left;
    dest.bottom = bottom;
    dest.right = right;
    dest.top = top;
    return dest;
}

pdfmake_dest_t pdfmake_dest_fitb(size_t page_index)
{
    pdfmake_dest_t dest = {0};
    dest.type = PDFMAKE_DEST_FITB;
    dest.page_index = page_index;
    return dest;
}

pdfmake_dest_t pdfmake_dest_fitbh(size_t page_index, double top)
{
    pdfmake_dest_t dest = {0};
    dest.type = PDFMAKE_DEST_FITBH;
    dest.page_index = page_index;
    dest.top = top;
    return dest;
}

pdfmake_dest_t pdfmake_dest_fitbv(size_t page_index, double left)
{
    pdfmake_dest_t dest = {0};
    dest.type = PDFMAKE_DEST_FITBV;
    dest.page_index = page_index;
    dest.left = left;
    return dest;
}

/*----------------------------------------------------------------------------
 * Destination to object conversion
 *--------------------------------------------------------------------------*/

pdfmake_obj_t pdfmake_dest_to_obj(pdfmake_arena_t *arena,
                                   pdfmake_doc_t *doc,
                                   pdfmake_dest_t dest)
{
    pdfmake_page_t *page;
    pdfmake_obj_t page_ref;
    pdfmake_obj_t arr;

    /* Get page reference */
    if (dest.page_index >= doc->page_count) {
        return pdfmake_null();
    }
    
    page = doc->pages[dest.page_index];
    page_ref = pdfmake_ref(page->page_num, 0);
    
    arr = pdfmake_array_new(arena);
    pdfmake_array_push(arena, &arr, page_ref);
    
    switch (dest.type) {
        case PDFMAKE_DEST_XYZ:
            pdfmake_array_push(arena, &arr, pdfmake_name(arena, "XYZ", 3));
            pdfmake_array_push(arena, &arr, (dest.left == 0) ? pdfmake_null() : pdfmake_real(dest.left));
            pdfmake_array_push(arena, &arr, (dest.top == 0) ? pdfmake_null() : pdfmake_real(dest.top));
            pdfmake_array_push(arena, &arr, (dest.zoom == 0) ? pdfmake_null() : pdfmake_real(dest.zoom));
            break;
            
        case PDFMAKE_DEST_FIT:
            pdfmake_array_push(arena, &arr, pdfmake_name(arena, "Fit", 3));
            break;
            
        case PDFMAKE_DEST_FITH:
            pdfmake_array_push(arena, &arr, pdfmake_name(arena, "FitH", 4));
            pdfmake_array_push(arena, &arr, pdfmake_real(dest.top));
            break;
            
        case PDFMAKE_DEST_FITV:
            pdfmake_array_push(arena, &arr, pdfmake_name(arena, "FitV", 4));
            pdfmake_array_push(arena, &arr, pdfmake_real(dest.left));
            break;
            
        case PDFMAKE_DEST_FITR:
            pdfmake_array_push(arena, &arr, pdfmake_name(arena, "FitR", 4));
            pdfmake_array_push(arena, &arr, pdfmake_real(dest.left));
            pdfmake_array_push(arena, &arr, pdfmake_real(dest.bottom));
            pdfmake_array_push(arena, &arr, pdfmake_real(dest.right));
            pdfmake_array_push(arena, &arr, pdfmake_real(dest.top));
            break;
            
        case PDFMAKE_DEST_FITB:
            pdfmake_array_push(arena, &arr, pdfmake_name(arena, "FitB", 4));
            break;
            
        case PDFMAKE_DEST_FITBH:
            pdfmake_array_push(arena, &arr, pdfmake_name(arena, "FitBH", 5));
            pdfmake_array_push(arena, &arr, pdfmake_real(dest.top));
            break;
            
        case PDFMAKE_DEST_FITBV:
            pdfmake_array_push(arena, &arr, pdfmake_name(arena, "FitBV", 5));
            pdfmake_array_push(arena, &arr, pdfmake_real(dest.left));
            break;
    }
    
    return arr;
}

/*----------------------------------------------------------------------------
 * Outline item creation
 *--------------------------------------------------------------------------*/

static pdfmake_outline_item_t *create_outline_item(pdfmake_doc_t *doc,
                                                     const char *title,
                                                     pdfmake_dest_t dest)
{
    pdfmake_arena_t *arena = doc->arena;
    pdfmake_outline_item_t *item = pdfmake_arena_alloc(arena, sizeof(pdfmake_outline_item_t));
    if (!item) return NULL;
    
    memset(item, 0, sizeof(*item));
    
    item->doc = doc;  /* Store doc pointer for arena access */
    
    if (title) {
        size_t len = strlen(title);
        item->title = pdfmake_arena_alloc(arena, len + 1);
        if (!item->title) return NULL;
        memcpy(item->title, title, len + 1);
    }
    
    item->dest = dest;
    item->open = 1;  /* Default to open/expanded */
    
    return item;
}

/*
 * Recalculate count for an item and all ancestors.
 * Count = number of visible descendants (when open).
 */
static void update_counts(pdfmake_outline_item_t *item)
{
    pdfmake_outline_item_t *child;
    int count;
    while (item) {
        count = 0;
        for (child = item->first; child; child = child->next) {
            count++;
            if (child->open && child->count > 0) {
                count += child->count;
            }
        }
        item->count = count;
        item = item->parent;
    }
}

/*----------------------------------------------------------------------------
 * Document outline storage
 *
 * The outline root is stored directly in the pdfmake_doc_t structure
 * via the outline_root field, avoiding global state issues.
 *--------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------
 * Public API - Document outline
 *--------------------------------------------------------------------------*/

pdfmake_outline_item_t *pdfmake_doc_get_outline(pdfmake_doc_t *doc)
{
    if (!doc) return NULL;
    return (pdfmake_outline_item_t *)doc->outline_root;
}

pdfmake_outline_item_t *pdfmake_doc_add_outline_root(pdfmake_doc_t *doc,
                                                      const char *title,
                                                      pdfmake_dest_t dest)
{
    pdfmake_outline_item_t *root;

    if (!doc) return NULL;

    if (doc->outline_root) {
        /* Already have a root - return it */
        return (pdfmake_outline_item_t *)doc->outline_root;
    }

    root = create_outline_item(doc, title, dest);
    if (!root) return NULL;

    doc->outline_root = root;
    return root;
}

pdfmake_outline_item_t *pdfmake_outline_add_child(pdfmake_outline_item_t *parent,
                                                   const char *title,
                                                   pdfmake_dest_t dest)
{
    pdfmake_outline_item_t *child;

    if (!parent || !parent->doc) return NULL;
    
    child = create_outline_item(parent->doc, title, dest);
    if (!child) return NULL;
    
    child->parent = parent;
    
    /* Add to end of children list */
    if (!parent->first) {
        parent->first = child;
        parent->last = child;
    } else {
        parent->last->next = child;
        child->prev = parent->last;
        parent->last = child;
    }
    
    update_counts(parent);
    
    return child;
}

pdfmake_err_t pdfmake_outline_set_title(pdfmake_outline_item_t *item,
                                         const char *title)
{
    size_t new_len;

    if (!item || !title) return PDFMAKE_EINVAL;
    
    /* Can't easily reallocate in arena - just update pointer if same length or smaller */
    /* For now, this is a limitation */
    new_len = strlen(title);
    if (item->title && strlen(item->title) >= new_len) {
        memcpy(item->title, title, new_len + 1);
        return PDFMAKE_OK;
    }
    
    /* Would need arena access to allocate new string */
    return PDFMAKE_EINVAL;
}

pdfmake_err_t pdfmake_outline_set_dest(pdfmake_outline_item_t *item,
                                        pdfmake_dest_t dest)
{
    if (!item) return PDFMAKE_EINVAL;
    item->dest = dest;
    return PDFMAKE_OK;
}

void pdfmake_outline_set_open(pdfmake_outline_item_t *item, int open)
{
    if (!item) return;
    item->open = open ? 1 : 0;
    update_counts(item->parent);
}

pdfmake_err_t pdfmake_outline_remove(pdfmake_outline_item_t *item)
{
    pdfmake_outline_item_t *parent;

    if (!item || !item->parent) return PDFMAKE_EINVAL;
    
    parent = item->parent;
    
    /* Unlink from siblings */
    if (item->prev) {
        item->prev->next = item->next;
    } else {
        parent->first = item->next;
    }
    
    if (item->next) {
        item->next->prev = item->prev;
    } else {
        parent->last = item->prev;
    }
    
    update_counts(parent);
    
    /* Item and children are now orphaned but remain in arena */
    return PDFMAKE_OK;
}

size_t pdfmake_outline_count(pdfmake_outline_item_t *root)
{
    size_t count;
    pdfmake_outline_item_t *child;

    if (!root) return 0;
    
    count = 1;
    for (child = root->first; child; child = child->next) {
        count += pdfmake_outline_count(child);
    }
    return count;
}

/*----------------------------------------------------------------------------
 * Outline finalization - write to PDF
 *--------------------------------------------------------------------------*/

static uint32_t write_outline_item(pdfmake_doc_t *doc,
                                    pdfmake_outline_item_t *item,
                                    uint32_t parent_num)
{
    pdfmake_arena_t *arena = doc->arena;
    pdfmake_obj_t dict;
    uint32_t parent_key;
    uint32_t item_num;
    pdfmake_outline_item_t *child;
    uint32_t first_key;
    uint32_t last_key;
    pdfmake_obj_t *obj_ptr;

    /* Build the outline item dictionary */
    dict = pdfmake_dict_new(arena);
    
    /* /Title */
    if (item->title) {
        uint32_t key = pdfmake_arena_intern_name(arena, "Title", 5);
        pdfmake_obj_t title_str = pdfmake_str(arena, item->title, strlen(item->title));
        pdfmake_dict_set(arena, &dict, key, title_str);
    }
    
    /* /Parent */
    parent_key = pdfmake_arena_intern_name(arena, "Parent", 6);
    pdfmake_dict_set(arena, &dict, parent_key, pdfmake_ref(parent_num, 0));
    
    /* /Dest */
    if (item->title) {  /* Only add dest if this is a real item, not root container */
        uint32_t dest_key = pdfmake_arena_intern_name(arena, "Dest", 4);
        pdfmake_obj_t dest_arr = pdfmake_dest_to_obj(arena, doc, item->dest);
        pdfmake_dict_set(arena, &dict, dest_key, dest_arr);
    }
    
    /* Reserve object number first so we can pass to children */
    item_num = pdfmake_doc_add(doc, pdfmake_null());
    item->obj_num = item_num;
    
    /* Write children first to get their object numbers */
    if (item->first) {
        uint32_t first_num = 0, last_num = 0;
        
        for (child = item->first; child; child = child->next) {
            uint32_t child_num = write_outline_item(doc, child, item_num);
            if (!first_num) first_num = child_num;
            last_num = child_num;
        }
        
        /* Now update children with sibling links */
        for (child = item->first; child; child = child->next) {
            pdfmake_obj_t *child_obj = pdfmake_doc_get(doc, child->obj_num);
            if (child_obj) {
                if (child->prev) {
                    uint32_t prev_key = pdfmake_arena_intern_name(arena, "Prev", 4);
                    pdfmake_dict_set(arena, child_obj, prev_key, pdfmake_ref(child->prev->obj_num, 0));
                }
                if (child->next) {
                    uint32_t next_key = pdfmake_arena_intern_name(arena, "Next", 4);
                    pdfmake_dict_set(arena, child_obj, next_key, pdfmake_ref(child->next->obj_num, 0));
                }
            }
        }
        
        /* /First and /Last */
        first_key = pdfmake_arena_intern_name(arena, "First", 5);
        last_key = pdfmake_arena_intern_name(arena, "Last", 4);
        pdfmake_dict_set(arena, &dict, first_key, pdfmake_ref(first_num, 0));
        pdfmake_dict_set(arena, &dict, last_key, pdfmake_ref(last_num, 0));
    }
    
    /* /Count */
    if (item->count > 0) {
        uint32_t count_key = pdfmake_arena_intern_name(arena, "Count", 5);
        int count_val = item->open ? item->count : -item->count;
        pdfmake_dict_set(arena, &dict, count_key, pdfmake_int(count_val));
    }
    
    /* Update the reserved object */
    obj_ptr = pdfmake_doc_get(doc, item_num);
    if (obj_ptr) {
        *obj_ptr = dict;
    }
    
    return item_num;
}

uint32_t pdfmake_outline_finalize(pdfmake_doc_t *doc,
                                   pdfmake_outline_item_t *root)
{
    pdfmake_arena_t *arena;
    pdfmake_obj_t outlines_dict;
    uint32_t type_key;
    uint32_t outlines_num;
    pdfmake_outline_item_t *child;
    uint32_t first_key;
    uint32_t last_key;
    uint32_t count_key;
    pdfmake_obj_t *outlines_ptr;

    if (!doc || !root) return 0;
    
    arena = doc->arena;
    
    /* Create /Outlines dictionary */
    outlines_dict = pdfmake_dict_new(arena);
    
    type_key = pdfmake_arena_intern_name(arena, "Type", 4);
    pdfmake_dict_set(arena, &outlines_dict, type_key, pdfmake_name(arena, "Outlines", 8));
    
    outlines_num = pdfmake_doc_add(doc, outlines_dict);
    
    /* If root has a title, it's a real item; otherwise just use its children */
    if (root->title) {
        /* Root is a real outline item */
        uint32_t root_item_num = write_outline_item(doc, root, outlines_num);
        
        first_key = pdfmake_arena_intern_name(arena, "First", 5);
        last_key = pdfmake_arena_intern_name(arena, "Last", 4);
        count_key = pdfmake_arena_intern_name(arena, "Count", 5);
        
        outlines_ptr = pdfmake_doc_get(doc, outlines_num);
        if (outlines_ptr) {
            pdfmake_dict_set(arena, outlines_ptr, first_key, pdfmake_ref(root_item_num, 0));
            pdfmake_dict_set(arena, outlines_ptr, last_key, pdfmake_ref(root_item_num, 0));
            pdfmake_dict_set(arena, outlines_ptr, count_key, pdfmake_int(1 + root->count));
        }
    } else if (root->first) {
        /* Root is a container - write its children directly under /Outlines */
        uint32_t first_num = 0, last_num = 0;
        int total_count = 0;
        
        for (child = root->first; child; child = child->next) {
            uint32_t child_num = write_outline_item(doc, child, outlines_num);
            if (!first_num) first_num = child_num;
            last_num = child_num;
            total_count++;
            if (child->open) total_count += child->count;
        }
        
        /* Update sibling links */
        for (child = root->first; child; child = child->next) {
            pdfmake_obj_t *child_obj = pdfmake_doc_get(doc, child->obj_num);
            if (child_obj) {
                if (child->prev) {
                    uint32_t prev_key = pdfmake_arena_intern_name(arena, "Prev", 4);
                    pdfmake_dict_set(arena, child_obj, prev_key, pdfmake_ref(child->prev->obj_num, 0));
                }
                if (child->next) {
                    uint32_t next_key = pdfmake_arena_intern_name(arena, "Next", 4);
                    pdfmake_dict_set(arena, child_obj, next_key, pdfmake_ref(child->next->obj_num, 0));
                }
            }
        }
        
        first_key = pdfmake_arena_intern_name(arena, "First", 5);
        last_key = pdfmake_arena_intern_name(arena, "Last", 4);
        count_key = pdfmake_arena_intern_name(arena, "Count", 5);
        
        outlines_ptr = pdfmake_doc_get(doc, outlines_num);
        if (outlines_ptr) {
            pdfmake_dict_set(arena, outlines_ptr, first_key, pdfmake_ref(first_num, 0));
            pdfmake_dict_set(arena, outlines_ptr, last_key, pdfmake_ref(last_num, 0));
            pdfmake_dict_set(arena, outlines_ptr, count_key, pdfmake_int(total_count));
        }
    }
    
    return outlines_num;
}
