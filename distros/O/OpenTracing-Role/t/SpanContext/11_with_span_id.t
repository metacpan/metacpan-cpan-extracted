use Test::Most;

BEGIN {
    $ENV{OPENTRACING_INTERFACE} = 1 unless exists $ENV{OPENTRACING_INTERFACE};
}
#
# This breaks if it would be set to 0 externally, so, don't do that!!!


use strict;
use warnings;


subtest 'Clone with span_id' => sub {
    
    my $span_context_1;
    my $span_context_2;
    
    lives_ok {
        $span_context_1 = MyStub::SpanContext->new(
#           trace_id      => 12345, # you can not assign to trace_id!
#           span_id       => 67890, # you can not assign to span_id!
            baggage_items => { foo => 1, bar => 2 },
        )
    } "Created a SpanContext [1]"
    
    or return;
    
    my $span_id_1 = $span_context_1->span_id;
    
    lives_ok {
        $span_context_2 = $span_context_1->with_span_id('67890');
    } "... and cloned a new SpanContext [2]"
    
    or return;
    
    isnt $span_context_1, $span_context_2,
    "... that is not the same object reference as the original";
    
    is $span_context_1->trace_id, $span_context_2->trace_id,
        "... but has still the same 'trace_id'";
    
    is $span_context_1->span_id, $span_id_1,
        "... and the original SpanContext [1] has not changed";
    
    is $span_context_2->span_id, '67890',
        "... and the cloned SpanContext [2] has the expected values [67890]";
    
};



done_testing;



package MyStub::SpanContext;
use Moo;

BEGIN { with 'OpenTracing::Role::SpanContext'; }



1;
