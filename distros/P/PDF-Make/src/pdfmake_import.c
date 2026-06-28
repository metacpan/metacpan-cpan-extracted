/*
 * pdfmake_import.c — Cross-document object/page import.
 *
 * See include/pdfmake_import.h for the public API and design notes.
 */

#include "pdfmake_import.h"
#include "pdfmake_arena.h"
#include "pdfmake_page.h"
#include "pdfmake_buf.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/*============================================================================
 * Import context
 *==========================================================================*/

struct pdfmake_import_ctx {
    pdfmake_reader_t *src_reader;
    pdfmake_parser_t *src_parser;
    pdfmake_arena_t  *src_arena;
    pdfmake_doc_t    *dst;
    pdfmake_arena_t  *dst_arena;

    /* Remap table: src_num -> dst_num (0 means not yet imported).
     * Sized at src_parser->xref_size. */
    uint32_t         *remap;
    size_t            remap_size;
};

pdfmake_import_ctx_t *pdfmake_import_ctx_new(pdfmake_reader_t *src_reader,
                                              pdfmake_doc_t *dst) {
    pdfmake_import_ctx_t *ctx;

    if (!src_reader || !dst) return NULL;
    if (!src_reader->parser) return NULL;

    ctx = calloc(1, sizeof(*ctx));
    if (!ctx) return NULL;

    ctx->src_reader = src_reader;
    ctx->src_parser = src_reader->parser;
    ctx->src_arena  = src_reader->parser->doc->arena;
    ctx->dst        = dst;
    ctx->dst_arena  = pdfmake_doc_arena(dst);

    ctx->remap_size = ctx->src_parser->xref_size + 1;
    ctx->remap = calloc(ctx->remap_size, sizeof(uint32_t));
    if (!ctx->remap) {
        free(ctx);
        return NULL;
    }

    return ctx;
}

void pdfmake_import_ctx_free(pdfmake_import_ctx_t *ctx) {
    if (!ctx) return;
    free(ctx->remap);
    free(ctx);
}

/*============================================================================
 * Object deep-copy (walks composite graph)
 *==========================================================================*/

static pdfmake_obj_t import_obj(pdfmake_import_ctx_t *ctx, pdfmake_obj_t src);

/* Forward decl — streams reached via a ref need the src object number so
 * we can decrypt their bytes through the reader. */
static pdfmake_obj_t import_stream_with_decrypt(pdfmake_import_ctx_t *ctx,
                                                 pdfmake_obj_t src,
                                                 uint32_t src_num);

/* Import an indirect src_num → dst_num.  Handles cycles via remap slot.
 * Returns 0 on failure. */
static uint32_t import_ref_num(pdfmake_import_ctx_t *ctx, uint32_t src_num) {
    pdfmake_ref_t r;
    pdfmake_obj_t *src_obj;
    uint32_t dst_num;
    pdfmake_obj_t dst_obj;

    if (src_num == 0 || src_num >= ctx->remap_size) return 0;
    if (ctx->remap[src_num] != 0) return ctx->remap[src_num];

    r.num = src_num;
    r.gen = 0;
    src_obj = pdfmake_parser_resolve(ctx->src_parser, r);
    if (!src_obj) return 0;

    /* Reserve the dst slot before recursing so cycles terminate. */
    dst_num = pdfmake_doc_add(ctx->dst, pdfmake_null());
    if (dst_num == 0) return 0;
    ctx->remap[src_num] = dst_num;

    /* Streams carry the encryption state of the source file — decrypt them
     * through the reader before copying so the destination stays readable
     * when the source was encrypted.  Non-stream objects (names, numbers,
     * plain dicts) aren't per-object encrypted and import cleanly. */
    if (src_obj->kind == PDFMAKE_STREAM) {
        dst_obj = import_stream_with_decrypt(ctx, *src_obj, src_num);
    } else {
        dst_obj = import_obj(ctx, *src_obj);
    }

    /* Overwrite the reserved slot with the real imported object. */
    ctx->dst->objects[dst_num - 1].obj = dst_obj;

    return dst_num;
}

static pdfmake_obj_t import_name(pdfmake_import_ctx_t *ctx, pdfmake_obj_t src) {
    const char *bytes;
    size_t      len;
    uint32_t    new_id;
    pdfmake_obj_t out;

    bytes = pdfmake_arena_name_bytes(ctx->src_arena, src.as.name.id);
    len   = pdfmake_arena_name_len  (ctx->src_arena, src.as.name.id);
    if (!bytes) return pdfmake_null();
    new_id = pdfmake_arena_intern_name(ctx->dst_arena, bytes, len);
    out.kind = PDFMAKE_NAME;
    out.as.name.id = new_id;
    return out;
}

