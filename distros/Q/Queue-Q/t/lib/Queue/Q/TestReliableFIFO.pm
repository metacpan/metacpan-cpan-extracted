package # Hide from PAUSE
    Queue::Q::TestReliableFIFO;
use strict;
use warnings;
use Test::More;

sub qlen_claimcount {
    my ($q, $qlen, $claimcount, $name) = @_;
    $name = defined($name) ? "($name)" : "";
    is($q->queue_length, $qlen, "Queue length is $qlen $name");
    is($q->queue_length('busy'), $claimcount, "Claimed count is $claimcount $name");
}

sub test_claim_fifo {
    my $q = shift;

    # clean up so the tests make sense
    $q->flush_queue;
    qlen_claimcount($q, 0, 0, "Flushed queue is empty");

    for (1..2) {
        my $n = $q->enqueue_item([$_]);
        is($n, $_, '$_ items in queue');
    }
    qlen_claimcount($q, 2, 0, "1");

    my $n = $q->enqueue_item(151..161);
    qlen_claimcount($q, 13, 0, "2");
    is($n, 13, '13 items in the queue');

    my $item = $q->claim_item();
    isa_ok($item, "Queue::Q::ReliableFIFO::Item");
    is_deeply($item->data, [1], "Fetching one item");
    qlen_claimcount($q, 12, 1, "3");
    $q->mark_item_as_done($item);
    qlen_claimcount($q, 12, 0, "4");

    $item = $q->claim_item_nonblocking(); # throw a nonblocking call into the mix
    isa_ok($item, "Queue::Q::ReliableFIFO::Item");
    is_deeply($item->data, [2], "Fetching one item, 2");
    qlen_claimcount($q, 11, 1, "5");

    my @items = $q->claim_item();
    is(scalar(@items), 1, "claim_item returns one item by default");
    is($items[0]->data, 151, "Fetching one item via claim_item");
    qlen_claimcount($q, 10, 2, "6");

    $q->mark_item_as_done($items[0]);
    qlen_claimcount($q, 10, 1, "7");
    $q->mark_item_as_done($item);
    qlen_claimcount($q, 10, 0, "8");

    @items = $q->claim_item(3);
    is(scalar(@items), 3);
    isa_ok($_, "Queue::Q::ReliableFIFO::Item") for @items;
    qlen_claimcount($q, 7, 3, "9");
    is_deeply([map $_->data, @items], [152..154], "Fetching three items via claim_item");

    $q->enqueue_item({foo => "bar"});
    qlen_claimcount($q, 8, 3, "10");

    my @items2 = $q->claim_item(10);
    is(scalar(@items2), 8);
    isa_ok($_, "Queue::Q::ReliableFIFO::Item") for @items2[0..7];
    ok(!defined($items2[$_]), "items2[$_]") for 8..9;
    qlen_claimcount($q, 0, 11, "11");

    is_deeply([map $_->data, @items2[0..7]], [155..161, {foo => "bar"}], "Fetching items via claim_item");

    $item = $q->claim_item();
    ok(!defined($item));
    qlen_claimcount($q, 0, 11, "12");

    $item = $q->claim_item_nonblocking();
    ok(!defined($item));
    qlen_claimcount($q, 0, 11, "13");

    my @items3 = $q->claim_item_nonblocking(5);
    ok(!@items3);
    qlen_claimcount($q, 0, 11, "14");

    @items3 = $q->claim_item_nonblocking(3500); # anything large
    ok(!@items3);
    qlen_claimcount($q, 0, 11, "15");


    $q->mark_item_as_done(grep defined, @items2);
    qlen_claimcount($q, 0, 3, "16");
    $q->mark_item_as_done($_) for reverse @items;
    qlen_claimcount($q, 0, 0, "17");

    $q->mark_item_as_done($items[0]);
    qlen_claimcount($q, 0, 0, "18");
}

1;
