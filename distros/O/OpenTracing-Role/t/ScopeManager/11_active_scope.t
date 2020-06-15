use Test::More;



subtest "Setters and Getter" => sub {
    
    my $some_scope = bless {}, 'MyStub::Scope';
    
    my $scope_manager = MyStub::ScopeManager->new;
    
    $scope_manager->set_active_scope( $some_scope );
    
    is $scope_manager->get_active_scope, $some_scope,
        "Got the same Scope as that we set";
    
};



done_testing;



package MyStub::Scope;
use Moo;

BEGIN { with 'OpenTracing::Role::Scope'; }



package MyStub::ScopeManager;
use Moo;

sub build_scope { ... };

BEGIN { with 'OpenTracing::Role::ScopeManager'; }



1;