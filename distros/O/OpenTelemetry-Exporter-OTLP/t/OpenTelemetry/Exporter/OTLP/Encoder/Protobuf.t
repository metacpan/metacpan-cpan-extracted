#!/usr/bin/env perl

use Test2::Require::Module 'Google::ProtocolBuffers::Dynamic';
use Test2::V0 -target => 'OpenTelemetry::Exporter::OTLP::Encoder::Protobuf';

use experimental 'signatures';

use JSON::MaybeXS;
use OpenTelemetry::Proto;
use OpenTelemetry::Constants
    'INVALID_SPAN_ID',
    -trace_export,
    -span_kind,
    -span_status;
use OpenTelemetry::Trace::SpanContext;
use OpenTelemetry::Trace::Span::Status;

my $scope_mock = mock 'Local::Scope' => add => [
    new                => sub ( $class, %data ) { bless \%data, $class },
    dropped_attributes => 0,
    version            => '',
    name               => sub { shift->{name} //= 'SCOPE' },
    attributes         => sub { +{} },
];

my $resource_mock = mock 'Local::Resource' => add => [
    new                => sub ( $class, %data ) { bless \%data, $class },
    dropped_attributes => 0,
    schema_url         => '',
    attributes         => sub { shift->{attributes} //= {} },
];

my $a_scope = Local::Scope->new( name => 'A' );
my $b_scope = Local::Scope->new( name => 'B' );

my $a_resource = Local::Resource->new( attributes => { name => 'A' } );
my $b_resource = Local::Resource->new( attributes => { name => 'B' } );

my $span_mock = mock 'Local::Span' => add => [
    new => sub ( $class, %data ) {
        $data{context} //= OpenTelemetry::Trace::SpanContext->new;
        bless \%data, $class;
    },
    attributes            => sub { {} },
    dropped_attributes    => 0,
    dropped_events        => 0,
    dropped_links         => 0,
    end_timestamp         => 100,
    events                => sub { },
    kind                  => sub { SPAN_KIND_INTERNAL },
    links                 => sub { },
    name                  => sub { shift->{name} //= 'X' },
    parent_span_id        => sub { INVALID_SPAN_ID },
    span_id               => sub { shift->{context}->span_id     },
    start_timestamp       => 0,
    status                => sub { OpenTelemetry::Trace::Span::Status->ok },
    trace_flags           => sub { shift->{context}->trace_flags },
    trace_id              => sub { shift->{context}->trace_id    },
    trace_state           => sub { shift->{context}->trace_state },
    instrumentation_scope => sub { shift->{scope} //= Local::Scope->new },
    resource              => sub { shift->{resource} //= Local::Resource->new },
];


my $encoded = CLASS->new->encode([
    Local::Span->new(
        scope    => $a_scope,
        name     => 'A-A',
        resource => $a_resource,
    ),
    Local::Span->new(
        scope    => $a_scope,
        name     => 'A-B',
        resource => $b_resource,
    ),
    Local::Span->new(
        scope    => $b_scope,
        name     => 'B-A',
        resource => $a_resource,
    ),
    Local::Span->new(
        scope    => $b_scope,
        name     => 'B-B',
        resource => $b_resource,
    ),
]);

my $decoded = OpenTelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest->decode($encoded);

is decode_json($decoded->encode_json), {
    resourceSpans => array {
        prop size => 2;
        all_items {
            resource => {
                attributes => array {
                    all_items {
                        key   => T,
                        value => in_set(
                            { stringValue => T },
                            { arrayValue  => T },
                        ),
                    };
                    etc; # attributes
                },
            },
            scopeSpans => array {
                prop size => 2;
                all_items {
                    scope => { name => match qr/[AB]/ },
                    spans => [
                        {
                            endTimeUnixNano => E,
                            kind            => 'SPAN_KIND_INTERNAL',
                            name            => match qr/[AB]-[AB]/,
                            spanId          => match qr/[0-9a-zA-Z=+]+/,
                            traceId         => match qr/[0-9a-zA-Z=+]+/,
                            status          => {
                                code => 'STATUS_CODE_OK',
                            },
                        },
                    ],
                };
                etc; # scope_spans
            },
        };
        etc; # resource_spans
    },
};

done_testing;
