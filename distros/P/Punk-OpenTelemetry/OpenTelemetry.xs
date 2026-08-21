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

/* instrumentation (phase 5): the hooks become spans */
#include "otel_semconv.h"   /* attribute names, pinned; method bounding   */
#include "otel_instr.h"     /* the server and database observers          */
#include "otel_consume.h"   /* pk_abi + fetch_abi, both optional          */

/* metrics (phase 6) */
#include "otel_expo.h"      /* the base-2 exponential histogram          */
#include "otel_metric.h"    /* instruments, points, the cardinality cap  */
#include "otel_meter.h"     /* views, conflict detection, collection     */

/* logs (phase 7), and the encoders for both other signals */
#include "otel_log.h"       /* severity, the record queue, the tap       */
#include "otel_signal_pb.h" /* metrics + logs, in protobuf               */
#include "otel_grpc.h"      /* OTLP over gRPC: framing and status        */

/* schema urls */
#include "otel_schema.h"    /* converting between convention versions     */

/* configuration */
#include "otel_config.h"    /* the OTEL_* surface, precedence, the boot line */

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
