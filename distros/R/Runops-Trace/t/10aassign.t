#!perl
use Test::More tests => 1;
use Runops::Trace;

Runops::Trace::set_tracer(sub {});

Runops::Trace::enable_tracing();
out_of_memory_during_array_extend();
Runops::Trace::disable_tracing();
pass(q(Didn't OOM));

sub out_of_memory_during_array_extend {
    my @array = @_;
}
