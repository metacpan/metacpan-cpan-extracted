#!/usr/bin/perl

use strictures 2;

use Test2::V0 -no_srand => 1;

use Net::Nostr::Filter;
use Net::Nostr::Event;

my %BASE_EVENT = (
    pubkey     => 'aa' x 32,
    kind       => 1,
    content    => 'hello',
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
# POD: search matching
###############################################################################

subtest 'POD: search filter matches content' => sub {
    my $search_filter = Net::Nostr::Filter->new(search => 'nostr apps');
    my $note = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 1, content => 'best nostr apps for daily use',
        created_at => 1000, tags => [],
    );
    ok($search_filter->matches($note), 'search matches content');
};

###############################################################################
# POD: parse_search_extensions
###############################################################################

subtest 'POD: parse_search_extensions' => sub {
    my $result = Net::Nostr::Filter->parse_search_extensions(
        'best nostr apps language:en nsfw:false'
    );
    is($result->{terms}, ['best', 'nostr', 'apps'], 'terms');
    is($result->{extensions}{language}, 'en', 'language extension');
    is($result->{extensions}{nsfw}, 'false', 'nsfw extension');
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

subtest 'kinds rejects non-integer' => sub {
    like(
        dies { Net::Nostr::Filter->new(kinds => ['abc']) },
        qr/kinds: 'abc' is not a valid kind/,
        'non-integer kind rejected'
    );
};

subtest 'kinds rejects out of range' => sub {
    like(
        dies { Net::Nostr::Filter->new(kinds => [65536]) },
        qr/kinds: '65536' is not a valid kind/,
        'kind > 65535 rejected'
    );
    like(
        dies { Net::Nostr::Filter->new(kinds => [-1]) },
        qr/kinds: '-1' is not a valid kind/,
        'negative kind rejected'
    );
};

subtest 'kinds accepts valid range' => sub {
    ok(lives { Net::Nostr::Filter->new(kinds => [0, 1, 65535]) }, 'valid kinds accepted');
};

subtest 'since rejects non-integer' => sub {
    like(
        dies { Net::Nostr::Filter->new(since => 'abc') },
        qr/since must be a non-negative integer/,
        'non-integer since rejected'
    );
};

subtest 'limit rejects negative' => sub {
    like(
        dies { Net::Nostr::Filter->new(limit => -1) },
        qr/limit must be a non-negative integer/,
        'negative limit rejected'
    );
};

###############################################################################
# Empty arrays rejected
###############################################################################

subtest 'empty ids array rejected' => sub {
    like(
        dies { Net::Nostr::Filter->new(ids => []) },
        qr/ids must be a non-empty array/,
        'empty ids rejected'
    );
};

subtest 'empty authors array rejected' => sub {
    like(
        dies { Net::Nostr::Filter->new(authors => []) },
        qr/authors must be a non-empty array/,
        'empty authors rejected'
    );
};

subtest 'empty kinds array rejected' => sub {
    like(
        dies { Net::Nostr::Filter->new(kinds => []) },
        qr/kinds must be a non-empty array/,
        'empty kinds rejected'
    );
};

subtest 'empty #e tag filter rejected' => sub {
    like(
        dies { Net::Nostr::Filter->new('#e' => []) },
        qr/must be a non-empty array/,
        'empty #e rejected'
    );
};

subtest 'empty #p tag filter rejected' => sub {
    like(
        dies { Net::Nostr::Filter->new('#p' => []) },
        qr/must be a non-empty array/,
        'empty #p rejected'
    );
};

subtest 'empty #t tag filter rejected' => sub {
    like(
        dies { Net::Nostr::Filter->new('#t' => []) },
        qr/must be a non-empty array/,
        'empty #t rejected'
    );
};

subtest 'non-empty arrays still accepted' => sub {
    ok(lives { Net::Nostr::Filter->new(ids => ['aa' x 32]) }, 'non-empty ids ok');
    ok(lives { Net::Nostr::Filter->new(authors => ['aa' x 32]) }, 'non-empty authors ok');
    ok(lives { Net::Nostr::Filter->new(kinds => [1]) }, 'non-empty kinds ok');
    ok(lives { Net::Nostr::Filter->new('#t' => ['nostr']) }, 'non-empty #t ok');
};

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::Filter->new(bogus => 'value') },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

