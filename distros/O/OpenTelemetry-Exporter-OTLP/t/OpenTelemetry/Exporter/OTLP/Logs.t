#!/usr/bin/env perl

use Log::Any::Adapter 'Stderr';
use Test2::V0 -target => 'OpenTelemetry::Exporter::OTLP::Logs';

use experimental 'signatures';

use HTTP::Tiny;
use OpenTelemetry::Constants
    'HEX_INVALID_SPAN_ID',
    'INVALID_SPAN_ID',
    -trace_export,
    -span_kind,
    -span_status;
use OpenTelemetry::Trace::SpanContext;
use OpenTelemetry::Trace::Span::Status;

my $http_mock = mock 'HTTP::Tiny' => override => [
    request => sub { +{ success => 1, status => 200 } },
];

my $mock = mock 'OpenTelemetry::SDK::Logs::LogRecord' => add => [
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

is CLASS->new->export([
    OpenTelemetry::SDK::Logs::LogRecord->new,
    OpenTelemetry::SDK::Logs::LogRecord->new,
    OpenTelemetry::SDK::Logs::LogRecord->new,
    OpenTelemetry::SDK::Logs::LogRecord->new,
]), TRACE_EXPORT_SUCCESS;

done_testing;
