#!/usr/bin/perl

use strictures 2;

use Test2::V0 -no_srand => 1;

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Event;
use Net::Nostr::Filter;
use Net::Nostr::RelayStore;

my $PK1 = 'a' x 64;
my $PK2 = 'b' x 64;
my $PK3 = 'c' x 64;

###############################################################################
# Construction
###############################################################################

subtest 'new() creates empty store' => sub {
    my $store = Net::Nostr::RelayStore->new;
    is $store->event_count, 0, 'empty store has 0 events';
    is $store->all_events, [], 'all_events returns empty arrayref';
};

subtest 'new() accepts max_events' => sub {
    my $store = Net::Nostr::RelayStore->new(max_events => 100);
    is $store->max_events, 100, 'max_events preserved';
};

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::RelayStore->new(bogus => 1) },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

subtest 'new() rejects non-positive max_events' => sub {
    like(
        dies { Net::Nostr::RelayStore->new(max_events => 0) },
        qr/max_events must be a positive integer/,
        'zero rejected'
    );
    like(
        dies { Net::Nostr::RelayStore->new(max_events => -1) },
        qr/max_events must be a positive integer/,
        'negative rejected'
    );
    like(
        dies { Net::Nostr::RelayStore->new(max_events => 'abc') },
        qr/max_events must be a positive integer/,
        'non-numeric rejected'
    );
};

###############################################################################
# store / get_by_id / duplicate detection
###############################################################################

subtest 'store and get_by_id' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e = make_event(kind => 1, content => 'hello', created_at => 1000);

    is $store->store($e), 1, 'store returns 1 on success';
    is $store->event_count, 1, 'event_count is 1';

    my $got = $store->get_by_id($e->id);
    ok defined $got, 'get_by_id returns the event';
    is $got->id, $e->id, 'same event id';
    is $got->content, 'hello', 'same content';
};

subtest 'get_by_id returns undef for unknown id' => sub {
    my $store = Net::Nostr::RelayStore->new;
    is $store->get_by_id('f' x 64), undef, 'unknown id returns undef';
};

subtest 'store rejects duplicates' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e = make_event(kind => 1, content => 'hello', created_at => 1000);

    is $store->store($e), 1, 'first store succeeds';
    is $store->store($e), 0, 'duplicate returns 0';
    is $store->event_count, 1, 'still only 1 event';
};

###############################################################################
# find_replaceable / find_addressable
###############################################################################

subtest 'find_replaceable' => sub {
    my $store = Net::Nostr::RelayStore->new;

    # kind 0 is replaceable
    my $e = make_event(pubkey => $PK1, kind => 0, content => 'profile', created_at => 1000);
    $store->store($e);

    my $found = $store->find_replaceable($PK1, 0);
    ok defined $found, 'found replaceable event';
    is $found->id, $e->id, 'correct event';

    is $store->find_replaceable($PK2, 0), undef, 'different pubkey not found';
    is $store->find_replaceable($PK1, 3), undef, 'different kind not found';
};

subtest 'find_addressable' => sub {
    my $store = Net::Nostr::RelayStore->new;

    # kind 30023 is addressable
    my $e = make_event(
        pubkey => $PK1, kind => 30023, content => 'article',
        created_at => 1000, tags => [['d', 'my-article']],
    );
    $store->store($e);

    my $found = $store->find_addressable($PK1, 30023, 'my-article');
    ok defined $found, 'found addressable event';
    is $found->id, $e->id, 'correct event';

    is $store->find_addressable($PK1, 30023, 'other'), undef, 'different d_tag not found';
    is $store->find_addressable($PK2, 30023, 'my-article'), undef, 'different pubkey not found';
};

###############################################################################
# delete_by_id
###############################################################################

subtest 'delete_by_id removes event from all indexes' => sub {
    my $store = Net::Nostr::RelayStore->new;

    my $e = make_event(
        pubkey => $PK1, kind => 1, content => 'deleteme',
        created_at => 1000, tags => [['t', 'nostr']],
    );
    $store->store($e);
    is $store->event_count, 1, 'stored';

    my $removed = $store->delete_by_id($e->id);
    ok defined $removed, 'delete returns removed event';
    is $removed->id, $e->id, 'correct event returned';
    is $store->event_count, 0, 'event_count is 0';
    is $store->get_by_id($e->id), undef, 'gone from by_id';
    is $store->all_events, [], 'gone from ordered list';

    # query should find nothing
    my $results = $store->query([Net::Nostr::Filter->new(kinds => [1])]);
    is $results, [], 'gone from kind index';

    $results = $store->query([Net::Nostr::Filter->new(authors => [$PK1])]);
    is $results, [], 'gone from author index';

    $results = $store->query([Net::Nostr::Filter->new('#t' => ['nostr'])]);
    is $results, [], 'gone from tag index';
};

subtest 'delete_by_id returns undef for unknown id' => sub {
    my $store = Net::Nostr::RelayStore->new;
    is $store->delete_by_id('f' x 64), undef, 'unknown id returns undef';
};

