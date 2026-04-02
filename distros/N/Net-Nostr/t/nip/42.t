#!/usr/bin/perl

# NIP-42: Authentication of clients to relays
# https://github.com/nostr-protocol/nips/blob/master/42.md

use strictures 2;

use Test2::V0 -no_srand => 1;
use AnyEvent;
use IO::Socket::INET;
use JSON;

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Event;
use Net::Nostr::Message;
use Net::Nostr::Client;
use Net::Nostr::Relay;
use Net::Nostr::Key;

my $alice_pk = 'a' x 64;

###############################################################################
# AUTH message type - relay to client: ["AUTH", <challenge>]
###############################################################################

subtest 'AUTH message relay-to-client (challenge)' => sub {
    my $msg = Net::Nostr::Message->new(
        type      => 'AUTH',
        challenge => 'random-challenge-string',
    );
    is $msg->type, 'AUTH', 'type is AUTH';
    is $msg->challenge, 'random-challenge-string', 'challenge stored';

    my $json = $msg->serialize;
    my $arr = JSON::decode_json($json);
    is $arr->[0], 'AUTH', 'serialized type is AUTH';
    is $arr->[1], 'random-challenge-string', 'serialized challenge';
    is scalar @$arr, 2, 'relay AUTH has 2 elements';
};

subtest 'parse AUTH challenge from relay' => sub {
    my $msg = Net::Nostr::Message->parse('["AUTH","my-challenge-123"]');
    is $msg->type, 'AUTH', 'parsed type is AUTH';
    is $msg->challenge, 'my-challenge-123', 'parsed challenge';
};

###############################################################################
# AUTH message type - client to relay: ["AUTH", <signed-event>]
###############################################################################

subtest 'AUTH message client-to-relay (signed event)' => sub {
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 22242,
        content => '',
        tags    => [
            ['relay', 'wss://relay.example.com/'],
            ['challenge', 'challenge-string-here'],
        ],
    );
    my $msg = Net::Nostr::Message->new(type => 'AUTH', event => $event);
    is $msg->type, 'AUTH', 'type is AUTH';
    is $msg->event->kind, 22242, 'event kind is 22242';

    my $json = $msg->serialize;
    my $arr = JSON::decode_json($json);
    is $arr->[0], 'AUTH', 'serialized type is AUTH';
    is ref($arr->[1]), 'HASH', 'second element is event object';
    is $arr->[1]{kind}, 22242, 'serialized event kind';
};

subtest 'parse AUTH event from client' => sub {
    my $event_hash = {
        id         => '0' x 64,
        pubkey     => $alice_pk,
        created_at => time(),
        kind       => 22242,
        tags       => [
            ['relay', 'wss://relay.example.com/'],
            ['challenge', 'test-challenge'],
        ],
        content    => '',
        sig        => '0' x 128,
    };
    my $json = JSON->new->utf8->encode(['AUTH', $event_hash]);
    my $msg = Net::Nostr::Message->parse($json);
    is $msg->type, 'AUTH', 'parsed type is AUTH';
    is $msg->event->kind, 22242, 'parsed event kind';
};

###############################################################################
# AUTH event is kind 22242
###############################################################################

subtest 'AUTH event must be kind 22242' => sub {
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 22242,
        content => '',
        tags    => [
            ['relay', 'wss://relay.example.com/'],
            ['challenge', 'test'],
        ],
    );
    is $event->kind, 22242, 'auth event kind is 22242';
};

###############################################################################
# AUTH event has relay and challenge tags
###############################################################################

subtest 'AUTH event has relay and challenge tags' => sub {
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 22242,
        content => '',
        tags    => [
            ['relay', 'wss://relay.example.com/'],
            ['challenge', 'my-challenge'],
        ],
    );
    my @relay_tags = grep { $_->[0] eq 'relay' } @{$event->tags};
    my @chal_tags  = grep { $_->[0] eq 'challenge' } @{$event->tags};
    is scalar @relay_tags, 1, 'has relay tag';
    is $relay_tags[0][1], 'wss://relay.example.com/', 'relay URL correct';
    is scalar @chal_tags, 1, 'has challenge tag';
    is $chal_tags[0][1], 'my-challenge', 'challenge value correct';
};

###############################################################################
# Integration: relay sends AUTH challenge, client authenticates
###############################################################################

my $port;
{
    my $sock = IO::Socket::INET->new(
        Listen    => 1,
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
    );
    $port = $sock->sockport;
    close $sock;
}

