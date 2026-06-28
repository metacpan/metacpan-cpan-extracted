/*
 * pdfmake_ocg.h — Optional Content Groups (Layers)
 *
 * §8.11 Optional Content
 */

#ifndef PDFMAKE_OCG_H
#define PDFMAKE_OCG_H

#include "pdfmake_types.h"
#include "pdfmake_doc.h"
#include "pdfmake_content.h"

#ifdef __cplusplus
extern "C" {
#endif

/* OCG state */
typedef enum {
    PDFMAKE_OCG_ON  = 0,
    PDFMAKE_OCG_OFF = 1,
} pdfmake_ocg_state_t;

/* OCG intent */
typedef enum {
    PDFMAKE_OCG_INTENT_VIEW   = 0,
    PDFMAKE_OCG_INTENT_DESIGN = 1,
} pdfmake_ocg_intent_t;

/* OCMD policy */
typedef enum {
    PDFMAKE_OCMD_ALL_ON  = 0,
    PDFMAKE_OCMD_ANY_ON  = 1,
    PDFMAKE_OCMD_ALL_OFF = 2,
    PDFMAKE_OCMD_ANY_OFF = 3,
} pdfmake_ocmd_policy_t;

/* OCG structure */
typedef struct pdfmake_ocg {
    char                    name[128];
    int                     visible;         /* default visibility */
    pdfmake_ocg_intent_t    intent;
    pdfmake_ocg_state_t     print_state;     /* usage: print */
    pdfmake_ocg_state_t     view_state;      /* usage: view */
    pdfmake_ocg_state_t     export_state;    /* usage: export */
    int                     has_print_state;
    int                     has_view_state;
    int                     has_export_state;
    uint32_t                obj_num;         /* indirect object number (0 = not written) */
    char                    res_name[32];    /* resource name for /Properties (e.g. "MC0") */
} pdfmake_ocg_t;

/* ── Document-level OCG management ──────────────────────── */

/* Create a new OCG. Returns pointer owned by document. */
pdfmake_ocg_t *pdfmake_doc_create_ocg(pdfmake_doc_t *doc, const char *name);

/* Count of OCGs in document */
size_t pdfmake_doc_ocg_count(pdfmake_doc_t *doc);

/* Get OCG by index */
pdfmake_ocg_t *pdfmake_doc_ocg_at(pdfmake_doc_t *doc, size_t idx);

/* Find OCG by name */
pdfmake_ocg_t *pdfmake_doc_ocg_by_name(pdfmake_doc_t *doc, const char *name);

/* ── OCG writing ────────────────────────────────────────── */

/* Write OCG dictionary as indirect object. Returns obj_num. */
uint32_t pdfmake_ocg_write(pdfmake_ocg_t *ocg, pdfmake_doc_t *doc);

/* Write /OCProperties into the catalog. Called by finalize. */
pdfmake_err_t pdfmake_doc_write_ocproperties(pdfmake_doc_t *doc);

/* ── Page resource: /Properties ─────────────────────────── */

/* Add an OCG to the page's /Properties resource. */
int pdfmake_page_add_ocg(pdfmake_page_t *page, const char *name, uint32_t ocg_obj_num);

/* ── Content stream helpers ─────────────────────────────── */

/* Begin optional content: emits /OC /name BDC */
pdfmake_err_t pdfmake_content_begin_ocg(pdfmake_content_t *c, const char *res_name);

/* End optional content: emits EMC */
pdfmake_err_t pdfmake_content_end_ocg(pdfmake_content_t *c);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_OCG_H */
