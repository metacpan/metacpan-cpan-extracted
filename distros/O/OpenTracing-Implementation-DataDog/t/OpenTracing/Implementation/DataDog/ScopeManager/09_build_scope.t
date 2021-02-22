use Test::Most;
use Test::MockModule;

use aliased 'OpenTracing::Implementation::DataDog::ScopeManager';
use aliased 'OpenTracing::Implementation::DataDog::Span';

use Ref::Util qw/is_coderef/;



subtest "Build with known options" => sub {
    
    my $some_span;
    lives_ok {
        $some_span = Span->new(
            operation_name  => 'foo',
            context         => {
                service_name    => 'srvc name',
                resource_name   => 'rsrc name',
            },
        );
    } "Created a 'Span'"
    
    or return;
    
    my $test_scope_manager;
    lives_ok {
        $test_scope_manager = ScopeManager->new;
    } "Created a 'ScopeManager'"
    
    or return;
    
    my $mock_test = test_datadog_scope(
        {
            span                 => $some_span,
            finish_span_on_close => 0,
            on_close             => code( sub { is_coderef shift } ),
        },
        "'Scope->new' did receive the expected arguments"
    );
    
    lives_ok {
        $test_scope_manager->build_scope(
            span                 => $some_span,
            finish_span_on_close => 0,
        );
    } "... during call 'build_scope'"
    
    or return;
    
};



done_testing();



sub test_datadog_scope {
    my $expected = shift;
    my $message = shift;
    
    my $mock = Test::MockModule
        ->new( 'OpenTracing::Implementation::DataDog::Scope' );
    $mock->mock( 'new' =>
        sub {
            my $self = shift;
            my %args = @_;
            cmp_deeply( \%args => $expected, $message );
        }
    );
    return $mock
}

