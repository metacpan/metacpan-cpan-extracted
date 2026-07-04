#!/usr/bin/perl

# Unit tests for Net::Nostr::Deletion

use strictures 2;

use Test2::V0 -no_srand => 1;

use lib 't/lib';
use TestFixtures qw(make_event);
use JSON ();

use Net::Nostr::Deletion;
use Net::Nostr::Event;

my $pubkey   = 'aa' x 32;
my $event_id = 'bb' x 32;
my $other_id = 'cc' x 32;

###############################################################################
# POD SYNOPSIS examples
###############################################################################

subtest 'SYNOPSIS: create a deletion request' => sub {
    my $del = Net::Nostr::Deletion->new(reason => 'posted by accident');
    $del->add_event($event_id, kind => 1);
    $del->add_event($other_id, kind => 1);
    $del->add_address("30023:$pubkey:my-article", kind => 30023);

    my $event = $del->to_event(pubkey => $pubkey);
    is($event->kind, 5, 'kind 5');
    is($event->content, 'posted by accident', 'reason as content');
};

subtest 'SYNOPSIS: parse a received deletion request' => sub {
    my $del = Net::Nostr::Deletion->new(reason => 'test');
    $del->add_event($event_id, kind => 1);
    my $event = $del->to_event(pubkey => $pubkey);

    my $parsed = Net::Nostr::Deletion->from_event($event);
    is($parsed->reason, 'test', 'reason preserved');
    is($parsed->event_ids, [$event_id], 'event_ids preserved');
};

subtest 'SYNOPSIS: applies_to check' => sub {
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($event_id, kind => 1);
    my $del_event = $del->to_event(pubkey => $pubkey);

    my $target = make_event(
        pubkey => $pubkey,
        id     => $event_id,
        kind   => 1,
    );
    my $parsed = Net::Nostr::Deletion->from_event($del_event);
    ok($parsed->applies_to($target, $pubkey), 'deletion applies to target');
};

###############################################################################
# new()
###############################################################################

subtest 'new: default reason is empty string' => sub {
    my $del = Net::Nostr::Deletion->new;
    is($del->reason, '', 'default reason');
};

subtest 'new: accepts reason arg' => sub {
    my $del = Net::Nostr::Deletion->new(reason => 'spam');
    is($del->reason, 'spam', 'reason set');
};

subtest 'new: rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::Deletion->new(bogus => 'value') },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

###############################################################################
# add_event()
###############################################################################

subtest 'add_event: requires kind option' => sub {
    my $del = Net::Nostr::Deletion->new;
    like(
        dies { $del->add_event($event_id) },
        qr/kind/i,
        'dies without kind'
    );
};

subtest 'add_event: rejects bad hex (non-hex chars)' => sub {
    my $del = Net::Nostr::Deletion->new;
    like(
        dies { $del->add_event('zz' x 32, kind => 1) },
        qr/hex/i,
        'non-hex rejected'
    );
};

subtest 'add_event: rejects short id' => sub {
    my $del = Net::Nostr::Deletion->new;
    like(
        dies { $del->add_event('aa' x 31, kind => 1) },
        qr/hex/i,
        'short id rejected'
    );
};

subtest 'add_event: rejects uppercase hex' => sub {
    my $del = Net::Nostr::Deletion->new;
    like(
        dies { $del->add_event('AA' x 32, kind => 1) },
        qr/hex/i,
        'uppercase rejected'
    );
};

subtest 'add_event: returns $self for chaining' => sub {
    my $del = Net::Nostr::Deletion->new;
    my $ret = $del->add_event($event_id, kind => 1);
    ref_is($ret, $del, 'returns self');
};

subtest 'add_event: records kind' => sub {
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($event_id, kind => 7);
    my $event = $del->to_event(pubkey => $pubkey);
    my @k_tags = grep { $_->[0] eq 'k' } @{$event->tags};
    is(\@k_tags, [['k', '7']], 'k tag for kind 7');
};

###############################################################################
# add_address()
###############################################################################

subtest 'add_address: requires kind option' => sub {
    my $del = Net::Nostr::Deletion->new;
    like(
        dies { $del->add_address("30023:$pubkey:slug") },
        qr/kind/i,
        'dies without kind'
    );
};

subtest 'add_address: returns $self for chaining' => sub {
    my $del = Net::Nostr::Deletion->new;
    my $ret = $del->add_address("30023:$pubkey:slug", kind => 30023);
    ref_is($ret, $del, 'returns self');
};

subtest 'add_address: records kind' => sub {
    my $del = Net::Nostr::Deletion->new;
    $del->add_address("30023:$pubkey:slug", kind => 30023);
    my $event = $del->to_event(pubkey => $pubkey);
    my @k_tags = grep { $_->[0] eq 'k' } @{$event->tags};
    is(\@k_tags, [['k', '30023']], 'k tag for kind 30023');
};

