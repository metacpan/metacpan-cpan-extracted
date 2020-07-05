use Test::Most;
use Test::MockModule;

use aliased 'OpenTracing::Implementation::DataDog::Span';
use aliased 'OpenTracing::Implementation::DataDog::SpanContext';
use aliased 'OpenTracing::Implementation::DataDog::Tracer';

use Ref::Util qw/is_coderef/;

=for

instance_method build_span (
    Str                         :$operation_name,
    SpanContext                 :$context,
    Maybe[ SpanContext | Span ] :$child_of,
    Maybe[ PositiveOrZeroNum ]  :$start_time,
    Maybe[ HashRef[Str] ]       :$tags,
) :Return (Span) { };

=cut

subtest "Build with known options" => sub {
    
    my $some_context;
    lives_ok {
        $some_context = SpanContext->new(
            service_name    => 'srvc name',
            resource_name   => 'rsrc name',
        );
    } "Created some 'SpanContext'"
    
    or return;
    
    my $some_span;
    lives_ok {
        $some_span = Span->new(
            operation_name  => 'foo',
            context         => {
                service_name    => 'srvc name',
                resource_name   => 'rsrc name',
            },
        );
    } "Created some 'Span'"
    
    or return;
    
    my $test_tracer;
    lives_ok {
        $test_tracer = Tracer->new( );
    } "Created a test 'Tracer'"
    
    or return;
    
    my $mock_test = test_datadog_span(
        {
            operation_name => 'build_with_known_options',
            context        => $some_context,
            child_of       => $some_span,
            start_time     => 1234.125,
            tags           => { foo => 1, bar => 2 },
            on_finish      => code( sub { is_coderef shift } ),
        },
        "'Span->new' did receive the expected arguments"
    );
    
    lives_ok {
        $test_tracer->build_span(
            operation_name          => 'build_with_known_options',
            context                 => $some_context,
            child_of                => $some_span,
            start_time              => 1234.125,
            tags                    => { foo => 1, bar => 2 },
        );
    } "... during call 'build_span'"
    
    or return;
    

};


subtest "Build without optional arguments" => sub {
    
    my $some_context;
    lives_ok {
        $some_context = SpanContext->new(
            service_name    => 'srvc name',
            resource_name   => 'rsrc name',
        );
    } "Created some 'SpanContext'"
    
    or return;
    
    my $test_tracer;
    lives_ok {
        $test_tracer = Tracer->new( );
    } "Created a test 'Tracer'"
    
    or return;
    
    my $mock_test = test_datadog_span(
        {
            operation_name => 'build_without_optionals',
            context        => $some_context,
            on_finish      => code( sub { is_coderef shift } ),
        },
        "'Span->new' did not introduce undefined arguments"
    );
    
    lives_ok {
        $test_tracer->build_span(
            operation_name          => 'build_without_optionals',
            context                 => $some_context,
        );
    } "... during call 'build_span'"
    
    or return;
    

};


done_testing();



sub test_datadog_span {
    my $expected = shift;
    my $message = shift;
    
    my $mock = Test::MockModule
        ->new( 'OpenTracing::Implementation::DataDog::Span' );
    $mock->mock( 'new' =>
        sub {
            my $self = shift;
            my %args = @_;
            cmp_deeply( \%args => $expected, $message );
        }
    );
    return $mock
}
