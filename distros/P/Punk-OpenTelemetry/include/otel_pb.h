/* otel_pb.h - a protobuf writer for one fixed schema.
 *
 * OTLP's schema is small, versioned slowly, and entirely known at compile
 * time, so encoding it needs no descriptors, no reflection and no dependency:
 * a varint writer, a length-delimited writer, and the field numbers. That is
 * the whole of protobuf that OTLP uses.
 *
 * THE NESTING PROBLEM. Every embedded message is length-delimited, so a
 * parent cannot be written until its children's byte count is known. There
 * are two ways out: build backwards into a buffer, or walk twice - once to
 * measure, once to write. This takes the second. It costs a second pass over
 * data already in cache, and in exchange every size_* function sits beside
 * the write_* function it must agree with, where a reader can check them
 * against each other. Pointer arithmetic into a buffer being filled from the
 * end is faster to run and much harder to prove, and a wrong length here
 * produces bytes a collector rejects with no useful diagnostic.
 *
 * The two halves are kept honest by otel_pb_check (a debug build asserts that
 * what was written matches what was measured) and by the golden vectors in
 * t/01-protobuf.t.
 *
 * Needs Perl headers for SV/STRLEN/UV.
 */

#ifndef OTEL_PB_H
#define OTEL_PB_H

/* wire types */
#define PB_VARINT  0
#define PB_FIXED64 1
#define PB_BYTES   2
#define PB_FIXED32 5

/* A growable output buffer. An SV would do, but this is appended to once per
 * field on the hot path and SvGROW/SvCUR bookkeeping per call is exactly the
 * overhead worth not paying; the bytes become an SV once, at the end. */
typedef struct {
    char  *buf;
    size_t len;
    size_t cap;
} otel_buf;

static void otel_buf_init(otel_buf *b, size_t hint) {
    b->cap = hint > 64 ? hint : 64;
    Newx(b->buf, b->cap, char);
    b->len = 0;
}

static void otel_buf_free(otel_buf *b) {
    if (b->buf) Safefree(b->buf);
    b->buf = NULL; b->len = b->cap = 0;
}

static void otel_buf_need(otel_buf *b, size_t n) {
    if (b->len + n <= b->cap) return;
    while (b->cap < b->len + n) b->cap *= 2;
    Renew(b->buf, b->cap, char);
}

static void otel_buf_raw(otel_buf *b, const char *p, size_t n) {
    if (!n) return;
    otel_buf_need(b, n);
    memcpy(b->buf + b->len, p, n);
    b->len += n;
}

/* ---- varints ------------------------------------------------------------ */

/* How many bytes a varint of v takes. Base 128, seven bits a byte. */
static size_t otel_pb_varint_size(UV v) {
    size_t n = 1;
    while (v >= 0x80) { v >>= 7; n++; }
    return n;
}

static void otel_pb_varint(otel_buf *b, UV v) {
    otel_buf_need(b, 10);                    /* a 64-bit varint is at most 10 */
    while (v >= 0x80) {
        b->buf[b->len++] = (char)((v & 0x7f) | 0x80);
        v >>= 7;
    }
    b->buf[b->len++] = (char)v;
}

/* A tag is the field number and wire type in one varint. */
#define OTEL_PB_TAG(field, wire) ((UV)(((UV)(field) << 3) | (UV)(wire)))

static size_t otel_pb_tag_size(int field, int wire) {
    return otel_pb_varint_size(OTEL_PB_TAG(field, wire));
}

static void otel_pb_tag(otel_buf *b, int field, int wire) {
    otel_pb_varint(b, OTEL_PB_TAG(field, wire));
}

/* ---- scalar fields ------------------------------------------------------ *
 * Proto3 omits a field at its default value, and OTLP relies on that: a span
 * with no parent has no parent_span_id field at all rather than eight zero
 * bytes. Each writer below therefore takes the decision to emit at its call
 * site, not inside itself, because "zero" is a legitimate value for some of
 * these (a status code of 0 is UNSET and is genuinely omitted; a bucket count
 * of 0 inside a packed array is not). */

static size_t otel_pb_uint64_size(int field, UV v) {
    return otel_pb_tag_size(field, PB_VARINT) + otel_pb_varint_size(v);
}
static void otel_pb_uint64(otel_buf *b, int field, UV v) {
    otel_pb_tag(b, field, PB_VARINT);
    otel_pb_varint(b, v);
}

static size_t otel_pb_int32_size(int field, int v) {
    return otel_pb_tag_size(field, PB_VARINT) + otel_pb_varint_size((UV)v);
}
static void otel_pb_int32(otel_buf *b, int field, int v) {
    otel_pb_tag(b, field, PB_VARINT);
    otel_pb_varint(b, (UV)v);
}

static size_t otel_pb_bool_size(int field) {
    return otel_pb_tag_size(field, PB_VARINT) + 1;
}
static void otel_pb_bool(otel_buf *b, int field, int v) {
    otel_pb_tag(b, field, PB_VARINT);
    otel_pb_varint(b, v ? 1 : 0);
}

/* fixed64, little endian. OTLP uses it for the nanosecond timestamps, which
 * are always large, so a varint would cost more than the eight bytes. */
