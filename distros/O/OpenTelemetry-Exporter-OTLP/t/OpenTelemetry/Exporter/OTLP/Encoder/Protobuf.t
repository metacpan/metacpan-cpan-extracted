#!/usr/bin/env perl

use Test2::Require::Module 'Google::ProtocolBuffers::Dynamic';
use Test2::V0 -target => 'OpenTelemetry::Exporter::OTLP::Encoder::Protobuf';

use experimental 'signatures';

use JSON::MaybeXS;
use OpenTelemetry::Proto;
use OpenTelemetry::Constants
    'INVALID_SPAN_ID',
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
    schema_url         => 'https://foo.bar',
    attributes         => sub { shift->{attributes} //= {} },
];

my $a_scope = Local::Scope->new( name => 'A' );
my $b_scope = Local::Scope->new( name => 'B' );

my $a_resource = Local::Resource->new( attributes => { name => 'A' } );
my $b_resource = Local::Resource->new( attributes => { name => 'B' } );

subtest 'Spans' => sub {
    my $span_mock = mock 'OpenTelemetry::SDK::Trace::Span::Readable' => add => [
        attributes         => sub { {} },
        dropped_attributes => 0,
        dropped_events     => 0,
        dropped_links      => 0,
        end_timestamp      => 100,
        events             => sub { },
        hex_parent_span_id => sub { HEX_INVALID_SPAN_ID },
        hex_span_id        => sub { shift->{context}->hex_span_id },
        hex_trace_id       => sub { shift->{context}->hex_trace_id },
        kind               => sub { SPAN_KIND_INTERNAL },
        links              => sub { },
        name               => sub { shift->{name} //= 'X' },
        parent_span_id     => sub { INVALID_SPAN_ID },
        span_id            => sub { shift->{context}->span_id },
        start_timestamp    => time,
        status             => sub { OpenTelemetry::Trace::Span::Status->ok },
        trace_flags        => sub { shift->{context}->trace_flags },
        trace_id           => sub { shift->{context}->trace_id },
        trace_state        => sub { shift->{context}->trace_state },
        new => sub ( $class, %data ) {
            $data{context} //= OpenTelemetry::Trace::SpanContext->new;
            bless \%data, $class;
        },
        instrumentation_scope => sub {
            shift->{scope} //= mock {} => add => [
                attributes         => sub { {} },
                dropped_attributes => 0,
                name               => 'X',
                version            => '',
            ];
        },
        resource => sub {
            shift->{resource} //= mock {} => add => [
                attributes         => sub { +{} },
                dropped_attributes => 0,
                schema_url         => '',
            ];
        },
    ];

    my $encoded = CLASS->new->encode([
        OpenTelemetry::SDK::Trace::Span::Readable->new(
            scope    => $a_scope,
            name     => 'A-A',
            resource => $a_resource,
        ),
        OpenTelemetry::SDK::Trace::Span::Readable->new(
            scope    => $a_scope,
            name     => 'A-B',
            resource => $b_resource,
        ),
        OpenTelemetry::SDK::Trace::Span::Readable->new(
            scope    => $b_scope,
            name     => 'B-A',
            resource => $a_resource,
        ),
        OpenTelemetry::SDK::Trace::Span::Readable->new(
            scope    => $b_scope,
            name     => 'B-B',
            resource => $b_resource,
        ),
    ]);

    my $decoded = OpenTelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest
        ->decode($encoded);

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
                    droppedAttributesCount => DNE, # Missing if 0
                },
                schemaUrl => 'https://foo.bar',
                scopeSpans => array {
                    prop size => 2;
                    all_items {
                        scope => {
                            attributes             => DNE, # Missing if empty
                            droppedAttributesCount => DNE, # Missing if 0
                            name                   => match qr/[AB]/,
                            version                => DNE, # Missing if empty
                        },
                        spans => [
                            {
                                attributes             => DNE, # Missing if empty
                                droppedAttributesCount => DNE, # Missing if 0
                                droppedEventsCount     => DNE, # Missing if 0
                                droppedLinksCount      => DNE, # Missing if 0
                                endTimeUnixNano        => E,
                                events                 => DNE, # Missing if empty
                                kind                   => 'SPAN_KIND_INTERNAL',
                                links                  => DNE, # Missing if empty
                                name                   => match qr/[AB]-[AB]/,
                                spanId                 => match qr/[0-9a-zA-Z=+]+/,
                                startTimeUnixNano      => E,
                                traceId                => match qr/[0-9a-zA-Z=+]+/,
                                traceState             => DNE, # Missing if empty
                                status => {
                                    code    => 'STATUS_CODE_OK',
                                    message => DNE, # Missing if empty
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
};

subtest 'Logs' => sub {
    my $span_mock = mock 'OpenTelemetry::SDK::Logs::LogRecord' => add => [
        attributes            => sub { shift->{attributes} },
        body                  => sub { shift->{body} },
        dropped_attributes    => 0, # FIXME
        hex_span_id           => sub { shift->{context}->hex_span_id },
        hex_trace_id          => sub { shift->{context}->hex_trace_id },
        observed_timestamp    => sub { shift->{observed_timestamp} },
        severity_number       => sub { shift->{severity_number} },
        severity_text         => sub { shift->{severity_text} },
        span_id               => sub { shift->{context}->span_id },
        timestamp             => sub { shift->{timestamp} },
        trace_flags           => sub { shift->{context}->trace_flags },
        trace_id              => sub { shift->{context}->trace_id },
        trace_state           => sub { shift->{context}->trace_state },
        instrumentation_scope => sub {
            shift->{scope} //= mock {} => add => [
                attributes         => sub { {} },
                dropped_attributes => 0,
                name               => 'X',
                version            => '',
            ];
        },
        resource => sub {
            shift->{resource} //= mock {} => add => [
                attributes         => sub { +{} },
                dropped_attributes => 0,
                schema_url         => '',
            ];
        },
        new => sub ( $class, %data ) {
            $data{observed_timestamp} = time;
            $data{context} //= OpenTelemetry::Trace::SpanContext->new;
            $data{body}            //= 'Something happened';
            $data{severity_text}   //= 'WARN';
            $data{severity_number} //= 13;
            bless \%data, $class;
        },
    ];

    my $encoded = CLASS->new->encode([
        OpenTelemetry::SDK::Logs::LogRecord->new(
            scope     => $a_scope,
            body      => 'A-A',
            resource  => $a_resource,
            timestamp => time,
        ),
        OpenTelemetry::SDK::Logs::LogRecord->new(
            scope     => $a_scope,
            body      => 'A-B',
            resource  => $b_resource,
            timestamp => time,
        ),
        OpenTelemetry::SDK::Logs::LogRecord->new(
            scope    => $b_scope,
            body     => 'B-A',
            resource => $a_resource,
        ),
        OpenTelemetry::SDK::Logs::LogRecord->new(
            scope    => $b_scope,
            body     => 'B-B',
            resource => $b_resource,
        ),
    ]);

    my $decoded = OpenTelemetry::Proto::Collector::Logs::V1::ExportLogsServiceRequest
        ->decode($encoded);

    is decode_json($decoded->encode_json), {
        resourceLogs => array {
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
                    droppedAttributesCount => DNE, # Missing if 0
                },
                schemaUrl => 'https://foo.bar',
                scopeLogs => array {
                    prop size => 2;
                    all_items {
                        scope => {
                            attributes             => DNE, # Missing if empty
                            droppedAttributesCount => DNE, # Missing if 0
                            name                   => match qr/[AB]/,
                            version                => DNE, # Missing if empty
                        },
                        logRecords => [
                            {
                                attributes             => DNE, # Missing if empty
                                body                   => {
                                    stringValue => match qr/[AB]-[AB]/,
                                },
                                droppedAttributesCount => DNE, # Missing if 0
                                flags                  => DNE, # Missing if 0
                                observedTimeUnixNano   => T,
                                severityNumber         => 'SEVERITY_NUMBER_WARN',
                                severityText           => 'WARN',
                                spanId                 => match qr/[0-9a-zA-Z=+]+/,
                                timeUnixNano           => in_set( T, DNE ),
                                traceId                => match qr/[0-9a-zA-Z=+]+/,
                            },
                        ],
                    };
                    etc; # scope_spans
                },
            };
            etc; # resource_spans
        },
    };
};

done_testing;
