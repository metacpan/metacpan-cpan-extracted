use Test::Most;


$ENV{OPENTRACING_INTERFACE} = 1 unless exists $ENV{OPENTRACING_INTERFACE};
#
# This breaks if it would be set to 0 externally, so, don't do that!!!



use Test::Time::HiRes;



subtest "Test with 'current time'" => sub {
    
    Test::Time::HiRes->set_time( 256.875 );
    
    my $test_span = bless {}, 'MyStub::Span';
    
    throws_ok {
        $test_span->duration
    } qr/Span has not been started: \[.*\] \.\.\. how did you do that \?/,
        "Just showed you how to do that!";
    
    lives_ok {
        $test_span = MyStub::Span->new(
            operation_name => 'test',
            context        => bless( {}, 'MyStub::SpanContext' ),
            child_of       => bless( {}, 'MyStub::Span' ),
        );
    } "Created a Span with the 'current' start time"
        or return;
    
    is $test_span->start_time +0, 256.875,
        "... and started at the current time";
    
    throws_ok {
        $test_span->duration
    } qr/Span has not been finished: \[.*\] \.\.\. yet!/,
        "... and will not compute a duration if Span hasn't been finished yet";
    
    sleep( 512.750 );
    
    ok $test_span->finish->has_finished,
        "... and have now finished the Span";
    
    is $test_span->finish_time +0, 769.625,
        "... at the 'current time'";
    
    is $test_span->duration , 512.750,
        "... and the duration was as expected";
    
};



subtest "Test with 'explicit time'" => sub {
    
    Test::Time::HiRes->set_time( 128.250 );
    
    is MyStub::Span->new(
        operation_name => 'test',
        context        => bless( {}, 'MyStub::SpanContext' ),
        child_of       => bless( {}, 'MyStub::Span' ),
    )->finish(256.750)->duration, 128.500,
        "Did a quick chained reaction";
    
};



done_testing();



package MyStub::Span;

use Moo;

BEGIN { with 'OpenTracing::Role::Span' }



package MyStub::SpanContext;

use Moo;

BEGIN { with 'OpenTracing::Role::SpanContext' }



1;
