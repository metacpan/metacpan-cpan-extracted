use Test::Most;
use Test::MockObject::Extends;



subtest 'into_array_reference' => sub {
    
    my $some_carrier = [];
    
    test_with_carrier( array_reference => $some_carrier );
    
};



subtest 'into_hash_reference' => sub {
    
    my $some_carrier = {};
    
    test_with_carrier( hash_reference => $some_carrier );
    
};



subtest 'into_http_headers' => sub {
    
    my $some_carrier = bless {},'HTTP::Headers';
    
    test_with_carrier( http_headers => $some_carrier );
    
};



done_testing();



sub test_with_carrier {
    my $test_name = shift;
    my $some_carrier = shift;
    
    my ( $call_name, $call_args, $mock_tracer, $result );
    
    my $mock_context = bless {}, 'MyStub::SpanContext';
    
    
    
    $mock_tracer  = mock_tracer( );
    
    lives_ok {
        $result = $mock_tracer->inject_context( $some_carrier, $mock_context )
    } "Can call 'inject_context'"
    
    or return;
    
    
    ($call_name, $call_args) = $mock_tracer->next_call();
    
    is( $call_name, "inject_context_into_$test_name",
        "... and did pass on to correct code reference"
    )
    
    or return;
    
    
    cmp_deeply( $call_args =>
        [ $mock_tracer, $some_carrier, $mock_context ],
        "... and did pass on the expected arguments"
    );
    
    isnt $result, $some_carrier,
        "... and did return a 'cloned' carrier";
    
    
    
    $mock_tracer  = mock_tracer( active_context => $mock_context );
    
    lives_ok {
        $result = $mock_tracer->inject_context( $some_carrier )
    } "Can call 'inject_context' without a context"
    
    or return;
    
    ($call_name, $call_args) = $mock_tracer->next_call();
    
    is( $call_name, 'get_active_context',
        "... but did try to retrieve an active context"
    );
    
    ($call_name, $call_args) = $mock_tracer->next_call();
    
    cmp_deeply( $call_args =>
        [ $mock_tracer, $some_carrier, $mock_context ],
        "... and did pass on the expected arguments"
    );
    
    isnt $result, $some_carrier,
        "... and did return a 'cloned' carrier";
    
    
    
    $mock_tracer  = mock_tracer( active_context => undef );
    
    lives_ok {
        $result = $mock_tracer->inject_context( $some_carrier )
    } "Can call 'inject_context' without an active context"
    
    or return;
        
    is $result, $some_carrier,
        "... and did return the unmodified carrier";
    
    return
}





sub mock_tracer {
    my %opts = @_;
    
    my $context = delete $opts{active_context};
    
    my $mock_tracer = Test::MockObject::Extends->new(
        MyStub::Tracer->new(
            scope_manager => bless( {}, 'MyStub::ScopeManager'),
        )
    )->mock( 'inject_context_into_array_reference' =>
        sub { [ foo => 1, bar => 2 ] }
    )->mock( 'inject_context_into_hash_reference' =>
        sub { { foo => 1, bar => 2 } }
    )->mock( 'inject_context_into_http_headers' =>
        sub { bless { foo => 1, bar => 2 }, "HTTP::Headers" }
    )->mock( 'get_active_context' =>
        sub { return $context }
    );
    
    return $mock_tracer
}


package MyStub::Tracer;
use Moo;

sub build_span                           { ... }
sub build_context                        { ... }
sub inject_context_into_array_reference  { ... }
sub extract_context_from_array_reference { ... }
sub inject_context_into_hash_reference   { ... }
sub extract_context_from_hash_reference  { ... }
sub inject_context_into_http_headers     { ... }
sub extract_context_from_http_headers    { ... }

BEGIN { with 'OpenTracing::Role::Tracer'; }



package MyStub::SpanContext;
use Moo;

BEGIN { with 'OpenTracing::Role::SpanContext'; }



package MyStub::ScopeManager;
use Moo;

sub build_scope { ... };

BEGIN { with 'OpenTracing::Role::ScopeManager'; }



1;