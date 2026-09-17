/*
 * OpenTelemetry.xs - root XS file.
 *
 * Thin wrapper: includes the C implementation headers, then pulls in the
 * per-module XS fragments from xs/ via INCLUDE: (the Punk / Open::API
 * layout). All the behaviour lives in include/; the .pm files are
 * documentation.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Build with -DOTEL_PB_ASSERT to have every embedded message check that what
 * it wrote matches what it measured. Off in a normal build; on under the
 * author tests, where the cost does not matter and a drifted size_/write_
 * pair should be loud. */

#include "frj_abi.h"

/* ---- the File::Raw::JSON C ABI ------------------------------------------ *
 * Only the OTLP/JSON encoder needs it, so it is resolved lazily on first use
 * rather than at boot: a process exporting protobuf, which is the default,
 * never loads File::Raw::JSON at all. Same consumer pattern Punk uses. */
static const frj_abi *OTEL_FRJ = NULL;
static int OTEL_FRJ_TRIED = 0;

static const frj_abi *otel_frj(pTHX) {
    if (!OTEL_FRJ && !OTEL_FRJ_TRIED) {
        dSP; int count; IV p = 0;
        OTEL_FRJ_TRIED = 1;
        eval_pv("require File::Raw::JSON;", FALSE);
        SPAGAIN;   /* the require runs arbitrary Perl; the stack may have moved */
        if (!SvTRUE(ERRSV)) {
            ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
            count = call_pv("File::Raw::JSON::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (!SvTRUE(ERRSV) && count > 0) p = POPi;
            else if (count > 0)             (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            if (p) {
                const frj_abi *a = INT2PTR(const frj_abi *, p);
                if (a && a->abi_version >= FRJ_ABI_VERSION) OTEL_FRJ = a;
            }
        }
    }
    if (!OTEL_FRJ)
        croak("Punk::OpenTelemetry: OTLP/JSON needs File::Raw::JSON with a "
              "compatible C ABI (FRJ_ABI_VERSION %d)", FRJ_ABI_VERSION);
    return OTEL_FRJ;
}

#include "otel_pb.h"        /* varints, tags, length-delimited fields     */
#include "otel_proto.h"     /* the OTLP field numbers, pinned            */
#include "otel_value.h"     /* AnyValue / KeyValue from Perl scalars     */
#include "otel_trace.h"     /* the trace message tree                    */
#include "otel_json.h"      /* ... and the same tree as OTLP/JSON        */
#include "otel_export.h"   /* ... and the OTLP/HTTP transport            */

/* the trace SDK (phase 3): ids, clocks, sampling, spans, the batch queue */
#include "otel_id.h"        /* trace and span ids; never all-zero        */
#include "otel_clock.h"     /* wall once, monotonic for the duration     */
#include "otel_sample.h"    /* ParentBased(TraceIdRatioBased)            */
#include "otel_span.h"      /* the span struct, limits and drop counts   */
#include "otel_resource.h"  /* what produced this telemetry (needs the ids) */
#include "otel_tracer.h"    /* the tracer and its bounded batch queue    */

/* context propagation (phase 4) */
#include "otel_ctx.h"       /* the extracted context; invalid means ABSENT */
#include "otel_w3c.h"       /* traceparent + tracestate                  */
#include "otel_b3.h"        /* B3, single and multi                      */
#include "otel_jaeger.h"    /* uber-trace-id                             */
#include "otel_baggage.h"   /* W3C Baggage                               */

/* metrics (phase 6). BEFORE the instrumentation, which records the HTTP
 * duration histogram itself and so needs the meter's types. These need only
 * the clock and the span, both above. */
#include "otel_expo.h"      /* the base-2 exponential histogram          */
#include "otel_metric.h"    /* instruments, points, the cardinality cap  */
#include "otel_meter.h"     /* views, conflict detection, collection     */

/* instrumentation (phase 5): the hooks become spans, and one metric */
#include "otel_semconv.h"   /* attribute names, pinned; method bounding   */
#include "otel_instr.h"     /* the server and database observers          */
#include "otel_consume.h"   /* pk_abi + fetch_abi, both optional          */

/* logs (phase 7), and the encoders for both other signals */
#include "otel_log.h"       /* severity, the record queue, the tap       */
#include "otel_signal_pb.h" /* metrics + logs, in protobuf               */
#include "otel_grpc.h"      /* OTLP over gRPC: framing and status        */

/* schema urls */
#include "otel_schema.h"    /* converting between convention versions     */

/* configuration */
#include "otel_config.h"    /* the OTEL_* surface, precedence, the boot line */


/* ---- the log tap -------------------------------------------------------- *
 * Glue between two subsystems, so it lives in the file that includes both:
 * the observer is typed by pk_abi (otel_instr.h) and emits into the logger
 * (otel_log.h), and the logger header is included after the instrumentation
 * one. */
/* The logger this process exports through. Set by the plugin when the logs
 * signal is on, and NULL when it is off - which is what makes a log line cost
 * a load and a branch on a deployment that has turned logs off. */
static otel_logger *OTEL_LOGGER = NULL;

/* pk_abi's on_log_ctx: EVERY LINE THE APPLICATION LOGS, exported.
 *
 * This is why there is no separate "log to telemetry" call. An application
 * already has a logger and already uses it; asking it to make a second call
 * to a second logger means the two disagree the first time somebody adds a
 * line to one of them, and the telemetry copy is always the one that gets
 * forgotten. `$c->log->error(...)` is the whole interface.
 *
 * A TAP, NOT A SINK. The line still goes wherever it was going - Punk emits
 * it and then hands over a copy - so turning telemetry on never takes an
 * operator's logs away, and a collector outage never silences them.
 *
 * The span comes from the context, which is what v4 of the ABI exists to
 * pass. A record logged outside a request, or after the response ended,
 * carries no trace id rather than a stale one. */
static void otel_on_log(pTHX_ SV *c, const char *level, STRLEN llen, SV *msg,
                        HV *fields, void *ud) {
    const pk_abi *A = (const pk_abi *)ud;
    otel_span *span = NULL;
    SV *lvl;

    /* The SDK's own diagnostics must not come back round through here: the
     * exporter logs a failure, the failure becomes a record, the record is
     * exported... */
    if (!OTEL_LOGGER || OTEL_INSTR.suppress || !OTEL_INSTR.enabled) return;

    /* READ, NEVER TAKEN. otel_unstash_span CLEARS the slot - it is how the
     * response side ends the span - so using it here would end the request's
     * span by logging a line, and the trace would lose its root. */
    span = otel_peek_span(aTHX_ A, c);

    lvl = sv_2mortal(newSVpvn(level, llen));

    /* `message` IS THE BODY, so it does not also become an attribute.
     *
     * Punk's structured form puts the message inside the record - and the
     * record is what an observer is handed - so passing the hash through
     * unchanged exported every line twice: once as the body and once as an
     * attribute of the same name. That is bytes on every record, for ever,
     * saying the thing the record already says.
     *
     * A COPY, because the hash belongs to the caller. Filtering in place
     * would delete a key out of a live application's data structure. */
    if (fields && HvUSEDKEYS(fields)) {
        HV *attrs = newHV();
        HE *he;
        hv_iterinit(fields);
        while ((he = hv_iternext(fields))) {
            STRLEN kl;
            const char *k = HePV(he, kl);
            if (kl == 7 && memcmp(k, "message", 7) == 0) continue;
            (void)hv_store_ent(attrs, HeSVKEY_force(he), newSVsv(HeVAL(he)), 0);
        }
        otel_logger_emit(aTHX_ OTEL_LOGGER, lvl, msg, attrs, span);
        SvREFCNT_dec((SV *)attrs);   /* emit took its own reference */
    }
    else otel_logger_emit(aTHX_ OTEL_LOGGER, lvl, msg, NULL, span);
}

MODULE = Punk::OpenTelemetry    PACKAGE = Punk::OpenTelemetry

PROTOTYPES: DISABLE

INCLUDE: xs/encode.xs
INCLUDE: xs/resource.xs
INCLUDE: xs/exporter.xs
INCLUDE: xs/tracer.xs
INCLUDE: xs/propagate.xs
INCLUDE: xs/instrument.xs
INCLUDE: xs/meter.xs
INCLUDE: xs/logger.xs
INCLUDE: xs/grpc.xs
INCLUDE: xs/schema.xs
INCLUDE: xs/config.xs
