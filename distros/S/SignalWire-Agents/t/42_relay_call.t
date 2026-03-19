#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Agents::Relay::Call;
use SignalWire::Agents::Relay::Event;
use SignalWire::Agents::Relay::Action;

# ============================================================
# 1. Construction
# ============================================================
subtest 'construction' => sub {
    my $call = SignalWire::Agents::Relay::Call->new(
        call_id => 'c1',
        node_id => 'n1',
        tag     => 't1',
    );
    is($call->call_id, 'c1', 'call_id');
    is($call->node_id, 'n1', 'node_id');
    is($call->tag, 't1', 'tag');
    is($call->state, 'created', 'initial state');
};

# ============================================================
# 2. State transitions via events
# ============================================================
subtest 'state transitions' => sub {
    my $call = SignalWire::Agents::Relay::Call->new(call_id => 'c2', node_id => 'n2');

    for my $state (qw(ringing answered ending ended)) {
        my $event = SignalWire::Agents::Relay::Event->parse_event('calling.call.state', {
            call_id    => 'c2',
            call_state => $state,
        });
        $call->dispatch_event($event);
        is($call->state, $state, "state changed to $state");
    }
};

# ============================================================
# 3. End reason
# ============================================================
subtest 'end reason' => sub {
    my $call = SignalWire::Agents::Relay::Call->new(call_id => 'c3', node_id => 'n3');
    my $event = SignalWire::Agents::Relay::Event->parse_event('calling.call.state', {
        call_id    => 'c3',
        call_state => 'ended',
        end_reason => 'hangup',
    });
    $call->dispatch_event($event);
    is($call->end_reason, 'hangup', 'end_reason set');
};

# ============================================================
# 4. Event listener
# ============================================================
subtest 'event listener' => sub {
    my $call = SignalWire::Agents::Relay::Call->new(call_id => 'c4', node_id => 'n4');
    my @received;
    $call->on(sub { push @received, $_[1] });

    my $event = SignalWire::Agents::Relay::Event->parse_event('calling.call.state', {
        call_id    => 'c4',
        call_state => 'ringing',
    });
    $call->dispatch_event($event);
    is(scalar @received, 1, 'listener called once');
    is($received[0]->call_state, 'ringing', 'correct event');
};

# ============================================================
# 5. Actions resolved on call end
# ============================================================
subtest 'actions resolved on end' => sub {
    my $call = SignalWire::Agents::Relay::Call->new(call_id => 'c5', node_id => 'n5');
    my $action = SignalWire::Agents::Relay::Action::Play->new(
        control_id => 'ctl-5',
        call_id    => 'c5',
        node_id    => 'n5',
    );
    $call->_actions->{'ctl-5'} = $action;

    my $event = SignalWire::Agents::Relay::Event->parse_event('calling.call.state', {
        call_id    => 'c5',
        call_state => 'ended',
    });
    $call->dispatch_event($event);
    ok($action->is_done, 'action resolved on end');
};

# ============================================================
# 6. All simple methods exist
# ============================================================
subtest 'simple methods' => sub {
    my $call = SignalWire::Agents::Relay::Call->new(call_id => 'x', node_id => 'n');
    for my $m (qw(answer hangup pass connect disconnect hold unhold
                   denoise denoise_stop transfer join_conference leave_conference
                   echo join_room leave_room send_digits)) {
        ok($call->can($m), "has method: $m");
    }
};

# ============================================================
# 7. All action methods exist
# ============================================================
subtest 'action methods' => sub {
    my $call = SignalWire::Agents::Relay::Call->new(call_id => 'x', node_id => 'n');
    for my $m (qw(play record detect collect play_and_collect
                   send_fax receive_fax tap stream pay transcribe ai)) {
        ok($call->can($m), "has action method: $m");
    }
};

# ============================================================
# 8. Multiple listeners
# ============================================================
subtest 'multiple listeners' => sub {
    my $call = SignalWire::Agents::Relay::Call->new(call_id => 'c8', node_id => 'n8');
    my ($a, $b) = (0, 0);
    $call->on(sub { $a++ });
    $call->on(sub { $b++ });

    my $event = SignalWire::Agents::Relay::Event->parse_event('calling.call.state', {
        call_id    => 'c8',
        call_state => 'ringing',
    });
    $call->dispatch_event($event);
    is($a, 1, 'first listener called');
    is($b, 1, 'second listener called');
};

done_testing;
