#!/usr/bin/perl

# NIP-45: Event Counts
# https://github.com/nostr-protocol/nips/blob/master/45.md

use strictures 2;

use Test2::V0 -no_srand => 1;
use AnyEvent;
use IO::Socket::INET;
use JSON ();

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Event;
use Net::Nostr::Filter;
use Net::Nostr::Message;
use Net::Nostr::Client;
use Net::Nostr::Relay;

my $alice_pk = 'a' x 64;
my $bob_pk   = 'b' x 64;

###############################################################################
# "This NIP defines the verb COUNT, which accepts a query id and filters
#  as specified in NIP 01 for the verb REQ"
###############################################################################

subtest 'COUNT message client-to-relay structure' => sub {
    my $filter = Net::Nostr::Filter->new(kinds => [1, 7], authors => [$alice_pk]);
    my $msg = Net::Nostr::Message->new(
        type            => 'COUNT',
        subscription_id => 'q1',
        filters         => [$filter],
    );
    is $msg->type, 'COUNT', 'type is COUNT';
    is $msg->subscription_id, 'q1', 'subscription_id preserved';
    is scalar @{$msg->filters}, 1, 'one filter';

    my $json = $msg->serialize;
    my $arr = JSON::decode_json($json);
    is $arr->[0], 'COUNT', 'serializes as COUNT verb';
    is $arr->[1], 'q1', 'query id in position 1';
    is ref $arr->[2], 'HASH', 'filter object in position 2';
};

subtest 'COUNT message with multiple filters' => sub {
    my $f1 = Net::Nostr::Filter->new(kinds => [1]);
    my $f2 = Net::Nostr::Filter->new(kinds => [7]);
    my $msg = Net::Nostr::Message->new(
        type            => 'COUNT',
        subscription_id => 'q2',
        filters         => [$f1, $f2],
    );
    my $json = $msg->serialize;
    my $arr = JSON::decode_json($json);
    is scalar @$arr, 4, 'COUNT + query_id + 2 filters';
};

###############################################################################
# "Counts are returned using a COUNT response in the form {"count": <integer>}"
###############################################################################

subtest 'COUNT response relay-to-client' => sub {
    my $msg = Net::Nostr::Message->new(
        type            => 'COUNT',
        subscription_id => 'q1',
        count           => 5,
    );
    is $msg->count, 5, 'count accessor';
    my $json = $msg->serialize;
    my $arr = JSON::decode_json($json);
    is $arr->[0], 'COUNT', 'type is COUNT';
    is $arr->[1], 'q1', 'query id';
    is ref $arr->[2], 'HASH', 'third element is hash';
    is $arr->[2]{count}, 5, 'count value in response';
};

###############################################################################
# "Relays may use probabilistic counts ... it MAY indicate it in the response
#  with approximate key"
###############################################################################

subtest 'COUNT response with approximate flag' => sub {
    my $msg = Net::Nostr::Message->new(
        type            => 'COUNT',
        subscription_id => 'q1',
        count           => 93412452,
        approximate     => 1,
    );
    is $msg->approximate, 1, 'approximate accessor';
    my $json = $msg->serialize;
    my $arr = JSON::decode_json($json);
    is $arr->[2]{count}, 93412452, 'count value';
    is $arr->[2]{approximate}, JSON::true, 'approximate is true';
};

subtest 'COUNT response without approximate omits key' => sub {
    my $msg = Net::Nostr::Message->new(
        type            => 'COUNT',
        subscription_id => 'q1',
        count           => 5,
    );
    my $json = $msg->serialize;
    my $arr = JSON::decode_json($json);
    ok !exists $arr->[2]{approximate}, 'approximate key not present';
};

###############################################################################
# Parse COUNT messages
###############################################################################

subtest 'parse COUNT client-to-relay' => sub {
    my $json = JSON::encode_json(['COUNT', 'q1', { kinds => [1, 7], authors => [$alice_pk] }]);
    my $msg = Net::Nostr::Message->parse($json);
    is $msg->type, 'COUNT', 'type';
    is $msg->subscription_id, 'q1', 'subscription_id';
    is scalar @{$msg->filters}, 1, 'one filter';
    is $msg->filters->[0]->kinds, [1, 7], 'filter kinds';
};

