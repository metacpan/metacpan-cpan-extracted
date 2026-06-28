/*
 * pdfmake_doc.c — PDF document structure and file emission.
 */

#include "pdfmake_doc.h"
#include "pdfmake_meta.h"
#include "pdfmake_page.h"
#include "pdfmake_writer.h"
#include "pdfmake_attach.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <time.h>

/*----------------------------------------------------------------------------
 * FNV-1a hash for ID generation
 *--------------------------------------------------------------------------*/

#define FNV_OFFSET_BASIS 0xcbf29ce484222325ULL
#define FNV_PRIME        0x100000001b3ULL

static uint64_t fnv1a_64(const void *data, size_t len) {
    uint64_t hash = FNV_OFFSET_BASIS;
    const uint8_t *p = (const uint8_t *)data;
    size_t i;
    for (i = 0; i < len; i++) {
        hash ^= p[i];
        hash *= FNV_PRIME;
    }
    return hash;
}

/*----------------------------------------------------------------------------
 * Lifecycle
 *--------------------------------------------------------------------------*/

pdfmake_doc_t *pdfmake_doc_new(void) {
    pdfmake_doc_t *doc = calloc(1, sizeof(pdfmake_doc_t));
    if (!doc) return NULL;

    doc->arena = pdfmake_arena_new();
    if (!doc->arena) {
        free(doc);
        return NULL;
    }

    doc->objects = calloc(PDFMAKE_DOC_INIT_CAP, sizeof(pdfmake_indirect_t));
    if (!doc->objects) {
        pdfmake_arena_free(doc->arena);
        free(doc);
        return NULL;
    }
    doc->obj_cap = PDFMAKE_DOC_INIT_CAP;
    doc->obj_count = 0;

    doc->pages = NULL;
    doc->page_count = 0;
    doc->page_cap = 0;
    doc->pages_num = 0;
    doc->finalized = 0;

    return doc;
}

void pdfmake_doc_free(pdfmake_doc_t *doc) {
    size_t i;
    if (!doc) return;
    /* Free page annotation arrays (malloc'd, not arena) before arena is freed */
    for (i = 0; i < doc->page_count; i++) {
        if (doc->pages[i] && doc->pages[i]->annots) {
            free(doc->pages[i]->annots);
        }
    }
    pdfmake_arena_free(doc->arena);
    free(doc->objects);
    free(doc->pages);       /* Page structs are in arena, just free the pointer array */
    free(doc->ocgs);        /* OCG pointers in arena, just free the pointer array */
    /* Free individual attachments (data + struct) */
    if (doc->attachments) {
        for (i = 0; i < doc->attach_count; i++) {
            pdfmake_attachment_t *att = doc->attachments[i];
            if (att) {
                free(att->data);
                free(att);
            }
        }
        free(doc->attachments);
    }
    free(doc);
}

pdfmake_arena_t *pdfmake_doc_arena(pdfmake_doc_t *doc) {
    return doc ? doc->arena : NULL;
}

/*----------------------------------------------------------------------------
 * Indirect object management
 *--------------------------------------------------------------------------*/

static int doc_grow_objects(pdfmake_doc_t *doc) {
    size_t new_cap = doc->obj_cap * 2;
    pdfmake_indirect_t *new_arr = realloc(doc->objects,
                                          new_cap * sizeof(pdfmake_indirect_t));
    if (!new_arr) return 0;

    /* Zero out new entries */
    memset(new_arr + doc->obj_cap, 0,
           (new_cap - doc->obj_cap) * sizeof(pdfmake_indirect_t));

    doc->objects = new_arr;
    doc->obj_cap = new_cap;
    return 1;
}

uint32_t pdfmake_doc_add(pdfmake_doc_t *doc, pdfmake_obj_t obj) {
    uint32_t num;
    size_t idx;
    if (!doc) return 0;

    /* Grow if needed */
    if (doc->obj_count >= doc->obj_cap) {
        if (!doc_grow_objects(doc)) return 0;
    }

    /* Object numbers are 1-based; index 0 corresponds to object 1 */
    num = (uint32_t)(doc->obj_count + 1);
    idx = doc->obj_count;

    doc->objects[idx].num = num;
    doc->objects[idx].gen = 0;
    doc->objects[idx].byte_offset = 0;
    doc->objects[idx].obj = obj;
    doc->objects[idx].in_use = 1;
    doc->obj_count++;

    return num;
}

