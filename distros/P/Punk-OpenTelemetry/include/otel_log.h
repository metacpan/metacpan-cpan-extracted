/* otel_log.h - the logs signal.
 *
 * The cheapest of the three, because Punk 0.19 already did the hard part: a
 * log record is a message plus fields, which is exactly what an OTLP
 * LogRecord is. What remains is severity, trace correlation, and a queue.
 *
 * SEVERITY. Punk has five levels; OTLP has a 24-point scale in bands of four
 * (TRACE 1-4, DEBUG 5-8, INFO 9-12, WARN 13-16, ERROR 17-20, FATAL 21-24).
 * The mapping picks the FIRST value of each band rather than the middle,
 * because that is what every other SDK emits and because a backend filtering
 * "warn and above" compares against the band start. A number in the right
 * band is not enough if a dashboard's threshold is written as `>= 13`.
 *
 * THE TAP. These records are a COPY. The application's logs still go wherever
 * they were going - stderr, psgix.logger, a file - and the collector gets a
 * duplicate. A telemetry layer that silently redirects an operator's logs
 * somewhere else is a bad neighbour, and the failure mode when the collector
 * is down would be that the logs vanish.
 */

#ifndef OTEL_LOG_H
#define OTEL_LOG_H

#include "otel_clock.h"
#include "otel_span.h"

#define OTEL_SEV_TRACE  1
#define OTEL_SEV_DEBUG  5
#define OTEL_SEV_INFO   9
#define OTEL_SEV_WARN  13
#define OTEL_SEV_ERROR 17
#define OTEL_SEV_FATAL 21

/* Logs are far higher volume than spans, so the queue is bigger and has its
 * own drop counter - but it is the same bounded, drop-oldest, count-what-you
 * -dropped arrangement, for the same reasons. */
#define OTEL_LOG_QUEUE_MAX 4096

typedef struct {
    SV     *body;
    HV     *attrs;
    int     severity;
    SV     *severity_text;
    U64TYPE time;
    unsigned char trace_id[16];
    unsigned char span_id[8];
    int     has_span;
} otel_logrec;

typedef struct {
    otel_logrec *queue;
    int      qcap, qhead, qcount;
    IV       emitted, dropped;
    HV      *resource;
    SV      *scope_name, *scope_version;
    pid_t    owner_pid;
} otel_logger;

static int otel_sev_of(pTHX_ SV *level) {
    STRLEN l;
    const char *s;
    if (!level || !SvOK(level)) return OTEL_SEV_INFO;
    s = SvPV_const(level, l);
    if (l == 5 && memEQ(s, "debug", 5)) return OTEL_SEV_DEBUG;
    if (l == 4 && memEQ(s, "info",  4)) return OTEL_SEV_INFO;
    if (l == 4 && memEQ(s, "warn",  4)) return OTEL_SEV_WARN;
    if (l == 5 && memEQ(s, "error", 5)) return OTEL_SEV_ERROR;
    if (l == 5 && memEQ(s, "fatal", 5)) return OTEL_SEV_FATAL;
    if (l == 5 && memEQ(s, "trace", 5)) return OTEL_SEV_TRACE;
    return OTEL_SEV_INFO;
}

static otel_logger *otel_logger_new(pTHX) {
    otel_logger *lg;
    Newxz(lg, 1, otel_logger);
    lg->qcap = OTEL_LOG_QUEUE_MAX;
    Newxz(lg->queue, lg->qcap, otel_logrec);
    lg->resource = newHV();
    lg->owner_pid = getpid();
    return lg;
}

static void otel_logrec_clear(pTHX_ otel_logrec *r) {
    if (r->body)          SvREFCNT_dec(r->body);
    if (r->attrs)         SvREFCNT_dec((SV *)r->attrs);
    if (r->severity_text) SvREFCNT_dec(r->severity_text);
    Zero(r, 1, otel_logrec);
}

static void otel_logger_free(pTHX_ otel_logger *lg) {
    int i;
    if (!lg) return;
    for (i = 0; i < lg->qcount; i++)
        otel_logrec_clear(aTHX_ &lg->queue[(lg->qhead + i) % lg->qcap]);
    Safefree(lg->queue);
    if (lg->resource)      SvREFCNT_dec((SV *)lg->resource);
    if (lg->scope_name)    SvREFCNT_dec(lg->scope_name);
    if (lg->scope_version) SvREFCNT_dec(lg->scope_version);
    Safefree(lg);
}

