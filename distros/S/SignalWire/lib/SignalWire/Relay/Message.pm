package SignalWire::Relay::Message;
use strict;
use warnings;
use Moo;

use SignalWire::Relay::Constants qw(MESSAGE_TERMINAL_STATES);

has 'message_id'  => ( is => 'ro', required => 1 );
has 'context'     => ( is => 'rw', default => sub { '' } );
has 'direction'   => ( is => 'rw', default => sub { '' } );
has 'from_number' => ( is => 'rw', default => sub { '' } );
has 'to_number'   => ( is => 'rw', default => sub { '' } );
has 'body'        => ( is => 'rw', default => sub { '' } );
has 'media'       => ( is => 'rw', default => sub { [] } );
has 'segments'    => ( is => 'rw', default => sub { 0 } );
has 'state'       => ( is => 'rw', default => sub { '' } );
has 'reason'      => ( is => 'rw', default => sub { '' } );
has 'tags'        => ( is => 'rw', default => sub { [] } );

has 'completed' => ( is => 'rw', default => sub { 0 } );
has 'result'    => ( is => 'rw', default => sub { undef } );

has '_on_completed' => ( is => 'rw', default => sub { undef } );
has '_on_event'     => ( is => 'rw', default => sub { [] } );

# Check if message has reached a terminal state
sub is_done {
    my ($self) = @_;
    return $self->completed;
}

# Register on_completed callback
sub on_completed {
    my ($self, $cb) = @_;
    if ($cb) {
        $self->_on_completed($cb);
        if ($self->completed) {
            eval { $cb->($self) };
            warn "Message on_completed callback error: $@" if $@;
        }
        return $self;
    }
    return $self->_on_completed;
}

# Register event listener
sub on {
    my ($self, $cb) = @_;
    push @{$self->_on_event}, $cb;
    return $self;
}

# Blocking wait
sub wait {
    my ($self, %opts) = @_;
    my $timeout = $opts{timeout} || 30;
    my $start = time();
    while (!$self->completed && (time() - $start) < $timeout) {
        select(undef, undef, undef, 0.1);
    }
    return $self->result;
}

# Handle a messaging.state event
sub dispatch_event {
    my ($self, $event) = @_;

    my $message_state = $event->can('message_state') ? $event->message_state : '';
    $self->state($message_state) if $message_state;

    # Update fields from event
    $self->reason($event->reason) if $event->can('reason') && $event->reason;

    # Fire event callbacks
    for my $cb (@{$self->_on_event}) {
        eval { $cb->($self, $event) };
        warn "Message event callback error: $@" if $@;
    }

    # Check for terminal state
    if (MESSAGE_TERMINAL_STATES->{$message_state}) {
        $self->completed(1);
        $self->result($event);
        if (my $cb = $self->_on_completed) {
            eval { $cb->($self) };
            warn "Message on_completed callback error: $@" if $@;
        }
    }
}

1;
