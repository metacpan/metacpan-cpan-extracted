use Test::Most;

BEGIN {
    $ENV{EXTENDED_TESTING} = 1 unless exists $ENV{EXTENDED_TESTING};
}
#
# This breaks if it would be set to 0 externally, so, don't do that!!!


our @test_params;




subtest "pass on arguments for 'activate_span'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::ScopeManager';
    
    my $duck_span = bless {}, 'MyStub::Span';
    
    lives_ok {
        $test_object->activate_span( $duck_span )
    } "Can call method 'activate_span'";
    
    lives_ok {
        $test_object->activate_span( $duck_span, finish_span_on_close => 1 )
    } "... can call 'activate_span' with 'finish_span_on_close'";
    
    cmp_deeply(
        \@test_params => [
            [
                $test_object,
                $duck_span,
            ],
            [
                $test_object,
                $duck_span,
                finish_span_on_close => 1,
            ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};



subtest "pass on arguments for 'get_active_scope'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::ScopeManager';
    
    lives_ok {
        $test_object->get_active_scope()
    } "Can call method 'get_active_scope'";
    
    cmp_deeply(
        \@test_params => [
            [ $test_object ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};



done_testing();



package MyTest::ScopeManager;

sub activate_span {
    push @main::test_params, [ @_ ];
    
    return bless {}, 'MyStub::Scope'
    
};

sub get_active_scope {
    push @main::test_params, [ @_ ];
    
    return bless {}, 'MyStub::Scope'
    
};

BEGIN {
    use Role::Tiny::With;
    with 'OpenTracing::Interface::ScopeManager'
}



package MyStub::Scope;

sub close;
sub get_span;



package MyStub::Span;

sub get_context              { ... };
sub overwrite_operation_name { ... };
sub finish                   { ... };
sub add_tag                  { ... };
sub add_tags                 { ... };
sub get_tags                 { ... };
sub log_data                 { ... };
sub add_baggage_item         { ... };
sub add_baggage_items        { ... };
sub get_baggage_item         { ... };
sub get_baggage_items        { ... };



1;
