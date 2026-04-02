#!/usr/bin/perl

# NIP-02: Follow List
# https://github.com/nostr-protocol/nips/blob/master/02.md

use strictures 2;

use Test2::V0 -no_srand => 1;
use JSON;
use AnyEvent;
use IO::Socket::INET;

use Net::Nostr::Event;
use Net::Nostr::Filter;
use Net::Nostr::FollowList;
use Net::Nostr::Key;
use Net::Nostr::Client;
use Net::Nostr::Relay;

###############################################################################
# Follow list is a kind 3 event
###############################################################################

subtest 'follow list produces a kind 3 event' => sub {
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64);
    my $event = $fl->to_event(pubkey => 'b' x 64);
    is($event->kind, 3, 'kind is 3');
    isa_ok($event, 'Net::Nostr::Event');
};

###############################################################################
# Tags are ["p", <hex key>, <relay URL>, <petname>]
###############################################################################

subtest 'follow entries have p tag with key, relay URL, and petname' => sub {
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64, relay => 'wss://relay.example.com/', petname => 'alice');
    my $event = $fl->to_event(pubkey => 'b' x 64);
    is($event->tags, [
        ['p', 'a' x 64, 'wss://relay.example.com/', 'alice'],
    ], 'p tag has all three fields');
};

subtest 'relay URL and petname default to empty string' => sub {
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64);
    my $event = $fl->to_event(pubkey => 'b' x 64);
    is($event->tags, [
        ['p', 'a' x 64, '', ''],
    ], 'defaults to empty strings');
};

subtest 'relay URL without petname sets petname to empty string' => sub {
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64, relay => 'wss://relay.example.com/');
    my $event = $fl->to_event(pubkey => 'b' x 64);
    is($event->tags, [
        ['p', 'a' x 64, 'wss://relay.example.com/', ''],
    ], 'petname defaults to empty');
};

subtest 'petname without relay URL sets relay to empty string' => sub {
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64, petname => 'alice');
    my $event = $fl->to_event(pubkey => 'b' x 64);
    is($event->tags, [
        ['p', 'a' x 64, '', 'alice'],
    ], 'relay defaults to empty');
};

###############################################################################
# Content is not used
###############################################################################

subtest 'follow list event has empty content' => sub {
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64);
    my $event = $fl->to_event(pubkey => 'b' x 64);
    is($event->content, '', 'content is empty string');
};

###############################################################################
# Parse from existing kind 3 event
###############################################################################

subtest 'from_event parses a kind 3 event' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => 'b' x 64, kind => 3, content => '',
        tags => [
            ['p', 'a' x 64, 'wss://alicerelay.com/', 'alice'],
            ['p', 'c' x 64, 'wss://bobrelay.com/', 'bob'],
            ['p', 'd' x 64, '', ''],
        ],
    );
    my $fl = Net::Nostr::FollowList->from_event($event);
    my @follows = $fl->follows;
    is(scalar @follows, 3, 'three follows parsed');
    is($follows[0], { pubkey => 'a' x 64, relay => 'wss://alicerelay.com/', petname => 'alice' }, 'first follow');
    is($follows[1], { pubkey => 'c' x 64, relay => 'wss://bobrelay.com/', petname => 'bob' }, 'second follow');
    is($follows[2], { pubkey => 'd' x 64, relay => '', petname => '' }, 'third follow');
};

subtest 'from_event ignores non-p tags' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => 'b' x 64, kind => 3, content => '',
        tags => [
            ['p', 'a' x 64, '', ''],
            ['e', 'f' x 64],
            ['p', 'c' x 64, '', ''],
        ],
    );
    my $fl = Net::Nostr::FollowList->from_event($event);
    is(scalar($fl->follows), 2, 'only p tags parsed');
};

subtest 'from_event croaks on non-kind-3 event' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => 'b' x 64, kind => 1, content => 'hello',
    );
    ok(dies { Net::Nostr::FollowList->from_event($event) }, 'croaks on kind 1');
};

###############################################################################
# New follow list overwrites past ones (replaceable kind 3)
###############################################################################

subtest 'kind 3 is replaceable: new list overwrites old on relay' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $pubkey = 'a' x 64;

    # Publish first follow list
    my $fl1 = Net::Nostr::FollowList->new;
    $fl1->add('b' x 64, petname => 'bob');
    my $e1 = $fl1->to_event(pubkey => $pubkey, created_at => 1000, sig => 'a' x 128);

    # Publish second follow list (newer)
    my $fl2 = Net::Nostr::FollowList->new;
    $fl2->add('b' x 64, petname => 'bob');
    $fl2->add('c' x 64, petname => 'carol');
    my $e2 = $fl2->to_event(pubkey => $pubkey, created_at => 2000, sig => 'a' x 128);

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my @events;
    my $ok_count = 0;

    $client->on(ok => sub {
        $ok_count++;
        if ($ok_count == 2) {
            $client->subscribe('fl', Net::Nostr::Filter->new(kinds => [3], authors => [$pubkey]));
        }
    });

    $client->on(event => sub {
        my ($sub_id, $event) = @_;
        push @events, $event;
    });

    $client->on(eose => sub { $cv->send });

    $client->connect("ws://127.0.0.1:$port");
    $client->publish($e1);
    $client->publish($e2);

    $cv->recv;

    is(scalar @events, 1, 'relay returns only one kind 3 event');
    is($events[0]->created_at, 2000, 'relay returns the latest version');

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# New follows appended to end (chronological order)
###############################################################################

