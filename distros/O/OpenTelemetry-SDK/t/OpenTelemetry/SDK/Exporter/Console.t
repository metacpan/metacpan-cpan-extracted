#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::SDK::Exporter::Console';

use Test2::Tools::OpenTelemetry;
use OpenTelemetry::Constants -trace_export;
use OpenTelemetry::SDK::InstrumentationScope;
use OpenTelemetry::SDK::Trace::Span;
use OpenTelemetry::Trace::SpanContext;

my $scope = OpenTelemetry::SDK::InstrumentationScope->new( name => 'test' );
my $context = OpenTelemetry::Trace::SpanContext->new(
    trace_id => "\1" x 16,
    span_id  => "\1" x 8,
);

my $span = OpenTelemetry::SDK::Trace::Span->new(
    name       => 'test-span',
    scope      => $scope,
    attributes => { foo => 123 },
    start      => 123456789.1234,
    context    => $context,
    links      => [
        {
            context => $context,
            attributes => { link => 123 },
        },
        {
            context => OpenTelemetry::Trace::SpanContext->INVALID,
            attributes => { dropped => 1 },
        },
    ],
)->add_event(
    name       => "event",
    timestamp  => 123456789,
    attributes => { event => 123 },
)->snapshot;

open my $handle, '>', \my $out or die $!;

is my $exporter = CLASS->new( handle => $handle ), object {
    prop isa => $CLASS;
}, 'Can create exporter';

is $exporter->export( [$span], 100 ), TRACE_EXPORT_SUCCESS,
    'Exporting is successful';

is $out, ( <<'DUMP' =~ s/\n//gr . "\n" ), 'Exported span';
{'attributes' => {'foo' => 123},'dropped_attributes' => 0,'dropped_e
vents' => 0,'dropped_links' => 0,'end_timestamp' => undef,'events' =
> [{'attributes' => {'event' => 123},'dropped_attributes' => 0,'name
' => 'event','timestamp' => 123456789}],'instrumentation_scope' => {
'name' => 'test','version' => ''},'kind' => 1,'links' => [{'attribut
es' => {'link' => 123},'dropped_attributes' => 0,'span_id' => '01010
10101010101','trace_id' => '01010101010101010101010101010101'}],'nam
e' => 'test-span','parent_span_id' => '0000000000000000','resource'
 => {},'span_id' => '0101010101010101','start_timestamp' => '1234567
89.1234','status' => {'code' => 0,'description' => ''},'trace_flags'
 => 0,'trace_id' => '01010101010101010101010101010101','trace_state'
 => ''}
DUMP

$out = '';
is $exporter->export([]), TRACE_EXPORT_SUCCESS, 'Timeout is optional';

is $out, '', 'Nothing exported if no spans are given';

is $exporter->force_flush( 100 ), TRACE_EXPORT_SUCCESS, 'Can force flush';
is $exporter->force_flush, TRACE_EXPORT_SUCCESS, 'Force flushing is optional';

is $exporter->shutdown( 100 ), TRACE_EXPORT_SUCCESS, 'Can shutdown exporter';

$out = '';
is $exporter->export([$span]), TRACE_EXPORT_FAILURE,
    'Exporter does not export if it has been shutdown';

is $out, '', 'Nothing exported on failure';

done_testing;
