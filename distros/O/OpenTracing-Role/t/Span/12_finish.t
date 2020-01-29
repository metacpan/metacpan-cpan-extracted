use Test::Most;


$ENV{OPENTRACING_INTERFACE} = 1 unless exists $ENV{OPENTRACING_INTERFACE};
#
# This breaks if it would be set to 0 externally, so, don't do that!!!


package MyTest::Span;

use Moo;

with 'OpenTracing::Role::Span';



package MyTest::SpanContext;

use Moo;

with 'OpenTracing::Role::SpanContext';



package main;

my $test_span_context = MyTest::SpanContext->new();

my $test_span;

my $start_time = time();


$test_span = MyTest::Span->new(
    operation_name => 'test',
    context        => $test_span_context,
    start_time     => 0,
);


$test_span->finish( );

# note, perl time works with integers, the Span object should work with floats
#
ok( between( $test_span->finish_time, $start_time, $start_time +1 ),
    "Span finished within 1 second"
);



done_testing();



sub between {
    return ($_[0] >= $_[1]) && ($_[0] <= $_[2])
}



1;