subtest 'new follows are appended to end of list' => sub {
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64, petname => 'alice');
    $fl->add('b' x 64, petname => 'bob');
    $fl->add('c' x 64, petname => 'carol');

    my @follows = $fl->follows;
    is($follows[0]{petname}, 'alice', 'alice first');
    is($follows[1]{petname}, 'bob', 'bob second');
    is($follows[2]{petname}, 'carol', 'carol third');
};

###############################################################################
# Pubkey validation
###############################################################################

subtest 'add croaks on invalid pubkey' => sub {
    my $fl = Net::Nostr::FollowList->new;
    ok(dies { $fl->add('not-hex') }, 'rejects non-hex pubkey');
    ok(dies { $fl->add('a' x 63) }, 'rejects too-short pubkey');
    ok(dies { $fl->add('A' x 64) }, 'rejects uppercase hex');
};

###############################################################################
# Remove and contains
###############################################################################

subtest 'remove a follow' => sub {
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64, petname => 'alice');
    $fl->add('b' x 64, petname => 'bob');
    $fl->remove('a' x 64);
    my @follows = $fl->follows;
    is(scalar @follows, 1, 'one follow remains');
    is($follows[0]{pubkey}, 'b' x 64, 'bob remains');
};

subtest 'contains checks for pubkey' => sub {
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64);
    ok($fl->contains('a' x 64), 'contains returns true for added pubkey');
    ok(!$fl->contains('b' x 64), 'contains returns false for absent pubkey');
};

###############################################################################
# Duplicate add replaces existing entry
###############################################################################

subtest 'adding same pubkey twice updates the entry' => sub {
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64, petname => 'alice');
    $fl->add('a' x 64, petname => 'alice-updated', relay => 'wss://new.relay/');
    my @follows = $fl->follows;
    is(scalar @follows, 1, 'still one entry');
    is($follows[0]{petname}, 'alice-updated', 'petname updated');
    is($follows[0]{relay}, 'wss://new.relay/', 'relay updated');
};

###############################################################################
# Round-trip: FollowList -> Event -> FollowList
###############################################################################

subtest 'round-trip through event preserves data' => sub {
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('a' x 64, relay => 'wss://r1.com/', petname => 'alice');
    $fl->add('b' x 64, relay => 'wss://r2.com/', petname => 'bob');

    my $event = $fl->to_event(pubkey => 'c' x 64);
    my $fl2 = Net::Nostr::FollowList->from_event($event);

    is([$fl2->follows], [$fl->follows], 'data survives round-trip');
};

###############################################################################
# Signed follow list via Key
###############################################################################

subtest 'create signed follow list event with Key' => sub {
    my $key = Net::Nostr::Key->new;
    my $fl = Net::Nostr::FollowList->new;
    $fl->add('d' x 64, petname => 'dave');

    my $event = $fl->to_event(pubkey => $key->pubkey_hex);
    $key->sign_event($event);

    ok($event->verify_sig($key), 'signature is valid');
    is($event->kind, 3, 'kind is 3');
    is(scalar @{$event->tags}, 1, 'one p tag');
};

###############################################################################
# Match follow list from spec example
###############################################################################

subtest 'spec example follow list' => sub {
    my $fl = Net::Nostr::FollowList->new;
    # shortened pubkeys in spec example — use full 64-char hex for our test
    my $alice_pk = 'a' x 64;
    my $bob_pk   = 'b' x 64;
    my $carol_pk = 'c' x 64;

    $fl->add($alice_pk, relay => 'wss://alicerelay.com/', petname => 'alice');
    $fl->add($bob_pk,   relay => 'wss://bobrelay.com/nostr', petname => 'bob');
    $fl->add($carol_pk, relay => 'ws://carolrelay.com/ws', petname => 'carol');

    my $event = $fl->to_event(pubkey => 'd' x 64);
    is($event->kind, 3, 'kind 3');
    is($event->content, '', 'empty content');
    is($event->tags, [
        ['p', $alice_pk, 'wss://alicerelay.com/', 'alice'],
        ['p', $bob_pk,   'wss://bobrelay.com/nostr', 'bob'],
        ['p', $carol_pk, 'ws://carolrelay.com/ws', 'carol'],
    ], 'tags match spec example format');
};

###############################################################################
# Empty follow list
###############################################################################

subtest 'empty follow list produces kind 3 with no tags' => sub {
    my $fl = Net::Nostr::FollowList->new;
    my $event = $fl->to_event(pubkey => 'a' x 64);
    is($event->kind, 3, 'kind 3');
    is($event->tags, [], 'no tags');
    is($event->content, '', 'empty content');
};

###############################################################################
# Helpers
###############################################################################

sub free_port {
    my $sock = IO::Socket::INET->new(
        Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0,
    );
    my $port = $sock->sockport;
    close $sock;
    return $port;
}

done_testing;
