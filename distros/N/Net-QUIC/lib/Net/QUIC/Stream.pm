package Net::QUIC::Stream;

use strict;
use warnings;

use Carp qw(croak);
use Net::QUIC ();

our $VERSION = '0.04';

sub _new {
    my ($class, $connection, $id, $local_initiated, $bidirectional) = @_;

    $connection->_stream_retain($id);

    return bless {
        connection      => $connection,
        id              => $id,
        local_initiated => $local_initiated ? 1 : 0,
        bidirectional   => $bidirectional ? 1 : 0,
        retained        => 1,
    }, $class;
}

sub DESTROY {
    my ($self) = @_;

    return if !$self->{retained};

    $self->{retained} = 0;
    my $connection = $self->{connection};
    return if !defined $connection;

    my $need_output = eval {
        $connection->_stream_release($self->{id});
    };

    eval { $connection->_notify_output }
        if $need_output;

    return;
}

sub id {
    my ($self) = @_;
    return $self->{id};
}

sub local_initiated {
    my ($self) = @_;
    return $self->{local_initiated};
}

sub bidirectional {
    my ($self) = @_;
    return $self->{bidirectional};
}

sub can_send {
    my ($self) = @_;
    return $self->{bidirectional} || $self->{local_initiated};
}

sub can_receive {
    my ($self) = @_;
    return $self->{bidirectional} || !$self->{local_initiated};
}

sub send {
    my ($self, $bytes) = @_;

    croak "send requires bytes" if !defined $bytes;
    croak "cannot send on this unidirectional QUIC stream"
        if !$self->can_send;

    $self->{connection}->_stream_send($self->{id}, $bytes);
    $self->{connection}->_notify_output;
    return;
}

sub send_some {
    my ($self, $bytes) = @_;

    croak "send_some requires bytes" if !defined $bytes;
    croak "cannot send on this unidirectional QUIC stream"
        if !$self->can_send;

    my $accepted =
        $self->{connection}->_stream_send_some($self->{id}, $bytes);

    $self->{connection}->_notify_output if $accepted;
    return $accepted;
}

sub send_buffered_bytes {
    my ($self) = @_;
    return $self->{connection}->_stream_send_buffered_bytes($self->{id});
}

sub finish {
    my ($self) = @_;

    croak "cannot finish the send side of this QUIC stream"
        if !$self->can_send;

    $self->{connection}->_stream_finish($self->{id});
    $self->{connection}->_notify_output;
    return;
}

sub next_data {
    my ($self) = @_;

    croak "cannot receive on this unidirectional QUIC stream"
        if !$self->can_receive;

    my $event = $self->{connection}->_stream_take_data($self->{id});
    return if !defined $event;

    $self->{connection}->_notify_output;
    return $event->[0];
}

sub next_data_chunk {
    my ($self) = @_;

    croak "cannot receive on this unidirectional QUIC stream"
        if !$self->can_receive;

    my $event = $self->{connection}->_stream_take_data_chunk($self->{id});
    return if !defined $event;

    return wantarray ? @$event : $event;
}

sub consume {
    my ($self, $amount) = @_;

    croak "cannot receive on this unidirectional QUIC stream"
        if !$self->can_receive;
    croak "consume requires a non-negative integer byte count"
        if !defined($amount) || ref($amount) || $amount !~ /\A\d+\z/;

    $self->{connection}->_stream_consume($self->{id}, $amount);
    $self->{connection}->_notify_output if $amount;
    return;
}

sub acked_offset {
    my ($self) = @_;
    return $self->{connection}->_stream_acked_offset($self->{id});
}

sub remote_finished {
    my ($self) = @_;
    return $self->{connection}->_stream_remote_finished($self->{id});
}

sub closed {
    my ($self) = @_;
    return $self->{connection}->_stream_closed($self->{id});
}

sub early_data {
    my ($self) = @_;
    return $self->{connection}->_stream_early_data($self->{id});
}

sub remote_reset_code {
    my ($self) = @_;
    return $self->{connection}->_stream_remote_reset_code($self->{id});
}

sub local_reset_code {
    my ($self) = @_;
    return $self->{connection}->_stream_local_reset_code($self->{id});
}

