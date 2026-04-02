#!/usr/bin/perl

use strictures 2;

use Test2::V0 -no_srand => 1;

use Net::Nostr::Filter;
use Net::Nostr::Event;

my %BASE_EVENT = (
    pubkey     => 'aa' x 32,
    kind       => 1,
    content    => 'hello',
    sig        => '',
    created_at => 1000,
    tags       => [],
);

###############################################################################
# Construction
###############################################################################

subtest 'new() with all fields' => sub {
    my $filter = Net::Nostr::Filter->new(
        ids     => ['bb' x 32],
        authors => ['aa' x 32],
        kinds   => [1, 2],
        since   => 900,
        until   => 1100,
        limit   => 10,
        '#e'    => ['cc' x 32],
        '#p'    => ['dd' x 32],
    );
    is($filter->ids, ['bb' x 32], 'ids set');
    is($filter->authors, ['aa' x 32], 'authors set');
    is($filter->kinds, [1, 2], 'kinds set');
    is($filter->since, 900, 'since set');
    is($filter->until, 1100, 'until set');
    is($filter->limit, 10, 'limit set');
    is($filter->tag_filter('e'), ['cc' x 32], '#e tag filter set');
    is($filter->tag_filter('p'), ['dd' x 32], '#p tag filter set');
};

subtest 'new() with no fields is an empty filter' => sub {
    my $filter = Net::Nostr::Filter->new;
    ok(!defined $filter->ids, 'ids undef');
    ok(!defined $filter->authors, 'authors undef');
    ok(!defined $filter->kinds, 'kinds undef');
    ok(!defined $filter->since, 'since undef');
    ok(!defined $filter->until, 'until undef');
    ok(!defined $filter->limit, 'limit undef');
};

###############################################################################
# matches() - empty filter matches everything
###############################################################################

subtest 'empty filter matches any event' => sub {
    my $filter = Net::Nostr::Filter->new;
    my $event = Net::Nostr::Event->new(%BASE_EVENT);
    ok($filter->matches($event), 'empty filter matches');
};

###############################################################################
# matches() - ids
###############################################################################

subtest 'ids filter matches event with matching id' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT);
    my $filter = Net::Nostr::Filter->new(ids => [$event->id]);
    ok($filter->matches($event), 'matching id passes');
};

subtest 'ids filter rejects event with non-matching id' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT);
    my $filter = Net::Nostr::Filter->new(ids => ['ff' x 32]);
    ok(!$filter->matches($event), 'non-matching id rejected');
};

subtest 'ids filter matches if any id matches' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT);
    my $filter = Net::Nostr::Filter->new(ids => ['ff' x 32, $event->id]);
    ok($filter->matches($event), 'second id matches');
};

###############################################################################
# matches() - authors
###############################################################################

subtest 'authors filter matches event pubkey' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT);
    my $filter = Net::Nostr::Filter->new(authors => ['aa' x 32]);
    ok($filter->matches($event), 'matching author passes');
};

subtest 'authors filter rejects wrong pubkey' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT);
    my $filter = Net::Nostr::Filter->new(authors => ['ff' x 32]);
    ok(!$filter->matches($event), 'wrong author rejected');
};

###############################################################################
# matches() - kinds
###############################################################################

subtest 'kinds filter matches event kind' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT);
    my $filter = Net::Nostr::Filter->new(kinds => [1]);
    ok($filter->matches($event), 'matching kind passes');
};

subtest 'kinds filter rejects wrong kind' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT);
    my $filter = Net::Nostr::Filter->new(kinds => [2, 3]);
    ok(!$filter->matches($event), 'wrong kind rejected');
};

###############################################################################
# matches() - since / until
###############################################################################

subtest 'since filter matches created_at >= since' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT); # created_at => 1000
    my $filter_eq = Net::Nostr::Filter->new(since => 1000);
    ok($filter_eq->matches($event), 'created_at == since passes');

    my $filter_lt = Net::Nostr::Filter->new(since => 999);
    ok($filter_lt->matches($event), 'created_at > since passes');

    my $filter_gt = Net::Nostr::Filter->new(since => 1001);
    ok(!$filter_gt->matches($event), 'created_at < since rejected');
};

subtest 'until filter matches created_at <= until' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT); # created_at => 1000
    my $filter_eq = Net::Nostr::Filter->new(until => 1000);
    ok($filter_eq->matches($event), 'created_at == until passes');

    my $filter_gt = Net::Nostr::Filter->new(until => 1001);
    ok($filter_gt->matches($event), 'created_at < until passes');

    my $filter_lt = Net::Nostr::Filter->new(until => 999);
    ok(!$filter_lt->matches($event), 'created_at > until rejected');
};

subtest 'since and until together' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT); # created_at => 1000
    my $in_range = Net::Nostr::Filter->new(since => 900, until => 1100);
    ok($in_range->matches($event), 'in range passes');

    my $out_range = Net::Nostr::Filter->new(since => 1001, until => 2000);
    ok(!$out_range->matches($event), 'out of range rejected');
};