subtest 'parse COUNT relay-to-client' => sub {
    my $json = JSON::encode_json(['COUNT', 'q1', { count => 42 }]);
    my $msg = Net::Nostr::Message->parse($json);
    is $msg->type, 'COUNT', 'type';
    is $msg->subscription_id, 'q1', 'subscription_id';
    is $msg->count, 42, 'count parsed';
};

subtest 'parse COUNT with approximate' => sub {
    my $json = JSON::encode_json(['COUNT', 'q1', { count => 93412452, approximate => JSON::true }]);
    my $msg = Net::Nostr::Message->parse($json);
    is $msg->count, 93412452, 'count';
    ok $msg->approximate, 'approximate is true';
};

###############################################################################
# Spec examples
###############################################################################

subtest 'spec example: count notes and reactions' => sub {
    # ["COUNT", <query_id>, {"kinds": [1, 7], "authors": [<pubkey>]}]
    my $filter = Net::Nostr::Filter->new(kinds => [1, 7], authors => [$alice_pk]);
    my $msg = Net::Nostr::Message->new(
        type => 'COUNT', subscription_id => 'q1', filters => [$filter],
    );
    my $arr = JSON::decode_json($msg->serialize);
    is $arr->[0], 'COUNT', 'verb';
    is $arr->[2]{kinds}, [1, 7], 'kinds filter';
    is $arr->[2]{authors}, [$alice_pk], 'authors filter';

    # ["COUNT", <query_id>, {"count": 5}]
    my $resp = Net::Nostr::Message->new(
        type => 'COUNT', subscription_id => 'q1', count => 5,
    );
    my $resp_arr = JSON::decode_json($resp->serialize);
    is $resp_arr, ['COUNT', 'q1', { count => 5 }], 'response matches spec';
};

subtest 'spec example: count notes approximately' => sub {
    # ["COUNT", <query_id>, {"kinds": [1]}]
    # ["COUNT", <query_id>, {"count": 93412452, "approximate": true}]
    my $resp = Net::Nostr::Message->new(
        type => 'COUNT', subscription_id => 'q1',
        count => 93412452, approximate => 1,
    );
    my $arr = JSON::decode_json($resp->serialize);
    is $arr->[2]{count}, 93412452, 'count';
    is $arr->[2]{approximate}, JSON::true, 'approximate true';
};

###############################################################################
# "Whenever the relay decides to refuse to fulfill the COUNT request,
#  it MUST return a CLOSED message"
###############################################################################

subtest 'spec example: relay refuses to count' => sub {
    # ["CLOSED", <query_id>, "auth-required: cannot count other people's DMs"]
    my $msg = Net::Nostr::Message->new(
        type            => 'CLOSED',
        subscription_id => 'q1',
        message         => 'auth-required: cannot count other people\'s DMs',
    );
    is $msg->prefix, 'auth-required', 'prefix is auth-required';
};

###############################################################################
# Client: count method
###############################################################################

subtest 'client count method sends COUNT message' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my ($got_count, $got_approx);
    $client->on(count => sub {
        my ($sub_id, $count, $approximate) = @_;
        $got_count = $count;
        $got_approx = $approximate;
        $cv->send;
    });

    $client->connect("ws://127.0.0.1:$port");
    $client->count('q1', Net::Nostr::Filter->new(kinds => [1], authors => [$alice_pk]));

    $cv->recv;

    is $got_count, 0, 'count is 0 (no events stored)';
    ok !$got_approx, 'not approximate';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# Relay: COUNT returns correct counts
###############################################################################

