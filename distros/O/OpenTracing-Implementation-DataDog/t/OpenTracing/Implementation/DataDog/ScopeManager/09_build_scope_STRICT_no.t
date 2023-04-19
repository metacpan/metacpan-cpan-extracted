use Test::Most;
use Test::MockModule;


BEGIN {
    delete $ENV{$_}
        for qw/EXTENDED_TESTING AUTHOR_TESTING RELEASE_TESTING PERL_STRICT/
}

use aliased 'OpenTracing::Implementation::DataDog::ScopeManager';
use aliased 'OpenTracing::Implementation::DataDog::Span';

use Ref::Util qw/is_coderef/;



subtest "Build with missing options" => sub {
    
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
            span                 => undef,
            finish_span_on_close => undef,
            on_close             => code( sub { is_coderef shift } ),
        },
        "'Scope->new' did introduce undefined arguments, which SHOULD fail"
    );
    
    lives_ok {
        $test_scope_manager->build_scope(
        );
    } "And will not die when required arguments are missing, GOOD LUCK!!"
    
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

