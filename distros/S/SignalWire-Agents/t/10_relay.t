#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# ===== Constants =====
# Must use BEGIN block so constants are available at compile time
BEGIN { use_ok('SignalWire::Agents::Relay::Constants', ':all') }

# Protocol version
{
    my $pv = PROTOCOL_VERSION;
    is(ref $pv, 'HASH', 'PROTOCOL_VERSION is a hashref');
    is($pv->{major}, 2, 'protocol major version is 2');
    is($pv->{minor}, 0, 'protocol minor version is 0');
    is($pv->{revision}, 0, 'protocol revision is 0');
}

# Call states
{
    my $states = CALL_STATES;
    is(ref $states, 'ARRAY', 'CALL_STATES is arrayref');
    is(scalar @$states, 5, '5 call states');
    is(CALL_STATE_CREATED, 'created', 'CALL_STATE_CREATED');
    is(CALL_STATE_RINGING, 'ringing', 'CALL_STATE_RINGING');
    is(CALL_STATE_ANSWERED, 'answered', 'CALL_STATE_ANSWERED');
    is(CALL_STATE_ENDING, 'ending', 'CALL_STATE_ENDING');
    is(CALL_STATE_ENDED, 'ended', 'CALL_STATE_ENDED');
}

# Call terminal states
{
    my $terminal = CALL_TERMINAL_STATES;
    ok($terminal->{ended}, 'ended is terminal');
    ok(!$terminal->{ringing}, 'ringing is not terminal');
}

# Call end reasons
{
    my $reasons = CALL_END_REASONS;
    is($reasons->{hangup}, 'hangup', 'hangup end reason');
    is($reasons->{busy}, 'busy', 'busy end reason');
    is($reasons->{error}, 'error', 'error end reason');
}

# Dial states
{
    is(DIAL_STATE_DIALING, 'dialing', 'dial state dialing');
    is(DIAL_STATE_ANSWERED, 'answered', 'dial state answered');
    is(DIAL_STATE_FAILED, 'failed', 'dial state failed');
}

# Message states
{
    is(MESSAGE_STATE_QUEUED, 'queued', 'message state queued');
    is(MESSAGE_STATE_DELIVERED, 'delivered', 'message state delivered');
    is(MESSAGE_STATE_FAILED, 'failed', 'message state failed');
    my $terminal = MESSAGE_TERMINAL_STATES;
    ok($terminal->{delivered}, 'delivered is terminal');
    ok($terminal->{undelivered}, 'undelivered is terminal');
    ok($terminal->{failed}, 'failed is terminal');
    ok(!$terminal->{queued}, 'queued is not terminal');
}

# Event types
{
    my $types = EVENT_TYPES;
    is(ref $types, 'HASH', 'EVENT_TYPES is hashref');
    is($types->{'calling.call.state'}, 'CallState', 'calling.call.state event type');
    is($types->{'calling.call.play'}, 'CallPlay', 'calling.call.play event type');
    is($types->{'messaging.receive'}, 'MessageReceive', 'messaging.receive event type');
    is($types->{'signalwire.disconnect'}, 'Disconnect', 'signalwire.disconnect event type');
    ok(scalar(keys %$types) >= 22, 'at least 22 event types');
}

# Action terminal states
{
    my $ats = ACTION_TERMINAL_STATES;
    ok($ats->{'calling.call.play'}{finished}, 'play finished is terminal');
    ok($ats->{'calling.call.play'}{error}, 'play error is terminal');
    ok($ats->{'calling.call.record'}{no_input}, 'record no_input is terminal');
    ok($ats->{'calling.call.collect'}{no_match}, 'collect no_match is terminal');
}

# ===== Event =====
use_ok('SignalWire::Agents::Relay::Event');