subtest 'delete_by_id cleans replaceable index' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e = make_event(pubkey => $PK1, kind => 0, content => 'profile', created_at => 1000);
    $store->store($e);
    $store->delete_by_id($e->id);
    is $store->find_replaceable($PK1, 0), undef, 'replaceable index cleaned';
};

subtest 'delete_by_id cleans addressable index' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e = make_event(
        pubkey => $PK1, kind => 30023, content => '',
        created_at => 1000, tags => [['d', 'slug']],
    );
    $store->store($e);
    $store->delete_by_id($e->id);
    is $store->find_addressable($PK1, 30023, 'slug'), undef, 'addressable index cleaned';
};

###############################################################################
# delete_matching (NIP-09)
###############################################################################

subtest 'delete_matching by event id' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e1 = make_event(pubkey => $PK1, kind => 1, content => 'keep', created_at => 1000);
    my $e2 = make_event(pubkey => $PK1, kind => 1, content => 'delete', created_at => 2000);
    $store->store($e1);
    $store->store($e2);

    my $count = $store->delete_matching($PK1, [$e2->id], [], 9999);
    is $count, 1, 'deleted 1 event';
    is $store->event_count, 1, '1 event remains';
    ok defined $store->get_by_id($e1->id), 'kept event still there';
    is $store->get_by_id($e2->id), undef, 'deleted event gone';
};

subtest 'delete_matching by address' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e = make_event(
        pubkey => $PK1, kind => 30023, content => '',
        created_at => 1000, tags => [['d', 'slug']],
    );
    $store->store($e);

    my $addr = "30023:$PK1:slug";
    my $count = $store->delete_matching($PK1, [], [$addr], 2000);
    is $count, 1, 'deleted by address';
    is $store->event_count, 0, 'store empty';
};

subtest 'delete_matching respects before_ts for addresses' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e = make_event(
        pubkey => $PK1, kind => 30023, content => '',
        created_at => 5000, tags => [['d', 'slug']],
    );
    $store->store($e);

    my $addr = "30023:$PK1:slug";
    # deletion timestamp is before the event — should NOT delete
    my $count = $store->delete_matching($PK1, [], [$addr], 3000);
    is $count, 0, 'not deleted (event newer than deletion)';
    is $store->event_count, 1, 'event still there';
};

subtest 'delete_matching skips kind 5 events' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $del_event = make_event(
        pubkey => $PK1, kind => 5, content => '',
        created_at => 1000, tags => [],
    );
    $store->store($del_event);

    my $count = $store->delete_matching($PK1, [$del_event->id], [], 9999);
    is $count, 0, 'kind 5 not deleted';
    is $store->event_count, 1, 'deletion event preserved';
};

subtest 'delete_matching ignores wrong pubkey' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e = make_event(pubkey => $PK1, kind => 1, content => 'mine', created_at => 1000);
    $store->store($e);

    my $count = $store->delete_matching($PK2, [$e->id], [], 9999);
    is $count, 0, 'cannot delete another pubkey\'s event';
    is $store->event_count, 1, 'event preserved';
};

###############################################################################
# query
###############################################################################

subtest 'query with empty store' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $results = $store->query([Net::Nostr::Filter->new(kinds => [1])]);
    is $results, [], 'empty result';
};

subtest 'query with empty filter matches all' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e1 = make_event(kind => 1, content => 'a', created_at => 1000);
    my $e2 = make_event(kind => 2, content => 'b', created_at => 2000);
    $store->store($e1);
    $store->store($e2);

    my $results = $store->query([Net::Nostr::Filter->new]);
    is scalar @$results, 2, 'empty filter returns all events';
};

subtest 'query by kind' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e1 = make_event(kind => 1, content => 'a', created_at => 1000);
    my $e2 = make_event(kind => 7, content => 'b', created_at => 2000);
    $store->store($e1);
    $store->store($e2);

    my $results = $store->query([Net::Nostr::Filter->new(kinds => [1])]);
    is scalar @$results, 1, '1 match';
    is $results->[0]->kind, 1, 'correct kind';
};

subtest 'query by author' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e1 = make_event(pubkey => $PK1, kind => 1, content => 'a', created_at => 1000);
    my $e2 = make_event(pubkey => $PK2, kind => 1, content => 'b', created_at => 2000);
    $store->store($e1);
    $store->store($e2);

    my $results = $store->query([Net::Nostr::Filter->new(authors => [$PK1])]);
    is scalar @$results, 1, '1 match';
    is $results->[0]->pubkey, $PK1, 'correct author';
};

subtest 'query by id' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e1 = make_event(kind => 1, content => 'a', created_at => 1000);
    my $e2 = make_event(kind => 1, content => 'b', created_at => 2000);
    $store->store($e1);
    $store->store($e2);

    my $results = $store->query([Net::Nostr::Filter->new(ids => [$e1->id])]);
    is scalar @$results, 1, '1 match';
    is $results->[0]->id, $e1->id, 'correct id';
};

