/* otel_proto.h - the OTLP field numbers, in one place.
 *
 * Every number here comes from the published opentelemetry-proto schema. They
 * are pinned in one header rather than spelled at each use so that a schema
 * bump is one file to review, and so that a wrong number is a typo in a table
 * rather than a magic constant buried in a writer.
 *
 * Schema: opentelemetry/proto/{common,resource,trace,metrics,logs}/v1
 *
 * The trace tree is what phase 2 implements. The metrics and logs numbers are
 * here too because they cost nothing to write down now and because having the
 * whole schema in one table is the point of the file; their writers arrive
 * with phases 6 and 7.
 */

#ifndef OTEL_PROTO_H
#define OTEL_PROTO_H

/* ---- common/v1 ---------------------------------------------------------- */

/* AnyValue is a oneof: exactly one of these is set. */
#define PB_ANYVALUE_STRING      1
#define PB_ANYVALUE_BOOL        2
#define PB_ANYVALUE_INT         3
#define PB_ANYVALUE_DOUBLE      4
#define PB_ANYVALUE_ARRAY       5
#define PB_ANYVALUE_KVLIST      6
#define PB_ANYVALUE_BYTES       7

#define PB_ARRAYVALUE_VALUES    1
#define PB_KVLIST_VALUES        1

#define PB_KEYVALUE_KEY         1
#define PB_KEYVALUE_VALUE       2

#define PB_SCOPE_NAME           1
#define PB_SCOPE_VERSION        2
#define PB_SCOPE_ATTRIBUTES     3
#define PB_SCOPE_DROPPED_ATTRS  4

/* ---- resource/v1 -------------------------------------------------------- */

#define PB_RESOURCE_ATTRIBUTES   1
#define PB_RESOURCE_DROPPED_ATTRS 2

/* ---- trace/v1 ----------------------------------------------------------- */

#define PB_TRACESDATA_RESOURCE_SPANS 1

#define PB_RESOURCESPANS_RESOURCE    1
#define PB_RESOURCESPANS_SCOPE_SPANS 2
#define PB_RESOURCESPANS_SCHEMA_URL  3

#define PB_SCOPESPANS_SCOPE          1
#define PB_SCOPESPANS_SPANS          2
#define PB_SCOPESPANS_SCHEMA_URL     3

#define PB_SPAN_TRACE_ID              1
#define PB_SPAN_SPAN_ID               2
#define PB_SPAN_TRACE_STATE           3
#define PB_SPAN_PARENT_SPAN_ID        4
#define PB_SPAN_NAME                  5
#define PB_SPAN_KIND                  6
#define PB_SPAN_START_TIME            7   /* fixed64 unix nanos */
#define PB_SPAN_END_TIME              8   /* fixed64 unix nanos */
#define PB_SPAN_ATTRIBUTES            9
#define PB_SPAN_DROPPED_ATTRS        10
#define PB_SPAN_EVENTS               11
#define PB_SPAN_DROPPED_EVENTS       12
#define PB_SPAN_LINKS                13
#define PB_SPAN_DROPPED_LINKS        14
#define PB_SPAN_STATUS               15
#define PB_SPAN_FLAGS                16

#define PB_EVENT_TIME                 1   /* fixed64 unix nanos */
#define PB_EVENT_NAME                 2
#define PB_EVENT_ATTRIBUTES           3
#define PB_EVENT_DROPPED_ATTRS        4

#define PB_LINK_TRACE_ID              1
#define PB_LINK_SPAN_ID               2
#define PB_LINK_TRACE_STATE           3
#define PB_LINK_ATTRIBUTES            4
#define PB_LINK_DROPPED_ATTRS         5
#define PB_LINK_FLAGS                 6

#define PB_STATUS_MESSAGE             2
#define PB_STATUS_CODE                3

/* SpanKind. UNSPECIFIED is 0 and, being the proto3 default, is never written. */
#define OTEL_KIND_UNSPECIFIED 0
#define OTEL_KIND_INTERNAL    1
#define OTEL_KIND_SERVER      2
#define OTEL_KIND_CLIENT      3
#define OTEL_KIND_PRODUCER    4
#define OTEL_KIND_CONSUMER    5

/* StatusCode. UNSET is 0 and is likewise never written - which is correct and
 * deliberate: an instrumentation layer that has no opinion must leave the
 * status alone rather than claim success. */
#define OTEL_STATUS_UNSET 0
#define OTEL_STATUS_OK    1
#define OTEL_STATUS_ERROR 2

/* ---- collector service requests ----------------------------------------- *
 * Each Export*ServiceRequest has one repeated field, the same shape as the
 * *Data message, so one writer serves both. */
#define PB_EXPORT_TRACE_RESOURCE_SPANS   1
#define PB_EXPORT_METRICS_RESOURCE_METRICS 1
#define PB_EXPORT_LOGS_RESOURCE_LOGS     1

/* The partial-success message every export response may carry. A 200 with one
 * of these is NOT a failure and must not be retried, but the count has to be
 * surfaced or data disappears while the dashboard looks healthy. */
#define PB_EXPORT_TRACE_PARTIAL_SUCCESS  1
#define PB_PARTIAL_REJECTED_SPANS        1
#define PB_PARTIAL_REJECTED_DATA_POINTS  1
#define PB_PARTIAL_REJECTED_LOG_RECORDS  1
#define PB_PARTIAL_ERROR_MESSAGE         2