# Parse known event type
{
    my $event = SignalWire::Agents::Relay::Event->parse_event('calling.call.state', {
        call_id    => 'c1',
        node_id    => 'n1',
        tag        => 't1',
        call_state => 'ringing',
    });
    isa_ok($event, 'SignalWire::Agents::Relay::Event::CallState');
    is($event->event_type, 'calling.call.state', 'event_type set');
    is($event->call_id, 'c1', 'call_id set');
    is($event->node_id, 'n1', 'node_id set');
    is($event->tag, 't1', 'tag set');
    is($event->call_state, 'ringing', 'call_state set');
}

# Parse dial event
{
    my $event = SignalWire::Agents::Relay::Event->parse_event('calling.call.dial', {
        tag        => 'dial-tag',
        dial_state => 'answered',
        node_id    => 'n2',
        call       => { call_id => 'winner-id', dial_winner => 1 },
    });
    isa_ok($event, 'SignalWire::Agents::Relay::Event::CallDial');
    is($event->tag, 'dial-tag', 'dial tag');
    is($event->dial_state, 'answered', 'dial_state');
    is($event->call->{call_id}, 'winner-id', 'nested call_id');
}

# Parse play event
{
    my $event = SignalWire::Agents::Relay::Event->parse_event('calling.call.play', {
        call_id    => 'c3',
        control_id => 'ctl1',
        state      => 'finished',
    });
    isa_ok($event, 'SignalWire::Agents::Relay::Event::CallPlay');
    is($event->control_id, 'ctl1', 'control_id set');
    is($event->state, 'finished', 'state set');
}

# Parse record event
{
    my $event = SignalWire::Agents::Relay::Event->parse_event('calling.call.record', {
        call_id    => 'c4',
        control_id => 'ctl2',
        state      => 'finished',
        url        => 'https://example.com/rec.mp3',
        duration   => 15,
        size       => 48000,
    });
    isa_ok($event, 'SignalWire::Agents::Relay::Event::CallRecord');
    is($event->url, 'https://example.com/rec.mp3', 'record url');
    is($event->duration, 15, 'record duration');
    is($event->size, 48000, 'record size');
}

# Parse collect event
{
    my $event = SignalWire::Agents::Relay::Event->parse_event('calling.call.collect', {
        call_id    => 'c5',
        control_id => 'ctl3',
        result     => { type => 'digit', params => { digits => '1234', terminator => '#' } },
    });
    isa_ok($event, 'SignalWire::Agents::Relay::Event::CallCollect');
    is($event->result->{type}, 'digit', 'collect result type');
}

# Parse detect event
{
    my $event = SignalWire::Agents::Relay::Event->parse_event('calling.call.detect', {
        call_id    => 'c6',
        control_id => 'ctl4',
        detect     => { type => 'machine', params => { event => 'HUMAN' } },
    });
    isa_ok($event, 'SignalWire::Agents::Relay::Event::CallDetect');
    is($event->detect->{type}, 'machine', 'detect type');
}

# Parse message receive event
{
    my $event = SignalWire::Agents::Relay::Event->parse_event('messaging.receive', {
        message_id    => 'msg-1',
        context       => 'office',
        direction     => 'inbound',
        from_number   => '+15551111111',
        to_number     => '+15552222222',
        body          => 'Hello',
        media         => [],
        segments      => 1,
        message_state => 'received',
    });
    isa_ok($event, 'SignalWire::Agents::Relay::Event::MessageReceive');
    is($event->message_id, 'msg-1', 'message_id set');
    is($event->from_number, '+15551111111', 'from_number set');
    is($event->body, 'Hello', 'body set');
}

# Parse message state event
{
    my $event = SignalWire::Agents::Relay::Event->parse_event('messaging.state', {
        message_id    => 'msg-2',
        message_state => 'delivered',
        direction     => 'outbound',
        from_number   => '+15551111111',
        to_number     => '+15552222222',
    });
    isa_ok($event, 'SignalWire::Agents::Relay::Event::MessageState');
    is($event->message_state, 'delivered', 'message_state set');
}

