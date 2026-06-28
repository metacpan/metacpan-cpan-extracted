/*
 * pdfmake_annot.c — PDF annotation builders implementation
 */

#include "pdfmake_annot.h"
#include "pdfmake_arena.h"
#include <string.h>
#include <stdlib.h>

/*============================================================================
 * Helper: Build common annotation dict entries
 *==========================================================================*/

static pdfmake_obj_t build_annot_base(pdfmake_arena_t *arena,
                                       const char *subtype,
                                       pdfmake_rect_t rect) {
    pdfmake_obj_t dict;
    uint32_t type_key;
    uint32_t subtype_key;
    uint32_t rect_key;
    pdfmake_obj_t rect_arr;

    dict = pdfmake_dict_new(arena);
    if (dict.kind != PDFMAKE_DICT) return dict;
    
    type_key = pdfmake_arena_intern_name(arena, "Type", 4);
    subtype_key = pdfmake_arena_intern_name(arena, "Subtype", 7);
    rect_key = pdfmake_arena_intern_name(arena, "Rect", 4);
    
    pdfmake_dict_set(arena, &dict, type_key, pdfmake_name_cstr(arena, "Annot"));
    pdfmake_dict_set(arena, &dict, subtype_key, pdfmake_name_cstr(arena, subtype));
    
    /* Build /Rect array */
    rect_arr = pdfmake_array_new(arena);
    pdfmake_array_push(arena, &rect_arr, pdfmake_real(rect.x1));
    pdfmake_array_push(arena, &rect_arr, pdfmake_real(rect.y1));
    pdfmake_array_push(arena, &rect_arr, pdfmake_real(rect.x2));
    pdfmake_array_push(arena, &rect_arr, pdfmake_real(rect.y2));
    pdfmake_dict_set(arena, &dict, rect_key, rect_arr);
    
    return dict;
}

/*============================================================================
 * Text annotation
 *==========================================================================*/

static const char *icon_names[] = {
    "Note",
    "Comment", 
    "Key",
    "Help",
    "Paragraph",
    "NewParagraph",
    "Insert"
};

uint32_t pdfmake_annot_text(pdfmake_doc_t *doc,
                            pdfmake_rect_t rect,
                            const char *contents,
                            pdfmake_annot_icon_t icon,
                            int open) {
    pdfmake_arena_t *arena;
    pdfmake_obj_t dict;
    uint32_t contents_key;
    uint32_t open_key;
    uint32_t name_key;

    if (!doc || !contents) return 0;
    if (icon > PDFMAKE_ANNOT_ICON_INSERT) return 0;
    
    arena = pdfmake_doc_arena(doc);
    
    dict = build_annot_base(arena, "Text", rect);
    if (dict.kind != PDFMAKE_DICT) return 0;
    
    contents_key = pdfmake_arena_intern_name(arena, "Contents", 8);
    open_key = pdfmake_arena_intern_name(arena, "Open", 4);
    name_key = pdfmake_arena_intern_name(arena, "Name", 4);
    
    pdfmake_dict_set(arena, &dict, contents_key, 
                     pdfmake_str(arena, contents, strlen(contents)));
    pdfmake_dict_set(arena, &dict, open_key, pdfmake_bool(open));
    pdfmake_dict_set(arena, &dict, name_key, 
                     pdfmake_name_cstr(arena, icon_names[icon]));
    
    return pdfmake_doc_add(doc, dict);
}

/*============================================================================
 * Markup annotations (Highlight, Underline, etc.)
 *==========================================================================*/

static const char *markup_subtypes[] = {
    "Highlight",
    "Underline",
    "Squiggly",
    "StrikeOut"
};

uint32_t pdfmake_annot_markup(pdfmake_doc_t *doc,
                               pdfmake_rect_t rect,
                               const double *quads,
                               size_t quad_count,
                               pdfmake_markup_type_t type,
                               const double *color) {
    pdfmake_arena_t *arena;
    pdfmake_obj_t dict;
    uint32_t qp_key;
    pdfmake_obj_t qp_arr;
    size_t num_values;
    size_t i;
    uint32_t c_key;
    pdfmake_obj_t c_arr;

    if (!doc || !quads || quad_count == 0) return 0;
    if (type > PDFMAKE_MARKUP_STRIKEOUT) return 0;
    
    arena = pdfmake_doc_arena(doc);
    
    dict = build_annot_base(arena, markup_subtypes[type], rect);
    if (dict.kind != PDFMAKE_DICT) return 0;
    
    /* Build /QuadPoints array */
    qp_key = pdfmake_arena_intern_name(arena, "QuadPoints", 10);
    qp_arr = pdfmake_array_new(arena);
    
    num_values = quad_count * 8;  /* 8 values per quad */
    for (i = 0; i < num_values; i++) {
        pdfmake_array_push(arena, &qp_arr, pdfmake_real(quads[i]));
    }
    pdfmake_dict_set(arena, &dict, qp_key, qp_arr);
    
    /* Set color if provided */
    if (color) {
        c_key = pdfmake_arena_intern_name(arena, "C", 1);
        c_arr = pdfmake_array_new(arena);
        pdfmake_array_push(arena, &c_arr, pdfmake_real(color[0]));
        pdfmake_array_push(arena, &c_arr, pdfmake_real(color[1]));
        pdfmake_array_push(arena, &c_arr, pdfmake_real(color[2]));
        pdfmake_dict_set(arena, &dict, c_key, c_arr);
    }
    
    return pdfmake_doc_add(doc, dict);
}

