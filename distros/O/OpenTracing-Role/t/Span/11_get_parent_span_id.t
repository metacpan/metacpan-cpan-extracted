use Test::Most;


$ENV{OPENTRACING_INTERFACE} = 1 unless exists $ENV{OPENTRACING_INTERFACE};
#
# This breaks if it would be set to 0 externally, so, don't do that!!!



subtest "Test without 'child_of'" => sub {
    
    my $this_context = MyStub::SpanContext
        ->new
        ->with_span_id('1e43f');
    
    my $test_span;
    
    lives_ok {
        $test_span = MyStub::Span->new(
            operation_name => 'child_of_none',
            context        => $this_context,
        );
    } "Created a new span, without a 'child_of'"
    
    or return;
    
    is $test_span->get_span_id, '1e43f',
        "... and 'span_id' is from the required context";
    
    is $test_span->get_parent_span_id, undef,
        "... and there is no 'parent_span_id'";
};



subtest "Test with 'child_of' a 'SpanContext'" => sub {
    
    my $some_context = MyStub::SpanContext
        ->new
        ->with_span_id('1e43f');
    
    my $this_context = $some_context
        ->new_clone
        ->with_span_id('45ed0');
    
    my $test_span;
    
    lives_ok {
        $test_span = MyStub::Span->new(
            operation_name => 'child_of_span_context',
            context        => $this_context,
            child_of       => $some_context,
        );
    } "Created a new span, with a 'child_of' 'span_contex'"
    
    or return;
    
    is $test_span->get_span_id, '45ed0',
        "... and 'span_id' is from the required context";
    
    is $test_span->get_parent_span_id, '1e43f',
        "... and there is no 'parent_span_id'";
};



subtest "Test with 'child_of' a 'Span'" => sub {
    
    my $some_context = MyStub::SpanContext->new
        ->with_span_id('1e43f');
    
    my $some_span = MyStub::Span->new(
        operation_name => 'some_span', 
        context        => $some_context
    );
    
    my $this_context = $some_span
        ->get_context
        ->new_clone
        ->with_span_id('45ed0');
    
    my $test_span;
    
    lives_ok {
        $test_span = MyStub::Span->new(
            operation_name => 'child_of_span',
            context        => $this_context,
            child_of       => $some_span,
        );
    } "Created a new span, with a 'child_of' 'span_contex'"
    
    or return;
    
    is $test_span->get_span_id, '45ed0',
        "... and 'span_id' is from the required context";
    
    is $test_span->get_parent_span_id, '1e43f',
        "... and there is no 'parent_span_id'";
};



done_testing();



package MyStub::Span;
use Moo;

BEGIN { with 'OpenTracing::Role::Span' }



package MyStub::SpanContext;
use Moo;

BEGIN { with 'OpenTracing::Role::SpanContext' }



1;
