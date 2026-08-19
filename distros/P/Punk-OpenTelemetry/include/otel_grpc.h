/* otel_grpc.h - OTLP over gRPC.
 *
 * gRPC is not a framework here and is not a dependency. OTLP/gRPC is a narrow,
 * fixed use of HTTP/2 that can be implemented directly:
 *
 *   - POST over HTTP/2 to one fixed path per signal
 *   - content-type: application/grpc+proto, te: trailers
 *   - the body is LENGTH-PREFIXED FRAMES: one byte compressed flag, four
 *     bytes big-endian length, then the protobuf message from phase 2
 *   - the response is the same framing, and then the part that catches people
 *
 * THE STATUS IS IN THE TRAILERS.
 *
 * A gRPC call returns HTTP 200 even when it fails. The real outcome is in the
 * HTTP/2 trailing headers: `grpc-status` (a number) and `grpc-message`. A
 * transport that reads the HTTP status and stops will report every failure as
 * a success - which is worse than not implementing gRPC at all, because it
 * looks like it works.
 *
 * This needs Fetch 0.15 or newer. Before it, Fetch's HTTP/2 header callback
 * filtered to NGHTTP2_HCAT_RESPONSE and discarded trailers - which arrive as
 * a second HEADERS frame, category NGHTTP2_HCAT_HEADERS - so there was no
 * grpc-status to read and a client could only ever report success. Fetch now
 * captures them and exposes $res->trailers.
 */

#ifndef OTEL_GRPC_H
#define OTEL_GRPC_H

/* gRPC status codes. The names matter because grpc-message is free text and
 * the code is the only thing worth branching on. */
#define GRPC_OK                  0
#define GRPC_CANCELLED           1
#define GRPC_UNKNOWN             2
#define GRPC_INVALID_ARGUMENT    3
#define GRPC_DEADLINE_EXCEEDED   4
#define GRPC_NOT_FOUND           5
#define GRPC_ALREADY_EXISTS      6
#define GRPC_PERMISSION_DENIED   7
#define GRPC_RESOURCE_EXHAUSTED  8
#define GRPC_FAILED_PRECONDITION 9
#define GRPC_ABORTED            10
#define GRPC_OUT_OF_RANGE       11
#define GRPC_UNIMPLEMENTED      12
#define GRPC_INTERNAL           13
#define GRPC_UNAVAILABLE        14
#define GRPC_DATA_LOSS          15
#define GRPC_UNAUTHENTICATED    16

/* The OTLP spec's retryable set.
 *
 * RESOURCE_EXHAUSTED is the odd one: it is retryable ONLY when the server
 * sent RetryInfo in the details. Without it, the server is saying "you are
 * over quota", and retrying a quota refusal on a timer is how a client turns
 * its own rate limit into an outage. */
static int otel_grpc_retryable(int code, int has_retry_info) {
    switch (code) {
        case GRPC_CANCELLED:
        case GRPC_DEADLINE_EXCEEDED:
        case GRPC_ABORTED:
        case GRPC_OUT_OF_RANGE:
        case GRPC_UNAVAILABLE:
        case GRPC_DATA_LOSS:
            return 1;
        case GRPC_RESOURCE_EXHAUSTED:
            return has_retry_info ? 1 : 0;
        default:
            return 0;
    }
}

/* The service path for a signal. Fixed, and part of the protocol rather than
 * configuration - a gRPC endpoint is a host and port, and the path is derived
 * from the proto package and method. */
static const char *otel_grpc_path(const char *signal) {
    if (strEQ(signal, "traces"))
        return "/opentelemetry.proto.collector.trace.v1.TraceService/Export";
    if (strEQ(signal, "metrics"))
        return "/opentelemetry.proto.collector.metrics.v1.MetricsService/Export";
    if (strEQ(signal, "logs"))
        return "/opentelemetry.proto.collector.logs.v1.LogsService/Export";
    return NULL;
}

/* ---- message framing ---------------------------------------------------- *
 *
 *   byte 0      compressed flag (0 or 1)
 *   bytes 1..4  message length, BIG-endian
 *   bytes 5..   the protobuf message
 *
 * Big-endian, unlike every other length in this dist, which are protobuf
 * varints or little-endian fixed64. Getting the byte order wrong here
 * produces a length in the billions and a peer that closes the stream. */
