/*
 * pdfmake_ocg.c — Optional Content Groups (Layers)
 *
 * §8.11 Optional Content
 */

#include "pdfmake_ocg.h"
#include "pdfmake_page.h"
#include "pdfmake_arena.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* ── Document-level OCG management ──────────────────────── */

pdfmake_ocg_t *pdfmake_doc_create_ocg(pdfmake_doc_t *doc, const char *name) {
    pdfmake_ocg_t *ocg;
    if (!doc || !name) return NULL;

    /* Grow array if needed */
    if (doc->ocg_count >= doc->ocg_cap) {
        size_t new_cap = doc->ocg_cap == 0 ? 4 : doc->ocg_cap * 2;
        void **new_arr = realloc(doc->ocgs, new_cap * sizeof(void *));
        if (!new_arr) return NULL;
        doc->ocgs = new_arr;
        doc->ocg_cap = new_cap;
    }

    ocg = pdfmake_arena_calloc(doc->arena, sizeof(pdfmake_ocg_t));
    if (!ocg) return NULL;

    strncpy(ocg->name, name, sizeof(ocg->name) - 1);
    ocg->visible = 1;  /* default ON */
    ocg->intent = PDFMAKE_OCG_INTENT_VIEW;
    ocg->obj_num = 0;

    /* Generate resource name: MC0, MC1, ... */
    snprintf(ocg->res_name, sizeof(ocg->res_name), "MC%zu", doc->ocg_count);

    doc->ocgs[doc->ocg_count++] = ocg;
    return ocg;
}

size_t pdfmake_doc_ocg_count(pdfmake_doc_t *doc) {
    return doc ? doc->ocg_count : 0;
}

pdfmake_ocg_t *pdfmake_doc_ocg_at(pdfmake_doc_t *doc, size_t idx) {
    if (!doc || idx >= doc->ocg_count) return NULL;
    return (pdfmake_ocg_t *)doc->ocgs[idx];
}

pdfmake_ocg_t *pdfmake_doc_ocg_by_name(pdfmake_doc_t *doc, const char *name) {
    size_t i;
    pdfmake_ocg_t *ocg;
    if (!doc || !name) return NULL;
    for (i = 0; i < doc->ocg_count; i++) {
        ocg = (pdfmake_ocg_t *)doc->ocgs[i];
        if (strcmp(ocg->name, name) == 0) return ocg;
    }
    return NULL;
}

/* ── Write OCG dictionary ───────────────────────────────── */

uint32_t pdfmake_ocg_write(pdfmake_ocg_t *ocg, pdfmake_doc_t *doc) {
    pdfmake_arena_t *arena;
    pdfmake_obj_t dict;
    uint32_t k;
    pdfmake_obj_t usage;
    uint32_t usage_key;
    pdfmake_obj_t print_dict;
    uint32_t ps_key;
    uint32_t print_key;
    pdfmake_obj_t view_dict;
    uint32_t vs_key;
    uint32_t view_key;
    pdfmake_obj_t export_dict;
    uint32_t es_key;
    uint32_t exp_key;
    if (!ocg || !doc) return 0;
    if (ocg->obj_num) return ocg->obj_num;  /* already written */

    arena = pdfmake_doc_arena(doc);

    dict = pdfmake_dict_new(arena);
    if (dict.kind != PDFMAKE_DICT) return 0;

    k = pdfmake_arena_intern_name(arena, "Type", 4);
    pdfmake_dict_set(arena, &dict, k, pdfmake_name_cstr(arena, "OCG"));

    k = pdfmake_arena_intern_name(arena, "Name", 4);
    pdfmake_dict_set(arena, &dict, k, pdfmake_str_cstr(arena, ocg->name));

    /* Intent */
    k = pdfmake_arena_intern_name(arena, "Intent", 6);
    pdfmake_dict_set(arena, &dict, k, pdfmake_name_cstr(arena,
        ocg->intent == PDFMAKE_OCG_INTENT_DESIGN ? "Design" : "View"));

    /* Usage dictionary */
    if (ocg->has_print_state || ocg->has_view_state || ocg->has_export_state) {
        usage = pdfmake_dict_new(arena);
        usage_key = pdfmake_arena_intern_name(arena, "Usage", 5);

        if (ocg->has_print_state) {
            print_dict = pdfmake_dict_new(arena);
            ps_key = pdfmake_arena_intern_name(arena, "PrintState", 10);
            pdfmake_dict_set(arena, &print_dict, ps_key,
                pdfmake_name_cstr(arena, ocg->print_state == PDFMAKE_OCG_ON ? "ON" : "OFF"));
            print_key = pdfmake_arena_intern_name(arena, "Print", 5);
            pdfmake_dict_set(arena, &usage, print_key, print_dict);
        }

        if (ocg->has_view_state) {
            view_dict = pdfmake_dict_new(arena);
            vs_key = pdfmake_arena_intern_name(arena, "ViewState", 9);
            pdfmake_dict_set(arena, &view_dict, vs_key,
                pdfmake_name_cstr(arena, ocg->view_state == PDFMAKE_OCG_ON ? "ON" : "OFF"));
            view_key = pdfmake_arena_intern_name(arena, "View", 4);
            pdfmake_dict_set(arena, &usage, view_key, view_dict);
        }

        if (ocg->has_export_state) {
            export_dict = pdfmake_dict_new(arena);
            es_key = pdfmake_arena_intern_name(arena, "ExportState", 11);
            pdfmake_dict_set(arena, &export_dict, es_key,
                pdfmake_name_cstr(arena, ocg->export_state == PDFMAKE_OCG_ON ? "ON" : "OFF"));
            exp_key = pdfmake_arena_intern_name(arena, "Export", 6);
            pdfmake_dict_set(arena, &usage, exp_key, export_dict);
        }

        pdfmake_dict_set(arena, &dict, usage_key, usage);
    }

    ocg->obj_num = pdfmake_doc_add(doc, dict);
    return ocg->obj_num;
}

