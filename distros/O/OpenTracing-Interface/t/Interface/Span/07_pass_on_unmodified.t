use Test::Most;

BEGIN {
    $ENV{OPENTRACING_INTERFACE} = 1 unless exists $ENV{OPENTRACING_INTERFACE};
}
#
# This breaks if it would be set to 0 externally, so, don't do that!!!


our @test_params;



subtest "pass on arguments for 'get_context'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::Span';
    
    lives_ok {
        $test_object->get_context( )
    } "Can call method 'get_context'";
    
    cmp_deeply(
        \@test_params => [
            [ $test_object ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};



subtest "pass on arguments for 'overwrite_operation_name'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::Span';
    
    lives_ok {
        $test_object->overwrite_operation_name( 'new operation-name' )
    } "Can call method 'overwrite_operation_name'";
    
    cmp_deeply(
        \@test_params => [
            [ $test_object, 'new operation-name' ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};



subtest "pass on arguments for 'finish'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::Span';
    
    lives_ok {
        $test_object->finish( )
    } "Can call method 'finish'";
    
    lives_ok {
        $test_object->finish( 123.45 )
    } "Can call method 'finish' with a timestamp";
    
    cmp_deeply(
        \@test_params => [
            [ $test_object ],
            [ $test_object, 123.45 ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};



subtest "pass on arguments for 'set_tag'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::Span';
    
    lives_ok {
        $test_object->set_tag( tag_key => 0 )
    } "Can call method 'set_tag'";
    
    cmp_deeply(
        \@test_params => [
            [ $test_object, 'tag_key', 0 ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};



subtest "pass on arguments for 'log_data'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::Span';
    
    lives_ok {
        $test_object->log_data( log_key_1 => 1, log_key_2 => 2 )
    } "Can call method 'log_data'";
    
    cmp_deeply(
        \@test_params => [
            [ $test_object, 'log_key_1', 1, 'log_key_2', 2 ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};



subtest "pass on arguments for 'set_baggage_item'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::Span';
    
    lives_ok {
        $test_object->set_baggage_item( item => 'value' )
    } "Can call method 'set_baggage_item'";
    
    cmp_deeply(
        \@test_params => [
            [ $test_object, 'item', 'value' ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};



subtest "pass on arguments for 'get_baggage_item'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::Span';
    
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



done_testing();



package MyTest::Span;

sub get_context {
    push @main::test_params, [ @_ ];
    
    return bless {}, 'MyDuck::SpanContext'
    
};

sub overwrite_operation_name {
    push @main::test_params, [ @_ ];
    
    return shift
    
};

sub finish {
    push @main::test_params, [ @_ ];
    
    return shift
    
};

sub set_tag {
    push @main::test_params, [ @_ ];
    
    return shift
    
};

sub log_data {
    push @main::test_params, [ @_ ];
    
    return shift
    
};

sub set_baggage_item {
    push @main::test_params, [ @_ ];
    
    return shift
    
};

sub get_baggage_item {
    push @main::test_params, [ @_ ];
    
    return 'this is a baggae item value - what ever'
    
};

BEGIN {
    use Role::Tiny::With;
    with 'OpenTracing::Interface::Span'
}



package MyDuck::SpanContext;

sub get_baggage_item;
sub with_baggage_item;



1;