sub remote_stop_sending_code {
    my ($self) = @_;
    return $self->{connection}->_stream_remote_stop_sending_code($self->{id});
}

sub local_stop_sending_code {
    my ($self) = @_;
    return $self->{connection}->_stream_local_stop_sending_code($self->{id});
}

sub reset {
    my ($self, $app_error_code) = @_;

    croak "cannot reset the send side of this QUIC stream"
        if !$self->can_send;

    $app_error_code = 0 if !defined $app_error_code;
    croak "application error code must be a non-negative integer"
        if $app_error_code !~ /\A\d+\z/;

    $self->{connection}->_stream_reset($self->{id}, $app_error_code);
    $self->{connection}->_notify_output;
    return;
}

sub stop_sending {
    my ($self, $app_error_code) = @_;

    croak "cannot stop the receive side of this QUIC stream"
        if !$self->can_receive;

    $app_error_code = 0 if !defined $app_error_code;
    croak "application error code must be a non-negative integer"
        if $app_error_code !~ /\A\d+\z/;

    $self->{connection}->_stream_stop_sending($self->{id}, $app_error_code);
    $self->{connection}->_notify_output;
    return;
}

1;

__END__

=head1 NAME

Net::QUIC::Stream - one reliable QUIC byte stream

=head1 DESCRIPTION

A Stream is one ordered sequence of bytes inside a
L<Net::QUIC::Connection>.

It is not a sequence of application messages.

One call to:

    $stream->send($message);

does not guarantee one matching C<next_data> result on the peer.

If the application needs message boundaries, add framing above the Stream.

=head1 BASIC USE

Send bytes:

    $stream->send("hello");
    $stream->finish;

Read available bytes:

    while (defined(my $bytes = $stream->next_data)) {
        handle_bytes($bytes);
    }

Check whether the peer finished cleanly:

    if ($stream->remote_finished) {
        ...
    }

=head1 STREAM DIRECTION

A bidirectional Stream allows both endpoints to send.

A unidirectional Stream allows only the endpoint that created it to send
application bytes.

Use:

    $stream->can_send
    $stream->can_receive

when code needs to handle either kind.

=head1 METHODS

=head2 id

    my $id = $stream->id;

Returns the QUIC stream ID.

Most applications do not need to interpret the numeric value.

=head2 local_initiated

    if ($stream->local_initiated) {
        ...
    }

Returns true when this endpoint opened the Stream.

=head2 bidirectional

Returns true for a bidirectional Stream.

Returns false for a unidirectional Stream.

=head2 can_send

Returns true when this endpoint can send application bytes on the Stream.

=head2 can_receive

Returns true when this endpoint can receive application bytes on the Stream.

=head2 send

    $stream->send($bytes);

Queues bytes for reliable ordered delivery.

The bytes are copied into Net::QUIC-owned memory.

When the Stream belongs to a Connection obtained through
L<Net::QUIC::Driver>, Driver is notified automatically when new transport work
is needed.

If the Connection has an explicit
L<Net::QUIC::Connection/send_buffer_limit>, C<send> stays all-or-nothing and
throws rather than exceeding that limit. Use L</send_some> when partial
acceptance is wanted.

=head2 send_some

    my $accepted = $stream->send_some($bytes);

Advanced bounded transmit interface.

The Connection must first have a
L<Net::QUIC::Connection/send_buffer_limit> configured.

Returns the number of prefix bytes copied into Net::QUIC-owned transmit
memory. This can be zero or less than C<length($bytes)> when the configured
connection-wide buffer is full.

The caller retains ownership only of bytes that were not accepted and may
release or reuse the accepted input after this method returns.

When C<send_some> accepts fewer bytes than requested, pause the producer.
L<Net::QUIC::Connection/on_stream_activity> wakes protocol engines when ACK or
other Stream progress can make more buffer space available.

=head2 send_buffered_bytes

    my $bytes = $stream->send_buffered_bytes;

Returns the number of this Stream's transmit data bytes currently retained by
Net::QUIC.

It includes data that has been sent but is still retained until peer
acknowledgement.

