/*
 * pdfmake_reader.c — Document reader implementation
 *
 * Flattens page tree, resolves inheritable attributes, extracts content streams.
 */

#include "pdfmake_reader.h"
#include "pdfmake_parser.h"
#include "pdfmake_filter.h"
#include "pdfmake_arena.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/*----------------------------------------------------------------------------
 * Internal helpers
 *--------------------------------------------------------------------------*/

/* Set error message */
static void reader_set_error(pdfmake_reader_t *reader, pdfmake_err_t err, const char *msg) {
    reader->last_err = err;
    snprintf(reader->err_msg, sizeof(reader->err_msg), "%s", msg);
}

/* Resolve indirect reference if needed */
static pdfmake_obj_t *resolve_ref(pdfmake_reader_t *reader, pdfmake_obj_t *obj) {
    if (!obj) return NULL;
    if (obj->kind == PDFMAKE_REF) {
        return pdfmake_parser_resolve(reader->parser, obj->as.ref);
    }
    return obj;
}

/* Get dict entry by C string key */
static pdfmake_obj_t *dict_get_cstr(pdfmake_reader_t *reader, pdfmake_obj_t *dict, const char *key) {
    uint32_t key_id;
    if (!dict || dict->kind != PDFMAKE_DICT) return NULL;
    key_id = pdfmake_arena_intern_name(reader->doc->arena, key, strlen(key));
    if (key_id == 0) return NULL;
    return pdfmake_dict_get(dict, key_id);
}

/* Get name value as C string (from interned id) */
static const char *name_cstr(pdfmake_reader_t *reader, pdfmake_obj_t *obj) {
    if (!obj || obj->kind != PDFMAKE_NAME) return NULL;
    return pdfmake_arena_name_bytes(reader->doc->arena, obj->as.name.id);
}

/* Parse a rectangle array [llx, lly, urx, ury] */
static int parse_rect(pdfmake_reader_t *reader, pdfmake_obj_t *arr, double out[4]) {
    int i;
    if (!arr || arr->kind != PDFMAKE_ARRAY) return 0;
    if (pdfmake_array_len(arr) < 4) return 0;
    
    for (i = 0; i < 4; i++) {
        pdfmake_obj_t *item = pdfmake_array_get(arr, i);
        item = resolve_ref(reader, item);
        if (!item) return 0;
        
        if (item->kind == PDFMAKE_INT) {
            out[i] = (double)item->as.i;
        } else if (item->kind == PDFMAKE_REAL) {
            out[i] = item->as.r;
        } else {
            return 0;
        }
    }
    return 1;
}

/*----------------------------------------------------------------------------
 * Cycle detection for page tree traversal
 *--------------------------------------------------------------------------*/

typedef struct {
    pdfmake_obj_t **visited;
    size_t          count;
    size_t          cap;
} cycle_detector_t;

static void cycle_detector_init(cycle_detector_t *cd) {
    cd->visited = NULL;
    cd->count = 0;
    cd->cap = 0;
}

static void cycle_detector_free(cycle_detector_t *cd) {
    free(cd->visited);
    cd->visited = NULL;
    cd->count = 0;
    cd->cap = 0;
}

static int cycle_detector_check(cycle_detector_t *cd, pdfmake_obj_t *node) {
    size_t i;
    /* Check if we've seen this node before */
    for (i = 0; i < cd->count; i++) {
        if (cd->visited[i] == node) {
            return 1;  /* Cycle detected */
        }
    }
    
    /* Add node to visited list */
    if (cd->count >= cd->cap) {
        size_t new_cap = cd->cap ? cd->cap * 2 : 16;
        pdfmake_obj_t **new_visited = realloc(cd->visited, new_cap * sizeof(*cd->visited));
        if (!new_visited) return -1;  /* Allocation failure */
        cd->visited = new_visited;
        cd->cap = new_cap;
    }
    cd->visited[cd->count++] = node;
    return 0;  /* No cycle */
}

/*----------------------------------------------------------------------------
 * Page tree flattening
 *--------------------------------------------------------------------------*/

/* Forward declaration */
static pdfmake_err_t flatten_pages_recursive(pdfmake_reader_t *reader,
                                              pdfmake_obj_t *node,
                                              cycle_detector_t *cd);

