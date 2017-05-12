package # Hide from PAUSE
    Queue::Q::TestClaimFIFO;
use strict;
use warnings;
use Test::More;

sub qlen_claimcount {
    my ($q, $qlen, $claimcount, $name) = @_;
    $name = defined($name) ? "($name)" : "";
    is($q->queue_length, $qlen, "Queue length is $qlen $name");
    is($q->claimed_count, $claimcount, "Claimed count is $claimcount $name");
}

sub test_claim_fifo {
    my $q = shift;

    # clean up so the tests make sense
    $q->flush_queue;
    qlen_claimcount($q, 0, 0, "Flushed queue is empty");

    for (1..2) {
        my $item = $q->enqueue_item([$_]);
        isa_ok($item, "Queue::Q::ClaimFIFO::Item");
    }
    qlen_claimcount($q, 2, 0, "1");

    my @x = $q->enqueue_items(151..161);
    qlen_claimcount($q, 13, 0, "2");
    isa_ok($_, "Queue::Q::ClaimFIFO::Item") for @x;
    @x = ();

    my $item = $q->claim_item();
    isa_ok($item, "Queue::Q::ClaimFIFO::Item");
    is_deeply($item->data, [1], "Fetching one item");
    qlen_claimcount($q, 12, 1, "3");
    $q->mark_item_as_done($item);
    qlen_claimcount($q, 12, 0, "4");

    $item = $q->claim_item();
    isa_ok($item, "Queue::Q::ClaimFIFO::Item");
    is_deeply($item->data, [2], "Fetching one item, 2");
    qlen_claimcount($q, 11, 1, "5");

    my @items = $q->claim_items();
    is(scalar(@items), 1, "claim_items returns one item by default");
    is($items[0]->data, 151, "Fetching one item via claim_items");
    qlen_claimcount($q, 10, 2, "6");

    $q->mark_item_as_done($items[0]);
    qlen_claimcount($q, 10, 1, "7");
    $q->mark_item_as_done($item);
    qlen_claimcount($q, 10, 0, "8");

    @items = $q->claim_items(3);
    is(scalar(@items), 3);
    isa_ok($_, "Queue::Q::ClaimFIFO::Item") for @items;
    qlen_claimcount($q, 7, 3, "9");
    is_deeply([map $_->data, @items], [152..154], "Fetching three items via claim_items");

    $q->enqueue_item({foo => "bar"});
    qlen_claimcount($q, 8, 3, "10");

    my @items2 = $q->claim_items(10);
    is(scalar(@items2), 8);
    isa_ok($_, "Queue::Q::ClaimFIFO::Item") for @items2[0..7];
    ok(!defined($items2[$_]), "items2[$_]") for 8..9;
    qlen_claimcount($q, 0, 11, "11");

    is_deeply([map $_->data, @items2[0..7]], [155..161, {foo => "bar"}], "Fetching items via claim_items");


    $item = $q->claim_item();
    ok(!defined($item));
    qlen_claimcount($q, 0, 11, "12");

    $q->mark_items_as_done(grep defined, @items2);
    qlen_claimcount($q, 0, 3, "13");
    $q->mark_item_as_done($_) for reverse @items;
    qlen_claimcount($q, 0, 0, "14");

    $q->mark_item_as_done($items[0]);
    qlen_claimcount($q, 0, 0, "15");
}

1;
