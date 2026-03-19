package SignalWire::Agents::Relay::Action;
use strict;
use warnings;
use Moo;

# Base Action class for long-running RELAY operations.
# Tracks control_id, completion state, and supports blocking wait.

has 'control_id' => ( is => 'ro', required => 1 );
has 'call_id'    => ( is => 'ro', default => sub { '' } );
has 'node_id'    => ( is => 'ro', default => sub { '' } );
has 'state'      => ( is => 'rw', default => sub { 'created' } );
has 'completed'  => ( is => 'rw', default => sub { 0 } );  # boolean
has 'result'     => ( is => 'rw', default => sub { undef } );
has 'events'     => ( is => 'rw', default => sub { [] } );
has 'payload'    => ( is => 'rw', default => sub { {} } ); # latest event payload

has '_on_completed' => ( is => 'rw', default => sub { undef } );
has '_client'       => ( is => 'rw', default => sub { undef } );

# Register on_completed callback
sub on_completed {
    my ($self, $cb) = @_;
    if ($cb) {
        $self->_on_completed($cb);
        # If already done, fire immediately
        if ($self->completed) {
            eval { $cb->($self) };
            warn "on_completed callback error: $@" if $@;
        }
        return $self;
    }
    return $self->_on_completed;
}

# Check if the action is done
sub is_done {
    my ($self) = @_;
    return $self->completed;
}

# Blocking wait using select() polling loop
sub wait {
    my ($self, %opts) = @_;
    my $timeout = $opts{timeout} || 30;
    my $start = time();
    while (!$self->completed && (time() - $start) < $timeout) {
        select(undef, undef, undef, 0.1);  # sleep 100ms
    }
    return $self->result;
}

# Called by event dispatch when an event is received for this action
sub _handle_event {
    my ($self, $event) = @_;
    push @{$self->events}, $event;
    $self->payload($event->params // {});

    my $state = $event->can('state') ? $event->state : '';
    $self->state($state) if $state;
}

# Mark the action as completed with a result
sub _resolve {
    my ($self, $result) = @_;
    return if $self->completed;
    $self->completed(1);
    $self->result($result);

    if (my $cb = $self->_on_completed) {
        eval { $cb->($self) };
        warn "on_completed callback error: $@" if $@;
    }
}

# Send a sub-command on this action (e.g., play.stop, record.pause)
sub _execute_subcommand {
    my ($self, $method) = @_;
    my $client = $self->_client;
    return unless $client;
    return $client->execute($method, {
        node_id    => $self->node_id,
        call_id    => $self->call_id,
        control_id => $self->control_id,
    });
}

# Stop the action
sub stop {
    my ($self) = @_;
    return if $self->completed;
    return $self->_execute_subcommand($self->_stop_method);
}

# Override in subclasses
sub _stop_method { return '' }

# --- PlayAction ---
package SignalWire::Agents::Relay::Action::Play;
use Moo;
extends 'SignalWire::Agents::Relay::Action';

sub _stop_method { 'calling.play.stop' }

sub pause {
    my ($self) = @_;
    return $self->_execute_subcommand('calling.play.pause');
}

sub resume {
    my ($self) = @_;
    return $self->_execute_subcommand('calling.play.resume');
}

sub volume {
    my ($self, $vol) = @_;
    my $client = $self->_client;
    return unless $client;
    return $client->execute('calling.play.volume', {
        node_id    => $self->node_id,
        call_id    => $self->call_id,
        control_id => $self->control_id,
        volume     => $vol,
    });
}

# --- RecordAction ---
package SignalWire::Agents::Relay::Action::Record;
use Moo;
extends 'SignalWire::Agents::Relay::Action';

sub _stop_method { 'calling.record.stop' }

sub pause {
    my ($self, %opts) = @_;
    my $client = $self->_client;
    return unless $client;
    my $params = {
        node_id    => $self->node_id,
        call_id    => $self->call_id,
        control_id => $self->control_id,
    };
    $params->{behavior} = $opts{behavior} if $opts{behavior};
    return $client->execute('calling.record.pause', $params);
}

sub resume {
    my ($self) = @_;
    return $self->_execute_subcommand('calling.record.resume');
}

# Result accessors
sub url      { $_[0]->payload->{url}      // '' }
sub duration { $_[0]->payload->{duration}  // 0 }
sub size     { $_[0]->payload->{size}      // 0 }

# --- DetectAction ---
package SignalWire::Agents::Relay::Action::Detect;
use Moo;
extends 'SignalWire::Agents::Relay::Action';

sub _stop_method { 'calling.detect.stop' }

sub detect_result { $_[0]->payload->{detect} // {} }

# --- CollectAction ---
package SignalWire::Agents::Relay::Action::Collect;
use Moo;
extends 'SignalWire::Agents::Relay::Action';

sub _stop_method { 'calling.collect.stop' }

sub start_input_timers {
    my ($self) = @_;
    return $self->_execute_subcommand('calling.collect.start_input_timers');
}

sub collect_result { $_[0]->payload->{result} // {} }

# Override event handling: for play_and_collect, ignore play events
sub _handle_event {
    my ($self, $event) = @_;
    # If this is a play_and_collect action, only resolve on collect events
    if ($event->event_type eq 'calling.call.play') {
        # Ignore play events for collect actions (play_and_collect gotcha)
        return;
    }
    $self->SUPER::_handle_event($event);
}

# --- FaxAction ---
package SignalWire::Agents::Relay::Action::Fax;
use Moo;
extends 'SignalWire::Agents::Relay::Action';

has '_fax_type' => ( is => 'ro', default => sub { 'send' } );

sub _stop_method {
    my ($self) = @_;
    return $self->_fax_type eq 'receive'
        ? 'calling.receive_fax.stop'
        : 'calling.send_fax.stop';
}

sub fax_result { $_[0]->payload->{fax} // {} }

# --- TapAction ---
package SignalWire::Agents::Relay::Action::Tap;
use Moo;
extends 'SignalWire::Agents::Relay::Action';

sub _stop_method { 'calling.tap.stop' }

# --- StreamAction ---
package SignalWire::Agents::Relay::Action::Stream;
use Moo;
extends 'SignalWire::Agents::Relay::Action';

sub _stop_method { 'calling.stream.stop' }

# --- PayAction ---
package SignalWire::Agents::Relay::Action::Pay;
use Moo;
extends 'SignalWire::Agents::Relay::Action';

sub _stop_method { 'calling.pay.stop' }

sub pay_result { $_[0]->payload->{result} // {} }

# --- TranscribeAction ---
package SignalWire::Agents::Relay::Action::Transcribe;
use Moo;
extends 'SignalWire::Agents::Relay::Action';

sub _stop_method { 'calling.transcribe.stop' }

# --- AIAction ---
package SignalWire::Agents::Relay::Action::AI;
use Moo;
extends 'SignalWire::Agents::Relay::Action';

sub _stop_method { 'calling.ai.stop' }

1;
