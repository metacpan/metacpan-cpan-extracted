use strict;
use warnings;

use Test::More;
use Test::Deep;

use OpenTracing::Tracer;

my $tracer = new_ok('OpenTracing::Tracer');
isa_ok($tracer->process, 'OpenTracing::Process');
subtest duration => sub {
    isa_ok(my $span = $tracer->span, 'OpenTracing::SpanProxy');
    is($span->duration, undef, 'no duration yet');
    Time::HiRes::sleep(0.1);
    is($span->duration, undef, 'still no duration yet');
    $span->finish;
    cmp_ok($span->duration, '>=', 0.1, 'span duration is realistic');
    done_testing;
};
subtest chained => sub {
    my $span = $tracer->span;
    isa_ok(my $child = $span->new_span, 'OpenTracing::SpanProxy');
    is($child->parent_id, $span->id, 'parent ID is correct');
    is($child->trace_id, $span->trace_id, 'trace ID is correct');
    cmp_deeply($tracer->spans, superbagof(
        map { $_->span } $span, $child
    ), 'have both spans queued in tracer');
    done_testing;
};
done_testing;

