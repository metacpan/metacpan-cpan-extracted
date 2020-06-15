use Test::Most;
use Test::MockObject::Extends;
use Test::Deep qw/true false/;

=head1 DESCRIPTION

Purpose of these tests are to check that the call of C<activate_span> (from the
public OpenTracing API) are passed on to the (local) C<buikld_scope> as
expected. Their interface are slightly different, because the calls to C<build>
have only explicit and required named parameters.

=cut

subtest "Do pass-on as Named Parameters with defaults..." => sub {
    
    my ($call_name, $call_args);
    
    my $some_span  = bless {}, 'MyStub::Span';
    
    my $mock_scope_manager = Test::MockObject::Extends->new(
        bless {}, 'MyStub::ScopeManager'
    )->mock( build_scope =>
        sub { bless {}, 'MyStub::Scope' }
    );
    
    lives_ok {
        $mock_scope_manager
            ->activate_span( $some_span,
#               finish_span_on_close => 1, # we want default behaviour tested
            )->close;
    } "Can call 'activate_span' without options";
    
    ($call_name, $call_args) = $mock_scope_manager->next_call();
    
    is( $call_name, 'build_scope',
        "... and did pass on to 'build_scope'"
    );
    
    is( shift @{$call_args}, $mock_scope_manager,
        "... with the invocant is the 'MyStub::ScopeManager'"
    );
    
    cmp_deeply(
        { @{$call_args} },
        {
            span                 => $some_span,
            finish_span_on_close => true,
        },
        "... with the expected required options"
    );
    
};



subtest "Do pass-on as Named Parameters ..." => sub {
    
    my ($call_name, $call_args);
    
    my $some_span  = bless {}, 'MyStub::Span';
    
    my $mock_scope_manager = Test::MockObject::Extends->new(
        bless {}, 'MyStub::ScopeManager'
    )->mock( build_scope =>
        sub { bless {}, 'MyStub::Scope' }
    );
    
    lives_ok {
        $mock_scope_manager
            ->activate_span( $some_span,
               finish_span_on_close => undef,
            )->close;
    } "Can call 'activate_span' with known options";
    
    ($call_name, $call_args) = $mock_scope_manager->next_call();
    
    
    shift @{$call_args};
    
    cmp_deeply(
        { @{$call_args} },
        {
            span                 => $some_span,
            finish_span_on_close => false,
        },
        "... with the expected required options"
    );
    
};



subtest "Does set active scope ..." => sub {
    
    my $some_scope = bless {}, 'MyStub::Scope';
    
    my $mock_scope_manager = Test::MockObject::Extends->new(
        bless {}, 'MyStub::ScopeManager'
    )->mock( build_scope =>
        sub { $some_scope }
    );
    
    lives_ok {
        $mock_scope_manager
            ->activate_span( bless( {}, 'MyStub::Span' ) );
    } "Can call 'activate_span'";
    
    is $mock_scope_manager->get_active_scope, $some_scope,
        "... and did set the active scope to what we got from 'build_scope'";
    
    $mock_scope_manager->get_active_scope->close;
    
};



done_testing();



# MyStub::...
#
# The following packages are stubs with minimal implementation that only
# satisfy required subroutines so roles can be applied.
# Any subroutines under testing probably need mocking
# Test::MockObject::Extends is your friend

package MyStub::Span;
use Moo;

BEGIN { with 'OpenTracing::Role::Span'; }



package MyStub::Scope;
use Moo;

BEGIN { with 'OpenTracing::Role::Scope'; }



package MyStub::ScopeManager;
use Moo;

sub build_scope { ... };

BEGIN { with 'OpenTracing::Role::ScopeManager'; }



1;
