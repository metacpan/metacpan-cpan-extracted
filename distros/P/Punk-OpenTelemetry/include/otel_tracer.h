/* otel_tracer.h - the tracer: what starts spans, and what holds them until
 * they are exported.
 *
 * THE BATCH QUEUE, and the doctrine it is built on.
 *
 * The queue is BOUNDED and drops the OLDEST span when it is full, and it
 * counts what it dropped. Every part of that is deliberate:
 *
 *   - Bounded, because an unbounded queue in front of an unreachable
 *     collector is not a queue, it is a memory leak with a schedule. The
 *     failure it produces is a web server dying of OOM some hours after a
 *     collector went down, which is a far worse outage than the missing
 *     telemetry.
 *
 *   - Drop-oldest rather than drop-newest, because when a system is in
 *     trouble the interesting spans are the recent ones. Keeping the oldest
 *     preserves a snapshot of the moment things were still fine.
 *
 *   - Counted, and the count exported, because a telemetry layer that cannot
 *     report its own losses is asking to be trusted for no reason. A gap in a
 *     trace with a number beside it is a diagnosis; a gap without one is a
 *     mystery.
 *
 * This is Maat::Shipper's rule restated: the job is not "do not lose data",
 * it is DO NOT BECOME THE PROBLEM.
 */

#ifndef OTEL_TRACER_H
#define OTEL_TRACER_H

#include "otel_id.h"
#include "otel_sample.h"
#include "otel_span.h"

/* The spec's BatchSpanProcessor defaults. */
#define OTEL_QUEUE_MAX     2048
#define OTEL_BATCH_MAX      512

typedef struct {
    otel_sampler sampler;

    HV      *resource;        /* +1 owned: attributes, hashref */
    SV      *scope_name;
    SV      *scope_version;
    SV      *schema_url;        /* the resource's */
    SV      *scope_schema_url;   /* the scope's, which may legitimately differ */

    /* the bounded ring of ended spans awaiting export */
    otel_span **queue;
    int      qcap, qhead, qcount;

    /* what happened, so the SDK can report its own losses */
    IV       started, ended, dropped_queue, sampled_out;

    pid_t    owner_pid;       /* the process this tracer's queue belongs to */
} otel_tracer;

static otel_tracer *otel_tracer_new(pTHX) {
    otel_tracer *t;
    Newxz(t, 1, otel_tracer);
    otel_sampler_init(&t->sampler, OTEL_SAMPLER_PARENT_RATIO, 1.0);
    t->resource = newHV();
    t->qcap = OTEL_QUEUE_MAX;
    Newxz(t->queue, t->qcap, otel_span *);
    t->owner_pid = getpid();
    return t;
}

static void otel_tracer_free(pTHX_ otel_tracer *t) {
    int i;
    if (!t) return;
    for (i = 0; i < t->qcount; i++)
        otel_span_free(aTHX_ t->queue[(t->qhead + i) % t->qcap]);
    Safefree(t->queue);
    if (t->resource)      SvREFCNT_dec((SV *)t->resource);
    if (t->scope_name)    SvREFCNT_dec(t->scope_name);
    if (t->scope_version) SvREFCNT_dec(t->scope_version);
    if (t->schema_url)    SvREFCNT_dec(t->schema_url);
    if (t->scope_schema_url) SvREFCNT_dec(t->scope_schema_url);
    Safefree(t);
}

/* A worker that inherited a queue across fork would export the parent's spans
 * as its own, duplicating every one of them - once per worker. The queue
 * belongs to the process that filled it, so a child starts empty. */
static void otel_tracer_check_fork(pTHX_ otel_tracer *t) {
    pid_t me = getpid();
    int i;
    if (t->owner_pid == me) return;
    for (i = 0; i < t->qcount; i++)
        otel_span_free(aTHX_ t->queue[(t->qhead + i) % t->qcap]);
    t->qhead = t->qcount = 0;
    t->owner_pid = me;
}