static pdfmake_obj_t import_string(pdfmake_import_ctx_t *ctx, pdfmake_obj_t src) {
    void *copy;
    pdfmake_obj_t out;

    copy = pdfmake_arena_memdup(ctx->dst_arena, src.as.str.bytes, src.as.str.len);
    if (!copy && src.as.str.len > 0) return pdfmake_null();
    out.kind = PDFMAKE_STR;
    out.as.str.bytes = (const uint8_t *)copy;
    out.as.str.len   = src.as.str.len;
    out.as.str.hex   = src.as.str.hex;
    return out;
}

static pdfmake_obj_t import_array(pdfmake_import_ctx_t *ctx, pdfmake_obj_t src) {
    pdfmake_obj_t out;
    uint32_t i;
    pdfmake_obj_t elem;

    out = pdfmake_array_new(ctx->dst_arena);
    if (out.kind != PDFMAKE_ARRAY || !src.as.arr) return out;
    for (i = 0; i < src.as.arr->len; i++) {
        elem = import_obj(ctx, src.as.arr->items[i]);
        if (!pdfmake_array_push(ctx->dst_arena, &out, elem)) break;
    }
    return out;
}

static pdfmake_obj_t import_dict(pdfmake_import_ctx_t *ctx, pdfmake_obj_t src) {
    pdfmake_obj_t out;
    pdfmake_dict_iter_t it;
    const char *kb;
    size_t      kl;
    uint32_t    new_key;
    pdfmake_obj_t new_val;

    out = pdfmake_dict_new(ctx->dst_arena);
    if (out.kind != PDFMAKE_DICT) return out;

    pdfmake_dict_iter_init(&it, &src);
    while (pdfmake_dict_iter_next(&it)) {
        kb = pdfmake_arena_name_bytes(ctx->src_arena, it.current_key);
        kl = pdfmake_arena_name_len  (ctx->src_arena, it.current_key);
        if (!kb) continue;
        new_key = pdfmake_arena_intern_name(ctx->dst_arena, kb, kl);
        if (new_key == 0) continue;
        new_val = import_obj(ctx, *it.current_value);
        pdfmake_dict_set(ctx->dst_arena, &out, new_key, new_val);
    }
    return out;
}

/* Copy a stream verbatim without touching encryption state.  Used for
 * streams that weren't reached through a ref (no src_num available).
 * Bytes already passed through the parser → in raw form (possibly
 * encrypted).  The caller is responsible for pairing this with an
 * unencrypted destination or ensuring the source wasn't encrypted. */
static pdfmake_obj_t import_stream(pdfmake_import_ctx_t *ctx, pdfmake_obj_t src) {
    pdfmake_obj_t out;
    pdfmake_obj_t src_dict_obj;
    pdfmake_obj_t new_dict_obj;
    void *copy;

    out = pdfmake_stream_new(ctx->dst_arena);
    if (out.kind != PDFMAKE_STREAM || !src.as.stream) return out;

    src_dict_obj.kind = PDFMAKE_DICT;
    src_dict_obj.as.dict = src.as.stream->dict;
    new_dict_obj = import_dict(ctx, src_dict_obj);
    out.as.stream->dict = new_dict_obj.as.dict;

    if (src.as.stream->raw && src.as.stream->raw_len > 0) {
        copy = pdfmake_arena_memdup(ctx->dst_arena,
                                    src.as.stream->raw,
                                    src.as.stream->raw_len);
        out.as.stream->raw     = (const uint8_t *)copy;
        out.as.stream->raw_len = src.as.stream->raw_len;
    }
    out.as.stream->filtered = 1;

    return out;
}

/* Import a stream by src object number.  When the source document is
 * encrypted we fetch fully decoded (decrypt + decompress) bytes through
 * the reader and store them raw in the destination — dropping /Filter,
 * /DecodeParms, and /Length from the dict so the writer emits the
 * plain-text bytes with a fresh /Length it will compute at write time.
 *
 * The trade-off is file-size: stored uncompressed rather than re-applying
 * /Filter.  For a typical encrypted document this is fine; callers who
 * care can FlateDecode the whole output by emitting with compression
 * enabled on the destination. */
