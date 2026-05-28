#!/usr/bin/env perl
# Real-mock-backed tests for SDK event dispatch / routing edge cases.
# Mirrors signalwire-python tests/unit/relay/test_event_dispatch_mock.py.

use strict;
use warnings;
use Test::More;
use FindBin ();
use lib "$FindBin::Bin/../lib";
use Time::HiRes qw(sleep time);
use JSON ();

use RelayMockTest;
use SignalWire::Relay::Client;

sub _connected_client {
    my $client = RelayMockTest::client(contexts => ['default']);
    $client->connect;
    return $client;
}

sub _pump_until {
    my ($client, $secs, $cb) = @_;
    my $deadline = time() + $secs;
    while (time() < $deadline) {
        return 1 if $cb->();
        eval { $client->_read_once };
    }
    return $cb->() ? 1 : 0;
}

sub _answered_call {
    my ($client, $call_id) = @_;
    my $captured;
    $client->on_call(sub {
        my ($call) = @_;
        $captured = $call;
        $call->answer;
    });
    RelayMockTest::inbound_call(call_id => $call_id, auto_states => ['created']);
    _pump_until($client, 5, sub { $captured });
    _pump_until($client, 1, sub { 0 });
    $captured->state('answered');
    return $captured;
}

sub _bare_event_frame {
    my ($event_type, $params) = @_;
    return {
        jsonrpc => '2.0',
        id      => 'evt-' . int(rand 1_000_000),
        method  => 'signalwire.event',
        params  => {
            event_type => $event_type,
            params     => $params,
        },
    };
}

# ---------------------------------------------------------------------------
# Sub-command journaling
# ---------------------------------------------------------------------------

subtest 'record pause journals calling.record.pause' => sub {
    my $client = _connected_client();
    my $call = _answered_call($client, 'ec-rec-pa');
    my $action = $call->record(record => { audio => { format => 'wav' } });
    $action->pause(behavior => 'continuous');
    my $pauses = RelayMockTest::journal_recv(method => 'calling.record.pause');
    ok(scalar @$pauses, 'pause journaled');
    my $p = $pauses->[-1]{frame}{params};
    is($p->{control_id}, $action->control_id, 'control_id matches');
    is($p->{behavior},   'continuous',         'behavior on wire');
    $client->disconnect;
};

subtest 'record resume journals calling.record.resume' => sub {
    my $client = _connected_client();
    my $call = _answered_call($client, 'ec-rec-re');
    my $action = $call->record(record => { audio => { format => 'wav' } });
    $action->resume;
    my $resumes = RelayMockTest::journal_recv(method => 'calling.record.resume');
    ok(scalar @$resumes, 'resume journaled');
    is($resumes->[-1]{frame}{params}{control_id}, $action->control_id,
       'control_id matches');
    $client->disconnect;
};

subtest 'collect start_input_timers journals correctly' => sub {
    my $client = _connected_client();
    my $call = _answered_call($client, 'ec-col-sit');
    my $action = $call->collect(
        digits             => { max => 4 },
        start_input_timers => JSON::false,
    );
    $action->start_input_timers;
    my $starts = RelayMockTest::journal_recv(
        method => 'calling.collect.start_input_timers'
    );
    ok(scalar @$starts, 'start_input_timers journaled');
    is($starts->[-1]{frame}{params}{control_id}, $action->control_id,
       'control_id matches');
    $client->disconnect;
};

subtest 'play volume carries negative value' => sub {
    my $client = _connected_client();
    my $call = _answered_call($client, 'ec-pvol');
    my $action = $call->play(
        play => [{ type => 'silence', params => { duration => 60 } }],
    );
    $action->volume(-5.5);
    my $vol = RelayMockTest::journal_recv(method => 'calling.play.volume');
    ok(scalar @$vol, 'volume journaled');
    cmp_ok($vol->[-1]{frame}{params}{volume}, '==', -5.5,
           'negative volume preserved');
    $client->disconnect;
};