# Parse authorization state event
{
    my $event = SignalWire::Agents::Relay::Event->parse_event('signalwire.authorization.state', {
        authorization_state => 'enc-blob:tag-blob',
    });
    isa_ok($event, 'SignalWire::Agents::Relay::Event::AuthorizationState');
    is($event->authorization_state, 'enc-blob:tag-blob', 'authorization_state set');
}

# Parse disconnect event
{
    my $event = SignalWire::Agents::Relay::Event->parse_event('signalwire.disconnect', {
        restart => 1,
    });
    isa_ok($event, 'SignalWire::Agents::Relay::Event::Disconnect');
    is($event->restart, 1, 'restart flag set');
}

# Parse inbound call
{
    my $event = SignalWire::Agents::Relay::Event->parse_event('calling.call.receive', {
        call_id    => 'inbound-1',
        node_id    => 'n3',
        context    => 'support',
        call_state => 'ringing',
        device     => { type => 'phone', params => { from_number => '+15553333333', to_number => '+15554444444' } },
    });
    isa_ok($event, 'SignalWire::Agents::Relay::Event::CallReceive');
    is($event->call_id, 'inbound-1', 'inbound call_id');
    is($event->context, 'support', 'inbound context');
}

# Unknown event type falls back to base
{
    my $event = SignalWire::Agents::Relay::Event->parse_event('calling.call.unknown_future_thing', {
        foo => 'bar',
    });
    isa_ok($event, 'SignalWire::Agents::Relay::Event');
    is($event->event_type, 'calling.call.unknown_future_thing', 'unknown event type preserved');
    is($event->params->{foo}, 'bar', 'params preserved for unknown event');
}

# Parse all event types (ensure they all create objects without error)
{
    my @all_types = qw(
        calling.call.state calling.call.receive calling.call.dial
        calling.call.connect calling.call.disconnect calling.call.play
        calling.call.record calling.call.collect calling.call.detect
        calling.call.fax calling.call.tap calling.call.stream
        calling.call.transcribe calling.call.pay calling.call.send_digits
        calling.call.refer calling.conference calling.call.ai
        messaging.receive messaging.state
        signalwire.authorization.state signalwire.disconnect
    );
    for my $type (@all_types) {
        my $event = SignalWire::Agents::Relay::Event->parse_event($type, {});
        ok($event, "parsed event type: $type");
        isa_ok($event, 'SignalWire::Agents::Relay::Event');
    }
}

# ===== Action =====
use_ok('SignalWire::Agents::Relay::Action');

# Base action construction and wait
{
    my $action = SignalWire::Agents::Relay::Action->new(control_id => 'ctl-test');
    is($action->control_id, 'ctl-test', 'action control_id');
    ok(!$action->is_done, 'action not done initially');
    is($action->state, 'created', 'action initial state');

    # Resolve it
    $action->_resolve('test-result');
    ok($action->is_done, 'action done after resolve');
    is($action->result, 'test-result', 'action result set');

    # Wait should return immediately since done
    my $r = $action->wait(timeout => 1);
    is($r, 'test-result', 'wait returns result');
}

# Action on_completed callback
{
    my $called = 0;
    my $action = SignalWire::Agents::Relay::Action->new(control_id => 'ctl-cb');
    $action->on_completed(sub { $called = 1 });
    is($called, 0, 'callback not called yet');
    $action->_resolve('done');
    is($called, 1, 'callback called on resolve');
}

# on_completed callback when already done
{
    my $called = 0;
    my $action = SignalWire::Agents::Relay::Action->new(control_id => 'ctl-cb2');
    $action->_resolve('already');
    $action->on_completed(sub { $called = 1 });
    is($called, 1, 'callback called immediately when already done');
}

# Double resolve is ignored
{
    my $count = 0;
    my $action = SignalWire::Agents::Relay::Action->new(control_id => 'ctl-dbl');
    $action->on_completed(sub { $count++ });
    $action->_resolve('first');
    $action->_resolve('second');
    is($count, 1, 'callback only fires once');
    is($action->result, 'first', 'first result preserved');
}

