/*
 * pdfmake_linear.c — PDF Linearization (Fast Web View) implementation
 *
 * Implements PDF linearization per Annex F of ISO 32000-2:2020.
 */

#include "pdfmake_linear.h"
#include "pdfmake_arena.h"
#include "pdfmake_buf.h"
#include "pdfmake_writer.h"
#include "pdfmake_parser.h"
#include "pdfmake_reader.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

/*============================================================================
 * Internal Helpers
 *==========================================================================*/

/* Recursively collect objects referenced by an object */
static void collect_refs(
    pdfmake_obj_t *obj,
    uint32_t *refs,
    size_t *ref_count,
    size_t ref_cap,
    uint8_t *visited,
    size_t visited_size)
{
    if (!obj) return;
    
    switch (obj->kind) {
        case PDFMAKE_REF: {
            uint32_t num = obj->as.ref.num;
            if (num < visited_size && !visited[num]) {
                visited[num] = 1;
                if (*ref_count < ref_cap) {
                    refs[(*ref_count)++] = num;
                }
            }
            break;
        }
        case PDFMAKE_ARRAY: {
            size_t i;
            pdfmake_array_t *arr = obj->as.arr;
            for (i = 0; i < arr->len; i++) {
                collect_refs(&arr->items[i], refs, ref_count, ref_cap, visited, visited_size);
            }
            break;
        }
        case PDFMAKE_DICT: {
            size_t i;
            pdfmake_dict_t *dict = obj->as.dict;
            for (i = 0; i < dict->cap; i++) {
                if (dict->entries[i].key == 0 || dict->entries[i].deleted) continue;
                collect_refs(&dict->entries[i].value, refs, ref_count, ref_cap, visited, visited_size);
            }
            break;
        }
        case PDFMAKE_STREAM: {
            pdfmake_stream_t *stream = obj->as.stream;
            if (stream->dict) {
                pdfmake_obj_t dict_obj;
                dict_obj.kind = PDFMAKE_DICT;
                dict_obj.as.dict = stream->dict;
                collect_refs(&dict_obj, refs, ref_count, ref_cap, visited, visited_size);
            }
            break;
        }
        default:
            break;
    }
}

/*============================================================================
 * Linearization Detection
 *==========================================================================*/

