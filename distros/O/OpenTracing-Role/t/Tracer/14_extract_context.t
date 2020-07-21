use Test::Most;
use Test::MockObject::Extends;



subtest 'from_array_reference' => sub {
    
    my $some_carrier = [];
    
    test_with_carrier( array_reference => $some_carrier );
    
};



subtest 'from_hash_reference' => sub {
    
    my $some_carrier = {};
    
    test_with_carrier( hash_reference => $some_carrier );
    
};



subtest 'from_http_headers' => sub {
    
    my $some_carrier = bless {},'HTTP::Headers';
    
    test_with_carrier( http_headers => $some_carrier );
    
};



done_testing();



sub test_with_carrier {
    my $test_name = shift;
    my $some_carrier = shift;
    
    my ( $call_name, $call_args, $mock_tracer, $result );
    
    my $mock_context = bless {}, 'MyStub::SpanContext';
    
    
    
    $mock_tracer  = mock_tracer( extracted_context => $mock_context );
    
    lives_ok {
        $result = $mock_tracer->extract_context( $some_carrier )
    } "Can call 'extract_context'"
    
    or return;
    
    
    ($call_name, $call_args) = $mock_tracer->next_call();
    
    is( $call_name, "extract_context_from_$test_name",
        "... and did pass on to correct code reference"
    )
    
    or return;
    
    
    cmp_deeply( $call_args =>
        [ $mock_tracer, $some_carrier ],
        "... and did pass on the expected arguments"
    );
    
    is $result, $mock_context,
        "... and did return a 'mocked' context";
    
    return
}





sub mock_tracer {
    my %opts = @_;
    
    my $context = delete $opts{extracted_context};
    
    my $mock_tracer = Test::MockObject::Extends->new(
        MyStub::Tracer->new(
            scope_manager => bless( {}, 'MyStub::ScopeManager'),
        )
    )->mock( 'extract_context_from_array_reference' =>
        sub { return $context }
    )->mock( 'extract_context_from_hash_reference' =>
        sub { return $context }
    )->mock( 'extract_context_from_http_headers' =>
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