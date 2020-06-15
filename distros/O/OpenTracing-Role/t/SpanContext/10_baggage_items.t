use Test::Most;



subtest "A single baggage_item" => sub {
    
    my $span_context_1;
    my $span_context_2;
    
    lives_ok {
        $span_context_1 = MyStub::SpanContext->new(
            baggage_items => {
                item_1 => 'foo',
            },
        );
    } "Instantiated a SpanContext [1]";
    
    is $span_context_1->get_baggage_item( 'item_1' ), 'foo',
        "... that has the given 'baggage_item'";
    
    lives_ok {
        $span_context_2 = $span_context_1->with_baggage_item(
            item_2 => 'bar',
        );
    } "Got a SpanContext [2]";
    
    isnt $span_context_1, $span_context_2,
        "... that is not the same object reference as the original";
    
    is $span_context_1->trace_id, $span_context_2->trace_id,
        "... but has still the same 'trace_id'";
    
    is $span_context_1->get_baggage_item( 'item_2' ), undef,
        "... and SpanContext [1] has not new 'baggage_item' [item_2]";
    
    is $span_context_2->get_baggage_item( 'item_1' ), 'foo',
        "... and SpanContext [2] has the old 'baggage_item' [item_1]";
    
    is $span_context_2->get_baggage_item( 'item_2' ), 'bar',
        "... and SpanContext [2] has the new 'baggage_item' [item_2]";
    
};



subtest "Multiple baggage_items" => sub {
    
    my $span_context_1;
    my $span_context_2;
    
    lives_ok {
        $span_context_1 = MyStub::SpanContext->new(
            baggage_items => {
                item_1 => 'foo',
                item_2 => 'bar',
            },
        );
    } "Instantiated a SpanContext [1]";
    
    cmp_deeply(
        {
            $span_context_1->get_baggage_items
        },
        {
            item_1 => 'foo',
            item_2 => 'bar',
        },
        "... that has the given 'baggage_item's"
    );
    
    lives_ok {
        $span_context_2 = $span_context_1->with_baggage_items(
            item_2 => 'qux',
            item_3 => 'baz',
        );
    } "Got a SpanContext [2]";
    
    isnt $span_context_1, $span_context_2,
        "... that is not the same object reference as the original";
    
    cmp_deeply(
        {
            $span_context_1->get_baggage_items
        },
        {
            item_1 => 'foo',
            item_2 => 'bar',
        },
        "... and SpanContext [1] has the old 'baggage_item's"
    );
    
    cmp_deeply(
        {
            $span_context_2->get_baggage_items
        },
        {
            item_1 => 'foo',
            item_2 => 'qux',
            item_3 => 'baz',
        },
        "... and SpanContext [2] has the new 'baggage_item's"
    );
    
};



done_testing();



package MyStub::SpanContext;
use Moo;

BEGIN { with 'OpenTracing::Role::SpanContext'; }



1;