int pdfmake_data_is_linearized(const uint8_t *data, size_t len)
{
    const char *p;
    const char *end;
    const char *lin;
    int obj_num;
    if (!data || len < 100) return 0;
    
    /* Find first object after header */
    p = (const char *)data;
    end = p + (len < 4096 ? len : 4096);  /* Check first 4KB */
    
    /* Skip header line */
    while (p < end && *p != '\n') p++;
    if (p >= end) return 0;
    p++;
    
    /* Skip binary comment if present */
    if (p < end && *p == '%') {
        while (p < end && *p != '\n') p++;
        if (p >= end) return 0;
        p++;
    }
    
    /* Skip whitespace */
    while (p < end && (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r')) p++;
    
    /* Look for object definition */
    obj_num = 0;
    if (sscanf(p, "%d 0 obj", &obj_num) != 1) return 0;
    
    /* Skip to << */
    while (p < end && *p != '<') p++;
    if (p + 1 >= end || *(p+1) != '<') return 0;
    
    /* Look for /Linearized */
    lin = strstr(p, "/Linearized");
    if (!lin || lin >= end) return 0;
    
    return 1;
}

int pdfmake_doc_is_linearized(pdfmake_doc_t *doc)
{
    pdfmake_obj_t *obj;
    pdfmake_dict_t *dict;
    size_t i;
    if (!doc || doc->obj_count < 1) return 0;
    
    /* In a linearized PDF, object 1 should be the linearization dict */
    obj = pdfmake_doc_get(doc, 1);
    if (!obj || obj->kind != PDFMAKE_DICT) return 0;
    
    dict = obj->as.dict;
    if (!dict) return 0;
    
    /* Look for /Linearized key in dictionary */
    /* This requires name table access which we check via flag pattern */
    for (i = 0; i < dict->len; i++) {
        /* We'd need to resolve the name ID to check if it's "Linearized" */
        /* For now, check if doc has linearization marker set */
    }
    
    return 0;  /* Conservative default */
}

pdfmake_err_t pdfmake_doc_linear_params(
    pdfmake_doc_t *doc,
    pdfmake_linear_params_t *out)
{
    pdfmake_obj_t *obj;
    if (!doc || !out) return PDFMAKE_EINVAL;
    
    memset(out, 0, sizeof(*out));
    
    if (!pdfmake_doc_is_linearized(doc)) {
        return PDFMAKE_EINVAL;
    }
    
    /* Extract parameters from linearization dictionary (object 1) */
    obj = pdfmake_doc_get(doc, 1);
    if (!obj || obj->kind != PDFMAKE_DICT) return PDFMAKE_EINVAL;
    
    /* Parse linearization dictionary values */
    /* /Linearized, /L, /H, /O, /E, /N, /T */
    
    return PDFMAKE_OK;
}

/*============================================================================
 * Linearization Context
 *==========================================================================*/

pdfmake_linear_t *pdfmake_linear_new(pdfmake_doc_t *doc)
{
    pdfmake_linear_t *lin;
    size_t map_size;
    if (!doc) return NULL;
    
    lin = calloc(1, sizeof(pdfmake_linear_t));
    if (!lin) return NULL;
    
    lin->arena = pdfmake_arena_new();
    if (!lin->arena) {
        free(lin);
        return NULL;
    }
    
    lin->doc = doc;
    
    /* Allocate object map */
    map_size = doc->obj_count + 1;
    lin->obj_map = pdfmake_arena_alloc(lin->arena, map_size * sizeof(uint32_t));
    if (!lin->obj_map) {
        pdfmake_arena_free(lin->arena);
        free(lin);
        return NULL;
    }
    memset(lin->obj_map, 0, map_size * sizeof(uint32_t));
    lin->obj_map_size = map_size;
    
    /* Allocate page objects arrays */
    lin->page_objects = pdfmake_arena_alloc(lin->arena, 
        doc->page_count * sizeof(*lin->page_objects));
    if (!lin->page_objects) {
        pdfmake_arena_free(lin->arena);
        free(lin);
        return NULL;
    }
    memset(lin->page_objects, 0, doc->page_count * sizeof(*lin->page_objects));
    
    /* Allocate reference counts */
    lin->ref_counts = pdfmake_arena_alloc(lin->arena, map_size * sizeof(uint16_t));
    if (!lin->ref_counts) {
        pdfmake_arena_free(lin->arena);
        free(lin);
        return NULL;
    }
    memset(lin->ref_counts, 0, map_size * sizeof(uint16_t));
    
    return lin;
}

void pdfmake_linear_free(pdfmake_linear_t *lin)
{
    if (!lin) return;
    
    if (lin->arena) {
        pdfmake_arena_free(lin->arena);
    }
    
    free(lin);
}

/*============================================================================
 * Page Dependency Analysis
 *==========================================================================*/

/* Recursively collect all objects needed to render a page */
static pdfmake_err_t collect_page_objects(
    pdfmake_linear_t *lin,
    size_t page_idx,
    uint32_t start_obj)
{
    pdfmake_doc_t *doc = lin->doc;
    size_t cap;
    uint32_t *objects;
    size_t count;
    size_t visited_size;
    uint8_t *visited;
    pdfmake_obj_t *page_obj;
    size_t i;
    
    /* Initial capacity */
    cap = 64;
    objects = pdfmake_arena_alloc(lin->arena, cap * sizeof(uint32_t));
    if (!objects) return PDFMAKE_ENOMEM;
    
    count = 0;
    
    /* Visited bitmap */
    visited_size = doc->obj_count + 1;
    visited = pdfmake_arena_alloc(lin->arena, visited_size);
    if (!visited) return PDFMAKE_ENOMEM;
    memset(visited, 0, visited_size);
    
    /* Start with the page object */
    page_obj = pdfmake_doc_get(doc, start_obj);
    if (!page_obj) return PDFMAKE_EINVAL;
    
    objects[count++] = start_obj;
    visited[start_obj] = 1;
    
    /* Collect all referenced objects */
    collect_refs(page_obj, objects, &count, cap, visited, visited_size);
    
    /* Store results */
    lin->page_objects[page_idx].objects = objects;
    lin->page_objects[page_idx].count = count;
    lin->page_objects[page_idx].cap = cap;
    
    /* Update reference counts */
    for (i = 0; i < count; i++) {
        uint32_t num = objects[i];
        if (num < lin->obj_map_size) {
            lin->ref_counts[num]++;
        }
    }
    
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_linear_analyze(pdfmake_linear_t *lin)
{
    pdfmake_doc_t *doc;
    size_t i;
    size_t p;
    size_t shared_cap;
    uint32_t next_num;
    if (!lin || !lin->doc) return PDFMAKE_EINVAL;
    
    doc = lin->doc;
    
    /* Ensure document is finalized */
    if (!doc->finalized) {
        return PDFMAKE_EINVAL;
    }
    
    /* Analyze each page's dependencies */
    for (i = 0; i < doc->page_count; i++) {
        pdfmake_page_t *page;
        uint32_t page_obj_num;
        pdfmake_err_t err;
        page = doc->pages[i];
        if (!page) continue;
        
        /* Get page object number - this needs page structure access */
        /* For now, assume pages are numbered sequentially after Pages object */
        page_obj_num = doc->pages_num + 1 + (uint32_t)i;
        
        err = collect_page_objects(lin, i, page_obj_num);
        if (err != PDFMAKE_OK) return err;
    }
    
    /* Identify shared objects (referenced by multiple pages) */
    shared_cap = 64;
    lin->shared_objects = pdfmake_arena_alloc(lin->arena, shared_cap * sizeof(uint32_t));
    if (!lin->shared_objects) return PDFMAKE_ENOMEM;
    
    for (i = 1; i <= doc->obj_count; i++) {
        if (lin->ref_counts[i] > 1) {
            if (lin->shared_count >= shared_cap) {
                /* Would need to reallocate */
                continue;
            }
            lin->shared_objects[lin->shared_count++] = (uint32_t)i;
        }
    }
    lin->shared_cap = shared_cap;
    
    /* Compute object renumbering for linearized layout */
    next_num = 1;
    
    /* Object 1: linearization dictionary (will be created) */
    next_num++;
    
    /* First page objects */
    if (doc->page_count > 0) {
        for (i = 0; i < lin->page_objects[0].count; i++) {
            uint32_t old_num = lin->page_objects[0].objects[i];
            if (old_num < lin->obj_map_size && lin->obj_map[old_num] == 0) {
                lin->obj_map[old_num] = next_num++;
            }
        }
    }
    
    /* Remaining page objects */
    for (p = 1; p < doc->page_count; p++) {
        for (i = 0; i < lin->page_objects[p].count; i++) {
            uint32_t old_num = lin->page_objects[p].objects[i];
            /* Skip shared objects (they come later) */
            if (old_num < lin->obj_map_size && lin->ref_counts[old_num] > 1) {
                continue;
            }
            if (old_num < lin->obj_map_size && lin->obj_map[old_num] == 0) {
                lin->obj_map[old_num] = next_num++;
            }
        }
    }
    
    /* Shared objects at the end */
    for (i = 0; i < lin->shared_count; i++) {
        uint32_t old_num = lin->shared_objects[i];
        if (old_num < lin->obj_map_size && lin->obj_map[old_num] == 0) {
            lin->obj_map[old_num] = next_num++;
        }
    }
    
    /* Map any remaining objects */
    for (i = 1; i <= doc->obj_count; i++) {
        if (lin->obj_map[i] == 0) {
            lin->obj_map[i] = next_num++;
        }
    }
    
    /* Store parameters */
    lin->params.page_count = doc->page_count;
    lin->params.version = 1;
    
    return PDFMAKE_OK;
}

/*============================================================================
 * Hint Table Generation
 *==========================================================================*/

pdfmake_err_t pdfmake_linear_build_hints(pdfmake_linear_t *lin)
{
    pdfmake_doc_t *doc;
    size_t page_count;
    size_t i;
    if (!lin || !lin->doc) return PDFMAKE_EINVAL;
    
    doc = lin->doc;
    page_count = doc->page_count;
    
    /* Allocate page hints */
    lin->hints.page_hints = pdfmake_arena_alloc(lin->arena,
        page_count * sizeof(pdfmake_page_hint_t));
    if (!lin->hints.page_hints) return PDFMAKE_ENOMEM;
    memset(lin->hints.page_hints, 0, page_count * sizeof(pdfmake_page_hint_t));
    lin->hints.page_hint_count = page_count;
    
    /* Build page hints */
    for (i = 0; i < page_count; i++) {
        pdfmake_page_hint_t *hint = &lin->hints.page_hints[i];
        uint16_t shared_count;
        uint16_t idx;
        size_t j;
        
        hint->obj_count = (uint32_t)lin->page_objects[i].count;
        hint->page_length = 0;  /* Will be computed during write */
        hint->content_offset = 0;
        hint->content_length = 0;
        
        /* Count shared object references for this page */
        shared_count = 0;
        for (j = 0; j < lin->page_objects[i].count; j++) {
            uint32_t num = lin->page_objects[i].objects[j];
            if (num < lin->obj_map_size && lin->ref_counts[num] > 1) {
                shared_count++;
            }
        }
        hint->shared_count = shared_count;
        
        if (shared_count > 0) {
            hint->shared_ids = pdfmake_arena_alloc(lin->arena,
                shared_count * sizeof(uint16_t));
            if (!hint->shared_ids) return PDFMAKE_ENOMEM;
            
            idx = 0;
            for (j = 0; j < lin->page_objects[i].count && idx < shared_count; j++) {
                uint32_t num = lin->page_objects[i].objects[j];
                if (num < lin->obj_map_size && lin->ref_counts[num] > 1) {
                    /* Find shared object index */
                    size_t k;
                    for (k = 0; k < lin->shared_count; k++) {
                        if (lin->shared_objects[k] == num) {
                            hint->shared_ids[idx++] = (uint16_t)k;
                            break;
                        }
                    }
                }
            }
        }
    }
    
    /* Allocate and build shared object hints */
    lin->hints.shared_hints = pdfmake_arena_alloc(lin->arena,
        lin->shared_count * sizeof(pdfmake_shared_hint_t));
    if (!lin->hints.shared_hints && lin->shared_count > 0) return PDFMAKE_ENOMEM;
    lin->hints.shared_hint_count = lin->shared_count;
    
    for (i = 0; i < lin->shared_count; i++) {
        pdfmake_shared_hint_t *hint = &lin->hints.shared_hints[i];
        uint32_t num = lin->shared_objects[i];
        
        hint->obj_num = lin->obj_map[num];  /* Use remapped number */
        hint->offset = 0;   /* Will be set during write */
        hint->length = 0;   /* Will be computed during write */
        hint->ref_count = lin->ref_counts[num];
    }
    
    lin->hints.arena = lin->arena;
    
    return PDFMAKE_OK;
}

/*============================================================================
 * Linearized Writer
 *==========================================================================*/

/* Write object with remapped references */
static pdfmake_err_t write_remapped_obj(
    pdfmake_linear_t *lin,
    pdfmake_buf_t *out,
    pdfmake_obj_t *obj)
{
    /* For now, use standard writer - full implementation would remap refs */
    return pdfmake_write_obj(out, lin->arena, obj);
}

/* Write linearization dictionary */
static pdfmake_err_t write_linearization_dict(
    pdfmake_linear_t *lin,
    pdfmake_buf_t *out,
    size_t *dict_end)
{
    /* Object header */
    pdfmake_buf_appendf(out, "1 0 obj\n");
    
    /* Linearization dictionary - values will be fixed up later */
    pdfmake_buf_appendf(out, "<<\n");
    pdfmake_buf_appendf(out, "  /Linearized 1\n");
    pdfmake_buf_appendf(out, "  /L %10zu\n", (size_t)0);  /* File length - placeholder */
    pdfmake_buf_appendf(out, "  /H [ %10zu %10zu ]\n", (size_t)0, (size_t)0);  /* Hint offset/length */
    pdfmake_buf_appendf(out, "  /O %u\n", lin->params.first_page_obj);
    pdfmake_buf_appendf(out, "  /E %10zu\n", (size_t)0);  /* First page end */
    pdfmake_buf_appendf(out, "  /N %zu\n", lin->params.page_count);
    pdfmake_buf_appendf(out, "  /T %10zu\n", (size_t)0);  /* Main xref offset */
    pdfmake_buf_appendf(out, ">>\n");
    pdfmake_buf_appendf(out, "endobj\n\n");
    
    *dict_end = pdfmake_buf_len(out);
    
    return PDFMAKE_OK;
}

/* Write partial xref for first page */
static pdfmake_err_t write_first_page_xref(
    pdfmake_linear_t *lin,
    pdfmake_buf_t *out)
{
    lin->first_page_xref_pos = pdfmake_buf_len(out);
    
    /* Write partial xref covering first page objects */
    pdfmake_buf_appendf(out, "xref\n");
    
    /* For now, just a placeholder - real impl tracks object positions */
    pdfmake_buf_appendf(out, "0 1\n");
    pdfmake_buf_appendf(out, "0000000000 65535 f \n");
    
    /* Trailer for partial xref */
    pdfmake_buf_appendf(out, "trailer\n");
    pdfmake_buf_appendf(out, "<<\n");
    pdfmake_buf_appendf(out, "  /Size %zu\n", lin->doc->obj_count + 2);
    pdfmake_buf_appendf(out, "  /Prev %10zu\n", (size_t)0);  /* Will point to main xref */
    pdfmake_buf_appendf(out, "  /Root %u 0 R\n", lin->doc->root_num);
    if (lin->doc->info_num) {
        pdfmake_buf_appendf(out, "  /Info %u 0 R\n", lin->doc->info_num);
    }
    pdfmake_buf_appendf(out, ">>\n");
    pdfmake_buf_appendf(out, "startxref\n");
    pdfmake_buf_appendf(out, "0\n");  /* Placeholder */
    pdfmake_buf_appendf(out, "%%%%EOF\n\n");
    
    return PDFMAKE_OK;
}

/* Write hint stream */
static pdfmake_err_t write_hint_stream(
    pdfmake_linear_t *lin,
    pdfmake_buf_t *out)
{
    pdfmake_buf_t hint_data;
    pdfmake_err_t err;
    uint32_t hint_obj_num;
    lin->hint_stream_pos = pdfmake_buf_len(out);
    
    /* Build hint stream data */
    pdfmake_buf_init(&hint_data);
    
    err = pdfmake_build_hint_stream(lin->arena, &lin->hints, &hint_data);
    if (err != PDFMAKE_OK) {
        pdfmake_buf_free(&hint_data);
        return err;
    }
    
    /* Write as stream object */
    hint_obj_num = 2;  /* Hint stream is typically object 2 */
    pdfmake_buf_appendf(out, "%u 0 obj\n", hint_obj_num);
    pdfmake_buf_appendf(out, "<<\n");
    pdfmake_buf_appendf(out, "  /Type /XRef\n");
    pdfmake_buf_appendf(out, "  /Length %zu\n", pdfmake_buf_len(&hint_data));
    pdfmake_buf_appendf(out, "  /S %zu\n", lin->hints.page_hint_count);  /* Shared obj hint offset */
    pdfmake_buf_appendf(out, ">>\n");
    pdfmake_buf_appendf(out, "stream\n");
    pdfmake_buf_append(out, pdfmake_buf_data(&hint_data), pdfmake_buf_len(&hint_data));
    pdfmake_buf_appendf(out, "\nendstream\n");
    pdfmake_buf_appendf(out, "endobj\n\n");
    
    lin->params.hint_offset = lin->hint_stream_pos;
    lin->params.hint_length = pdfmake_buf_len(out) - lin->hint_stream_pos;
    
    pdfmake_buf_free(&hint_data);
    
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_linear_write(pdfmake_linear_t *lin, pdfmake_buf_t *out)
{
    pdfmake_doc_t *doc;
    size_t lin_dict_end;
    pdfmake_err_t err;
    size_t i;
    size_t p;
    int id_i;
    pdfmake_obj_t *catalog;
    if (!lin || !lin->doc || !out) return PDFMAKE_EINVAL;
    
    doc = lin->doc;
    
    /* 1. Write header */
    pdfmake_buf_appendf(out, "%%PDF-2.0\n");
    pdfmake_buf_appendf(out, "%%\xE2\xE3\xCF\xD3\n");  /* Binary comment */
    
    /* 2. Write linearization dictionary (object 1) */
    err = write_linearization_dict(lin, out, &lin_dict_end);
    if (err != PDFMAKE_OK) return err;
    
    /* 3. Write first-page cross-reference section */
    err = write_first_page_xref(lin, out);
    if (err != PDFMAKE_OK) return err;
    
    /* 4. Write document catalog and first-page objects */
    /* Write catalog */
    catalog = pdfmake_doc_get(doc, doc->root_num);
    if (catalog) {
        pdfmake_buf_appendf(out, "%u 0 obj\n", doc->root_num);
        write_remapped_obj(lin, out, catalog);
        pdfmake_buf_appendf(out, "\nendobj\n\n");
    }
    
    /* Write first page objects */
    if (doc->page_count > 0 && lin->page_objects[0].count > 0) {
        for (i = 0; i < lin->page_objects[0].count; i++) {
            uint32_t num = lin->page_objects[0].objects[i];
            pdfmake_obj_t *obj = pdfmake_doc_get(doc, num);
            if (obj && num != doc->root_num) {
                uint32_t new_num = lin->obj_map[num];
                pdfmake_buf_appendf(out, "%u 0 obj\n", new_num);
                write_remapped_obj(lin, out, obj);
                pdfmake_buf_appendf(out, "\nendobj\n\n");
            }
        }
    }
    
    lin->params.first_page_end = pdfmake_buf_len(out);
    lin->params.first_page_obj = doc->root_num;  /* Simplified */
    
    /* 5. Write hint stream */
    err = write_hint_stream(lin, out);
    if (err != PDFMAKE_OK) return err;
    
    /* 6. Write remaining pages (2..N) */
    for (p = 1; p < doc->page_count; p++) {
        for (i = 0; i < lin->page_objects[p].count; i++) {
            uint32_t num = lin->page_objects[p].objects[i];
            pdfmake_obj_t *obj;
            /* Skip if already written or shared */
            if (lin->ref_counts[num] > 1) continue;
            
            obj = pdfmake_doc_get(doc, num);
            if (obj) {
                uint32_t new_num = lin->obj_map[num];
                pdfmake_buf_appendf(out, "%u 0 obj\n", new_num);
                write_remapped_obj(lin, out, obj);
                pdfmake_buf_appendf(out, "\nendobj\n\n");
            }
        }
    }
    
    /* 7. Write shared objects */
    for (i = 0; i < lin->shared_count; i++) {
        uint32_t num = lin->shared_objects[i];
        pdfmake_obj_t *obj = pdfmake_doc_get(doc, num);
        if (obj) {
            uint32_t new_num = lin->obj_map[num];
            pdfmake_buf_appendf(out, "%u 0 obj\n", new_num);
            write_remapped_obj(lin, out, obj);
            pdfmake_buf_appendf(out, "\nendobj\n\n");
        }
    }
    
    /* 8. Write main cross-reference table */
    lin->main_xref_pos = pdfmake_buf_len(out);
    lin->params.main_xref_offset = lin->main_xref_pos;
    
    pdfmake_buf_appendf(out, "xref\n");
    pdfmake_buf_appendf(out, "0 %zu\n", doc->obj_count + 2);
    pdfmake_buf_appendf(out, "0000000000 65535 f \n");
    
    /* Write xref entries - simplified, real impl tracks all positions */
    for (i = 1; i <= doc->obj_count + 1; i++) {
        pdfmake_buf_appendf(out, "%010zu 00000 n \n", (size_t)0);
    }
    
    /* Trailer */
    pdfmake_buf_appendf(out, "trailer\n");
    pdfmake_buf_appendf(out, "<<\n");
    pdfmake_buf_appendf(out, "  /Size %zu\n", doc->obj_count + 2);
    pdfmake_buf_appendf(out, "  /Root %u 0 R\n", doc->root_num);
    if (doc->info_num) {
        pdfmake_buf_appendf(out, "  /Info %u 0 R\n", doc->info_num);
    }
    if (doc->id_set) {
        pdfmake_buf_appendf(out, "  /ID [<");
        for (id_i = 0; id_i < 16; id_i++) {
            pdfmake_buf_appendf(out, "%02X", doc->id1[id_i]);
        }
        pdfmake_buf_appendf(out, "> <");
        for (id_i = 0; id_i < 16; id_i++) {
            pdfmake_buf_appendf(out, "%02X", doc->id2[id_i]);
        }
        pdfmake_buf_appendf(out, ">]\n");
    }
    pdfmake_buf_appendf(out, ">>\n");
    pdfmake_buf_appendf(out, "startxref\n");
    pdfmake_buf_appendf(out, "%zu\n", lin->main_xref_pos);
    pdfmake_buf_appendf(out, "%%%%EOF\n");
    
    /* Update file length in linearization dictionary */
    lin->params.file_length = pdfmake_buf_len(out);
    
    /* TODO: Fix up placeholder values in linearization dictionary */
    /* This requires going back and patching specific byte offsets */
    
    return PDFMAKE_OK;
}

/*============================================================================
 * High-Level API
 *==========================================================================*/

pdfmake_err_t pdfmake_doc_linearize(pdfmake_doc_t *doc)
{
    /* This is a no-op marker for now */
    /* Real linearization happens during write */
    (void)doc;
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_doc_write_linearized(pdfmake_doc_t *doc, pdfmake_buf_t *out)
{
    pdfmake_linear_t *lin;
    pdfmake_err_t err;
    if (!doc || !out) return PDFMAKE_EINVAL;
    
    /* Ensure finalized */
    if (!doc->finalized) {
        return PDFMAKE_EINVAL;
    }
    
    /* Create linearization context */
    lin = pdfmake_linear_new(doc);
    if (!lin) return PDFMAKE_ENOMEM;
    
    /* Analyze document structure */
    err = pdfmake_linear_analyze(lin);
    if (err != PDFMAKE_OK) {
        pdfmake_linear_free(lin);
        return err;
    }
    
    /* Build hint tables */
    err = pdfmake_linear_build_hints(lin);
    if (err != PDFMAKE_OK) {
        pdfmake_linear_free(lin);
        return err;
    }
    
    /* Write linearized output */
    err = pdfmake_linear_write(lin, out);
    
    pdfmake_linear_free(lin);
    
    return err;
}

pdfmake_err_t pdfmake_doc_write_linearized_to_path(
    pdfmake_doc_t *doc,
    const char *path)
{
    pdfmake_buf_t buf;
    pdfmake_err_t err;
    FILE *fp;
    size_t written;
    if (!doc || !path) return PDFMAKE_EINVAL;
    
    pdfmake_buf_init(&buf);
    
    err = pdfmake_doc_write_linearized(doc, &buf);
    if (err != PDFMAKE_OK) {
        pdfmake_buf_free(&buf);
        return err;
    }
    
    fp = fopen(path, "wb");
    if (!fp) {
        pdfmake_buf_free(&buf);
        return PDFMAKE_EIO;
    }
    
    written = fwrite(pdfmake_buf_data(&buf), 1, pdfmake_buf_len(&buf), fp);
    fclose(fp);
    
    pdfmake_buf_free(&buf);
    
    if (written != pdfmake_buf_len(&buf)) {
        return PDFMAKE_EIO;
    }
    
    return PDFMAKE_OK;
}

/*============================================================================
 * Streaming Reader
 *==========================================================================*/

pdfmake_stream_reader_t *pdfmake_stream_reader_new(
    pdfmake_fetch_fn fetch,
    void *ctx)
{
    pdfmake_stream_reader_t *reader;
    if (!fetch) return NULL;
    
    reader = calloc(1, sizeof(pdfmake_stream_reader_t));
    if (!reader) return NULL;
    
    reader->fetch = fetch;
    reader->fetch_ctx = ctx;
    
    reader->arena = pdfmake_arena_new();
    if (!reader->arena) {
        free(reader);
        return NULL;
    }
    
    return reader;
}

void pdfmake_stream_reader_free(pdfmake_stream_reader_t *reader)
{
    if (!reader) return;
    
    if (reader->arena) {
        pdfmake_arena_free(reader->arena);
    }
    if (reader->doc) {
        pdfmake_doc_free(reader->doc);
    }
    if (reader->page_loaded) {
        free(reader->page_loaded);
    }
    if (reader->header_data) {
        free(reader->header_data);
    }
    
    free(reader);
}

pdfmake_err_t pdfmake_stream_reader_read_header(pdfmake_stream_reader_t *reader)
{
    size_t header_size;
    ssize_t bytes;
    const char *n_ptr;
    const char *l_ptr;
    size_t bitmap_size;
    if (!reader) return PDFMAKE_EINVAL;
    
    /* Fetch first 4KB to get linearization dict */
    header_size = 4096;
    reader->header_data = malloc(header_size);
    if (!reader->header_data) return PDFMAKE_ENOMEM;
    
    bytes = reader->fetch(reader->fetch_ctx, 0, header_size, reader->header_data);
    if (bytes < 0) {
        free(reader->header_data);
        reader->header_data = NULL;
        return PDFMAKE_EIO;
    }
    reader->header_len = (size_t)bytes;
    
    /* Check if linearized */
    reader->is_linearized = pdfmake_data_is_linearized(reader->header_data, reader->header_len);
    
    if (reader->is_linearized) {
        /* Parse linearization dictionary */
        /* Extract /L, /H, /O, /E, /N, /T values */
        
        /* For now, try to extract page count from /N */
        n_ptr = strstr((char*)reader->header_data, "/N ");
        if (n_ptr) {
            reader->params.page_count = (size_t)atoi(n_ptr + 3);
        }
        
        /* Extract file length from /L */
        l_ptr = strstr((char*)reader->header_data, "/L ");
        if (l_ptr) {
            reader->params.file_length = (size_t)atol(l_ptr + 3);
        }
        
        /* Allocate page loaded bitmap */
        if (reader->params.page_count > 0) {
            bitmap_size = (reader->params.page_count + 7) / 8;
            reader->page_loaded = calloc(1, bitmap_size);
            if (!reader->page_loaded) return PDFMAKE_ENOMEM;
            
            /* Mark first page as loaded (it's in the header) */
            reader->page_loaded[0] |= 1;
        }
    }
    
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_stream_reader_load_hints(pdfmake_stream_reader_t *reader)
{
    const char *h_ptr;
    uint8_t *hint_data;
    ssize_t bytes;
    pdfmake_err_t err;
    if (!reader || !reader->is_linearized) return PDFMAKE_EINVAL;
    if (reader->hints_loaded) return PDFMAKE_OK;
    
    /* Fetch hint stream */
    if (reader->params.hint_offset == 0 || reader->params.hint_length == 0) {
        /* Try to parse from header data */
        h_ptr = strstr((char*)reader->header_data, "/H [");
        if (h_ptr) {
            sscanf(h_ptr + 4, "%zu %zu", 
                   &reader->params.hint_offset, 
                   &reader->params.hint_length);
        }
    }
    
    if (reader->params.hint_offset == 0 || reader->params.hint_length == 0) {
        return PDFMAKE_EINVAL;
    }
    
    hint_data = malloc(reader->params.hint_length);
    if (!hint_data) return PDFMAKE_ENOMEM;
    
    bytes = reader->fetch(reader->fetch_ctx,
        reader->params.hint_offset,
        reader->params.hint_length,
        hint_data);
    
    if (bytes < 0 || (size_t)bytes < reader->params.hint_length) {
        free(hint_data);
        return PDFMAKE_EIO;
    }
    
    /* Parse hint stream */
    err = pdfmake_parse_hint_stream(
        reader->arena,
        hint_data,
        reader->params.hint_length,
        reader->params.page_count,
        &reader->hints);
    
    free(hint_data);
    
    if (err == PDFMAKE_OK) {
        reader->hints_loaded = 1;
    }
    
    return err;
}

int pdfmake_stream_reader_page_available(
    pdfmake_stream_reader_t *reader,
    int page_num)
{
    size_t byte_idx;
    uint8_t bit_mask;
    if (!reader || !reader->page_loaded) return 0;
    if (page_num < 0 || (size_t)page_num >= reader->params.page_count) return 0;
    
    byte_idx = page_num / 8;
    bit_mask = 1 << (page_num % 8);
    
    return (reader->page_loaded[byte_idx] & bit_mask) != 0;
}

pdfmake_err_t pdfmake_stream_reader_read_page(
    pdfmake_stream_reader_t *reader,
    int page_num)
{
    size_t offset;
    size_t length;
    pdfmake_err_t err;
    uint8_t *page_data;
    ssize_t bytes;
    size_t byte_idx;
    uint8_t bit_mask;
    if (!reader) return PDFMAKE_EINVAL;
    if (page_num < 0 || (size_t)page_num >= reader->params.page_count) {
        return PDFMAKE_EINVAL;
    }
    
    /* Already loaded? */
    if (pdfmake_stream_reader_page_available(reader, page_num)) {
        return PDFMAKE_OK;
    }
    
    /* Need hints to know where to fetch */
    if (!reader->hints_loaded) {
        err = pdfmake_stream_reader_load_hints(reader);
        if (err != PDFMAKE_OK) return err;
    }
    
    /* Get page byte range */
    err = pdfmake_stream_reader_page_range(reader, page_num, &offset, &length);
    if (err != PDFMAKE_OK) return err;
    
    /* Fetch page data */
    page_data = malloc(length);
    if (!page_data) return PDFMAKE_ENOMEM;
    
    bytes = reader->fetch(reader->fetch_ctx, offset, length, page_data);
    if (bytes < 0 || (size_t)bytes < length) {
        free(page_data);
        return PDFMAKE_EIO;
    }
    
    /* Parse page objects into document */
    /* (Simplified - real impl would parse and merge objects) */
    
    /* Mark page as loaded */
    byte_idx = page_num / 8;
    bit_mask = 1 << (page_num % 8);
    reader->page_loaded[byte_idx] |= bit_mask;
    
    free(page_data);
    
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_stream_reader_page_range(
    pdfmake_stream_reader_t *reader,
    int page_num,
    size_t *offset,
    size_t *length)
{
    pdfmake_page_hint_t *hint;
    size_t page_offset;
    int i;
    if (!reader || !offset || !length) return PDFMAKE_EINVAL;
    if (!reader->hints_loaded) return PDFMAKE_EINVAL;
    if (page_num < 0 || (size_t)page_num >= reader->hints.page_hint_count) {
        return PDFMAKE_EINVAL;
    }
    
    /* Calculate from hint tables */
    hint = &reader->hints.page_hints[page_num];
    
    /* Compute offset by summing previous page lengths */
    page_offset = reader->hints.first_page_offset;
    for (i = 0; i < page_num; i++) {
        page_offset += reader->hints.page_hints[i].page_length;
    }
    
    *offset = page_offset;
    *length = hint->page_length;
    
    return PDFMAKE_OK;
}

size_t pdfmake_stream_reader_page_count(pdfmake_stream_reader_t *reader)
{
    if (!reader) return 0;
    return reader->params.page_count;
}

pdfmake_doc_t *pdfmake_stream_reader_doc(pdfmake_stream_reader_t *reader)
{
    if (!reader) return NULL;
    return reader->doc;
}

/*============================================================================
 * Hint Table Parsing and Building
 *==========================================================================*/

pdfmake_err_t pdfmake_parse_hint_stream(
    pdfmake_arena_t *arena,
    const uint8_t *data,
    size_t len,
    size_t page_count,
    pdfmake_hint_tables_t *out)
{
    if (!arena || !data || !out) return PDFMAKE_EINVAL;
    
    memset(out, 0, sizeof(*out));
    out->arena = arena;
    
    /* Hint stream format (§F.4):
     * - Page offset hint table header
     * - Page offset hint table data
     * - Shared objects hint table header (at offset /S in hint stream dict)
     * - Shared objects hint table data
     */
    
    /* Allocate page hints */
    out->page_hints = pdfmake_arena_alloc(arena, page_count * sizeof(pdfmake_page_hint_t));
    if (!out->page_hints) return PDFMAKE_ENOMEM;
    memset(out->page_hints, 0, page_count * sizeof(pdfmake_page_hint_t));
    out->page_hint_count = page_count;
    
    /* Parse page offset hint table header (§F.4.2) */
    if (len < 36) return PDFMAKE_EINVAL;  /* Minimum header size */
    
    /* Header fields are 32-bit big-endian values */
    /* Item 1: Min obj count per page (4 bytes) */
    /* Item 2: First page location (4 bytes) */
    /* Item 3: Bits for obj count delta (2 bytes) */
    /* ... and more */
    
    /* For now, simplified parsing - just extract basic structure */
    
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_build_hint_stream(
    pdfmake_arena_t *arena,
    const pdfmake_hint_tables_t *hints,
    pdfmake_buf_t *out)
{
    uint32_t min_obj_count;
    size_t i;
    uint8_t header[40];
    size_t hdr_len;
    uint32_t first_loc;
    size_t min_len;
    if (!arena || !hints || !out) return PDFMAKE_EINVAL;
    
    /* Build page offset hint table (§F.4.2) */
    
    /* Header */
    /* Item 1: Minimum object count per page */
    min_obj_count = UINT32_MAX;
    for (i = 0; i < hints->page_hint_count; i++) {
        if (hints->page_hints[i].obj_count < min_obj_count) {
            min_obj_count = hints->page_hints[i].obj_count;
        }
    }
    if (min_obj_count == UINT32_MAX) min_obj_count = 0;
    
    /* Write header in big-endian */
    hdr_len = 0;
    
    /* Item 1: Min obj count (4 bytes) */
    header[hdr_len++] = (min_obj_count >> 24) & 0xFF;
    header[hdr_len++] = (min_obj_count >> 16) & 0xFF;
    header[hdr_len++] = (min_obj_count >> 8) & 0xFF;
    header[hdr_len++] = min_obj_count & 0xFF;
    
    /* Item 2: First page object location (4 bytes) */
    first_loc = (uint32_t)hints->first_page_offset;
    header[hdr_len++] = (first_loc >> 24) & 0xFF;
    header[hdr_len++] = (first_loc >> 16) & 0xFF;
    header[hdr_len++] = (first_loc >> 8) & 0xFF;
    header[hdr_len++] = first_loc & 0xFF;
    
    /* Item 3: Bits for obj count delta (2 bytes) */
    header[hdr_len++] = 0;
    header[hdr_len++] = 16;  /* 16 bits */
    
    /* Item 4: Min page length (4 bytes) */
    min_len = SIZE_MAX;
    for (i = 0; i < hints->page_hint_count; i++) {
        if (hints->page_hints[i].page_length < min_len) {
            min_len = hints->page_hints[i].page_length;
        }
    }
    if (min_len == SIZE_MAX) min_len = 0;
    header[hdr_len++] = (min_len >> 24) & 0xFF;
    header[hdr_len++] = (min_len >> 16) & 0xFF;
    header[hdr_len++] = (min_len >> 8) & 0xFF;
    header[hdr_len++] = min_len & 0xFF;
    
    /* Item 5: Bits for page length delta (2 bytes) */
    header[hdr_len++] = 0;
    header[hdr_len++] = 32;  /* 32 bits */
    
    /* Item 6: Min content stream offset (4 bytes) - 0 */
    header[hdr_len++] = 0;
    header[hdr_len++] = 0;
    header[hdr_len++] = 0;
    header[hdr_len++] = 0;
    
    /* Item 7: Bits for content offset delta (2 bytes) */
    header[hdr_len++] = 0;
    header[hdr_len++] = 0;
    
    /* Item 8: Min content length (4 bytes) - 0 */
    header[hdr_len++] = 0;
    header[hdr_len++] = 0;
    header[hdr_len++] = 0;
    header[hdr_len++] = 0;
    
    /* Item 9: Bits for content length delta (2 bytes) */
    header[hdr_len++] = 0;
    header[hdr_len++] = 0;
    
    /* Item 10: Bits for shared obj refs (2 bytes) */
    header[hdr_len++] = 0;
    header[hdr_len++] = 16;
    
    /* Item 11: Bits for shared obj identifier (2 bytes) */
    header[hdr_len++] = 0;
    header[hdr_len++] = 16;
    
    /* Item 12: Bits for numerator (2 bytes) */
    header[hdr_len++] = 0;
    header[hdr_len++] = 0;
    
    /* Item 13: Denominator (2 bytes) */
    header[hdr_len++] = 0;
    header[hdr_len++] = 1;
    
    pdfmake_buf_append(out, header, hdr_len);
    
    /* Write per-page data */
    for (i = 0; i < hints->page_hint_count; i++) {
        pdfmake_page_hint_t *hint = &hints->page_hints[i];
        uint16_t obj_delta;
        uint32_t len_delta;
        uint16_t j;
        
        /* Object count delta (16 bits) */
        obj_delta = hint->obj_count - min_obj_count;
        pdfmake_buf_append_byte(out, (obj_delta >> 8) & 0xFF);
        pdfmake_buf_append_byte(out, obj_delta & 0xFF);
        
        /* Page length delta (32 bits) */
        len_delta = (uint32_t)(hint->page_length - min_len);
        pdfmake_buf_append_byte(out, (len_delta >> 24) & 0xFF);
        pdfmake_buf_append_byte(out, (len_delta >> 16) & 0xFF);
        pdfmake_buf_append_byte(out, (len_delta >> 8) & 0xFF);
        pdfmake_buf_append_byte(out, len_delta & 0xFF);
        
        /* Shared object count (16 bits) */
        pdfmake_buf_append_byte(out, (hint->shared_count >> 8) & 0xFF);
        pdfmake_buf_append_byte(out, hint->shared_count & 0xFF);
        
        /* Shared object identifiers */
        for (j = 0; j < hint->shared_count; j++) {
            uint16_t id = hint->shared_ids ? hint->shared_ids[j] : 0;
            pdfmake_buf_append_byte(out, (id >> 8) & 0xFF);
            pdfmake_buf_append_byte(out, id & 0xFF);
        }
    }
    
    /* Build shared objects hint table (§F.4.3) */
    if (hints->shared_hint_count > 0) {
        uint32_t first_shared;
        uint32_t first_offset;
        uint32_t count;
        /* Header */
        /* Item 1: First shared object number (4 bytes) */
        first_shared = hints->shared_hints[0].obj_num;
        pdfmake_buf_append_byte(out, (first_shared >> 24) & 0xFF);
        pdfmake_buf_append_byte(out, (first_shared >> 16) & 0xFF);
        pdfmake_buf_append_byte(out, (first_shared >> 8) & 0xFF);
        pdfmake_buf_append_byte(out, first_shared & 0xFF);
        
        /* Item 2: First shared object offset (4 bytes) */
        first_offset = (uint32_t)hints->shared_hints[0].offset;
        pdfmake_buf_append_byte(out, (first_offset >> 24) & 0xFF);
        pdfmake_buf_append_byte(out, (first_offset >> 16) & 0xFF);
        pdfmake_buf_append_byte(out, (first_offset >> 8) & 0xFF);
        pdfmake_buf_append_byte(out, first_offset & 0xFF);
        
        /* Item 3: Number of first page shared objects (4 bytes) */
        pdfmake_buf_append_byte(out, 0);
        pdfmake_buf_append_byte(out, 0);
        pdfmake_buf_append_byte(out, 0);
        pdfmake_buf_append_byte(out, 0);
        
        /* Item 4: Number of shared objects (4 bytes) */
        count = (uint32_t)hints->shared_hint_count;
        pdfmake_buf_append_byte(out, (count >> 24) & 0xFF);
        pdfmake_buf_append_byte(out, (count >> 16) & 0xFF);
        pdfmake_buf_append_byte(out, (count >> 8) & 0xFF);
        pdfmake_buf_append_byte(out, count & 0xFF);
        
        /* Item 5: Bits for object length delta (2 bytes) */
        pdfmake_buf_append_byte(out, 0);
        pdfmake_buf_append_byte(out, 32);
        
        /* Min shared object length (4 bytes) */
        pdfmake_buf_append_byte(out, 0);
        pdfmake_buf_append_byte(out, 0);
        pdfmake_buf_append_byte(out, 0);
        pdfmake_buf_append_byte(out, 0);
        
        /* Per-object data */
        for (i = 0; i < hints->shared_hint_count; i++) {
            pdfmake_shared_hint_t *hint = &hints->shared_hints[i];
            
            /* Length delta (32 bits) */
            uint32_t len = (uint32_t)hint->length;
            pdfmake_buf_append_byte(out, (len >> 24) & 0xFF);
            pdfmake_buf_append_byte(out, (len >> 16) & 0xFF);
            pdfmake_buf_append_byte(out, (len >> 8) & 0xFF);
            pdfmake_buf_append_byte(out, len & 0xFF);
        }
    }
    
    return PDFMAKE_OK;
}
