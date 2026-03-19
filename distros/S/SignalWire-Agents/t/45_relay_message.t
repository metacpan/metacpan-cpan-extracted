#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Agents::Relay::Message;
use SignalWire::Agents::Relay::Event;
use SignalWire::Agents::Relay::Client;
BEGIN { use SignalWire::Agents::Relay::Constants ':all' }

# ============================================================
# 1. Message construction
# ============================================================
subtest 'construction' => sub {
    my $msg = SignalWire::Agents::Relay::Message->new(
        message_id  => 'm1',
        from_number => '+15551111111',
        to_number   => '+15552222222',
        body        => 'Hello',
        direction   => 'outbound',
    );
    is($msg->message_id, 'm1', 'message_id');
    is($msg->from_number, '+15551111111', 'from_number');
    is($msg->body, 'Hello', 'body');
    ok(!$msg->is_done, 'not done initially');
};

# ============================================================
# 2. Terminal state delivery
# ============================================================
subtest 'terminal state: delivered' => sub {
    my $msg = SignalWire::Agents::Relay::Message->new(
        message_id => 'm2',
        direction  => 'outbound',
    );
    my $cb_fired = 0;
    $msg->on_completed(sub { $cb_fired = 1 });

    my $event = SignalWire::Agents::Relay::Event->parse_event('messaging.state', {
        message_id    => 'm2',
        message_state => 'delivered',
    });
    $msg->dispatch_event($event);
    ok($msg->is_done, 'done on delivered');
    is($msg->state, 'delivered', 'state delivered');
    ok($cb_fired, 'callback fired');
};

# ============================================================
# 3. Terminal state: failed
# ============================================================
subtest 'terminal state: failed' => sub {
    my $msg = SignalWire::Agents::Relay::Message->new(
        message_id => 'm3',
        direction  => 'outbound',
    );
    my $event = SignalWire::Agents::Relay::Event->parse_event('messaging.state', {
        message_id    => 'm3',
        message_state => 'failed',
    });
    $msg->dispatch_event($event);
    ok($msg->is_done, 'done on failed');
    is($msg->state, 'failed', 'state failed');
};

# ============================================================
# 4. Non-terminal state
# ============================================================
subtest 'non-terminal state' => sub {
    my $msg = SignalWire::Agents::Relay::Message->new(
        message_id => 'm4',
        direction  => 'outbound',
    );
    my $event = SignalWire::Agents::Relay::Event->parse_event('messaging.state', {
        message_id    => 'm4',
        message_state => 'sent',
    });
    $msg->dispatch_event($event);
    ok(!$msg->is_done, 'not done on sent');
    is($msg->state, 'sent', 'state is sent');
};

# ============================================================
# 5. Message constants
# ============================================================
subtest 'message constants' => sub {
    is(MESSAGE_STATE_QUEUED, 'queued', 'queued');
    is(MESSAGE_STATE_DELIVERED, 'delivered', 'delivered');
    is(MESSAGE_STATE_FAILED, 'failed', 'failed');
};

subtest 'message terminal states' => sub {
    my $terminal = MESSAGE_TERMINAL_STATES;
    ok($terminal->{delivered}, 'delivered terminal');
    ok($terminal->{undelivered}, 'undelivered terminal');
    ok($terminal->{failed}, 'failed terminal');
    ok(!$terminal->{queued}, 'queued not terminal');
    ok(!$terminal->{sent}, 'sent not terminal');
};

# ============================================================
# 6. Client message tracking
# ============================================================
subtest 'client message tracking' => sub {
    my $client = SignalWire::Agents::Relay::Client->new(
        project => 'p', token => 't', host => 'h',
    );

    my $msg = SignalWire::Agents::Relay::Message->new(
        message_id => 'track-1',
        direction  => 'outbound',
    );
    $client->_messages->{'track-1'} = $msg;

    # Non-terminal
    $client->_handle_event({
        event_type => 'messaging.state',
        params     => { message_id => 'track-1', message_state => 'sent' },
    });
    is($msg->state, 'sent', 'state updated');
    ok(exists $client->_messages->{'track-1'}, 'still tracked');

    # Terminal
    $client->_handle_event({
        event_type => 'messaging.state',
        params     => { message_id => 'track-1', message_state => 'delivered' },
    });
    ok($msg->is_done, 'done');
    ok(!exists $client->_messages->{'track-1'}, 'removed from tracking');
};

# ============================================================
# 7. Inbound message via client
# ============================================================
subtest 'inbound message via client' => sub {
    my $client = SignalWire::Agents::Relay::Client->new(
        project => 'p', token => 't', host => 'h',
    );
    my $received;
    $client->on_message(sub { $received = $_[0] });

    $client->_handle_event({
        event_type => 'messaging.receive',
        params     => {
            message_id  => 'inbound-1',
            from_number => '+15551234567',
            to_number   => '+15559876543',
            body        => 'Hi there',
        },
    });
    ok($received, 'on_message fired');
    isa_ok($received, 'SignalWire::Agents::Relay::Event::MessageReceive');
};

done_testing;
