/*
 * pdfmake_redact_rewrite.c — Content-stream rewriter for true redaction.
 *
 * Given an existing PDF content stream plus a list of redaction rects,
 * produce a new stream with every text-showing operator whose baseline
 * origin falls inside a rect omitted.  Everything else is copied
 * verbatim.
 *
 * Scope (phase 1): tuned for streams produced by PDF::Make::Builder,
 * which emit each `add_text` as a self-contained BT..ET block:
 *
 *     BT
 *     0 0 0 rg
 *     /F_Helvetica_normal 9 Tf
 *     1 0 0 1 <x> <y> Tm
 *     (text) Tj
 *     ET
 *
 * A block is dropped when its Tm origin (the last two of the six Tm
 * operands) lies inside any redaction rect.  All non-text operators
 * (graphics state, paths, shape fills used for the black rectangles
 * painted by mark_redaction) are preserved.
 *
 * Limitations:
 *   - Does not handle CTM transformations (cm operator) – assumes
 *     identity CTM, which matches Builder output.
 *   - Does not parse TJ/'/\" operators individually; a block containing
 *     those inside a rect would still be dropped via its Tm origin.
 *   - Non-Builder streams with multiple Tj ops inside one BT..ET block
 *     are handled at block granularity (all or nothing).
 */

#include "pdfmake_redact.h"
#include "pdfmake_buf.h"
#include <ctype.h>
#include <string.h>
#include <stdlib.h>

static int point_in_rect(double x, double y, const double r[4]) {
    return x >= r[0] && x <= r[2] && y >= r[1] && y <= r[3];
}

/* strstr on byte buffers, honouring the given length. */
static const uint8_t *find_bytes(const uint8_t *hay, size_t hay_len,
                                  const char *needle) {
    size_t n = strlen(needle);
    size_t i;
    if (n == 0 || n > hay_len) return NULL;
    for (i = 0; i + n <= hay_len; i++) {
        if (memcmp(hay + i, needle, n) == 0) return hay + i;
    }
    return NULL;
}

/* True iff `op` at position (op, op+op_len) is a standalone operator:
 * preceded by whitespace/boundary and followed by whitespace/boundary. */
static int is_standalone_op(const uint8_t *buf, size_t buf_len,
                            const uint8_t *op, size_t op_len) {
    const uint8_t *after;
    if (op < buf) return 0;
    if (op > buf && !isspace((unsigned char)op[-1])) return 0;
    after = op + op_len;
    if (after >= buf + buf_len) return 1;
    return isspace((unsigned char)*after);
}

/* Find the next standalone occurrence of `tag` within [buf, buf+buf_len). */
static const uint8_t *find_op(const uint8_t *buf, size_t buf_len,
                               const char *tag) {
    size_t tag_len = strlen(tag);
    const uint8_t *p = buf;
    size_t remaining = buf_len;
    size_t advanced;
    while (1) {
        const uint8_t *hit = find_bytes(p, remaining, tag);
        if (!hit) return NULL;
        if (is_standalone_op(buf, buf_len, hit, tag_len)) return hit;
        advanced = (hit - p) + 1;
        if (advanced >= remaining) return NULL;
        p = hit + 1;
        remaining -= advanced;
    }
}

/* Parse the 6 numbers preceding a Tm op.  Numbers are space-separated.
 * Returns 1 on success with e/f filled from the last two. */
static int parse_tm_origin(const uint8_t *block_start, const uint8_t *tm_op,
                           double *ex, double *ey) {
    /* Walk forward from block_start collecting numbers; reset the window
     * whenever a non-number token appears.  The final six numbers before
     * Tm are its operands. */
    double nums[6];
    int count = 0;
    const uint8_t *p = block_start;
    const uint8_t *tok;
    size_t tok_len;
    char tmp[64];
    char *endp;
    double v;
    int i;
    while (p < tm_op) {
        while (p < tm_op && isspace((unsigned char)*p)) p++;
        if (p >= tm_op) break;
        tok = p;
        while (p < tm_op && !isspace((unsigned char)*p)) p++;
        tok_len = (size_t)(p - tok);
        if (tok_len == 0 || tok_len >= 64) { count = 0; continue; }

        memcpy(tmp, tok, tok_len);
        tmp[tok_len] = '\0';
        endp = NULL;
        v = strtod(tmp, &endp);
        if (endp != tmp + tok_len) {
            count = 0;   /* non-number → reset window */
            continue;
        }
        if (count < 6) {
            nums[count++] = v;
        } else {
            for (i = 0; i < 5; i++) nums[i] = nums[i + 1];
            nums[5] = v;
        }
    }
    if (count < 6) return 0;
    *ex = nums[4];
    *ey = nums[5];
    return 1;
}

pdfmake_err_t pdfmake_redact_rewrite_stream(
    const uint8_t *in, size_t in_len,
    const pdfmake_redact_t *redactions, size_t n_redactions,
    pdfmake_buf_t *out)
{
    const uint8_t *p;
    size_t remaining;
    if (!in || !out) return PDFMAKE_EINVAL;
    if (n_redactions == 0) {
        return pdfmake_buf_append(out, in, in_len);
    }

    p = in;
    remaining = in_len;

    while (remaining > 0) {
        const uint8_t *bt = find_op(p, remaining, "BT");
        pdfmake_err_t err;
        size_t after_bt_off;
        const uint8_t *et;
        const uint8_t *block_end;
        size_t block_len;
        int keep;
        const uint8_t *tm;
        size_t consumed;

        if (!bt) {
            err = pdfmake_buf_append(out, p, remaining);
            return err;
        }

        /* Copy everything up to (but not including) BT. */
        err = pdfmake_buf_append(out, p, (size_t)(bt - p));
        if (err != PDFMAKE_OK) return err;

        after_bt_off = (size_t)(bt - p) + 2;
        et = find_op(bt + 2, remaining - after_bt_off, "ET");
        if (!et) {
            err = pdfmake_buf_append(out, bt, remaining - (size_t)(bt - p));
            return err;
        }
        block_end = et + 2;  /* include "ET" */
        block_len = (size_t)(block_end - bt);

        /* Decide whether to keep this block. */
        keep = 1;
        tm = find_op(bt + 2, (size_t)(et - (bt + 2)), "Tm");
        if (tm) {
            double ex, ey;
            if (parse_tm_origin(bt + 2, tm, &ex, &ey)) {
                size_t i;
                for (i = 0; i < n_redactions; i++) {
                    if (point_in_rect(ex, ey, redactions[i].rect)) {
                        keep = 0;
                        break;
                    }
                }
            }
        }

        if (keep) {
            err = pdfmake_buf_append(out, bt, block_len);
            if (err != PDFMAKE_OK) return err;
        }

        /* Advance past the block. */
        consumed = (size_t)(bt - p) + block_len;
        p = bt + block_len;
        remaining -= consumed;
    }

    return PDFMAKE_OK;
}