###############################################################################
# event_ids() and addresses()
###############################################################################

subtest 'event_ids: returns arrayref' => sub {
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($event_id, kind => 1);
    is(ref $del->event_ids, 'ARRAY', 'arrayref');
    is($del->event_ids, [$event_id], 'correct contents');
};

subtest 'event_ids: returns a copy' => sub {
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($event_id, kind => 1);
    my $ids = $del->event_ids;
    push @$ids, 'extra';
    is($del->event_ids, [$event_id], 'internal state unchanged');
};

subtest 'addresses: returns arrayref' => sub {
    my $del = Net::Nostr::Deletion->new;
    my $addr = "30023:$pubkey:slug";
    $del->add_address($addr, kind => 30023);
    is(ref $del->addresses, 'ARRAY', 'arrayref');
    is($del->addresses, [$addr], 'correct contents');
};

subtest 'addresses: returns a copy' => sub {
    my $del = Net::Nostr::Deletion->new;
    my $addr = "30023:$pubkey:slug";
    $del->add_address($addr, kind => 30023);
    my $addrs = $del->addresses;
    push @$addrs, 'extra';
    is($del->addresses, [$addr], 'internal state unchanged');
};

###############################################################################
# to_event()
###############################################################################

subtest 'to_event: kind is 5' => sub {
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($event_id, kind => 1);
    my $event = $del->to_event(pubkey => $pubkey);
    is($event->kind, 5, 'kind 5');
};

subtest 'to_event: content is reason' => sub {
    my $del = Net::Nostr::Deletion->new(reason => 'oops');
    $del->add_event($event_id, kind => 1);
    my $event = $del->to_event(pubkey => $pubkey);
    is($event->content, 'oops', 'content matches reason');
};

subtest 'to_event: has e, a, and k tags' => sub {
    my $addr = "30023:$pubkey:my-article";
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($event_id, kind => 1);
    $del->add_address($addr, kind => 30023);
    my $event = $del->to_event(pubkey => $pubkey);

    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    my @a_tags = grep { $_->[0] eq 'a' } @{$event->tags};
    my @k_tags = grep { $_->[0] eq 'k' } @{$event->tags};

    is(\@e_tags, [['e', $event_id]], 'e tags');
    is(\@a_tags, [['a', $addr]], 'a tags');
    is(scalar @k_tags, 2, 'two k tags');
};

subtest 'to_event: k tags sorted numerically and stringified' => sub {
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($event_id, kind => 30023);
    $del->add_event($other_id, kind => 1);
    my $event = $del->to_event(pubkey => $pubkey);

    my @k_tags = grep { $_->[0] eq 'k' } @{$event->tags};
    is(\@k_tags, [['k', '1'], ['k', '30023']], 'k tags sorted numerically');
    is(ref $k_tags[0][1], '', 'k value is a string, not a ref');
};

subtest 'to_event: passes through extra args' => sub {
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($event_id, kind => 1);
    my $event = $del->to_event(pubkey => $pubkey, created_at => 1700000000);
    is($event->pubkey, $pubkey, 'pubkey passed through');
    is($event->created_at, 1700000000, 'created_at passed through');
};

###############################################################################
# from_event()
###############################################################################

subtest 'from_event: croaks if not kind 5' => sub {
    my $event = make_event(kind => 1);
    like(
        dies { Net::Nostr::Deletion->from_event($event) },
        qr/kind 5/,
        'not kind 5 rejected'
    );
};

subtest 'from_event: round-trip preserves data' => sub {
    my $addr = "30023:$pubkey:my-article";
    my $del = Net::Nostr::Deletion->new(reason => 'cleanup');
    $del->add_event($event_id, kind => 1);
    $del->add_event($other_id, kind => 7);
    $del->add_address($addr, kind => 30023);

    my $event = $del->to_event(pubkey => $pubkey);
    my $restored = Net::Nostr::Deletion->from_event($event);

    is($restored->reason, 'cleanup', 'reason round-trips');
    is($restored->event_ids, [$event_id, $other_id], 'event_ids round-trip');
    is($restored->addresses, [$addr], 'addresses round-trip');
};

subtest 'from_event: extracts reason, event_ids, addresses' => sub {
    my $event = Net::Nostr::Event->new(
        kind       => 5,
        pubkey     => $pubkey,
        content    => 'bad post',
        tags       => [
            ['e', $event_id],
            ['a', "30023:$pubkey:slug"],
            ['k', '1'],
            ['k', '30023'],
        ],
        created_at => 1700000000,
    );
    my $del = Net::Nostr::Deletion->from_event($event);
    is($del->reason, 'bad post', 'reason');
    is($del->event_ids, [$event_id], 'event_ids');
    is($del->addresses, ["30023:$pubkey:slug"], 'addresses');
};