/* Push an ended span, dropping the oldest when full. */
static void otel_tracer_enqueue(pTHX_ otel_tracer *t, otel_span *s) {
    otel_tracer_check_fork(aTHX_ t);
    if (t->qcount == t->qcap) {
        otel_span *old = t->queue[t->qhead];
        otel_span_free(aTHX_ old);
        t->qhead = (t->qhead + 1) % t->qcap;
        t->qcount--;
        t->dropped_queue++;
    }
    t->queue[(t->qhead + t->qcount) % t->qcap] = s;
    t->qcount++;
}

/* Start a span.
 *
 * An UNSAMPLED span returns NULL and allocates NOTHING. That is the property
 * that makes sampling worth having: at 1% the other 99% of requests must not
 * pay for a struct, a hash, an id or a timestamp. Everything above has to
 * cope with a NULL span, which is a small price for the 99%.
 *
 * parent_tid / parent_sid are the extracted inbound context, or NULL. */
static otel_span *otel_tracer_start(pTHX_ otel_tracer *t,
                                    const unsigned char *parent_tid,
                                    const unsigned char *parent_sid,
                                    int parent_sampled, SV *name, int kind) {
    unsigned char tid[16], sid[8];
    int has_parent = (parent_tid && parent_sid) ? 1 : 0;
    otel_span *s;

    if (has_parent) Copy(parent_tid, tid, 16, unsigned char);
    else if (!otel_gen_id(tid, 16)) return NULL;   /* no entropy: no trace */

    if (!otel_should_sample(&t->sampler, tid, has_parent, parent_sampled)) {
        t->sampled_out++;
        return NULL;
    }
    if (!otel_gen_id(sid, 8)) return NULL;

    s = otel_span_new(aTHX);
    Copy(tid, s->trace_id, 16, unsigned char);
    Copy(sid, s->span_id,   8, unsigned char);
    if (has_parent) {
        Copy(parent_sid, s->parent_id, 8, unsigned char);
        s->has_parent = 1;
    }
    s->sampled = 1;
    s->kind    = kind;
    if (name && SvOK(name)) s->name = newSVsv(name);
    t->started++;
    return s;
}

/* Take up to `max` spans off the queue as the payload the phase-2 encoder
 * wants. Returns NULL when there is nothing to send - the common case, and
 * the one that must not allocate. */
static SV *otel_tracer_drain(pTHX_ otel_tracer *t, int max) {
    HV *payload, *rs, *ss, *res, *scope;
    AV *rss, *sss, *spans;
    int n, i;

    otel_tracer_check_fork(aTHX_ t);
    if (t->qcount <= 0) return NULL;
    n = t->qcount < max ? t->qcount : max;

    spans = newAV();
    for (i = 0; i < n; i++) {
        otel_span *s = t->queue[t->qhead];
        t->queue[t->qhead] = NULL;
        t->qhead = (t->qhead + 1) % t->qcap;
        t->qcount--;
        av_push(spans, otel_span_to_hv(aTHX_ s));
        otel_span_free(aTHX_ s);
    }

    scope = newHV();
    if (t->scope_name)    (void)hv_stores(scope, "name", newSVsv(t->scope_name));
    if (t->scope_version) (void)hv_stores(scope, "version",
                                          newSVsv(t->scope_version));
    ss = newHV();
    (void)hv_stores(ss, "scope", newRV_noinc((SV *)scope));
    (void)hv_stores(ss, "spans", newRV_noinc((SV *)spans));
    if (t->scope_schema_url)
        (void)hv_stores(ss, "schema_url", newSVsv(t->scope_schema_url));
    sss = newAV();
    av_push(sss, newRV_noinc((SV *)ss));

    res = newHV();
    (void)hv_stores(res, "attributes", newRV_inc((SV *)t->resource));
    rs = newHV();
    (void)hv_stores(rs, "resource", newRV_noinc((SV *)res));
    (void)hv_stores(rs, "scope_spans", newRV_noinc((SV *)sss));
    if (t->schema_url)
        (void)hv_stores(rs, "schema_url", newSVsv(t->schema_url));
    rss = newAV();
    av_push(rss, newRV_noinc((SV *)rs));

    payload = newHV();
    (void)hv_stores(payload, "resource_spans", newRV_noinc((SV *)rss));
    return newRV_noinc((SV *)payload);
}

#endif /* OTEL_TRACER_H */