/* Same rule as the span queue: a child owns none of its parent's records. */
static void otel_logger_check_fork(pTHX_ otel_logger *lg) {
    pid_t me = getpid();
    int i;
    if (lg->owner_pid == me) return;
    for (i = 0; i < lg->qcount; i++)
        otel_logrec_clear(aTHX_ &lg->queue[(lg->qhead + i) % lg->qcap]);
    lg->qhead = lg->qcount = 0;
    lg->owner_pid = me;
}

static void otel_logger_emit(pTHX_ otel_logger *lg, SV *level, SV *body,
                             HV *attrs, otel_span *span) {
    otel_logrec *r;
    otel_logger_check_fork(aTHX_ lg);
    if (lg->qcount == lg->qcap) {
        otel_logrec_clear(aTHX_ &lg->queue[lg->qhead]);
        lg->qhead = (lg->qhead + 1) % lg->qcap;
        lg->qcount--;
        lg->dropped++;
    }
    r = &lg->queue[(lg->qhead + lg->qcount) % lg->qcap];
    Zero(r, 1, otel_logrec);
    r->body     = body ? newSVsv(body) : NULL;
    r->attrs    = attrs ? (HV *)SvREFCNT_inc((SV *)attrs) : NULL;
    r->severity = otel_sev_of(aTHX_ level);
    r->severity_text = level && SvOK(level) ? newSVsv(level) : NULL;
    r->time     = otel_wall_nanos();
    if (span) {
        Copy(span->trace_id, r->trace_id, 16, unsigned char);
        Copy(span->span_id,  r->span_id,   8, unsigned char);
        r->has_span = 1;
    }
    lg->qcount++;
    lg->emitted++;
}

static SV *otel_logger_drain(pTHX_ otel_logger *lg, int max) {
    HV *payload, *rl, *sl, *res, *scope;
    AV *rls, *sls, *recs;
    int n, i;

    otel_logger_check_fork(aTHX_ lg);
    if (lg->qcount <= 0) return NULL;
    n = lg->qcount < max ? lg->qcount : max;

    recs = newAV();
    for (i = 0; i < n; i++) {
        otel_logrec *r = &lg->queue[lg->qhead];
        HV *h = newHV();
        char hex[32];
        (void)hv_stores(h, "time_unix_nano", newSVuv((UV)r->time));
        (void)hv_stores(h, "observed_time_unix_nano",
                        newSVuv((UV)otel_wall_nanos()));
        (void)hv_stores(h, "severity_number", newSViv(r->severity));
        if (r->severity_text)
            (void)hv_stores(h, "severity_text", newSVsv(r->severity_text));
        if (r->body)  (void)hv_stores(h, "body", newSVsv(r->body));
        if (r->attrs) (void)hv_stores(h, "attributes",
                                      newRV_inc((SV *)r->attrs));
        if (r->has_span) {
            otel_bytes_to_hex(r->trace_id, 16, hex);
            (void)hv_stores(h, "trace_id", newSVpvn(hex, 32));
            otel_bytes_to_hex(r->span_id, 8, hex);
            (void)hv_stores(h, "span_id", newSVpvn(hex, 16));
        }
        av_push(recs, newRV_noinc((SV *)h));
        otel_logrec_clear(aTHX_ r);
        lg->qhead = (lg->qhead + 1) % lg->qcap;
        lg->qcount--;
    }

    scope = newHV();
    if (lg->scope_name)    (void)hv_stores(scope, "name",
                                           newSVsv(lg->scope_name));
    if (lg->scope_version) (void)hv_stores(scope, "version",
                                           newSVsv(lg->scope_version));
    sl = newHV();
    (void)hv_stores(sl, "scope", newRV_noinc((SV *)scope));
    (void)hv_stores(sl, "log_records", newRV_noinc((SV *)recs));
    sls = newAV();
    av_push(sls, newRV_noinc((SV *)sl));

    res = newHV();
    (void)hv_stores(res, "attributes", newRV_inc((SV *)lg->resource));
    rl = newHV();
    (void)hv_stores(rl, "resource", newRV_noinc((SV *)res));
    (void)hv_stores(rl, "scope_logs", newRV_noinc((SV *)sls));
    rls = newAV();
    av_push(rls, newRV_noinc((SV *)rl));

    payload = newHV();
    (void)hv_stores(payload, "resource_logs", newRV_noinc((SV *)rls));
    return newRV_noinc((SV *)payload);
}

#endif /* OTEL_LOG_H */