subtest 'relay sends AUTH challenge on connection' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;
    my $got_challenge;
    $client->on(auth => sub {
        my ($challenge) = @_;
        $got_challenge = $challenge;
    });
    $client->connect("ws://127.0.0.1:$port");

    # Wait for challenge
    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    ok defined($got_challenge), 'client received AUTH challenge';
    ok length($got_challenge) > 0, 'challenge is non-empty';

    $client->disconnect;
    $relay->stop;
};

subtest 'client authenticates with relay' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $key = Net::Nostr::Key->new;
    my $client = Net::Nostr::Client->new;
    my ($got_challenge, $auth_ok, $auth_event_id);

    $client->on(auth => sub {
        my ($challenge) = @_;
        $got_challenge = $challenge;
    });
    $client->on(ok => sub {
        my ($event_id, $accepted, $message) = @_;
        $auth_ok = $accepted;
        $auth_event_id = $event_id;
    });
    $client->connect("ws://127.0.0.1:$port");

    # Wait for challenge
    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    ok defined($got_challenge), 'got challenge';

    # Authenticate
    $client->authenticate($key, "ws://127.0.0.1:$port");

    # Wait for OK
    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is $auth_ok, 1, 'authentication accepted';

    $client->disconnect;
    $relay->stop;
};

subtest 'relay tracks authenticated pubkeys' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $key = Net::Nostr::Key->new;
    my $client = Net::Nostr::Client->new;
    my $got_challenge;

    $client->on(auth => sub { $got_challenge = $_[0] });
    $client->on(ok => sub {});
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    $client->authenticate($key, "ws://127.0.0.1:$port");

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Check relay knows about authenticated pubkeys
    my $auth = $relay->authenticated_pubkeys;
    ok scalar(keys %$auth) > 0, 'relay has authenticated connections';
    # Find our connection's pubkeys
    my @all_pubkeys = map { keys %$_ } values %$auth;
    ok grep({ $_ eq $key->pubkey_hex } @all_pubkeys), 'our pubkey is authenticated';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# Relay MUST exclude kind 22242 from broadcast
###############################################################################

subtest 'relay excludes kind 22242 from broadcast' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $key = Net::Nostr::Key->new;
    my $client1 = Net::Nostr::Client->new;
    my $client2 = Net::Nostr::Client->new;
    my (@c1_events, @c2_events);

    $client1->on(auth => sub {});
    $client2->on(auth => sub {});
    $client1->on(ok => sub {});
    $client2->on(ok => sub {});
    $client1->on(event => sub { push @c1_events, $_[1] });
    $client2->on(event => sub { push @c2_events, $_[1] });

    $client1->connect("ws://127.0.0.1:$port");
    $client2->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Subscribe to all events on client2
    use Net::Nostr::Filter;
    my $filter = Net::Nostr::Filter->new(kinds => [22242]);
    $client2->on(eose => sub {});
    $client2->subscribe('all', $filter);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Client1 authenticates (sends kind 22242 event)
    $client1->authenticate($key, "ws://127.0.0.1:$port");

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is scalar @c2_events, 0, 'kind 22242 not broadcast to subscribers';

    # Verify it's not stored either
    is scalar(grep { $_->kind == 22242 } @{$relay->events}), 0,
        'kind 22242 not stored in relay events';

    $client1->disconnect;
    $client2->disconnect;
    $relay->stop;
};

###############################################################################
# Multiple pubkeys from same client
###############################################################################

subtest 'client MAY authenticate with multiple pubkeys' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $key1 = Net::Nostr::Key->new;
    my $key2 = Net::Nostr::Key->new;
    my $client = Net::Nostr::Client->new;
    my @ok_results;

    $client->on(auth => sub {});
    $client->on(ok => sub { push @ok_results, [$_[0], $_[1]] });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    $client->authenticate($key1, "ws://127.0.0.1:$port");

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    $client->authenticate($key2, "ws://127.0.0.1:$port");

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is scalar @ok_results, 2, 'got OK for both auth attempts';
    is $ok_results[0][1], 1, 'first auth accepted';
    is $ok_results[1][1], 1, 'second auth accepted';

    # Both pubkeys should be tracked
    my $auth = $relay->authenticated_pubkeys;
    my @all_pubkeys = map { keys %$_ } values %$auth;
    ok grep({ $_ eq $key1->pubkey_hex } @all_pubkeys), 'first pubkey authenticated';
    ok grep({ $_ eq $key2->pubkey_hex } @all_pubkeys), 'second pubkey authenticated';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# AUTH event validation: created_at within ~10 minutes