/* Add a page to the reader's page list */
static pdfmake_err_t add_page(pdfmake_reader_t *reader, pdfmake_obj_t *page_dict) {
    pdfmake_reader_page_t *page;
    if (reader->page_count >= reader->page_cap) {
        size_t new_cap = reader->page_cap ? reader->page_cap * 2 : 16;
        pdfmake_reader_page_t *new_pages = realloc(reader->pages, 
                                                    new_cap * sizeof(*reader->pages));
        if (!new_pages) {
            reader_set_error(reader, PDFMAKE_ENOMEM, "Failed to allocate pages array");
            return PDFMAKE_ENOMEM;
        }
        reader->pages = new_pages;
        reader->page_cap = new_cap;
    }
    
    page = &reader->pages[reader->page_count++];
    memset(page, 0, sizeof(*page));
    page->page_dict = page_dict;
    
    return PDFMAKE_OK;
}

/* Recursively flatten pages tree */
static pdfmake_err_t flatten_pages_recursive(pdfmake_reader_t *reader,
                                              pdfmake_obj_t *node,
                                              cycle_detector_t *cd) {
    int cycle_result;
    pdfmake_obj_t *type_obj;
    const char *type_name;
    pdfmake_obj_t *kids;
    size_t kids_len;
    size_t i;

    if (!node) {
        reader_set_error(reader, PDFMAKE_EBADPAGE, "Null page tree node");
        return PDFMAKE_EBADPAGE;
    }
    
    /* Resolve indirect reference */
    node = resolve_ref(reader, node);
    if (!node || node->kind != PDFMAKE_DICT) {
        reader_set_error(reader, PDFMAKE_EBADPAGE, "Page tree node is not a dictionary");
        return PDFMAKE_EBADPAGE;
    }
    
    /* Check for cycles */
    cycle_result = cycle_detector_check(cd, node);
    if (cycle_result < 0) {
        reader_set_error(reader, PDFMAKE_ENOMEM, "Cycle detector allocation failed");
        return PDFMAKE_ENOMEM;
    }
    if (cycle_result > 0) {
        reader_set_error(reader, PDFMAKE_ECYCLE_PAGE, "Cycle detected in page tree");
        return PDFMAKE_ECYCLE_PAGE;
    }
    
    /* Get /Type to determine if this is a /Page or /Pages node */
    type_obj = dict_get_cstr(reader, node, "Type");
    type_obj = resolve_ref(reader, type_obj);
    type_name = name_cstr(reader, type_obj);
    
    if (!type_name) {
        reader_set_error(reader, PDFMAKE_EBADPAGE, "Page tree node missing /Type");
        return PDFMAKE_EBADPAGE;
    }
    
    if (strcmp(type_name, "Page") == 0) {
        /* Leaf page — add to list */
        return add_page(reader, node);
    } else if (strcmp(type_name, "Pages") == 0) {
        /* Intermediate node — recurse into /Kids */
        kids = dict_get_cstr(reader, node, "Kids");
        kids = resolve_ref(reader, kids);
        
        if (!kids || kids->kind != PDFMAKE_ARRAY) {
            reader_set_error(reader, PDFMAKE_EBADPAGE, "/Pages node missing /Kids array");
            return PDFMAKE_EBADPAGE;
        }
        
        kids_len = pdfmake_array_len(kids);
        for (i = 0; i < kids_len; i++) {
            pdfmake_obj_t *kid = pdfmake_array_get(kids, i);
            pdfmake_err_t err = flatten_pages_recursive(reader, kid, cd);
            if (err != PDFMAKE_OK) {
                return err;
            }
        }
        return PDFMAKE_OK;
    } else {
        char msg[128];
        snprintf(msg, sizeof(msg), "Unknown page tree node type: %s", type_name);
        reader_set_error(reader, PDFMAKE_EBADPAGE, msg);
        return PDFMAKE_EBADPAGE;
    }
}

pdfmake_err_t pdfmake_reader_flatten_pages(pdfmake_reader_t *reader,
                                            pdfmake_obj_t *pages_node) {
    cycle_detector_t cd;
    pdfmake_err_t err;
    cycle_detector_init(&cd);
    
    err = flatten_pages_recursive(reader, pages_node, &cd);
    
    cycle_detector_free(&cd);
    return err;
}

/*----------------------------------------------------------------------------
 * Inheritable attribute resolution
 *--------------------------------------------------------------------------*/

