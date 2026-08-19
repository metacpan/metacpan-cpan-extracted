/* otel_span.h - a span, as a C struct.
 *
 * The span is the thing there is one of per operation, so its cost is the
 * SDK's cost. It holds ids, times, kind, status and three bounded lists, and
 * it materialises no SV until something asks for one.
 *
 * SPAN LIMITS. The spec caps attributes, events and links, and requires the
 * count of what was dropped to be reported. Both halves matter, and the
 * second more than the first: a span that quietly loses its 129th attribute
 * looks complete, and someone will spend an afternoon working out why the
 * attribute they added is missing. A span that says "129 attributes, 1
 * dropped" answers that question before it is asked.
 *
 * ATTRIBUTE STORAGE. Keys and values are Perl SVs, because they came from
 * Perl and go back to Perl at export - and because the encoder in phase 2
 * already takes SVs. What is avoided is an SV per SPAN, and the per-span
 * hashes and blessed wrappers a Perl-side implementation would build. An
 * unsampled span allocates none of this at all: it is never created.
 */

#ifndef OTEL_SPAN_H
#define OTEL_SPAN_H

#include "otel_clock.h"
#include "otel_id.h"
#include "otel_proto.h"

/* The spec defaults. */
#define OTEL_LIMIT_ATTRS  128
#define OTEL_LIMIT_EVENTS 128
#define OTEL_LIMIT_LINKS  128

typedef struct otel_event {
    SV      *name;
    U64TYPE  time;
    HV      *attrs;          /* +1 owned, or NULL */
    struct otel_event *next;
} otel_event;

typedef struct otel_link {
    unsigned char trace_id[16];
    unsigned char span_id[8];
    HV      *attrs;
    struct otel_link *next;
} otel_link;

typedef struct otel_span {
    unsigned char trace_id[16];
    unsigned char span_id[8];
    unsigned char parent_id[8];
    int      has_parent;
    int      sampled;

    SV      *name;           /* +1 owned */
    int      kind;
    U64TYPE  start_wall;     /* unix nanos: where the span sits in time */
    U64TYPE  start_mono;     /* monotonic: only for the duration */
    U64TYPE  end_wall;       /* derived; 0 until ended */
    int      ended;

    int      status_code;
    SV      *status_message; /* +1 owned, or NULL */

    HV      *attrs;          /* +1 owned */
    IV       dropped_attrs;

    otel_event *events, *events_tail;
    IV       n_events, dropped_events;

    otel_link  *links, *links_tail;
    IV       n_links, dropped_links;

    SV      *trace_state;    /* +1 owned, or NULL */
} otel_span;

static otel_span *otel_span_new(pTHX) {
    otel_span *s;
    Newxz(s, 1, otel_span);
    s->attrs      = newHV();
    s->kind       = OTEL_KIND_INTERNAL;
    s->status_code = OTEL_STATUS_UNSET;
    s->start_wall = otel_wall_nanos();
    s->start_mono = otel_mono_nanos();
    return s;
}

static void otel_span_free(pTHX_ otel_span *s) {
    otel_event *e;
    otel_link  *l;
    if (!s) return;
    if (s->name)           SvREFCNT_dec(s->name);
    if (s->status_message) SvREFCNT_dec(s->status_message);
    if (s->trace_state)    SvREFCNT_dec(s->trace_state);
    if (s->attrs)          SvREFCNT_dec((SV *)s->attrs);
    for (e = s->events; e; ) {
        otel_event *n = e->next;
        if (e->name)  SvREFCNT_dec(e->name);
        if (e->attrs) SvREFCNT_dec((SV *)e->attrs);
        Safefree(e);
        e = n;
    }
    for (l = s->links; l; ) {
        otel_link *n = l->next;
        if (l->attrs) SvREFCNT_dec((SV *)l->attrs);
        Safefree(l);
        l = n;
    }
    Safefree(s);
}

/* Set an attribute, honouring the cap.
 *
 * An existing key is replaced and does NOT count against the limit or the
 * dropped count: overwriting is not adding. Getting that wrong makes a loop
 * that updates one attribute look like a span with a hundred dropped ones. */
static void otel_span_attr(pTHX_ otel_span *s, SV *key, SV *val) {
    if (!s || !key) return;
    if (hv_exists_ent(s->attrs, key, 0)) {
        (void)hv_store_ent(s->attrs, key, newSVsv(val), 0);
        return;
    }
    if ((IV)HvUSEDKEYS(s->attrs) >= OTEL_LIMIT_ATTRS) {
        s->dropped_attrs++;
        return;
    }
    (void)hv_store_ent(s->attrs, key, newSVsv(val), 0);
}

static void otel_span_event(pTHX_ otel_span *s, SV *name, HV *attrs) {
    otel_event *e;
    if (!s) return;
    if (s->n_events >= OTEL_LIMIT_EVENTS) { s->dropped_events++; return; }
    Newxz(e, 1, otel_event);
    e->name  = name ? newSVsv(name) : NULL;
    e->time  = otel_wall_nanos();
    e->attrs = attrs ? (HV *)SvREFCNT_inc((SV *)attrs) : NULL;
    if (s->events_tail) s->events_tail->next = e;
    else                s->events = e;
    s->events_tail = e;
    s->n_events++;
}