subtest 'query by tag filter' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e1 = make_event(kind => 1, content => 'a', created_at => 1000, tags => [['t', 'nostr']]);
    my $e2 = make_event(kind => 1, content => 'b', created_at => 2000, tags => [['t', 'bitcoin']]);
    $store->store($e1);
    $store->store($e2);

    my $results = $store->query([Net::Nostr::Filter->new('#t' => ['nostr'])]);
    is scalar @$results, 1, '1 match';
    is $results->[0]->content, 'a', 'correct event';
};

subtest 'query sort order: created_at DESC, id ASC' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e1 = make_event(kind => 1, content => 'oldest', created_at => 1000);
    my $e2 = make_event(kind => 1, content => 'middle', created_at => 2000);
    my $e3 = make_event(kind => 1, content => 'newest', created_at => 3000);
    $store->store($e1);
    $store->store($e3);
    $store->store($e2);

    my $results = $store->query([Net::Nostr::Filter->new(kinds => [1])]);
    is scalar @$results, 3, '3 results';
    is $results->[0]->content, 'newest', 'newest first';
    is $results->[2]->content, 'oldest', 'oldest last';
};

subtest 'query per-filter limit' => sub {
    my $store = Net::Nostr::RelayStore->new;
    for my $i (1..5) {
        $store->store(make_event(kind => 1, content => "e$i", created_at => $i * 1000));
    }

    my $results = $store->query([Net::Nostr::Filter->new(kinds => [1], limit => 2)]);
    is scalar @$results, 2, 'limited to 2';
    # newest first due to sort order
    is $results->[0]->content, 'e5', 'newest first';
    is $results->[1]->content, 'e4', 'second newest';
};

subtest 'query multiple filters deduplicates' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e = make_event(pubkey => $PK1, kind => 1, content => 'x', created_at => 1000);
    $store->store($e);

    # both filters match the same event
    my $results = $store->query([
        Net::Nostr::Filter->new(kinds => [1]),
        Net::Nostr::Filter->new(authors => [$PK1]),
    ]);
    is scalar @$results, 1, 'deduplicated across filters';
};

subtest 'query skips expired events' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $expired = make_event(
        kind => 1, content => 'expired', created_at => 1000,
        tags => [['expiration', '1']],  # expired long ago
    );
    my $fresh = make_event(kind => 1, content => 'fresh', created_at => 2000);
    $store->store($expired);
    $store->store($fresh);

    my $results = $store->query([Net::Nostr::Filter->new(kinds => [1])]);
    is scalar @$results, 1, 'only fresh event returned';
    is $results->[0]->content, 'fresh', 'correct event';
};

subtest 'query with since/until' => sub {
    my $store = Net::Nostr::RelayStore->new;
    for my $i (1..5) {
        $store->store(make_event(kind => 1, content => "e$i", created_at => $i * 1000));
    }

    my $results = $store->query([Net::Nostr::Filter->new(since => 2000, until => 4000)]);
    is scalar @$results, 3, 'events in range (inclusive)';
};

###############################################################################
# count
###############################################################################

subtest 'count matches' => sub {
    my $store = Net::Nostr::RelayStore->new;
    for my $i (1..5) {
        $store->store(make_event(kind => 1, content => "e$i", created_at => $i * 1000));
    }
    $store->store(make_event(kind => 7, content => 'reaction', created_at => 6000));

    is $store->count([Net::Nostr::Filter->new(kinds => [1])]), 5, 'count kind 1';
    is $store->count([Net::Nostr::Filter->new(kinds => [7])]), 1, 'count kind 7';
    is $store->count([Net::Nostr::Filter->new]), 6, 'count all';
};

subtest 'count skips expired' => sub {
    my $store = Net::Nostr::RelayStore->new;
    $store->store(make_event(
        kind => 1, content => 'expired', created_at => 1000,
        tags => [['expiration', '1']],
    ));
    $store->store(make_event(kind => 1, content => 'fresh', created_at => 2000));

    is $store->count([Net::Nostr::Filter->new(kinds => [1])]), 1, 'expired not counted';
};

subtest 'count deduplicates across filters' => sub {
    my $store = Net::Nostr::RelayStore->new;
    $store->store(make_event(pubkey => $PK1, kind => 1, content => 'x', created_at => 1000));

    is $store->count([
        Net::Nostr::Filter->new(kinds => [1]),
        Net::Nostr::Filter->new(authors => [$PK1]),
    ]), 1, 'counted once despite matching both filters';
};

###############################################################################
# all_events / event_count / clear
###############################################################################

subtest 'all_events returns snapshot in sort order' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e1 = make_event(kind => 1, content => 'old', created_at => 1000);
    my $e2 = make_event(kind => 1, content => 'new', created_at => 2000);
    $store->store($e1);
    $store->store($e2);

    my $all = $store->all_events;
    is scalar @$all, 2, '2 events';
    is $all->[0]->content, 'new', 'newest first';
    is $all->[1]->content, 'old', 'oldest last';

    # verify it's a copy, not a live reference
    push @$all, 'garbage';
    is $store->event_count, 2, 'store not affected by mutation';
};

