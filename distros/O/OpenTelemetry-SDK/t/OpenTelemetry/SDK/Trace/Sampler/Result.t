#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::SDK::Trace::Sampler::Result';
use OpenTelemetry::Propagator::TraceContext::TraceState;
use Scalar::Util 'refaddr';

is CLASS->DROP,              0, 'Drop constant';
is CLASS->RECORD_ONLY,       1, 'Record only constant';
is CLASS->RECORD_AND_SAMPLE, 2, 'Record and sample constant';

my $state = OpenTelemetry::Propagator::TraceContext::TraceState->new;

like dies { CLASS->new },
    qr/Required parameter .* is missing/, 'Empty constructor fails';

like dies {
    CLASS->new( trace_state => $state );
} => qr/Required parameter 'decision' is missing/, 'Decision is required';

like dies {
    CLASS->new( decision => CLASS->DROP );
} => qr/Required parameter 'trace_state' is missing/, 'TraceState is required';

is CLASS->new( trace_state => $state, decision => 'foo' ), object {
    call recording   => F;
    call sampled     => F;
    call trace_state => validator sub { refaddr $_ == refaddr $state };
}, 'An unrecognised decision is non-recording';

is CLASS->new(
    trace_state => $state,
    decision    => CLASS->RECORD_ONLY,
) => object {
    call recording => T;
    call sampled   => F;
}, 'Recording only';

is CLASS->new(
    trace_state => $state,
    decision    => CLASS->RECORD_AND_SAMPLE,
) => object {
    call recording => T;
    call sampled   => T;
}, 'Recording and sampled';

done_testing;