uint32_t pdfmake_annot_highlight(pdfmake_doc_t *doc,
                                  pdfmake_rect_t rect,
                                  const double *quads,
                                  size_t quad_count,
                                  const double *color) {
    return pdfmake_annot_markup(doc, rect, quads, quad_count,
                                 PDFMAKE_MARKUP_HIGHLIGHT, color);
}

/*============================================================================
 * Link annotation
 *==========================================================================*/

uint32_t pdfmake_annot_link_uri(pdfmake_doc_t *doc,
                                 pdfmake_rect_t rect,
                                 const char *uri) {
    pdfmake_arena_t *arena;
    pdfmake_obj_t dict;
    pdfmake_obj_t action;
    uint32_t s_key;
    uint32_t uri_key;
    uint32_t a_key;
    uint32_t border_key;
    pdfmake_obj_t border;

    if (!doc || !uri) return 0;
    
    arena = pdfmake_doc_arena(doc);
    
    dict = build_annot_base(arena, "Link", rect);
    if (dict.kind != PDFMAKE_DICT) return 0;
    
    /* Build URI action dict */
    action = pdfmake_dict_new(arena);
    s_key = pdfmake_arena_intern_name(arena, "S", 1);
    uri_key = pdfmake_arena_intern_name(arena, "URI", 3);
    
    pdfmake_dict_set(arena, &action, s_key, pdfmake_name_cstr(arena, "URI"));
    pdfmake_dict_set(arena, &action, uri_key, 
                     pdfmake_str(arena, uri, strlen(uri)));
    
    /* Set /A (action) in link annotation */
    a_key = pdfmake_arena_intern_name(arena, "A", 1);
    pdfmake_dict_set(arena, &dict, a_key, action);
    
    /* /Border [0 0 0] - no visible border */
    border_key = pdfmake_arena_intern_name(arena, "Border", 6);
    border = pdfmake_array_new(arena);
    pdfmake_array_push(arena, &border, pdfmake_int(0));
    pdfmake_array_push(arena, &border, pdfmake_int(0));
    pdfmake_array_push(arena, &border, pdfmake_int(0));
    pdfmake_dict_set(arena, &dict, border_key, border);
    
    return pdfmake_doc_add(doc, dict);
}

uint32_t pdfmake_annot_link_goto(pdfmake_doc_t *doc,
                                  pdfmake_rect_t rect,
                                  size_t dest_page) {
    pdfmake_arena_t *arena;
    pdfmake_obj_t dict;
    uint32_t dest_key;
    pdfmake_obj_t dest_arr;
    pdfmake_page_t *page;
    uint32_t border_key;
    pdfmake_obj_t border;

    if (!doc) return 0;
    if (dest_page >= pdfmake_doc_page_count(doc)) return 0;
    
    arena = pdfmake_doc_arena(doc);
    
    dict = build_annot_base(arena, "Link", rect);
    if (dict.kind != PDFMAKE_DICT) return 0;
    
    /* Build /Dest array: [page /Fit] */
    dest_key = pdfmake_arena_intern_name(arena, "Dest", 4);
    dest_arr = pdfmake_array_new(arena);
    
    /* Get page reference */
    page = pdfmake_doc_get_page(doc, dest_page);
    if (page && page->page_num > 0) {
        pdfmake_array_push(arena, &dest_arr, pdfmake_ref(page->page_num, 0));
    } else {
        /* Page not yet finalized - use page index */
        pdfmake_array_push(arena, &dest_arr, pdfmake_int((int64_t)dest_page));
    }
    pdfmake_array_push(arena, &dest_arr, pdfmake_name_cstr(arena, "Fit"));
    
    pdfmake_dict_set(arena, &dict, dest_key, dest_arr);
    
    /* /Border [0 0 0] */
    border_key = pdfmake_arena_intern_name(arena, "Border", 6);
    border = pdfmake_array_new(arena);
    pdfmake_array_push(arena, &border, pdfmake_int(0));
    pdfmake_array_push(arena, &border, pdfmake_int(0));
    pdfmake_array_push(arena, &border, pdfmake_int(0));
    pdfmake_dict_set(arena, &dict, border_key, border);
    
    return pdfmake_doc_add(doc, dict);
}