subtest 'new() rejects non-string search' => sub {
    like(
        dies { Net::Nostr::Filter->new(search => ['not', 'a', 'string']) },
        qr/search must be a string/i,
        'arrayref search rejected'
    );
    like(
        dies { Net::Nostr::Filter->new(search => { query => 'test' }) },
        qr/search must be a string/i,
        'hashref search rejected'
    );
};

###############################################################################
# Defensive copying: caller/accessor mutation must not affect internal state
###############################################################################

subtest 'caller mutation of ids does not affect filter' => sub {
    my @ids = ('a' x 64);
    my $f = Net::Nostr::Filter->new(ids => \@ids);
    push @ids, 'b' x 64;
    is scalar @{$f->ids}, 1, 'filter ids unaffected by caller push';
};

subtest 'accessor mutation of ids does not affect filter' => sub {
    my $f = Net::Nostr::Filter->new(ids => ['a' x 64]);
    my $got = $f->ids;
    push @$got, 'b' x 64;
    is scalar @{$f->ids}, 1, 'filter ids unaffected by accessor mutation';
};

subtest 'caller mutation of authors does not affect filter' => sub {
    my @authors = ('a' x 64);
    my $f = Net::Nostr::Filter->new(authors => \@authors);
    push @authors, 'b' x 64;
    is scalar @{$f->authors}, 1, 'filter authors unaffected';
};

subtest 'accessor mutation of authors does not affect filter' => sub {
    my $f = Net::Nostr::Filter->new(authors => ['a' x 64]);
    my $got = $f->authors;
    push @$got, 'b' x 64;
    is scalar @{$f->authors}, 1, 'filter authors unaffected';
};

subtest 'caller mutation of kinds does not affect filter' => sub {
    my @kinds = (1);
    my $f = Net::Nostr::Filter->new(kinds => \@kinds);
    push @kinds, 2;
    is scalar @{$f->kinds}, 1, 'filter kinds unaffected';
};

subtest 'accessor mutation of kinds does not affect filter' => sub {
    my $f = Net::Nostr::Filter->new(kinds => [1]);
    my $got = $f->kinds;
    push @$got, 2;
    is scalar @{$f->kinds}, 1, 'filter kinds unaffected';
};

subtest 'caller mutation of tag filter does not affect filter' => sub {
    my @tags = ('a' x 64);
    my $f = Net::Nostr::Filter->new('#e' => \@tags);
    push @tags, 'b' x 64;
    is scalar @{$f->tag_filter('e')}, 1, 'tag filter unaffected';
};

subtest 'accessor mutation of tag filter does not affect filter' => sub {
    my $f = Net::Nostr::Filter->new('#e' => ['a' x 64]);
    my $got = $f->tag_filter('e');
    push @$got, 'b' x 64;
    is scalar @{$f->tag_filter('e')}, 1, 'tag filter unaffected';
};

subtest 'to_hash returns copies of list fields' => sub {
    my $f = Net::Nostr::Filter->new(ids => ['a' x 64], '#e' => ['b' x 64]);
    my $h = $f->to_hash;
    push @{$h->{ids}}, 'c' x 64;
    push @{$h->{'#e'}}, 'd' x 64;
    is scalar @{$f->ids}, 1, 'ids unaffected by to_hash mutation';
    is scalar @{$f->tag_filter('e')}, 1, 'tag filter unaffected by to_hash mutation';
};

###############################################################################
# Hash set optimization: ids, authors, kinds use O(1) lookup internally
###############################################################################

