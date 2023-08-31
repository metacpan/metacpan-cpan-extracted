use Test::Most;
use HTTP::Headers;


use aliased 'OpenTracing::Implementation::DataDog::Tracer';



subtest 'No default_context or callback' => sub {
    
    my $test_tracer;
    lives_ok {
        $test_tracer = Tracer->new( );
    } "Can create a Tracer, without any attributes";
    
    
    my $test_span_context;
    lives_ok {
        $test_span_context = $test_tracer
            ->extract_context(
                bless( { foo => 0, bar => [ 1, 2 ] }, 'HTTP::Headers' )
            )
        #
        # XXX: this needs a FORMAT and a carrier
    } "... and can call 'extract_context'";
    
    ok !defined $test_span_context,
        "... but returns 'undef'"
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
        style    => ' datadog,   b3multi ', # extra whitespace and double style
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
        trace_id => undef,
        span_id  => undef,
        headers  => {},
    },
);

foreach my $case (@cases) {
    my $style = $case->{style};
    subtest 'HTTP Headers - ' . ($style // 'default style') => sub {
        local $ENV{DD_TRACE_PROPAGATION_STYLE} = $style;
        
        my $test_tracer;
        lives_ok {
            $test_tracer = Tracer->new(
                default_service_name  => 'test',
                default_resource_name => '/path',
            );
        } "Can create a Tracer, with default service name";
        
        my $trace_id = $case->{trace_id};
        my $span_id  = $case->{span_id};
        
        my $test_span_context;
        lives_ok {
            $test_span_context = $test_tracer->extract_context(
                HTTP::Headers->new( %{ $case->{headers} })
            )
        } "... and can call 'extract_context'";

        if (defined $trace_id and defined $span_id) {
            ok defined $test_span_context, "... and returns a context";
            is $test_span_context->trace_id, $trace_id, 'trace id';
            is $test_span_context->span_id, $span_id, 'span id';
        } else {
            ok !defined $test_span_context, "... and doesn't return a context";
        }
    };
}

done_testing( );
