
�
(opentelemetry/proto/trace/v1/trace.protoopentelemetry.proto.trace.v1*opentelemetry/proto/common/v1/common.proto.opentelemetry/proto/resource/v1/resource.proto"`

TracesDataR
resource_spans (2+.opentelemetry.proto.trace.v1.ResourceSpansRresourceSpans"�
ResourceSpansE
resource (2).opentelemetry.proto.resource.v1.ResourceRresourceI
scope_spans (2(.opentelemetry.proto.trace.v1.ScopeSpansR
scopeSpans

schema_url (	R	schemaUrlJ��"�

ScopeSpansI
scope (23.opentelemetry.proto.common.v1.InstrumentationScopeRscope8
spans (2".opentelemetry.proto.trace.v1.SpanRspans

schema_url (	R	schemaUrl"�

Span
trace_id (RtraceId
span_id (RspanId
trace_state (	R
traceState$
parent_span_id (RparentSpanId
flags (Rflags
name (	Rname?
kind (2+.opentelemetry.proto.trace.v1.Span.SpanKindRkind/
start_time_unix_nano (RstartTimeUnixNano+
end_time_unix_nano (RendTimeUnixNanoG

attributes	 (2'.opentelemetry.proto.common.v1.KeyValueR
attributes8
dropped_attributes_count
 (RdroppedAttributesCount@
events (2(.opentelemetry.proto.trace.v1.Span.EventRevents0
dropped_events_count (RdroppedEventsCount=
links (2'.opentelemetry.proto.trace.v1.Span.LinkRlinks.
dropped_links_count (RdroppedLinksCount<
status (2$.opentelemetry.proto.trace.v1.StatusRstatus�
Event$
time_unix_nano (RtimeUnixNano
name (	RnameG

attributes (2'.opentelemetry.proto.common.v1.KeyValueR
attributes8
dropped_attributes_count (RdroppedAttributesCount�
Link
trace_id (RtraceId
span_id (RspanId
trace_state (	R
traceStateG

attributes (2'.opentelemetry.proto.common.v1.KeyValueR
attributes8
dropped_attributes_count (RdroppedAttributesCount
flags (Rflags"�
SpanKind
SPAN_KIND_UNSPECIFIED 
SPAN_KIND_INTERNAL
SPAN_KIND_SERVER
SPAN_KIND_CLIENT
SPAN_KIND_PRODUCER
SPAN_KIND_CONSUMER"�
Status
message (	RmessageC
code (2/.opentelemetry.proto.trace.v1.Status.StatusCodeRcode"N

StatusCode
STATUS_CODE_UNSET 
STATUS_CODE_OK
STATUS_CODE_ERRORJ*�
	SpanFlags
SPAN_FLAGS_DO_NOT_USE  
SPAN_FLAGS_TRACE_FLAGS_MASK�*
%SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK�&
!SPAN_FLAGS_CONTEXT_IS_REMOTE_MASK�Bw
io.opentelemetry.proto.trace.v1B
TraceProtoPZ'go.opentelemetry.io/proto/otlp/trace/v1�OpenTelemetry.Proto.Trace.V1bproto3