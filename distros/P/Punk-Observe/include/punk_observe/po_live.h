/* po_live.h - the live tail: what it sends, and what it admits losing.
 *
 * A browser tailing logs is connected to ONE worker. The lines it wants are
 * being ingested by ALL of them. So an ingesting worker publishes matching
 * records on a per-tenant topic and whichever worker holds the connection
 * forwards them.
 *
 * THE TRANSPORT REFUSES OVERSIZE RATHER THAN TRUNCATING.
 *
 * The ring fixes a slot and REFUSES a record that does not fit one, and the
 * old bus before it returned HM_BUS_OVERSIZE for
 * anything larger - refused, never shortened. Handing it a long log line
 * therefore does not produce a short line, it produces NO line, and the tail
 * would silently skip exactly the interesting ones: a stack trace, a
 * serialised payload, the thing somebody is tailing to find.
 *
 * So the record is truncated HERE, deliberately, with a flag saying so. A
 * truncation the reader can see is a different thing from a line that never
 * arrived, and the difference is the entire point of this file.
 *
 * The same honesty runs through the rest of it. A lapped consumer, a resume
 * past the end of the buffer and a client that stopped reading are all
 * REPORTED with a number rather than papered over: a silently short stream is
 * indistinguishable from a quiet one.
 */
#ifndef PO_LIVE_H
#define PO_LIVE_H

#include "punk_observe/po_compat.h"
#include "punk_observe/po_store.h"

/* Matches HM_BUS_SLOT_SIZE. Defined independently so this header does not
 * require the bus to exist, and asserted equal where it does. */
#define PO_TAIL_SLOT      2048

/* The framing a slot carries besides the body: the fixed header below, plus
 * headroom for the topic the bus stores alongside it. A body sized to the
 * whole slot is a body that will be refused. */
#define PO_TAIL_OVERHEAD  128
#define PO_TAIL_BODY_MAX  (PO_TAIL_SLOT - PO_TAIL_OVERHEAD)

#define PO_TAIL_TRUNCATED 1u

#define PO_TAIL_TOPIC_MAX (PO_TENANT_MAX + 16)

/* ---- the topic, which is the tenant boundary ------------------------------
 *
 * A tail is a query and carries a tenant, so the topic contains the tenant id
 * and a connection can subscribe only to its own. Built through the same
 * allowlist that guards every path, because a topic that accepts arbitrary
 * bytes is a way to subscribe to somebody else's stream. */
static size_t po_tail_topic(const char *tenant, size_t tlen,
                            char *out, size_t cap) {
    static const char pre[] = "po.tail.";
    size_t n = sizeof(pre) - 1;
    if (!po_tenant_ok(tenant, tlen)) return 0;
    if (n + tlen >= cap) return 0;
    memcpy(out, pre, n);
    memcpy(out + n, tenant, tlen);
    out[n + tlen] = '\0';
    return n + tlen;
}

/* ---- one record on the wire ------------------------------------------------
 *
 *   [t_unix_nano][stream][severity][flags][service_len][body_len] bytes...
 *
 * Fixed fields first so a reader can size the rest before touching it. */
typedef struct {
    po_u64   t_unix_nano;
    po_u64   stream;
    uint32_t severity;
    uint32_t flags;
    const char *service; size_t service_len;
    const char *body;    size_t body_len;
} po_tail_rec;

/* Encode into `out`, which must hold PO_TAIL_SLOT bytes. Returns the length.
 *
 * THE BODY IS CUT TO FIT AND THE FLAG IS SET. Never a refusal, never a silent
 * drop, and never a length the transport will reject. */
static size_t po_tail_encode(const po_tail_rec *r, char *out, int *truncated) {
    size_t n = 0, svc = r->service_len, body = r->body_len, room;
    uint32_t u32;
    po_u64 u64;
    int cut = 0;

    if (svc > 128) { svc = 128; cut = 1; }

    /* What is left for the body once the fixed fields and the service name
     * have taken their share. Computed by subtraction, never as a sum that
     * could overflow past the slot. */
    room = PO_TAIL_BODY_MAX;
    room = room > (8 + 8 + 4 + 4 + 4 + 4) ? room - (8 + 8 + 4 + 4 + 4 + 4) : 0;
    room = room > svc ? room - svc : 0;
    if (body > room) { body = room; cut = 1; }

    u64 = po_le64(r->t_unix_nano); memcpy(out + n, &u64, 8); n += 8;
    u64 = po_le64(r->stream);      memcpy(out + n, &u64, 8); n += 8;
    u32 = po_le32(r->severity);    memcpy(out + n, &u32, 4); n += 4;
    u32 = po_le32(r->flags | (cut ? PO_TAIL_TRUNCATED : 0u));
    memcpy(out + n, &u32, 4); n += 4;
    u32 = po_le32((uint32_t)svc);  memcpy(out + n, &u32, 4); n += 4;
    u32 = po_le32((uint32_t)body); memcpy(out + n, &u32, 4); n += 4;
    if (svc)  memcpy(out + n, r->service, svc);  n += svc;
    if (body) memcpy(out + n, r->body, body);    n += body;

    if (truncated) *truncated = cut;
    return n;
}

