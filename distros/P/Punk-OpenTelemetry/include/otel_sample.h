/* otel_sample.h - whether to record this trace.
 *
 * THE RULE THAT MATTERS: the ratio decision is derived from the TRACE ID, not
 * from a random draw per service.
 *
 * Consider a request crossing three services, all sampling at 10%. With a
 * coin flip per service, each independently keeps a tenth - so the chance all
 * three keep the same trace is one in a thousand, and what a backend receives
 * is a stream of one-span fragments with dangling parents. The dashboard says
 * 10% sampling; what it actually has is 10% of spans and almost no complete
 * traces. Every service having flipped a fair coin is no comfort at all.
 *
 * Deriving the decision from the trace id makes it the SAME decision
 * everywhere the trace goes, with no coordination: the id is already
 * propagated, and every service computes the same answer from it. 10%
 * sampling then means 10% of traces, complete.
 *
 * The algorithm is the spec's: take the low 8 bytes of the trace id as a
 * big-endian unsigned integer and keep the trace when it is below a
 * threshold derived from the ratio.
 *
 * ParentBased wraps it: a trace that already carries a decision inherits it,
 * because a service that re-decides mid-trace produces exactly the fragments
 * this is here to prevent. Only a ROOT span consults the ratio.
 */

#ifndef OTEL_SAMPLE_H
#define OTEL_SAMPLE_H

/* the sampler kinds */
#define OTEL_SAMPLER_PARENT_RATIO 0   /* ParentBased(TraceIdRatioBased) */
#define OTEL_SAMPLER_ALWAYS_ON    1
#define OTEL_SAMPLER_ALWAYS_OFF   2

/* W3C traceparent flags */
#define OTEL_FLAG_SAMPLED 0x01

typedef struct {
    int      kind;
    double   ratio;        /* 0.0 .. 1.0 */
    U64TYPE  threshold;    /* ratio scaled to the 64-bit id space */
} otel_sampler;

static void otel_sampler_init(otel_sampler *s, int kind, double ratio) {
    s->kind = kind;
    if (ratio < 0.0) ratio = 0.0;
    if (ratio > 1.0) ratio = 1.0;
    s->ratio = ratio;
    /* 1.0 has to be exactly "everything": computing it as a scaled double
     * risks landing one short of UINT64_MAX and silently dropping the one
     * trace whose id is all ones. */
    if (ratio >= 1.0)      s->threshold = ~(U64TYPE)0;
    else if (ratio <= 0.0) s->threshold = 0;
    else s->threshold = (U64TYPE)(ratio * 18446744073709551616.0);
}

/* The low 8 bytes of a trace id, big-endian. */
static U64TYPE otel_trace_id_low(const unsigned char *tid) {
    U64TYPE v = 0;
    int i;
    for (i = 8; i < 16; i++) v = (v << 8) | (U64TYPE)tid[i];
    return v;
}

/* Would the ratio alone keep this trace? Deterministic in the trace id, so
 * every service in the trace computes the same answer. */
static int otel_ratio_sampled(const otel_sampler *s, const unsigned char *tid) {
    if (s->threshold == 0)          return 0;
    if (s->threshold == ~(U64TYPE)0) return 1;
    return otel_trace_id_low(tid) < s->threshold;
}

/* The decision.
 *
 * has_parent: a valid inbound trace context was extracted.
 * parent_sampled: its sampled flag.
 *
 * ParentBased: an existing decision is INHERITED, including a decision not to
 * sample. A service that overrides its parent produces a trace with holes in
 * the middle, which is harder to read than no trace at all. */
static int otel_should_sample(const otel_sampler *s, const unsigned char *tid,
                              int has_parent, int parent_sampled) {
    switch (s->kind) {
        case OTEL_SAMPLER_ALWAYS_ON:  return 1;
        case OTEL_SAMPLER_ALWAYS_OFF: return 0;
        default:
            if (has_parent) return parent_sampled ? 1 : 0;
            return otel_ratio_sampled(s, tid);
    }
}

#endif /* OTEL_SAMPLE_H */
