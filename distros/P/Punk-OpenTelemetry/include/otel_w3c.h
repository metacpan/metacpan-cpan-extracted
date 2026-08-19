/* otel_w3c.h - W3C Trace Context: traceparent and tracestate.
 *
 * traceparent is fixed-shape and 55 bytes for version 00:
 *
 *     00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
 *     ^^ ^                                ^                ^^
 *     version  trace-id (32 hex)          span-id (16 hex)  flags
 *
 * VERSION TOLERANCE is the part worth reading twice. A version above 00 must
 * be parsed LENIENTLY - take the first 55 bytes and ignore a trailing
 * `-suffix` - rather than rejected. Rejecting an unknown version is how a
 * service becomes the one that breaks every trace the day the ecosystem moves
 * to version 01: it would be the only participant dropping context, and the
 * traces would be broken in a way that points at everyone except the
 * offender. Version ff is the one explicit invalid.
 *
 * tracestate is vendor state travelling beside it, and its mutation rule is
 * the thing implementations get wrong: the member you changed moves to the
 * FRONT, and everyone else keeps their relative order. That ordering is how a
 * downstream vendor knows which system touched the trace most recently.
 */

#ifndef OTEL_W3C_H
#define OTEL_W3C_H

#include "otel_ctx.h"

#define OTEL_TRACESTATE_MAX_MEMBERS 32

/* Parse a traceparent. Returns 1 and fills ctx, or 0 for "no context" -
 * which is the answer for every malformed input, because a bad header is
 * absent rather than fatal. */
static int otel_w3c_parse(const char *s, STRLEN len, otel_ctx *ctx) {
    unsigned char ver[1], fl[1];
    otel_ctx_clear(ctx);
    if (!s || len < 55) return 0;
    /* the separators sit at fixed offsets; anything else is not a
     * traceparent, whatever version it claims */
    if (s[2] != '-' || s[35] != '-' || s[52] != '-') return 0;
    if (!otel_hexn(s, 2, 1, ver)) return 0;
    if (ver[0] == 0xff) return 0;                  /* the one invalid version */

    if (ver[0] == 0x00) {
        if (len != 55) return 0;                   /* v00 is exactly 55 */
    }
    else {
        /* A FUTURE version may carry more fields. Take the part we
         * understand and ignore the rest, rather than dropping the trace. */
        if (len > 55 && s[55] != '-') return 0;
    }

    if (!otel_hexn(s + 3,  32, 16, ctx->trace_id)) return 0;
    if (!otel_hexn(s + 36, 16,  8, ctx->span_id))  return 0;
    if (otel_all_zero(ctx->trace_id, 16)) return 0;
    if (otel_all_zero(ctx->span_id,   8)) return 0;
    if (!otel_hexn(s + 53, 2, 1, fl)) return 0;

    /* every flag bit is preserved, not just the one we understand: a bit we
     * do not know the meaning of today is still somebody's information */
    ctx->flags = fl[0];
    ctx->valid = 1;
    return 1;
}

/* Render a traceparent into `out`, which must hold 56 bytes. */
static void otel_w3c_format(const otel_ctx *ctx, char *out) {
    out[0] = '0'; out[1] = '0'; out[2] = '-';
    otel_bytes_to_hex(ctx->trace_id, 16, out + 3);
    out[35] = '-';
    otel_bytes_to_hex(ctx->span_id, 8, out + 36);
    out[52] = '-';
    {
        static const char H[] = "0123456789abcdef";
        int f = ctx->flags & 0xff;
        out[53] = H[(f >> 4) & 0xf];
        out[54] = H[f & 0xf];
    }
    out[55] = '\0';
}

/* ---- tracestate --------------------------------------------------------- *
 * A comma-separated list of key=value members. The grammar is restrictive and
 * a malformed member invalidates THAT MEMBER, not the whole header - dropping
 * everyone else's state because one vendor emitted something odd is both
 * rude and lossy. */

static int otel_ts_key_ok(const char *k, STRLEN n) {
    STRLEN i;
    int at = 0;
    if (n < 1 || n > 256) return 0;
    /* lcalpha at the start, or a digit for the multi-tenant form */
    if (!((k[0] >= 'a' && k[0] <= 'z') || (k[0] >= '0' && k[0] <= '9')))
        return 0;
    for (i = 0; i < n; i++) {
        char c = k[i];
        if (c == '@') { if (at++) return 0; continue; }
        if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')
            || c == '_' || c == '-' || c == '*' || c == '/') continue;
        return 0;
    }
    return 1;
}

static int otel_ts_value_ok(const char *v, STRLEN n) {
    STRLEN i;
    if (n > 256) return 0;
    for (i = 0; i < n; i++) {
        unsigned char c = (unsigned char)v[i];
        /* printable ASCII except comma and equals, which are the delimiters.
         * This is also the check that stops a value reflected back out from
         * carrying a byte that would forge a header. */
        if (c < 0x20 || c > 0x7e || c == ',' || c == '=') return 0;
    }
    return 1;
}

/* Rebuild a tracestate with `key`=`val` moved to (or inserted at) the FRONT,
 * every other valid member keeping its relative order, capped at 32 members.
 * Returns a mortal SV. Members beyond the cap are dropped from the RIGHT,
 * which is the oldest state - the same "keep what is most recent" reasoning
 * the span queue uses. */
static SV *otel_ts_mutate(pTHX_ const char *in, STRLEN inlen,
                          const char *key, STRLEN klen,
                          const char *val, STRLEN vlen) {
    SV *out = sv_2mortal(newSVpvs(""));
    STRLEN i = 0;
    int members = 0;

    if (klen && otel_ts_key_ok(key, klen) && otel_ts_value_ok(val, vlen)) {
        sv_catpvn(out, key, klen);
        sv_catpvs(out, "=");
        sv_catpvn(out, val, vlen);
        members = 1;
    }
    if (!in || !inlen) return out;

    while (i < inlen && members < OTEL_TRACESTATE_MAX_MEMBERS) {
        STRLEN start, end, eq;
        const char *mk, *mv;
        STRLEN mkl, mvl;
        while (i < inlen && (in[i] == ' ' || in[i] == '\t' || in[i] == ','))
            i++;
        if (i >= inlen) break;
        start = i;
        while (i < inlen && in[i] != ',') i++;
        end = i;
        while (end > start && (in[end - 1] == ' ' || in[end - 1] == '\t'))
            end--;
        if (end <= start) continue;

        for (eq = start; eq < end && in[eq] != '='; eq++) ;
        if (eq >= end) continue;                   /* no '=': not a member */
        mk = in + start;  mkl = eq - start;
        mv = in + eq + 1; mvl = end - eq - 1;
        if (!otel_ts_key_ok(mk, mkl))   continue;  /* drop THIS member only */
        if (!otel_ts_value_ok(mv, mvl)) continue;
        /* the key we just promoted must not also appear later */
        if (klen && mkl == klen && memEQ(mk, key, klen)) continue;

        if (SvCUR(out)) sv_catpvs(out, ",");
        sv_catpvn(out, mk, mkl);
        sv_catpvs(out, "=");
        sv_catpvn(out, mv, mvl);
        members++;
    }
    return out;
}

#endif /* OTEL_W3C_H */
