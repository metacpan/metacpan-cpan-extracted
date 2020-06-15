use Test::Most;


$ENV{OPENTRACING_INTERFACE} = 1 unless exists $ENV{OPENTRACING_INTERFACE};
#
# This breaks if it would be set to 0 externally, so, don't do that!!!


use Test::Time::HiRes time => 256.875;

my $test_span;

lives_ok {
    $test_span = MyStub::Span->new(
        operation_name => 'test',
        context        => bless( {}, 'MyStub::SpanContext' ),
        child_of       => bless( {}, 'MyStub::Span' ),
    );
} "Can create new 'Span'";

is $test_span->start_time +0, 256.875,      # Test::Time::HiRes returns a string
    "... and has the correct start_time";

done_testing();



package MyStub::Span;

use Moo;

BEGIN { with 'OpenTracing::Role::Span' }



package MyStub::SpanContext;

use Moo;

BEGIN {with 'OpenTracing::Role::SpanContext' }



1;
