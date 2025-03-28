
�%
,opentelemetry/proto/metrics/v1/metrics.protoopentelemetry.proto.metrics.v1*opentelemetry/proto/common/v1/common.proto.opentelemetry/proto/resource/v1/resource.proto"i
MetricsDataZ
resource_metrics (2/.opentelemetry.proto.metrics.v1.ResourceMetricsRresourceMetrics"�
ResourceMetricsE
resource (2).opentelemetry.proto.resource.v1.ResourceRresourceQ
scope_metrics (2,.opentelemetry.proto.metrics.v1.ScopeMetricsRscopeMetrics

schema_url (	R	schemaUrlJ��"�
ScopeMetricsI
scope (23.opentelemetry.proto.common.v1.InstrumentationScopeRscope@
metrics (2&.opentelemetry.proto.metrics.v1.MetricRmetrics

schema_url (	R	schemaUrl"�
Metric
name (	Rname 
description (	Rdescription
unit (	Runit=
gauge (2%.opentelemetry.proto.metrics.v1.GaugeH Rgauge7
sum (2#.opentelemetry.proto.metrics.v1.SumH RsumI
	histogram	 (2).opentelemetry.proto.metrics.v1.HistogramH R	histogramk
exponential_histogram
 (24.opentelemetry.proto.metrics.v1.ExponentialHistogramH RexponentialHistogramC
summary (2'.opentelemetry.proto.metrics.v1.SummaryH RsummaryC
metadata (2'.opentelemetry.proto.common.v1.KeyValueRmetadataB
dataJJJ	"Y
GaugeP
data_points (2/.opentelemetry.proto.metrics.v1.NumberDataPointR
dataPoints"�
SumP
data_points (2/.opentelemetry.proto.metrics.v1.NumberDataPointR
dataPointso
aggregation_temporality (26.opentelemetry.proto.metrics.v1.AggregationTemporalityRaggregationTemporality!
is_monotonic (RisMonotonic"�
	HistogramS
data_points (22.opentelemetry.proto.metrics.v1.HistogramDataPointR
dataPointso
aggregation_temporality (26.opentelemetry.proto.metrics.v1.AggregationTemporalityRaggregationTemporality"�
ExponentialHistogram^
data_points (2=.opentelemetry.proto.metrics.v1.ExponentialHistogramDataPointR
dataPointso
aggregation_temporality (26.opentelemetry.proto.metrics.v1.AggregationTemporalityRaggregationTemporality"\
SummaryQ
data_points (20.opentelemetry.proto.metrics.v1.SummaryDataPointR
dataPoints"�
NumberDataPointG

attributes (2'.opentelemetry.proto.common.v1.KeyValueR
attributes/
start_time_unix_nano (RstartTimeUnixNano$
time_unix_nano (RtimeUnixNano
	as_double (H RasDouble
as_int (H RasIntF
	exemplars (2(.opentelemetry.proto.metrics.v1.ExemplarR	exemplars
flags (RflagsB
valueJ"�
HistogramDataPointG

attributes	 (2'.opentelemetry.proto.common.v1.KeyValueR
attributes/
start_time_unix_nano (RstartTimeUnixNano$
time_unix_nano (RtimeUnixNano
count (Rcount
sum (H Rsum�#
bucket_counts (RbucketCounts'
explicit_bounds (RexplicitBoundsF
	exemplars (2(.opentelemetry.proto.metrics.v1.ExemplarR	exemplars
flags
 (Rflags
min (HRmin�
max (HRmax�B
_sumB
_minB
_maxJ"�
ExponentialHistogramDataPointG

attributes (2'.opentelemetry.proto.common.v1.KeyValueR
attributes/
start_time_unix_nano (RstartTimeUnixNano$
time_unix_nano (RtimeUnixNano
count (Rcount
sum (H Rsum�
scale (Rscale

zero_count (R	zeroCounta
positive (2E.opentelemetry.proto.metrics.v1.ExponentialHistogramDataPoint.BucketsRpositivea
negative	 (2E.opentelemetry.proto.metrics.v1.ExponentialHistogramDataPoint.BucketsRnegative
flags
 (RflagsF
	exemplars (2(.opentelemetry.proto.metrics.v1.ExemplarR	exemplars
min (HRmin�
max (HRmax�%
zero_threshold (RzeroThresholdF
Buckets
offset (Roffset#
bucket_counts (RbucketCountsB
_sumB
_minB
_max"�
SummaryDataPointG

attributes (2'.opentelemetry.proto.common.v1.KeyValueR
attributes/
start_time_unix_nano (RstartTimeUnixNano$
time_unix_nano (RtimeUnixNano
count (Rcount
sum (Rsumi
quantile_values (2@.opentelemetry.proto.metrics.v1.SummaryDataPoint.ValueAtQuantileRquantileValues
flags (RflagsC
ValueAtQuantile
quantile (Rquantile
value (RvalueJ"�
ExemplarX
filtered_attributes (2'.opentelemetry.proto.common.v1.KeyValueRfilteredAttributes$
time_unix_nano (RtimeUnixNano
	as_double (H RasDouble
as_int (H RasInt
span_id (RspanId
trace_id (RtraceIdB
valueJ*�
AggregationTemporality'
#AGGREGATION_TEMPORALITY_UNSPECIFIED !
AGGREGATION_TEMPORALITY_DELTA&
"AGGREGATION_TEMPORALITY_CUMULATIVE*^
DataPointFlags
DATA_POINT_FLAGS_DO_NOT_USE +
'DATA_POINT_FLAGS_NO_RECORDED_VALUE_MASKB
!io.opentelemetry.proto.metrics.v1BMetricsProtoPZ)go.opentelemetry.io/proto/otlp/metrics/v1�OpenTelemetry.Proto.Metrics.V1bproto3