# PlayAction subclass
{
    my $action = SignalWire::Agents::Relay::Action::Play->new(control_id => 'play-1');
    isa_ok($action, 'SignalWire::Agents::Relay::Action::Play');
    isa_ok($action, 'SignalWire::Agents::Relay::Action');
    is($action->_stop_method, 'calling.play.stop', 'play stop method');
    ok($action->can('pause'), 'play can pause');
    ok($action->can('resume'), 'play can resume');
    ok($action->can('volume'), 'play can volume');
}

# RecordAction subclass
{
    my $action = SignalWire::Agents::Relay::Action::Record->new(control_id => 'rec-1');
    isa_ok($action, 'SignalWire::Agents::Relay::Action::Record');
    is($action->_stop_method, 'calling.record.stop', 'record stop method');
    ok($action->can('pause'), 'record can pause');
    ok($action->can('resume'), 'record can resume');
}

# DetectAction
{
    my $action = SignalWire::Agents::Relay::Action::Detect->new(control_id => 'det-1');
    is($action->_stop_method, 'calling.detect.stop', 'detect stop method');
}

# CollectAction -- filters play events
{
    my $action = SignalWire::Agents::Relay::Action::Collect->new(control_id => 'coll-1');
    is($action->_stop_method, 'calling.collect.stop', 'collect stop method');
    ok($action->can('start_input_timers'), 'collect can start_input_timers');

    # Play event should be ignored
    my $play_event = SignalWire::Agents::Relay::Event->parse_event('calling.call.play', {
        control_id => 'coll-1',
        state      => 'finished',
    });
    $action->_handle_event($play_event);
    is($action->state, 'created', 'play event ignored by collect action');
}

# FaxAction
{
    my $send_action = SignalWire::Agents::Relay::Action::Fax->new(
        control_id => 'fax-s',
        _fax_type  => 'send',
    );
    is($send_action->_stop_method, 'calling.send_fax.stop', 'send fax stop method');

    my $recv_action = SignalWire::Agents::Relay::Action::Fax->new(
        control_id => 'fax-r',
        _fax_type  => 'receive',
    );
    is($recv_action->_stop_method, 'calling.receive_fax.stop', 'receive fax stop method');
}

# TapAction, StreamAction, PayAction, TranscribeAction, AIAction
{
    my $tap = SignalWire::Agents::Relay::Action::Tap->new(control_id => 'tap-1');
    is($tap->_stop_method, 'calling.tap.stop', 'tap stop method');

    my $stream = SignalWire::Agents::Relay::Action::Stream->new(control_id => 'str-1');
    is($stream->_stop_method, 'calling.stream.stop', 'stream stop method');

    my $pay = SignalWire::Agents::Relay::Action::Pay->new(control_id => 'pay-1');
    is($pay->_stop_method, 'calling.pay.stop', 'pay stop method');

    my $transcribe = SignalWire::Agents::Relay::Action::Transcribe->new(control_id => 'tx-1');
    is($transcribe->_stop_method, 'calling.transcribe.stop', 'transcribe stop method');

    my $ai = SignalWire::Agents::Relay::Action::AI->new(control_id => 'ai-1');
    is($ai->_stop_method, 'calling.ai.stop', 'ai stop method');
}

# ===== Call =====
use_ok('SignalWire::Agents::Relay::Call');

# Call construction
{
    my $call = SignalWire::Agents::Relay::Call->new(
        call_id => 'call-1',
        node_id => 'node-1',
        tag     => 'tag-1',
    );
    is($call->call_id, 'call-1', 'call call_id');
    is($call->node_id, 'node-1', 'call node_id');
    is($call->tag, 'tag-1', 'call tag');
    is($call->state, 'created', 'call initial state');
}

