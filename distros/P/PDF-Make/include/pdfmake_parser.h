/*
 * pdfmake_parser.h — PDF object parser + cross-reference reader
 *
 * Consumes tokens from pdfmake_tokenizer to build a pdfmake_obj_t tree
 * and resolves the xref table/stream to populate a pdfmake_doc_t.
 *
 * Supports:
 *   - Classic xref tables (§7.5.4)
 *   - Xref streams (§7.5.8)
 *   - Hybrid files (classic + XRefStm)
 *   - Incremental updates (/Prev chain, §7.5.6)
 *   - Repair mode (fallback scan when xref is broken)
 */

#ifndef PDFMAKE_PARSER_H
#define PDFMAKE_PARSER_H

#include "pdfmake_types.h"
#include "pdfmake_arena.h"
#include "pdfmake_doc.h"
#include "pdfmake_tokenizer.h"
#include "pdfmake_buf.h"

#ifdef __cplusplus
extern "C" {
#endif

/*============================================================================
 * Parser error codes (extend base pdfmake_err_t)
 *==========================================================================*/

#define PDFMAKE_EPARSE       20   /* Generic parse error */
#define PDFMAKE_EHEADER      21   /* Invalid PDF header */
#define PDFMAKE_EXREF        22   /* Malformed xref */
#define PDFMAKE_ETRAILER     23   /* Malformed trailer */
#define PDFMAKE_ESTREAM      24   /* Stream error */
#define PDFMAKE_ECYCLE       25   /* Cycle in /Prev chain */
#define PDFMAKE_ENOTFOUND    26   /* Object not found */

/*============================================================================
 * Xref entry types (per §7.5.4, §7.5.8)
 *==========================================================================*/

typedef enum {
    PDFMAKE_XREF_FREE      = 0,   /* Type 0: free object */
    PDFMAKE_XREF_UNCOMPRESSED = 1, /* Type 1: uncompressed (classic) object */
    PDFMAKE_XREF_COMPRESSED = 2    /* Type 2: compressed in object stream */
} pdfmake_xref_type_t;

/*============================================================================
 * Xref entry — represents one object in the cross-reference
 *==========================================================================*/

typedef struct {
    uint32_t             num;      /* Object number */
    uint16_t             gen;      /* Generation number */
    pdfmake_xref_type_t  type;     /* Entry type */
    union {
        /* Type 0 (free): next free object number in linked list */
        uint32_t next_free;
        /* Type 1 (uncompressed): byte offset in file */
        uint64_t offset;
        /* Type 2 (compressed): object stream number + index */
        struct {
            uint32_t obj_stm_num;  /* Object stream object number */
            uint32_t index;        /* Index within object stream */
        } compressed;
    } loc;
    uint8_t loaded;                /* 1 if object has been loaded */
} pdfmake_xref_entry_t;

/*============================================================================
 * Parser context — internal state during parsing
 *==========================================================================*/

typedef struct pdfmake_parser {
    /* Input buffer (not owned) */
    const uint8_t        *buf;
    size_t                buf_len;

    /* Tokenizer */
    pdfmake_tokenizer_t   tok;

    /* Output document (owned) */
    pdfmake_doc_t        *doc;

    /* Cross-reference table */
    pdfmake_xref_entry_t *xref;
    size_t                xref_size;    /* Highest object number + 1 */
    size_t                xref_cap;     /* Allocated capacity */

    /* Trailer dictionary values */
    uint32_t              root_num;     /* /Root object number */
    uint16_t              root_gen;
    uint32_t              info_num;     /* /Info object number (0 if none) */
    uint16_t              info_gen;
    uint32_t              encrypt_num;  /* /Encrypt object number (0 if none) */
    uint16_t              encrypt_gen;

    /* Document ID (first element of /ID array) */
    uint8_t               doc_id[32];
    size_t                doc_id_len;

    /* Parsing state */
    uint8_t               repair;       /* 1 = repair mode enabled */
    uint8_t               strict;       /* 1 = strict mode (no recovery) */

    /* Error information */
    pdfmake_err_t         last_err;
    char                  err_msg[256]; /* Human-readable error message */
    size_t                err_offset;   /* Byte offset where error occurred */

    /* /Prev chain cycle detection */
    uint64_t             *prev_offsets;
    size_t                prev_count;
    size_t                prev_cap;
} pdfmake_parser_t;

/*============================================================================
 * Parser API
 *==========================================================================*/

/*
 * Create a new parser for the given PDF byte buffer.
 * The buffer is not copied — caller must keep it alive until parsing completes.
 * Returns NULL on allocation failure.
 */
pdfmake_parser_t *pdfmake_parser_new(const uint8_t *buf, size_t len);

/*
 * Free the parser. Does NOT free the output document.
 */
void pdfmake_parser_free(pdfmake_parser_t *parser);

/*
 * Enable repair mode for fallback xref reconstruction.
 * Default is 0 (strict). Set to 1 to scan for `obj` keywords when xref broken.
 */
void pdfmake_parser_set_repair(pdfmake_parser_t *parser, int enable);

/*
 * Parse the PDF and build a document.
 * On success, *out_doc receives the parsed document (caller owns it).
 * Returns PDFMAKE_OK on success, error code on failure.
 */
pdfmake_err_t pdfmake_parser_run(pdfmake_parser_t *parser, pdfmake_doc_t **out_doc);

/*
 * Get error message for last parse failure.
 */
const char *pdfmake_parser_errmsg(pdfmake_parser_t *parser);

/*
 * Get byte offset where last error occurred.
 */
size_t pdfmake_parser_erroffset(pdfmake_parser_t *parser);

/*============================================================================
 * Object resolution (on-demand indirect lookup)
 *==========================================================================*/

/*
 * Resolve an indirect reference to its object.
 * Loads the object on first access (lazy loading).
 * Returns NULL if reference is invalid or object not found.
 *
 * The returned pointer is valid for the lifetime of the document.
 */
pdfmake_obj_t *pdfmake_parser_resolve(pdfmake_parser_t *parser, pdfmake_ref_t ref);

/*
 * Resolve an indirect reference, loading from the xref table.
 * Similar to resolve but returns the object directly.
 */
pdfmake_obj_t *pdfmake_doc_resolve(pdfmake_doc_t *doc, pdfmake_parser_t *parser, 
                                    uint32_t num, uint16_t gen);

/*============================================================================
 * Low-level parsing functions (internal, but exposed for testing)
 *==========================================================================*/

/*
 * Parse a single PDF object at the current tokenizer position.
 * Handles all object types including indirect references (N G R).
 * Returns pdfmake_null() with kind=PDFMAKE_NULL on error (check parser->last_err).
 */
pdfmake_obj_t pdfmake_parse_object(pdfmake_parser_t *parser);

/*
 * Parse an indirect object definition: N G obj ... endobj
 * Stores the object in the document's indirect table.
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_parse_indirect_object(pdfmake_parser_t *parser);

/*
 * Locate startxref by scanning backward from EOF.
 * Sets *offset to the xref byte offset.
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_locate_startxref(pdfmake_parser_t *parser, uint64_t *offset);

/*
 * Parse a classic xref table at the given offset.
 * Populates parser->xref entries.
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_parse_xref_table(pdfmake_parser_t *parser, uint64_t offset);

/*
 * Parse an xref stream at the given offset.
 * Decodes the stream (with predictor) and populates parser->xref.
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_parse_xref_stream(pdfmake_parser_t *parser, uint64_t offset);

/*
 * Parse the trailer dictionary.
 * Extracts /Root, /Info, /Encrypt, /Prev, /Size.
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_parse_trailer(pdfmake_parser_t *parser, pdfmake_obj_t *trailer);

/*
 * Repair mode: scan entire file for `N G obj` patterns.
 * Rebuilds xref from found objects.
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_repair_xref(pdfmake_parser_t *parser);

/*
 * Extract stream body from raw PDF bytes.
 * Uses /Length from dict, falls back to scanning for endstream.
 * Stores result in out_data/out_len (pointer into original buffer).
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_extract_stream_body(pdfmake_parser_t *parser,
                                          pdfmake_obj_t *stream_dict,
                                          size_t body_offset,
                                          const uint8_t **out_data,
                                          size_t *out_len);

/*============================================================================
 * Utility functions
 *==========================================================================*/

/*
 * Decode a stream's data using its filter chain.
 * Allocates decoded data in the arena.
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_decode_stream(pdfmake_parser_t *parser,
                                     pdfmake_stream_t *stream,
                                     uint8_t **out_data,
                                     size_t *out_len);

/*
 * Check if the PDF header is valid.
 * Returns PDFMAKE_OK if valid %PDF-N.M header found.
 */
pdfmake_err_t pdfmake_check_header(pdfmake_parser_t *parser, 
                                    int *major, int *minor);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_PARSER_H */