pdfmake_obj_t *pdfmake_reader_resolve_inheritable(pdfmake_reader_t *reader,
                                                   pdfmake_obj_t *page_dict,
                                                   const char *key) {
    pdfmake_obj_t *current = page_dict;
    pdfmake_obj_t *value;
    pdfmake_obj_t *parent;
    
    while (current) {
        current = resolve_ref(reader, current);
        if (!current || current->kind != PDFMAKE_DICT) break;
        
        /* Check for the key on this node */
        value = dict_get_cstr(reader, current, key);
        if (value) {
            return resolve_ref(reader, value);
        }
        
        /* Walk up to /Parent */
        parent = dict_get_cstr(reader, current, "Parent");
        current = parent;
    }
    
    return NULL;  /* Not found */
}

/*----------------------------------------------------------------------------
 * Resource merging
 *--------------------------------------------------------------------------*/

/* Merge a single resource category (e.g., /Font, /XObject) */
static void merge_resource_category(pdfmake_reader_t *reader,
                                     pdfmake_obj_t *dest,
                                     pdfmake_obj_t *src,
                                     const char *category) {
    pdfmake_obj_t *src_cat;
    pdfmake_obj_t *dest_cat;
    pdfmake_arena_t *key_arena;
    pdfmake_dict_iter_t iter;

    src_cat = dict_get_cstr(reader, src, category);
    src_cat = resolve_ref(reader, src_cat);
    if (!src_cat || src_cat->kind != PDFMAKE_DICT) return;
    
    dest_cat = dict_get_cstr(reader, dest, category);
    dest_cat = resolve_ref(reader, dest_cat);
    
    /* All name interning here uses the parser's arena so downstream
     * consumers (interpreter, textract) get a single consistent arena. */
    key_arena = reader->parser
        ? reader->parser->doc->arena
        : reader->arena;

    if (!dest_cat) {
        uint32_t cat_key;
        /* Category doesn't exist in dest — create it */
        dest_cat = pdfmake_arena_alloc(reader->arena, sizeof(pdfmake_obj_t));
        if (!dest_cat) return;
        *dest_cat = pdfmake_dict_new(reader->arena);

        cat_key = pdfmake_arena_intern_name(key_arena, category, strlen(category));
        if (cat_key) {
            pdfmake_dict_set(reader->arena, dest, cat_key, *dest_cat);
        }
    }
    
    /* Copy entries from src to dest (dest wins on conflict). Keys in
     * src_cat are interned in the parser's arena; we preserve that so all
     * downstream consumers (interpreter, textract) can use the parser
     * arena for consistent name-ID lookups. */
    pdfmake_dict_iter_init(&iter, src_cat);
    while (pdfmake_dict_iter_next(&iter)) {
        if (!pdfmake_dict_has(dest_cat, iter.current_key)) {
            pdfmake_dict_set(reader->arena, dest_cat, iter.current_key, *iter.current_value);
        }
    }
}

pdfmake_obj_t *pdfmake_reader_merge_resources(pdfmake_reader_t *reader,
                                               pdfmake_obj_t *page_dict) {
    pdfmake_obj_t *merged;
    pdfmake_obj_t *resource_chain[32];  /* Max depth */
    size_t chain_len = 0;
    pdfmake_obj_t *current;
    size_t i;
    const char **cat;

    /* Create merged resources dict */
    merged = pdfmake_arena_alloc(reader->arena, sizeof(pdfmake_obj_t));
    if (!merged) return NULL;
    *merged = pdfmake_dict_new(reader->arena);
    
    /* Collect all resource dicts from page up to root (child first) */
    current = page_dict;
    while (current && chain_len < 32) {
        pdfmake_obj_t *res;
        current = resolve_ref(reader, current);
        if (!current || current->kind != PDFMAKE_DICT) break;
        
        res = dict_get_cstr(reader, current, "Resources");
        res = resolve_ref(reader, res);
        if (res && res->kind == PDFMAKE_DICT) {
            resource_chain[chain_len++] = res;
        }
        
        current = dict_get_cstr(reader, current, "Parent");
    }
    
    /* Merge from root (ancestors) down to leaf (child wins) */
    {
        static const char *categories[] = {
            "ExtGState", "ColorSpace", "Pattern", "Shading",
            "XObject", "Font", "Properties", "ProcSet", NULL
        };

        for (i = chain_len; i > 0; i--) {
            pdfmake_obj_t *res = resource_chain[i - 1];
            for (cat = categories; *cat; cat++) {
                merge_resource_category(reader, merged, res, *cat);
            }
        }
    }
    
    return merged;
}

