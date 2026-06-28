/*
 * pdfmake_attach.c — File attachments and embedded files.
 *
 * §7.11.3 File Specification Dictionaries
 * §7.11.4 Embedded File Streams
 * §14.13  Embedded Files
 */

#include "pdfmake_attach.h"
#include "pdfmake_arena.h"
#include "pdfmake_filter.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* ── MIME type guessing from filename extension ─────────── */

static const char *_guess_mime(const char *filename) {
    const char *dot = strrchr(filename, '.');
    if (!dot) return "application/octet-stream";
    dot++;
    if (strcasecmp(dot, "pdf")  == 0) return "application/pdf";
    if (strcasecmp(dot, "txt")  == 0) return "text/plain";
    if (strcasecmp(dot, "html") == 0) return "text/html";
    if (strcasecmp(dot, "htm")  == 0) return "text/html";
    if (strcasecmp(dot, "xml")  == 0) return "application/xml";
    if (strcasecmp(dot, "json") == 0) return "application/json";
    if (strcasecmp(dot, "csv")  == 0) return "text/csv";
    if (strcasecmp(dot, "jpg")  == 0) return "image/jpeg";
    if (strcasecmp(dot, "jpeg") == 0) return "image/jpeg";
    if (strcasecmp(dot, "png")  == 0) return "image/png";
    if (strcasecmp(dot, "gif")  == 0) return "image/gif";
    if (strcasecmp(dot, "svg")  == 0) return "image/svg+xml";
    if (strcasecmp(dot, "zip")  == 0) return "application/zip";
    if (strcasecmp(dot, "xlsx") == 0) return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
    if (strcasecmp(dot, "docx") == 0) return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
    return "application/octet-stream";
}

/* ── Create ────────────────────────────────────────────── */

pdfmake_attachment_t *pdfmake_doc_attach(
    pdfmake_doc_t *doc,
    const char *name,
    const char *filename,
    const uint8_t *data, size_t len,
    const char *mime_type,
    const char *description)
{
    size_t new_cap;
    void **new_arr;
    pdfmake_attachment_t *att;

    if (!doc || !name || !data) return NULL;

    if (doc->attach_count >= doc->attach_cap) {
        new_cap = doc->attach_cap == 0 ? 4 : doc->attach_cap * 2;
        new_arr = realloc(doc->attachments, new_cap * sizeof(void *));
        if (!new_arr) return NULL;
        doc->attachments = new_arr;
        doc->attach_cap = new_cap;
    }

    att = calloc(1, sizeof(pdfmake_attachment_t));
    if (!att) return NULL;

    strncpy(att->name, name, sizeof(att->name) - 1);
    strncpy(att->filename, filename ? filename : name, sizeof(att->filename) - 1);

    if (mime_type) {
        strncpy(att->mime_type, mime_type, sizeof(att->mime_type) - 1);
    } else {
        strncpy(att->mime_type, _guess_mime(att->filename), sizeof(att->mime_type) - 1);
    }

    if (description) {
        strncpy(att->description, description, sizeof(att->description) - 1);
    }

    att->data = malloc(len);
    if (!att->data) { free(att); return NULL; }
    memcpy(att->data, data, len);
    att->data_len = len;

    doc->attachments[doc->attach_count++] = att;
    return att;
}

pdfmake_attachment_t *pdfmake_doc_attach_file(
    pdfmake_doc_t *doc,
    const char *name,
    const char *path)
{
    FILE *fp;
    long file_len;
    uint8_t *buf;
    size_t nread;
    const char *slash;
    const char *bslash;
    const char *fname;
    pdfmake_attachment_t *att;

    if (!doc || !name || !path) return NULL;

    fp = fopen(path, "rb");
    if (!fp) return NULL;

    fseek(fp, 0, SEEK_END);
    file_len = ftell(fp);
    if (file_len < 0) { fclose(fp); return NULL; }
    rewind(fp);

    buf = malloc((size_t)file_len);
    if (!buf) { fclose(fp); return NULL; }

    nread = fread(buf, 1, (size_t)file_len, fp);
    fclose(fp);

    if ((long)nread != file_len) { free(buf); return NULL; }

    /* Extract filename from path */
    slash = strrchr(path, '/');
    bslash = strrchr(path, '\\');
    fname = path;
    if (slash && slash > fname) fname = slash + 1;
    if (bslash && bslash > fname) fname = bslash + 1;

    att = pdfmake_doc_attach(doc, name, fname,
        buf, (size_t)file_len, NULL, NULL);
    free(buf);
    return att;
}

/* ── Query ─────────────────────────────────────────────── */

size_t pdfmake_doc_attachment_count(pdfmake_doc_t *doc) {
    return doc ? doc->attach_count : 0;
}

pdfmake_attachment_t *pdfmake_doc_attachment_at(pdfmake_doc_t *doc, size_t idx) {
    if (!doc || idx >= doc->attach_count) return NULL;
    return (pdfmake_attachment_t *)doc->attachments[idx];
}

