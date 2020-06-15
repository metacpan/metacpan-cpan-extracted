use Test::Most;



subtest "Using accessors" => sub {
    
    my $test_span;
    
    lives_ok {
        $test_span = MyStub::Span->new(
            operation_name  => 'this name',
            context         => bless( {}, 'MyStub::SpanContext' ),
            child_of        => bless( {}, 'MyStub::SpanContext' ),
        );
    } "Created a Stub Span with required 'operation_name'"
    
    or return;
    
    dies_ok {
        $test_span->operation_name;
    } "... and does not allow for attribute access to retrieve the name";
    
    is $test_span->get_operation_name, 'this name',
        "... but does return the right name using the 'getter' method";
    
    dies_ok {
        $test_span->operation_name( 'that name' );
    } "... and does not allow for just updating the name";
    
    dies_ok {
        $test_span->set_operation_name( 'that name' );
    } "... and does not allow for just use a 'setter'";
    
};



subtest "Using 'overwrite_operation_name'" => sub {
    
    my $test_span;
    
    lives_ok {
        $test_span = MyStub::Span->new(
            operation_name  => 'this name',
            context         => bless( {}, 'MyStub::SpanContext' ),
            child_of        => bless( {}, 'MyStub::SpanContext' ),
        );
    } "Created a Stub Span"
    
    
    or return;
    
    lives_ok {
        $test_span->overwrite_operation_name( 'that name' );
    } "... and could call the right 'overwrite' method";
    
    is $test_span->get_operation_name, 'that name',
        "... and does return the right name";
    
};



done_testing();



package MyStub::Span;
use Moo;

BEGIN { with 'OpenTracing::Role::Span'; }



package MyStub::SpanContext;
use Moo;

BEGIN { with 'OpenTracing::Role::SpanContext'; }



1;
