#!/usr/bin/env perl

use Log::Any::Adapter 'Stderr';
use Test2::V0 -target => 'OpenTelemetry::Exporter::OTLP';

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

my $span_mock = mock 'Local::Span' => add => [
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
    start_timestamp    => 0,
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

is CLASS->new->export([
    Local::Span->new,
    Local::Span->new,
    Local::Span->new,
    Local::Span->new,
]), TRACE_EXPORT_SUCCESS;

done_testing;
