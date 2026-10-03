package Net::QUIC::Connection;

use strict;
use warnings;

use Hash::Util::FieldHash qw(fieldhash);

use Net::QUIC ();
use Net::QUIC::Stream ();

our $VERSION = '0.03';

fieldhash my %OUTPUT_CALLBACK;
fieldhash my %STREAM_AVAILABLE_CALLBACK;
fieldhash my %STREAM_ACTIVITY_CALLBACK;
fieldhash my %STREAM_ACTIVITY_NOTIFIED;

my $EARLY_DATA_MAGIC = "NQED";
my $EARLY_DATA_VERSION = 1;
my $EARLY_DATA_HEADER_LEN = 13;

my $SAVED_STATE_VERSION = 1;
my $SESSION_TICKET_MAGIC = "NQST";
my $ADDRESS_TOKEN_MAGIC = "NQAT";

sub _encode_saved_state {
    my ($class, $magic, $version, $bytes) = @_;

    die "invalid saved QUIC version"
        if !defined($version) || $version !~ /\A[12]\z/;
    die "saved QUIC state cannot be empty"
        if !defined($bytes) || $bytes eq '';

    return pack(
        'a4CC',
        $magic,
        $SAVED_STATE_VERSION,
        $version,
    ) . $bytes;
}

sub _decode_saved_state {
    my ($class, $magic, $name, $state) = @_;

    die "$name cannot be empty"
        if !defined($state) || ref($state) || $state eq '';

    if (length($state) >= 6 && substr($state, 0, 4) eq $magic) {
        my ($got_magic, $format, $version) =
            unpack('a4CC', substr($state, 0, 6));

        die "invalid Net::QUIC $name"
            if $got_magic ne $magic
            || $format != $SAVED_STATE_VERSION
            || ($version != 1 && $version != 2)
            || length($state) == 6;

        return (substr($state, 6), $version);
    }

    # Net::QUIC 0.01 exposed raw values before QUIC v2 support.
    # Those values could only have been created by a v1 connection.
    return ($state, 1);
}

sub _decode_session_ticket {
    my ($class, $state) = @_;
    return $class->_decode_saved_state(
        $SESSION_TICKET_MAGIC,
        'session_ticket',
        $state,
    );
}

sub _decode_address_token {
    my ($class, $state) = @_;
    return $class->_decode_saved_state(
        $ADDRESS_TOKEN_MAGIC,
        'address_token',
        $state,
    );
}

sub session_ticket {
    my ($self) = @_;
    my $state = $self->_session_ticket_state;
    return if !defined $state;

    return __PACKAGE__->_encode_saved_state(
        $SESSION_TICKET_MAGIC,
        $state->[0],
        $state->[1],
    );
}

sub address_token {
    my ($self) = @_;
    my $state = $self->_address_token_state;
    return if !defined $state;

    return __PACKAGE__->_encode_saved_state(
        $ADDRESS_TOKEN_MAGIC,
        $state->[0],
        $state->[1],
    );
}

sub _encode_early_data_state {
    my ($class, $ticket, $transport) = @_;

    die "missing TLS session ticket for early-data state"
        if !defined($ticket) || $ticket eq '';
    die "missing QUIC transport parameters for early-data state"
        if !defined($transport) || $transport eq '';

    return pack(
        'a4CNN',
        $EARLY_DATA_MAGIC,
        $EARLY_DATA_VERSION,
        length($ticket),
        length($transport),
    ) . $ticket . $transport;
}

sub _decode_early_data_state {
    my ($class, $state) = @_;

    die "early_data must be an opaque state returned by early_data_state"
        if !defined($state)
        || ref($state)
        || length($state) < $EARLY_DATA_HEADER_LEN;

    my ($magic, $version, $ticket_len, $transport_len) =
        unpack('a4CNN', substr($state, 0, $EARLY_DATA_HEADER_LEN));

    die "invalid Net::QUIC early-data state"
        if $magic ne $EARLY_DATA_MAGIC
        || $version != $EARLY_DATA_VERSION
        || $ticket_len == 0
        || $transport_len == 0
        || $ticket_len > length($state) - $EARLY_DATA_HEADER_LEN
        || $transport_len
            != length($state) - $EARLY_DATA_HEADER_LEN - $ticket_len;

    my $ticket = substr($state, $EARLY_DATA_HEADER_LEN, $ticket_len);
    my $transport = substr(
        $state,
        $EARLY_DATA_HEADER_LEN + $ticket_len,
        $transport_len,
    );

    return ($ticket, $transport);
}

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