pdfmake_obj_t *pdfmake_doc_get(pdfmake_doc_t *doc, uint32_t num) {
    size_t idx;
    if (!doc || num == 0 || num > doc->obj_count) return NULL;
    idx = num - 1;
    if (!doc->objects[idx].in_use) return NULL;
    return &doc->objects[idx].obj;
}

pdfmake_obj_t pdfmake_doc_ref(pdfmake_doc_t *doc, uint32_t num) {
    uint16_t gen = 0;
    if (doc && num > 0 && num <= doc->obj_count) {
        gen = doc->objects[num - 1].gen;
    }
    return pdfmake_ref(num, gen);
}

/*----------------------------------------------------------------------------
 * Trailer setup
 *--------------------------------------------------------------------------*/

void pdfmake_doc_set_root(pdfmake_doc_t *doc, uint32_t num, uint16_t gen) {
    if (!doc) return;
    doc->root_num = num;
    doc->root_gen = gen;
}

void pdfmake_doc_set_info(pdfmake_doc_t *doc, uint32_t num, uint16_t gen) {
    if (!doc) return;
    doc->info_num = num;
    doc->info_gen = gen;
}

void pdfmake_doc_generate_id(pdfmake_doc_t *doc) {
    /*
     * Generate ID using FNV-1a hash of:
     *   - Current time
     *   - Document pointer (randomness)
     *   - Object count
     */
    struct {
        time_t t;
        void *ptr;
        size_t count;
        uint64_t counter;
    } seed;
    static uint64_t counter = 0;
    uint64_t h1;
    uint64_t h2;

    if (!doc) return;

    seed.t = time(NULL);
    seed.ptr = doc;
    seed.count = doc->obj_count;
    seed.counter = ++counter;

    h1 = fnv1a_64(&seed, sizeof(seed));
    seed.counter = ++counter;
    h2 = fnv1a_64(&seed, sizeof(seed));

    /* Pack two 64-bit hashes into two 16-byte IDs */
    memcpy(doc->id1, &h1, 8);
    memcpy(doc->id1 + 8, &h2, 8);

    /* For initial creation, id2 == id1 */
    memcpy(doc->id2, doc->id1, 16);

    doc->id_set = 1;
}

/*----------------------------------------------------------------------------
 * Encryption request and /Encrypt dict construction
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_doc_set_encryption(pdfmake_doc_t *doc,
                                         pdfmake_crypt_algo_t algorithm,
                                         const char *user_passwd,
                                         const char *owner_passwd,
                                         int32_t permissions)
{
    const char *u;
    const char *o;

    if (!doc) return PDFMAKE_EINVAL;
    if (algorithm < PDFMAKE_CRYPT_RC4_40 || algorithm > PDFMAKE_CRYPT_AES_256) {
        return PDFMAKE_EINVAL;
    }

    u = user_passwd  ? user_passwd  : "";
    o = owner_passwd ? owner_passwd : u;

    doc->enc_algo        = algorithm;
    doc->enc_user_pw     = pdfmake_arena_strdup(doc->arena, u);
    doc->enc_owner_pw    = pdfmake_arena_strdup(doc->arena, o);
    doc->enc_permissions = permissions;
    doc->enc_requested   = 1;
    doc->finalized       = 0;

    return PDFMAKE_OK;
}

/* Build the /Encrypt dict and add it as an indirect object.  Assumes the
 * doc has a generated /ID and that doc->encryption has been set up. */
