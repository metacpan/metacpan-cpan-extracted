#!/usr/bin/perl

use strictures 2;

use Test2::V0 -no_srand => 1;

use Net::Nostr::FollowList;
use Net::Nostr::Event;

###############################################################################
# Construction
###############################################################################

subtest 'new creates an empty follow list' => sub {
    my $fl = Net::Nostr::FollowList->new;
    isa_ok($fl, 'Net::Nostr::FollowList');
    is(scalar($fl->follows), 0, 'no follows');
};

###############################################################################
# add / follows
###############################################################################

subtest 'add and retrieve follows' => sub {
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64, relay => 'wss://r.com/', petname => 'alice');
    my @follows = $fl->follows;
    is(scalar @follows, 1, 'one follow');
    is($follows[0]{pubkey}, 'a' x 64, 'pubkey');
    is($follows[0]{relay}, 'wss://r.com/', 'relay');
    is($follows[0]{petname}, 'alice', 'petname');
};

subtest 'add with defaults' => sub {
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64);
    my @follows = $fl->follows;
    is($follows[0]{relay}, '', 'relay defaults to empty');
    is($follows[0]{petname}, '', 'petname defaults to empty');
};

###############################################################################
# remove
###############################################################################

subtest 'remove by pubkey' => sub {
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64);
    $fl->add('b' x 64);
    $fl->remove('a' x 64);
    my @follows = $fl->follows;
    is(scalar @follows, 1, 'one remains');
    is($follows[0]{pubkey}, 'b' x 64, 'correct one remains');
};

subtest 'remove nonexistent pubkey is a no-op' => sub {
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64);
    $fl->remove('b' x 64);
    is(scalar($fl->follows), 1, 'still one follow');
};

###############################################################################
# contains
###############################################################################

subtest 'contains' => sub {
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64);
    ok($fl->contains('a' x 64), 'true for present');
    ok(!$fl->contains('b' x 64), 'false for absent');
};

###############################################################################
# count
###############################################################################

subtest 'count' => sub {
    my $fl = Net::Nostr::FollowList->new;
    is($fl->count, 0, 'empty');
    $fl->add('a' x 64);
    is($fl->count, 1, 'one');
    $fl->add('b' x 64);
    is($fl->count, 2, 'two');
    $fl->remove('a' x 64);
    is($fl->count, 1, 'back to one');
};

###############################################################################
# Duplicate handling
###############################################################################

subtest 'add same pubkey replaces entry in place' => sub {
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64, petname => 'old');
    $fl->add('b' x 64, petname => 'bob');
    $fl->add('a' x 64, petname => 'new');
    my @follows = $fl->follows;
    is(scalar @follows, 2, 'still two entries');
    # replaced in place, not moved to end
    is($follows[0]{petname}, 'new', 'first entry updated');
    is($follows[1]{petname}, 'bob', 'second entry unchanged');
};

###############################################################################
# Validation
###############################################################################

subtest 'add validates pubkey format' => sub {
    my $fl = Net::Nostr::FollowList->new;
    ok(dies { $fl->add('short') }, 'rejects short string');
    ok(dies { $fl->add('G' x 64) }, 'rejects non-hex');
    ok(dies { $fl->add('a' x 65) }, 'rejects too-long string');
    ok(dies { $fl->add(undef) }, 'rejects undef');
};

###############################################################################
# to_event
###############################################################################

subtest 'to_event produces correct event' => sub {
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64, relay => 'wss://r.com/', petname => 'alice');
    my $event = $fl->to_event(pubkey => 'b' x 64, created_at => 1000);
    isa_ok($event, 'Net::Nostr::Event');
    is($event->kind, 3, 'kind 3');
    is($event->content, '', 'empty content');
    is($event->pubkey, 'b' x 64, 'pubkey passed through');
    is($event->created_at, 1000, 'created_at passed through');
};

subtest 'to_event passes extra args to Event->new' => sub {
    my $fl = Net::Nostr::FollowList->new;
    my $event = $fl->to_event(pubkey => 'a' x 64, sig => 'b' x 128);
    is($event->sig, 'b' x 128, 'sig passed through');
};

###############################################################################
# from_event
###############################################################################

subtest 'from_event round-trips' => sub {
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64, relay => 'wss://r.com/', petname => 'alice');
    $fl->add('b' x 64);

    my $event = $fl->to_event(pubkey => 'c' x 64);
    my $fl2 = Net::Nostr::FollowList->from_event($event);

    is([$fl2->follows], [$fl->follows], 'round-trip preserves data');
};

subtest 'from_event handles missing relay and petname fields' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 3, content => '',
        tags => [['p', 'b' x 64]],
    );
    my $fl = Net::Nostr::FollowList->from_event($event);
    my @follows = $fl->follows;
    is($follows[0]{relay}, '', 'missing relay becomes empty string');
    is($follows[0]{petname}, '', 'missing petname becomes empty string');
};

###############################################################################
# to_tags
###############################################################################

subtest 'to_tags returns tags array' => sub {
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64, relay => 'wss://r.com/', petname => 'alice');
    my $tags = $fl->to_tags;
    is($tags, [['p', 'a' x 64, 'wss://r.com/', 'alice']], 'correct tags');
};

done_testing;