# Call event dispatch -- state changes
{
    my $call = SignalWire::Agents::Relay::Call->new(
        call_id => 'call-2',
        node_id => 'node-2',
    );

    my $event = SignalWire::Agents::Relay::Event->parse_event('calling.call.state', {
        call_id    => 'call-2',
        call_state => 'answered',
    });
    $call->dispatch_event($event);
    is($call->state, 'answered', 'call state updated to answered');
}

# Call event listener
{
    my $call = SignalWire::Agents::Relay::Call->new(
        call_id => 'call-3',
        node_id => 'node-3',
    );

    my $received_event;
    $call->on(sub {
        my ($c, $e) = @_;
        $received_event = $e;
    });

    my $event = SignalWire::Agents::Relay::Event->parse_event('calling.call.state', {
        call_id    => 'call-3',
        call_state => 'ringing',
    });
    $call->dispatch_event($event);
    ok($received_event, 'event listener called');
    is($received_event->call_state, 'ringing', 'listener received correct event');
}

# Call methods exist
{
    my $call = SignalWire::Agents::Relay::Call->new(call_id => 'x', node_id => 'n');
    my @simple_methods = qw(answer hangup pass connect disconnect hold unhold
        denoise denoise_stop transfer join_conference leave_conference echo
        bind_digit clear_digit_bindings live_transcribe live_translate
        join_room leave_room amazon_bedrock ai_message ai_hold ai_unhold
        user_event queue_enter queue_leave refer send_digits);
    for my $method (@simple_methods) {
        ok($call->can($method), "call has method: $method");
    }

    my @action_methods = qw(play record detect collect play_and_collect
        send_fax receive_fax tap stream pay transcribe ai);
    for my $method (@action_methods) {
        ok($call->can($method), "call has action method: $method");
    }
}

# Call ended resolves all actions
{
    my $call = SignalWire::Agents::Relay::Call->new(call_id => 'call-end', node_id => 'n');
    # Manually add an action
    my $action = SignalWire::Agents::Relay::Action::Play->new(
        control_id => 'ctl-end-test',
        call_id    => 'call-end',
        node_id    => 'n',
    );
    $call->_actions->{'ctl-end-test'} = $action;

    # Dispatch ended event
    my $event = SignalWire::Agents::Relay::Event->parse_event('calling.call.state', {
        call_id    => 'call-end',
        call_state => 'ended',
        end_reason => 'hangup',
    });
    $call->dispatch_event($event);

    is($call->state, 'ended', 'call state is ended');
    is($call->end_reason, 'hangup', 'end reason set');
    ok($action->is_done, 'action resolved on call end');
}

# ===== Message =====
use_ok('SignalWire::Agents::Relay::Message');

# Message construction and state tracking
{
    my $msg = SignalWire::Agents::Relay::Message->new(
        message_id  => 'msg-test',
        from_number => '+15551111111',
        to_number   => '+15552222222',
        body        => 'Hello',
        direction   => 'outbound',
    );
    is($msg->message_id, 'msg-test', 'message_id');
    is($msg->from_number, '+15551111111', 'from_number');
    is($msg->body, 'Hello', 'body');
    ok(!$msg->is_done, 'not done initially');
}

# Message dispatch -- terminal state
{
    my $msg = SignalWire::Agents::Relay::Message->new(
        message_id => 'msg-del',
        direction  => 'outbound',
    );

    my $cb_fired = 0;
    $msg->on_completed(sub { $cb_fired = 1 });

    my $event = SignalWire::Agents::Relay::Event->parse_event('messaging.state', {
        message_id    => 'msg-del',
        message_state => 'delivered',
        direction     => 'outbound',
    });
    $msg->dispatch_event($event);

    ok($msg->is_done, 'message done on delivered');
    is($msg->state, 'delivered', 'state is delivered');
    is($cb_fired, 1, 'on_completed fired');
}

# Message dispatch -- non-terminal state
{
    my $msg = SignalWire::Agents::Relay::Message->new(
        message_id => 'msg-prog',
        direction  => 'outbound',
    );

    my $event = SignalWire::Agents::Relay::Event->parse_event('messaging.state', {
        message_id    => 'msg-prog',
        message_state => 'sent',
    });
    $msg->dispatch_event($event);

    ok(!$msg->is_done, 'not done on sent');
    is($msg->state, 'sent', 'state is sent');
}