subtest 'relay counts matching events' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    # Store some events
    $relay->events([]);
    for my $i (1 .. 3) {
        $relay->inject_event(make_event(
            pubkey => $alice_pk, kind => 1,
            content => "note $i", sig => 'a' x 128,
        ));
    }
    $relay->inject_event(make_event(
        pubkey => $alice_pk, kind => 7,
        content => '+', sig => 'a' x 128,
    ));
    $relay->inject_event(make_event(
        pubkey => $bob_pk, kind => 1,
        content => 'bob note', sig => 'a' x 128,
    ));

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my $got_count;
    $client->on(count => sub {
        my ($sub_id, $count) = @_;
        $got_count = $count;
        $cv->send;
    });

    $client->connect("ws://127.0.0.1:$port");
    $client->count('q1', Net::Nostr::Filter->new(kinds => [1], authors => [$alice_pk]));

    $cv->recv;

    is $got_count, 3, 'counts only alice kind-1 events';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# "Multiple filters are OR'd together and aggregated into a single count"
###############################################################################

subtest 'multiple filters OR-ed into single count' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    # 2 kind-1, 1 kind-7
    $relay->events([]);
    $relay->inject_event(make_event(
        pubkey => $alice_pk, kind => 1,
        content => 'note1', sig => 'a' x 128,
    ));
    $relay->inject_event(make_event(
        pubkey => $alice_pk, kind => 1,
        content => 'note2', sig => 'a' x 128,
    ));
    $relay->inject_event(make_event(
        pubkey => $alice_pk, kind => 7,
        content => '+', sig => 'a' x 128,
    ));

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my $got_count;
    $client->on(count => sub {
        my ($sub_id, $count) = @_;
        $got_count = $count;
        $cv->send;
    });

    $client->connect("ws://127.0.0.1:$port");

    # Two filters: kind 1 OR kind 7
    $client->count('q1',
        Net::Nostr::Filter->new(kinds => [1], authors => [$alice_pk]),
        Net::Nostr::Filter->new(kinds => [7], authors => [$alice_pk]),
    );

    $cv->recv;

    is $got_count, 3, 'OR-ed filters: 2 kind-1 + 1 kind-7 = 3';

    $client->disconnect;
    $relay->stop;
};

subtest 'multiple filters do not double-count' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    $relay->events([]);
    $relay->inject_event(make_event(
        pubkey => $alice_pk, kind => 1,
        content => 'note', sig => 'a' x 128,
    ));

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my $got_count;
    $client->on(count => sub {
        my ($sub_id, $count) = @_;
        $got_count = $count;
        $cv->send;
    });

    $client->connect("ws://127.0.0.1:$port");

    # Both filters match the same event
    $client->count('q1',
        Net::Nostr::Filter->new(kinds => [1]),
        Net::Nostr::Filter->new(authors => [$alice_pk]),
    );

    $cv->recv;

    is $got_count, 1, 'event matched by both filters counted only once';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# COUNT respects NIP-40 (expired events)
###############################################################################

subtest 'COUNT skips expired events' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    $relay->events([]);
    $relay->inject_event(make_event(
        pubkey => $alice_pk, kind => 1,
        content => 'valid', sig => 'a' x 128,
    ));
    $relay->inject_event(make_event(
        pubkey => $alice_pk, kind => 1,
        content => 'expired', sig => 'a' x 128,
        tags => [['expiration', '1000000000']],
    ));

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my $got_count;
    $client->on(count => sub {
        my ($sub_id, $count) = @_;
        $got_count = $count;
        $cv->send;
    });

    $client->connect("ws://127.0.0.1:$port");
    $client->count('q1', Net::Nostr::Filter->new(kinds => [1], authors => [$alice_pk]));

    $cv->recv;

    is $got_count, 1, 'expired event not counted';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# COUNT with tag filters
###############################################################################

