package Net::QUIC::Connection;

use strict;
use warnings;

use Hash::Util::FieldHash qw(fieldhash);

use Net::QUIC ();
use Net::QUIC::Stream ();

our $VERSION = '0.01';

fieldhash my %OUTPUT_CALLBACK;
fieldhash my %STREAM_AVAILABLE_CALLBACK;

sub _set_output_callback {
    my ($self, $callback) = @_;

    if (defined $callback) {
        die "output callback must be a coderef"
            if ref($callback) ne 'CODE';
        $OUTPUT_CALLBACK{$self} = $callback;
    } else {
        delete $OUTPUT_CALLBACK{$self};
    }

    return;
}

sub _notify_output {
    my ($self) = @_;
    my $callback = $OUTPUT_CALLBACK{$self};
    $callback->() if $callback;
    return;
}

sub on_stream_available {
    my ($self, $callback) = @_;

    if (defined $callback) {
        die "stream availability callback must be a coderef"
            if ref($callback) ne 'CODE';
        $STREAM_AVAILABLE_CALLBACK{$self} = $callback;
    } else {
        delete $STREAM_AVAILABLE_CALLBACK{$self};
    }

    $self->_dispatch_stream_availability;
    return $self;
}

sub _dispatch_stream_availability {
    my ($self) = @_;

    my $callback = $STREAM_AVAILABLE_CALLBACK{$self};
    return if !$callback;

    my $events = $self->_take_stream_available;
    $callback->($self, 'bidi') if $events & 0x01;
    $callback->($self, 'uni')  if $events & 0x02;
    return;
}

sub open_bidi_stream {
    my ($self) = @_;
    my $id = $self->_open_stream(1);
    return if !defined $id;
    return Net::QUIC::Stream->_new($self, $id, 1, 1);
}

sub open_uni_stream {
    my ($self) = @_;
    my $id = $self->_open_stream(0);
    return if !defined $id;
    return Net::QUIC::Stream->_new($self, $id, 1, 0);
}

sub next_stream {
    my ($self) = @_;
    my $id = $self->_next_stream_id;

    return if !defined $id;

    my $info = $self->_stream_info($id);
    return Net::QUIC::Stream->_new($self, $id, $info->[0], $info->[1]);
}

sub close {
    my ($self, $application_error_code) = @_;

    $application_error_code = 0
        if !defined $application_error_code;

    die "application error code must be a non-negative integer"
        if $application_error_code !~ /\A\d+\z/;

    $self->_close($application_error_code);
    $self->_notify_output;
    return;
}

sub close_info {
    my ($self) = @_;
    return $self->_close_info;
}

sub closed {
    my ($self) = @_;
    return $self->_retired;
}

1;

__END__

=head1 NAME

Net::QUIC::Connection - one QUIC connection

=head1 SYNOPSIS

A client Connection normally comes from L<Net::QUIC::Driver>:

    my $connection = $driver->connection;

Wait for the QUIC/TLS handshake:

    return if !$connection->ready;

Open a bidirectional stream:

    my $stream = $connection->open_bidi_stream;

    if ($stream) {
        $stream->send("hello");
        $stream->finish;
    }

Accept streams opened by the peer:

    while (my $stream = $connection->next_stream) {
        ...
    }

Close the Connection normally:

    $connection->close;

=head1 DESCRIPTION

Net::QUIC::Connection represents one QUIC connection.

Application protocol code normally works with Connection and
L<Net::QUIC::Stream>. UDP socket and timer integration normally stays in
L<Net::QUIC::Driver>.

A client Driver owns one Connection. A server Driver can expose many
Connections through C<next_connection>.

Connection objects are created by Driver or L<Net::QUIC::Endpoint>. Direct
native construction is private.

=head1 HANDSHAKE READINESS

=head2 ready

    if ($connection->ready) {
        ...
    }

Returns true after the QUIC cryptographic handshake has completed.

A server Connection may be returned before this becomes true.

