use Test::Most;


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
            environment   => 'staging',
        )
    } "Created a SpanContext [1]"
    
    or return;
    
    lives_ok {
        $span_context_2 = $span_context_1->with_environment('production');
    } "... and cloned a new SpanContext [2]"
    
    or return;
    
    isnt $span_context_1, $span_context_2,
    "... that is not the same object reference as the original";
    
    is $span_context_1->trace_id, $span_context_2->trace_id,
        "... but has still the same 'trace_id'";
    
    is $span_context_1->get_environment, 'staging',
        "... and the original SpanContext [1] has not changed";
    
    is $span_context_2->get_environment, 'production',
        "... and the cloned SpanContext [2] has the expected values [production]";
    
};


done_testing;
