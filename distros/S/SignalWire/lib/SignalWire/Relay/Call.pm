package SignalWire::Relay::Call;
use strict;
use warnings;
use Moo;

use SignalWire::Relay::Action;
use SignalWire::Relay::Constants qw(CALL_TERMINAL_STATES ACTION_TERMINAL_STATES);

has 'call_id'    => ( is => 'ro', required => 1 );
has 'node_id'    => ( is => 'rw', default => sub { '' } );
has 'tag'        => ( is => 'ro', default => sub { '' } );
has 'state'      => ( is => 'rw', default => sub { 'created' } );
has 'device'     => ( is => 'rw', default => sub { {} } );
has 'end_reason' => ( is => 'rw', default => sub { '' } );
has 'peer'       => ( is => 'rw', default => sub { {} } );
has 'context'    => ( is => 'rw', default => sub { '' } );
has 'dial_winner' => ( is => 'rw', default => sub { 0 } );

has '_client'  => ( is => 'rw', default => sub { undef } );
has '_actions' => ( is => 'rw', default => sub { {} } );   # control_id => Action
has '_on_event' => ( is => 'rw', default => sub { [] } );  # event callbacks

# Helper to generate a UUID-like control_id
sub _generate_uuid {
    my @hex = map { sprintf('%02x', int(rand(256))) } 1..16;
    $hex[6] = sprintf('%02x', (hex($hex[6]) & 0x0f) | 0x40);
    $hex[8] = sprintf('%02x', (hex($hex[8]) & 0x3f) | 0x80);
    return join('-',
        join('', @hex[0..3]),
        join('', @hex[4..5]),
        join('', @hex[6..7]),
        join('', @hex[8..9]),
        join('', @hex[10..15]),
    );
}

sub _base_params {
    my ($self) = @_;
    return (
        node_id => $self->node_id,
        call_id => $self->call_id,
    );
}

sub _execute {
    my ($self, $method, %extra) = @_;
    my $client = $self->_client;
    die "No client attached to call" unless $client;
    my %params = ($self->_base_params, %extra);
    return $client->execute($method, \%params);
}

# Start an action-based method: creates the Action, registers it, executes the RPC
sub _start_action {
    my ($self, $method, $action_class, %extra) = @_;
    my $control_id = _generate_uuid();
    my %params = ($self->_base_params, control_id => $control_id, %extra);

    my $action = $action_class->new(
        control_id => $control_id,
        call_id    => $self->call_id,
        node_id    => $self->node_id,
        _client    => $self->_client,
    );
    $self->_actions->{$control_id} = $action;

    my $client = $self->_client;
    if ($client) {
        my $result = $client->execute($method, \%params);
        # If call is gone (404/410), resolve action immediately
        if (ref $result eq 'HASH' && $result->{code} && $result->{code} =~ /^(404|410)$/) {
            $action->_resolve(undef);
        }
    }

    return $action;
}

# --- Event dispatch ---