/*============================================================================
 * Stamp annotation
 *==========================================================================*/

static const char *stamp_names[] = {
    "Approved",
    "Experimental",
    "NotApproved",
    "AsIs",
    "Expired",
    "NotForPublicRelease",
    "Confidential",
    "Final",
    "Sold",
    "Departmental",
    "ForLegalReview",
    "TopSecret",
    "Draft",
    "ForComment"
};

uint32_t pdfmake_annot_stamp(pdfmake_doc_t *doc,
                              pdfmake_rect_t rect,
                              pdfmake_stamp_type_t type) {
    pdfmake_arena_t *arena;
    pdfmake_obj_t dict;
    uint32_t name_key;

    if (!doc) return 0;
    if (type > PDFMAKE_STAMP_FORCOMMENT) return 0;
    
    arena = pdfmake_doc_arena(doc);
    
    dict = build_annot_base(arena, "Stamp", rect);
    if (dict.kind != PDFMAKE_DICT) return 0;
    
    name_key = pdfmake_arena_intern_name(arena, "Name", 4);
    pdfmake_dict_set(arena, &dict, name_key, 
                     pdfmake_name_cstr(arena, stamp_names[type]));
    
    return pdfmake_doc_add(doc, dict);
}

/*============================================================================
 * Ink annotation
 *==========================================================================*/

uint32_t pdfmake_annot_ink(pdfmake_doc_t *doc,
                            pdfmake_rect_t rect,
                            const double **paths,
                            const size_t *path_counts,
                            size_t num_paths,
                            const double *color,
                            double width) {
    pdfmake_arena_t *arena;
    pdfmake_obj_t dict;
    uint32_t inklist_key;
    pdfmake_obj_t inklist;
    size_t p;
    pdfmake_obj_t path_arr;
    size_t num_coords;
    size_t i;
    uint32_t c_key;
    pdfmake_obj_t c_arr;
    uint32_t bs_key;
    pdfmake_obj_t bs;
    uint32_t w_key;

    if (!doc || !paths || !path_counts || num_paths == 0) return 0;
    
    arena = pdfmake_doc_arena(doc);
    
    dict = build_annot_base(arena, "Ink", rect);
    if (dict.kind != PDFMAKE_DICT) return 0;
    
    /* Build /InkList array of arrays */
    inklist_key = pdfmake_arena_intern_name(arena, "InkList", 7);
    inklist = pdfmake_array_new(arena);
    
    for (p = 0; p < num_paths; p++) {
        path_arr = pdfmake_array_new(arena);
        num_coords = path_counts[p] * 2;  /* x,y pairs */
        for (i = 0; i < num_coords; i++) {
            pdfmake_array_push(arena, &path_arr, pdfmake_real(paths[p][i]));
        }
        pdfmake_array_push(arena, &inklist, path_arr);
    }
    pdfmake_dict_set(arena, &dict, inklist_key, inklist);
    
    /* Set color if provided */
    if (color) {
        c_key = pdfmake_arena_intern_name(arena, "C", 1);
        c_arr = pdfmake_array_new(arena);
        pdfmake_array_push(arena, &c_arr, pdfmake_real(color[0]));
        pdfmake_array_push(arena, &c_arr, pdfmake_real(color[1]));
        pdfmake_array_push(arena, &c_arr, pdfmake_real(color[2]));
        pdfmake_dict_set(arena, &dict, c_key, c_arr);
    }
    
    /* Set border style for line width */
    if (width > 0) {
        bs_key = pdfmake_arena_intern_name(arena, "BS", 2);
        bs = pdfmake_dict_new(arena);
        w_key = pdfmake_arena_intern_name(arena, "W", 1);
        pdfmake_dict_set(arena, &bs, w_key, pdfmake_real(width));
        pdfmake_dict_set(arena, &dict, bs_key, bs);
    }
    
    return pdfmake_doc_add(doc, dict);
}

/*============================================================================
 * Page annotation attachment
 *==========================================================================*/

pdfmake_err_t pdfmake_page_add_annot(pdfmake_page_t *page, uint32_t annot_num) {
    size_t new_cap;
    uint32_t *new_arr;

    if (!page || annot_num == 0) return PDFMAKE_EINVAL;

    /* Grow annots array if needed */
    if (page->annot_count >= page->annot_cap) {
        new_cap = page->annot_cap ? page->annot_cap * 2 : 8;
        new_arr = realloc(page->annots, new_cap * sizeof(uint32_t));
        if (!new_arr) return PDFMAKE_ENOMEM;
        page->annots = new_arr;
        page->annot_cap = new_cap;
    }
    page->annots[page->annot_count++] = annot_num;
    return PDFMAKE_OK;
}