static pdfmake_obj_t import_stream_with_decrypt(pdfmake_import_ctx_t *ctx,
                                                 pdfmake_obj_t src,
                                                 uint32_t src_num)
{
    pdfmake_buf_t decoded;
    pdfmake_err_t err;
    pdfmake_obj_t out;
    pdfmake_obj_t src_dict_obj;
    pdfmake_obj_t new_dict_obj;
    uint32_t filter_key;
    uint32_t parms_key;
    uint32_t length_key;
    pdfmake_obj_t dict_wrapper;
    void *copy;

    /* Fast path: no encryption → plain verbatim copy. */
    if (!ctx->src_reader ||
        !ctx->src_reader->crypt ||
        !ctx->src_reader->authenticated) {
        return import_stream(ctx, src);
    }

    /* Fetch decoded bytes through the reader (decrypt + filter chain). */
    pdfmake_buf_init(&decoded);
    err = pdfmake_reader_resolve_stream(
        ctx->src_reader, src_num, 0, &decoded);

    /* On failure fall back to verbatim copy so the document still imports
     * (readers may show the image as broken, but the page structure is
     * preserved). */
    if (err != PDFMAKE_OK) {
        pdfmake_buf_free(&decoded);
        return import_stream(ctx, src);
    }

    /* Build the destination stream: deep-copy the dict, strip /Filter +
     * /DecodeParms + /Length, then store the decoded bytes with
     * filtered=1 so the writer emits them verbatim (and writes a fresh
     * /Length).  */
    out = pdfmake_stream_new(ctx->dst_arena);
    if (out.kind != PDFMAKE_STREAM) {
        pdfmake_buf_free(&decoded);
        return out;
    }

    src_dict_obj.kind = PDFMAKE_DICT;
    src_dict_obj.as.dict = src.as.stream->dict;
    new_dict_obj = import_dict(ctx, src_dict_obj);
    out.as.stream->dict = new_dict_obj.as.dict;

    /* Drop filter-related entries so readers don't try to decode the
     * already-plain bytes. */
    filter_key = pdfmake_arena_intern_name(ctx->dst_arena, "Filter", 6);
    parms_key  = pdfmake_arena_intern_name(ctx->dst_arena, "DecodeParms", 11);
    length_key = pdfmake_arena_intern_name(ctx->dst_arena, "Length", 6);
    dict_wrapper.kind = PDFMAKE_DICT;
    dict_wrapper.as.dict = out.as.stream->dict;
    pdfmake_dict_del(&dict_wrapper, filter_key);
    pdfmake_dict_del(&dict_wrapper, parms_key);
    pdfmake_dict_del(&dict_wrapper, length_key);

    /* Copy decoded bytes into the destination arena. */
    if (decoded.len > 0) {
        copy = pdfmake_arena_memdup(ctx->dst_arena,
                                    decoded.data, decoded.len);
        out.as.stream->raw     = (const uint8_t *)copy;
        out.as.stream->raw_len = decoded.len;
    }
    out.as.stream->filtered = 1;
    pdfmake_buf_free(&decoded);
    return out;
}

static pdfmake_obj_t import_obj(pdfmake_import_ctx_t *ctx, pdfmake_obj_t src) {
    switch (src.kind) {
        case PDFMAKE_NULL:  return pdfmake_null();
        case PDFMAKE_BOOL:  return pdfmake_bool((int)src.as.i);
        case PDFMAKE_INT:   return pdfmake_int(src.as.i);
        case PDFMAKE_REAL:  return pdfmake_real(src.as.r);
        case PDFMAKE_NAME:  return import_name(ctx, src);
        case PDFMAKE_STR:   return import_string(ctx, src);
        case PDFMAKE_ARRAY: return import_array(ctx, src);
        case PDFMAKE_DICT:  return import_dict(ctx, src);
        case PDFMAKE_STREAM:return import_stream(ctx, src);
        case PDFMAKE_REF: {
            uint32_t dst_num = import_ref_num(ctx, src.as.ref.num);
            if (dst_num == 0) return pdfmake_null();
            return pdfmake_ref(dst_num, 0);
        }
    }
    return pdfmake_null();
}

uint32_t pdfmake_import_object(pdfmake_import_ctx_t *ctx, uint32_t src_num) {
    if (!ctx) return 0;
    return import_ref_num(ctx, src_num);
}

/*============================================================================
 * Page import
 *==========================================================================*/