###############################################################################
# applies_to()
###############################################################################

subtest 'applies_to: true when e tag matches and pubkeys match' => sub {
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($event_id, kind => 1);

    my $target = make_event(
        pubkey => $pubkey,
        id     => $event_id,
        kind   => 1,
    );
    ok($del->applies_to($target, $pubkey), 'applies via e tag');
};

subtest 'applies_to: true for addressable event via a tag' => sub {
    my $addr = "30023:$pubkey:my-article";
    my $del = Net::Nostr::Deletion->new;
    $del->add_address($addr, kind => 30023);

    my $target = make_event(
        pubkey => $pubkey,
        kind   => 30023,
        tags   => [['d', 'my-article']],
        id     => 'dd' x 32,
    );
    ok($del->applies_to($target, $pubkey), 'applies via a tag');
};

subtest 'applies_to: false when pubkeys differ' => sub {
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($event_id, kind => 1);

    my $other_pubkey = 'dd' x 32;
    my $target = make_event(
        pubkey => $other_pubkey,
        id     => $event_id,
        kind   => 1,
    );
    ok(!$del->applies_to($target, $pubkey), 'different pubkeys, no match');
};

subtest 'applies_to: false when id does not match' => sub {
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($event_id, kind => 1);

    my $target = make_event(
        pubkey => $pubkey,
        id     => 'ee' x 32,
        kind   => 1,
    );
    ok(!$del->applies_to($target, $pubkey), 'id mismatch');
};

subtest 'applies_to: false for non-addressable event against a tags' => sub {
    my $addr = "30023:$pubkey:slug";
    my $del = Net::Nostr::Deletion->new;
    $del->add_address($addr, kind => 30023);

    my $target = make_event(
        pubkey => $pubkey,
        id     => 'ff' x 32,
        kind   => 1,
        tags   => [['d', 'slug']],
    );
    ok(!$del->applies_to($target, $pubkey), 'non-addressable event not matched by a tag');
};

###############################################################################
# Chaining
###############################################################################

subtest 'chaining: add_event and add_address chain' => sub {
    my $addr = "30023:$pubkey:article";
    my $del = Net::Nostr::Deletion->new;
    my $ret = $del->add_event($event_id, kind => 1)
                  ->add_event($other_id, kind => 1)
                  ->add_address($addr, kind => 30023);

    ref_is($ret, $del, 'chained calls return self');
    is($del->event_ids, [$event_id, $other_id], 'both events added');
    is($del->addresses, [$addr], 'address added');
};

###############################################################################
# POD method examples
###############################################################################

subtest 'POD: new() no args' => sub {
    my $del = Net::Nostr::Deletion->new;
    is($del->reason, '', 'empty reason');
};

subtest 'POD: new() with reason' => sub {
    my $del = Net::Nostr::Deletion->new(reason => 'posted by accident');
    is($del->reason, 'posted by accident', 'reason set');
};

subtest 'POD: add_event chaining example' => sub {
    my $id1 = 'aa' x 32;
    my $id2 = 'bb' x 32;
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($id1, kind => 1)
        ->add_event($id2, kind => 1);
    is($del->event_ids, [$id1, $id2], 'both events via chaining');
};

subtest 'POD: to_event with created_at' => sub {
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($event_id, kind => 1);
    my $event = $del->to_event(pubkey => $pubkey, created_at => time());
    is($event->kind, 5, 'kind 5');
    ok($event->created_at, 'created_at set');
};

subtest 'POD: applies_to example' => sub {
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($event_id, kind => 1);

    my $target = make_event(
        pubkey => $pubkey,
        id     => $event_id,
        kind   => 1,
    );
    if ($del->applies_to($target, $pubkey)) {
        pass('event should be hidden/deleted');
    } else {
        fail('applies_to should have returned true');
    }
};

subtest 'POD: from_event iteration example' => sub {
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($event_id, kind => 1);
    $del->add_event($other_id, kind => 1);
    my $event = $del->to_event(pubkey => $pubkey);

    my $parsed = Net::Nostr::Deletion->from_event($event);
    my @collected;
    for my $id (@{$parsed->event_ids}) {
        push @collected, $id;
    }
    is(\@collected, [$event_id, $other_id], 'iteration works');
};

###############################################################################
# from_event skips short tags
###############################################################################

subtest 'from_event skips tags with missing value' => sub {
    my $pubkey = 'aa' x 32;
    my $event = Net::Nostr::Event->new(
        pubkey  => $pubkey,
        kind    => 5,
        content => '',
        tags    => [['e'], ['a'], ['k'], ['e', 'bb' x 32]],
    );
    my $del = Net::Nostr::Deletion->from_event($event);
    is($del->event_ids, ['bb' x 32], 'only well-formed e tag collected');
    is($del->addresses, [], 'no addresses from short a tag');
};

done_testing;