subtest 'clear empties everything' => sub {
    my $store = Net::Nostr::RelayStore->new;
    $store->store(make_event(kind => 1, content => 'a', created_at => 1000));
    $store->store(make_event(kind => 1, content => 'b', created_at => 2000));
    is $store->event_count, 2, 'pre-clear';

    $store->clear;
    is $store->event_count, 0, 'post-clear count is 0';
    is $store->all_events, [], 'post-clear all_events is empty';
};

###############################################################################
# max_events eviction
###############################################################################

subtest 'max_events evicts oldest when exceeded' => sub {
    my $store = Net::Nostr::RelayStore->new(max_events => 3);

    for my $i (1..3) {
        $store->store(make_event(kind => 1, content => "e$i", created_at => $i * 1000));
    }
    is $store->event_count, 3, 'at capacity';

    # store a 4th event (newest)
    my $e4 = make_event(kind => 1, content => 'e4', created_at => 4000);
    $store->store($e4);

    is $store->event_count, 3, 'still at capacity after eviction';

    my $all = $store->all_events;
    my @contents = map { $_->content } @$all;
    is \@contents, ['e4', 'e3', 'e2'], 'oldest (e1) was evicted';

    # evicted event is gone from all lookups
    my $results = $store->query([Net::Nostr::Filter->new(since => 1000, until => 1000)]);
    is $results, [], 'evicted event not found by query';
};

subtest 'max_events eviction cleans all indexes' => sub {
    my $store = Net::Nostr::RelayStore->new(max_events => 1);

    my $e1 = make_event(
        pubkey => $PK1, kind => 1, content => 'first', created_at => 1000,
        tags => [['t', 'test']],
    );
    $store->store($e1);
    my $evicted_id = $e1->id;

    my $e2 = make_event(
        pubkey => $PK2, kind => 1, content => 'second', created_at => 2000,
        tags => [['t', 'other']],
    );
    $store->store($e2);

    is $store->get_by_id($evicted_id), undef, 'evicted from id index';
    my $results = $store->query([Net::Nostr::Filter->new(authors => [$PK1])]);
    is $results, [], 'evicted from author index';
    $results = $store->query([Net::Nostr::Filter->new('#t' => ['test'])]);
    is $results, [], 'evicted from tag index';
};

###############################################################################
# query: authors + kinds intersection path
###############################################################################

subtest 'query by authors + kinds uses intersection' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e1 = make_event(pubkey => $PK1, kind => 1, content => 'pk1-k1', created_at => 1000);
    my $e2 = make_event(pubkey => $PK1, kind => 7, content => 'pk1-k7', created_at => 2000);
    my $e3 = make_event(pubkey => $PK2, kind => 1, content => 'pk2-k1', created_at => 3000);
    my $e4 = make_event(pubkey => $PK2, kind => 7, content => 'pk2-k7', created_at => 4000);
    $store->store($_) for ($e1, $e2, $e3, $e4);

    my $results = $store->query([Net::Nostr::Filter->new(authors => [$PK1], kinds => [1])]);
    is scalar @$results, 1, 'intersection returns 1 match';
    is $results->[0]->content, 'pk1-k1', 'correct event from intersection';

    # multiple authors, multiple kinds
    $results = $store->query([Net::Nostr::Filter->new(authors => [$PK1, $PK2], kinds => [7])]);
    is scalar @$results, 2, '2 matches for both authors, kind 7';
    is $results->[0]->content, 'pk2-k7', 'newest first';
    is $results->[1]->content, 'pk1-k7', 'second newest';
};

###############################################################################
# Addressable with empty d_tag
###############################################################################

subtest 'find_addressable with empty d_tag' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e = make_event(
        pubkey => $PK1, kind => 30023, content => 'no-dtag',
        created_at => 1000, tags => [['d', '']],
    );
    $store->store($e);

    my $found = $store->find_addressable($PK1, 30023, '');
    ok defined $found, 'found addressable with empty d_tag';
    is $found->id, $e->id, 'correct event';

    # implicit empty d_tag (no d tag at all — d_tag defaults to '')
    my $e2 = make_event(
        pubkey => $PK2, kind => 30023, content => 'implicit-empty',
        created_at => 2000, tags => [],
    );
    $store->store($e2);
    my $found2 = $store->find_addressable($PK2, 30023, '');
    ok defined $found2, 'found addressable with implicit empty d_tag';
    is $found2->id, $e2->id, 'correct event';
};

###############################################################################
# Multiple tags of same letter
###############################################################################

subtest 'event with multiple tags of same letter indexed correctly' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e = make_event(
        kind => 1, content => 'multi-p', created_at => 1000,
        tags => [['p', $PK1], ['p', $PK2], ['p', $PK3]],
    );
    $store->store($e);

    # should be findable via any of the three tag values
    for my $pk ($PK1, $PK2, $PK3) {
        my $results = $store->query([Net::Nostr::Filter->new('#p' => [$pk])]);
        is scalar @$results, 1, "found via p tag $pk";
        is $results->[0]->id, $e->id, 'correct event';
    }
};

