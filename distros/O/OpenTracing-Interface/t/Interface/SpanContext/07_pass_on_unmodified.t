use Test::Most;

BEGIN {
    $ENV{EXTENDED_TESTING} = 1 unless exists $ENV{EXTENDED_TESTING};
}
#
# This breaks if it would be set to 0 externally, so, don't do that!!!


our @test_params;



subtest "pass on arguments for 'get_baggage_item'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::SpanContext';
    
    lives_ok {
        $test_object->get_baggage_item( 'item' )
    } "Can call method 'get_baggage_item'";
    
    cmp_deeply(
        \@test_params => [
            [ $test_object, 'item' ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};



subtest "pass on arguments for 'with_baggage_item'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::SpanContext';
    
    lives_ok {
        $test_object->with_baggage_item( item => 'value' )
    } "Can call method 'with_baggage_item'";
    
    cmp_deeply(
        \@test_params => [
            [ $test_object, 'item', 'value' ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};




subtest "pass on arguments for 'with_baggage_items'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::SpanContext';
    
    lives_ok {
        $test_object->with_baggage_items( item => 'value', that => 'other' )
    } "Can call method 'with_baggage_item'";
    
    cmp_deeply(
        \@test_params => [
            [ $test_object, 'item', 'value', 'that', 'other' ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};






done_testing();



package MyTest::SpanContext;

sub get_baggage_item {
    push @main::test_params, [ @_ ];
    
    return 'this is a baggage item value - what ever'
};

sub get_baggage_items {
    push @main::test_params, [ @_ ];
    
    return this => 1, that => 2
};

sub with_baggage_item {
    push @main::test_params, [ @_ ];
    
    return bless {}, 'MyStub::SpanContext'
};

sub with_baggage_items {
    push @main::test_params, [ @_ ];
    
    return bless {}, 'MyStub::SpanContext'
};

BEGIN {
    use Role::Tiny::With;
    with 'OpenTracing::Interface::SpanContext'
}



package MyStub::SpanContext;

sub get_baggage_item;
sub get_baggage_items;
sub with_baggage_item;



1;
