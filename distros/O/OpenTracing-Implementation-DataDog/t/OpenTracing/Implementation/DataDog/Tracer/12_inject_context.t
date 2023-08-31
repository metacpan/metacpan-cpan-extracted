use Test::Most;


use aliased 'OpenTracing::Implementation::DataDog::Tracer';



subtest 'Carrier as an hash reference' => sub {
    
    my $test_tracer;
    lives_ok {
        $test_tracer = Tracer->new(
            default_resource_name => 'rsrc_name',
            default_service_name  => 'srvc_name',
            default_service_type  => 'web',
        );
    } "Can create a Tracer, with some defaults"
    
    or return;
    
    my $context = $test_tracer->build_context( );
    
    my $original_carrier = {
#       something => 'here',
        something => 'there',
        someother => 'where',
    };
    
    my $injected_carrier;
    lives_ok {
        $injected_carrier = $test_tracer->inject_context_into_hash_reference(
            $original_carrier, $context,
        );
    } "... and could call `inject_context`"
    
    or return;
    
    cmp_deeply(
        $injected_carrier => {
#           something => 'here',
            something => 'there',
            someother => 'where',
            opentracing_context => {
                trace_id  => ignore(),
                span_id   => ignore(),
                resource  => 'rsrc_name',
                service   => 'srvc_name',
                type      => 'web',
            },
        },
        "... that has the expected key / value pairs"
    );
    
};


subtest 'Carrier as HTTP headers' => sub {
    
    my $test_tracer;
    lives_ok {
        $test_tracer = Tracer->new(
            default_resource_name => 'rsrc_name',
            default_service_name  => 'srvc_name',
            default_service_type  => 'web',
        );
    } "Can create a Tracer, with some defaults"
    
    or return;
    
    my $context = $test_tracer->build_context( );
    
    my $original_carrier = HTTP::Headers->new(
        first  => 'foo',
        second => 'bar',
    );
    my $original_str = $original_carrier->as_string;
    
    my $injected_carrier;
    lives_ok {
        $injected_carrier = $test_tracer->inject_context_into_http_headers(
            $original_carrier, $context,
        );
    } "... and could call `inject_context`"
    
    or return;

    is $injected_carrier->header('first'), 'foo', 'first header preserved';
    is $injected_carrier->header('second'), 'bar', 'second header preserved';
    is $injected_carrier->header('x-datadog-trace-id'), $context->trace_id,
        'trace id injected';
    is $injected_carrier->header('x-datadog-parent-id'), $context->span_id,
        'span id injected';

    is $original_carrier->as_string, $original_str, "original carrier intact";
};


my @cases = (
    {
        style    => undef,                   # default
        trace_id => '5611920385980137472',
        span_id  => '8888811111122222200',
        headers  => {
            "x-datadog-trace-id"  => '5611920385980137472',
            "x-datadog-parent-id" => '8888811111122222200',
        },
    },
    {
        style    => 'datadog',
        trace_id => '5611920385980137472',
        span_id  => '8888811111122222200',
        headers  => {
            "x-datadog-trace-id"  => '5611920385980137472',
            "x-datadog-parent-id" => '8888811111122222200',
        },
    },
    {
        style    => 'b3 single header',
        trace_id => '5611920385980137472',
        span_id  => '8888811111122222200',
        headers  => {
            "b3" => '5611920385980137472-8888811111122222200',
        },
    },
    {
        style    => 'b3multi',
        trace_id => '5611920385980137472',
        span_id  => '8888811111122222200',
        headers  => {
            "x-b3-traceid" => '5611920385980137472',
            "x-b3-spanid"  => '8888811111122222200',
        },
    },
    {
        style    => 'tracecontext',
        trace_id => '5611920385980137472',
        span_id  => '8888811111122222200',
        headers  => {
            "traceparent" => '00-00000000000000004de18bdb9a1e8000-7b5b669c51fc3c78-00',
        },
    },
    {
        style    => 'none',
        trace_id => '5611920385980137472',
        span_id  => '8888811111122222200',
        headers  => {},    # just verify the original carrier is intact
    },
    {
        style    => 'datadog,b3 single header,b3multi,tracecontext',
        trace_id => '5611920385980137472',
        span_id  => '8888811111122222200',
        headers => {
            "x-datadog-trace-id"  => '5611920385980137472',
            "x-datadog-parent-id" => '8888811111122222200',

            "b3"           => '5611920385980137472-8888811111122222200',
            "x-b3-traceid" => '5611920385980137472',
            "x-b3-spanid"  => '8888811111122222200',
            "traceparent"  => '00-00000000000000004de18bdb9a1e8000-7b5b669c51fc3c78-00',
        },
    },
);

foreach my $case (@cases) {
    my $style = $case->{style};
    subtest 'Carrier as HTTP headers - ' . ($style // 'default style'), => sub {
        local $ENV{DD_TRACE_PROPAGATION_STYLE} = $style;

        my $test_tracer;
        lives_ok {
            $test_tracer = Tracer->new(
                default_resource_name => 'rsrc_name',
                default_service_name  => 'srvc_name',
                default_service_type  => 'web',
            );
        } "Can create a Tracer, with some defaults"
        
        or return;
        
        my $context = $test_tracer->build_context( )
                ->with_trace_id($case->{trace_id})
                ->with_span_id($case->{span_id});
        
        my $original_carrier = HTTP::Headers->new(
            first  => 'foo',
            second => 'bar',
        );
        my $original_str = $original_carrier->as_string;
        
        my $injected_carrier;
        lives_ok {
            $injected_carrier = $test_tracer->inject_context_into_http_headers(
                $original_carrier, $context,
            );
        } "... and could call `inject_context`"
        or return;

        is $injected_carrier->header('first'), 'foo', 'first header preserved';
        is $injected_carrier->header('second'), 'bar', 'second header preserved';

        while (my ($header, $value) = each %{ $case->{headers} }) {
            is $injected_carrier->header($header), $value, "$header injected";
        }

        is $original_carrier->as_string, $original_str, "original carrier intact";
    };
}

done_testing();
