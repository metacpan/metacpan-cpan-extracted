#!/usr/bin/perl

# NIP-40: Expiration Timestamp
# https://github.com/nostr-protocol/nips/blob/master/40.md

use strictures 2;

use Test2::V0 -no_srand => 1;
use AnyEvent;
use IO::Socket::INET;

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Event;
use Net::Nostr::Filter;
use Net::Nostr::Client;
use Net::Nostr::Relay;

my $alice_pk = 'a' x 64;

###############################################################################
# "The expiration tag enables users to specify a unix timestamp"
###############################################################################

subtest 'expiration tag on an event' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 1, content => 'temp',
        tags => [['expiration', '1600000000']],
    );
    my @exp = grep { $_->[0] eq 'expiration' } @{$event->tags};
    is scalar @exp, 1, 'one expiration tag';
    is $exp[0][1], '1600000000', 'expiration value is unix timestamp string';
};

###############################################################################
# Event: expiration accessor
###############################################################################

subtest 'expiration accessor returns timestamp' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 1, content => 'temp',
        tags => [['expiration', '1600000000']],
    );
    is $event->expiration, 1600000000, 'expiration returns numeric timestamp';
};

subtest 'expiration returns undef when no tag' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 1, content => 'no expiry',
    );
    ok !defined($event->expiration), 'expiration is undef';
};

###############################################################################
# Event: is_expired
###############################################################################

subtest 'is_expired returns true for past timestamp' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 1, content => 'old',
        tags => [['expiration', '1000000000']],
    );
    ok $event->is_expired, 'event with past expiration is expired';
};

subtest 'is_expired returns false for future timestamp' => sub {
    my $far_future = time() + 86400 * 365 * 10;
    my $event = make_event(
        pubkey => $alice_pk, kind => 1, content => 'future',
        tags => [['expiration', "$far_future"]],
    );
    ok !$event->is_expired, 'event with future expiration is not expired';
};

subtest 'is_expired returns false when no expiration tag' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 1, content => 'permanent',
    );
    ok !$event->is_expired, 'event without expiration is not expired';
};

subtest 'is_expired accepts custom time argument' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 1, content => 'temp',
        tags => [['expiration', '1600000000']],
    );
    ok $event->is_expired(1600000001), 'expired when now > expiration';
    ok !$event->is_expired(1500000000), 'not expired when now < expiration';
};

###############################################################################
# Spec JSON example
###############################################################################

subtest 'spec JSON example' => sub {
    my $event = make_event(
        pubkey     => $alice_pk,
        created_at => 1000000000,
        kind       => 1,
        content    => "This message will expire at the specified timestamp and be deleted by relays.\n",
        tags       => [['expiration', '1600000000']],
    );
    is $event->kind, 1, 'kind 1';
    is $event->created_at, 1000000000, 'created_at matches spec';
    is $event->expiration, 1600000000, 'expiration matches spec';
    is $event->content, "This message will expire at the specified timestamp and be deleted by relays.\n", 'content matches spec';
};

###############################################################################
# Relay: "Relays SHOULD drop any events that are published to them if they
#         are expired"
###############################################################################

subtest 'relay rejects expired events on publish' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $expired = make_event(
        pubkey => $alice_pk, kind => 1,
        content => 'old news', sig => 'a' x 128,
        tags => [['expiration', '1000000000']],
    );

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my ($accepted, $ok_msg);
    $client->on(ok => sub {
        my ($event_id, $acc, $msg) = @_;
        $accepted = $acc;
        $ok_msg = $msg;
        $cv->send;
    });

    $client->connect("ws://127.0.0.1:$port");
    $client->publish($expired);

    $cv->recv;

    ok !$accepted, 'relay rejects expired event';
    like $ok_msg, qr/expir/i, 'rejection message mentions expiration';

    $client->disconnect;
    $relay->stop;
};

subtest 'relay accepts non-expired events' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $far_future = time() + 86400 * 365 * 10;
    my $event = make_event(
        pubkey => $alice_pk, kind => 1,
        content => 'still fresh', sig => 'a' x 128,
        tags => [['expiration', "$far_future"]],
    );

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my $accepted;
    $client->on(ok => sub {
        my ($event_id, $acc, $msg) = @_;
        $accepted = $acc;
        $cv->send;
    });

    $client->connect("ws://127.0.0.1:$port");
    $client->publish($event);

    $cv->recv;

    ok $accepted, 'relay accepts non-expired event';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# Relay: "Relays SHOULD NOT send expired events to clients, even if they
