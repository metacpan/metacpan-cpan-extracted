use Test::Most;



subtest "Call bogus 'log_data'" => sub {
    
    my $test_span;
    
    lives_ok {
        $test_span = MyStub::Span->new(
            operation_name  => 'test',
            context         => bless( {}, 'MyStub::SpanContext' ),
            child_of        => bless( {}, 'MyStub::SpanContext' ),
        );
    } "Created a Stub Span"
    
    or return;
    
    lives_ok {
        $test_span->log_data(
            log_1 => 'foo',
            log_2 => 'bar',
        );
    } "... and is fine doiong a 'log_data' call, what ever that does"
    
};



done_testing();



package MyStub::Span;
use Moo;

BEGIN { with 'OpenTracing::Role::Span'; }



package MyStub::SpanContext;
use Moo;

BEGIN { with 'OpenTracing::Role::SpanContext'; }



1;