/* ── Write /OCProperties ────────────────────────────────── */

pdfmake_err_t pdfmake_doc_write_ocproperties(pdfmake_doc_t *doc) {
    pdfmake_arena_t *arena;
    size_t i;
    pdfmake_ocg_t *ocg;
    pdfmake_obj_t ocgs_arr;
    pdfmake_obj_t config;
    uint32_t k;
    pdfmake_obj_t off_arr;
    int has_off;
    pdfmake_obj_t order_arr;
    pdfmake_obj_t ocprops;
    pdfmake_obj_t *catalog;
    if (!doc || doc->ocg_count == 0) return PDFMAKE_OK;

    arena = pdfmake_doc_arena(doc);

    /* Ensure all OCGs are written */
    for (i = 0; i < doc->ocg_count; i++) {
        ocg = (pdfmake_ocg_t *)doc->ocgs[i];
        if (!ocg->obj_num) {
            if (pdfmake_ocg_write(ocg, doc) == 0)
                return PDFMAKE_ENOMEM;
        }
    }

    /* Build /OCGs array */
    ocgs_arr = pdfmake_array_new(arena);
    for (i = 0; i < doc->ocg_count; i++) {
        ocg = (pdfmake_ocg_t *)doc->ocgs[i];
        pdfmake_array_push(arena, &ocgs_arr, pdfmake_ref(ocg->obj_num, 0));
    }

    /* Build default config /D */
    config = pdfmake_dict_new(arena);

    k = pdfmake_arena_intern_name(arena, "Name", 4);
    pdfmake_dict_set(arena, &config, k, pdfmake_str_cstr(arena, "Default"));

    k = pdfmake_arena_intern_name(arena, "BaseState", 9);
    pdfmake_dict_set(arena, &config, k, pdfmake_name_cstr(arena, "ON"));

    /* Build OFF array for initially hidden layers */
    off_arr = pdfmake_array_new(arena);
    has_off = 0;
    for (i = 0; i < doc->ocg_count; i++) {
        ocg = (pdfmake_ocg_t *)doc->ocgs[i];
        if (!ocg->visible) {
            pdfmake_array_push(arena, &off_arr, pdfmake_ref(ocg->obj_num, 0));
            has_off = 1;
        }
    }
    if (has_off) {
        k = pdfmake_arena_intern_name(arena, "OFF", 3);
        pdfmake_dict_set(arena, &config, k, off_arr);
    }

    /* Order array (same as OCGs array — flat order) */
    order_arr = pdfmake_array_new(arena);
    for (i = 0; i < doc->ocg_count; i++) {
        ocg = (pdfmake_ocg_t *)doc->ocgs[i];
        pdfmake_array_push(arena, &order_arr, pdfmake_ref(ocg->obj_num, 0));
    }
    k = pdfmake_arena_intern_name(arena, "Order", 5);
    pdfmake_dict_set(arena, &config, k, order_arr);

    /* Build /OCProperties dict */
    ocprops = pdfmake_dict_new(arena);
    k = pdfmake_arena_intern_name(arena, "OCGs", 4);
    pdfmake_dict_set(arena, &ocprops, k, ocgs_arr);
    k = pdfmake_arena_intern_name(arena, "D", 1);
    pdfmake_dict_set(arena, &ocprops, k, config);

    /* Add to catalog */
    catalog = pdfmake_doc_get(doc, doc->root_num);
    if (!catalog || catalog->kind != PDFMAKE_DICT) return PDFMAKE_EINVAL;

    k = pdfmake_arena_intern_name(arena, "OCProperties", 12);
    pdfmake_dict_set(arena, catalog, k, ocprops);

    return PDFMAKE_OK;
}

/* ── Page /Properties resource ──────────────────────────── */

int pdfmake_page_add_ocg(pdfmake_page_t *page, const char *name, uint32_t ocg_obj_num) {
    pdfmake_prop_entry_t *entry;
    if (!page || !name || ocg_obj_num == 0) return -1;
    if (page->prop_count >= PDFMAKE_MAX_PAGE_PROPERTIES) return -1;

    entry = &page->properties[page->prop_count++];
    strncpy(entry->name, name, sizeof(entry->name) - 1);
    entry->name[sizeof(entry->name) - 1] = '\0';
    entry->prop_num = ocg_obj_num;

    return (int)(page->prop_count - 1);
}

/* ── Content stream OCG helpers ─────────────────────────── */

pdfmake_err_t pdfmake_content_begin_ocg(pdfmake_content_t *c, const char *res_name) {
    if (!c || !res_name) return PDFMAKE_EINVAL;
    return pdfmake_mc_BDC(c, "OC", res_name);
}

pdfmake_err_t pdfmake_content_end_ocg(pdfmake_content_t *c) {
    if (!c) return PDFMAKE_EINVAL;
    return pdfmake_mc_EMC(c);
}
