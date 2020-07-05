use Test::Most;
use Test::MockModule;

use aliased 'OpenTracing::Implementation::DataDog::Tracer';

=for

instance_method build_context (
    %span_context_args,
) :Return (SpanContext) {
    ( HashRef[Str] )->assert_valid( { %span_context_args } );
};

=cut

subtest "Build with known options" => sub {
        
    my $test_tracer;
    lives_ok {
        $test_tracer = Tracer->new( );
    } "Created a test 'Tracer'"
    
    or return;
    
    my $mock_test = test_datadog_span_context(
        {
            service_type  => 'db',
            service_name  => 'MyService',
            resource_name => 'build_with_known_options',
#           baggage_items => { foo => 1, bar => 2 },
        },
        "'SpanContext->new' did receive the expected arguments"
    );
    #
    # baggage_items is not allowed during `build_context`
    
    lives_ok {
        $test_tracer->build_context(
            service_type  => 'db',
            service_name  => 'MyService',
            resource_name => 'build_with_known_options',
#           baggage_items => { foo => 1, bar => 2 },
        );
    } "... during call 'build_context'"
    
    or return;
    
};


subtest "Build without optional arguments" => sub {
    
    my $test_tracer;
    lives_ok {
        $test_tracer = Tracer->new( );
    } "Created a test 'Tracer'"
    
    or return;
    
    my $mock_test = test_datadog_span_context(
        {
            resource_name => undef,
        },
        "'SpanContext->new' did introduce a required 'resource_name'"
    );
    
    lives_ok {
        $test_tracer->build_context( );
    } "... during call 'build_context'"
    
    or return;
    
};


subtest "Build with default arguments" => sub {
    
    my $test_tracer;
    lives_ok {
        $test_tracer = Tracer->new(
            default_service_type  => 'cache',
            default_service_name  => 'MyCache',
            default_resource_name => 'build_with_default_options',
        );
    } "Created a test 'Tracer'"
    
    or return;
    
    my $mock_test = test_datadog_span_context(
        {
            service_type  => 'cache',
            service_name  => 'MyCache',
            resource_name => 'build_with_default_options',
        },
        "'SpanContext->new' did introduce a undefined 'resource_name'"
    );
    
    lives_ok {
        $test_tracer->build_context( );
    } "... during call 'build_context'"
    
    or return;
    
};


done_testing();



sub test_datadog_span_context {
    my $expected = shift;
    my $message = shift;
    
    my $mock = Test::MockModule
        ->new( 'OpenTracing::Implementation::DataDog::SpanContext' );
    $mock->mock( 'new' =>
        sub {
            my $self = shift;
            my %args = @_;
            cmp_deeply( \%args => $expected, $message );
        }
    );
    return $mock
}
