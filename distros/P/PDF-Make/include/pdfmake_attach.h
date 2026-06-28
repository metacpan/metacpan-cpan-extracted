/*
 * pdfmake_attach.h — File attachments and embedded files.
 *
 * §7.11.3 File Specification Dictionaries
 * §7.11.4 Embedded File Streams
 * §14.13  Embedded Files
 */

#ifndef PDFMAKE_ATTACH_H
#define PDFMAKE_ATTACH_H

#include "pdfmake_types.h"
#include "pdfmake_doc.h"
#include "pdfmake_buf.h"

#ifdef __cplusplus
extern "C" {
#endif

#define PDFMAKE_MAX_ATTACHMENTS 64

/* Attachment structure */
typedef struct pdfmake_attachment {
    char         name[256];       /* Display/key name */
    char         filename[256];   /* Original filename */
    char         mime_type[128];  /* MIME type (e.g. "application/pdf") */
    char         description[256];/* Description */
    uint8_t     *data;            /* File data (owned, malloc'd) */
    size_t       data_len;
    uint32_t     ef_obj_num;      /* Embedded file stream object number */
    uint32_t     fs_obj_num;      /* Filespec dictionary object number */
} pdfmake_attachment_t;

/* ── Create ────────────────────────────────────────────── */

/* Attach file data to document. Data is copied. */
pdfmake_attachment_t *pdfmake_doc_attach(
    pdfmake_doc_t *doc,
    const char *name,
    const char *filename,
    const uint8_t *data, size_t len,
    const char *mime_type,        /* NULL for auto */
    const char *description       /* NULL for none */
);

/* Attach from file path. */
pdfmake_attachment_t *pdfmake_doc_attach_file(
    pdfmake_doc_t *doc,
    const char *name,
    const char *path
);

/* ── Query ─────────────────────────────────────────────── */

size_t pdfmake_doc_attachment_count(pdfmake_doc_t *doc);
pdfmake_attachment_t *pdfmake_doc_attachment_at(pdfmake_doc_t *doc, size_t idx);
pdfmake_attachment_t *pdfmake_doc_attachment_by_name(pdfmake_doc_t *doc, const char *name);

/* ── Properties ────────────────────────────────────────── */

const char *pdfmake_attachment_name(pdfmake_attachment_t *att);
const char *pdfmake_attachment_filename(pdfmake_attachment_t *att);
const char *pdfmake_attachment_mime_type(pdfmake_attachment_t *att);
size_t pdfmake_attachment_size(pdfmake_attachment_t *att);

/* ── Extract ───────────────────────────────────────────── */

/* Get raw data pointer (owned by attachment, do not free). */
const uint8_t *pdfmake_attachment_data(pdfmake_attachment_t *att, size_t *out_len);

/* Extract to file. */
pdfmake_err_t pdfmake_attachment_extract_to_file(pdfmake_attachment_t *att, const char *path);

/* ── Write ─────────────────────────────────────────────── */

/* Write embedded file stream + filespec dict. Returns filespec obj_num. */
uint32_t pdfmake_attachment_write(pdfmake_attachment_t *att, pdfmake_doc_t *doc);

/* Write /Names/EmbeddedFiles into catalog. Called by finalize. */
pdfmake_err_t pdfmake_doc_write_attachments(pdfmake_doc_t *doc);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_ATTACH_H */