###############################################################################
# delete_matching with ids AND addresses simultaneously
###############################################################################

subtest 'delete_matching with both ids and addresses' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e1 = make_event(pubkey => $PK1, kind => 1, content => 'by-id', created_at => 1000);
    my $e2 = make_event(
        pubkey => $PK1, kind => 30023, content => 'by-addr',
        created_at => 2000, tags => [['d', 'target']],
    );
    my $e3 = make_event(pubkey => $PK1, kind => 1, content => 'keep', created_at => 3000);
    $store->store($_) for ($e1, $e2, $e3);

    my $addr = "30023:$PK1:target";
    my $count = $store->delete_matching($PK1, [$e1->id], [$addr], 9999);
    is $count, 2, 'deleted 2 events (one by id, one by address)';
    is $store->event_count, 1, '1 event remains';
    ok defined $store->get_by_id($e3->id), 'kept event still there';
    is $store->get_by_id($e1->id), undef, 'id-targeted event gone';
    is $store->get_by_id($e2->id), undef, 'addr-targeted event gone';
};

###############################################################################
# Eviction of replaceable/addressable events cleans special indexes
###############################################################################

subtest 'max_events eviction cleans replaceable index' => sub {
    my $store = Net::Nostr::RelayStore->new(max_events => 1);

    my $e1 = make_event(pubkey => $PK1, kind => 0, content => 'profile', created_at => 1000);
    $store->store($e1);
    ok defined $store->find_replaceable($PK1, 0), 'replaceable index populated';

    # store a newer event, evicting the replaceable one
    my $e2 = make_event(pubkey => $PK2, kind => 1, content => 'newer', created_at => 2000);
    $store->store($e2);
    is $store->event_count, 1, 'only 1 event';
    is $store->find_replaceable($PK1, 0), undef, 'replaceable index cleaned after eviction';
};

subtest 'max_events eviction cleans addressable index' => sub {
    my $store = Net::Nostr::RelayStore->new(max_events => 1);

    my $e1 = make_event(
        pubkey => $PK1, kind => 30023, content => 'article',
        created_at => 1000, tags => [['d', 'slug']],
    );
    $store->store($e1);
    ok defined $store->find_addressable($PK1, 30023, 'slug'), 'addressable index populated';

    my $e2 = make_event(pubkey => $PK2, kind => 1, content => 'newer', created_at => 2000);
    $store->store($e2);
    is $store->event_count, 1, 'only 1 event';
    is $store->find_addressable($PK1, 30023, 'slug'), undef, 'addressable index cleaned after eviction';
};

###############################################################################
# Tiebreaking sort order: same created_at, id ASC
###############################################################################

subtest 'sort tiebreak: same created_at orders by id ASC' => sub {
    my $store = Net::Nostr::RelayStore->new;
    # create events with same timestamp but different ids
    my @events;
    for my $c ('a'..'e') {
        push @events, make_event(
            kind => 1, content => "content-$c", created_at => 5000,
            tags => [['nonce', $c]],  # force different id
        );
    }
    $store->store($_) for @events;

    my $all = $store->all_events;
    is scalar @$all, 5, '5 events';

    # all have same created_at, should be sorted by id ASC
    my @ids = map { $_->id } @$all;
    my @sorted_ids = sort @ids;
    is \@ids, \@sorted_ids, 'ids sorted ascending for same created_at';
};

###############################################################################
# query with limit => 0
###############################################################################

subtest 'query with limit 0 returns nothing' => sub {
    my $store = Net::Nostr::RelayStore->new;
    $store->store(make_event(kind => 1, content => 'a', created_at => 1000));

    my $results = $store->query([Net::Nostr::Filter->new(kinds => [1], limit => 0)]);
    is $results, [], 'limit 0 returns empty';
};

###############################################################################
# Store reuse after clear
###############################################################################

subtest 'store works correctly after clear' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e1 = make_event(
        pubkey => $PK1, kind => 0, content => 'first', created_at => 1000,
        tags => [['t', 'tag1']],
    );
    $store->store($e1);
    is $store->event_count, 1, 'stored 1';

    $store->clear;
    is $store->event_count, 0, 'cleared';

    # store new events and verify all indexes work
    my $e2 = make_event(
        pubkey => $PK1, kind => 0, content => 'second', created_at => 2000,
        tags => [['t', 'tag2']],
    );
    $store->store($e2);
    is $store->event_count, 1, 'stored after clear';

    ok defined $store->get_by_id($e2->id), 'id index works after clear';
    is $store->get_by_id($e1->id), undef, 'old event gone';
    ok defined $store->find_replaceable($PK1, 0), 'replaceable index works after clear';

    my $results = $store->query([Net::Nostr::Filter->new(kinds => [0])]);
    is scalar @$results, 1, 'kind index works after clear';

    $results = $store->query([Net::Nostr::Filter->new(authors => [$PK1])]);
    is scalar @$results, 1, 'author index works after clear';

    $results = $store->query([Net::Nostr::Filter->new('#t' => ['tag2'])]);
    is scalar @$results, 1, 'tag index works after clear';

    $results = $store->query([Net::Nostr::Filter->new('#t' => ['tag1'])]);
    is $results, [], 'old tag not found after clear';
};