# ===== Client =====
use_ok('SignalWire::Agents::Relay::Client');

# Client construction
{
    my $client = SignalWire::Agents::Relay::Client->new(
        project  => 'proj-123',
        token    => 'tok-abc',
        host     => 'example.signalwire.com',
        contexts => ['office', 'support'],
    );
    is($client->project, 'proj-123', 'client project');
    is($client->token, 'tok-abc', 'client token');
    is($client->host, 'example.signalwire.com', 'client host');
    is_deeply($client->contexts, ['office', 'support'], 'client contexts');
    ok(!$client->connected, 'not connected initially');
    is($client->protocol, '', 'no protocol initially');
    is($client->authorization_state, '', 'no auth state initially');
}

# Client correlation maps initialization
{
    my $client = SignalWire::Agents::Relay::Client->new(
        project => 'p', token => 't', host => 'h',
    );
    is(ref $client->_pending, 'HASH', 'pending map is hash');
    is(ref $client->_calls, 'HASH', 'calls map is hash');
    is(ref $client->_pending_dials, 'HASH', 'pending_dials map is hash');
    is(ref $client->_messages, 'HASH', 'messages map is hash');
    is(scalar keys %{$client->_pending}, 0, 'pending map empty');
    is(scalar keys %{$client->_calls}, 0, 'calls map empty');
}

# Client handler registration
{
    my $client = SignalWire::Agents::Relay::Client->new(
        project => 'p', token => 't', host => 'h',
    );

    my $call_cb = sub { 'call' };
    my $msg_cb = sub { 'msg' };
    my $evt_cb = sub { 'evt' };

    $client->on_call($call_cb);
    $client->on_message($msg_cb);
    $client->on_event($evt_cb);

    is($client->_on_call, $call_cb, 'on_call handler set');
    is($client->_on_message, $msg_cb, 'on_message handler set');
    is($client->_on_event, $evt_cb, 'on_event handler set');
}

# Client _handle_event -- authorization state
{
    my $client = SignalWire::Agents::Relay::Client->new(
        project => 'p', token => 't', host => 'h',
    );
    $client->_handle_event({
        event_type => 'signalwire.authorization.state',
        params => { authorization_state => 'abc:def' },
    });
    is($client->authorization_state, 'abc:def', 'authorization_state stored');
}

# Client _handle_event -- inbound call
{
    my $client = SignalWire::Agents::Relay::Client->new(
        project => 'p', token => 't', host => 'h',
    );

    my $received_call;
    $client->on_call(sub { $received_call = $_[0] });

    $client->_handle_event({
        event_type => 'calling.call.receive',
        params => {
            call_id    => 'inbound-test',
            node_id    => 'n1',
            context    => 'office',
            call_state => 'ringing',
            device     => { type => 'phone', params => { from_number => '+15551234567' } },
        },
    });

    ok($received_call, 'on_call handler fired');
    isa_ok($received_call, 'SignalWire::Agents::Relay::Call');
    is($received_call->call_id, 'inbound-test', 'inbound call call_id');
    is($received_call->context, 'office', 'inbound call context');
    ok(exists $client->_calls->{'inbound-test'}, 'call registered in calls map');
}

# Client _handle_event -- inbound message
{
    my $client = SignalWire::Agents::Relay::Client->new(
        project => 'p', token => 't', host => 'h',
    );

    my $received_msg;
    $client->on_message(sub { $received_msg = $_[0] });

    $client->_handle_event({
        event_type => 'messaging.receive',
        params => {
            message_id  => 'msg-inbound',
            context     => 'sms',
            from_number => '+15559999999',
            to_number   => '+15558888888',
            body        => 'Hi there',
        },
    });

    ok($received_msg, 'on_message handler fired');
    isa_ok($received_msg, 'SignalWire::Agents::Relay::Event::MessageReceive');
}