###############################################################################

subtest 'relay rejects AUTH with stale created_at' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $key = Net::Nostr::Key->new;
    my $client = Net::Nostr::Client->new;
    my ($got_challenge, $auth_accepted);

    $client->on(auth => sub { $got_challenge = $_[0] });
    $client->on(ok => sub { $auth_accepted = $_[1] });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Manually send an AUTH event with old timestamp
    my $auth_event = $key->create_event(
        kind       => 22242,
        content    => '',
        created_at => time() - 700,  # 11+ minutes ago
        tags       => [
            ['relay', "ws://127.0.0.1:$port"],
            ['challenge', $got_challenge],
        ],
    );
    my $msg = Net::Nostr::Message->new(type => 'AUTH', event => $auth_event);
    $client->_conn->send($msg->serialize);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is $auth_accepted, 0, 'stale AUTH event rejected';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# AUTH event validation: challenge must match
###############################################################################

subtest 'relay rejects AUTH with wrong challenge' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $key = Net::Nostr::Key->new;
    my $client = Net::Nostr::Client->new;
    my ($got_challenge, $auth_accepted);

    $client->on(auth => sub { $got_challenge = $_[0] });
    $client->on(ok => sub { $auth_accepted = $_[1] });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Send AUTH with wrong challenge
    my $auth_event = $key->create_event(
        kind    => 22242,
        content => '',
        tags    => [
            ['relay', "ws://127.0.0.1:$port"],
            ['challenge', 'wrong-challenge-value'],
        ],
    );
    my $msg = Net::Nostr::Message->new(type => 'AUTH', event => $auth_event);
    $client->_conn->send($msg->serialize);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is $auth_accepted, 0, 'wrong challenge rejected';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# AUTH event validation: kind must be 22242
###############################################################################

subtest 'relay rejects AUTH with wrong kind' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $key = Net::Nostr::Key->new;
    my $client = Net::Nostr::Client->new;
    my ($got_challenge, $auth_accepted);

    $client->on(auth => sub { $got_challenge = $_[0] });
    $client->on(ok => sub { $auth_accepted = $_[1] });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Send AUTH with wrong kind
    my $auth_event = $key->create_event(
        kind    => 1,
        content => '',
        tags    => [
            ['relay', "ws://127.0.0.1:$port"],
            ['challenge', $got_challenge],
        ],
    );
    my $msg = Net::Nostr::Message->new(type => 'AUTH', event => $auth_event);
    $client->_conn->send($msg->serialize);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is $auth_accepted, 0, 'wrong kind rejected';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# AUTH event validation: relay tag must match relay URL
###############################################################################

subtest 'relay rejects AUTH with wrong relay URL' => sub {
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        relay_url         => "ws://127.0.0.1:$port",
    );
    $relay->start('127.0.0.1', $port);

    my $key = Net::Nostr::Key->new;
    my $client = Net::Nostr::Client->new;
    my ($got_challenge, $auth_accepted, $auth_msg);

    $client->on(auth => sub { $got_challenge = $_[0] });
    $client->on(ok => sub { $auth_accepted = $_[1]; $auth_msg = $_[2] });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Send AUTH with wrong relay URL
    my $auth_event = $key->create_event(
        kind    => 22242,
        content => '',
        tags    => [
            ['relay', 'wss://evil.example.com/'],
            ['challenge', $got_challenge],
        ],
    );
    my $msg = Net::Nostr::Message->new(type => 'AUTH', event => $auth_event);
    $client->_conn->send($msg->serialize);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is $auth_accepted, 0, 'wrong relay URL rejected';
    like $auth_msg, qr/relay/, 'rejection message mentions relay';

    $client->disconnect;
    $relay->stop;
};

subtest 'relay accepts AUTH with matching relay URL' => sub {
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        relay_url         => "ws://127.0.0.1:$port",
    );
    $relay->start('127.0.0.1', $port);

    my $key = Net::Nostr::Key->new;
    my $client = Net::Nostr::Client->new;
    my ($got_challenge, $auth_accepted);

    $client->on(auth => sub { $got_challenge = $_[0] });
    $client->on(ok => sub { $auth_accepted = $_[1] });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    $client->authenticate($key, "ws://127.0.0.1:$port");

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is $auth_accepted, 1, 'matching relay URL accepted';

    $client->disconnect;
    $relay->stop;
};

