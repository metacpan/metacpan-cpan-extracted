use Test::Most;


use Devel::StrictMode;

subtest "All happy ..." => sub {
    
    my $some_scope = bless {}, 'MyStub::Scope';
    
    my $mock_scope_manager = MyStub::ScopeManager->new;
        
    lives_ok {
        $mock_scope_manager->build_scope(
            span                 => bless( {}, 'MyStub::Span' ), 
            finish_span_on_close => 1,
        )
    } "Does build and return a Scope";
    
};



subtest "Missing Required Named Arguments ..." => sub {
    
    SKIP: { skip "Not under STRICT, no exceptions thrown", 2 unless STRICT;
    
    my $some_scope = bless {}, 'MyStub::Scope';
    
    my $mock_scope_manager = MyStub::ScopeManager->new;
        
    throws_ok {
        $mock_scope_manager->build_scope(
            finish_span_on_close => 1,
            finish_span_on_close => 1,
            #
            # declare does a required count, before name
        )
    } qr/missing named parameter: span/,
        "Does require a 'span' argumnent";
    
    throws_ok {
        $mock_scope_manager->build_scope(
            span                 => bless( {}, 'MyStub::Span' ), 
            span                 => bless( {}, 'MyStub::Span' ), 
            #
            # declare does a required count, before name
        )
    } qr/missing named parameter: finish_span_on_close/,
        "Does require a 'finish_span_on_close' argumnent";
    
    }
};



subtest "Bad Return Type ..." => sub {
    
    SKIP: { skip "Not under STRICT, no exceptions thrown", 2 unless STRICT;
    
    my $some_scope = bless {}, 'MyStub::Scope';
    
    my $mock_scope_manager = MyStub::ScopeManager::Undef->new;
        
    throws_ok {
        my $return = $mock_scope_manager->build_scope(
            span                 => bless( {}, 'MyStub::Span' ), 
            finish_span_on_close => 1,
        );
    } qr/Undef did not pass type constraint "Scope"/,
        "Does need to return a Scope";
    }
    
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

# sub close { $_[0]->_set_closed( !undef); $_[0] }

BEGIN { with 'OpenTracing::Role::Scope'; }



package MyStub::ScopeManager;
use Moo;

sub build_scope { bless {}, 'MyStub::Scope' };

BEGIN { with 'OpenTracing::Role::ScopeManager'; }



package MyStub::ScopeManager::Undef;
use Moo;

sub build_scope { undef };

BEGIN { with 'OpenTracing::Role::ScopeManager'; }



1;
