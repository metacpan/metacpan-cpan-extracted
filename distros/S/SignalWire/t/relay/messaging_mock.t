#!/usr/bin/env perl
# Real-mock-backed tests for messaging (send_message + inbound).
# Mirrors signalwire-python tests/unit/relay/test_messaging_mock.py.

use strict;
use warnings;
use Test::More;
use FindBin ();
use lib "$FindBin::Bin/../lib";
use Time::HiRes qw(sleep time);

use RelayMockTest;
use SignalWire::Relay::Client;

# Connected client with default contexts.
sub _connected_client {
    my $client = RelayMockTest::client(contexts => ['default']);
    $client->connect;
    return $client;
}

# Pump the client's recv loop until $cb returns truthy or timeout fires.
sub _pump_until {
    my ($client, $secs, $cb) = @_;
    my $deadline = time() + $secs;
    while (time() < $deadline) {
        return 1 if $cb->();
        eval { $client->_read_once };
    }
    return $cb->() ? 1 : 0;
}

# ---------------------------------------------------------------------------
# send_message — outbound
# ---------------------------------------------------------------------------

subtest 'send_message journals messaging.send' => sub {
    my $client = _connected_client();
    my $msg = $client->send_message(
        to_number   => '+15551112222',
        from_number => '+15553334444',
        body        => 'hello',
        tags        => ['t1', 't2'],
    );
    isa_ok($msg, 'SignalWire::Relay::Message');
    ok($msg->message_id, 'mock generated message_id');
    is($msg->body, 'hello', 'body propagated');

    my $entries = RelayMockTest::journal_recv(method => 'messaging.send');
    is(scalar @$entries, 1, 'one messaging.send entry');
    my $p = $entries->[0]{frame}{params};
    is($p->{to_number},   '+15551112222', 'to_number on wire');
    is($p->{from_number}, '+15553334444', 'from_number on wire');
    is($p->{body},        'hello',         'body on wire');
    is_deeply($p->{tags}, ['t1', 't2'],    'tags on wire');
    $client->disconnect;
};

subtest 'send_message with media only' => sub {
    my $client = _connected_client();
    my $msg = $client->send_message(
        to_number   => '+15551112222',
        from_number => '+15553334444',
        media       => ['https://media.example/cat.jpg'],
    );
    isa_ok($msg, 'SignalWire::Relay::Message');

    my $entries = RelayMockTest::journal_recv(method => 'messaging.send');
    is(scalar @$entries, 1, 'one messaging.send entry');
    my $p = $entries->[0]{frame}{params};
    is_deeply($p->{media}, ['https://media.example/cat.jpg'],
              'media on wire');
    ok(!$p->{body}, 'no body field for media-only');
    $client->disconnect;
};

subtest 'send_message includes context' => sub {
    my $client = _connected_client();
    $client->send_message(
        to_number   => '+15551112222',
        from_number => '+15553334444',
        body        => 'hi',
        context     => 'custom-ctx',
    );
    my $entries = RelayMockTest::journal_recv(method => 'messaging.send');
    is($entries->[0]{frame}{params}{context}, 'custom-ctx',
       'context on wire');
    $client->disconnect;
};

subtest 'send_message returns initial state queued' => sub {
    my $client = _connected_client();
    my $msg = $client->send_message(
        to_number   => '+15551112222',
        from_number => '+15553334444',
        body        => 'hi',
    );
    is($msg->state, 'queued', 'state is queued');
    ok(!$msg->is_done, 'not done yet');
    $client->disconnect;
};

subtest 'send_message resolves on delivered' => sub {
    my $client = _connected_client();
    my $msg = $client->send_message(
        to_number   => '+15551112222',
        from_number => '+15553334444',
        body        => 'hi',
    );
    # Push the terminal delivered state.
    RelayMockTest::push_frame({
        jsonrpc => '2.0',
        id      => 'evt-deliver-1',
        method  => 'signalwire.event',
        params  => {
            event_type => 'messaging.state',
            params     => {
                message_id    => $msg->message_id,
                message_state => 'delivered',
                from_number   => '+15553334444',
                to_number     => '+15551112222',
                body          => 'hi',
            },
        },
    });
    my $ok = _pump_until($client, 5, sub { $msg->is_done });
    ok($ok, 'message resolved');
    is($msg->state, 'delivered', 'state is delivered');
    ok($msg->is_done, 'is_done true');
    $client->disconnect;
};

