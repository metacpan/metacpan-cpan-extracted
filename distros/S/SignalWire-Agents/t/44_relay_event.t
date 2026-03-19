#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Agents::Relay::Event;
BEGIN { use SignalWire::Agents::Relay::Constants ':all' }

# ============================================================
# 1. CallState event
# ============================================================
subtest 'CallState event' => sub {
    my $e = SignalWire::Agents::Relay::Event->parse_event('calling.call.state', {
        call_id    => 'c1',
        node_id    => 'n1',
        call_state => 'answered',
    });
    isa_ok($e, 'SignalWire::Agents::Relay::Event::CallState');
    is($e->call_state, 'answered', 'call_state');
    is($e->call_id, 'c1', 'call_id');
};

# ============================================================
# 2. CallPlay event
# ============================================================
subtest 'CallPlay event' => sub {
    my $e = SignalWire::Agents::Relay::Event->parse_event('calling.call.play', {
        call_id    => 'c2',
        control_id => 'ctl1',
        state      => 'finished',
    });
    isa_ok($e, 'SignalWire::Agents::Relay::Event::CallPlay');
    is($e->state, 'finished', 'state');
    is($e->control_id, 'ctl1', 'control_id');
};

# ============================================================
# 3. CallRecord event
# ============================================================
subtest 'CallRecord event' => sub {
    my $e = SignalWire::Agents::Relay::Event->parse_event('calling.call.record', {
        call_id    => 'c3',
        control_id => 'ctl2',
        state      => 'finished',
        url        => 'https://example.com/rec.mp3',
        duration   => 30,
        size       => 96000,
    });
    isa_ok($e, 'SignalWire::Agents::Relay::Event::CallRecord');
    is($e->url, 'https://example.com/rec.mp3', 'url');
    is($e->duration, 30, 'duration');
    is($e->size, 96000, 'size');
};

# ============================================================
# 4. CallCollect event
# ============================================================
subtest 'CallCollect event' => sub {
    my $e = SignalWire::Agents::Relay::Event->parse_event('calling.call.collect', {
        call_id    => 'c4',
        control_id => 'ctl3',
        result     => { type => 'digit', params => { digits => '1234' } },
    });
    isa_ok($e, 'SignalWire::Agents::Relay::Event::CallCollect');
    is($e->result->{type}, 'digit', 'result type');
};

# ============================================================
# 5. CallDetect event
# ============================================================
subtest 'CallDetect event' => sub {
    my $e = SignalWire::Agents::Relay::Event->parse_event('calling.call.detect', {
        call_id    => 'c5',
        control_id => 'ctl4',
        detect     => { type => 'machine', params => { event => 'HUMAN' } },
    });
    isa_ok($e, 'SignalWire::Agents::Relay::Event::CallDetect');
    is($e->detect->{type}, 'machine', 'detect type');
};

# ============================================================
# 6. MessageReceive event
# ============================================================
subtest 'MessageReceive event' => sub {
    my $e = SignalWire::Agents::Relay::Event->parse_event('messaging.receive', {
        message_id  => 'm1',
        from_number => '+15551111111',
        to_number   => '+15552222222',
        body        => 'Hello',
        direction   => 'inbound',
    });
    isa_ok($e, 'SignalWire::Agents::Relay::Event::MessageReceive');
    is($e->body, 'Hello', 'body');
    is($e->from_number, '+15551111111', 'from_number');
};

# ============================================================
# 7. MessageState event
# ============================================================
subtest 'MessageState event' => sub {
    my $e = SignalWire::Agents::Relay::Event->parse_event('messaging.state', {
        message_id    => 'm2',
        message_state => 'delivered',
    });
    isa_ok($e, 'SignalWire::Agents::Relay::Event::MessageState');
    is($e->message_state, 'delivered', 'message_state');
};

# ============================================================
# 8. AuthorizationState event
# ============================================================
subtest 'AuthorizationState event' => sub {
    my $e = SignalWire::Agents::Relay::Event->parse_event('signalwire.authorization.state', {
        authorization_state => 'enc:tag',
    });
    isa_ok($e, 'SignalWire::Agents::Relay::Event::AuthorizationState');
    is($e->authorization_state, 'enc:tag', 'authorization_state');
};

# ============================================================
# 9. Disconnect event
# ============================================================
subtest 'Disconnect event' => sub {
    my $e = SignalWire::Agents::Relay::Event->parse_event('signalwire.disconnect', {
        restart => 1,
    });
    isa_ok($e, 'SignalWire::Agents::Relay::Event::Disconnect');
    is($e->restart, 1, 'restart');
};

# ============================================================
# 10. CallReceive event
# ============================================================
subtest 'CallReceive event' => sub {
    my $e = SignalWire::Agents::Relay::Event->parse_event('calling.call.receive', {
        call_id => 'inbound-1',
        node_id => 'n1',
        context => 'office',
    });
    isa_ok($e, 'SignalWire::Agents::Relay::Event::CallReceive');
    is($e->context, 'office', 'context');
};

# ============================================================
# 11. Unknown event fallback
# ============================================================
subtest 'unknown event type' => sub {
    my $e = SignalWire::Agents::Relay::Event->parse_event('calling.call.future_thing', {
        foo => 'bar',
    });
    isa_ok($e, 'SignalWire::Agents::Relay::Event');
    is($e->event_type, 'calling.call.future_thing', 'type preserved');
    is($e->params->{foo}, 'bar', 'params preserved');
};

# ============================================================
# 12. All known event types parse
# ============================================================
subtest 'all event types parse' => sub {
    my @types = qw(
        calling.call.state calling.call.receive calling.call.dial
        calling.call.connect calling.call.disconnect calling.call.play
        calling.call.record calling.call.collect calling.call.detect
        calling.call.fax calling.call.tap calling.call.stream
        calling.call.transcribe calling.call.pay calling.call.send_digits
        calling.call.refer calling.conference calling.call.ai
        messaging.receive messaging.state
        signalwire.authorization.state signalwire.disconnect
    );
    for my $type (@types) {
        my $e = SignalWire::Agents::Relay::Event->parse_event($type, {});
        ok($e, "parsed: $type");
        isa_ok($e, 'SignalWire::Agents::Relay::Event');
    }
};

# ============================================================
# 13. Event types constants
# ============================================================
subtest 'EVENT_TYPES constant' => sub {
    my $types = EVENT_TYPES;
    is(ref $types, 'HASH', 'is hashref');
    ok(scalar(keys %$types) >= 22, 'at least 22 types');
};

# ============================================================
# 14. Action terminal states
# ============================================================
subtest 'ACTION_TERMINAL_STATES' => sub {
    my $ats = ACTION_TERMINAL_STATES;
    ok($ats->{'calling.call.play'}{finished}, 'play finished terminal');
    ok($ats->{'calling.call.record'}{no_input}, 'record no_input terminal');
};

done_testing;