pdfmake_attachment_t *pdfmake_doc_attachment_by_name(pdfmake_doc_t *doc, const char *name) {
    size_t i;
    pdfmake_attachment_t *att;

    if (!doc || !name) return NULL;
    for (i = 0; i < doc->attach_count; i++) {
        att = (pdfmake_attachment_t *)doc->attachments[i];
        if (strcmp(att->name, name) == 0) return att;
    }
    return NULL;
}

/* ── Properties ────────────────────────────────────────── */

const char *pdfmake_attachment_name(pdfmake_attachment_t *att) {
    return att ? att->name : NULL;
}
const char *pdfmake_attachment_filename(pdfmake_attachment_t *att) {
    return att ? att->filename : NULL;
}
const char *pdfmake_attachment_mime_type(pdfmake_attachment_t *att) {
    return att ? att->mime_type : NULL;
}
size_t pdfmake_attachment_size(pdfmake_attachment_t *att) {
    return att ? att->data_len : 0;
}

/* ── Extract ───────────────────────────────────────────── */

const uint8_t *pdfmake_attachment_data(pdfmake_attachment_t *att, size_t *out_len) {
    if (!att) { if (out_len) *out_len = 0; return NULL; }
    if (out_len) *out_len = att->data_len;
    return att->data;
}

pdfmake_err_t pdfmake_attachment_extract_to_file(pdfmake_attachment_t *att, const char *path) {
    FILE *fp;
    size_t written;

    if (!att || !path || !att->data) return PDFMAKE_EINVAL;
    fp = fopen(path, "wb");
    if (!fp) return PDFMAKE_EINVAL;
    written = fwrite(att->data, 1, att->data_len, fp);
    fclose(fp);
    return (written == att->data_len) ? PDFMAKE_OK : PDFMAKE_EINVAL;
}

/* ── Write ─────────────────────────────────────────────── */

uint32_t pdfmake_attachment_write(pdfmake_attachment_t *att, pdfmake_doc_t *doc) {
    pdfmake_arena_t *arena;
    uint32_t k;
    pdfmake_buf_t compressed;
    pdfmake_flate_params_t params;
    int use_flate;
    pdfmake_obj_t ef_stream;
    pdfmake_obj_t ef_dict_obj;
    char encoded[256];
    size_t ei;
    size_t i;
    pdfmake_obj_t ef_params;
    pdfmake_obj_t fs;
    pdfmake_obj_t ef_dict;
    pdfmake_obj_t ef_ref;

    if (!att || !doc || !att->data) return 0;
    if (att->fs_obj_num) return att->fs_obj_num;

    arena = pdfmake_doc_arena(doc);

    /* Compress data with FlateDecode */
    pdfmake_buf_init(&compressed);
    memset(&params, 0, sizeof(params));
    params.predictor = 1;
    use_flate = (pdfmake_flate_encode(att->data, att->data_len, &params, &compressed) == PDFMAKE_OK);

    /* Create embedded file stream */
    ef_stream = pdfmake_stream_new(arena);
    if (ef_stream.kind != PDFMAKE_STREAM) {
        pdfmake_buf_free(&compressed);
        return 0;
    }

    if (use_flate && compressed.len < att->data_len) {
        pdfmake_stream_set_data(arena, &ef_stream, compressed.data, compressed.len);
    } else {
        pdfmake_stream_set_data(arena, &ef_stream, att->data, att->data_len);
        use_flate = 0;
    }

    /* Set stream dict entries */
    ef_dict_obj.kind = PDFMAKE_DICT;
    ef_dict_obj.as.dict = pdfmake_stream_dict(&ef_stream);

    k = pdfmake_arena_intern_name(arena, "Type", 4);
    pdfmake_dict_set(arena, &ef_dict_obj, k, pdfmake_name_cstr(arena, "EmbeddedFile"));

    /* MIME subtype: encode / as #2F per PDF spec */
    if (att->mime_type[0]) {
        ei = 0;
        for (i = 0; att->mime_type[i] && ei < sizeof(encoded) - 4; i++) {
            if (att->mime_type[i] == '/') {
                encoded[ei++] = '#'; encoded[ei++] = '2'; encoded[ei++] = 'F';
            } else {
                encoded[ei++] = att->mime_type[i];
            }
        }
        encoded[ei] = '\0';
        k = pdfmake_arena_intern_name(arena, "Subtype", 7);
        pdfmake_dict_set(arena, &ef_dict_obj, k, pdfmake_name(arena, encoded, ei));
    }

    if (use_flate) {
        k = pdfmake_arena_intern_name(arena, "Filter", 6);
        pdfmake_dict_set(arena, &ef_dict_obj, k, pdfmake_name_cstr(arena, "FlateDecode"));
    }

    /* Params */
    ef_params = pdfmake_dict_new(arena);
    k = pdfmake_arena_intern_name(arena, "Size", 4);
    pdfmake_dict_set(arena, &ef_params, k, pdfmake_int((int64_t)att->data_len));
    k = pdfmake_arena_intern_name(arena, "Params", 6);
    pdfmake_dict_set(arena, &ef_dict_obj, k, ef_params);

    k = pdfmake_arena_intern_name(arena, "Length", 6);
    pdfmake_dict_set(arena, &ef_dict_obj, k,
        pdfmake_int((int64_t)(use_flate ? compressed.len : att->data_len)));

    att->ef_obj_num = pdfmake_doc_add(doc, ef_stream);
    pdfmake_buf_free(&compressed);
    if (att->ef_obj_num == 0) return 0;

    /* Create Filespec dictionary */
    fs = pdfmake_dict_new(arena);
    k = pdfmake_arena_intern_name(arena, "Type", 4);
    pdfmake_dict_set(arena, &fs, k, pdfmake_name_cstr(arena, "Filespec"));

    k = pdfmake_arena_intern_name(arena, "F", 1);
    pdfmake_dict_set(arena, &fs, k, pdfmake_str_cstr(arena, att->filename));

    k = pdfmake_arena_intern_name(arena, "UF", 2);
    pdfmake_dict_set(arena, &fs, k, pdfmake_str_cstr(arena, att->filename));

    if (att->description[0]) {
        k = pdfmake_arena_intern_name(arena, "Desc", 4);
        pdfmake_dict_set(arena, &fs, k, pdfmake_str_cstr(arena, att->description));
    }

    /* /EF << /F ref /UF ref >> */
    ef_dict = pdfmake_dict_new(arena);
    ef_ref = pdfmake_ref(att->ef_obj_num, 0);
    k = pdfmake_arena_intern_name(arena, "F", 1);
    pdfmake_dict_set(arena, &ef_dict, k, ef_ref);
    k = pdfmake_arena_intern_name(arena, "UF", 2);
    pdfmake_dict_set(arena, &ef_dict, k, ef_ref);
    k = pdfmake_arena_intern_name(arena, "EF", 2);
    pdfmake_dict_set(arena, &fs, k, ef_dict);

    /* AFRelationship */
    k = pdfmake_arena_intern_name(arena, "AFRelationship", 14);
    pdfmake_dict_set(arena, &fs, k, pdfmake_name_cstr(arena, "Data"));

    att->fs_obj_num = pdfmake_doc_add(doc, fs);
    return att->fs_obj_num;
}