/*----------------------------------------------------------------------------
 * Reader lifecycle
 *--------------------------------------------------------------------------*/

pdfmake_reader_t *pdfmake_reader_new(pdfmake_parser_t *parser) {
    pdfmake_reader_t *reader;
    if (!parser) return NULL;
    
    reader = calloc(1, sizeof(*reader));
    if (!reader) return NULL;
    
    reader->parser = parser;
    reader->doc = NULL;  /* Will be set by pdfmake_parser_run */
    reader->arena = pdfmake_arena_new();
    if (!reader->arena) {
        free(reader);
        return NULL;
    }
    
    return reader;
}

void pdfmake_reader_free(pdfmake_reader_t *reader) {
    if (!reader) return;
    
    free(reader->pages);
    pdfmake_arena_free(reader->arena);
    free(reader);
}

pdfmake_err_t pdfmake_reader_init(pdfmake_reader_t *reader) {
    pdfmake_doc_t *doc;
    pdfmake_err_t err;
    pdfmake_ref_t root_ref;
    pdfmake_obj_t *pages_ref;
    pdfmake_ref_t enc_ref;
    pdfmake_obj_t *enc_dict;

    if (!reader || !reader->parser) {
        return PDFMAKE_EINVAL;
    }
    
    /* Get document from parser */
    /* Note: parser should have already parsed the document */
    doc = NULL;
    err = pdfmake_parser_run(reader->parser, &doc);
    if (err != PDFMAKE_OK) {
        reader_set_error(reader, err, "Parser failed");
        return err;
    }
    reader->doc = doc;
    
    /* Get catalog from /Root */
    if (reader->parser->root_num == 0) {
        reader_set_error(reader, PDFMAKE_ENOROOT, "Missing /Root in trailer");
        return PDFMAKE_ENOROOT;
    }
    
    root_ref.num = reader->parser->root_num;
    root_ref.gen = reader->parser->root_gen;
    reader->catalog = pdfmake_parser_resolve(reader->parser, root_ref);
    if (!reader->catalog || reader->catalog->kind != PDFMAKE_DICT) {
        reader_set_error(reader, PDFMAKE_ENOROOT, "Invalid /Root catalog");
        return PDFMAKE_ENOROOT;
    }
    
    /* Get /Pages from catalog */
    pages_ref = dict_get_cstr(reader, reader->catalog, "Pages");
    if (!pages_ref) {
        reader_set_error(reader, PDFMAKE_ENOPAGES, "Missing /Pages in catalog");
        return PDFMAKE_ENOPAGES;
    }
    
    /* Flatten the page tree */
    err = pdfmake_reader_flatten_pages(reader, pages_ref);
    if (err != PDFMAKE_OK) {
        return err;
    }

    /* Set up decryption if /Encrypt is present */
    if (reader->parser->encrypt_num > 0) {
        reader->encrypted = 1;

        /* Resolve the /Encrypt dictionary */
        enc_ref.num = reader->parser->encrypt_num;
        enc_ref.gen = reader->parser->encrypt_gen;
        enc_dict = pdfmake_parser_resolve(reader->parser, enc_ref);
        if (enc_dict && enc_dict->kind == PDFMAKE_DICT) {
            pdfmake_obj_t *V_obj = dict_get_cstr(reader, enc_dict, "V");
            pdfmake_obj_t *R_obj = dict_get_cstr(reader, enc_dict, "R");
            pdfmake_obj_t *O_obj = dict_get_cstr(reader, enc_dict, "O");
            pdfmake_obj_t *U_obj = dict_get_cstr(reader, enc_dict, "U");
            pdfmake_obj_t *P_obj = dict_get_cstr(reader, enc_dict, "P");
            pdfmake_obj_t *len_obj = dict_get_cstr(reader, enc_dict, "Length");

            /* Optional AES-256 fields */
            pdfmake_obj_t *OE_obj = dict_get_cstr(reader, enc_dict, "OE");
            pdfmake_obj_t *UE_obj = dict_get_cstr(reader, enc_dict, "UE");
            pdfmake_obj_t *Perms_obj = dict_get_cstr(reader, enc_dict, "Perms");
            pdfmake_obj_t *em_obj = dict_get_cstr(reader, enc_dict, "EncryptMetadata");

            int V = (V_obj && V_obj->kind == PDFMAKE_INT) ? (int)V_obj->as.i : 0;
            int R = (R_obj && R_obj->kind == PDFMAKE_INT) ? (int)R_obj->as.i : 0;
            int key_length = (len_obj && len_obj->kind == PDFMAKE_INT)
                             ? (int)len_obj->as.i : 40;
            int32_t P = (P_obj && P_obj->kind == PDFMAKE_INT)
                        ? (int32_t)P_obj->as.i : 0;
            int encrypt_metadata = 1;
            const uint8_t *O;
            size_t O_len;
            const uint8_t *U;
            size_t U_len;
            const uint8_t *OE = NULL; size_t OE_len = 0;
            const uint8_t *UE = NULL; size_t UE_len = 0;
            const uint8_t *Perms = NULL; size_t Perms_len = 0;

            if (em_obj && em_obj->kind == PDFMAKE_BOOL && !em_obj->as.b)
                encrypt_metadata = 0;

            O = (O_obj && O_obj->kind == PDFMAKE_STR) ? O_obj->as.str.bytes : NULL;
            O_len = (O_obj && O_obj->kind == PDFMAKE_STR) ? O_obj->as.str.len : 0;
            U = (U_obj && U_obj->kind == PDFMAKE_STR) ? U_obj->as.str.bytes : NULL;
            U_len = (U_obj && U_obj->kind == PDFMAKE_STR) ? U_obj->as.str.len : 0;

            if (OE_obj && OE_obj->kind == PDFMAKE_STR) { OE = OE_obj->as.str.bytes; OE_len = OE_obj->as.str.len; }
            if (UE_obj && UE_obj->kind == PDFMAKE_STR) { UE = UE_obj->as.str.bytes; UE_len = UE_obj->as.str.len; }
            if (Perms_obj && Perms_obj->kind == PDFMAKE_STR) { Perms = Perms_obj->as.str.bytes; Perms_len = Perms_obj->as.str.len; }

            if (O && U) {
                reader->crypt = pdfmake_arena_alloc(reader->arena, sizeof(pdfmake_crypt_ctx_t));
                if (reader->crypt) {
                    int rc;
                    pdfmake_crypt_init(reader->crypt);
                    rc = pdfmake_crypt_load(reader->crypt,
                        V, R, key_length, O, O_len, U, U_len,
                        OE, OE_len, UE, UE_len, Perms, Perms_len,
                        P, reader->parser->doc_id, reader->parser->doc_id_len,
                        encrypt_metadata);
                    if (rc == 0) {
                        /* Try empty password first */
                        int auth = pdfmake_crypt_authenticate(reader->crypt, "");
                        if (auth >= 0) {
                            reader->authenticated = 1;
                        }
                    }
                }
            }
        }
    }

    return PDFMAKE_OK;
}