subtest 'send_message resolves on undelivered' => sub {
    my $client = _connected_client();
    my $msg = $client->send_message(
        to_number   => '+15551112222',
        from_number => '+15553334444',
        body        => 'hi',
    );
    RelayMockTest::push_frame({
        jsonrpc => '2.0',
        id      => 'evt-undeliver',
        method  => 'signalwire.event',
        params  => {
            event_type => 'messaging.state',
            params     => {
                message_id    => $msg->message_id,
                message_state => 'undelivered',
                reason        => 'carrier_blocked',
            },
        },
    });
    _pump_until($client, 5, sub { $msg->is_done });
    is($msg->state,  'undelivered',     'state undelivered');
    is($msg->reason, 'carrier_blocked', 'reason set');
    $client->disconnect;
};

subtest 'send_message resolves on failed' => sub {
    my $client = _connected_client();
    my $msg = $client->send_message(
        to_number   => '+15551112222',
        from_number => '+15553334444',
        body        => 'hi',
    );
    RelayMockTest::push_frame({
        jsonrpc => '2.0',
        id      => 'evt-fail',
        method  => 'signalwire.event',
        params  => {
            event_type => 'messaging.state',
            params     => {
                message_id    => $msg->message_id,
                message_state => 'failed',
                reason        => 'spam',
            },
        },
    });
    _pump_until($client, 5, sub { $msg->is_done });
    is($msg->state, 'failed', 'state failed');
    $client->disconnect;
};

subtest 'send_message intermediate state does not resolve' => sub {
    my $client = _connected_client();
    my $msg = $client->send_message(
        to_number   => '+15551112222',
        from_number => '+15553334444',
        body        => 'hi',
    );
    RelayMockTest::push_frame({
        jsonrpc => '2.0',
        id      => 'evt-sent',
        method  => 'signalwire.event',
        params  => {
            event_type => 'messaging.state',
            params     => {
                message_id    => $msg->message_id,
                message_state => 'sent',
            },
        },
    });
    _pump_until($client, 2, sub { $msg->state eq 'sent' });
    is($msg->state, 'sent', 'state advanced to sent');
    ok(!$msg->is_done, 'still not done on intermediate');
    $client->disconnect;
};

# ---------------------------------------------------------------------------
# Inbound messages
# ---------------------------------------------------------------------------

subtest 'inbound message fires on_message handler' => sub {
    my $client = _connected_client();
    my %seen;
    $client->on_message(sub {
        my ($evt) = @_;
        $seen{got} = 1;
        $seen{message_id}  = $evt->message_id;
        $seen{direction}   = $evt->direction;
        $seen{from_number} = $evt->from_number;
        $seen{to_number}   = $evt->to_number;
        $seen{body}        = $evt->body;
        $seen{tags}        = $evt->tags;
    });

    RelayMockTest::push_frame({
        jsonrpc => '2.0',
        id      => 'evt-in-msg-1',
        method  => 'signalwire.event',
        params  => {
            event_type => 'messaging.receive',
            params     => {
                message_id    => 'in-msg-1',
                context       => 'default',
                direction     => 'inbound',
                from_number   => '+15551110000',
                to_number     => '+15552220000',
                body          => 'hello back',
                media         => [],
                segments      => 1,
                message_state => 'received',
                tags          => ['incoming'],
            },
        },
    });
    _pump_until($client, 5, sub { $seen{got} });
    ok($seen{got}, 'on_message handler fired');
    is($seen{message_id},  'in-msg-1',      'message_id');
    is($seen{direction},   'inbound',       'direction');
    is($seen{from_number}, '+15551110000',  'from_number');
    is($seen{to_number},   '+15552220000',  'to_number');
    is($seen{body},        'hello back',    'body');
    is_deeply($seen{tags}, ['incoming'],    'tags');
    $client->disconnect;
};

# ---------------------------------------------------------------------------
# Full state progression
# ---------------------------------------------------------------------------

subtest 'full message state progression' => sub {
    my $client = _connected_client();
    my $msg = $client->send_message(
        to_number   => '+15551112222',
        from_number => '+15553334444',
        body        => 'full pipeline',
    );
    # Push intermediate sent.
    RelayMockTest::push_frame({
        jsonrpc => '2.0',
        id      => 'evt-prog-sent',
        method  => 'signalwire.event',
        params  => {
            event_type => 'messaging.state',
            params     => {
                message_id    => $msg->message_id,
                message_state => 'sent',
            },
        },
    });
    _pump_until($client, 2, sub { $msg->state eq 'sent' });
    is($msg->state, 'sent', 'reached sent');

    # Push terminal delivered.
    RelayMockTest::push_frame({
        jsonrpc => '2.0',
        id      => 'evt-prog-deliv',
        method  => 'signalwire.event',
        params  => {
            event_type => 'messaging.state',
            params     => {
                message_id    => $msg->message_id,
                message_state => 'delivered',
            },
        },
    });
    _pump_until($client, 5, sub { $msg->is_done });
    is($msg->state, 'delivered', 'reached delivered');
    ok($msg->is_done, 'is_done true');
    $client->disconnect;
};

done_testing();