/* ── Write /Names/EmbeddedFiles into catalog ───────────── */

pdfmake_err_t pdfmake_doc_write_attachments(pdfmake_doc_t *doc) {
    pdfmake_arena_t *arena;
    uint32_t k;
    size_t i;
    pdfmake_attachment_t *att;
    pdfmake_obj_t names_arr;
    pdfmake_obj_t ef_tree;
    pdfmake_obj_t names_dict;
    pdfmake_obj_t *catalog;

    if (!doc || doc->attach_count == 0) return PDFMAKE_OK;

    arena = pdfmake_doc_arena(doc);

    /* Ensure all attachments are written */
    for (i = 0; i < doc->attach_count; i++) {
        att = (pdfmake_attachment_t *)doc->attachments[i];
        if (!att->fs_obj_num) {
            if (pdfmake_attachment_write(att, doc) == 0)
                return PDFMAKE_ENOMEM;
        }
    }

    /* Build /Names array: [(name1) ref1 (name2) ref2 ...] */
    names_arr = pdfmake_array_new(arena);
    for (i = 0; i < doc->attach_count; i++) {
        att = (pdfmake_attachment_t *)doc->attachments[i];
        pdfmake_array_push(arena, &names_arr,
            pdfmake_str_cstr(arena, att->name));
        pdfmake_array_push(arena, &names_arr,
            pdfmake_ref(att->fs_obj_num, 0));
    }

    /* /EmbeddedFiles << /Names [...] >> */
    ef_tree = pdfmake_dict_new(arena);
    k = pdfmake_arena_intern_name(arena, "Names", 5);
    pdfmake_dict_set(arena, &ef_tree, k, names_arr);

    /* /Names << /EmbeddedFiles ... >> */
    names_dict = pdfmake_dict_new(arena);
    k = pdfmake_arena_intern_name(arena, "EmbeddedFiles", 13);
    pdfmake_dict_set(arena, &names_dict, k, ef_tree);

    /* Add to catalog */
    catalog = pdfmake_doc_get(doc, doc->root_num);
    if (!catalog || catalog->kind != PDFMAKE_DICT) return PDFMAKE_EINVAL;

    k = pdfmake_arena_intern_name(arena, "Names", 5);
    pdfmake_dict_set(arena, catalog, k, names_dict);

    return PDFMAKE_OK;
}