static SV *otel_grpc_frame(pTHX_ SV *msg, int compressed) {
    STRLEN len;
    const char *p = SvPV_const(msg, len);
    SV *out = newSV(len + 5);
    char *d;
    SvPOK_on(out);
    d = SvPVX(out);
    d[0] = (char)(compressed ? 1 : 0);
    d[1] = (char)((len >> 24) & 0xff);
    d[2] = (char)((len >> 16) & 0xff);
    d[3] = (char)((len >>  8) & 0xff);
    d[4] = (char)( len        & 0xff);
    Copy(p, d + 5, len, char);
    SvCUR_set(out, len + 5);
    d[len + 5] = '\0';
    return out;
}

/* Read one frame. Returns 1 and fills *body / *blen / *compressed, or 0 when
 * the buffer does not hold a whole frame yet - which is not an error, only
 * "not yet". A length that would run past the buffer is treated the same way
 * rather than trusted, because it arrived over a network. */
static int otel_grpc_unframe(const char *buf, STRLEN len, const char **body,
                             STRLEN *blen, int *compressed, STRLEN *consumed) {
    U32 n;
    if (!buf || len < 5) return 0;
    n = ((U32)(unsigned char)buf[1] << 24)
      | ((U32)(unsigned char)buf[2] << 16)
      | ((U32)(unsigned char)buf[3] <<  8)
      |  (U32)(unsigned char)buf[4];
    if (len < (STRLEN)n + 5) return 0;
    if (compressed) *compressed = buf[0] ? 1 : 0;
    if (body)  *body  = buf + 5;
    if (blen)  *blen  = (STRLEN)n;
    if (consumed) *consumed = (STRLEN)n + 5;
    return 1;
}

/* ---- RetryInfo ---------------------------------------------------------- *
 * grpc-status-details-bin carries a base64 google.rpc.Status whose details
 * hold a RetryInfo { retry_delay: Duration { seconds, nanos } }. When the
 * server names a delay, it wins over any computed backoff: it knows when it
 * will be ready and the client does not. */

static int otel_b64_val(char c) {
    if (c >= 'A' && c <= 'Z') return c - 'A';
    if (c >= 'a' && c <= 'z') return c - 'a' + 26;
    if (c >= '0' && c <= '9') return c - '0' + 52;
    if (c == '+' || c == '-') return 62;      /* URL-safe alphabet too: the */
    if (c == '/' || c == '_') return 63;      /* header is base64url in practice */
    return -1;
}

static STRLEN otel_b64_decode(const char *s, STRLEN len, char *out,
                              STRLEN cap) {
    STRLEN i, o = 0;
    int acc = 0, bits = 0;
    for (i = 0; i < len; i++) {
        int v;
        if (s[i] == '=' || s[i] == '\n' || s[i] == '\r') continue;
        v = otel_b64_val(s[i]);
        if (v < 0) return 0;                  /* not base64: no details */
        acc = (acc << 6) | v;
        bits += 6;
        if (bits >= 8) {
            bits -= 8;
            if (o >= cap) return 0;
            out[o++] = (char)((acc >> bits) & 0xff);
        }
    }
    return o;
}

#define OTEL_GRPC_DETAILS_MAX 1024

/* Find a RetryInfo delay in a grpc-status-details-bin value. Returns the
 * delay in seconds, or -1 for none.
 *
 * This walks the protobuf generically rather than decoding google.rpc.Status
 * properly: Status.details is an Any, whose type_url identifies RetryInfo and
 * whose value holds the Duration. Walking for the shape is enough to answer
 * the only question being asked - "did the server name a delay" - and avoids
 * a second protobuf reader in a dist whose encoder is deliberately one-way. */
