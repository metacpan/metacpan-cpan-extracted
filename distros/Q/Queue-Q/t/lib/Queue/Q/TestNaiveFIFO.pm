package # Hide from PAUSE
    Queue::Q::TestNaiveFIFO;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

sub test_naive_fifo {
    my $q = shift;

    # clean up so the tests make sense
    $q->flush_queue;
    is($q->queue_length, 0, "Flushed queue has no items");

    $q->enqueue_item([$_]) for 1..2;
    is($q->queue_length, 2, "Queue len check 1");

    $q->enqueue_items(151..161);
    is($q->queue_length, 13, "Queue len check 2");

    my $item = $q->claim_item();
    is_deeply($item, [1], "Fetching one item");
    is($q->queue_length, 12, "Queue len check 3");

    $item = $q->claim_item();
    is_deeply($item, [2], "Fetching one item, 2");
    is($q->queue_length, 11, "Queue len check 4");

    my @items = $q->claim_items();
    is_deeply(\@items, [151], "Fetching one item via claim_items");
    is($q->queue_length, 10, "Queue len check 5");

    @items = $q->claim_items(3);
    is_deeply(\@items, [152..154], "Fetching three items via claim_items");
    is($q->queue_length, 7, "Queue len check 6");

    $q->enqueue_item({foo => "bar"});
    is($q->queue_length, 8, "Queue len check 7");

    @items = $q->claim_items(10);
    is_deeply(\@items, [155..161, {foo => "bar"}], "Fetching items via claim_items");
    is($q->queue_length, 0, "Queue len check 8");

    $item = $q->claim_item();
    ok(!defined($item), "Getting undef from claim_item after queue is exhausted")
        or diag(Dumper([$item]));

    $q->flush_queue;
    $item = $q->claim_item();
    ok(!defined($item), "Getting undef from claim_item after queue is exhausted (after full flush)")
        or diag(Dumper([$item]));

    is($q->queue_length, 0, "Queue len check 9");
}

1;