Application work that requires an established connection should wait for
C<ready>.

=head1 OPENING STREAMS

=head2 open_bidi_stream

    my $stream = $connection->open_bidi_stream;

Opens a local bidirectional stream and returns a L<Net::QUIC::Stream>.

Both endpoints can send application bytes on a bidirectional stream.

Returns undef when the peer's current bidirectional stream limit has been
reached.

That is normal QUIC flow control. It does not mean the Connection failed.

Other failures still throw an exception.

=head2 open_uni_stream

    my $stream = $connection->open_uni_stream;

Opens a local unidirectional stream.

This endpoint can send application bytes on the stream but cannot receive
application bytes from it.

Returns undef when the peer's current unidirectional stream limit has been
reached.

Other failures still throw an exception.

=head2 on_stream_available

    $connection->on_stream_available(sub {
        my ($connection, $type) = @_;

        return if $type ne 'bidi';

        my $stream = $connection->open_bidi_stream;
        return if !defined $stream;

        ...
    });

Registers a callback for stream-limit recovery.

Use it when C<open_bidi_stream> or C<open_uni_stream> returned undef and the
application wants to continue when the peer later grants more stream credit.

C<$type> is:

    bidi

or:

    uni

The callback runs outside ngtcp2's internal callback stack, so opening a stream
from it is safe.

Pass undef to remove the callback:

    $connection->on_stream_available(undef);

=head1 PEER-CREATED STREAMS

=head2 next_stream

    while (my $stream = $connection->next_stream) {
        ...
    }

Returns the next stream opened by the peer, or undef when no new incoming
stream is waiting.

The returned object is a L<Net::QUIC::Stream>.

=head1 CLOSING

=head2 close

    $connection->close;

or:

    $connection->close($application_error_code);

Starts a normal QUIC application-level Connection close.

The application error code defaults to zero.

Calling C<close> again while the Connection is already closing is harmless.

C<close> does not immediately destroy the object. QUIC has a closing/draining
period during which late packets still need network and timer service.

When the Connection belongs to a Driver, Driver automatically services the
close packet and timeout changes.

=head2 closed

    if ($connection->closed) {
        ...
    }

Returns true after the Connection has completely finished its QUIC closing or
draining period and no longer needs network or timer service.

C<close_info> can become available before C<closed> becomes true.

=head1 CLOSE AND ERROR INFORMATION

=head2 close_info

    my $info = $connection->close_info;

Returns undef while no Connection close or failure has been recorded.

Once a close or failure is known, returns a small hash reference.

The common fields are:

    type
    initiator
    code

C<type> is one of:

    application
    transport
    tls
    certificate
    handshake
    idle
    drop

C<initiator> is:

    local

or:

    peer

C<code> is the application error code, QUIC transport error code, or TLS alert
code as appropriate.

For example, a normal peer application close can be:

    {
        type      => 'application',
        initiator => 'peer',
        code      => 0,
    }

C<frame_type> is included when a peer transport close identifies the QUIC frame
that caused the error.

C<native_error> is included for failures detected locally by ngtcp2.

TLS certificate verification failures use:

    type => 'certificate'

Other TLS failures use:

    type => 'tls'

Handshake timeout uses:

    type => 'handshake'

Local API misuse, invalid configuration, allocation failure, and internal
implementation failures still throw Perl exceptions. Those are local
programming or system failures rather than ordinary remote Connection
outcomes.

=head1 DRIVER NOTIFICATION

Connections obtained through L<Net::QUIC::Driver> are privately connected back
to that Driver.

State-changing application calls such as stream send/finish/reset, data
consumption, and Connection close can therefore cause QUIC output and timer
changes to be serviced automatically.

Application code does not need to call a separate pump or service method.

=head1 SEE ALSO

L<Net::QUIC>

L<Net::QUIC::Driver>

L<Net::QUIC::Stream>

L<Net::QUIC::Endpoint>

=cut