###############################################################################
# Index consistency under mixed operations
###############################################################################

subtest 'store, delete, store cycle maintains consistency' => sub {
    my $store = Net::Nostr::RelayStore->new;

    my $e1 = make_event(pubkey => $PK1, kind => 1, content => 'a', created_at => 1000);
    my $e2 = make_event(pubkey => $PK1, kind => 1, content => 'b', created_at => 2000);

    $store->store($e1);
    $store->store($e2);
    is $store->event_count, 2, '2 events stored';

    $store->delete_by_id($e1->id);
    is $store->event_count, 1, '1 event after delete';

    # store a new event with same pubkey
    my $e3 = make_event(pubkey => $PK1, kind => 1, content => 'c', created_at => 3000);
    $store->store($e3);
    is $store->event_count, 2, '2 events again';

    my $results = $store->query([Net::Nostr::Filter->new(authors => [$PK1])]);
    is scalar @$results, 2, 'author index correct';
    is $results->[0]->content, 'c', 'newest first';
    is $results->[1]->content, 'b', 'second event';
};

subtest 'replaceable index updated on delete + re-store' => sub {
    my $store = Net::Nostr::RelayStore->new;

    my $e1 = make_event(pubkey => $PK1, kind => 0, content => 'old profile', created_at => 1000);
    $store->store($e1);
    is $store->find_replaceable($PK1, 0)->id, $e1->id, 'first replaceable stored';

    $store->delete_by_id($e1->id);
    is $store->find_replaceable($PK1, 0), undef, 'replaceable cleared after delete';

    my $e2 = make_event(pubkey => $PK1, kind => 0, content => 'new profile', created_at => 2000);
    $store->store($e2);
    is $store->find_replaceable($PK1, 0)->id, $e2->id, 'new replaceable stored';
};

###############################################################################
# store() enforces "newest wins" for replaceable/addressable indexes
###############################################################################

subtest 'store older replaceable does not overwrite newer in index' => sub {
    my $store = Net::Nostr::RelayStore->new;

    my $newer = make_event(pubkey => $PK1, kind => 0, content => 'new', created_at => 2000);
    my $older = make_event(pubkey => $PK1, kind => 0, content => 'old', created_at => 1000);

    $store->store($newer);
    $store->store($older);  # both stored, but index should still point to newer

    is $store->event_count, 2, 'both events stored';
    is $store->find_replaceable($PK1, 0)->id, $newer->id,
        'replaceable index points to newest event';
};

subtest 'store older addressable does not overwrite newer in index' => sub {
    my $store = Net::Nostr::RelayStore->new;

    my $newer = make_event(
        pubkey => $PK1, kind => 30023, content => 'new',
        created_at => 2000, tags => [['d', 'slug']],
    );
    my $older = make_event(
        pubkey => $PK1, kind => 30023, content => 'old',
        created_at => 1000, tags => [['d', 'slug']],
    );

    $store->store($newer);
    $store->store($older);

    is $store->event_count, 2, 'both events stored';
    is $store->find_addressable($PK1, 30023, 'slug')->id, $newer->id,
        'addressable index points to newest event';
};

subtest 'store newer replaceable does overwrite older in index' => sub {
    my $store = Net::Nostr::RelayStore->new;

    my $older = make_event(pubkey => $PK1, kind => 0, content => 'old', created_at => 1000);
    my $newer = make_event(pubkey => $PK1, kind => 0, content => 'new', created_at => 2000);

    $store->store($older);
    is $store->find_replaceable($PK1, 0)->id, $older->id, 'older is current';

    $store->store($newer);
    is $store->find_replaceable($PK1, 0)->id, $newer->id,
        'replaceable index updated to newer event';
};

subtest 'store same-timestamp replaceable uses id tiebreak' => sub {
    my $store = Net::Nostr::RelayStore->new;

    my $e1 = make_event(
        pubkey => $PK1, kind => 0, content => 'first',
        created_at => 1000, tags => [['nonce', 'a']],
    );
    my $e2 = make_event(
        pubkey => $PK1, kind => 0, content => 'second',
        created_at => 1000, tags => [['nonce', 'b']],
    );

    $store->store($e1);
    $store->store($e2);

    # NIP-01: lowest id wins tiebreak for replaceable
    my $expected = ($e1->id lt $e2->id) ? $e1 : $e2;
    is $store->find_replaceable($PK1, 0)->id, $expected->id,
        'tiebreak: lowest id wins for replaceable index';
};

###############################################################################
# delete_by_id promotes next best candidate in special indexes
###############################################################################

