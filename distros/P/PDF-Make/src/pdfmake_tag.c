/*
 * pdfmake_tag.c — Tagged PDF / Logical Structure
 *
 * §14.6 Marked Content, §14.7 Logical Structure, §14.8 Tagged PDF
 */

#include "pdfmake_tag.h"
#include "pdfmake_page.h"
#include "pdfmake_arena.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* ── Type names ────────────────────────────────────────── */

static const char *_struct_type_names[] = {
    "Document", "Part", "Art", "Sect", "Div",
    "BlockQuote", "Caption", "TOC", "TOCI",
    "P", "H", "H1", "H2", "H3", "H4", "H5", "H6",
    "L", "LI", "Lbl", "LBody",
    "Table", "TR", "TH", "TD", "THead", "TBody", "TFoot",
    "Span", "Quote", "Note", "Reference", "Code", "Link", "Annot",
    "Figure", "Formula", "Form",
};

const char *pdfmake_struct_type_name(pdfmake_struct_type_t type) {
    if (type < 0 || type >= PDFMAKE_TAG_COUNT) return "Div";
    return _struct_type_names[type];
}

int pdfmake_struct_type_lookup(const char *name) {
    int i;
    if (!name) return -1;
    for (i = 0; i < PDFMAKE_TAG_COUNT; i++) {
        if (strcmp(name, _struct_type_names[i]) == 0) return i;
    }
    return -1;
}

/* ── Document-level ────────────────────────────────────── */

pdfmake_struct_tree_t *pdfmake_doc_create_struct_tree(pdfmake_doc_t *doc) {
    pdfmake_struct_tree_t *tree;

    if (!doc) return NULL;

    /* Reuse if already exists on this document */
    if (doc->struct_tree) return (pdfmake_struct_tree_t *)doc->struct_tree;

    tree = calloc(1, sizeof(*tree));
    if (!tree) return NULL;

    /* Create root Document element */
    tree->root = calloc(1, sizeof(pdfmake_struct_elem_t));
    if (!tree->root) { free(tree); return NULL; }
    tree->root->type = PDFMAKE_TAG_DOCUMENT;

    doc->struct_tree = tree;
    return tree;
}

pdfmake_struct_tree_t *pdfmake_doc_struct_tree(pdfmake_doc_t *doc) {
    return doc ? (pdfmake_struct_tree_t *)doc->struct_tree : NULL;
}

/* ── Structure elements ────────────────────────────────── */

pdfmake_struct_elem_t *pdfmake_struct_elem_create(
    pdfmake_doc_t *doc,
    pdfmake_struct_type_t type,
    pdfmake_struct_elem_t *parent)
{
    pdfmake_struct_elem_t *elem;
    size_t new_cap;
    pdfmake_struct_elem_t **new_arr;

    (void)doc;
    elem = calloc(1, sizeof(*elem));
    if (!elem) return NULL;

    elem->type = type;
    elem->parent = parent;

    /* Add to parent's children */
    if (parent) {
        if (parent->child_count >= parent->child_cap) {
            new_cap = parent->child_cap == 0 ? 8 : parent->child_cap * 2;
            new_arr = realloc(parent->children,
                new_cap * sizeof(pdfmake_struct_elem_t *));
            if (!new_arr) { free(elem); return NULL; }
            parent->children = new_arr;
            parent->child_cap = new_cap;
        }
        parent->children[parent->child_count++] = elem;
    }

    return elem;
}

pdfmake_struct_elem_t *pdfmake_struct_elem_create_custom(
    pdfmake_doc_t *doc,
    const char *custom_type,
    pdfmake_struct_elem_t *parent)
{
    pdfmake_struct_elem_t *elem = pdfmake_struct_elem_create(doc, PDFMAKE_TAG_DIV, parent);
    if (elem && custom_type) {
        strncpy(elem->custom_type, custom_type, sizeof(elem->custom_type) - 1);
    }
    return elem;
}

