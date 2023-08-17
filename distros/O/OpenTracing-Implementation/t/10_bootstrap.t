use Test::Most;

BEGIN {
    use Module::Loaded;
    mark_as_loaded( OpenTracing::Implementation::NoOp::Tracer )
    #
    # underlying use OpenTracing::GlobalTracer import warns if it can not load the NoOp::Tracer
}

use OpenTracing::Implementation;

use Module::Loaded;

# _build_tracer will try to `load` these from disk
#
mark_as_loaded( MyTest::Implementation );
mark_as_loaded( MyTest::Default );
mark_as_loaded( OpenTracing::Implementation::NoOp );



our @test_params;



subtest "pass on arguments for 'bootstrap_tracer'" => sub {
    
    undef @test_params;
    
    lives_ok {
        my $tracer = OpenTracing::Implementation->bootstrap_tracer(
            '+MyTest::Implementation',
            foo => 1,
            qw/more/
        )
    } "Can call method 'bootstrap_tracer'";
    
    cmp_deeply(
        \@test_params => [
            [ 'MyTest::Implementation', 'foo', 1, 'more' ]
        ], "... and passes on the right params to 'MyTest::Implementation"
    );
    
};



subtest "pass NO arguments for 'bootstrap_default_tracer'" => sub {
    
    undef @test_params;
    
    local $ENV{OPENTRACING_IMPLEMENTATION} = '+MyTest::Default';
    
    lives_ok {
        my $tracer = OpenTracing::Implementation->bootstrap_default_tracer(
        )
    } "Can call method 'bootstrap_default_tracer'";
    
    cmp_deeply(
        \@test_params => [
            [ 'MyTest::Default' ]
        ], "... and passes on the right params to 'MyTest::Default', NONE!"
    );
    
};



subtest "pass on arguments for 'bootstrap_default_tracer'" => sub {
    
    undef @test_params;
    
    local $ENV{OPENTRACING_IMPLEMENTATION} = '+MyTest::Default';
    
    lives_ok {
        my $tracer = OpenTracing::Implementation->bootstrap_default_tracer(
            bar => 2,
            qw/more here/
        )
    } "Can call method 'bootstrap_default_tracer'";
    
    cmp_deeply(
        \@test_params => [
            [ 'MyTest::Default', 'bar', 2, 'more', 'here' ]
        ], "... and passes on the right params to 'MyTest::Default"
    );
    
};



subtest "pass on arguments for 'bootstrap_global_tracer'" => sub {
    
    undef @test_params;
    
    lives_ok {
        my $tracer = OpenTracing::Implementation->bootstrap_global_tracer(
            '+MyTest::Implementation',
            baz => 3,
            qw/and more/
        )
    } "Can call method 'bootstrap_global_tracer'";
    
    cmp_deeply(
        \@test_params => [
            [ 'MyTest::Implementation', 'baz', 3, 'and', 'more' ]
        ], "... and passes on the right params to 'MyTest::Implementation"
    );
    
};



subtest "pass on arguments for 'bootstrap_global_default_tracer'" => sub {
    
    undef @test_params;
    
    local $ENV{OPENTRACING_IMPLEMENTATION} = '+MyTest::Default';
    
    lives_ok {
        my $tracer = OpenTracing::Implementation->bootstrap_global_default_tracer(
            qux => 4,
            qw/and much more/
        )
    } "Can call method 'bootstrap_global_default_tracer'";
    
    cmp_deeply(
        \@test_params => [
            [ 'MyTest::Default', 'qux', 4, 'and', 'much', 'more' ]
        ], "... and passes on the right params to 'MyTest::Default"
    );
    
};



subtest "pass on arguments for 'NoOp'" => sub {
    
    undef @test_params;
    
    lives_ok {
        my $tracer = OpenTracing::Implementation->bootstrap_default_tracer(
            tix => 5,
            qw/nothing/
        )
    } "Can call method 'bootstrap_global_tracer'";
    
    cmp_deeply(
        \@test_params => [
            [ 'OpenTracing::Implementation::NoOp', 'tix', 5, 'nothing' ]
        ], "... and passes on the right params to 'NoOp"
    );
    
};



done_testing();



package MyTest::Implementation;

sub bootstrap_tracer {
    push @main::test_params, [ @_ ];
    
    bless {}, 'MyStub::Tracer'
}

BEGIN {
    use Role::Tiny::With;
    with 'OpenTracing::Implementation::Interface::Bootstrap'
} # check at compile time, perl -c will work



package MyTest::Default;

sub bootstrap_tracer {
    push @main::test_params, [ @_ ];
    
    bless {}, 'MyStub::Tracer'
}

BEGIN {
    use Role::Tiny::With;
    with 'OpenTracing::Implementation::Interface::Bootstrap'
} # check at compile time, perl -c will work



package OpenTracing::Implementation::NoOp;

sub bootstrap_tracer {
    push @main::test_params, [ @_ ];
    
    bless {}, 'MyStub::Tracer'
}

BEGIN {
    use Role::Tiny::With;
    with 'OpenTracing::Implementation::Interface::Bootstrap'
} # check at compile time, perl -c will work



package MyStub::Tracer;


sub get_scope_manager { ... }
sub get_active_span { ... }
sub start_active_span { ... }
sub start_span { ... }
sub inject_context { ... }
sub extract_context { ... }

BEGIN {
    use Role::Tiny::With;
    with 'OpenTracing::Interface::Tracer'
} # check at compile time, perl -c will work
