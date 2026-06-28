/*
 * pdfmake_redact.h — Secure PDF redaction.
 *
 * §12.5.6.17 Redaction Annotations
 */

#ifndef PDFMAKE_REDACT_H
#define PDFMAKE_REDACT_H

#include "pdfmake_types.h"
#include "pdfmake_doc.h"
#include "pdfmake_buf.h"

#ifdef __cplusplus
extern "C" {
#endif

#define PDFMAKE_MAX_REDACTIONS 256

/* Redaction options */
typedef struct {
    double overlay_color[3];     /* RGB 0-1 for fill (default black) */
    const char *overlay_text;    /* Repeated text in redaction area */
    double overlay_font_size;    /* Font size for overlay text */
} pdfmake_redact_opts_t;

/* Redaction mark */
typedef struct pdfmake_redact {
    double   rect[4];           /* [x0, y0, x1, y1] in page coords */
    double   overlay_color[3];
    char     overlay_text[128];
    double   overlay_font_size;
    int      applied;           /* 1 if already applied */
} pdfmake_redact_t;

/* ── Mark ──────────────────────────────────────────────── */

/* Mark a rectangular area for redaction on a page.
 * Content is NOT removed until apply_redactions is called. */
pdfmake_redact_t *pdfmake_page_mark_redaction(
    pdfmake_page_t *page,
    double x0, double y0, double x1, double y1,
    const pdfmake_redact_opts_t *opts);

/* Query redaction marks */
size_t pdfmake_page_redaction_count(pdfmake_page_t *page);
pdfmake_redact_t *pdfmake_page_redaction_at(pdfmake_page_t *page, size_t idx);

/* ── Apply ─────────────────────────────────────────────── */

/* Apply all redactions on a page: remove content within rects,
 * burn in overlay appearance. Content stream is rewritten. */
pdfmake_err_t pdfmake_page_apply_redactions(pdfmake_page_t *page);

/* Apply all redactions across all pages. */
pdfmake_err_t pdfmake_doc_apply_redactions(pdfmake_doc_t *doc);

/* ── Content-stream rewriter ───────────────────────────── */

/*
 * Rewrite a content stream, omitting every BT..ET block whose Tm origin
 * (the last two operands of the Tm operator inside the block) falls
 * inside any redaction rect.  All other bytes are copied verbatim.
 *
 * Used by apply_redactions to actually remove text bytes from the page
 * rather than just painting over them.  Output is written into `out`
 * (which the caller has initialised with pdfmake_buf_init).
 */
pdfmake_err_t pdfmake_redact_rewrite_stream(
    const uint8_t *in, size_t in_len,
    const pdfmake_redact_t *redactions, size_t n_redactions,
    pdfmake_buf_t *out);

/* ── Sanitize ──────────────────────────────────────────── */

/* Remove metadata that might contain redacted content. */
pdfmake_err_t pdfmake_doc_sanitize_metadata(pdfmake_doc_t *doc);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_REDACT_H */