pdfmake_err_t pdfmake_struct_elem_set_alt_text(pdfmake_struct_elem_t *elem, const char *alt) {
    if (!elem || !alt) return PDFMAKE_EINVAL;
    strncpy(elem->alt_text, alt, sizeof(elem->alt_text) - 1);
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_struct_elem_set_actual_text(pdfmake_struct_elem_t *elem, const char *text) {
    if (!elem || !text) return PDFMAKE_EINVAL;
    strncpy(elem->actual_text, text, sizeof(elem->actual_text) - 1);
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_struct_elem_set_lang(pdfmake_struct_elem_t *elem, const char *lang) {
    if (!elem || !lang) return PDFMAKE_EINVAL;
    strncpy(elem->lang, lang, sizeof(elem->lang) - 1);
    return PDFMAKE_OK;
}

size_t pdfmake_struct_elem_child_count(pdfmake_struct_elem_t *elem) {
    return elem ? elem->child_count : 0;
}

pdfmake_struct_elem_t *pdfmake_struct_elem_child_at(pdfmake_struct_elem_t *elem, size_t idx) {
    if (!elem || idx >= elem->child_count) return NULL;
    return elem->children[idx];
}

pdfmake_err_t pdfmake_struct_elem_add_mcr(
    pdfmake_struct_elem_t *elem,
    uint32_t page_obj_num,
    int mcid)
{
    size_t new_cap;
    pdfmake_mcr_t *new_arr;

    if (!elem) return PDFMAKE_EINVAL;
    if (elem->mcr_count >= elem->mcr_cap) {
        new_cap = elem->mcr_cap == 0 ? 4 : elem->mcr_cap * 2;
        new_arr = realloc(elem->content_refs, new_cap * sizeof(pdfmake_mcr_t));
        if (!new_arr) return PDFMAKE_ENOMEM;
        elem->content_refs = new_arr;
        elem->mcr_cap = new_cap;
    }
    elem->content_refs[elem->mcr_count].page_obj_num = page_obj_num;
    elem->content_refs[elem->mcr_count].mcid = mcid;
    elem->mcr_count++;
    return PDFMAKE_OK;
}

/* ── Content stream ────────────────────────────────────── */

pdfmake_err_t pdfmake_content_begin_tag(
    pdfmake_content_t *c,
    pdfmake_struct_type_t type,
    int mcid)
{
    pdfmake_buf_t *buf;
    const char *tag;
    char props[64];

    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;
    tag = pdfmake_struct_type_name(type);

    /* Emit: /Tag <</MCID n>> BDC */
    snprintf(props, sizeof(props), "<</MCID %d>>", mcid);

    pdfmake_buf_append_byte(buf, '/');
    pdfmake_buf_append_cstr(buf, tag);
    pdfmake_buf_append_byte(buf, ' ');
    pdfmake_buf_append_cstr(buf, props);
    pdfmake_buf_append_cstr(buf, " BDC\n");

    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_content_end_tag(pdfmake_content_t *c) {
    if (!c) return PDFMAKE_EINVAL;
    return pdfmake_mc_EMC(c);
}

/* ── Role mapping ──────────────────────────────────────── */

pdfmake_err_t pdfmake_struct_tree_map_role(
    pdfmake_struct_tree_t *tree,
    const char *custom,
    pdfmake_struct_type_t standard)
{
    size_t new_cap;
    void *new_arr;

    if (!tree || !custom) return PDFMAKE_EINVAL;
    if (tree->role_map_count >= tree->role_map_cap) {
        new_cap = tree->role_map_cap == 0 ? 4 : tree->role_map_cap * 2;
        new_arr = realloc(tree->role_map, new_cap * sizeof(tree->role_map[0]));
        if (!new_arr) return PDFMAKE_ENOMEM;
        tree->role_map = new_arr;
        tree->role_map_cap = new_cap;
    }
    strncpy(tree->role_map[tree->role_map_count].custom, custom, 63);
    tree->role_map[tree->role_map_count].standard = standard;
    tree->role_map_count++;
    return PDFMAKE_OK;
}

/* ── Writing ───────────────────────────────────────────── */

/* Write a single structure element recursively */
static uint32_t _write_struct_elem(pdfmake_struct_elem_t *elem,
                                     pdfmake_doc_t *doc,
                                     uint32_t parent_num)
{
    pdfmake_arena_t *arena;
    uint32_t k;
    pdfmake_obj_t dict;
    const char *type_name;
    pdfmake_obj_t kids;
    size_t i_mcr;
    size_t i_child;
    pdfmake_obj_t mcr;
    uint32_t mk;
    uint32_t child_num;
    pdfmake_obj_t *elem_obj;

    if (!elem || !doc) return 0;
    arena = pdfmake_doc_arena(doc);

    dict = pdfmake_dict_new(arena);
    k = pdfmake_arena_intern_name(arena, "Type", 4);
    pdfmake_dict_set(arena, &dict, k, pdfmake_name_cstr(arena, "StructElem"));

    /* /S — structure type */
    k = pdfmake_arena_intern_name(arena, "S", 1);
    type_name = elem->custom_type[0] ? elem->custom_type
                                     : pdfmake_struct_type_name(elem->type);
    pdfmake_dict_set(arena, &dict, k, pdfmake_name_cstr(arena, type_name));

    /* /P — parent reference */
    if (parent_num > 0) {
        k = pdfmake_arena_intern_name(arena, "P", 1);
        pdfmake_dict_set(arena, &dict, k, pdfmake_ref(parent_num, 0));
    }

    /* /Alt, /ActualText, /Lang */
    if (elem->alt_text[0]) {
        k = pdfmake_arena_intern_name(arena, "Alt", 3);
        pdfmake_dict_set(arena, &dict, k, pdfmake_str_cstr(arena, elem->alt_text));
    }
    if (elem->actual_text[0]) {
        k = pdfmake_arena_intern_name(arena, "ActualText", 10);
        pdfmake_dict_set(arena, &dict, k, pdfmake_str_cstr(arena, elem->actual_text));
    }
    if (elem->lang[0]) {
        k = pdfmake_arena_intern_name(arena, "Lang", 4);
        pdfmake_dict_set(arena, &dict, k, pdfmake_str_cstr(arena, elem->lang));
    }

    /* Add as indirect object to get our number */
    elem->obj_num = pdfmake_doc_add(doc, dict);
    if (elem->obj_num == 0) return 0;

    /* /K — children array (MCRs + child elements) */
    if (elem->mcr_count > 0 || elem->child_count > 0) {
        kids = pdfmake_array_new(arena);

        /* Marked content references */
        for (i_mcr = 0; i_mcr < elem->mcr_count; i_mcr++) {
            mcr = pdfmake_dict_new(arena);
            mk = pdfmake_arena_intern_name(arena, "Type", 4);
            pdfmake_dict_set(arena, &mcr, mk, pdfmake_name_cstr(arena, "MCR"));
            mk = pdfmake_arena_intern_name(arena, "Pg", 2);
            pdfmake_dict_set(arena, &mcr, mk,
                pdfmake_ref(elem->content_refs[i_mcr].page_obj_num, 0));
            mk = pdfmake_arena_intern_name(arena, "MCID", 4);
            pdfmake_dict_set(arena, &mcr, mk,
                pdfmake_int(elem->content_refs[i_mcr].mcid));
            pdfmake_array_push(arena, &kids, mcr);
        }

        /* Child elements */
        for (i_child = 0; i_child < elem->child_count; i_child++) {
            child_num = _write_struct_elem(elem->children[i_child], doc, elem->obj_num);
            if (child_num > 0) {
                pdfmake_array_push(arena, &kids, pdfmake_ref(child_num, 0));
            }
        }

        /* Update the element dict with /K */
        elem_obj = pdfmake_doc_get(doc, elem->obj_num);
        if (elem_obj && elem_obj->kind == PDFMAKE_DICT) {
            k = pdfmake_arena_intern_name(arena, "K", 1);
            pdfmake_dict_set(arena, elem_obj, k, kids);
        }
    }

    return elem->obj_num;
}

pdfmake_err_t pdfmake_doc_write_struct_tree(pdfmake_doc_t *doc) {
    pdfmake_struct_tree_t *tree;
    pdfmake_arena_t *arena;
    uint32_t k;
    uint32_t root_elem_num;
    pdfmake_obj_t tree_dict;
    pdfmake_obj_t rm;
    size_t i;
    uint32_t rk;
    pdfmake_obj_t *root_obj;
    pdfmake_obj_t *catalog;
    pdfmake_obj_t mark_info;
    uint32_t marked_key;

    if (!doc) return PDFMAKE_EINVAL;

    tree = pdfmake_doc_create_struct_tree(doc);
    if (!tree || !tree->root) return PDFMAKE_OK; /* No tree */
    if (tree->root->child_count == 0 && tree->root->mcr_count == 0)
        return PDFMAKE_OK; /* Empty tree */

    arena = pdfmake_doc_arena(doc);

    /* Write all elements recursively */
    root_elem_num = _write_struct_elem(tree->root, doc, 0);
    if (root_elem_num == 0) return PDFMAKE_ENOMEM;

    /* Build /StructTreeRoot */
    tree_dict = pdfmake_dict_new(arena);
    k = pdfmake_arena_intern_name(arena, "Type", 4);
    pdfmake_dict_set(arena, &tree_dict, k, pdfmake_name_cstr(arena, "StructTreeRoot"));

    k = pdfmake_arena_intern_name(arena, "K", 1);
    pdfmake_dict_set(arena, &tree_dict, k, pdfmake_ref(root_elem_num, 0));

    /* Role mapping */
    if (tree->role_map_count > 0) {
        rm = pdfmake_dict_new(arena);
        for (i = 0; i < tree->role_map_count; i++) {
            rk = pdfmake_arena_intern_name(arena,
                tree->role_map[i].custom, strlen(tree->role_map[i].custom));
            pdfmake_dict_set(arena, &rm, rk,
                pdfmake_name_cstr(arena, pdfmake_struct_type_name(tree->role_map[i].standard)));
        }
        k = pdfmake_arena_intern_name(arena, "RoleMap", 7);
        pdfmake_dict_set(arena, &tree_dict, k, rm);
    }

    tree->obj_num = pdfmake_doc_add(doc, tree_dict);
    if (tree->obj_num == 0) return PDFMAKE_ENOMEM;

    /* Update root element's /P to point to tree root */
    root_obj = pdfmake_doc_get(doc, root_elem_num);
    if (root_obj && root_obj->kind == PDFMAKE_DICT) {
        k = pdfmake_arena_intern_name(arena, "P", 1);
        pdfmake_dict_set(arena, root_obj, k, pdfmake_ref(tree->obj_num, 0));
    }

    /* Add /StructTreeRoot to catalog */
    catalog = pdfmake_doc_get(doc, doc->root_num);
    if (catalog && catalog->kind == PDFMAKE_DICT) {
        k = pdfmake_arena_intern_name(arena, "StructTreeRoot", 14);
        pdfmake_dict_set(arena, catalog, k, pdfmake_ref(tree->obj_num, 0));

        /* Mark as tagged: /MarkInfo << /Marked true >> */
        mark_info = pdfmake_dict_new(arena);
        marked_key = pdfmake_arena_intern_name(arena, "Marked", 6);
        pdfmake_dict_set(arena, &mark_info, marked_key, pdfmake_bool(1));
        k = pdfmake_arena_intern_name(arena, "MarkInfo", 8);
        pdfmake_dict_set(arena, catalog, k, mark_info);
    }

    return PDFMAKE_OK;
}
