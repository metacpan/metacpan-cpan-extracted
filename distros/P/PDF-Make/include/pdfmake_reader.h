/*
 * pdfmake_reader.h — Document reader (pages + resources)
 *
 * Given a parsed pdfmake_doc_t, exposes the high-level shape:
 *   - Page tree enumeration (flattened)
 *   - Per-page media box, crop box, rotation
 *   - Per-page resources (fonts, images) with inheritance
 *   - Content stream extraction (decompressed)
 *
 * References:
 *   - §7.7.2 Document catalog
 *   - §7.7.3 Page tree (esp. §7.7.3.4 inheritable attributes)
 *   - §7.8 Content streams and resources
 *   - §14.11.2 Page boundaries (MediaBox, CropBox, etc.)
 */

#ifndef PDFMAKE_READER_H
#define PDFMAKE_READER_H

#include "pdfmake_types.h"
#include "pdfmake_doc.h"
#include "pdfmake_buf.h"
#include "pdfmake_crypt.h"

#ifdef __cplusplus
extern "C" {
#endif

/*----------------------------------------------------------------------------
 * Reader error codes
 *--------------------------------------------------------------------------*/

#define PDFMAKE_EREADER      30   /* Generic reader error */
#define PDFMAKE_ENOROOT      31   /* Missing /Root in trailer */
#define PDFMAKE_ENOPAGES     32   /* Missing /Pages in catalog */
#define PDFMAKE_ECYCLE_PAGE  33   /* Cycle detected in page tree */
#define PDFMAKE_EBADPAGE     34   /* Invalid page node */
#define PDFMAKE_ENOMEDIABOX  35   /* No MediaBox found */

/*----------------------------------------------------------------------------
 * Reader page handle
 *--------------------------------------------------------------------------*/

/*
 * Opaque page handle for reader operations.
 * Valid for the lifetime of the pdfmake_reader_t.
 */
typedef struct pdfmake_reader_page {
    pdfmake_obj_t      *page_dict;      /* Page dictionary object */
    pdfmake_obj_t      *resources;      /* Merged resources (lazily resolved) */
    double              media_box[4];   /* [llx, lly, urx, ury] */
    double              crop_box[4];    /* Falls back to MediaBox */
    int                 rotation;       /* 0, 90, 180, or 270 */
    uint8_t             media_box_set;  /* 1 if MediaBox resolved */
    uint8_t             crop_box_set;   /* 1 if CropBox resolved */
    uint8_t             rotation_set;   /* 1 if Rotate resolved */
    uint8_t             resources_set;  /* 1 if Resources merged */
} pdfmake_reader_page_t;

/*----------------------------------------------------------------------------
 * Reader context
 *--------------------------------------------------------------------------*/

/*
 * Reader context — holds parsed document and flattened page list.
 * Created from a parsed pdfmake_parser_t.
 */
typedef struct pdfmake_reader {
    /* Parsed document (not owned) */
    struct pdfmake_parser   *parser;
    pdfmake_doc_t           *doc;
    
    /* Catalog dictionary */
    pdfmake_obj_t           *catalog;
    
    /* Flattened page list */
    pdfmake_reader_page_t   *pages;
    size_t                   page_count;
    size_t                   page_cap;
    
    /* Arena for reader allocations */
    pdfmake_arena_t         *arena;

    /* Decryption context (NULL if document is not encrypted) */
    pdfmake_crypt_ctx_t     *crypt;
    uint8_t                  encrypted;    /* 1 if /Encrypt present */
    uint8_t                  authenticated; /* 1 if password accepted */

    /* Error state */
    pdfmake_err_t            last_err;
    char                     err_msg[256];
} pdfmake_reader_t;

/*----------------------------------------------------------------------------
 * Reader lifecycle
 *--------------------------------------------------------------------------*/

/*
 * Create a reader from a parsed document.
 * The parser must remain valid for the lifetime of the reader.
 * Returns NULL on allocation failure.
 */
pdfmake_reader_t *pdfmake_reader_new(struct pdfmake_parser *parser);

/*
 * Free the reader and all owned resources.
 * Does NOT free the parser or document.
 */
void pdfmake_reader_free(pdfmake_reader_t *reader);

/*
 * Initialize the reader by building the page tree.
 * Must be called after pdfmake_reader_new and before accessing pages.
 * If the document is encrypted, attempts empty-password authentication.
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_reader_init(pdfmake_reader_t *reader);

/*
 * Set password for an encrypted document.
 * Must be called after init if the document requires a non-empty password.
 * Returns 1 if owner, 0 if user, -1 if authentication failed.
 */
int pdfmake_reader_set_password(pdfmake_reader_t *reader, const char *password);

/*
 * Check if the document is encrypted.
 */
int pdfmake_reader_is_encrypted(pdfmake_reader_t *reader);

/*
 * Check if the reader has been authenticated (can read content).
 */
int pdfmake_reader_is_authenticated(pdfmake_reader_t *reader);

/*
 * Get error message for last reader failure.
 */
const char *pdfmake_reader_errmsg(pdfmake_reader_t *reader);

/*----------------------------------------------------------------------------
 * Page enumeration
 *--------------------------------------------------------------------------*/

/*
 * Get the number of pages in the document.
 */
size_t pdfmake_reader_page_count(pdfmake_reader_t *reader);

/*
 * Get a page by index (0-based).
 * Returns NULL if index out of bounds.
 * The returned pointer is valid for the lifetime of the reader.
 */
pdfmake_reader_page_t *pdfmake_reader_page_at(pdfmake_reader_t *reader, size_t idx);

/*----------------------------------------------------------------------------
 * Page attributes
 *--------------------------------------------------------------------------*/

/*
 * Get the page's MediaBox.
 * out[4] receives [llx, lly, urx, ury].
 * Returns PDFMAKE_OK on success, PDFMAKE_ENOMEDIABOX if not found.
 */
pdfmake_err_t pdfmake_reader_page_media_box(pdfmake_reader_t *reader,
                                             pdfmake_reader_page_t *page,
                                             double out[4]);

/*
 * Get the page's CropBox.
 * Falls back to MediaBox if CropBox not specified.
 * out[4] receives [llx, lly, urx, ury].
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_reader_page_crop_box(pdfmake_reader_t *reader,
                                            pdfmake_reader_page_t *page,
                                            double out[4]);

/*
 * Get the page's rotation.
 * Returns 0, 90, 180, or 270 degrees.
 * Returns 0 if /Rotate not specified.
 */
int pdfmake_reader_page_rotation(pdfmake_reader_t *reader,
                                  pdfmake_reader_page_t *page);

/*
 * Get the page's merged Resources dictionary.
 * Includes inherited resources from parent pages nodes (§7.7.3.4).
 * Returns the dict object, or NULL if no resources.
 */
pdfmake_obj_t *pdfmake_reader_page_resources(pdfmake_reader_t *reader,
                                              pdfmake_reader_page_t *page);

/*----------------------------------------------------------------------------
 * Content stream extraction
 *--------------------------------------------------------------------------*/

/*
 * Get the page's content stream bytes.
 * Handles both single stream and array of streams.
 * Concatenates multiple streams with whitespace separator.
 * Decompresses using the filter chain (FlateDecode, etc.).
 * 
 * out     - Buffer to receive decompressed content bytes.
 *           Must be initialized with pdfmake_buf_init().
 *           Caller is responsible for freeing with pdfmake_buf_free().
 *
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_reader_page_content_bytes(pdfmake_reader_t *reader,
                                                 pdfmake_reader_page_t *page,
                                                 pdfmake_buf_t *out);

/*
 * Decrypt (if needed) and decompress an arbitrary stream object resolved
 * by object number. Used to fetch /ToUnicode, /FontFile, etc.
 *
 * obj_num - indirect object number (must be a stream).
 * out     - buffer to receive decoded bytes. Caller frees with pdfmake_buf_free().
 *
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_reader_resolve_stream(pdfmake_reader_t *reader,
                                             uint32_t obj_num,
                                             uint16_t gen,
                                             pdfmake_buf_t *out);

/*----------------------------------------------------------------------------
 * Internal helpers (exposed for testing)
 *--------------------------------------------------------------------------*/

/*
 * Flatten the page tree into an array of leaf pages.
 * Handles arbitrary nesting with cycle detection.
 * Internal use; called by pdfmake_reader_init().
 */
pdfmake_err_t pdfmake_reader_flatten_pages(pdfmake_reader_t *reader,
                                            pdfmake_obj_t *pages_node);

/*
 * Resolve an inheritable attribute by walking up the page tree.
 * Looks for the named key starting from page_dict, then parents.
 * Returns the found value, or NULL if not found anywhere.
 */
pdfmake_obj_t *pdfmake_reader_resolve_inheritable(pdfmake_reader_t *reader,
                                                   pdfmake_obj_t *page_dict,
                                                   const char *key);

/*
 * Merge resource dictionaries from child and ancestors.
 * Child resources override ancestor resources for same-named entries.
 * Returns a new merged dict allocated in reader's arena.
 */
pdfmake_obj_t *pdfmake_reader_merge_resources(pdfmake_reader_t *reader,
                                               pdfmake_obj_t *page_dict);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_READER_H */
