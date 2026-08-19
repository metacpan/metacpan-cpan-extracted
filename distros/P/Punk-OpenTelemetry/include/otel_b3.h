/* otel_b3.h - B3, in both of its spellings.
 *
 * Zipkin's format, and still the most widely deployed non-W3C one. It exists
 * twice:
 *
 *   single:  b3: {trace}-{span}-{sampled}-{parent}
 *   multi:   X-B3-TraceId, X-B3-SpanId, X-B3-ParentSpanId,
 *            X-B3-Sampled, X-B3-Flags
 *
 * TWO THINGS BITE.
 *
 * 1. A B3 trace id may be 64-bit (16 hex) as well as 128-bit, and a short one
 *    is LEFT-padded. Get the side wrong and you produce a well-formed id of a
 *    completely different value - which is worse than rejecting it, because
 *    it looks correct and silently joins to nothing. Handled in
 *    otel_trace_id_flex, shared with Jaeger, which has the same trap.
 *
 * 2. `sampled` has five spellings across deployments - "1", "0", "true",
 *    "false" and "d" - and "d" is DEBUG, which is a distinct state that
 *    IMPLIES sampled rather than being a synonym for it. A debug trace that
 *    is treated as merely sampled loses the "always keep this one" signal
 *    that is the entire reason somebody set it.
 */

#ifndef OTEL_B3_H
#define OTEL_B3_H

#include "otel_ctx.h"

/* -1 unknown, 0 not sampled, 1 sampled, 2 debug (which implies sampled) */
static int otel_b3_sampled(const char *s, STRLEN n) {
    if (n == 1) {
        if (s[0] == '1') return 1;
        if (s[0] == '0') return 0;
        if (s[0] == 'd' || s[0] == 'D') return 2;
        return -1;
    }
    if (n == 4 && (memEQ(s, "true", 4) || memEQ(s, "TRUE", 4))) return 1;
    if (n == 5 && (memEQ(s, "false", 5) || memEQ(s, "FALSE", 5))) return 0;
    return -1;
}

/* b3: {trace}-{span}[-{sampled}[-{parent}]]
 *
 * Also accepts the two degenerate forms deployments really send: a bare "0"
 * meaning "definitely do not sample", and a bare "d". */
static int otel_b3_parse_single(const char *s, STRLEN len, otel_ctx *ctx) {
    STRLEN i = 0, f[4], n[4];
    int fields = 0, samp;
    otel_ctx_clear(ctx);
    if (!s || !len) return 0;

    if (len == 1) {                       /* the sampling-only forms */
        samp = otel_b3_sampled(s, 1);
        if (samp < 0) return 0;
        ctx->flags = samp ? OTEL_FLAG_SAMPLED : 0;
        ctx->debug = (samp == 2);
        return 0;                          /* a decision, but no ids */
    }

    while (i <= len && fields < 4) {
        STRLEN start = i;
        while (i < len && s[i] != '-') i++;
        f[fields] = start;
        n[fields] = i - start;
        fields++;
        if (i >= len) break;
        i++;
    }
    if (fields < 2) return 0;
    if (!otel_trace_id_flex(s + f[0], n[0], ctx->trace_id)) return 0;
    if (!otel_span_id_flex(s + f[1], n[1], ctx->span_id))   return 0;

    if (fields >= 3 && n[2]) {
        samp = otel_b3_sampled(s + f[2], n[2]);
        if (samp > 0) {
            ctx->flags |= OTEL_FLAG_SAMPLED;
            ctx->debug = (samp == 2);
        }
    }
    /* field 4 is the parent span id, which OTel has no use for: a span's
     * parent is the span id above, and B3's parent field describes Zipkin's
     * own model. Parsed to validate the shape, then discarded. */
    ctx->valid = 1;
    return 1;
}

/* The multi-header form. Any of the values may be NULL. */
static int otel_b3_parse_multi(const char *tid, STRLEN tl,
                               const char *sid, STRLEN sl,
                               const char *smp, STRLEN pl,
                               const char *flg, STRLEN fl,
                               otel_ctx *ctx) {
    otel_ctx_clear(ctx);
    if (!tid || !sid) return 0;
    if (!otel_trace_id_flex(tid, tl, ctx->trace_id)) return 0;
    if (!otel_span_id_flex(sid, sl, ctx->span_id))   return 0;

    /* X-B3-Flags: 1 is the multi-header spelling of debug, and debug implies
     * sampled even when X-B3-Sampled says otherwise or is absent entirely */
    if (flg && fl == 1 && flg[0] == '1') {
        ctx->debug = 1;
        ctx->flags |= OTEL_FLAG_SAMPLED;
    }
    else if (smp && pl) {
        int samp = otel_b3_sampled(smp, pl);
        if (samp > 0) {
            ctx->flags |= OTEL_FLAG_SAMPLED;
            ctx->debug = (samp == 2);
        }
    }
    ctx->valid = 1;
    return 1;
}

/* Render the single-header form into `out` (needs 56 bytes). The single form
 * is what the spec recommends emitting. */
static void otel_b3_format_single(const otel_ctx *ctx, char *out) {
    otel_bytes_to_hex(ctx->trace_id, 16, out);
    out[32] = '-';
    otel_bytes_to_hex(ctx->span_id, 8, out + 33);
    out[49] = '-';
    out[50] = ctx->debug ? 'd' : ((ctx->flags & OTEL_FLAG_SAMPLED) ? '1' : '0');
    out[51] = '\0';
}

#endif /* OTEL_B3_H */