int pdfmake_reader_set_password(pdfmake_reader_t *reader, const char *password) {
    int auth;
    if (!reader || !reader->crypt) return -1;
    auth = pdfmake_crypt_authenticate(reader->crypt, password ? password : "");
    if (auth >= 0) reader->authenticated = 1;
    return auth;
}

int pdfmake_reader_is_encrypted(pdfmake_reader_t *reader) {
    return reader ? reader->encrypted : 0;
}

int pdfmake_reader_is_authenticated(pdfmake_reader_t *reader) {
    return reader ? reader->authenticated : 0;
}

const char *pdfmake_reader_errmsg(pdfmake_reader_t *reader) {
    return reader ? reader->err_msg : "NULL reader";
}

/*----------------------------------------------------------------------------
 * Page enumeration
 *--------------------------------------------------------------------------*/

size_t pdfmake_reader_page_count(pdfmake_reader_t *reader) {
    return reader ? reader->page_count : 0;
}

pdfmake_reader_page_t *pdfmake_reader_page_at(pdfmake_reader_t *reader, size_t idx) {
    if (!reader || idx >= reader->page_count) return NULL;
    return &reader->pages[idx];
}

/*----------------------------------------------------------------------------
 * Page attributes
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_reader_page_media_box(pdfmake_reader_t *reader,
                                             pdfmake_reader_page_t *page,
                                             double out[4]) {
    pdfmake_obj_t *media_box;

    if (!reader || !page || !out) return PDFMAKE_EINVAL;
    
    /* Check cache */
    if (page->media_box_set) {
        memcpy(out, page->media_box, sizeof(page->media_box));
        return PDFMAKE_OK;
    }
    
    /* Resolve inheritable /MediaBox */
    media_box = pdfmake_reader_resolve_inheritable(reader, 
                                                                   page->page_dict, 
                                                                   "MediaBox");
    if (!media_box) {
        reader_set_error(reader, PDFMAKE_ENOMEDIABOX, "No MediaBox found");
        return PDFMAKE_ENOMEDIABOX;
    }
    
    if (!parse_rect(reader, media_box, page->media_box)) {
        reader_set_error(reader, PDFMAKE_EBADPAGE, "Invalid MediaBox format");
        return PDFMAKE_EBADPAGE;
    }
    
    page->media_box_set = 1;
    memcpy(out, page->media_box, sizeof(page->media_box));
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_reader_page_crop_box(pdfmake_reader_t *reader,
                                            pdfmake_reader_page_t *page,
                                            double out[4]) {
    pdfmake_obj_t *crop_box;
    pdfmake_err_t err;

    if (!reader || !page || !out) return PDFMAKE_EINVAL;
    
    /* Check cache */
    if (page->crop_box_set) {
        memcpy(out, page->crop_box, sizeof(page->crop_box));
        return PDFMAKE_OK;
    }
    
    /* Try /CropBox first */
    crop_box = pdfmake_reader_resolve_inheritable(reader,
                                                                  page->page_dict,
                                                                  "CropBox");
    if (crop_box && parse_rect(reader, crop_box, page->crop_box)) {
        page->crop_box_set = 1;
        memcpy(out, page->crop_box, sizeof(page->crop_box));
        return PDFMAKE_OK;
    }
    
    /* Fall back to MediaBox */
    err = pdfmake_reader_page_media_box(reader, page, page->crop_box);
    if (err != PDFMAKE_OK) return err;
    
    page->crop_box_set = 1;
    memcpy(out, page->crop_box, sizeof(page->crop_box));
    return PDFMAKE_OK;
}