subtest 'ids hash set: multiple ids, match and miss' => sub {
    my $id1 = 'aa' x 32;
    my $id2 = 'bb' x 32;
    my $e1 = Net::Nostr::Event->new(pubkey => 'cc' x 32, kind => 1, content => '', created_at => 1, tags => []);
    my $e2 = Net::Nostr::Event->new(pubkey => 'cc' x 32, kind => 1, content => 'x', created_at => 2, tags => []);
    my $filter = Net::Nostr::Filter->new(ids => [$id1, $id2, $e1->id]);
    ok($filter->matches($e1), 'event whose id is in the set matches');
    ok(!$filter->matches($e2), 'event whose id is not in the set does not match');
};

subtest 'authors hash set: multiple authors, match and miss' => sub {
    my $pk1 = 'aa' x 32;
    my $pk2 = 'bb' x 32;
    my $pk3 = 'cc' x 32;
    my $e_match = Net::Nostr::Event->new(pubkey => $pk2, kind => 1, content => '', created_at => 1, tags => []);
    my $e_miss  = Net::Nostr::Event->new(pubkey => $pk3, kind => 1, content => '', created_at => 2, tags => []);
    my $filter = Net::Nostr::Filter->new(authors => [$pk1, $pk2]);
    ok($filter->matches($e_match), 'event with matching pubkey passes');
    ok(!$filter->matches($e_miss), 'event with non-matching pubkey rejected');
};

subtest 'kinds hash set: multiple kinds, match and miss' => sub {
    my $e_k1 = Net::Nostr::Event->new(pubkey => 'aa' x 32, kind => 1, content => '', created_at => 1, tags => []);
    my $e_k3 = Net::Nostr::Event->new(pubkey => 'aa' x 32, kind => 3, content => '', created_at => 2, tags => []);
    my $e_k5 = Net::Nostr::Event->new(pubkey => 'aa' x 32, kind => 5, content => '', created_at => 3, tags => []);
    my $filter = Net::Nostr::Filter->new(kinds => [1, 3, 7]);
    ok($filter->matches($e_k1), 'kind 1 matches');
    ok($filter->matches($e_k3), 'kind 3 matches');
    ok(!$filter->matches($e_k5), 'kind 5 not in set, rejected');
};

subtest 'kinds hash set: numeric comparison (kind 0)' => sub {
    my $e = Net::Nostr::Event->new(pubkey => 'aa' x 32, kind => 0, content => '', created_at => 1, tags => []);
    my $filter = Net::Nostr::Filter->new(kinds => [0]);
    ok($filter->matches($e), 'kind 0 matches via hash set');
};

###############################################################################
# Pre-parsed search terms optimization
###############################################################################

subtest 'pre-parsed search: basic term matching' => sub {
    my $filter = Net::Nostr::Filter->new(search => 'hello world');
    my $e_match = Net::Nostr::Event->new(
        pubkey => 'aa' x 32, kind => 1, content => 'hello beautiful world',
        created_at => 1, tags => [],
    );
    my $e_miss = Net::Nostr::Event->new(
        pubkey => 'aa' x 32, kind => 1, content => 'hello there',
        created_at => 2, tags => [],
    );
    ok($filter->matches($e_match), 'both terms found');
    ok(!$filter->matches($e_miss), 'missing term rejected');
};

subtest 'pre-parsed search: case-insensitive' => sub {
    my $filter = Net::Nostr::Filter->new(search => 'NOSTR');
    my $e = Net::Nostr::Event->new(
        pubkey => 'aa' x 32, kind => 1, content => 'Best nostr apps',
        created_at => 1, tags => [],
    );
    ok($filter->matches($e), 'case-insensitive match works');
};

subtest 'pre-parsed search: extensions are excluded from term matching' => sub {
    my $filter = Net::Nostr::Filter->new(search => 'nostr language:en');
    my $e = Net::Nostr::Event->new(
        pubkey => 'aa' x 32, kind => 1, content => 'nostr is great',
        created_at => 1, tags => [],
    );
    # "language:en" is an extension, not a search term — should not be required in content
    ok($filter->matches($e), 'extension not required in content');
};