static double otel_grpc_retry_after(const char *b64, STRLEN len) {
    char buf[OTEL_GRPC_DETAILS_MAX];
    STRLEN n, pos = 0;
    if (!b64 || !len) return -1;
    n = otel_b64_decode(b64, len, buf, sizeof buf);
    if (!n) return -1;

    /* look for the Any whose type_url mentions RetryInfo, then read the
     * Duration inside its value */
    while (pos + 1 < n) {
        if ((STRLEN)(pos + 9) <= n && memEQ(buf + pos, "RetryInfo", 9)) {
            STRLEN q = pos + 9;
            double secs = -1;
            /* the Duration follows within the same Any value; its seconds is
             * field 1 varint, nanos field 2 varint */
            while (q + 1 < n && q < pos + 64) {
                unsigned char tag = (unsigned char)buf[q];
                if ((tag >> 3) == 1 && (tag & 7) == 0) {
                    UV v = 0;
                    int shift = 0;
                    q++;
                    while (q < n) {
                        unsigned char b = (unsigned char)buf[q++];
                        v |= (UV)(b & 0x7f) << shift;
                        if (!(b & 0x80)) break;
                        shift += 7;
                        if (shift > 56) break;
                    }
                    secs = (double)v;
                    break;
                }
                q++;
            }
            return secs >= 0 ? secs : 0;   /* named, even if zero seconds */
        }
        pos++;
    }
    return -1;
}

/* ---- the classification a caller acts on -------------------------------- *
 * Mirrors the HTTP transport's verdicts so a caller branches once:
 *   0 ok, 1 retry, 2 permanent
 *
 * `have_status` is 0 when no grpc-status trailer was seen at all. That is NOT
 * success: it means the stream ended without the server saying how it went,
 * which is a transport failure and is retryable. Treating a missing status as
 * OK is the specific bug that makes a broken gRPC client look healthy. */
static int otel_grpc_verdict(int have_status, int code, int has_retry_info) {
    if (!have_status) return 1;
    if (code == GRPC_OK) return 0;
    return otel_grpc_retryable(code, has_retry_info) ? 1 : 2;
}

/* ---- reading the status off a response ---------------------------------- *
 *
 * Fetch 0.15 exposes HTTP/2 trailers as $res->trailers
 *
 * TWO PLACES TO LOOK, and both are normal:
 *
 *   - the TRAILERS, for an ordinary call: HEADERS, then DATA, then a second
 *     HEADERS carrying grpc-status.
 *   - the response HEADERS, for a TRAILERS-ONLY response: a server that fails
 *     before producing a body sends ONE HEADERS frame with :status, the
 *     grpc-status and END_STREAM, and no DATA at all. nghttp2 reports that
 *     first frame as HCAT_RESPONSE, so the status lands in the ordinary
 *     header list. A client that only looked at trailers would see no status
 *     and - if it treated that as success - would report every fast failure
 *     as a successful export.
 *
 * Found nowhere is NOT success; see otel_grpc_verdict. */
static SV *otel_grpc_hdr(pTHX_ SV *list, const char *want, STRLEN wlen) {
    AV *av;
    SSize_t i, n;
    if (!list || !SvROK(list) || SvTYPE(SvRV(list)) != SVt_PVAV) return NULL;
    av = (AV *)SvRV(list);
    n = av_len(av) + 1;
    for (i = 0; i + 1 < n; i += 2) {
        SV **k = av_fetch(av, i, 0);
        STRLEN kl;
        const char *ks;
        if (!(k && *k)) continue;
        ks = SvPV_const(*k, kl);
        if (kl == wlen && strnEQ(ks, want, wlen)) {
            SV **v = av_fetch(av, i + 1, 0);
            return (v && *v) ? *v : NULL;
        }
    }
    return NULL;
}

/* Pull one named field from a response, looking in the trailers first and
 * then the headers. `res` is a Fetch::Response or the raw simple_response
 * hash; both are hashes with `headers` and possibly `trailers`. */
static SV *otel_grpc_field(pTHX_ SV *res, const char *want, STRLEN wlen) {
    HV *h;
    SV **e;
    SV *found;
    if (!res || !SvROK(res) || SvTYPE(SvRV(res)) != SVt_PVHV) return NULL;
    h = (HV *)SvRV(res);
    e = hv_fetchs(h, "trailers", 0);
    if (e && *e) {
        found = otel_grpc_hdr(aTHX_ *e, want, wlen);
        if (found) return found;
    }
    e = hv_fetchs(h, "headers", 0);
    if (e && *e) return otel_grpc_hdr(aTHX_ *e, want, wlen);
    return NULL;
}

#endif /* OTEL_GRPC_H */
