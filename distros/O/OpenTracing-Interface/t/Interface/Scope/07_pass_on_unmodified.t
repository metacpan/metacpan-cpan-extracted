use Test::Most;

BEGIN {
    $ENV{OPENTRACING_INTERFACE} = 1 unless exists $ENV{OPENTRACING_INTERFACE};
}
#
# This breaks if it would be set to 0 externally, so, don't do that!!!


our @test_params;




subtest "pass on arguments for 'close'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::Scope';
    
    lives_ok {
        $test_object->close( )
    } "Can call method 'close'";
    
    cmp_deeply(
        \@test_params => [
            [ $test_object ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};



subtest "pass on arguments for 'get_span'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::Scope';
    
    lives_ok {
        $test_object->get_span()
    } "Can call method 'get_span'";
    
    cmp_deeply(
        \@test_params => [
            [ $test_object ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};



done_testing();



package MyTest::Scope;

sub close {
    push @main::test_params, [ @_ ];
    
    return shift;
    
};

sub get_span {
    push @main::test_params, [ @_ ];
    
    return bless {}, 'MyDuck::Span'
    
};

BEGIN {
    use Role::Tiny::With;
    with 'OpenTracing::Interface::Scope'
}



package MyDuck::Span;

sub get_context;
sub overwrite_operation_name;
sub finish;
sub set_tag;
sub log_data;
sub set_baggage_item;
sub get_baggage_item;



1;
