package PAGI::Server::TransportState;

use strict;
use warnings;

our $VERSION = '0.002002';

use Scalar::Util qw(weaken);

=head1 NAME

PAGI::Server::TransportState - Outbound flow-control introspection for a connection

=head1 SYNOPSIS

    # Built by the server from an outbound-buffer source (not by the app):
    my $transport = PAGI::Server::TransportState->new(
        measure   => sub { $conn->_get_write_buffer_size },
        high      => sub { $conn->{write_high_watermark} },
        low       => sub { $conn->{write_low_watermark} },
        arm_drain => sub { my $fire = shift; $conn->_wait_for_drain->on_ready($fire) },
    );

    # Read by the application via the scope:
    my $transport = $scope->{'pagi.transport'};

    # Bytes queued for the client but not yet written to the network
    my $pending = $transport->buffered_amount;

    # The backpressure band (sends block at high, resume at low)
    my $ceiling = $transport->high_water_mark;
    my $floor   = $transport->low_water_mark;

=head1 DESCRIPTION

PAGI::Server::TransportState is the object placed in the C<pagi.transport> scope
key. It gives an application a synchronous, read-only view of B<outbound flow
control> -- how much data the server has queued for the client but not yet
written to the network -- so it can conflate, coalesce, shed load, or disconnect
a slow client instead of only blocking until the buffer drains. It is the
server-side analogue of the browser WebSocket API's C<bufferedAmount>.

The handle is source-agnostic: it measures the outbound buffer through coderefs
supplied by the server, never by reaching into a connection itself. That lets
the same hysteresis logic serve different transports -- under HTTP/1.1 the
source reads the shared TCP write buffer, while under HTTP/2 it reads a
per-stream send queue. All reads are live: each call invokes the source and
reports its current state. See the "Transport Flow Control" section in
L<PAGI::Spec::Www> for the full specification.

=head1 METHODS

=head2 new

    my $transport = PAGI::Server::TransportState->new(
        measure   => sub { ... },   # current buffered bytes
        high      => $bytes,        # high-water mark (value or coderef)
        low       => $bytes,        # low-water mark  (value or coderef)
        arm_drain => sub { my $fire = shift; ... },
    );

Creates a transport-state handle. B<This is built by the server, not the
application> -- apps receive the finished handle via the C<pagi.transport> scope
key. The arguments describe the outbound buffer source:

=over 4

=item * C<measure> -- coderef returning the current buffered byte count.
C<undef>/missing is treated as C<0>.

=item * C<high> / C<low> -- the backpressure band. Each may be a plain value or
a coderef returning the current mark; C<undef> means unavailable.

=item * C<arm_drain> -- coderef invoked when the buffer crosses the high mark. It
receives a single C<$fire> callback and must invoke it exactly once when the
buffer next falls below the low mark, so C<on_drain> fires and the cycle re-arms.

=back

=cut

sub new {
    my ($class, %args) = @_;

    my $self = bless {
        _measure   => $args{measure},     # coderef -> current buffered bytes
        _high      => $args{high},        # value or coderef -> high mark (undef ok)
        _low       => $args{low},         # value or coderef -> low mark  (undef ok)
        _arm_drain => $args{arm_drain},   # coderef: (fire) -> call fire once when below low

        # Backpressure callbacks + hysteresis state. _above_high is true once
        # the buffer has crossed the high mark and not yet drained below the low
        # mark, so on_high_water is edge-triggered (fires once per cycle).
        _high_water_callbacks => [],
        _drain_callbacks      => [],
        _above_high           => 0,
    }, $class;

    return $self;
}

=head2 buffered_amount

    my $pending = $transport->buffered_amount;

Returns the number of bytes queued for the client but not yet written to the
network, as an integer; C<0> when the send buffer is fully drained (or once the
underlying connection has gone away). A synchronous, non-blocking,
non-destructive read.

=cut