###############################################################################
# matches() - tag filters (#e, #p, etc.)
###############################################################################

subtest '#e tag filter matches event with matching e tag' => sub {
    my $eid = 'cc' x 32;
    my $event = Net::Nostr::Event->new(%BASE_EVENT, tags => [['e', $eid]]);
    my $filter = Net::Nostr::Filter->new('#e' => [$eid]);
    ok($filter->matches($event), 'matching #e tag passes');
};

subtest '#e tag filter rejects event without matching e tag' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT, tags => [['e', 'cc' x 32]]);
    my $filter = Net::Nostr::Filter->new('#e' => ['ff' x 32]);
    ok(!$filter->matches($event), 'non-matching #e tag rejected');
};

subtest '#p tag filter matches' => sub {
    my $pk = 'dd' x 32;
    my $event = Net::Nostr::Event->new(%BASE_EVENT, tags => [['p', $pk]]);
    my $filter = Net::Nostr::Filter->new('#p' => [$pk]);
    ok($filter->matches($event), 'matching #p tag passes');
};

subtest 'tag filter checks first value only' => sub {
    my $eid = 'cc' x 32;
    my $other_eid = 'ee' x 32;
    my $event = Net::Nostr::Event->new(%BASE_EVENT,
        tags => [['e', $eid, 'wss://relay.example.com']]);
    my $filter = Net::Nostr::Filter->new('#e' => [$eid]);
    ok($filter->matches($event), 'first value indexed');

    my $filter2 = Net::Nostr::Filter->new('#e' => [$other_eid]);
    ok(!$filter2->matches($event), 'non-matching id rejected');

    # relay URL in third position is not indexed (use #t for arbitrary values)
    my $event2 = Net::Nostr::Event->new(%BASE_EVENT,
        tags => [['t', 'wss://relay.example.com', 'extra']]);
    my $filter3 = Net::Nostr::Filter->new('#t' => ['extra']);
    ok(!$filter3->matches($event2), 'non-first value not indexed');
};

subtest 'tag filter matches if any event tag matches any filter value' => sub {
    my $eid1 = 'cc' x 32;
    my $eid2 = 'dd' x 32;
    my $event = Net::Nostr::Event->new(%BASE_EVENT,
        tags => [['e', $eid1], ['e', $eid2]]);
    my $filter = Net::Nostr::Filter->new('#e' => ['ff' x 32, $eid2]);
    ok($filter->matches($event), 'second event tag matches second filter value');
};

subtest 'tag filter on event with no tags of that type rejects' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT, tags => [['p', 'aa' x 32]]);
    my $filter = Net::Nostr::Filter->new('#e' => ['cc' x 32]);
    ok(!$filter->matches($event), 'no e tags means #e filter rejects');
};

subtest 'arbitrary single-letter tag filter' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT, tags => [['t', 'nostr']]);
    my $filter = Net::Nostr::Filter->new('#t' => ['nostr']);
    ok($filter->matches($event), 'custom #t tag filter matches');
};

###############################################################################
# matches() - multiple conditions are AND
###############################################################################

subtest 'all conditions must match (AND)' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT); # kind 1, pubkey aa..
    my $filter = Net::Nostr::Filter->new(
        authors => ['aa' x 32],
        kinds   => [1],
    );
    ok($filter->matches($event), 'both conditions match');

    my $filter2 = Net::Nostr::Filter->new(
        authors => ['aa' x 32],
        kinds   => [2],
    );
    ok(!$filter2->matches($event), 'one condition fails => rejected');
};

###############################################################################
# to_hash
###############################################################################

subtest 'to_hash round-trips all fields' => sub {
    my $filter = Net::Nostr::Filter->new(
        ids     => ['bb' x 32],
        authors => ['aa' x 32],
        kinds   => [1],
        since   => 900,
        until   => 1100,
        limit   => 10,
        '#e'    => ['cc' x 32],
    );
    my $h = $filter->to_hash;
    is($h->{ids}, ['bb' x 32], 'ids in hash');
    is($h->{authors}, ['aa' x 32], 'authors in hash');
    is($h->{kinds}, [1], 'kinds in hash');
    is($h->{since}, 900, 'since in hash');
    is($h->{until}, 1100, 'until in hash');
    is($h->{limit}, 10, 'limit in hash');
    is($h->{'#e'}, ['cc' x 32], '#e in hash');
};

subtest 'to_hash omits undef fields' => sub {
    my $filter = Net::Nostr::Filter->new(kinds => [1]);
    my $h = $filter->to_hash;
    ok(!exists $h->{ids}, 'ids omitted');
    ok(!exists $h->{authors}, 'authors omitted');
    ok(!exists $h->{since}, 'since omitted');
    ok(!exists $h->{until}, 'until omitted');
    ok(!exists $h->{limit}, 'limit omitted');
    is($h->{kinds}, [1], 'kinds present');
};

