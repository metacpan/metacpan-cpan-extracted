use Test::Most;

BEGIN {
    $ENV{EXTENDED_TESTING} = 1 unless exists $ENV{EXTENDED_TESTING};
}
#
# This breaks if it would be set to 0 externally, so, don't do that!!!


our @test_params;



subtest "pass on arguments for 'new_child_of'" => sub {
    
    undef @test_params;
    
    my $duck_spancontext = bless {}, 'MyStub::SpanContext';
    
    lives_ok {
        MyTest::ContextReference->new_child_of( $duck_spancontext )
    } "Can call method 'new_child_of'";
    
    cmp_deeply(
        \@test_params => [
            [ 'MyTest::ContextReference', $duck_spancontext ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};



subtest "pass on arguments for 'new_follows_from'" => sub {
    
    undef @test_params;
    
    my $duck_spancontext = bless {}, 'MyStub::SpanContext';
    
    lives_ok {
        MyTest::ContextReference->new_follows_from( $duck_spancontext )
    } "Can call method 'new_follows_from'";
    
    cmp_deeply(
        \@test_params => [
            [ 'MyTest::ContextReference', $duck_spancontext ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};



subtest "pass on arguments for 'get_referenced_context'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::ContextReference';
    
    lives_ok {
        $test_object->get_referenced_context( )
    } "Can call method 'get_referenced_context'";
    
    cmp_deeply(
        \@test_params => [
            [ $test_object ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};



subtest "pass on arguments for 'type_is_child_of'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::ContextReference';
    
    lives_ok {
        $test_object->type_is_child_of( )
    } "Can call method 'type_is_child_of'";
    
    cmp_deeply(
        \@test_params => [
            [ $test_object ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};



subtest "pass on arguments for 'type_is_follows_from'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::ContextReference';
    
    lives_ok {
        $test_object->type_is_follows_from( )
    } "Can call method 'type_is_follows_from'";
    
    cmp_deeply(
        \@test_params => [
            [ $test_object ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};



done_testing();



package MyTest::ContextReference;

sub new_child_of {
    push @main::test_params, [ @_ ];
    
    return bless {}, 'MyTest::ContextReference'
    
};

sub new_follows_from {
    push @main::test_params, [ @_ ];
    
    return bless {}, 'MyTest::ContextReference'
    
};

sub get_referenced_context {
    push @main::test_params, [ @_ ];
    
    return bless {}, 'MyStub::SpanContext'
    
};

sub type_is_child_of {
    push @main::test_params, [ @_ ];
    
    return !undef;
    
};

sub type_is_follows_from {
    push @main::test_params, [ @_ ];
    
    return !undef;
    
};

BEGIN {
    use Role::Tiny::With;
    with 'OpenTracing::Interface::ContextReference'
}



package MyStub::SpanContext;

sub get_baggage_item   { ... };
sub get_baggage_items  { ... };
sub with_baggage_item  { ... };
sub with_baggage_items { ... };



1;