int pdfmake_reader_page_rotation(pdfmake_reader_t *reader,
                                  pdfmake_reader_page_t *page) {
    pdfmake_obj_t *rotate;

    if (!reader || !page) return 0;
    
    /* Check cache */
    if (page->rotation_set) {
        return page->rotation;
    }
    
    /* Resolve inheritable /Rotate */
    rotate = pdfmake_reader_resolve_inheritable(reader,
                                                                page->page_dict,
                                                                "Rotate");
    if (rotate && rotate->kind == PDFMAKE_INT) {
        int r = (int)rotate->as.i;
        /* Normalize to 0, 90, 180, 270 */
        r = ((r % 360) + 360) % 360;
        if (r != 0 && r != 90 && r != 180 && r != 270) {
            r = 0;  /* Invalid rotation, default to 0 */
        }
        page->rotation = r;
    } else {
        page->rotation = 0;
    }
    
    page->rotation_set = 1;
    return page->rotation;
}

pdfmake_obj_t *pdfmake_reader_page_resources(pdfmake_reader_t *reader,
                                              pdfmake_reader_page_t *page) {
    if (!reader || !page) return NULL;
    
    /* Check cache */
    if (page->resources_set) {
        return page->resources;
    }
    
    /* Merge resources from page and ancestors */
    page->resources = pdfmake_reader_merge_resources(reader, page->page_dict);
    page->resources_set = 1;
    
    return page->resources;
}

/*----------------------------------------------------------------------------
 * Content stream extraction
 *--------------------------------------------------------------------------*/

/*
 * Decrypt (if needed) and decompress a stream object.
 * obj_num/gen are used for per-object key derivation.
 */