static pdfmake_err_t build_encrypt_dict(pdfmake_doc_t *doc) {
    pdfmake_arena_t *a = doc->arena;
    pdfmake_crypt_ctx_t *ctx = doc->encryption;
    pdfmake_obj_t d;
    uint32_t k;
    int ou_len;
    pdfmake_obj_t std_cf;
    uint32_t cfm_k;
    uint32_t len_k;
    uint32_t auth_k;
    uint32_t type_k;
    pdfmake_obj_t cf;
    uint32_t stdcf_k;
    uint32_t num;
    if (!ctx) return PDFMAKE_EINVAL;

    d = pdfmake_dict_new(a);
    if (d.kind != PDFMAKE_DICT) return PDFMAKE_ENOMEM;

    k = pdfmake_arena_intern_name(a, "Filter", 6);
    pdfmake_dict_set(a, &d, k, pdfmake_name_cstr(a, "Standard"));

    k = pdfmake_arena_intern_name(a, "V", 1);
    pdfmake_dict_set(a, &d, k, pdfmake_int(ctx->V));

    k = pdfmake_arena_intern_name(a, "R", 1);
    pdfmake_dict_set(a, &d, k, pdfmake_int(ctx->R));

    k = pdfmake_arena_intern_name(a, "Length", 6);
    pdfmake_dict_set(a, &d, k, pdfmake_int(ctx->key_length * 8));

    k = pdfmake_arena_intern_name(a, "P", 1);
    pdfmake_dict_set(a, &d, k, pdfmake_int((int64_t)(int32_t)ctx->P));

    /* O and U keys as hex strings — binary bytes survive unchanged.
     * (R2-R4: 32 bytes, R6: 48 bytes including salts.) */
    ou_len = (ctx->R == 6) ? 48 : 32;
    k = pdfmake_arena_intern_name(a, "O", 1);
    pdfmake_dict_set(a, &d, k, pdfmake_hexstr(a, ctx->O, ou_len));
    k = pdfmake_arena_intern_name(a, "U", 1);
    pdfmake_dict_set(a, &d, k, pdfmake_hexstr(a, ctx->U, ou_len));

    if (ctx->R == 6) {
        /* R6 extras: OE, UE, Perms (each 32/32/16 bytes) */
        k = pdfmake_arena_intern_name(a, "OE", 2);
        pdfmake_dict_set(a, &d, k, pdfmake_hexstr(a, ctx->OE, 32));
        k = pdfmake_arena_intern_name(a, "UE", 2);
        pdfmake_dict_set(a, &d, k, pdfmake_hexstr(a, ctx->UE, 32));
        k = pdfmake_arena_intern_name(a, "Perms", 5);
        pdfmake_dict_set(a, &d, k, pdfmake_hexstr(a, ctx->Perms, 16));
    }

    /* V=4/5 need /CF + /StmF + /StrF */
    if (ctx->V >= 4) {
        std_cf = pdfmake_dict_new(a);
        cfm_k  = pdfmake_arena_intern_name(a, "CFM",         3);
        len_k  = pdfmake_arena_intern_name(a, "Length",      6);
        auth_k = pdfmake_arena_intern_name(a, "AuthEvent",   9);
        type_k = pdfmake_arena_intern_name(a, "Type",        4);
        pdfmake_dict_set(a, &std_cf, type_k, pdfmake_name_cstr(a, "CryptFilter"));
        pdfmake_dict_set(a, &std_cf, cfm_k,
            pdfmake_name_cstr(a, ctx->V == 5 ? "AESV3" : "AESV2"));
        pdfmake_dict_set(a, &std_cf, auth_k, pdfmake_name_cstr(a, "DocOpen"));
        pdfmake_dict_set(a, &std_cf, len_k, pdfmake_int(ctx->key_length));

        cf = pdfmake_dict_new(a);
        stdcf_k = pdfmake_arena_intern_name(a, "StdCF", 5);
        pdfmake_dict_set(a, &cf, stdcf_k, std_cf);

        k = pdfmake_arena_intern_name(a, "CF", 2);
        pdfmake_dict_set(a, &d, k, cf);
        k = pdfmake_arena_intern_name(a, "StmF", 4);
        pdfmake_dict_set(a, &d, k, pdfmake_name_cstr(a, "StdCF"));
        k = pdfmake_arena_intern_name(a, "StrF", 4);
        pdfmake_dict_set(a, &d, k, pdfmake_name_cstr(a, "StdCF"));
    }

    num = pdfmake_doc_add(doc, d);
    if (num == 0) return PDFMAKE_ENOMEM;
    doc->encrypt_num = num;
    return PDFMAKE_OK;
}

/* Prepare encryption for write: generate ID if needed, allocate+setup the
 * crypt ctx, add the /Encrypt indirect dict. */
pdfmake_err_t pdfmake_doc_prepare_encryption(pdfmake_doc_t *doc) {
    if (!doc || !doc->enc_requested || doc->encrypt_num != 0) {
        return PDFMAKE_OK;
    }
    if (!doc->id_set) pdfmake_doc_generate_id(doc);

    doc->encryption = pdfmake_arena_calloc(doc->arena,
                                           sizeof(pdfmake_crypt_ctx_t));
    if (!doc->encryption) return PDFMAKE_ENOMEM;

    if (pdfmake_crypt_setup(doc->encryption, doc->enc_algo,
                            doc->enc_user_pw, doc->enc_owner_pw,
                            doc->enc_permissions,
                            doc->id1, 16) != 0) {
        return PDFMAKE_EINVAL;
    }

    return build_encrypt_dict(doc);
}