# Client _handle_event -- message state tracking
{
    my $client = SignalWire::Agents::Relay::Client->new(
        project => 'p', token => 't', host => 'h',
    );

    # Manually add a tracked message
    my $msg = SignalWire::Agents::Relay::Message->new(
        message_id => 'msg-track',
        direction  => 'outbound',
    );
    $client->_messages->{'msg-track'} = $msg;

    # Dispatch sent state
    $client->_handle_event({
        event_type => 'messaging.state',
        params => {
            message_id    => 'msg-track',
            message_state => 'sent',
        },
    });
    is($msg->state, 'sent', 'message state updated');
    ok(!$msg->is_done, 'not terminal yet');

    # Dispatch delivered state
    $client->_handle_event({
        event_type => 'messaging.state',
        params => {
            message_id    => 'msg-track',
            message_state => 'delivered',
        },
    });
    is($msg->state, 'delivered', 'message state delivered');
    ok($msg->is_done, 'message is terminal');
    ok(!exists $client->_messages->{'msg-track'}, 'terminal message removed from map');
}

# Client _handle_event -- call state routing
{
    my $client = SignalWire::Agents::Relay::Client->new(
        project => 'p', token => 't', host => 'h',
    );

    # Register a call
    my $call = SignalWire::Agents::Relay::Call->new(
        call_id => 'c-route',
        node_id => 'n',
        _client => $client,
    );
    $client->_calls->{'c-route'} = $call;

    # Dispatch state event
    $client->_handle_event({
        event_type => 'calling.call.state',
        params => { call_id => 'c-route', call_state => 'answered' },
    });
    is($call->state, 'answered', 'call state updated via client routing');

    # Dispatch ended
    $client->_handle_event({
        event_type => 'calling.call.state',
        params => { call_id => 'c-route', call_state => 'ended' },
    });
    is($call->state, 'ended', 'call state ended');
    ok(!exists $client->_calls->{'c-route'}, 'ended call removed from map');
}

# Client _handle_event -- dial completion
{
    my $client = SignalWire::Agents::Relay::Client->new(
        project => 'p', token => 't', host => 'h',
    );

    my $resolved_call;
    $client->_pending_dials->{'dial-tag-1'} = {
        resolve => sub { $resolved_call = $_[0] },
        reject  => sub { die "should not reject" },
    };

    # First, a state event during dial (creates the call object)
    $client->_handle_event({
        event_type => 'calling.call.state',
        params => {
            call_id    => 'dial-call-1',
            node_id    => 'dn1',
            tag        => 'dial-tag-1',
            call_state => 'created',
            device     => { type => 'phone' },
        },
    });
    ok(exists $client->_calls->{'dial-call-1'}, 'dial leg registered during state event');

    # Then the dial completion event
    $client->_handle_event({
        event_type => 'calling.call.dial',
        params => {
            tag        => 'dial-tag-1',
            dial_state => 'answered',
            call       => { call_id => 'dial-call-1', node_id => 'dn1' },
        },
    });
    ok($resolved_call, 'dial resolved');
    isa_ok($resolved_call, 'SignalWire::Agents::Relay::Call');
    is($resolved_call->call_id, 'dial-call-1', 'resolved call_id');
    is($resolved_call->state, 'answered', 'resolved call state');
    ok($resolved_call->dial_winner, 'dial_winner flag set');
}

# Client _handle_event -- dial failed
{
    my $client = SignalWire::Agents::Relay::Client->new(
        project => 'p', token => 't', host => 'h',
    );

    my $rejected;
    $client->_pending_dials->{'dial-tag-fail'} = {
        resolve => sub { die "should not resolve" },
        reject  => sub { $rejected = $_[0] },
    };

    $client->_handle_event({
        event_type => 'calling.call.dial',
        params => {
            tag        => 'dial-tag-fail',
            dial_state => 'failed',
        },
    });
    is($rejected, 'Dial failed', 'dial failure rejected');
}