static pdfmake_err_t reader_decode_stream(pdfmake_reader_t *reader,
                                           pdfmake_obj_t *stream_obj,
                                           uint32_t obj_num, uint16_t gen,
                                           pdfmake_buf_t *out) {
    pdfmake_stream_t *stream;
    uint8_t *decoded = NULL;
    size_t decoded_len = 0;
    pdfmake_err_t err;

    if (!stream_obj || stream_obj->kind != PDFMAKE_STREAM)
        return PDFMAKE_EINVAL;

    stream = stream_obj->as.stream;

    /* If encrypted and authenticated, decrypt the raw data first */
    if (reader->crypt && reader->authenticated && !stream->filtered) {
        uint8_t *decrypted = NULL;
        size_t dec_len = 0;
        int rc = pdfmake_crypt_decrypt_stream(reader->crypt,
                                              (int)obj_num, (int)gen,
                                              stream->raw, stream->raw_len,
                                              &decrypted, &dec_len);
        if (rc >= 0 && decrypted) {
            /* Replace raw data with decrypted data for filter decode */
            uint8_t *arena_copy = pdfmake_arena_alloc(reader->arena, dec_len);
            if (arena_copy) {
                memcpy(arena_copy, decrypted, dec_len);
                stream->raw = arena_copy;
                stream->raw_len = dec_len;
            }
            free(decrypted);
        }
    }

    /* Now decompress through filter chain */
    err = pdfmake_decode_stream(reader->parser,
                                               stream, &decoded, &decoded_len);
    if (err != PDFMAKE_OK) return err;

    pdfmake_buf_append(out, decoded, decoded_len);
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_reader_resolve_stream(pdfmake_reader_t *reader,
                                             uint32_t obj_num,
                                             uint16_t gen,
                                             pdfmake_buf_t *out) {
    pdfmake_ref_t ref;
    pdfmake_obj_t *obj;
    if (!reader || !out) return PDFMAKE_EINVAL;
    ref.num = obj_num;
    ref.gen = gen;
    obj = pdfmake_parser_resolve(reader->parser, ref);
    if (!obj || obj->kind != PDFMAKE_STREAM) return PDFMAKE_EINVAL;
    return reader_decode_stream(reader, obj, obj_num, gen, out);
}

pdfmake_err_t pdfmake_reader_page_content_bytes(pdfmake_reader_t *reader,
                                                 pdfmake_reader_page_t *page,
                                                 pdfmake_buf_t *out) {
    pdfmake_obj_t *contents_raw;
    uint32_t cont_obj_num = 0;
    uint16_t cont_gen = 0;
    pdfmake_obj_t *contents;
    size_t arr_len;
    size_t i;

    if (!reader || !page || !out) return PDFMAKE_EINVAL;
    
    /* Get /Contents from page */
    contents_raw = dict_get_cstr(reader, page->page_dict, "Contents");
    if (!contents_raw) {
        /* Page with no content is valid — empty content */
        return PDFMAKE_OK;
    }

    /* Track object number for decryption key derivation */
    if (contents_raw->kind == PDFMAKE_REF) {
        cont_obj_num = contents_raw->as.ref.num;
        cont_gen = contents_raw->as.ref.gen;
    }

    contents = resolve_ref(reader, contents_raw);
    if (!contents) {
        reader_set_error(reader, PDFMAKE_EBADPAGE, "Could not resolve /Contents");
        return PDFMAKE_EBADPAGE;
    }

    /* Handle single stream or array of streams */
    if (contents->kind == PDFMAKE_STREAM) {
        pdfmake_err_t err = reader_decode_stream(reader, contents,
                                                  cont_obj_num, cont_gen, out);
        if (err != PDFMAKE_OK) {
            reader_set_error(reader, err, "Failed to decode content stream");
            return err;
        }

    } else if (contents->kind == PDFMAKE_ARRAY) {
        arr_len = pdfmake_array_len(contents);

        for (i = 0; i < arr_len; i++) {
            pdfmake_obj_t *stream_ref;
            uint32_t s_num = 0;
            uint16_t s_gen = 0;
            pdfmake_obj_t *stream;
            pdfmake_err_t err;

            if (i > 0)
                pdfmake_buf_append(out, (const uint8_t *)" ", 1);

            stream_ref = pdfmake_array_get(contents, i);
            if (stream_ref && stream_ref->kind == PDFMAKE_REF) {
                s_num = stream_ref->as.ref.num;
                s_gen = stream_ref->as.ref.gen;
            }
            stream = resolve_ref(reader, stream_ref);

            if (!stream || stream->kind != PDFMAKE_STREAM) {
                reader_set_error(reader, PDFMAKE_EBADPAGE, "/Contents array has non-stream element");
                return PDFMAKE_EBADPAGE;
            }

            err = reader_decode_stream(reader, stream,
                                                      s_num, s_gen, out);
            if (err != PDFMAKE_OK) {
                char msg[128];
                snprintf(msg, sizeof(msg), "Failed to decode content stream %zu", i);
                reader_set_error(reader, err, msg);
                return err;
            }
        }

    } else {
        reader_set_error(reader, PDFMAKE_EBADPAGE, "/Contents is neither stream nor array");
        return PDFMAKE_EBADPAGE;
    }
    
    return PDFMAKE_OK;
}
