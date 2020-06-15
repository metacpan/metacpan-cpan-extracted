use Test::Most;


$ENV{OPENTRACING_INTERFACE} = 1 unless exists $ENV{OPENTRACING_INTERFACE};
#
# This breaks if it would be set to 0 externally, so, don't do that!!!


package MyTest::ContextReference;

use Moo;

with 'OpenTracing::Role::ContextReference';



package MyTest::SpanContext;

use Moo;

with 'OpenTracing::Role::SpanContext';



package main;

my $test_span_context = MyTest::SpanContext->new();


subtest 'child_of' => sub {
    
    my $test_reference;
    
    lives_ok {
        $test_reference =
            MyTest::ContextReference->new_child_of( $test_span_context );
    } "Can create an object with 'new_child_of'";
    
    isa_ok $test_reference, 'MyTest::ContextReference';
    
    ok $test_reference->type_is_child_of,
        "... and is type 'child_of'";
    
    is $test_reference->get_referenced_context, $test_span_context,
        "... and the referenced context is as expected"
};



subtest 'follows_from' => sub {
    
    my $test_reference;
    
    lives_ok {
        $test_reference =
            MyTest::ContextReference->new_follows_from( $test_span_context );
    } "Can create an object with 'new_follows_from'";
    
    isa_ok $test_reference, 'MyTest::ContextReference';
    
    ok $test_reference->type_is_follows_from,
        "... and is type 'follows_from'";
    
    is $test_reference->get_referenced_context, $test_span_context,
        "... and the referenced context is as expected"
};



done_testing();
