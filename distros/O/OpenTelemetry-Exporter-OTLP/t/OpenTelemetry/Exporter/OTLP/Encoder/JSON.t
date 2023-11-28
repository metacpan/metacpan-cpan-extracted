#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Exporter::OTLP::Encoder::JSON';

use experimental 'signatures';

use JSON::MaybeXS;
use OpenTelemetry::Constants
    'HEX_INVALID_SPAN_ID',
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
    hex_parent_span_id    => sub { HEX_INVALID_SPAN_ID },
    hex_span_id           => sub { shift->{context}->hex_span_id },
    hex_trace_id          => sub { shift->{context}->hex_trace_id },
    instrumentation_scope => sub { shift->{scope} //= Local::Scope->new },
    kind                  => sub { SPAN_KIND_INTERNAL },
    links                 => sub { },
    name                  => sub { shift->{name} //= 'X' },
    resource              => sub { shift->{resource} //= Local::Resource->new },
    start_timestamp       => 0,
    status                => sub { OpenTelemetry::Trace::Span::Status->ok },
    trace_flags           => sub { shift->{context}->trace_flags },
    trace_state           => sub { shift->{context}->trace_state },
];

is decode_json(CLASS->new->encode([
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
])), {
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
                droppedAttributesCount => 0,
            },
            schemaUrl => '',
            scopeSpans => array {
                prop size => 2;
                all_items {
                    scope => {
                        attributes             => [],
                        droppedAttributesCount => 0,
                        name                   => match qr/[AB]/,
                        version                => '',
                    },
                    spans => [
                        {
                            attributes             => [],
                            droppedAttributesCount => 0,
                            droppedEventsCount     => 0,
                            droppedLinksCount      => 0,
                            endTimeUnixNano        => E,
                            events                 => [],
                            kind                   => SPAN_KIND_INTERNAL,
                            links                  => [],
                            name                   => match qr/[AB]-[AB]/,
                            spanId                 => match qr/[0-9a-zA-Z=+]+/,
                            startTimeUnixNano      => E,
                            traceId                => match qr/[0-9a-zA-Z=+]+/,
                            traceState             => '',
                            status => {
                                code    => SPAN_STATUS_OK,
                                message => '',
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