subtest 'delete replaceable promotes next best candidate' => sub {
    my $store = Net::Nostr::RelayStore->new;

    my $older = make_event(pubkey => $PK1, kind => 0, content => 'old', created_at => 1000);
    my $newer = make_event(pubkey => $PK1, kind => 0, content => 'new', created_at => 2000);

    $store->store($older);
    $store->store($newer);
    is $store->find_replaceable($PK1, 0)->id, $newer->id, 'index points to newest';

    $store->delete_by_id($newer->id);
    my $promoted = $store->find_replaceable($PK1, 0);
    ok defined $promoted, 'index not empty after deleting newest';
    is $promoted->id, $older->id, 'older event promoted to index';
};

subtest 'delete addressable promotes next best candidate' => sub {
    my $store = Net::Nostr::RelayStore->new;

    my $older = make_event(
        pubkey => $PK1, kind => 30023, content => 'old',
        created_at => 1000, tags => [['d', 'slug']],
    );
    my $newer = make_event(
        pubkey => $PK1, kind => 30023, content => 'new',
        created_at => 2000, tags => [['d', 'slug']],
    );

    $store->store($older);
    $store->store($newer);
    is $store->find_addressable($PK1, 30023, 'slug')->id, $newer->id, 'index points to newest';

    $store->delete_by_id($newer->id);
    my $promoted = $store->find_addressable($PK1, 30023, 'slug');
    ok defined $promoted, 'index not empty after deleting newest';
    is $promoted->id, $older->id, 'older event promoted to index';
};

subtest 'delete only replaceable clears index completely' => sub {
    my $store = Net::Nostr::RelayStore->new;

    my $e = make_event(pubkey => $PK1, kind => 0, content => 'solo', created_at => 1000);
    $store->store($e);
    $store->delete_by_id($e->id);
    is $store->find_replaceable($PK1, 0), undef, 'index empty when no candidates remain';
};

###############################################################################
# delete_by_id binary search correctness
###############################################################################

subtest 'delete_by_id removes from beginning of ordered list (newest)' => sub {
    my $store = Net::Nostr::RelayStore->new;

    my $e1 = make_event(pubkey => $PK1, kind => 1, content => 'old', created_at => 1000);
    my $e2 = make_event(pubkey => $PK1, kind => 1, content => 'mid', created_at => 2000);
    my $e3 = make_event(pubkey => $PK1, kind => 1, content => 'new', created_at => 3000);
    $store->store($e1);
    $store->store($e2);
    $store->store($e3);

    $store->delete_by_id($e3->id);
    is $store->event_count, 2, 'count after deleting newest';
    is $store->get_by_id($e3->id), undef, 'newest gone';
    my $all = $store->all_events;
    is scalar @$all, 2, 'ordered list has 2';
    is $all->[0]->id, $e2->id, 'first is now e2 (next newest)';
    is $all->[1]->id, $e1->id, 'second is e1 (oldest)';
};

subtest 'delete_by_id removes from end of ordered list (oldest)' => sub {
    my $store = Net::Nostr::RelayStore->new;

    my $e1 = make_event(pubkey => $PK1, kind => 1, content => 'old', created_at => 1000);
    my $e2 = make_event(pubkey => $PK1, kind => 1, content => 'mid', created_at => 2000);
    my $e3 = make_event(pubkey => $PK1, kind => 1, content => 'new', created_at => 3000);
    $store->store($e1);
    $store->store($e2);
    $store->store($e3);

    $store->delete_by_id($e1->id);
    is $store->event_count, 2, 'count after deleting oldest';
    is $store->get_by_id($e1->id), undef, 'oldest gone';
    my $all = $store->all_events;
    is $all->[0]->id, $e3->id, 'first is newest';
    is $all->[1]->id, $e2->id, 'second is middle';
};

subtest 'delete_by_id removes from middle of ordered list' => sub {
    my $store = Net::Nostr::RelayStore->new;

    my $e1 = make_event(pubkey => $PK1, kind => 1, content => 'old', created_at => 1000);
    my $e2 = make_event(pubkey => $PK1, kind => 1, content => 'mid', created_at => 2000);
    my $e3 = make_event(pubkey => $PK1, kind => 1, content => 'new', created_at => 3000);
    $store->store($e1);
    $store->store($e2);
    $store->store($e3);

    $store->delete_by_id($e2->id);
    is $store->event_count, 2, 'count after deleting middle';
    is $store->get_by_id($e2->id), undef, 'middle gone';
    my $all = $store->all_events;
    is $all->[0]->id, $e3->id, 'first is newest';
    is $all->[1]->id, $e1->id, 'second is oldest';
};