=head2 finish

    $stream->finish;

Finishes this endpoint's send side cleanly after all already queued bytes.

This is the normal way to say:

    I am done sending.

It does not discard queued data.

On a bidirectional Stream, the peer can continue sending data back.

=head2 next_data

    while (defined(my $bytes = $stream->next_data)) {
        ...
    }

Returns the next received byte chunk.

Returns undef when no received data is currently waiting.

Always test with C<defined>.

Reading data also returns receive flow-control credit to QUIC automatically.

Do not mix C<next_data> with L</next_data_chunk> or L</consume> on the same
Stream.

=head2 next_data_chunk

    my ($bytes, $fin) = $stream->next_data_chunk;

This is an advanced receive interface for protocol engines.

It returns the next received byte chunk without returning receive flow-control
credit to QUIC.

In list context it returns:

    ($bytes, $fin)

C<$fin> is true when this chunk carries the peer's clean end-of-stream marker.

In scalar context it returns an array reference containing those same two
values.

Returns undef, or an empty list in list context, when no received data is
currently waiting.

Each chunk is delivered only once. After processing the bytes, report the
number actually consumed with L</consume>.

Do not mix C<next_data_chunk> with L</next_data> on the same Stream.

=head2 consume

    $stream->consume($byte_count);

Returns receive flow-control credit for bytes previously delivered by
L</next_data_chunk>.

The byte count may be smaller than the amount delivered. Additional bytes may
be consumed later.

A count of zero is valid.

It is an error to consume more bytes than have been delivered and not already
consumed.

Calling C<consume> selects the explicit receive mode for the Stream, even when
the byte count is zero. Do not use L</next_data> after selecting explicit
receive mode.

=head2 acked_offset

    my $offset = $stream->acked_offset;

Returns the number of bytes from the start of this Stream that the peer has
acknowledged contiguously.

The value starts at zero and never moves backward.

This is an advanced protocol-engine interface. Ordinary applications normally
do not need acknowledgement offsets.

=head2 remote_finished

Returns true after the peer cleanly finished its send side.

=head2 reset

    $stream->reset;

or:

    $stream->reset($application_error_code);

Abruptly aborts this endpoint's send side.

Queued transmit data that has not completed can be discarded.

On a bidirectional Stream, the receive side remains independent and can still
receive data from the peer.

The application error code defaults to zero.

For an ordinary clean finish, use L</finish> instead.

=head2 stop_sending

    $stream->stop_sending;

or:

    $stream->stop_sending($application_error_code);

Abruptly stops this endpoint's receive side and asks the peer to stop sending.

Unread buffered receive data is discarded.

On a bidirectional Stream, this endpoint's send side remains independent.

The application error code defaults to zero.

=head2 remote_reset_code

    my $code = $stream->remote_reset_code;

Returns the application error code received when the peer reset its send side.

Returns undef when no peer reset has been received.

=head2 local_reset_code

    my $code = $stream->local_reset_code;

Returns the application error code this endpoint passed to L</reset>.

Returns undef when this endpoint has not reset its send side.

=head2 remote_stop_sending_code

    my $code = $stream->remote_stop_sending_code;

Returns the application error code received when the peer asked this endpoint
to stop sending.

Returns undef when no such request has been received.

=head2 local_stop_sending_code

    my $code = $stream->local_stop_sending_code;

Returns the application error code this endpoint passed to
L</stop_sending>.

Returns undef when this endpoint has not stopped its receive side.

=head2 early_data

    if ($stream->early_data) {
        ...
    }

Returns true when this Stream carried 0-RTT early data.

This matters because 0-RTT data can be replayed.

A server can use this flag even after the handshake finishes to keep
replay-sensitive application handling separate.

=head2 closed

Returns true when QUIC has completely closed the Stream.

=head1 OBJECT LIFETIME

A Stream object keeps its Connection alive.

Dropping the Perl Stream object does not discard transmit data that QUIC still
needs to send or finish.

Final status and unread buffered receive data remain available while the public
Stream object still needs them.

=head1 SEE ALSO

L<Net::QUIC>

L<Net::QUIC::Connection>

L<Net::QUIC::Driver>

=cut
