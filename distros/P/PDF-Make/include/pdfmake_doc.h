/*
 * pdfmake_doc.h — PDF document structure and file emission.
 *
 * A pdfmake_doc_t owns an arena, a table of indirect objects, and
 * references for the trailer dictionary (Root, Info, ID). The
 * pdfmake_doc_write() function emits a complete PDF file:
 *   - %PDF-2.0 header with binary comment
 *   - Body of indirect objects (N G obj ... endobj)
 *   - Classic cross-reference table
 *   - Trailer dictionary with startxref and %%EOF
 */

#ifndef PDFMAKE_DOC_H
#define PDFMAKE_DOC_H

#include "pdfmake_types.h"
#include "pdfmake_arena.h"
#include "pdfmake_buf.h"
#include "pdfmake_crypt.h"

#ifdef __cplusplus
extern "C" {
#endif

/*----------------------------------------------------------------------------
 * Indirect object entry
 *--------------------------------------------------------------------------*/

typedef struct pdfmake_indirect {
    uint32_t       num;         /* Object number (1-based) */
    uint16_t       gen;         /* Generation number (usually 0) */
    uint64_t       byte_offset; /* Byte offset of 'N G obj' in output */
    pdfmake_obj_t  obj;         /* The object value */
    int            in_use;      /* 1 if active, 0 if free */
} pdfmake_indirect_t;

/*----------------------------------------------------------------------------
 * Forward declarations
 *--------------------------------------------------------------------------*/

typedef struct pdfmake_page pdfmake_page_t;

/*----------------------------------------------------------------------------
 * Document structure
 *--------------------------------------------------------------------------*/

struct pdfmake_doc {
    pdfmake_arena_t     *arena;       /* Owns all object allocations */

    /* Indirect object table */
    pdfmake_indirect_t  *objects;     /* Dynamic array of indirect objects */
    size_t               obj_count;   /* Number of objects in use */
    size_t               obj_cap;     /* Allocated capacity */

    /* Trailer references */
    uint32_t             root_num;    /* /Root object number (Catalog) */
    uint16_t             root_gen;
    uint32_t             info_num;    /* /Info object number (optional) */
    uint16_t             info_gen;

    /* Page tree */
    pdfmake_page_t     **pages;       /* Array of page pointers */
    size_t               page_count;  /* Number of pages */
    size_t               page_cap;    /* Allocated capacity */
    uint32_t             pages_num;   /* /Pages object number */
    int                  finalized;   /* Has finalize been called? */

    /* File identifiers for /ID array */
    uint8_t              id1[16];     /* Creation ID */
    uint8_t              id2[16];     /* Modification ID */
    int                  id_set;      /* Have IDs been generated? */

    /* Internal state for emission */
    uint64_t             xref_offset; /* Byte offset of xref keyword */
    
    /* Extension data (forms, outlines, etc.) */
    void                *form_data;     /* Form storage - owned by arena */
    void                *outline_root;  /* Outline root item - owned by arena */

    /* Optional Content Groups (layers) */
    void               **ocgs;        /* Array of pdfmake_ocg_t pointers */
    size_t               ocg_count;
    size_t               ocg_cap;

    /* Attachments */
    void               **attachments;
    size_t               attach_count;
    size_t               attach_cap;

    /* Structure tree (tagged PDF) */
    void                *struct_tree;

    /* Signature-preparation cache.  pdfmake_doc_sign populates these the
     * first time it runs so subsequent calls (used by the Perl two-pass
     * TSA flow) can find the existing widget + reserved sig object number
     * instead of re-adding new ones. */
    uint32_t             sig_widget_num;
    uint32_t             sig_obj_num_reserved;
    /* Visible-signature state, captured in pass 1 so the pass-2 re-emit of
     * the widget during the incremental update can reproduce /Rect, /AP,
     * and /P without having to re-parse the cached widget dict. */
    uint32_t             sig_ap_num;        /* Form XObject obj num, 0 if invisible */
    uint32_t             sig_page_num;      /* containing page indirect, 0 if invisible */
    int                  sig_visible;       /* 1 if the widget is visible */
    double               sig_rect[4];       /* llx lly urx ury — valid when sig_visible */

    /* Encryption — pdfmake_doc_set_encryption() populates the request; the
     * key derivation and /Encrypt dict are created during finalize, using
     * the document /ID that is generated beforehand. */
    int                     enc_requested;     /* 1 if encryption was requested */
    pdfmake_crypt_algo_t    enc_algo;
    char                   *enc_user_pw;       /* arena-copied */
    char                   *enc_owner_pw;      /* arena-copied, may alias user */
    int32_t                 enc_permissions;
    pdfmake_crypt_ctx_t    *encryption;        /* arena-allocated context */
    uint32_t                encrypt_num;       /* object number of /Encrypt dict (0 if none) */
};

/*----------------------------------------------------------------------------
 * Lifecycle
 *--------------------------------------------------------------------------*/

/* Create a new empty document. */
pdfmake_doc_t *pdfmake_doc_new(void);

/* Free the document and all owned resources. */
void pdfmake_doc_free(pdfmake_doc_t *doc);

/* Get the document's arena (for creating objects). */
pdfmake_arena_t *pdfmake_doc_arena(pdfmake_doc_t *doc);

/*----------------------------------------------------------------------------
 * Indirect object management
 *--------------------------------------------------------------------------*/

/*
 * Add an object to the document as an indirect object.
 * Returns the object number (1-based), or 0 on error.
 * The generation is always 0 for new objects.
 */
uint32_t pdfmake_doc_add(pdfmake_doc_t *doc, pdfmake_obj_t obj);

/*
 * Get an indirect object by number.
 * Returns NULL if not found or deleted.
 */
pdfmake_obj_t *pdfmake_doc_get(pdfmake_doc_t *doc, uint32_t num);

/*
 * Create a reference to an indirect object.
 * Shorthand for pdfmake_ref(num, 0).
 */
pdfmake_obj_t pdfmake_doc_ref(pdfmake_doc_t *doc, uint32_t num);

/*----------------------------------------------------------------------------
 * Trailer setup
 *--------------------------------------------------------------------------*/

/* Set the /Root reference (required - document catalog). */
void pdfmake_doc_set_root(pdfmake_doc_t *doc, uint32_t num, uint16_t gen);

/* Set the /Info reference (optional - document information dictionary). */
void pdfmake_doc_set_info(pdfmake_doc_t *doc, uint32_t num, uint16_t gen);

/* Generate /ID array using FNV-1a hash. Called automatically by write. */
void pdfmake_doc_generate_id(pdfmake_doc_t *doc);

/*
 * Request password-based encryption for the document.  Stores the algorithm
 * and passwords; the key derivation, /Encrypt dict creation, and per-object
 * encryption happen during pdfmake_doc_write.
 *
 * @param algorithm       RC4-40 | RC4-128 | AES-128 | AES-256
 * @param user_passwd     user open password (may be "")
 * @param owner_passwd    owner password (NULL → user password is used)
 * @param permissions     PDFMAKE_PERM_* flags (0xFFFFFFFC = all allowed)
 *
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_doc_set_encryption(pdfmake_doc_t *doc,
                                         pdfmake_crypt_algo_t algorithm,
                                         const char *user_passwd,
                                         const char *owner_passwd,
                                         int32_t permissions);

/*
 * Materialize the encryption context and the /Encrypt indirect dict.
 * Called by pdfmake_doc_write; safe to call twice (no-op on second call).
 */
pdfmake_err_t pdfmake_doc_prepare_encryption(pdfmake_doc_t *doc);

/*----------------------------------------------------------------------------
 * File emission
 *--------------------------------------------------------------------------*/

/*
 * Write a complete PDF file to the buffer.
 * Emits: header, body, xref table, trailer, startxref, %%EOF.
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_doc_write(pdfmake_doc_t *doc, pdfmake_buf_t *out);

/*----------------------------------------------------------------------------
 * Constants
 *--------------------------------------------------------------------------*/

/* PDF version we emit. */
#define PDFMAKE_PDF_VERSION "2.0"

/* Initial capacity for indirect object table. */
#define PDFMAKE_DOC_INIT_CAP 64

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_DOC_H */
