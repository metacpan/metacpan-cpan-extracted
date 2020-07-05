use Test::Most;

BEGIN {
    $ENV{OPENTRACING_INTERFACE} = 1 unless exists $ENV{OPENTRACING_INTERFACE};
}
#
# This breaks if it would be set to 0 externally, so, don't do that!!!


use strict;
use warnings;

use aliased 'OpenTracing::Implementation::DataDog::SpanContext';

subtest 'Clone with service_name' => sub {
    
    my $span_context_1;
    my $span_context_2;
    
    lives_ok {
        $span_context_1 = SpanContext->new(
#           trace_id      => 12345, # you can not assign to trace_id!
            service_type  => 'web',
            service_name  => 'srvc 1',
            resource_name => 'rsrc 1',
            baggage_items => { foo => 1, bar => 2 },
        )
    } "Created a SpanContext [1]"
    
    or return;
    
    lives_ok {
        $span_context_2 = $span_context_1->with_service_type('custom');
    } "... and cloned a new SpanContext [2]"
    
    or return;
    
    isnt $span_context_1, $span_context_2,
    "... that is not the same object reference as the original";
    
    is $span_context_1->trace_id, $span_context_2->trace_id,
        "... but has still the same 'trace_id'";
    
    is $span_context_1->get_service_type, 'web',
        "... and the original SpanContext [1] has not changed";
    
    is $span_context_2->get_service_type, 'custom',
        "... and the cloned SpanContext [2] has the expected values [custom]";
    
};


done_testing;