###############################################################################
# Validation: ids, authors, #e, #p must be 64-char lowercase hex
###############################################################################

subtest 'ids rejects non-64-char-lowercase-hex' => sub {
    ok(dies { Net::Nostr::Filter->new(ids => ['short']) }, 'too short');
    ok(dies { Net::Nostr::Filter->new(ids => ['AA' x 32]) }, 'uppercase rejected');
    ok(dies { Net::Nostr::Filter->new(ids => ['gg' x 32]) }, 'non-hex rejected');
    ok(dies { Net::Nostr::Filter->new(ids => ['aa' x 33]) }, 'too long');
    ok(lives { Net::Nostr::Filter->new(ids => ['aa' x 32]) }, 'valid id accepted');
    ok(lives { Net::Nostr::Filter->new(ids => ['aa' x 32, 'bb' x 32]) }, 'multiple valid ids accepted');
    ok(dies { Net::Nostr::Filter->new(ids => ['aa' x 32, 'short']) }, 'one invalid in list rejects');
};

subtest 'authors rejects non-64-char-lowercase-hex' => sub {
    ok(dies { Net::Nostr::Filter->new(authors => ['short']) }, 'too short');
    ok(dies { Net::Nostr::Filter->new(authors => ['AA' x 32]) }, 'uppercase rejected');
    ok(lives { Net::Nostr::Filter->new(authors => ['aa' x 32]) }, 'valid author accepted');
};

subtest '#e rejects non-64-char-lowercase-hex' => sub {
    ok(dies { Net::Nostr::Filter->new('#e' => ['short']) }, 'too short');
    ok(dies { Net::Nostr::Filter->new('#e' => ['AA' x 32]) }, 'uppercase rejected');
    ok(lives { Net::Nostr::Filter->new('#e' => ['aa' x 32]) }, 'valid #e accepted');
};

subtest '#p rejects non-64-char-lowercase-hex' => sub {
    ok(dies { Net::Nostr::Filter->new('#p' => ['short']) }, 'too short');
    ok(dies { Net::Nostr::Filter->new('#p' => ['AA' x 32]) }, 'uppercase rejected');
    ok(lives { Net::Nostr::Filter->new('#p' => ['aa' x 32]) }, 'valid #p accepted');
};

subtest 'other tag filters do not require hex' => sub {
    ok(lives { Net::Nostr::Filter->new('#t' => ['nostr']) }, '#t accepts arbitrary strings');
    ok(lives { Net::Nostr::Filter->new('#r' => ['https://example.com']) }, '#r accepts URLs');
};

###############################################################################
# tag_filter accessor
###############################################################################

subtest 'POD: tag_filter returns values for a tag filter' => sub {
    my $filter = Net::Nostr::Filter->new('#t' => ['nostr', 'perl']);
    is($filter->tag_filter('t'), ['nostr', 'perl'], 'tag_filter returns values');
};

subtest 'POD: tag_filter returns undef for unset tag' => sub {
    my $filter = Net::Nostr::Filter->new(kinds => [1]);
    is($filter->tag_filter('t'), undef, 'tag_filter returns undef for unset tag');
};

subtest 'POD: matches with since filter' => sub {
    my $filter = Net::Nostr::Filter->new(kinds => [1], since => 1000);
    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 1, content => '',
        created_at => 2000, tags => [],
    );
    ok($filter->matches($event), 'event after since matches');

    my $old_event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 1, content => '',
        created_at => 500, tags => [],
    );
    ok(!$filter->matches($old_event), 'event before since does not match');
};

###############################################################################
# matches_any - multiple filters are OR
###############################################################################

subtest 'matches_any returns true if any filter matches' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT); # kind 1, pubkey aa..
    my $f1 = Net::Nostr::Filter->new(kinds => [2]);      # no match
    my $f2 = Net::Nostr::Filter->new(kinds => [1]);      # match
    ok(Net::Nostr::Filter->matches_any($event, $f1, $f2), 'second filter matches');
};

subtest 'matches_any returns false if no filter matches' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT);
    my $f1 = Net::Nostr::Filter->new(kinds => [2]);
    my $f2 = Net::Nostr::Filter->new(kinds => [3]);
    ok(!Net::Nostr::Filter->matches_any($event, $f1, $f2), 'no filter matches');
};

subtest 'matches_any with single filter' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT);
    my $f = Net::Nostr::Filter->new(kinds => [1]);
    ok(Net::Nostr::Filter->matches_any($event, $f), 'single matching filter');
};

###############################################################################
# croak on bad input
###############################################################################

subtest 'new() croaks from caller perspective on bad hex' => sub {
    like(dies { Net::Nostr::Filter->new(ids => ['not-hex']) },
        qr/at \Q${\__FILE__}\E/, 'bad ids croaks from caller perspective');
    like(dies { Net::Nostr::Filter->new(authors => ['bad']) },
        qr/at \Q${\__FILE__}\E/, 'bad authors croaks from caller perspective');
};

done_testing;