sub dispatch_event {
    my ($self, $event) = @_;
    my $event_type = $event->event_type // '';

    # Update call state from state events
    if ($event_type eq 'calling.call.state') {
        my $new_state = $event->call_state // '';
        $self->state($new_state);
        $self->end_reason($event->end_reason) if $event->can('end_reason') && $event->end_reason;
        $self->peer($event->peer) if $event->can('peer') && ref $event->peer eq 'HASH' && %{$event->peer};

        # If call ended, resolve all pending actions
        if (CALL_TERMINAL_STATES->{$new_state}) {
            $self->_resolve_all_actions;
        }
    }
    elsif ($event_type eq 'calling.call.connect') {
        $self->peer($event->peer) if $event->can('peer');
    }

    # Route to action by control_id
    my $control_id = $event->can('control_id') ? $event->control_id : '';
    if ($control_id && exists $self->_actions->{$control_id}) {
        my $action = $self->_actions->{$control_id};
        # The action decides whether to consume the event. play_and_collect's
        # CollectAction filters calling.call.play events out entirely so they
        # neither dispatch nor terminally resolve.
        my $consumed = 1;
        if ($action->can('_should_consume_event')) {
            $consumed = $action->_should_consume_event($event);
        }
        if ($consumed) {
            $action->_handle_event($event);

            # Check if action reached terminal state — but only for events
            # the action consumed, AND only if the action hasn't already
            # decided to resolve itself in _handle_event (e.g. Detect on
            # first detect payload).
            unless ($action->completed) {
                my $terminal = ACTION_TERMINAL_STATES->{$event_type} // {};
                my $action_state = $event->can('state') ? ($event->state // '') : '';
                if ($terminal->{$action_state}) {
                    $action->_resolve($event);
                }
            }
            if ($action->completed) {
                delete $self->_actions->{$control_id};
            }
        }
    }

    # Fire registered event callbacks
    for my $cb (@{$self->_on_event}) {
        eval { $cb->($self, $event) };
        warn "Call event callback error: $@" if $@;
    }
}

# Register an event listener
sub on {
    my ($self, $cb) = @_;
    push @{$self->_on_event}, $cb;
    return $self;
}

# Resolve all pending actions (e.g., on call ended or call-gone)
sub _resolve_all_actions {
    my ($self) = @_;
    for my $action (values %{$self->_actions}) {
        $action->_resolve(undef) unless $action->completed;
    }
    $self->_actions({});
}

# --- Simple fire-and-response methods ---

sub answer {
    my ($self, %opts) = @_;
    return $self->_execute('calling.answer', %opts);
}

sub hangup {
    my ($self, %opts) = @_;
    return $self->_execute('calling.end', %opts);
}

sub pass {
    my ($self) = @_;
    return $self->_execute('calling.pass');
}

sub connect {
    my ($self, %opts) = @_;
    return $self->_execute('calling.connect', %opts);
}

sub disconnect {
    my ($self) = @_;
    return $self->_execute('calling.disconnect');
}

sub hold {
    my ($self) = @_;
    return $self->_execute('calling.hold');
}

sub unhold {
    my ($self) = @_;
    return $self->_execute('calling.unhold');
}

sub denoise {
    my ($self) = @_;
    return $self->_execute('calling.denoise');
}

sub denoise_stop {
    my ($self) = @_;
    return $self->_execute('calling.denoise.stop');
}

sub transfer {
    my ($self, %opts) = @_;
    return $self->_execute('calling.transfer', %opts);
}

sub join_conference {
    my ($self, %opts) = @_;
    return $self->_execute('calling.join_conference', %opts);
}

sub leave_conference {
    my ($self, %opts) = @_;
    return $self->_execute('calling.leave_conference', %opts);
}

sub echo {
    my ($self, %opts) = @_;
    return $self->_execute('calling.echo', %opts);
}

sub bind_digit {
    my ($self, %opts) = @_;
    return $self->_execute('calling.bind_digit', %opts);
}

sub clear_digit_bindings {
    my ($self, %opts) = @_;
    return $self->_execute('calling.clear_digit_bindings', %opts);
}

sub live_transcribe {
    my ($self, %opts) = @_;
    return $self->_execute('calling.live_transcribe', %opts);
}

sub live_translate {
    my ($self, %opts) = @_;
    return $self->_execute('calling.live_translate', %opts);
}

sub join_room {
    my ($self, %opts) = @_;
    return $self->_execute('calling.join_room', %opts);
}

sub leave_room {
    my ($self, %opts) = @_;
    # Python parity: Call.leave_room(**kwargs). Forwards any caller-provided
    # kwargs to the Relay leave_room dispatch (slurpy hash on the Perl side
    # ≡ **kwargs on the Python side).
    return $self->_execute('calling.leave_room', %opts);
}

sub amazon_bedrock {
    my ($self, %opts) = @_;
    return $self->_execute('calling.amazon_bedrock', %opts);
}

sub ai_message {
    my ($self, %opts) = @_;
    return $self->_execute('calling.ai_message', %opts);
}

sub ai_hold {
    my ($self, %opts) = @_;
    return $self->_execute('calling.ai_hold', %opts);
}

sub ai_unhold {
    my ($self, %opts) = @_;
    return $self->_execute('calling.ai_unhold', %opts);
}

sub user_event {
    my ($self, %opts) = @_;
    return $self->_execute('calling.user_event', %opts);
}

sub queue_enter {
    my ($self, %opts) = @_;
    return $self->_execute('calling.queue.enter', %opts);
}

sub queue_leave {
    my ($self, %opts) = @_;
    return $self->_execute('calling.queue.leave', %opts);
}

sub refer {
    my ($self, %opts) = @_;
    return $self->_execute('calling.refer', %opts);
}

sub send_digits {
    my ($self, %opts) = @_;
    return $self->_execute('calling.send_digits', %opts);
}

# --- Action-based methods (control_id tracking) ---

sub play {
    my ($self, %opts) = @_;
    return $self->_start_action('calling.play', 'SignalWire::Relay::Action::Play', %opts);
}

sub record {
    my ($self, %opts) = @_;
    return $self->_start_action('calling.record', 'SignalWire::Relay::Action::Record', %opts);
}

sub detect {
    my ($self, %opts) = @_;
    return $self->_start_action('calling.detect', 'SignalWire::Relay::Action::Detect', %opts);
}

sub collect {
    my ($self, %opts) = @_;
    return $self->_start_action('calling.collect', 'SignalWire::Relay::Action::StandaloneCollect', %opts);
}

sub play_and_collect {
    my ($self, %opts) = @_;
    return $self->_start_action('calling.play_and_collect', 'SignalWire::Relay::Action::Collect', %opts);
}

sub send_fax {
    my ($self, %opts) = @_;
    my $action = $self->_start_action('calling.send_fax', 'SignalWire::Relay::Action::Fax', %opts);
    return $action;
}

sub receive_fax {
    my ($self, %opts) = @_;
    my $control_id = _generate_uuid();
    my %params = ($self->_base_params, control_id => $control_id, %opts);

    my $action = SignalWire::Relay::Action::Fax->new(
        control_id => $control_id,
        call_id    => $self->call_id,
        node_id    => $self->node_id,
        _client    => $self->_client,
        _fax_type  => 'receive',
    );
    $self->_actions->{$control_id} = $action;

    my $client = $self->_client;
    if ($client) {
        my $result = $client->execute('calling.receive_fax', \%params);
        if (ref $result eq 'HASH' && $result->{code} && $result->{code} =~ /^(404|410)$/) {
            $action->_resolve(undef);
        }
    }

    return $action;
}

sub tap {
    my ($self, %opts) = @_;
    return $self->_start_action('calling.tap', 'SignalWire::Relay::Action::Tap', %opts);
}

sub stream {
    my ($self, %opts) = @_;
    return $self->_start_action('calling.stream', 'SignalWire::Relay::Action::Stream', %opts);
}

sub pay {
    my ($self, %opts) = @_;
    return $self->_start_action('calling.pay', 'SignalWire::Relay::Action::Pay', %opts);
}

sub transcribe {
    my ($self, %opts) = @_;
    return $self->_start_action('calling.transcribe', 'SignalWire::Relay::Action::Transcribe', %opts);
}

sub ai {
    my ($self, %opts) = @_;
    return $self->_start_action('calling.ai', 'SignalWire::Relay::Action::AI', %opts);
}

1;