# ---------------------------------------------------------------------------
# Unknown event types — recv loop survives
# ---------------------------------------------------------------------------

subtest 'unknown event type does not crash' => sub {
    my $client = _connected_client();
    RelayMockTest::push_frame(_bare_event_frame('nonsense.unknown',
                                                  { foo => 'bar' }));
    _pump_until($client, 0.5, sub { 0 });
    ok($client->connected, 'client still connected');
    $client->disconnect;
};

subtest 'event with bad call_id is dropped' => sub {
    my $client = _connected_client();
    RelayMockTest::push_frame(_bare_event_frame('calling.call.play', {
        call_id    => 'no-such-call-bogus',
        control_id => 'stranger',
        state      => 'playing',
    }));
    _pump_until($client, 0.5, sub { 0 });
    ok($client->connected, 'client still connected');
    $client->disconnect;
};

subtest 'event with empty event_type is dropped' => sub {
    my $client = _connected_client();
    RelayMockTest::push_frame(_bare_event_frame('', { call_id => 'x' }));
    _pump_until($client, 0.5, sub { 0 });
    ok($client->connected, 'client still connected');
    $client->disconnect;
};

# ---------------------------------------------------------------------------
# Multi-action concurrency: 3 actions on one call
# ---------------------------------------------------------------------------

subtest 'three concurrent actions resolve independently' => sub {
    my $client = _connected_client();
    my $call = _answered_call($client, 'ec-3acts');
    my $play1 = $call->play(
        play => [{ type => 'silence', params => { duration => 60 } }],
    );
    my $play2 = $call->play(
        play => [{ type => 'silence', params => { duration => 60 } }],
    );
    my $rec = $call->record(record => { audio => { format => 'wav' } });

    # Fire only play1's finished.
    RelayMockTest::push_frame(_bare_event_frame('calling.call.play', {
        call_id    => 'ec-3acts',
        control_id => $play1->control_id,
        state      => 'finished',
    }));
    _pump_until($client, 5, sub { $play1->is_done });
    ok($play1->is_done,  'play1 done');
    ok(!$play2->is_done, 'play2 still pending');
    ok(!$rec->is_done,   'rec still pending');

    # Fire play2's.
    RelayMockTest::push_frame(_bare_event_frame('calling.call.play', {
        call_id    => 'ec-3acts',
        control_id => $play2->control_id,
        state      => 'finished',
    }));
    _pump_until($client, 5, sub { $play2->is_done });
    ok($play2->is_done, 'play2 done');
    ok(!$rec->is_done,  'rec still pending');
    $client->disconnect;
};

# ---------------------------------------------------------------------------
# Event ACK round-trip
# ---------------------------------------------------------------------------