#         are stored"
###############################################################################

subtest 'relay does not return expired events in queries' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    # Manually store an event that has since expired
    my $expired = make_event(
        pubkey => $alice_pk, kind => 1,
        content => 'expired now', sig => 'a' x 128,
        tags => [['expiration', '1000000000']],
    );
    $relay->inject_event($expired);

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my @events;
    $client->on(event => sub {
        my ($sub_id, $event) = @_;
        push @events, $event;
    });
    $client->on(eose => sub { $cv->send });

    $client->connect("ws://127.0.0.1:$port");
    $client->subscribe('q', Net::Nostr::Filter->new(kinds => [1], authors => [$alice_pk]));

    $cv->recv;

    is scalar @events, 0, 'expired event not returned to client';

    $client->disconnect;
    $relay->stop;
};

subtest 'relay does not broadcast expired events' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    # Manually inject an expired event that was stored before it expired
    my $expired = make_event(
        pubkey => $alice_pk, kind => 1,
        content => 'will expire', sig => 'a' x 128,
        tags => [['expiration', '1000000000']],
    );

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 2, cb => sub { $cv->send });

    my @events;
    $client->on(event => sub {
        my ($sub_id, $event) = @_;
        push @events, $event;
    });

    $client->connect("ws://127.0.0.1:$port");
    $client->subscribe('q', Net::Nostr::Filter->new(kinds => [1], authors => [$alice_pk]));

    # Wait for subscription to be set up, then broadcast
    my $setup; $setup = AnyEvent->timer(after => 0.5, cb => sub {
        undef $setup;
        $relay->broadcast($expired);
    });

    $cv->recv;

    is scalar @events, 0, 'expired event not broadcast to subscribers';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# "An expiration timestamp does not affect storage of ephemeral events"
###############################################################################

subtest 'expiration does not affect ephemeral event handling' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $far_future = time() + 86400 * 365 * 10;
    my $ephemeral = make_event(
        pubkey => $alice_pk, kind => 20001,
        content => 'ephemeral with expiry', sig => 'a' x 128,
        tags => [['expiration', "$far_future"]],
    );

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my $accepted;
    $client->on(ok => sub {
        my ($event_id, $acc, $msg) = @_;
        $accepted = $acc;
        $cv->send;
    });

    $client->connect("ws://127.0.0.1:$port");
    $client->publish($ephemeral);

    $cv->recv;

    ok $accepted, 'ephemeral event with expiration is accepted';
    is scalar @{$relay->events}, 0, 'ephemeral event still not stored (as per NIP-01)';

    $client->disconnect;
    $relay->stop;
};

subtest 'expired ephemeral event is still accepted and broadcast' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $expired_ephemeral = make_event(
        pubkey => $alice_pk, kind => 20001,
        content => 'expired ephemeral', sig => 'a' x 128,
        tags => [['expiration', '1000000000']],
    );

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my $accepted;
    $client->on(ok => sub {
        my ($event_id, $acc, $msg) = @_;
        $accepted = $acc;
        $cv->send;
    });

    $client->connect("ws://127.0.0.1:$port");
    $client->publish($expired_ephemeral);

    $cv->recv;

    ok $accepted, 'expired ephemeral event is accepted (expiration does not affect ephemeral)';
    is scalar @{$relay->events}, 0, 'ephemeral event not stored';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# Events without expiration tag are unaffected
###############################################################################

subtest 'events without expiration are unaffected by relay filtering' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $normal = make_event(
        pubkey => $alice_pk, kind => 1,
        content => 'permanent note', sig => 'a' x 128,
    );

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my @events;
    my $accepted;
    $client->on(ok => sub {
        my ($event_id, $acc, $msg) = @_;
        $accepted = $acc;
        $client->subscribe('q', Net::Nostr::Filter->new(kinds => [1], authors => [$alice_pk]));
    });
    $client->on(event => sub {
        my ($sub_id, $event) = @_;
        push @events, $event;
    });
    $client->on(eose => sub { $cv->send });

    $client->connect("ws://127.0.0.1:$port");
    $client->publish($normal);

    $cv->recv;

    ok $accepted, 'normal event accepted';
    is scalar @events, 1, 'normal event returned in query';

    $client->disconnect;
    $relay->stop;
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
