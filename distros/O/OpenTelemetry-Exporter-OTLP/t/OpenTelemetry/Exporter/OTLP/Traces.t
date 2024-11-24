#!/usr/bin/env perl

use Log::Any::Adapter 'Stderr';
use Test2::V0 -target => 'OpenTelemetry::Exporter::OTLP::Traces';
use Test2::Tools::OpenTelemetry;
use Test2::Tools::Spec;

use experimental 'signatures';

use OpenTelemetry 'otel_error_handler';
use OpenTelemetry::Constants
    'HEX_INVALID_SPAN_ID',
    'INVALID_SPAN_ID',
    -trace_export,
    -span_kind,
    -span_status;
use OpenTelemetry::Trace::SpanContext;
use OpenTelemetry::Trace::Span::Status;

use HTTP::Tiny;
use Syntax::Keyword::Dynamically;

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

subtest Export => sub {
    my $http_mock = mock 'HTTP::Tiny' => override => [
        request => sub { +{ success => 1, status => 200 } },
    ];

    is CLASS->new->export([
        OpenTelemetry::SDK::Trace::Span::Readable->new,
        OpenTelemetry::SDK::Trace::Span::Readable->new,
        OpenTelemetry::SDK::Trace::Span::Readable->new,
        OpenTelemetry::SDK::Trace::Span::Readable->new,
    ]), TRACE_EXPORT_SUCCESS;
};

describe Retries => sub {
    my $retries;

    case 'No retries' => sub { $retries = 0 };
    case 'One retry'  => sub { $retries = 1 };

    tests Retries => { flat => 1 } => sub {
        my $exporter = CLASS->new( retries => $retries );

        my $content;
        $content = OTel::Google::RPC::Status->new_and_check({
            code    => 999,
            message => 'Test failure',
        })->encode if eval { require OpenTelemetry::Proto; 1 };

        my $http_mock = mock 'HTTP::Tiny' => override => [
            request => sub {
                +{
                    success => 0,
                    status  => 429,
                    content => $content,
                };
            },
        ];

        dynamically otel_error_handler = sub {};

        is metrics {
            $exporter->export([
                OpenTelemetry::SDK::Trace::Span::Readable->new,
            ]);
        } => bag {
            item match qr/otel_exporter_otlp_failure reason:429 = @{[ $retries + 1 ]}/;
            etc;
        };
    };
};

done_testing;