/*----------------------------------------------------------------------------
 * File emission - Header
 *--------------------------------------------------------------------------*/

static pdfmake_err_t emit_header(pdfmake_buf_t *out) {
    /*
     * §7.5.2: %PDF-x.y followed by a binary comment.
     * The binary comment ensures file transfer programs treat the file
     * as binary. It must contain at least 4 bytes, each >= 128.
     */
    return pdfmake_buf_append_cstr(out,
        "%PDF-" PDFMAKE_PDF_VERSION "\n"
        "%\xE2\xE3\xCF\xD3\n");
}

/*----------------------------------------------------------------------------
 * File emission - Body
 *--------------------------------------------------------------------------*/

static pdfmake_err_t emit_body(pdfmake_doc_t *doc, pdfmake_buf_t *out) {
    pdfmake_err_t err;
    const pdfmake_crypt_ctx_t *crypt =
        (doc->enc_requested && doc->encryption) ? doc->encryption : NULL;
    size_t i;
    pdfmake_indirect_t *ind;

    for (i = 0; i < doc->obj_count; i++) {
        ind = &doc->objects[i];
        if (!ind->in_use) continue;

        /* Record byte offset of this object */
        ind->byte_offset = out->len;

        /* Emit: N G obj\n */
        err = pdfmake_buf_appendf(out, "%u %u obj\n",
                                  (unsigned)ind->num, (unsigned)ind->gen);
        if (err != PDFMAKE_OK) return err;

        /* Emit the object value.  The /Encrypt dict itself must remain
         * plaintext (its strings are special-cased by the spec). */
        if (crypt) {
            int skip = (ind->num == doc->encrypt_num);
            err = pdfmake_write_obj_encrypted(out, doc->arena, crypt,
                                              ind->num, skip, &ind->obj);
        } else {
            err = pdfmake_write_obj(out, doc->arena, &ind->obj);
        }
        if (err != PDFMAKE_OK) return err;

        /* Emit: \nendobj\n */
        err = pdfmake_buf_append_cstr(out, "\nendobj\n");
        if (err != PDFMAKE_OK) return err;
    }

    return PDFMAKE_OK;
}

/*----------------------------------------------------------------------------
 * File emission - Cross-reference table
 *--------------------------------------------------------------------------*/

static pdfmake_err_t emit_xref(pdfmake_doc_t *doc, pdfmake_buf_t *out) {
    pdfmake_err_t err;
    size_t n_entries;
    size_t i;
    pdfmake_indirect_t *ind;
    char entry[21];

    /* Record xref offset for startxref */
    doc->xref_offset = out->len;

    /*
     * Classic xref table format (§7.5.4):
     *   xref
     *   0 N
     *   0000000000 65535 f 
     *   nnnnnnnnnn ggggg n 
     *   ...
     *
     * Each entry is exactly 20 bytes: 10-digit offset, space, 5-digit gen,
     * space, 'f' or 'n', space, newline (we use space + \n = 2 chars).
     * Actually the spec says "space or EOL" after the letter, and requires
     * exactly 20 bytes including the line terminator. We emit:
     *   "OOOOOOOOOO GGGGG X \n" (space before \n for Windows compat).
     */

    /* Number of entries = obj_count + 1 (for entry 0) */
    n_entries = doc->obj_count + 1;

    err = pdfmake_buf_appendf(out, "xref\n0 %zu\n", n_entries);
    if (err != PDFMAKE_OK) return err;

    /* Entry 0: head of free list, gen 65535 */
    err = pdfmake_buf_append_cstr(out, "0000000000 65535 f \n");
    if (err != PDFMAKE_OK) return err;

    /* Entries for each object */
    for (i = 0; i < doc->obj_count; i++) {
        ind = &doc->objects[i];

        if (ind->in_use) {
            snprintf(entry, sizeof(entry), "%010lu %05u n \n",
                     (unsigned long)ind->byte_offset,
                     (unsigned)ind->gen);
        } else {
            /* Free entry: offset points to next free (0 = end of list) */
            snprintf(entry, sizeof(entry), "%010u %05u f \n",
                     0, (unsigned)(ind->gen + 1));
        }

        err = pdfmake_buf_append(out, entry, 20);
        if (err != PDFMAKE_OK) return err;
    }

    return PDFMAKE_OK;
}

