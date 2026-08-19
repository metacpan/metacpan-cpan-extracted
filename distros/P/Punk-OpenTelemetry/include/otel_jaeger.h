/* otel_jaeger.h - Jaeger's uber-trace-id.
 *
 *     uber-trace-id: {trace-id}:{span-id}:{parent-span-id}:{flags}
 *
 * Three quirks, all of which show up in real deployments:
 *
 * 1. The trace id is frequently written SHORT - leading zeroes trimmed, so
 *    "abc" rather than 32 characters - and must be left-padded. Same trap as
 *    B3, same shared helper.
 *
 * 2. The parent field is deprecated and is usually "0". It is parsed to
 *    validate the shape and then discarded, because OTel's parent is the span
 *    id above it.
 *
 * 3. The WHOLE VALUE is sometimes percent-encoded, because proxies and client
 *    libraries treat it as a URL component and helpfully escape the colons.
 *    A parser that only accepts the raw form silently drops context from
 *    every request that passed through one of those, which looks like an
 *    intermittent tracing bug and is really a decoding one.
 *
 * flags is a bitfield: 1 sampled, 2 debug. Debug implies sampled, exactly as
 * in B3.
 */

#ifndef OTEL_JAEGER_H
#define OTEL_JAEGER_H

#include "otel_ctx.h"

#define OTEL_JAEGER_MAX 256   /* a bound, so no allocation follows the input */

/* Percent-decode in place into `out` (bounded by OTEL_JAEGER_MAX). Returns
 * the decoded length, or 0 when it will not fit - never a partial decode. */
static STRLEN otel_pct_decode(const char *s, STRLEN len, char *out,
                              STRLEN cap) {
    STRLEN i = 0, o = 0;
    while (i < len) {
        if (o >= cap) return 0;
        if (s[i] == '%' && i + 2 < len) {
            int hi = otel_nib(s[i + 1]), lo = otel_nib(s[i + 2]);
            if (hi >= 0 && lo >= 0) {
                out[o++] = (char)((hi << 4) | lo);
                i += 3;
                continue;
            }
        }
        out[o++] = s[i++];
    }
    return o;
}

static int otel_jaeger_parse(const char *s, STRLEN len, otel_ctx *ctx) {
    char buf[OTEL_JAEGER_MAX];
    STRLEN i = 0, f[4], n[4];
    int fields = 0;
    otel_ctx_clear(ctx);
    if (!s || !len || len >= OTEL_JAEGER_MAX) return 0;

    /* Decode unconditionally: a value with no percent escapes comes back
     * unchanged, so this costs one bounded copy and buys every request that
     * came through a proxy which escaped the colons. */
    len = otel_pct_decode(s, len, buf, sizeof buf);
    if (!len) return 0;
    s = buf;

    while (i <= len && fields < 4) {
        STRLEN start = i;
        while (i < len && s[i] != ':') i++;
        f[fields] = start;
        n[fields] = i - start;
        fields++;
        if (i >= len) break;
        i++;
    }
    if (fields < 2) return 0;

    /* a short trace id is left-padded; see otel_trace_id_flex */
    if (n[0] > 32) return 0;
    if (n[0] == 32 || n[0] == 16) {
        if (!otel_trace_id_flex(s + f[0], n[0], ctx->trace_id)) return 0;
    }
    else {
        char pad[32];
        STRLEN want = 32, j;
        if (n[0] == 0 || (n[0] % 2)) {
            /* an odd-length id is legal here: Jaeger trims leading zeroes
             * without regard for byte boundaries */
            if (n[0] == 0) return 0;
        }
        for (j = 0; j < want - n[0]; j++) pad[j] = '0';
        Copy(s + f[0], pad + (want - n[0]), n[0], char);
        if (!otel_trace_id_flex(pad, want, ctx->trace_id)) return 0;
    }

    if (n[1] == 16) {
        if (!otel_span_id_flex(s + f[1], n[1], ctx->span_id)) return 0;
    }
    else {
        char pad[16];
        STRLEN want = 16, j;
        if (n[1] == 0 || n[1] > 16) return 0;
        for (j = 0; j < want - n[1]; j++) pad[j] = '0';
        Copy(s + f[1], pad + (want - n[1]), n[1], char);
        if (!otel_span_id_flex(pad, want, ctx->span_id)) return 0;
    }

    if (fields >= 4 && n[3]) {
        int v = 0;
        STRLEN j;
        for (j = 0; j < n[3] && j < 8; j++) {
            int d = otel_nib(s[f[3] + j]);
            if (d < 0) { v = 0; break; }
            v = (v << 4) | d;
        }
        if (v & 0x2) { ctx->debug = 1; ctx->flags |= OTEL_FLAG_SAMPLED; }
        else if (v & 0x1) ctx->flags |= OTEL_FLAG_SAMPLED;
    }
    ctx->valid = 1;
    return 1;
}

/* Render into `out` (needs 56 bytes). The parent field is emitted as 0,
 * which is what Jaeger itself does now that it is deprecated. */
static void otel_jaeger_format(const otel_ctx *ctx, char *out) {
    otel_bytes_to_hex(ctx->trace_id, 16, out);
    out[32] = ':';
    otel_bytes_to_hex(ctx->span_id, 8, out + 33);
    out[49] = ':';
    out[50] = '0';
    out[51] = ':';
    out[52] = ctx->debug ? '3' : ((ctx->flags & OTEL_FLAG_SAMPLED) ? '1' : '0');
    out[53] = '\0';
}

#endif /* OTEL_JAEGER_H */
