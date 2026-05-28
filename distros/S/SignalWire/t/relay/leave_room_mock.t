#!/usr/bin/env perl
# Real-mock-backed tests for SignalWire::Relay::Call::leave_room.
#
# Mirrors signalwire-python's test for Call.leave_room(**kwargs):
# verify the slurpy hash gets forwarded onto the wire as part of the
# calling.leave_room params payload (alongside the call_id / node_id
# from _base_params).

use strict;
use warnings;
use Test::More;
use FindBin ();
use lib "$FindBin::Bin/../lib";
use Time::HiRes qw(time);

use RelayMockTest;
use SignalWire::Relay::Client;
use SignalWire::Relay::Call;

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

# ---------------------------------------------------------------------------
# leave_room — bare invocation (no kwargs)
# ---------------------------------------------------------------------------

subtest 'leave_room bare sends calling.leave_room with call_id+node_id' => sub {
    my $client = _connected_client();

    my $captured;
    $client->on_call(sub { $captured = $_[0]; $_[0]->answer; });
    RelayMockTest::inbound_call(call_id => 'c-leave-1', auto_states => ['created']);
    _pump_until($client, 5, sub { $captured });

    $captured->leave_room;
    _pump_until($client, 2, sub { 0 });

    my $entries = RelayMockTest::journal_recv(method => 'calling.leave_room');
    ok(scalar @$entries, 'calling.leave_room journaled');
    my $p = $entries->[-1]{frame}{params};
    is($p->{call_id}, 'c-leave-1', 'call_id passed via _base_params');
    ok(defined $p->{node_id}, 'node_id passed via _base_params');
    $client->disconnect;
};

# ---------------------------------------------------------------------------
# leave_room — kwargs slurpy forwarded to wire
# ---------------------------------------------------------------------------

subtest 'leave_room with kwargs forwards to wire (Python parity: **kwargs)' => sub {
    my $client = _connected_client();

    my $captured;
    $client->on_call(sub { $captured = $_[0]; $_[0]->answer; });
    RelayMockTest::inbound_call(call_id => 'c-leave-2', auto_states => ['created']);
    _pump_until($client, 5, sub { $captured });

    $captured->leave_room(reason => 'guest_kicked', extra_param => 'xyz');
    _pump_until($client, 2, sub { 0 });

    my $entries = RelayMockTest::journal_recv(method => 'calling.leave_room');
    ok(scalar @$entries, 'calling.leave_room journaled');
    my $p = $entries->[-1]{frame}{params};
    is($p->{reason},      'guest_kicked', 'kwargs.reason on wire');
    is($p->{extra_param}, 'xyz',          'kwargs.extra_param on wire');
    is($p->{call_id},     'c-leave-2',    'call_id still present');
    $client->disconnect;
};

done_testing();