static size_t otel_pb_fixed64_size(int field) {
    return otel_pb_tag_size(field, PB_FIXED64) + 8;
}
static void otel_pb_fixed64(otel_buf *b, int field, U64TYPE v) {
    int i;
    otel_pb_tag(b, field, PB_FIXED64);
    otel_buf_need(b, 8);
    for (i = 0; i < 8; i++) b->buf[b->len++] = (char)((v >> (i * 8)) & 0xff);
}

/* a double, as its IEEE-754 bits in fixed64 */
static size_t otel_pb_double_size(int field) {
    return otel_pb_tag_size(field, PB_FIXED64) + 8;
}
static void otel_pb_double(otel_buf *b, int field, double d) {
    U64TYPE bits;
    Copy(&d, &bits, 1, U64TYPE);
    otel_pb_fixed64(b, field, bits);
}

/* ---- length-delimited --------------------------------------------------- */

static size_t otel_pb_bytes_size(int field, size_t n) {
    return otel_pb_tag_size(field, PB_BYTES) + otel_pb_varint_size((UV)n) + n;
}
static void otel_pb_bytes(otel_buf *b, int field, const char *p, size_t n) {
    otel_pb_tag(b, field, PB_BYTES);
    otel_pb_varint(b, (UV)n);
    otel_buf_raw(b, p, n);
}

/* An embedded message: the same shape, with the child's measured size as the
 * length. The caller writes the child straight after. */
static size_t otel_pb_msg_size(int field, size_t inner) {
    return otel_pb_tag_size(field, PB_BYTES) + otel_pb_varint_size((UV)inner)
         + inner;
}
static void otel_pb_msg_head(otel_buf *b, int field, size_t inner) {
    otel_pb_tag(b, field, PB_BYTES);
    otel_pb_varint(b, (UV)inner);
}

/* ---- packed repeated fields --------------------------------------------- *
 * A repeated numeric field is encoded as ONE length-delimited field holding
 * the values back to back, not as a tag per value. Emitting the unpacked form
 * is legal proto2 and is accepted by most parsers, but the OTLP schema
 * declares these packed and some consumers read them strictly - so a
 * histogram's buckets would arrive empty from something that only accepts
 * what the schema promised. */

static size_t otel_pb_packed_u64_size(int field, const IV *v, int n) {
    size_t inner = 0;
    int i;
    for (i = 0; i < n; i++) inner += 8;          /* fixed64 elements */
    PERL_UNUSED_VAR(v);
    return otel_pb_tag_size(field, PB_BYTES)
         + otel_pb_varint_size((UV)inner) + inner;
}
static void otel_pb_packed_u64(otel_buf *b, int field, const IV *v, int n) {
    int i, j;
    otel_pb_tag(b, field, PB_BYTES);
    otel_pb_varint(b, (UV)(n * 8));
    otel_buf_need(b, (size_t)n * 8);
    for (i = 0; i < n; i++) {
        U64TYPE u = (U64TYPE)v[i];
        for (j = 0; j < 8; j++) b->buf[b->len++] = (char)((u >> (j * 8)) & 0xff);
    }
}

/* packed varints, for repeated uint64 (the exponential histogram's buckets) */
static size_t otel_pb_packed_varint_size(int field, const IV *v, int n) {
    size_t inner = 0;
    int i;
    for (i = 0; i < n; i++) inner += otel_pb_varint_size((UV)v[i]);
    return otel_pb_tag_size(field, PB_BYTES)
         + otel_pb_varint_size((UV)inner) + inner;
}
static void otel_pb_packed_varint(otel_buf *b, int field, const IV *v, int n) {
    size_t inner = 0;
    int i;
    for (i = 0; i < n; i++) inner += otel_pb_varint_size((UV)v[i]);
    otel_pb_tag(b, field, PB_BYTES);
    otel_pb_varint(b, (UV)inner);
    for (i = 0; i < n; i++) otel_pb_varint(b, (UV)v[i]);
}

static size_t otel_pb_packed_double_size(int field, int n) {
    return otel_pb_tag_size(field, PB_BYTES)
         + otel_pb_varint_size((UV)(n * 8)) + (size_t)n * 8;
}
static void otel_pb_packed_double(otel_buf *b, int field, const double *v,
                                  int n) {
    int i, j;
    otel_pb_tag(b, field, PB_BYTES);
    otel_pb_varint(b, (UV)(n * 8));
    otel_buf_need(b, (size_t)n * 8);
    for (i = 0; i < n; i++) {
        U64TYPE bits;
        Copy(&v[i], &bits, 1, U64TYPE);
        for (j = 0; j < 8; j++) b->buf[b->len++] = (char)((bits >> (j*8)) & 0xff);
    }
}

/* The assertion that keeps the two passes honest: after writing a child, the
 * bytes actually appended must equal what size_* promised. A mismatch means a
 * size function and its writer have drifted, which produces a length prefix
 * that lies - and a collector rejecting the payload with nothing useful to
 * say about why. Compiled out of a normal build. */
#ifdef OTEL_PB_ASSERT
#  define OTEL_PB_CHECK(b, mark, expect, what)                             \
      do { size_t _got = (b)->len - (mark);                                \
           if (_got != (size_t)(expect))                                   \
               croak("Punk::OpenTelemetry: %s wrote %lu bytes, measured "  \
                     "%lu - a size_ function and its writer disagree",     \
                     (what), (unsigned long)_got,                          \
                     (unsigned long)(expect)); } while (0)
#else
#  define OTEL_PB_CHECK(b, mark, expect, what) ((void)0)
#endif

#endif /* OTEL_PB_H */