/* ---- logs/v1 (phase 7) -------------------------------------------------- */

#define PB_RESOURCELOGS_RESOURCE     1
#define PB_RESOURCELOGS_SCOPE_LOGS   2
#define PB_RESOURCELOGS_SCHEMA_URL   3
#define PB_SCOPELOGS_SCOPE           1
#define PB_SCOPELOGS_RECORDS         2
#define PB_SCOPELOGS_SCHEMA_URL      3

#define PB_LOGRECORD_TIME            1   /* fixed64 */
#define PB_LOGRECORD_SEVERITY_NUMBER 2
#define PB_LOGRECORD_SEVERITY_TEXT   3
#define PB_LOGRECORD_BODY            5
#define PB_LOGRECORD_ATTRIBUTES      6
#define PB_LOGRECORD_DROPPED_ATTRS   7
#define PB_LOGRECORD_FLAGS           8
#define PB_LOGRECORD_TRACE_ID        9
#define PB_LOGRECORD_SPAN_ID        10
#define PB_LOGRECORD_OBSERVED_TIME  11   /* fixed64 */

/* ---- metrics/v1 (phase 6) ----------------------------------------------- */

#define PB_RESOURCEMETRICS_RESOURCE     1
#define PB_RESOURCEMETRICS_SCOPE_METRICS 2
#define PB_RESOURCEMETRICS_SCHEMA_URL   3
#define PB_SCOPEMETRICS_SCOPE           1
#define PB_SCOPEMETRICS_METRICS         2
#define PB_SCOPEMETRICS_SCHEMA_URL      3

#define PB_METRIC_NAME          1
#define PB_METRIC_DESCRIPTION   2
#define PB_METRIC_UNIT          3
#define PB_METRIC_GAUGE         5
#define PB_METRIC_SUM           7
#define PB_METRIC_HISTOGRAM     9
#define PB_METRIC_EXP_HISTOGRAM 10
#define PB_METRIC_SUMMARY       11

/* the data-type wrappers */
#define PB_SUM_DATA_POINTS      1
#define PB_SUM_TEMPORALITY      2
#define PB_SUM_IS_MONOTONIC     3
#define PB_GAUGE_DATA_POINTS    1
#define PB_HIST_DATA_POINTS     1
#define PB_HIST_TEMPORALITY     2
#define PB_EXPO_DATA_POINTS     1
#define PB_EXPO_TEMPORALITY     2

/* NumberDataPoint. Note the field numbers are NOT in declaration order -
 * attributes is 7, after the value - which is ordinary in a proto that grew,
 * and exactly why they are written down here rather than guessed. */
#define PB_NDP_START_TIME       2
#define PB_NDP_TIME             3
#define PB_NDP_AS_DOUBLE        4
#define PB_NDP_EXEMPLARS        5
#define PB_NDP_AS_INT           6
#define PB_NDP_ATTRIBUTES       7
#define PB_NDP_FLAGS            8

#define PB_HDP_START_TIME       2
#define PB_HDP_TIME             3
#define PB_HDP_COUNT            4
#define PB_HDP_SUM              5
#define PB_HDP_BUCKET_COUNTS    6
#define PB_HDP_EXPLICIT_BOUNDS  7
#define PB_HDP_EXEMPLARS        8
#define PB_HDP_ATTRIBUTES       9
#define PB_HDP_FLAGS           10
#define PB_HDP_MIN             11
#define PB_HDP_MAX             12

#define PB_EDP_ATTRIBUTES       1
#define PB_EDP_START_TIME       2
#define PB_EDP_TIME             3
#define PB_EDP_COUNT            4
#define PB_EDP_SUM              5
#define PB_EDP_SCALE            6
#define PB_EDP_ZERO_COUNT       7
#define PB_EDP_POSITIVE         8
#define PB_EDP_NEGATIVE         9
#define PB_EDP_FLAGS           10
#define PB_EDP_EXEMPLARS       11
#define PB_EDP_MIN             12
#define PB_EDP_MAX             13
#define PB_EDP_ZERO_THRESHOLD  14

#define PB_BUCKETS_OFFSET       1
#define PB_BUCKETS_COUNTS       2

#define PB_EXEMPLAR_TIME        2
#define PB_EXEMPLAR_AS_DOUBLE   3
#define PB_EXEMPLAR_SPAN_ID     4
#define PB_EXEMPLAR_TRACE_ID    5
#define PB_EXEMPLAR_AS_INT      6
#define PB_EXEMPLAR_ATTRIBUTES  7

/* AggregationTemporality, and a trap.
 *
 * The OTLP enum is DELTA=1, CUMULATIVE=2 - the REVERSE of the internal
 * constants in otel_metric.h, which were numbered before this file existed.
 * Emitting the internal value directly would label every cumulative series as
 * delta and every delta series as cumulative, which a backend accepts without
 * complaint and then draws completely wrongly. Hence the explicit map below,
 * and hence a test for it. */
#define PB_TEMPORALITY_DELTA      1
#define PB_TEMPORALITY_CUMULATIVE 2

#endif /* OTEL_PROTO_H */
