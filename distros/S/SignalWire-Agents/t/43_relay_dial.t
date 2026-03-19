#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON qw(encode_json);

use SignalWire::Agents::Relay::Client;
use SignalWire::Agents::Relay::Call;
use SignalWire::Agents::Relay::Event;
BEGIN { use SignalWire::Agents::Relay::Constants ':all' }

# ============================================================
# 1. Dial states constants
# ============================================================
subtest 'dial state constants' => sub {
    is(DIAL_STATE_DIALING, 'dialing', 'dialing');
    is(DIAL_STATE_ANSWERED, 'answered', 'answered');
    is(DIAL_STATE_FAILED, 'failed', 'failed');
};

# ============================================================
# 2. Successful dial via client
# ============================================================
subtest 'dial answered' => sub {
    my $client = SignalWire::Agents::Relay::Client->new(
        project => 'p', token => 't', host => 'h',
    );

    my $resolved_call;
    $client->_pending_dials->{'dial-1'} = {
        resolve => sub { $resolved_call = $_[0] },
        reject  => sub { die "should not reject" },
    };

    # State event creates call
    $client->_handle_event({
        event_type => 'calling.call.state',
        params     => {
            call_id    => 'dial-c1',
            node_id    => 'dn1',
            tag        => 'dial-1',
            call_state => 'created',
            device     => { type => 'phone' },
        },
    });
    ok(exists $client->_calls->{'dial-c1'}, 'call registered');

    # Dial completion event
    $client->_handle_event({
        event_type => 'calling.call.dial',
        params     => {
            tag        => 'dial-1',
            dial_state => 'answered',
            call       => { call_id => 'dial-c1', node_id => 'dn1' },
        },
    });
    ok($resolved_call, 'dial resolved');
    is($resolved_call->call_id, 'dial-c1', 'call_id');
    is($resolved_call->state, 'answered', 'state answered');
    ok($resolved_call->dial_winner, 'dial_winner set');
};

# ============================================================
# 3. Failed dial
# ============================================================
subtest 'dial failed' => sub {
    my $client = SignalWire::Agents::Relay::Client->new(
        project => 'p', token => 't', host => 'h',
    );

    my $rejected;
    $client->_pending_dials->{'dial-fail'} = {
        resolve => sub { die "should not resolve" },
        reject  => sub { $rejected = $_[0] },
    };

    $client->_handle_event({
        event_type => 'calling.call.dial',
        params     => {
            tag        => 'dial-fail',
            dial_state => 'failed',
        },
    });
    is($rejected, 'Dial failed', 'failure rejected');
};

# ============================================================
# 4. Dial event parsing
# ============================================================
subtest 'dial event parsing' => sub {
    my $event = SignalWire::Agents::Relay::Event->parse_event('calling.call.dial', {
        tag        => 'tag-1',
        dial_state => 'answered',
        call       => { call_id => 'winner', dial_winner => 1 },
    });
    isa_ok($event, 'SignalWire::Agents::Relay::Event::CallDial');
    is($event->dial_state, 'answered', 'dial_state');
    is($event->call->{call_id}, 'winner', 'nested call');
};

# ============================================================
# 5. Dial with unmatched tag
# ============================================================
subtest 'unmatched dial tag' => sub {
    my $client = SignalWire::Agents::Relay::Client->new(
        project => 'p', token => 't', host => 'h',
    );
    # No pending dials - should not crash
    $client->_handle_event({
        event_type => 'calling.call.dial',
        params     => {
            tag        => 'no-such-tag',
            dial_state => 'answered',
            call       => { call_id => 'x' },
        },
    });
    pass('unmatched dial tag does not crash');
};

done_testing;
