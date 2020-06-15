use Test::Most;
use Test::MockObject::Extends;


=for comments:

Test that:
- given a ScopeManager
- given a Acitve Scope
- given a related Span

we do return that Span, `undef` otherwise

=cut

subtest "All happy ..." => sub {
    
    my $some_span = bless {}, 'MyStub::Span';
    
    my $mock_scope = Test::MockObject::Extends->new(
        bless {}, 'MyStub::Scope'
    )->mock( get_span =>
        sub { $some_span }
    );
    
    my $mock_scope_manager = Test::MockObject::Extends->new(
        bless {}, 'MyStub::ScopeManager'
    )->mock( get_active_scope =>
        sub { $mock_scope }
    );
    
    my $mock_tracer = Test::MockObject::Extends->new(
        MyStub::Tracer->new(
            scope_manager => $mock_scope_manager,
        )
    );
    
    is $mock_tracer->get_active_span(), $some_span,
        "Does return the expected span"
};



subtest "No Active Scope" => sub {
    
    my $mock_scope_manager = bless {
        active_scope => undef,
    }, 'MyStub::ScopeManager';

    my $mock_tracer = Test::MockObject::Extends->new(
        MyStub::Tracer->new(
            scope_manager => $mock_scope_manager
        )
    );
    
TODO: {
    
    local $TODO = "Wait for v0.19 of OT::Interface, allow for 'undef'";
    
    is $mock_tracer->get_active_span(), undef,
        "Does return `undef` without complaints";
    
    }
    
};



done_testing();



# MyStub::...
#
# The following packages are stubs with minimal implementation that only
# satisfy required subroutines so roles can be applied.
# Any subroutines under testing probably need mocking
# Test::MockObject::Extends is your friend

package MyStub::Tracer;
use Moo;

sub build_span          { ... }
sub build_context       { ... }
sub extract_context     { ... }
sub inject_context      { ... }

BEGIN { with 'OpenTracing::Role::Tracer'; }



package MyStub::Span;
use Moo;

BEGIN { with 'OpenTracing::Role::Span'; }



package MyStub::Scope;
use Moo;

sub close { $_[0]->_set_closed( !undef); $_[0] }

BEGIN { with 'OpenTracing::Role::Scope'; }



package MyStub::ScopeManager;
use Moo;

sub build_scope { ... };

BEGIN { with 'OpenTracing::Role::ScopeManager'; }






1;