subtest 'COUNT with tag filters' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $target_id = 'c' x 64;
    $relay->events([]);
    $relay->inject_event(make_event(
        pubkey => $alice_pk, kind => 7,
        content => '+', sig => 'a' x 128,
        tags => [['e', $target_id]],
    ));
    $relay->inject_event(make_event(
        pubkey => $bob_pk, kind => 7,
        content => '+', sig => 'a' x 128,
        tags => [['e', $target_id]],
    ));
    $relay->inject_event(make_event(
        pubkey => $alice_pk, kind => 7,
        content => '+', sig => 'a' x 128,
        tags => [['e', 'd' x 64]],
    ));

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my $got_count;
    $client->on(count => sub {
        my ($sub_id, $count) = @_;
        $got_count = $count;
        $cv->send;
    });

    $client->connect("ws://127.0.0.1:$port");
    # Reaction count for target event (common query from spec)
    $client->count('q1', Net::Nostr::Filter->new(kinds => [7], '#e' => [$target_id]));

    $cv->recv;

    is $got_count, 2, 'counts reactions to target event';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# COUNT does not create a subscription (no live events)
###############################################################################

subtest 'COUNT does not create a live subscription' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 3, cb => sub { $cv->send });

    my $got_count = 0;
    my @live_events;
    $client->on(count => sub {
        my ($sub_id, $count) = @_;
        $got_count++;
        # After receiving count, inject an event and wait
        my $event = make_event(
            pubkey => $alice_pk, kind => 1,
            content => 'later', sig => 'a' x 128,
        );
        $relay->inject_event($event);
        $relay->broadcast($event);
    });
    $client->on(event => sub {
        push @live_events, $_[1];
    });

    $client->connect("ws://127.0.0.1:$port");
    $client->count('q1', Net::Nostr::Filter->new(kinds => [1]));

    $cv->recv;

    is $got_count, 1, 'received exactly one count response';
    is scalar @live_events, 0, 'no live events (COUNT is one-shot)';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# COUNT with zero results
###############################################################################

subtest 'COUNT returns zero for no matches' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my $got_count;
    $client->on(count => sub {
        my ($sub_id, $count) = @_;
        $got_count = $count;
        $cv->send;
    });

    $client->connect("ws://127.0.0.1:$port");
    $client->count('q1', Net::Nostr::Filter->new(kinds => [9999]));

    $cv->recv;

    is $got_count, 0, 'count is 0 when nothing matches';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# Follower count with #p tag filter (spec line 88)
###############################################################################

subtest 'COUNT follower count with #p tag filter' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $target_pk = 'c' x 64;

    # 3 follow-list events (kind 3) that follow target
    $relay->events([]);
    for my $pk ($alice_pk, $bob_pk, 'd' x 64) {
        $relay->inject_event(make_event(
            pubkey => $pk, kind => 3,
            content => '', sig => 'a' x 128,
            tags => [['p', $target_pk]],
        ));
    }
    # One kind-3 that does NOT follow target
    $relay->inject_event(make_event(
        pubkey => 'e' x 64, kind => 3,
        content => '', sig => 'a' x 128,
        tags => [['p', 'f' x 64]],
    ));

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my $got_count;
    $client->on(count => sub {
        my ($sub_id, $count) = @_;
        $got_count = $count;
        $cv->send;
    });

    $client->connect("ws://127.0.0.1:$port");
    # Spec common query: follower count
    # {"#p": ["<pubkey>"], "kinds": [3]}
    $client->count('followers', Net::Nostr::Filter->new(
        kinds => [3], '#p' => [$target_pk],
    ));

    $cv->recv;

    is $got_count, 3, 'follower count via #p tag filter';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# HyperLogLog: forward-compatible test
# Passes now (no HLL support) and will still pass if HLL is added later
###############################################################################

subtest 'COUNT response with hll key is parseable' => sub {
    # Parse a COUNT response that includes an hll value (as a relay with
    # HLL support would send). The count must still be correct.
    my $hll_hex = '06' x 256;  # 512-char hex string (256 registers)
    my $json = JSON::encode_json([
        'COUNT', 'q1', { count => 16578, hll => $hll_hex },
    ]);
    my $msg = Net::Nostr::Message->parse($json);
    is $msg->type, 'COUNT', 'type is COUNT';
    is $msg->subscription_id, 'q1', 'subscription_id preserved';
    is $msg->count, 16578, 'count parsed correctly despite hll presence';
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
