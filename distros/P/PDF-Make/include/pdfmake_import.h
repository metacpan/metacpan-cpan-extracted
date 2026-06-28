/*
 * pdfmake_import.h — Cross-document object/page import.
 *
 * Given a parsed source document (pdfmake_reader_t), import individual
 * pages or arbitrary indirect-object subgraphs into a destination
 * pdfmake_doc_t that is still open for writing.
 *
 * The importer walks the object graph from the source, deep-copies each
 * object into the destination arena, re-interns names, and renumbers
 * indirect references. A remap table (src_num -> dst_num) is used to
 * share imported objects across multiple pages and to break reference
 * cycles.
 *
 * Scope (phase 1):
 *   - Page dimensions + rotation
 *   - Content stream (decompressed from source, stored uncompressed in dest)
 *   - /Resources entries of type /Font, /XObject, /ExtGState, /Properties
 *   - Transitive closure of all referenced objects
 *
 * Out of scope (silently skipped):
 *   - Page annotations (/Annots)
 *   - /ColorSpace, /Pattern, /Shading resource entries
 *   - Outlines, form fields on imported pages
 */

#ifndef PDFMAKE_IMPORT_H
#define PDFMAKE_IMPORT_H

#include "pdfmake_types.h"
#include "pdfmake_doc.h"
#include "pdfmake_parser.h"
#include "pdfmake_reader.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Import context: reused across multiple imports from the same source
 * so shared fonts/images aren't duplicated in the destination.
 *
 * Create with pdfmake_import_ctx_new(reader, dst), pass to each
 * import call, free with pdfmake_import_ctx_free.
 */
typedef struct pdfmake_import_ctx pdfmake_import_ctx_t;

pdfmake_import_ctx_t *pdfmake_import_ctx_new(pdfmake_reader_t *src_reader,
                                              pdfmake_doc_t *dst);

void pdfmake_import_ctx_free(pdfmake_import_ctx_t *ctx);

/*
 * Import an indirect object (and its transitive closure) from the source
 * parser into the destination document. Returns the new dst object
 * number, or 0 on failure. Repeated imports of the same src_num return
 * the cached dst_num from the remap table.
 */
uint32_t pdfmake_import_object(pdfmake_import_ctx_t *ctx, uint32_t src_num);

/*
 * Import page at src_page_index from the reader and append it to dst.
 * Returns the appended pdfmake_page_t* on success, NULL on failure.
 */
pdfmake_page_t *pdfmake_doc_import_page(pdfmake_import_ctx_t *ctx,
                                         size_t src_page_index);

/*
 * Convenience: import every page from the reader, in order.
 * Returns number of pages appended (may be less than total on first failure).
 */
size_t pdfmake_doc_import_all_pages(pdfmake_import_ctx_t *ctx);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_IMPORT_H */