subtest 'delete_by_id with same created_at (tiebreaker by id)' => sub {
    my $store = Net::Nostr::RelayStore->new;

    # Create 5 events with identical timestamp — order is by id ASC
    my @events;
    for my $i (1..5) {
        my $e = make_event(
            pubkey => $PK1, kind => 1, content => "event_$i", created_at => 1000,
        );
        $store->store($e);
        push @events, $e;
    }
    is $store->event_count, 5, '5 events stored';

    # Delete the middle one (by sort order)
    my @sorted = sort { $a->id cmp $b->id } @events;
    my $mid = $sorted[2];
    $store->delete_by_id($mid->id);
    is $store->event_count, 4, 'count is 4 after delete';
    is $store->get_by_id($mid->id), undef, 'middle-by-id event gone';

    # Remaining events should still be in correct order
    my $all = $store->all_events;
    is scalar @$all, 4, '4 events in ordered list';
    for my $i (0 .. $#$all - 1) {
        my $cmp = $all->[$i]->created_at <=> $all->[$i+1]->created_at;
        $cmp = $all->[$i]->id cmp $all->[$i+1]->id if $cmp == 0;
        ok($cmp <= 0, "order preserved at position $i");
    }
};

subtest 'delete_by_id: sequential deletes until empty' => sub {
    my $store = Net::Nostr::RelayStore->new;

    my @events;
    for my $ts (1000, 2000, 3000, 4000, 5000) {
        my $e = make_event(pubkey => $PK1, kind => 1, content => "t$ts", created_at => $ts);
        $store->store($e);
        push @events, $e;
    }
    is $store->event_count, 5, '5 events stored';

    # Delete in random order: 3rd, 1st, 5th, 2nd, 4th
    for my $idx (2, 0, 4, 1, 3) {
        $store->delete_by_id($events[$idx]->id);
    }
    is $store->event_count, 0, 'all events deleted';
    is $store->all_events, [], 'ordered list empty';
};

subtest 'delete_by_id: single event store' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $e = make_event(pubkey => $PK1, kind => 1, content => 'solo', created_at => 1000);
    $store->store($e);
    $store->delete_by_id($e->id);
    is $store->event_count, 0, 'store empty after deleting sole event';
    is $store->all_events, [], 'ordered list empty';
};

subtest 'delete_by_id: store and delete interleaved maintains order' => sub {
    my $store = Net::Nostr::RelayStore->new;

    my $e1 = make_event(pubkey => $PK1, kind => 1, content => 'a', created_at => 1000);
    my $e2 = make_event(pubkey => $PK1, kind => 1, content => 'b', created_at => 2000);
    $store->store($e1);
    $store->store($e2);
    $store->delete_by_id($e1->id);

    my $e3 = make_event(pubkey => $PK1, kind => 1, content => 'c', created_at => 1500);
    $store->store($e3);

    my $all = $store->all_events;
    is scalar @$all, 2, '2 events';
    is $all->[0]->id, $e2->id, 'newest first';
    is $all->[1]->id, $e3->id, 'next by created_at';
};

###############################################################################
# Issue 4: delete_matching must handle a-tag references to replaceable events
###############################################################################

subtest 'delete_matching: a-tag deletion of replaceable event' => sub {
    my $store = Net::Nostr::RelayStore->new;

    # Kind 10000 is replaceable (10000-19999 range)
    my $e = make_event(
        pubkey => $PK1, kind => 10000, content => 'replaceable',
        created_at => 1000, tags => [['d', '']],
    );
    $store->store($e);
    is $store->event_count, 1, 'event stored';

    # a-tag format for replaceable: "kind:pubkey:" (empty d-tag component)
    my $count = $store->delete_matching($PK1, [], ["10000:${PK1}:"], 2000);
    is $count, 1, 'replaceable event deleted via a-tag';
    is $store->event_count, 0, 'store empty after deletion';
};

subtest 'delete_matching: a-tag deletion of kind 0 replaceable event' => sub {
    my $store = Net::Nostr::RelayStore->new;

    my $e = make_event(
        pubkey => $PK1, kind => 0, content => '{"name":"test"}',
        created_at => 1000,
    );
    $store->store($e);
    is $store->event_count, 1, 'kind 0 event stored';

    my $count = $store->delete_matching($PK1, [], ["0:${PK1}:"], 2000);
    is $count, 1, 'kind 0 replaceable event deleted via a-tag';
    is $store->event_count, 0, 'store empty';
};

subtest 'delete_matching: a-tag deletion of replaceable respects before_ts' => sub {
    my $store = Net::Nostr::RelayStore->new;

    my $e = make_event(
        pubkey => $PK1, kind => 10000, content => 'newer',
        created_at => 3000,
    );
    $store->store($e);

    # Deletion request created_at 2000 — event at 3000 should NOT be deleted
    my $count = $store->delete_matching($PK1, [], ["10000:${PK1}:"], 2000);
    is $count, 0, 'replaceable event newer than deletion not deleted';
    is $store->event_count, 1, 'event still in store';
};

subtest 'delete_matching: a-tag deletion of replaceable respects pubkey' => sub {
    my $store = Net::Nostr::RelayStore->new;

    my $e = make_event(
        pubkey => $PK1, kind => 10000, content => 'mine',
        created_at => 1000,
    );
    $store->store($e);

    # PK2 tries to delete PK1's event
    my $count = $store->delete_matching($PK2, [], ["10000:${PK1}:"], 2000);
    is $count, 0, 'cannot delete another pubkey replaceable event';
    is $store->event_count, 1, 'event still in store';
};

done_testing;
