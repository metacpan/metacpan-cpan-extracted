#!perl

use strict;
use warnings;

use Runops::Trace;
use Test::More 'no_plan';

ok( !Runops::Trace::tracing_enabled(), "disabled" );

Runops::Trace::set_tracer(sub {});

is_deeply( Runops::Trace::get_op_counters(), {}, "no counters yet" );

Runops::Trace::set_trace_threshold(3);

Runops::Trace::enable_tracing();

my $i;
for ( 1 .. 10 ) {
	$i++;
}

Runops::Trace::disable_tracing();

is( $i, 10, "loop ran correctly" );

ok( scalar(keys %{ Runops::Trace::get_op_counters() }), "counted something now" );