subtest 'relay URL validation is case-insensitive on host' => sub {
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        relay_url         => "ws://127.0.0.1:$port",
    );
    $relay->start('127.0.0.1', $port);

    my $key = Net::Nostr::Key->new;
    my $client = Net::Nostr::Client->new;
    my ($got_challenge, $auth_accepted);

    $client->on(auth => sub { $got_challenge = $_[0] });
    $client->on(ok => sub { $auth_accepted = $_[1] });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Send AUTH with uppercase host (should still match)
    my $auth_event = $key->create_event(
        kind    => 22242,
        content => '',
        tags    => [
            ['relay', "WS://127.0.0.1:$port"],
            ['challenge', $got_challenge],
        ],
    );
    my $msg = Net::Nostr::Message->new(type => 'AUTH', event => $auth_event);
    $client->_conn->send($msg->serialize);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is $auth_accepted, 1, 'case-insensitive host comparison accepted';

    $client->disconnect;
    $relay->stop;
};

subtest 'relay without relay_url skips relay tag validation' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $key = Net::Nostr::Key->new;
    my $client = Net::Nostr::Client->new;
    my ($got_challenge, $auth_accepted);

    $client->on(auth => sub { $got_challenge = $_[0] });
    $client->on(ok => sub { $auth_accepted = $_[1] });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Send AUTH with any relay URL - should still be accepted
    my $auth_event = $key->create_event(
        kind    => 22242,
        content => '',
        tags    => [
            ['relay', 'wss://any.relay.example.com/'],
            ['challenge', $got_challenge],
        ],
    );
    my $msg = Net::Nostr::Message->new(type => 'AUTH', event => $auth_event);
    $client->_conn->send($msg->serialize);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is $auth_accepted, 1, 'no relay_url set means relay tag not validated';

    $client->disconnect;
    $relay->stop;
};

subtest 'relay rejects AUTH with missing relay tag' => sub {
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        relay_url         => "ws://127.0.0.1:$port",
    );
    $relay->start('127.0.0.1', $port);

    my $key = Net::Nostr::Key->new;
    my $client = Net::Nostr::Client->new;
    my ($got_challenge, $auth_accepted, $auth_msg);

    $client->on(auth => sub { $got_challenge = $_[0] });
    $client->on(ok => sub { $auth_accepted = $_[1]; $auth_msg = $_[2] });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Send AUTH without relay tag
    my $auth_event = $key->create_event(
        kind    => 22242,
        content => '',
        tags    => [
            ['challenge', $got_challenge],
        ],
    );
    my $msg = Net::Nostr::Message->new(type => 'AUTH', event => $auth_event);
    $client->_conn->send($msg->serialize);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is $auth_accepted, 0, 'missing relay tag rejected';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# auth-required and restricted prefixes
###############################################################################

subtest 'auth-required prefix in OK and CLOSED messages' => sub {
    my $ok_msg = Net::Nostr::Message->new(
        type     => 'OK',
        event_id => '0' x 64,
        accepted => 0,
        message  => 'auth-required: you must authenticate',
    );
    is $ok_msg->prefix, 'auth-required', 'OK auth-required prefix';

    my $closed_msg = Net::Nostr::Message->new(
        type            => 'CLOSED',
        subscription_id => 'sub1',
        message         => 'auth-required: we can\'t serve DMs to unauthenticated users',
    );
    is $closed_msg->prefix, 'auth-required', 'CLOSED auth-required prefix';
};

subtest 'restricted prefix in OK and CLOSED messages' => sub {
    my $ok_msg = Net::Nostr::Message->new(
        type     => 'OK',
        event_id => '0' x 64,
        accepted => 0,
        message  => 'restricted: you are not allowed',
    );
    is $ok_msg->prefix, 'restricted', 'OK restricted prefix';

    my $closed_msg = Net::Nostr::Message->new(
        type            => 'CLOSED',
        subscription_id => 'sub1',
        message         => 'restricted: this relay requires payment',
    );
    is $closed_msg->prefix, 'restricted', 'CLOSED restricted prefix';
};

###############################################################################
# Client stores challenge from relay
###############################################################################

subtest 'client stores challenge for relay' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;
    $client->on(auth => sub {});
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    ok defined($client->challenge), 'client stored challenge';
    ok length($client->challenge) > 0, 'challenge is non-empty';

    $client->disconnect;
    $relay->stop;
};

done_testing;