# Client _handle_disconnect
{
    my $client = SignalWire::Agents::Relay::Client->new(
        project => 'p', token => 't', host => 'h',
    );
    $client->protocol('old-proto');
    $client->authorization_state('old-auth');

    # Non-restart disconnect
    $client->_handle_disconnect({ restart => 0 });
    is($client->protocol, 'old-proto', 'protocol preserved on non-restart');
    is($client->authorization_state, 'old-auth', 'auth preserved on non-restart');

    # Restart disconnect
    $client->_handle_disconnect({ restart => 1 });
    is($client->protocol, '', 'protocol cleared on restart');
    is($client->authorization_state, '', 'auth cleared on restart');
}

# Client _handle_message -- JSON-RPC response matching
{
    my $client = SignalWire::Agents::Relay::Client->new(
        project => 'p', token => 't', host => 'h',
    );

    my $resolved;
    $client->_pending->{'rpc-id-1'} = {
        resolve => sub { $resolved = $_[0] },
        reject  => sub { die "should not reject" },
    };

    use JSON qw(encode_json);
    $client->_handle_message(encode_json({
        jsonrpc => '2.0',
        id      => 'rpc-id-1',
        result  => { code => '200', message => 'OK' },
    }));

    ok($resolved, 'RPC response matched');
    is($resolved->{code}, '200', 'result code matched');
    ok(!exists $client->_pending->{'rpc-id-1'}, 'pending removed after resolve');
}

# Client _handle_message -- JSON-RPC error
{
    my $client = SignalWire::Agents::Relay::Client->new(
        project => 'p', token => 't', host => 'h',
    );

    my $rejected;
    $client->_pending->{'rpc-err'} = {
        resolve => sub { die "should not resolve" },
        reject  => sub { $rejected = $_[0] },
    };

    $client->_handle_message(encode_json({
        jsonrpc => '2.0',
        id      => 'rpc-err',
        error   => { code => -32600, message => 'Invalid request' },
    }));

    ok($rejected, 'RPC error matched');
    is($rejected->{code}, -32600, 'error code matched');
}

# Client _handle_message -- signalwire.ping pong
{
    # Just verify it does not crash
    my $client = SignalWire::Agents::Relay::Client->new(
        project => 'p', token => 't', host => 'h',
    );
    # Provide a mock _send that captures output
    my @sent;
    {
        no warnings 'redefine';
        *SignalWire::Agents::Relay::Client::_send = sub {
            my ($self, $msg) = @_;
            push @sent, $msg;
        };
    }

    $client->_handle_message(encode_json({
        jsonrpc => '2.0',
        id      => 'ping-123',
        method  => 'signalwire.ping',
        params  => {},
    }));

    ok(scalar @sent >= 1, 'pong sent');
    is($sent[0]->{id}, 'ping-123', 'pong id matches ping');
    is_deeply($sent[0]->{result}, {}, 'pong has empty result');
}

# Client _handle_message -- signalwire.event ACK
{
    my $client = SignalWire::Agents::Relay::Client->new(
        project => 'p', token => 't', host => 'h',
    );
    my @sent;
    {
        no warnings 'redefine';
        *SignalWire::Agents::Relay::Client::_send = sub {
            my ($self, $msg) = @_;
            push @sent, $msg;
        };
    }

    $client->_handle_message(encode_json({
        jsonrpc => '2.0',
        id      => 'evt-456',
        method  => 'signalwire.event',
        params  => {
            event_type => 'calling.call.state',
            params => { call_id => 'ack-test', call_state => 'ringing' },
        },
    }));

    # Check ACK was sent
    my @acks = grep { $_->{id} eq 'evt-456' && exists $_->{result} } @sent;
    ok(scalar @acks >= 1, 'ACK sent for event');
    is_deeply($acks[0]->{result}, {}, 'ACK has empty result');
}

done_testing();