subtest 'pre-parsed search: only extensions, no plain terms' => sub {
    my $filter = Net::Nostr::Filter->new(search => 'language:en nsfw:false');
    my $e = Net::Nostr::Event->new(
        pubkey => 'aa' x 32, kind => 1, content => 'anything',
        created_at => 1, tags => [],
    );
    ok($filter->matches($e), 'filter with only extensions matches any content');
};

subtest 'pre-parsed search: empty search string' => sub {
    my $filter = Net::Nostr::Filter->new(search => '');
    my $e = Net::Nostr::Event->new(
        pubkey => 'aa' x 32, kind => 1, content => 'anything',
        created_at => 1, tags => [],
    );
    ok($filter->matches($e), 'empty search matches everything');
};

###############################################################################
# Tag matching hash set optimization
###############################################################################

subtest 'tag hash set: multiple filter values, one matches' => sub {
    my $e = Net::Nostr::Event->new(
        pubkey => 'aa' x 32, kind => 1, content => '', created_at => 1,
        tags => [['t', 'bitcoin']],
    );
    my $filter = Net::Nostr::Filter->new('#t' => ['nostr', 'bitcoin', 'lightning']);
    ok($filter->matches($e), 'event tag value found in filter value set');
};

subtest 'tag hash set: multiple event tags, one matches' => sub {
    my $e = Net::Nostr::Event->new(
        pubkey => 'aa' x 32, kind => 1, content => '', created_at => 1,
        tags => [['t', 'rust'], ['t', 'perl'], ['t', 'python']],
    );
    my $filter = Net::Nostr::Filter->new('#t' => ['perl']);
    ok($filter->matches($e), 'one of multiple event tags matches');
};

subtest 'tag hash set: no overlap rejects' => sub {
    my $e = Net::Nostr::Event->new(
        pubkey => 'aa' x 32, kind => 1, content => '', created_at => 1,
        tags => [['t', 'rust'], ['t', 'go']],
    );
    my $filter = Net::Nostr::Filter->new('#t' => ['perl', 'python']);
    ok(!$filter->matches($e), 'no overlap between event tags and filter values');
};

subtest 'tag hash set: multiple tag letters, all must match (AND)' => sub {
    my $eid = 'dd' x 32;
    my $e = Net::Nostr::Event->new(
        pubkey => 'aa' x 32, kind => 1, content => '', created_at => 1,
        tags => [['e', $eid], ['t', 'nostr']],
    );
    my $filter = Net::Nostr::Filter->new('#e' => [$eid], '#t' => ['nostr']);
    ok($filter->matches($e), 'both tag filters match');

    my $filter_miss = Net::Nostr::Filter->new('#e' => [$eid], '#t' => ['bitcoin']);
    ok(!$filter_miss->matches($e), 'one tag filter misses => rejected');
};

subtest 'tag hash set: large number of filter values' => sub {
    my @vals = map { "val_$_" } 1..100;
    my $e = Net::Nostr::Event->new(
        pubkey => 'aa' x 32, kind => 1, content => '', created_at => 1,
        tags => [['t', 'val_50']],
    );
    my $filter = Net::Nostr::Filter->new('#t' => \@vals);
    ok($filter->matches($e), 'match found in large filter value set');

    my $e_miss = Net::Nostr::Event->new(
        pubkey => 'aa' x 32, kind => 1, content => '', created_at => 2,
        tags => [['t', 'val_999']],
    );
    ok(!$filter->matches($e_miss), 'miss in large filter value set');
};

subtest 'tag hash set: large number of event tags' => sub {
    my @tags = map { ['t', "tag_$_"] } 1..100;
    my $e = Net::Nostr::Event->new(
        pubkey => 'aa' x 32, kind => 1, content => '', created_at => 1,
        tags => \@tags,
    );
    my $filter = Net::Nostr::Filter->new('#t' => ['tag_100']);
    ok($filter->matches($e), 'match found with many event tags');

    my $filter_miss = Net::Nostr::Filter->new('#t' => ['tag_999']);
    ok(!$filter_miss->matches($e), 'miss with many event tags');
};

done_testing;