sub on_stream_activity {
    my ($self, $callback) = @_;

    delete $STREAM_ACTIVITY_NOTIFIED{$self};

    if (defined $callback) {
        die "stream activity callback must be a coderef"
            if ref($callback) ne 'CODE';
        $STREAM_ACTIVITY_CALLBACK{$self} = $callback;
        $self->_set_stream_activity_enabled(1);
    } else {
        delete $STREAM_ACTIVITY_CALLBACK{$self};
        $self->_set_stream_activity_enabled(0);
    }

    $self->_dispatch_stream_activity;
    return $self;
}

sub _dispatch_stream_activity {
    my ($self) = @_;

    my $callback = $STREAM_ACTIVITY_CALLBACK{$self};
    return if !$callback;
    return if $STREAM_ACTIVITY_NOTIFIED{$self};
    return if !$self->_stream_activity_pending;

    $STREAM_ACTIVITY_NOTIFIED{$self} = 1;
    $callback->($self);
    return;
}

sub next_active_stream_id {
    my ($self) = @_;

    my $id = $self->_next_active_stream_id;

    delete $STREAM_ACTIVITY_NOTIFIED{$self}
        if !defined($id) || !$self->_stream_activity_pending;

    return $id;
}

sub send_buffer_limit {
    my ($self, @args) = @_;

    return $self->_send_buffer_limit if !@args;

    my $limit = $args[0];

    if (!defined $limit) {
        $self->_clear_send_buffer_limit;
        return $self;
    }

    die "send buffer limit must be a non-negative integer"
        if ref($limit) || $limit !~ /\A\d+\z/;

    $self->_set_send_buffer_limit($limit);
    return $self;
}