/* Decode, borrowing into the buffer. Returns 0 on anything that does not add
 * up - a slot is untrusted input the moment another process wrote it. */
static int po_tail_decode(const char *p, size_t len, po_tail_rec *r) {
    uint32_t svc, body;
    if (len < 32) return 0;
    memset(r, 0, sizeof(*r));
    memcpy(&r->t_unix_nano, p,      8); r->t_unix_nano = po_le64(r->t_unix_nano);
    memcpy(&r->stream,      p + 8,  8); r->stream      = po_le64(r->stream);
    memcpy(&r->severity,    p + 16, 4); r->severity    = po_le32(r->severity);
    memcpy(&r->flags,       p + 20, 4); r->flags       = po_le32(r->flags);
    memcpy(&svc,            p + 24, 4); svc            = po_le32(svc);
    memcpy(&body,           p + 28, 4); body           = po_le32(body);
    /* Subtraction, not addition: `32 + svc + body > len` wraps. */
    if (svc > len - 32) return 0;
    if (body > len - 32 - svc) return 0;
    r->service     = svc  ? p + 32       : NULL;
    r->service_len = svc;
    r->body        = body ? p + 32 + svc : NULL;
    r->body_len    = body;
    return 1;
}

static int po_tail_is_truncated(const po_tail_rec *r) {
    return (r->flags & PO_TAIL_TRUNCATED) != 0;
}

/* ---- the per-connection ring -----------------------------------------------
 *
 * A busy tail appends thousands of rows a minute. Unbounded, the browser tab
 * consumes a gigabyte and stops responding within the hour, and the user's
 * conclusion is that the product is broken. So the server-side buffer that
 * backs Last-Event-ID is bounded too, and what falls off the end is COUNTED.
 *
 * Event ids are monotonic from 1. Zero means "no id", which is what a fresh
 * connection sends. */
#define PO_RING_ROWS  512               /* rows held for a resume       */
#define PO_RING_BYTES ((po_u64)512 * 1024)  /* and the ceiling in bytes */

typedef struct { po_u64 id; char *p; size_t len; } po_ring_ent;

typedef struct {
    po_ring_ent *e;
    uint32_t     cap, n, head;
    po_u64       next_id;    /* the id the next push will carry */
    po_u64       evicted;    /* rows that scrolled off the back */
    po_u64       bytes, bytes_max;
} po_tail_ring;

/* Bounded by BOTH rows and bytes, and the second bound is the one that
 * matters: 512 slots at the full 2048 would be a megabyte per connection held
 * for a resume nobody may ever ask for. Rows are stored at their real length,
 * not at the slot size. */
static int po_tail_ring_init(po_tail_ring *r, uint32_t rows, po_u64 bytes) {
    memset(r, 0, sizeof(*r));
    r->cap = rows ? rows : PO_RING_ROWS;
    r->bytes_max = bytes ? bytes : PO_RING_BYTES;
    r->next_id = 1;
    r->e = (po_ring_ent *)calloc(r->cap, sizeof(po_ring_ent));
    return r->e != NULL;
}

static void po_tail_ring_free(po_tail_ring *r) {
    uint32_t i;
    if (r->e) for (i = 0; i < r->cap; i++) free(r->e[i].p);
    free(r->e);
    r->e = NULL; r->n = 0;
}

static uint32_t po_ring_tail_idx(const po_tail_ring *r) {
    return (r->head + r->cap - r->n) % r->cap;
}

static void po_ring_evict_one(po_tail_ring *r) {
    uint32_t idx = po_ring_tail_idx(r);
    r->bytes -= (po_u64)r->e[idx].len;
    free(r->e[idx].p);
    r->e[idx].p = NULL; r->e[idx].len = 0;
    r->n--;
    r->evicted++;
}

/* Returns the id, or 0 if the row could not be stored. */
static po_u64 po_tail_ring_push(po_tail_ring *r, const char *p, size_t len) {
    char *copy;
    uint32_t idx;

    if (len > PO_TAIL_SLOT) len = PO_TAIL_SLOT;
    copy = (char *)malloc(len ? len : 1);
    if (!copy) return 0;
    memcpy(copy, p, len);

    while (r->n == r->cap
           || (r->n && r->bytes + (po_u64)len > r->bytes_max))
        po_ring_evict_one(r);

    idx = r->head;
    free(r->e[idx].p);
    r->e[idx].id  = r->next_id;
    r->e[idx].p   = copy;
    r->e[idx].len = len;
    r->bytes += (po_u64)len;
    r->head = (r->head + 1) % r->cap;
    r->n++;
    return r->next_id++;
}

