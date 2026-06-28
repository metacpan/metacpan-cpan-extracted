/*
 * pdfmake_tag.h — Tagged PDF / Logical Structure
 *
 * §14.6 Marked Content
 * §14.7 Logical Structure
 * §14.8 Tagged PDF
 */

#ifndef PDFMAKE_TAG_H
#define PDFMAKE_TAG_H

#include "pdfmake_types.h"
#include "pdfmake_doc.h"
#include "pdfmake_content.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Standard structure types (§14.8.4) */
typedef enum {
    /* Grouping */
    PDFMAKE_TAG_DOCUMENT = 0,
    PDFMAKE_TAG_PART,
    PDFMAKE_TAG_ART,
    PDFMAKE_TAG_SECT,
    PDFMAKE_TAG_DIV,
    PDFMAKE_TAG_BLOCKQUOTE,
    PDFMAKE_TAG_CAPTION,
    PDFMAKE_TAG_TOC,
    PDFMAKE_TAG_TOCI,
    /* Block-level */
    PDFMAKE_TAG_P,
    PDFMAKE_TAG_HEADING,   /* Generic heading (was H, but H is a macro on some systems) */
    PDFMAKE_TAG_H1,
    PDFMAKE_TAG_H2,
    PDFMAKE_TAG_H3,
    PDFMAKE_TAG_H4,
    PDFMAKE_TAG_H5,
    PDFMAKE_TAG_H6,
    PDFMAKE_TAG_L,         /* List */
    PDFMAKE_TAG_LI,        /* List item */
    PDFMAKE_TAG_LBL,       /* Label */
    PDFMAKE_TAG_LBODY,     /* List body */
    PDFMAKE_TAG_TABLE,
    PDFMAKE_TAG_TR,
    PDFMAKE_TAG_TH,
    PDFMAKE_TAG_TD,
    PDFMAKE_TAG_THEAD,
    PDFMAKE_TAG_TBODY,
    PDFMAKE_TAG_TFOOT,
    /* Inline */
    PDFMAKE_TAG_SPAN,
    PDFMAKE_TAG_QUOTE,
    PDFMAKE_TAG_NOTE,
    PDFMAKE_TAG_REFERENCE,
    PDFMAKE_TAG_CODE,
    PDFMAKE_TAG_LINK,
    PDFMAKE_TAG_ANNOT,
    /* Illustration */
    PDFMAKE_TAG_FIGURE,
    PDFMAKE_TAG_FORMULA,
    PDFMAKE_TAG_FORM,
    PDFMAKE_TAG_COUNT
} pdfmake_struct_type_t;

/* Get the standard type name string */
const char *pdfmake_struct_type_name(pdfmake_struct_type_t type);

/* Look up type from name string. Returns -1 if not found. */
int pdfmake_struct_type_lookup(const char *name);

/* Maximum children per element */
#define PDFMAKE_MAX_STRUCT_CHILDREN 64

/* Marked content reference */
typedef struct {
    uint32_t page_obj_num;   /* Page object number */
    int      mcid;           /* Marked content ID */
} pdfmake_mcr_t;

/* Structure element */
typedef struct pdfmake_struct_elem {
    pdfmake_struct_type_t   type;
    char                    custom_type[64]; /* For non-standard types */
    struct pdfmake_struct_elem *parent;
    struct pdfmake_struct_elem **children;
    size_t                  child_count;
    size_t                  child_cap;
    pdfmake_mcr_t          *content_refs;   /* Marked content references */
    size_t                  mcr_count;
    size_t                  mcr_cap;
    char                    alt_text[512];
    char                    actual_text[512];
    char                    lang[32];
    uint32_t                obj_num;        /* Written object number */
} pdfmake_struct_elem_t;

/* Structure tree */
typedef struct pdfmake_struct_tree {
    pdfmake_struct_elem_t  *root;
    int                     next_mcid;      /* Per-page MCID counter */
    /* Role mapping */
    struct { char custom[64]; pdfmake_struct_type_t standard; } *role_map;
    size_t                  role_map_count;
    size_t                  role_map_cap;
    uint32_t                obj_num;
} pdfmake_struct_tree_t;

/* ── Document-level ────────────────────────────────────── */

pdfmake_struct_tree_t *pdfmake_doc_create_struct_tree(pdfmake_doc_t *doc);
pdfmake_struct_tree_t *pdfmake_doc_struct_tree(pdfmake_doc_t *doc);

/* ── Structure elements ────────────────────────────────── */

pdfmake_struct_elem_t *pdfmake_struct_elem_create(
    pdfmake_doc_t *doc,
    pdfmake_struct_type_t type,
    pdfmake_struct_elem_t *parent);

pdfmake_struct_elem_t *pdfmake_struct_elem_create_custom(
    pdfmake_doc_t *doc,
    const char *custom_type,
    pdfmake_struct_elem_t *parent);

pdfmake_err_t pdfmake_struct_elem_set_alt_text(pdfmake_struct_elem_t *elem, const char *alt);
pdfmake_err_t pdfmake_struct_elem_set_actual_text(pdfmake_struct_elem_t *elem, const char *text);
pdfmake_err_t pdfmake_struct_elem_set_lang(pdfmake_struct_elem_t *elem, const char *lang);

size_t pdfmake_struct_elem_child_count(pdfmake_struct_elem_t *elem);
pdfmake_struct_elem_t *pdfmake_struct_elem_child_at(pdfmake_struct_elem_t *elem, size_t idx);

/* Link content to structure */
pdfmake_err_t pdfmake_struct_elem_add_mcr(
    pdfmake_struct_elem_t *elem,
    uint32_t page_obj_num,
    int mcid);

/* ── Content stream ────────────────────────────────────── */

/* Begin marked content with MCID for structure tagging.
 * Emits: /type <</MCID n>> BDC
 * Sets *mcid_out to the assigned MCID. */
pdfmake_err_t pdfmake_content_begin_tag(
    pdfmake_content_t *c,
    pdfmake_struct_type_t type,
    int mcid);

/* End tagged marked content: EMC */
pdfmake_err_t pdfmake_content_end_tag(pdfmake_content_t *c);

/* ── Role mapping ──────────────────────────────────────── */

pdfmake_err_t pdfmake_struct_tree_map_role(
    pdfmake_struct_tree_t *tree,
    const char *custom,
    pdfmake_struct_type_t standard);

/* ── Writing ───────────────────────────────────────────── */

/* Write the entire structure tree. Called during finalize. */
pdfmake_err_t pdfmake_doc_write_struct_tree(pdfmake_doc_t *doc);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_TAG_H */
