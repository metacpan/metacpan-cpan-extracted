package # Hide from PAUSE
    Queue::Q::TestDistFIFO;
use strict;
use warnings;
use Test::More;


sub test_dist_fifo {
    my $q = shift;

    # clean up so the tests make sense
    $q->flush_queue;
    is($q->queue_length, 0, "Flushed queue has no items");

    $q->enqueue_item($_) for 1..2;
    is($q->queue_length, 2, "Queue len check 1");

    my @items;
    push @items, $q->claim_item;
    is($q->queue_length, 1, "Queue len check 3");

    push @items, $q->claim_item();
    is($q->queue_length, 0, "Queue len check 4");

    $q->enqueue_items(151..161);
    is($q->queue_length, 11, "Queue len check 2");

    @items = sort {$a <=> $b} @items; 
    is(scalar(@items), 2);
    is($items[0], 1, "Fetched one item [1]");
    is($items[1], 2, "Fetched one item [2]");

    @items = $q->claim_items();
    is($q->queue_length, 10, "Queue len check 5");

    push @items, $q->claim_items(3);
    is($q->queue_length, 7, "Queue len check 6");

    push @items, grep defined, $q->claim_items(15);
    is($q->queue_length, 0, "Queue len check 7");
    @items = sort {$a <=> $b} @items;
    is_deeply(\@items, [151..161]);

    my @set1 = (1..10);
    my @set2 = (11..20);
    my @set3 = (21..30);

    $q->enqueue_items_strict_ordering(@set1);
    $q->enqueue_items_strict_ordering(@set2);
    $q->enqueue_items_strict_ordering(@set3);

    for (1..30) {
        my $item = $q->claim_item();
        for my $s (\@set1, \@set2, \@set3) {
            if (@$s and $s->[0] == $item) {
                pass("Strict ordering checks: $_");
                $item = undef;
                shift @$s;
                last;
            }
        }
        if (defined $item) {
            fail("Strict ordering checks: $_");
        }
    }

    $q->enqueue_items(1..100);
    is($q->queue_length, 100, "Queue len check 8");
    $q->flush_queue;
    is($q->queue_length, 0, "Queue len check 8");
}

sub qlen_claimcount {
    my ($q, $qlen, $claimcount, $name) = @_;
    $name = defined($name) ? "($name)" : "";
    is($q->queue_length, $qlen, "Queue length is $qlen $name");
    is($q->claimed_count, $claimcount, "Claimed count is $claimcount $name");
}

sub test_dist_fifo_claim {
    my $q = shift;

    # clean up so the tests make sense
    $q->flush_queue;
    qlen_claimcount($q, 0, 0, "Flushed queue has no items");

    $q->enqueue_item($_) for 1..2;
    qlen_claimcount($q, 2, 0, "1");

    my @items;
    push @items, $q->claim_item;
    qlen_claimcount($q, 1, 1, "2");

    push @items, $q->claim_item();
    qlen_claimcount($q, 0, 2, "3");

    $q->enqueue_items($_) for 151..161;
    qlen_claimcount($q, 11, 2, "4");

    @items = sort {$a->data <=> $b->data} @items;
    is(scalar(@items), 2);
    is($items[0]->data, 1, "Fetched one item [1]");
    is($items[1]->data, 2, "Fetched one item [2]");
    $q->mark_item_as_done($_) for @items;
    qlen_claimcount($q, 11, 0, "5");

    @items = $q->claim_items();
    qlen_claimcount($q, 10, 1, "6");

    push @items, $q->claim_items(3);
    qlen_claimcount($q, 7, 4, "7");
    push @items, grep defined, $q->claim_items(15);
    qlen_claimcount($q, 0, 11, "8");

    @items = sort {$a->data <=> $b->data} @items;
    is_deeply([map $_->data, @items], [151..161]);

    $q->mark_items_as_done(@items);
    qlen_claimcount($q, 0, 0, "9");

    my @set1 = (1..10);
    my @set2 = (11..20);
    my @set3 = (21..30);

    $q->enqueue_items_strict_ordering(@set1);
    $q->enqueue_items_strict_ordering(@set2);
    $q->enqueue_items_strict_ordering(@set3);

    for (1..30) {
        my $item = $q->claim_item();
        for my $s (\@set1, \@set2, \@set3) {
            if (@$s and $s->[0] == $item->data) {
                pass("Strict ordering checks: $_");
                $q->mark_item_as_done($item);
                $item = undef;
                shift @$s;
                last;
            }
        }
        if (defined $item) {
            fail("Strict ordering checks: $_");
        }
    }

    $q->enqueue_items(1..100);
    is($q->queue_length, 100, "Queue len check 8");
    $q->flush_queue;
    is($q->queue_length, 0, "Queue len check 8");
}


1;
