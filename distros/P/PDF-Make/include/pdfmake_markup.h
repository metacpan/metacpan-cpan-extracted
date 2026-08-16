/*
 * libpdfmake - document markup parser.
 *
 * Parses the tag language documents are authored in into a node tree that
 * PDF::Make::Markup::Build walks onto the builder. Deliberately not an XML
 * parser and deliberately not an HTML parser: the tag set is fixed and
 * closed, attribute values must be quoted, and anything outside the grammar
 * is an error carrying a line and a column rather than a silent recovery.
 *
 * That strictness is the product decision. A template that renders something
 * slightly wrong is worse than one that refuses to render, because the wrong
 * one goes out to a customer's customer with a number on it.
 *
 * Everything - nodes, attributes, decoded text - is allocated in one arena
 * and freed in one call.
 */

#ifndef PDFMAKE_MARKUP_H
#define PDFMAKE_MARKUP_H

#include "pdfmake_types.h"
#include "pdfmake_arena.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Nesting limit. Hostile input is the normal case here - templates arrive
 * from customers - and unbounded depth is a stack overflow waiting to be
 * found by someone else. */
#ifndef PDFMAKE_MARKUP_MAX_DEPTH
#define PDFMAKE_MARKUP_MAX_DEPTH 64
#endif

#define PDFMAKE_MARKUP_ERR_LEN 256

/* The closed tag set. Never renumber: PDF::Make::Markup::Build switches on
 * these and a stale build would silently mean a different element. */
typedef enum {
    PDFMAKE_MK_INVALID = 0,
    /* structure */
    PDFMAKE_MK_DOC,
    PDFMAKE_MK_STYLE,
    PDFMAKE_MK_PAGE,
    PDFMAKE_MK_PAGEBREAK,
    PDFMAKE_MK_HEADER,
    PDFMAKE_MK_FOOTER,
    /* blocks */
    PDFMAKE_MK_H1,
    PDFMAKE_MK_H2,
    PDFMAKE_MK_H3,
    PDFMAKE_MK_H4,
    PDFMAKE_MK_H5,
    PDFMAKE_MK_H6,
    PDFMAKE_MK_P,
    PDFMAKE_MK_TEXT,
    PDFMAKE_MK_HR,
    PDFMAKE_MK_BOX,
    PDFMAKE_MK_IMG,
    /* layout */
    PDFMAKE_MK_ROW,
    PDFMAKE_MK_CELL,
    PDFMAKE_MK_TABLE,
    PDFMAKE_MK_TR,
    PDFMAKE_MK_TH,
    PDFMAKE_MK_TD,
    /* navigation */
    PDFMAKE_MK_BOOKMARK,
    /* inline */
    PDFMAKE_MK_B,
    PDFMAKE_MK_I,
    PDFMAKE_MK_SPAN,
    PDFMAKE_MK_MAX
} pdfmake_markup_tag_t;

typedef enum {
    PDFMAKE_MARKUP_ELEM = 0,
    PDFMAKE_MARKUP_TEXT = 1
} pdfmake_markup_kind_t;

/* Tag properties, from the static table in the .c. */
#define PDFMAKE_MKF_VOID      0x01u  /* takes no children */
#define PDFMAKE_MKF_CONTAINER 0x02u  /* whitespace-only text between its
                                       * children is layout, not content */
#define PDFMAKE_MKF_INLINE    0x04u  /* contributes a styled run rather than
                                       * a block of its own */

typedef struct pdfmake_markup_attr {
    const char *name;
    size_t      name_len;
    const char *value;          /* entity-decoded, null-terminated */
    size_t      value_len;
    uint32_t    line;
    uint32_t    col;
    struct pdfmake_markup_attr *next;
} pdfmake_markup_attr_t;

typedef struct pdfmake_markup_node {
    pdfmake_markup_kind_t kind;
    pdfmake_markup_tag_t  tag;      /* ELEM only */
    const char           *text;     /* TEXT only, entity-decoded */
    size_t                text_len;
    pdfmake_markup_attr_t *attrs;
    struct pdfmake_markup_node *parent;
    struct pdfmake_markup_node *first_child;
    struct pdfmake_markup_node *last_child;
    struct pdfmake_markup_node *next_sibling;
    uint32_t line;
    uint32_t col;
} pdfmake_markup_node_t;

typedef struct {
    pdfmake_arena_t       *arena;
    pdfmake_markup_node_t *root;    /* the <doc> element, NULL on error */
    int                    ok;
    uint32_t               err_line;
    uint32_t               err_col;
    char                   err[PDFMAKE_MARKUP_ERR_LEN];
} pdfmake_markup_doc_t;

/*
 * Parse src. Never returns NULL except on allocation failure; on a parse
 * error the returned doc has ok == 0 and err/err_line/err_col set, which is
 * what `pdfmake check` reports. The caller always frees with
 * pdfmake_markup_free.
 */
pdfmake_markup_doc_t *pdfmake_markup_parse(const char *src, size_t len);

void pdfmake_markup_free(pdfmake_markup_doc_t *doc);

/* Tag name for an id, or NULL. Static storage, never freed. */
const char *pdfmake_markup_tag_name(pdfmake_markup_tag_t tag);

/* Tag id for a name, or PDFMAKE_MK_INVALID when it is not in the set. */
pdfmake_markup_tag_t pdfmake_markup_tag_id(const char *name, size_t len);

/* PDFMAKE_MKF_* bits for a tag id, or 0. */
uint32_t pdfmake_markup_tag_flags(pdfmake_markup_tag_t tag);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_MARKUP_H */