subtest 'event ack sent back to server' => sub {
    my $client = _connected_client();
    my $evt_id = 'evt-ack-test-1';
    RelayMockTest::push_frame({
        jsonrpc => '2.0',
        id      => $evt_id,
        method  => 'signalwire.event',
        params  => {
            event_type => 'calling.call.play',
            params     => {
                call_id    => 'anything',
                control_id => 'x',
                state      => 'playing',
            },
        },
    });
    _pump_until($client, 1, sub { 0 });

    my $j = RelayMockTest::journal_all();
    my @acks = grep {
        ($_->{direction} // '') eq 'recv'
        && ($_->{frame}{id} // '') eq $evt_id
        && exists $_->{frame}{result};
    } @$j;
    ok(scalar @acks, "event ACK with id=$evt_id present");
    $client->disconnect;
};

# ---------------------------------------------------------------------------
# Server ping
# ---------------------------------------------------------------------------

subtest 'server ping acked by SDK' => sub {
    my $client = _connected_client();
    my $ping_id = 'ping-test-1';
    RelayMockTest::push_frame({
        jsonrpc => '2.0',
        id      => $ping_id,
        method  => 'signalwire.ping',
        params  => {},
    });
    _pump_until($client, 1, sub { 0 });
    my $j = RelayMockTest::journal_all();
    my @pongs = grep {
        ($_->{direction} // '') eq 'recv'
        && ($_->{frame}{id} // '') eq $ping_id
        && exists $_->{frame}{result};
    } @$j;
    ok(scalar @pongs, 'SDK responded to ping');
    $client->disconnect;
};

# ---------------------------------------------------------------------------
# Authorization state
# ---------------------------------------------------------------------------

subtest 'authorization state event captured' => sub {
    my $client = _connected_client();
    RelayMockTest::push_frame(_bare_event_frame(
        'signalwire.authorization.state',
        { authorization_state => 'test-auth-state-blob' },
    ));
    _pump_until($client, 2, sub {
        $client->authorization_state eq 'test-auth-state-blob';
    });
    is($client->authorization_state, 'test-auth-state-blob',
       'authorization_state stored');
    $client->disconnect;
};

# ---------------------------------------------------------------------------
# calling.error event — does not raise
# ---------------------------------------------------------------------------

subtest 'calling.error event does not crash' => sub {
    my $client = _connected_client();
    RelayMockTest::push_frame(_bare_event_frame(
        'calling.error',
        { code => '5001', message => 'synthetic error' },
    ));
    _pump_until($client, 0.5, sub { 0 });
    ok($client->connected, 'client still connected');
    $client->disconnect;
};

# ---------------------------------------------------------------------------
# Call state event for an answered call updates Call.state
# ---------------------------------------------------------------------------

subtest 'call state event updates state' => sub {
    my $client = _connected_client();
    my $call = _answered_call($client, 'ec-stt');
    RelayMockTest::push_frame(_bare_event_frame('calling.call.state', {
        call_id    => 'ec-stt',
        call_state => 'ending',
        direction  => 'inbound',
    }));
    _pump_until($client, 5, sub { $call->state eq 'ending' });
    is($call->state, 'ending', 'state advanced to ending');
    $client->disconnect;
};

subtest 'call listener fires on event' => sub {
    my $client = _connected_client();
    my $call = _answered_call($client, 'ec-list');
    my @seen;
    $call->on(sub {
        my ($c, $event) = @_;
        push @seen, $event;
    });
    RelayMockTest::push_frame(_bare_event_frame('calling.call.play', {
        call_id    => 'ec-list',
        control_id => 'x',
        state      => 'playing',
    }));
    _pump_until($client, 5, sub { scalar @seen });
    ok(scalar @seen, 'listener fired');
    is($seen[0]->event_type, 'calling.call.play', 'event_type matches');
    $client->disconnect;
};

# ---------------------------------------------------------------------------
# Tag-based dial routing — call.call_id nested
# ---------------------------------------------------------------------------

subtest 'dial event routes via tag when no top-level call_id' => sub {
    my $client = _connected_client();
    RelayMockTest::arm_dial(
        tag            => 'ec-tag-route',
        winner_call_id => 'WINTAG',
        states         => ['created', 'answered'],
        node_id        => 'n',
        device         => { type => 'phone', params => {} },
    );
    my $call = $client->dial(
        devices => [[
            { type => 'phone',
              params => { to_number => '+1', from_number => '+2' } },
        ]],
        tag     => 'ec-tag-route',
        timeout => 5,
    );
    is($call->call_id, 'WINTAG', 'dial routed via tag without top-level call_id');
    my $sends = RelayMockTest::journal_send(event_type => 'calling.call.dial');
    ok(scalar @$sends, 'calling.call.dial event in journal');
    my $inner = $sends->[-1]{frame}{params}{params};
    ok(!exists $inner->{call_id}, 'no top-level call_id');
    is($inner->{call}{call_id}, 'WINTAG', 'nested call.call_id is winner');
    $client->disconnect;
};

done_testing();