sub send_buffered_bytes {
    my ($self) = @_;
    return $self->_send_buffered_bytes;
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

sub migrate {
    my ($self, $local) = @_;

    die "missing migration local address"
        if !defined $local;

    $self->_migrate($local);
    $self->_notify_output;
    return;
}

sub path {
    my ($self) = @_;

    my $path = $self->_path;
    return if !defined $path;

    return {
        local => $path->[0],
        peer  => $path->[1],
    };
}

sub path_validation {
    my ($self) = @_;

    my $state = $self->_path_validation;
    return { status => 'none' } if !defined $state;

    my @status = qw(none validating succeeded failed aborted);
    my $status = $status[$state->[0]];

    die "invalid native path validation status"
        if !defined $status;

    return {
        status            => $status,
        local             => $state->[2],
        peer              => $state->[3],
        preferred_address => ($state->[1] & 0x01) ? 1 : 0,
        new_token         => ($state->[1] & 0x02) ? 1 : 0,
    };
}

sub path_validation_status {
    my ($self) = @_;
    return $self->path_validation->{status};
}

sub early_data_state {
    my ($self) = @_;

    my $ticket = $self->session_ticket;
    return if !defined $ticket;

    my $transport = $self->_early_data_transport_params;
    return if !defined $transport;

    return __PACKAGE__->_encode_early_data_state($ticket, $transport);
}

sub early_data_status {
    my ($self) = @_;
    my @status = qw(none pending accepted rejected);
    my $value = $self->_early_data_status;

    die "invalid native early-data status"
        if !defined($status[$value]);

    return $status[$value];
}

sub closed {
    my ($self) = @_;
    return $self->_retired;
}

1;

__END__

=head1 NAME

Net::QUIC::Connection - one QUIC connection

=head1 DESCRIPTION

A Connection is one secure QUIC relationship with a peer.

It can contain many independent L<Net::QUIC::Stream> objects.

Application protocol code normally works with Connection and Stream. UDP
socket and timer handling normally stays in L<Net::QUIC::Driver>.

A client Driver has one Connection.

A server Driver can create many Connections.

=head1 BASIC USE

Get the client Connection:

    my $connection = $driver->connection;

Wait for the handshake:

    return if !$connection->ready;

Open a bidirectional Stream:

    my $stream = $connection->open_bidi_stream;

    if ($stream) {
        $stream->send("hello");
        $stream->finish;
    }

Accept Streams opened by the peer:

    while (my $stream = $connection->next_stream) {
        ...
    }

Close normally:

    $connection->close;

=head1 HANDSHAKE AND SAVED STATE

=head2 ready

    if ($connection->ready) {
        ...
    }

Returns true after the QUIC/TLS handshake is ready for normal application
work.

A server can expose a Connection before this becomes true.

=head2 client_chosen_version

    my $version = $connection->client_chosen_version;

Returns 1 or 2 for the QUIC version used by the client's first Initial packet.

This can differ from L</version> when Compatible Version Negotiation switches
the connection to another supported version during the handshake.

=head2 version

    my $version = $connection->version;

Returns the final negotiated QUIC version, 1 or 2.

It can be undef before version negotiation is complete.

Most applications do not need to branch on this value.

=head2 session_ticket

    my $ticket = $connection->session_ticket;

Returns the newest opaque TLS session ticket received by the client, or undef
if none is available.

A later client can pass it as:

    session_ticket => $ticket

to attempt a faster resumed TLS handshake.

Treat the ticket as opaque bytes.

If it is expired or otherwise unusable, the connection falls back to a normal
full handshake.

=head2 resumed

    if ($connection->resumed) {
        ...
    }

Returns true when the completed TLS handshake actually resumed a previous
session.

=head2 address_token

    my $token = $connection->address_token;

Returns the newest opaque QUIC address-validation token received by the client,
or undef if none is available.

A later client can pass it as:

    address_token => $token

A valid token can let a server with address validation enabled accept the new
connection without another Retry round trip.

Treat the token as opaque bytes.

=head2 early_data_state

    my $state = $connection->early_data_state;

Returns one opaque value that a client can save for a later 0-RTT attempt.

A later client supplies it as:

    early_data => $state

0-RTT allows some application data to be sent before the new handshake
completes.

0-RTT data can be replayed. Only use it for operations that are safe to repeat.

=head2 early_data_status

    my $status = $connection->early_data_status;

Returns one of:

    none
    pending
    accepted
    rejected

C<pending> means this client is attempting 0-RTT and does not yet know whether
the server accepted it.

If 0-RTT is rejected, the normal TLS handshake can still complete.

Streams created for the rejected early-data attempt become invalid. Open new
Streams after C<ready> and resend only operations that are safe to repeat.

=head1 OPENING STREAMS

=head2 open_bidi_stream

    my $stream = $connection->open_bidi_stream;

Opens a bidirectional Stream.

Both endpoints can send on a bidirectional Stream.

Returns undef when the peer's current bidirectional stream limit has been
reached.

That is normal QUIC flow control, not a Connection failure.

=head2 open_uni_stream

    my $stream = $connection->open_uni_stream;

Opens a unidirectional Stream.

Only this endpoint can send application bytes on a locally opened
unidirectional Stream.

Returns undef when the peer's current unidirectional stream limit has been
reached.

=head2 on_stream_available

    $connection->on_stream_available(sub {
        my ($connection, $type) = @_;
        ...
    });

Registers a callback for new local stream credit.

C<$type> is:

    bidi

or:

    uni

Use this when C<open_bidi_stream> or C<open_uni_stream> returned undef and the
application wants to try again when the peer allows another Stream.

=head1 PEER-CREATED STREAMS

=head2 next_stream

    while (my $stream = $connection->next_stream) {
        ...
    }

Returns the next Stream opened by the peer.

Returns undef when no new peer-created Stream is waiting.

A Stream can be bidirectional or unidirectional. Use:

    $stream->can_send
    $stream->can_receive

when code needs to handle either kind.

=head2 on_stream_activity

    $connection->on_stream_activity(sub {
        my ($connection) = @_;
        ...
    });

Registers an advanced protocol-engine wake-up callback.

The callback runs when one or more Streams have meaningful new activity, such
as received data, FIN, acknowledgement progress, RESET_STREAM, STOP_SENDING,
stream close, or a newly peer-created Stream.

The callback does not receive one event object per transport event. Activity is
coalesced by Stream.

Drain the changed Stream IDs with L</next_active_stream_id>.

Pass undef to disable activity tracking:

    $connection->on_stream_activity(undef);

Activity tracking is opt-in so ordinary applications pay no queueing cost.

=head2 next_active_stream_id

    while (defined(my $id = $connection->next_active_stream_id)) {
        ...
    }

Returns the next Stream ID with coalesced activity.

Returns undef when the activity queue is empty.

A protocol engine should normally drain this queue when L</on_stream_activity>
wakes it. State such as received data, acknowledgement offsets, reset codes,
and STOP_SENDING codes remains available on the corresponding Stream object.

=head1 BOUNDED TRANSMIT BUFFERING

These methods are for advanced producers that need a hard bound on Stream data
retained by Net::QUIC.

=head2 send_buffer_limit

    $connection->send_buffer_limit(4 * 1024 * 1024);

Enables a connection-wide limit on retained Stream transmit bytes.

The limit counts Stream data that is queued for sending plus data already sent
but still retained until peer acknowledgement.

Use:

    my $limit = $connection->send_buffer_limit;

to read the current limit.

It returns undef when bounded transmit mode is disabled.

Disable the limit with:

    $connection->send_buffer_limit(undef);

A new limit cannot be smaller than the amount of Stream data already retained.

When a limit is enabled, ordinary L<Net::QUIC::Stream/send> remains
all-or-nothing. It throws instead of exceeding the configured bound.
Advanced producers should use L<Net::QUIC::Stream/send_some>.

=head2 send_buffered_bytes

    my $bytes = $connection->send_buffered_bytes;

Returns the total number of Stream data bytes currently retained for transmit
across this Connection.

This includes sent data that still has to remain available until it is
acknowledged.

=head1 NETWORK PATH

A QUIC Connection can survive some network-address changes without being
recreated.

Most applications do not need to inspect path state during ordinary use.

=head2 path

    my $path = $connection->path;

Returns the active network path:

    {
        local => $packed_local_address,
        peer  => $packed_peer_address,
    }

=head2 migrate

    $connection->migrate($new_packed_local_address);

Client only.

Starts migration to another local address while keeping the same QUIC
Connection.

Net::QUIC validates the new path before switching to it.

If validation fails, the previous working path stays active.

=head2 path_validation_status

    my $status = $connection->path_validation_status;

Returns:

    none
    validating
    succeeded
    failed
    aborted

This is the simple path-validation view.

=head2 path_validation

    my $info = $connection->path_validation;

Returns the detailed current or most recent path-validation state.

The hash includes at least:

    status

and, when a validation has occurred:

    local
    peer

It also reports whether the validation was associated with a server preferred
address or a fresh address-validation token.

=head2 path_max_udp_payload_size

    my $bytes = $connection->path_max_udp_payload_size;

Returns the currently discovered maximum UDP payload size for the active path.

A new path starts at QUIC's safe 1200-byte baseline. The native QUIC engine can
raise this value when larger packets work.

This is mainly diagnostic. Applications normally do not need to manage PMTU
discovery themselves.

=head1 CLOSING

=head2 close

    $connection->close;

or:

    $connection->close($application_error_code);

Starts a normal application-level QUIC close.

The default application error code is zero.

Closing is not immediate destruction. QUIC has a short closing/draining period
so late packets can still be handled correctly.

=head2 closed

    if ($connection->closed) {
        ...
    }

Returns true when the Connection no longer needs network or timer service.

=head1 CLOSE AND ERROR INFORMATION

=head2 close_info

    my $info = $connection->close_info;

Returns undef while no close or failure has been recorded.

Otherwise it returns a hash describing the outcome.

For example, a normal peer application close can look like:

    {
        type      => 'application',
        initiator => 'peer',
        code      => 0,
    }

C<type> can be:

    application
    transport
    tls
    certificate
    handshake
    idle
    drop

C<initiator> is:

    local
    peer

C<code> is the application error code, QUIC transport error code, or TLS alert
code as appropriate.

A peer transport error can also include C<frame_type>.

A locally detected native transport failure can include C<native_error>.

Remote protocol errors, certificate failures, handshake failures, idle timeout,
and normal closes are Connection outcomes rather than ordinary Perl
exceptions.

Local programming mistakes, invalid configuration, allocation failure, and
internal implementation failures still throw Perl exceptions.

=head1 DRIVER NOTIFICATION

Connections obtained through L<Net::QUIC::Driver> automatically notify Driver
when application operations create new transport work.

For example:

    $stream->send(...);
    $stream->finish;
    $stream->reset(...);
    $connection->close;

do not require a separate service or pump call.

=head1 SEE ALSO

L<Net::QUIC>

L<Net::QUIC::Driver>

L<Net::QUIC::Stream>

L<Net::QUIC::Endpoint>

=cut