static void otel_span_link(pTHX_ otel_span *s, const unsigned char *tid,
                           const unsigned char *sid, HV *attrs) {
    otel_link *l;
    if (!s || !tid || !sid) return;
    if (s->n_links >= OTEL_LIMIT_LINKS) { s->dropped_links++; return; }
    Newxz(l, 1, otel_link);
    Copy(tid, l->trace_id, 16, unsigned char);
    Copy(sid, l->span_id,   8, unsigned char);
    l->attrs = attrs ? (HV *)SvREFCNT_inc((SV *)attrs) : NULL;
    if (s->links_tail) s->links_tail->next = l;
    else               s->links = l;
    s->links_tail = l;
    s->n_links++;
}

/* End the span. Idempotent: ending twice is a bug in the caller, not a reason
 * to move the end timestamp, and a scoped guard firing after an explicit end
 * is the ordinary way it happens. */
static void otel_span_end(pTHX_ otel_span *s) {
    if (!s || s->ended) return;
    s->end_wall = otel_end_nanos(s->start_wall, s->start_mono);
    s->ended = 1;
}

/* ---- to the payload shape the phase-2 encoder takes --------------------- */

static SV *otel_span_to_hv(pTHX_ otel_span *s) {
    HV *h = newHV();
    char hex[32];
    otel_event *e;
    otel_link  *l;
    AV *av;

    otel_bytes_to_hex(s->trace_id, 16, hex);
    (void)hv_stores(h, "trace_id", newSVpvn(hex, 32));
    otel_bytes_to_hex(s->span_id, 8, hex);
    (void)hv_stores(h, "span_id", newSVpvn(hex, 16));
    if (s->has_parent) {
        otel_bytes_to_hex(s->parent_id, 8, hex);
        (void)hv_stores(h, "parent_span_id", newSVpvn(hex, 16));
    }
    if (s->trace_state)
        (void)hv_stores(h, "trace_state", newSVsv(s->trace_state));
    if (s->name) (void)hv_stores(h, "name", newSVsv(s->name));
    (void)hv_stores(h, "kind", newSViv(s->kind));
    (void)hv_stores(h, "start_time_unix_nano", newSVuv((UV)s->start_wall));
    (void)hv_stores(h, "end_time_unix_nano",
                    newSVuv((UV)(s->ended ? s->end_wall
                                          : otel_end_nanos(s->start_wall,
                                                           s->start_mono))));
    (void)hv_stores(h, "attributes", newRV_inc((SV *)s->attrs));
    if (s->dropped_attrs)
        (void)hv_stores(h, "dropped_attributes_count",
                        newSViv(s->dropped_attrs));

    if (s->events) {
        av = newAV();
        for (e = s->events; e; e = e->next) {
            HV *eh = newHV();
            if (e->name) (void)hv_stores(eh, "name", newSVsv(e->name));
            (void)hv_stores(eh, "time_unix_nano", newSVuv((UV)e->time));
            if (e->attrs)
                (void)hv_stores(eh, "attributes", newRV_inc((SV *)e->attrs));
            av_push(av, newRV_noinc((SV *)eh));
        }
        (void)hv_stores(h, "events", newRV_noinc((SV *)av));
    }
    if (s->dropped_events)
        (void)hv_stores(h, "dropped_events_count", newSViv(s->dropped_events));

    if (s->links) {
        av = newAV();
        for (l = s->links; l; l = l->next) {
            HV *lh = newHV();
            otel_bytes_to_hex(l->trace_id, 16, hex);
            (void)hv_stores(lh, "trace_id", newSVpvn(hex, 32));
            otel_bytes_to_hex(l->span_id, 8, hex);
            (void)hv_stores(lh, "span_id", newSVpvn(hex, 16));
            if (l->attrs)
                (void)hv_stores(lh, "attributes", newRV_inc((SV *)l->attrs));
            av_push(av, newRV_noinc((SV *)lh));
        }
        (void)hv_stores(h, "links", newRV_noinc((SV *)av));
    }
    if (s->dropped_links)
        (void)hv_stores(h, "dropped_links_count", newSViv(s->dropped_links));

    if (s->status_code != OTEL_STATUS_UNSET || s->status_message) {
        HV *st = newHV();
        (void)hv_stores(st, "code", newSViv(s->status_code));
        if (s->status_message)
            (void)hv_stores(st, "message", newSVsv(s->status_message));
        (void)hv_stores(h, "status", newRV_noinc((SV *)st));
    }
    /* the W3C sampled flag, which OTLP carries on the span too */
    if (s->sampled) (void)hv_stores(h, "flags", newSVuv(OTEL_FLAG_SAMPLED));
    return newRV_noinc((SV *)h);
}

#endif /* OTEL_SPAN_H */
