use Test::Most;


use aliased 'OpenTracing::Implementation::DataDog::SpanContext';

use Types::Standard qw/is_Int/;



subtest 'new SpanContext with all parameters' => sub {
    
    my $test_span_context;
    
    lives_ok {
        $test_span_context = SpanContext->new(
#           trace_id      => 12345, # you can not assign to trace_id!
            service_type  => 'web',
            service_name  => 'srvc name',
            resource_name => 'rsrc name',
            baggage_items => { foo => 1, bar => 2 },
            environment   => 'test envr',
            hostname      => 'host name',
        )
    } "Created a SpanContext" ;
    
};



subtest 'new SpanContext with minimal parameters' => sub {
    
    my $test_span_context;
    
    local $ENV{ DD_SERVICE_NAME } = 'srvc dflt';
    local $ENV{ DD_ENV          } = 'test envr';
    local $ENV{ DD_HOSTNAME     } = 'host dflt';
    
    lives_ok {
        $test_span_context = SpanContext->new(
#           service_name  => 'srvc name', # DD_SERVICE_NMAME
            resource_name => 'rsrc name',
        )
    } "Created a SpanContext" ;
    
    ok ( is_Int( $test_span_context->trace_id ),
        "... and default 'trace_id' has been set to an 'Int'"
    );
    is ( $test_span_context->get_service_type, 'custom',
        "... and default 'service_type' has been set to 'custom'"
    );
    is ( $test_span_context->get_service_name, 'srvc dflt',
        "... and default 'service_name' has been set to DD_SERVICE_NAME"
    );
    is ( $test_span_context->get_environment, 'test envr',
        "... and default 'environment' has been set to DD_ENV"
    );
    is ( $test_span_context->get_hostname, 'host dflt',
        "... and default 'hostname' has been set to DD_HOSTNAME"
    );
    
};



done_testing;
