/*
 * pdfmake_linear.h — PDF Linearization (Fast Web View)
 *
 * Implements PDF linearization per Annex F of ISO 32000-2:2020.
 * Linearization reorganizes a PDF for efficient web delivery:
 * - First page displays before entire file downloads
 * - Subsequent pages load via HTTP byte-range requests
 * - Hint tables enable fast page offset lookups
 */

#ifndef PDFMAKE_LINEAR_H
#define PDFMAKE_LINEAR_H

#include "pdfmake.h"
#include "pdfmake_buf.h"
#include "pdfmake_doc.h"
#include <stdint.h>
#include <stddef.h>
#include <sys/types.h>  /* For ssize_t */

#ifdef __cplusplus
extern "C" {
#endif

/*============================================================================
 * Linearization Parameters (§F.2)
 *==========================================================================*/

/*
 * Linearization dictionary parameters.
 * These values are extracted from the first object in a linearized PDF.
 */
typedef struct pdfmake_linear_params {
    int         version;         /* /Linearized value (usually 1) */
    size_t      file_length;     /* /L - total file length */
    size_t      hint_offset;     /* /H[0] - primary hint stream offset */
    size_t      hint_length;     /* /H[1] - primary hint stream length */
    size_t      overflow_offset; /* /H[2] - overflow hint offset (optional) */
    size_t      overflow_length; /* /H[3] - overflow hint length (optional) */
    uint32_t    first_page_obj;  /* /O - first page's page object number */
    size_t      first_page_end;  /* /E - end of first page section */
    size_t      page_count;      /* /N - number of pages */
    size_t      main_xref_offset;/* /T - offset of first entry in main xref */
} pdfmake_linear_params_t;

/*============================================================================
 * Page Offset Hint Table Entry (§F.4.2)
 *==========================================================================*/

typedef struct pdfmake_page_hint {
    uint32_t    obj_count;       /* Number of objects in this page */
    size_t      page_length;     /* Length of page section in bytes */
    uint32_t    content_offset;  /* Offset to content stream from page start */
    size_t      content_length;  /* Content stream length */
    uint16_t    shared_count;    /* Number of shared object references */
    uint16_t   *shared_ids;      /* Array of shared object identifiers */
    uint16_t   *shared_numerators; /* Fractional position numerators */
} pdfmake_page_hint_t;

/*============================================================================
 * Shared Objects Hint Table Entry (§F.4.3)
 *==========================================================================*/

typedef struct pdfmake_shared_hint {
    uint32_t    obj_num;         /* Object number */
    size_t      offset;          /* Offset in file */
    size_t      length;          /* Object length */
    uint16_t    ref_count;       /* Number of pages referencing this object */
} pdfmake_shared_hint_t;

/*============================================================================
 * Hint Tables Container
 *==========================================================================*/

typedef struct pdfmake_hint_tables {
    /* Page offset hints */
    pdfmake_page_hint_t  *page_hints;
    size_t                page_hint_count;
    
    /* Shared object hints */
    pdfmake_shared_hint_t *shared_hints;
    size_t                 shared_hint_count;
    
    /* First page data (special case) */
    uint32_t    first_page_obj_start;  /* First object number for page 1 */
    size_t      first_page_offset;     /* Offset of first page section */
    
    /* Allocation tracking */
    pdfmake_arena_t *arena;
} pdfmake_hint_tables_t;

/*============================================================================
 * Linearization State
 *==========================================================================*/

typedef struct pdfmake_linear {
    pdfmake_doc_t          *doc;
    pdfmake_arena_t        *arena;
    
    /* Linearization parameters */
    pdfmake_linear_params_t params;
    
    /* Hint tables */
    pdfmake_hint_tables_t   hints;
    
    /* Object mapping: original -> linearized */
    uint32_t               *obj_map;       /* obj_map[old_num] = new_num */
    size_t                  obj_map_size;
    
    /* Page dependency tracking */
    struct {
        uint32_t   *objects;    /* Object numbers for this page */
        size_t      count;
        size_t      cap;
    } *page_objects;            /* Array indexed by page number */
    
    /* Shared objects (used by multiple pages) */
    uint32_t               *shared_objects;
    size_t                  shared_count;
    size_t                  shared_cap;
    
    /* Object reference counts */
    uint16_t               *ref_counts;    /* ref_counts[obj_num] = page count */
    
    /* Write state */
    size_t                  first_page_xref_pos;
    size_t                  hint_stream_pos;
    size_t                  main_xref_pos;
} pdfmake_linear_t;

/*============================================================================
 * Linearization Detection
 *==========================================================================*/

/*
 * Check if a document is linearized.
 * Returns 1 if linearized, 0 if not, -1 on error.
 */
int pdfmake_doc_is_linearized(pdfmake_doc_t *doc);

/*
 * Check if raw PDF data is linearized (without full parse).
 * Returns 1 if linearized, 0 if not.
 */
int pdfmake_data_is_linearized(const uint8_t *data, size_t len);

/*
 * Extract linearization parameters from a linearized document.
 * Returns PDFMAKE_OK on success, PDFMAKE_EINVAL if not linearized.
 */
pdfmake_err_t pdfmake_doc_linear_params(
    pdfmake_doc_t *doc,
    pdfmake_linear_params_t *out
);

/*============================================================================
 * Linearization Process
 *==========================================================================*/

/*
 * Create linearization context for a document.
 */
pdfmake_linear_t *pdfmake_linear_new(pdfmake_doc_t *doc);

/*
 * Free linearization context.
 */
void pdfmake_linear_free(pdfmake_linear_t *lin);

/*
 * Analyze document and prepare for linearization.
 * - Identifies page dependencies
 * - Finds shared objects
 * - Computes object renumbering
 */
pdfmake_err_t pdfmake_linear_analyze(pdfmake_linear_t *lin);

/*
 * Build hint tables from analysis results.
 */
pdfmake_err_t pdfmake_linear_build_hints(pdfmake_linear_t *lin);

/*
 * Write linearized PDF to buffer.
 */
pdfmake_err_t pdfmake_linear_write(pdfmake_linear_t *lin, pdfmake_buf_t *out);

/*============================================================================
 * High-Level API
 *==========================================================================*/

/*
 * Linearize document in place.
 * Prepares document for linearized output.
 */
pdfmake_err_t pdfmake_doc_linearize(pdfmake_doc_t *doc);

/*
 * Write document in linearized format.
 */
pdfmake_err_t pdfmake_doc_write_linearized(pdfmake_doc_t *doc, pdfmake_buf_t *out);

/*
 * Write linearized document to file path.
 */
pdfmake_err_t pdfmake_doc_write_linearized_to_path(
    pdfmake_doc_t *doc,
    const char *path
);

/*============================================================================
 * Streaming Reader (for byte-range fetching)
 *==========================================================================*/

/*
 * Callback function for fetching byte ranges.
 * Should return number of bytes read, or -1 on error.
 */
typedef ssize_t (*pdfmake_fetch_fn)(
    void *ctx,
    size_t offset,
    size_t length,
    uint8_t *out
);

/*
 * Streaming reader for linearized PDFs.
 */
typedef struct pdfmake_stream_reader {
    pdfmake_fetch_fn        fetch;
    void                   *fetch_ctx;
    pdfmake_arena_t        *arena;
    
    /* Linearization info (from first fetch) */
    pdfmake_linear_params_t params;
    int                     is_linearized;
    
    /* Hint tables (parsed from hint stream) */
    pdfmake_hint_tables_t   hints;
    int                     hints_loaded;
    
    /* Page availability bitmap */
    uint8_t                *page_loaded;
    
    /* Cached data */
    uint8_t                *header_data;
    size_t                  header_len;
    
    /* Parsed document (incrementally built) */
    pdfmake_doc_t          *doc;
} pdfmake_stream_reader_t;

/*
 * Create streaming reader with fetch callback.
 */
pdfmake_stream_reader_t *pdfmake_stream_reader_new(
    pdfmake_fetch_fn fetch,
    void *ctx
);

/*
 * Free streaming reader.
 */
void pdfmake_stream_reader_free(pdfmake_stream_reader_t *reader);

/*
 * Read and parse header/linearization dictionary.
 * This is the first fetch operation.
 */
pdfmake_err_t pdfmake_stream_reader_read_header(pdfmake_stream_reader_t *reader);

/*
 * Load hint tables (if linearized).
 */
pdfmake_err_t pdfmake_stream_reader_load_hints(pdfmake_stream_reader_t *reader);

/*
 * Check if a specific page is loaded.
 */
int pdfmake_stream_reader_page_available(
    pdfmake_stream_reader_t *reader,
    int page_num
);

/*
 * Read/fetch a specific page's data.
 * page_num is 0-based.
 */
pdfmake_err_t pdfmake_stream_reader_read_page(
    pdfmake_stream_reader_t *reader,
    int page_num
);

/*
 * Get byte range for a page (for HTTP Range header).
 * Returns PDFMAKE_OK and fills offset/length, or PDFMAKE_EINVAL if unknown.
 */
pdfmake_err_t pdfmake_stream_reader_page_range(
    pdfmake_stream_reader_t *reader,
    int page_num,
    size_t *offset,
    size_t *length
);

/*
 * Get the total page count (available after read_header for linearized).
 */
size_t pdfmake_stream_reader_page_count(pdfmake_stream_reader_t *reader);

/*
 * Get the underlying document (incrementally populated).
 */
pdfmake_doc_t *pdfmake_stream_reader_doc(pdfmake_stream_reader_t *reader);

/*============================================================================
 * Hint Table Parsing
 *==========================================================================*/

/*
 * Parse hint stream data into hint tables.
 */
pdfmake_err_t pdfmake_parse_hint_stream(
    pdfmake_arena_t *arena,
    const uint8_t *data,
    size_t len,
    size_t page_count,
    pdfmake_hint_tables_t *out
);

/*
 * Build hint stream from hint tables.
 */
pdfmake_err_t pdfmake_build_hint_stream(
    pdfmake_arena_t *arena,
    const pdfmake_hint_tables_t *hints,
    pdfmake_buf_t *out
);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_LINEAR_H */