/* The oldest id still held, or 0 when the ring is empty. */
static po_u64 po_tail_ring_oldest(const po_tail_ring *r) {
    if (!r->n) return 0;
    return r->e[po_ring_tail_idx(r)].id;
}

/* Entry i of the resume window, counting from the oldest kept. */
static const po_ring_ent *po_tail_ring_at(const po_tail_ring *r, uint32_t i) {
    if (i >= r->n) return NULL;
    return &r->e[(po_ring_tail_idx(r) + i) % r->cap];
}

/* Resume after `since`.
 *
 * Returns how many entries follow it and, through `missed`, HOW MANY WERE
 * LOST between what the client last saw and the oldest thing still held. A
 * reconnection that quietly starts from the oldest available row hides a gap,
 * and a gap the reader cannot see is the failure this whole file exists to
 * prevent.
 *
 * `since == 0` is a fresh connection: everything held, nothing missed,
 * because it never saw anything to miss. */
static uint32_t po_tail_ring_since(const po_tail_ring *r, po_u64 since,
                                   uint32_t *first, po_u64 *missed) {
    po_u64 oldest = po_tail_ring_oldest(r);
    uint32_t i;

    if (missed) *missed = 0;
    if (first) *first = 0;
    if (!r->n) return 0;

    if (since == 0) return r->n;

    if (missed && since + 1 < oldest) *missed = oldest - since - 1;
    for (i = 0; i < r->n; i++) {
        const po_ring_ent *e = po_tail_ring_at(r, i);
        if (e->id > since) { if (first) *first = i; return r->n - i; }
    }
    return 0;
}

/* ---- backpressure ----------------------------------------------------------
 *
 * A browser that has stopped reading must not become an unbounded queue in
 * the server. Over the threshold the connection is CLOSED WITH A REASON,
 * which the client can act on, rather than the worker growing a buffer until
 * something else fails. */
typedef struct {
    po_u64 pending;      /* bytes written but not yet drained */
    po_u64 limit;
    po_u64 dropped;      /* rows never queued because the client was behind */
    int    closed;
} po_tail_flow;

static void po_tail_flow_init(po_tail_flow *f, po_u64 limit) {
    memset(f, 0, sizeof(*f));
    f->limit = limit ? limit : (po_u64)1024 * 1024;
}

/* Returns 1 when the row may be queued, 0 when the connection has been closed
 * for falling too far behind. */
static int po_tail_flow_admit(po_tail_flow *f, size_t bytes) {
    if (f->closed) return 0;
    if (f->pending + (po_u64)bytes > f->limit) {
        f->closed = 1;
        f->dropped++;
        return 0;
    }
    f->pending += (po_u64)bytes;
    return 1;
}

static void po_tail_flow_drained(po_tail_flow *f, size_t bytes) {
    f->pending = f->pending > (po_u64)bytes ? f->pending - (po_u64)bytes : 0;
}

/* ---- the SSE frame ---------------------------------------------------------
 *
 * `id:` is what makes Last-Event-ID work at all, so it is never omitted. A
 * frame ends with a blank line, and a body containing a newline has to be
 * split across `data:` lines or the frame ends early and the rest of the line
 * becomes the next event. */
static size_t po_sse_frame(po_u64 id, const char *ev, size_t evlen,
                           const char *data, size_t dlen,
                           char *out, size_t cap) {
    size_t n = 0, i, start;
    char idbuf[24];
    size_t idn = 0;
    po_u64 v = id;

    if (v == 0) idbuf[idn++] = '0';
    else { char t[24]; size_t k = 0;
           while (v) { t[k++] = (char)('0' + (int)(v % 10)); v /= 10; }
           while (k) idbuf[idn++] = t[--k]; }

    if (cap < idn + evlen + dlen + 32) return 0;

    memcpy(out + n, "id: ", 4); n += 4;
    memcpy(out + n, idbuf, idn); n += idn;
    out[n++] = '\n';

    if (evlen) {
        memcpy(out + n, "event: ", 7); n += 7;
        memcpy(out + n, ev, evlen); n += evlen;
        out[n++] = '\n';
    }

    start = 0;
    for (i = 0; i <= dlen; i++) {
        if (i == dlen || data[i] == '\n') {
            memcpy(out + n, "data: ", 6); n += 6;
            if (i > start) memcpy(out + n, data + start, i - start);
            n += i - start;
            out[n++] = '\n';
            start = i + 1;
            if (i == dlen) break;
        }
    }
    out[n++] = '\n';
    return n;
}

/* An idle stream is closed by intermediaries, so a heartbeat is not optional.
 * A comment frame carries no event and no id, which is exactly right: it must
 * not advance a client's Last-Event-ID. */
static size_t po_sse_heartbeat(char *out, size_t cap) {
    if (cap < 3) return 0;
    memcpy(out, ":\n\n", 3);
    return 3;
}

#endif /* PO_LIVE_H */