sub buffered_amount {
    my $self = shift;
    my $measure = $self->{_measure};
    return 0 unless $measure;
    return $measure->() // 0;
}

=head2 high_water_mark

    my $ceiling = $transport->high_water_mark;

Returns the buffered-byte threshold at or above which the server applies
backpressure (a C<$send> that would exceed it blocks until the buffer drains),
or C<undef> if unavailable. Applications use it to threshold relative to the
ceiling rather than hard-coding a byte count.

=cut

sub high_water_mark {
    my $self = shift;
    my $high = $self->{_high};
    return ref $high eq 'CODE' ? $high->() : $high;
}

=head2 low_water_mark

    my $floor = $transport->low_water_mark;

Returns the buffered-byte threshold the buffer must fall back to before the
server releases backpressure (the drain point), or C<undef> if unavailable.

=cut

sub low_water_mark {
    my $self = shift;
    my $low = $self->{_low};
    return ref $low eq 'CODE' ? $low->() : $low;
}

=head2 on_high_water

    $transport->on_high_water(sub { $source->pause });

Registers a callback invoked when the outbound buffer reaches or exceeds
L</high_water_mark> (backpressure engaged). Edge-triggered: it fires once when
the buffer crosses up, and not again until the buffer has drained below the low
mark and crossed up again. If the buffer is already at or above the mark when
the callback is registered, it is invoked immediately. Multiple callbacks may be
registered; they are invoked in registration order with no arguments. Returns
the handle for chaining.

=cut

sub on_high_water {
    my ($self, $cb) = @_;
    push @{$self->{_high_water_callbacks}}, $cb;

    if ($self->{_above_high}) {
        # Already in the high state: this late registrant fires now.
        $self->_fire([$cb]);
    }
    else {
        # May already be above the mark but not yet detected (no send since).
        $self->_check_watermarks;
    }

    return $self;
}

=head2 on_drain

    $transport->on_drain(sub { $source->resume });

Registers a callback invoked when the outbound buffer falls back below
L</low_water_mark> after having reached the high mark (backpressure released).
It is not invoked merely because the buffer is below the low mark when
registered -- only on an actual high-then-low transition. Multiple callbacks may
be registered; they are invoked in registration order with no arguments. Returns
the handle for chaining.

=cut

sub on_drain {
    my ($self, $cb) = @_;
    push @{$self->{_drain_callbacks}}, $cb;
    return $self;
}

=head2 _check_watermarks

    $transport->_check_watermarks;

B<Internal method> - Called by the server after an application send. Detects a
high-water crossing and fires C<on_high_water>, then arms drain detection (via
the source's C<arm_drain> coderef) so C<on_drain> fires once the buffer falls
below the low mark. Edge-triggered and idempotent while above.

=cut

sub _check_watermarks {
    my ($self) = @_;

    return if $self->{_above_high};     # already armed; waiting for drain

    my $high = $self->high_water_mark;
    return unless defined $high;
    return unless $self->buffered_amount >= $high;

    $self->{_above_high} = 1;
    $self->_fire($self->{_high_water_callbacks});

    # Arm drain detection through the source: when the buffer falls below the
    # low mark, fire on_drain and re-arm the cycle.
    my $arm = $self->{_arm_drain} or return;
    weaken(my $weak = $self);
    $arm->(sub {
        return unless $weak;
        $weak->{_above_high} = 0;
        $weak->_fire($weak->{_drain_callbacks});
    });

    return;
}

# Invoke a list of callbacks in order, isolating exceptions.
sub _fire {
    my ($self, $cbs) = @_;
    for my $cb (@$cbs) {
        eval { $cb->(); 1 } or warn "transport callback error: $@";
    }
}

1;

__END__

=head1 SEE ALSO

L<PAGI::Spec::Www> - "Transport Flow Control" specification

L<PAGI::Server::ConnectionState> - HTTP disconnect-state introspection (sibling handle)

L<PAGI::Server::Connection> - Per-connection state machine (internal)

=cut