/*----------------------------------------------------------------------------
 * File emission - Trailer
 *--------------------------------------------------------------------------*/

static pdfmake_err_t emit_trailer(pdfmake_doc_t *doc, pdfmake_buf_t *out) {
    pdfmake_err_t err;
    int i;

    /* Generate ID if not already done */
    if (!doc->id_set) {
        pdfmake_doc_generate_id(doc);
    }

    err = pdfmake_buf_append_cstr(out, "trailer\n<<");
    if (err != PDFMAKE_OK) return err;

    /* /Size: total number of entries in xref (obj_count + 1) */
    err = pdfmake_buf_appendf(out, "/Size %zu", doc->obj_count + 1);
    if (err != PDFMAKE_OK) return err;

    /* /Root: required reference to document catalog */
    if (doc->root_num > 0) {
        err = pdfmake_buf_appendf(out, "/Root %u %u R",
                                  (unsigned)doc->root_num,
                                  (unsigned)doc->root_gen);
        if (err != PDFMAKE_OK) return err;
    }

    /* /Info: optional reference to info dictionary */
    if (doc->info_num > 0) {
        err = pdfmake_buf_appendf(out, "/Info %u %u R",
                                  (unsigned)doc->info_num,
                                  (unsigned)doc->info_gen);
        if (err != PDFMAKE_OK) return err;
    }

    /* /Encrypt: reference to the Standard security handler dict */
    if (doc->encrypt_num > 0) {
        err = pdfmake_buf_appendf(out, "/Encrypt %u 0 R",
                                  (unsigned)doc->encrypt_num);
        if (err != PDFMAKE_OK) return err;
    }

    /* /ID: array of two byte strings */
    err = pdfmake_buf_append_cstr(out, "/ID[<");
    if (err != PDFMAKE_OK) return err;

    /* Emit id1 as hex */
    for (i = 0; i < 16; i++) {
        err = pdfmake_buf_appendf(out, "%02X", doc->id1[i]);
        if (err != PDFMAKE_OK) return err;
    }

    err = pdfmake_buf_append_cstr(out, "><");
    if (err != PDFMAKE_OK) return err;

    /* Emit id2 as hex */
    for (i = 0; i < 16; i++) {
        err = pdfmake_buf_appendf(out, "%02X", doc->id2[i]);
        if (err != PDFMAKE_OK) return err;
    }

    err = pdfmake_buf_append_cstr(out, ">]");
    if (err != PDFMAKE_OK) return err;

    /* Close trailer dict */
    err = pdfmake_buf_append_cstr(out, ">>\n");
    if (err != PDFMAKE_OK) return err;

    /* startxref */
    err = pdfmake_buf_appendf(out, "startxref\n%lu\n",
                              (unsigned long)doc->xref_offset);
    if (err != PDFMAKE_OK) return err;

    /* %%EOF */
    err = pdfmake_buf_append_cstr(out, "%%EOF\n");
    if (err != PDFMAKE_OK) return err;

    return PDFMAKE_OK;
}

/*----------------------------------------------------------------------------
 * File emission - Main entry point
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_doc_write(pdfmake_doc_t *doc, pdfmake_buf_t *out) {
    pdfmake_err_t err;
    if (!doc || !out) return PDFMAKE_EINVAL;

    /* 0a. Finalize document structure if not already done */
    if (doc->page_count > 0 && !doc->finalized) {
        err = pdfmake_doc_finalize(doc);
        if (err != PDFMAKE_OK) return err;
    }

    /* 0b. Auto-fill metadata (Producer, CreationDate, ModDate) */
    pdfmake_meta_auto_fill(doc);

    /* 0c. Materialize encryption ctx + /Encrypt dict (no-op if no
     * encryption was requested).  Must happen after all other indirects
     * are in place so obj numbers for real content don't collide with
     * the encrypt dict's number. */
    err = pdfmake_doc_prepare_encryption(doc);
    if (err != PDFMAKE_OK) return err;

    /* 1. Header */
    err = emit_header(out);
    if (err != PDFMAKE_OK) return err;

    /* 2. Body (indirect objects) */
    err = emit_body(doc, out);
    if (err != PDFMAKE_OK) return err;

    /* 3. Cross-reference table */
    err = emit_xref(doc, out);
    if (err != PDFMAKE_OK) return err;

    /* 4. Trailer */
    err = emit_trailer(doc, out);
    if (err != PDFMAKE_OK) return err;

    return PDFMAKE_OK;
}