/* Resolve an obj through a single ref indirection, in the parser arena. */
static pdfmake_obj_t *parser_resolve(pdfmake_parser_t *parser,
                                     pdfmake_obj_t *obj) {
    if (!obj) return NULL;
    if (obj->kind == PDFMAKE_REF) {
        return pdfmake_parser_resolve(parser, obj->as.ref);
    }
    return obj;
}

/* Find a page's /Resources dict by walking up /Parent until one is found.
 * All name lookups happen in the parser's arena so ids stay consistent
 * for downstream import_obj calls.  Returns a dict obj (in parser arena)
 * or NULL if none found. */
static pdfmake_obj_t *find_inherited_resources(pdfmake_import_ctx_t *ctx,
                                                pdfmake_obj_t *page_dict) {
    pdfmake_arena_t *pa = ctx->src_arena;
    uint32_t res_key    = pdfmake_arena_intern_name(pa, "Resources", 9);
    uint32_t parent_key = pdfmake_arena_intern_name(pa, "Parent",    6);
    pdfmake_obj_t *current;
    int depth;
    pdfmake_obj_t *res;
    pdfmake_obj_t *parent;

    current = parser_resolve(ctx->src_parser, page_dict);
    depth = 0;
    while (current && current->kind == PDFMAKE_DICT && depth < 32) {
        res = pdfmake_dict_get(current, res_key);
        res = parser_resolve(ctx->src_parser, res);
        if (res && res->kind == PDFMAKE_DICT) return res;

        parent = pdfmake_dict_get(current, parent_key);
        if (!parent) break;
        current = parser_resolve(ctx->src_parser, parent);
        depth++;
    }
    return NULL;
}

pdfmake_page_t *pdfmake_doc_import_page(pdfmake_import_ctx_t *ctx,
                                         size_t src_page_index) {
    pdfmake_reader_page_t *rp;
    double mbox[4];
    double width;
    double height;
    pdfmake_page_t *dst_page;
    pdfmake_buf_t content;
    pdfmake_err_t cerr;
    pdfmake_obj_t *resources;
    pdfmake_obj_t dst_res;

    if (!ctx) return NULL;

    rp = pdfmake_reader_page_at(ctx->src_reader, src_page_index);
    if (!rp) return NULL;

    /* Dimensions from media box */
    if (pdfmake_reader_page_media_box(ctx->src_reader, rp, mbox) != PDFMAKE_OK) {
        return NULL;
    }
    width  = mbox[2] - mbox[0];
    height = mbox[3] - mbox[1];
    if (width <= 0 || height <= 0) return NULL;

    /* Append a fresh page to dst */
    dst_page = pdfmake_doc_add_page(ctx->dst, width, height);
    if (!dst_page) return NULL;

    dst_page->rotation = pdfmake_reader_page_rotation(ctx->src_reader, rp);

    /* Content stream (decompressed bytes from reader, stored uncompressed
     * in dst so the writer emits them as-is without /Filter). */
    if (pdfmake_buf_init(&content) == PDFMAKE_OK) {
        cerr = pdfmake_reader_page_content_bytes(
            ctx->src_reader, rp, &content);
        if (cerr == PDFMAKE_OK && content.len > 0) {
            pdfmake_page_set_content(dst_page, content.data, content.len);
        }
        pdfmake_buf_free(&content);
    }

    /* Resolve /Resources using our own /Parent walk in the parser arena
     * (the reader's merged dict mixes reader-arena and parser-arena name
     * ids, which would corrupt key lookups during deep-copy).  Child
     * nearest-ancestor wins; entry-level merging across ancestors is not
     * yet implemented. */
    resources = find_inherited_resources(ctx, rp->page_dict);
    if (resources && resources->kind == PDFMAKE_DICT) {
        dst_res = import_obj(ctx, *resources);
        if (dst_res.kind == PDFMAKE_DICT) {
            dst_page->imported_resources = dst_res.as.dict;
        }
    }

    ctx->dst->finalized = 0;
    return dst_page;
}

size_t pdfmake_doc_import_all_pages(pdfmake_import_ctx_t *ctx) {
    size_t total;
    size_t imported;
    size_t i;

    if (!ctx) return 0;
    total = pdfmake_reader_page_count(ctx->src_reader);
    imported = 0;
    for (i = 0; i < total; i++) {
        if (!pdfmake_doc_import_page(ctx, i)) break;
        imported++;
    }
    return imported;
}
