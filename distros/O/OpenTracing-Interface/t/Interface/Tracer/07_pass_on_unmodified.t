use Test::Most;

BEGIN {
    $ENV{OPENTRACING_INTERFACE} = 1 unless exists $ENV{OPENTRACING_INTERFACE};
}
#
# This breaks if it would be set to 0 externally, so, don't do that!!!


our @test_params;



subtest "pass on arguments for 'get_scope_manager'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::Tracer';
    
    lives_ok {
        $test_object->get_scope_manager( )
    } "Can call method 'get_scope_manager'";
    
    cmp_deeply(
        \@test_params => [
            [ $test_object ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};



subtest "pass on arguments for 'start_active_span'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::Tracer';
    
    lives_ok {
        $test_object->start_active_span( 'this is an operation name' )
    } "Can call method 'start_active_span' with only a operation name";
    
    cmp_deeply(
        \@test_params => [
            [ $test_object, 'this is an operation name' ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
    undef @test_params;
    
    my $span_context         = bless {}, 'MyDuck::SpanContext';
    my $context_reference_1  = bless {}, 'MyDuck::ContextReference';
    my $context_reference_2  = bless {}, 'MyDuck::ContextReference';
    
    # the options 'child_of' and 'references' are mutual exclusive
    # so we test those separatly
    
    lives_ok {
        $test_object->start_active_span( 'here is an operation name' =>
            child_of             => $span_context,
        )
    } "Can call method 'start_active_span' with option 'child_of'";
    
    lives_ok {
        $test_object->start_active_span( 'here is an operation name' =>
            references           => [
                $context_reference_1,
                $context_reference_2,
            ],
        )
    } "Can call method 'start_active_span' with option 'references'";
    
    lives_ok {
        $test_object->start_active_span( 'here is an operation name' =>
#           child_of             => $span_context,
#           references           => [ $reference_1, $reference_2 ],
            tags                 => {
                tag_1                => 'value 1',
                tag_2                => 'value 2',
            },
            start_time           => 123.45,
            ignore_active_span   => 1,
            finish_span_on_close => 0,
        )
    } "Can call method 'start_active_span' with other named options";
    
    cmp_deeply(
        \@test_params => [
            [
                $test_object,
                'here is an operation name',
                'child_of',
                $span_context,
            ],
            [
                $test_object,
                'here is an operation name',
                'references',
                [
                    $context_reference_1,
                    $context_reference_2,
                ],
            ],
            [
                $test_object,
                'here is an operation name',
                'tags',
                {
                    tag_1 => 'value 1',
                    tag_2 => 'value 2',
                },
                'start_time',
                123.45,
                'ignore_active_span',
                1,
                'finish_span_on_close',
                0,
            ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};



subtest "pass on arguments for 'start_span'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::Tracer';
    
    lives_ok {
        $test_object->start_span( 'this is an operation name' )
    } "Can call method 'start_span' with only a operation name";
    
    cmp_deeply(
        \@test_params => [
            [ $test_object, 'this is an operation name' ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
    undef @test_params;
    
    my $span_context         = bless {}, 'MyDuck::SpanContext';
    my $context_reference_1  = bless {}, 'MyDuck::ContextReference';
    my $context_reference_2  = bless {}, 'MyDuck::ContextReference';
    
    # the options 'child_of' and 'references' are mutual exclusive
    # so we test those separatly
    
    lives_ok {
        $test_object->start_span( 'here is an operation name' =>
            child_of             => $span_context,
        )
    } "Can call method 'start_span' with option 'child_of'";
    
    lives_ok {
        $test_object->start_span( 'here is an operation name' =>
            references           => [
                $context_reference_1,
                $context_reference_2,
            ],
        )
    } "Can call method 'start_span' with option 'references'";
    
    lives_ok {
        $test_object->start_span( 'here is an operation name' =>
#           child_of             => $span_context,
#           references           => [ $reference_1, $reference_2 ],
            tags                 => {
                tag_1                => 'value 1',
                tag_2                => 'value 2',
            },
            start_time           => 123.45,
            ignore_active_span   => 1,
        )
    } "Can call method 'start_span' with other named options";
    
    cmp_deeply(
        \@test_params => [
            [
                $test_object,
                'here is an operation name',
                'child_of',
                $span_context,
            ],
            [
                $test_object,
                'here is an operation name',
                'references',
                [
                    $context_reference_1,
                    $context_reference_2,
                ],
            ],
            [
                $test_object,
                'here is an operation name',
                'tags',
                {
                    tag_1 => 'value 1',
                    tag_2 => 'value 2',
                },
                'start_time',
                123.45,
                'ignore_active_span',
                1,
            ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};



subtest "pass on arguments for 'inject_context'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::Tracer';
    
    my $span_context = bless {}, 'MyDuck::SpanContext';
    my $carrier      = bless {}, 'MyDuck::Carrier'; # nope, does not exists
    
    lives_ok {
        $test_object->inject_context(
            CARRIER_FORMAT => $carrier,
            $span_context
        )
    } "Can call method 'inject_context'";
    
    cmp_deeply(
        \@test_params => [
            [
                $test_object,
                'CARRIER_FORMAT',
                $carrier,
                $span_context,
            ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};



subtest "pass on arguments for 'extract_context'" => sub {
    
    undef @test_params;
    
    my $test_object = bless {}, 'MyTest::Tracer';
    
    my $carrier      = bless {}, 'MyDuck::Carrier'; # nope, does not exists
    
    lives_ok {
        $test_object->extract_context(
            CARRIER_FORMAT => $carrier
        )
    } "Can call method 'extract_context'";
    
    cmp_deeply(
        \@test_params => [
            [
                $test_object,
                'CARRIER_FORMAT',
                $carrier
            ],
        ],
        "... and the original subroutine gets the expected arguments"
    );
    
};










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
    
} if undef;



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
    
} if undef;



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
    
} if undef;



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
    
} if undef;



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
    
} if undef;



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
    
} if undef;



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
    
} if undef;



done_testing();



package MyTest::Tracer;

sub get_scope_manager {
    push @main::test_params, [ @_ ];
    
    return bless {}, 'MyDuck::ScopeManager'
    
};

sub get_active_span {

    push @main::test_params, [ @_ ];
    
    return bless {}, 'MyDuck::Span'
    
};

sub start_active_span {

    push @main::test_params, [ @_ ];
    
    return bless {}, 'MyDuck::Scope'
    
};

sub start_span {

    push @main::test_params, [ @_ ];
    
    return bless {}, 'MyDuck::Span'
    
};

sub inject_context {

    push @main::test_params, [ @_ ];
    
    return bless {}, 'MyDuck::Carrier' # don't care
    
};

sub extract_context {

    push @main::test_params, [ @_ ];
    
    return bless {}, 'MyDuck::SpanContext'
    
};

BEGIN {
    use Role::Tiny::With;
    with 'OpenTracing::Interface::Tracer'
}






package MyDuck::ContextReference;

sub new_child_of;
sub new_follows_from;
sub get_referenced_context;
sub type_is_child_of;
sub type_is_follows_from;



package MyDuck::Span;

sub get_context;
sub overwrite_operation_name;
sub finish;
sub set_tag;
sub log_data;
sub set_baggage_item;
sub get_baggage_item;



package MyDuck::SpanContext;

sub get_baggage_item;
sub with_baggage_item;



package MyDuck::Scope;

sub close;
sub get_span;



package MyDuck::ScopeManager;

sub activate_span;
sub get_active_scope;



1;
