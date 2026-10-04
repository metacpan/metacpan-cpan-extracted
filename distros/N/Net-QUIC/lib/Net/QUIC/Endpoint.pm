package Net::QUIC::Endpoint;

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(looks_like_number refaddr);
use Net::QUIC ();
use Net::QUIC::Connection ();
use Net::QUIC::Datagram ();

our $VERSION = '0.04';

sub _transport_config {
    my ($class, $value) = @_;

    $value = {} if !defined $value;

    croak "transport must be a hash reference"
        if ref($value) ne 'HASH';

    my %config = (
        handshake_timeout => 10,
        idle_timeout      => 30,
        connection_window => 1024 * 1024,
        stream_window     => 256 * 1024,
        max_bidi_streams        => 100,
        max_uni_streams         => 100,
        max_datagram_frame_size => 0,
    );

    my %known = map { $_ => 1 } keys %config;

    for my $name (keys %$value) {
        croak "unknown transport option: $name"
            if !$known{$name};
        $config{$name} = $value->{$name};
    }

    for my $name (qw(handshake_timeout idle_timeout)) {
        my $seconds = $config{$name};

        croak "$name must be a non-negative number of seconds"
            if !defined($seconds)
            || !looks_like_number($seconds)
            || $seconds < 0
            || "$seconds" =~ /nan|inf/i;

        croak "handshake_timeout must be greater than zero"
            if $name eq 'handshake_timeout' && $seconds == 0;

        $config{$name} = int($seconds * 1000 + 0.5);
    }

    for my $name (qw(
        connection_window
        stream_window
        max_bidi_streams
        max_uni_streams
        max_datagram_frame_size
    )) {
        my $number = $config{$name};

        croak "$name must be a non-negative integer"
            if !defined($number)
            || $number !~ /\A\d+\z/;

        croak "max_datagram_frame_size cannot exceed 65535"
            if $name eq 'max_datagram_frame_size' && $number > 65535;

        $config{$name} = 0 + $number;
    }

    return [
        $config{handshake_timeout},
        $config{idle_timeout},
        $config{connection_window},
        $config{stream_window},
        $config{max_bidi_streams},
        $config{max_uni_streams},
        $config{max_datagram_frame_size},
    ];
}

sub _require_concrete_local {
    my ($class, $local) = @_;

    croak "local must be a concrete IPv4 or IPv6 address; "
        . "0.0.0.0 and :: are wildcard bind addresses, not QUIC paths"
        if Net::QUIC::_local_address_is_unspecified($local);

    return;
}


sub _quic_version {
    my ($class, $value, $name, $default) = @_;

    $value = $default if !defined $value;

    croak "$name must be 1 or 2"
        if !defined($value) || $value !~ /\A[12]\z/;

    return 0 + $value;
}

sub client {
    my ($class, %args) = @_;

    for my $name (qw(local peer alpn server_name)) {
        croak "missing required $name argument"
            if !defined $args{$name};
    }

    croak "server_name cannot be empty"
        if $args{server_name} eq '';

    $class->_require_concrete_local($args{local});

    my $ca_file = defined $args{ca_file}
        ? $args{ca_file}
        : '';

    my $transport = $class->_transport_config(delete $args{transport});
    my $version_arg = delete $args{version};
    my $session_ticket = delete $args{session_ticket};
    my $early_data = delete $args{early_data};
    my $address_token = delete $args{address_token};
    my $early_transport;
    my $saved_version;

    if (defined $early_data) {
        croak "session_ticket and early_data cannot be used together"
            if defined $session_ticket;

        ($session_ticket, $early_transport) =
            Net::QUIC::Connection->_decode_early_data_state($early_data);
    }

    if (defined $session_ticket) {
        my $ticket_version;
        ($session_ticket, $ticket_version) =
            Net::QUIC::Connection->_decode_session_ticket($session_ticket);
        $saved_version = $ticket_version;
    }

    if (defined $address_token) {
        my $token_version;
        ($address_token, $token_version) =
            Net::QUIC::Connection->_decode_address_token($address_token);

        croak "saved session and address token QUIC versions do not match"
            if defined($saved_version)
            && $saved_version != $token_version;

        $saved_version = $token_version;
    }

    my $version = $class->_quic_version(
        $version_arg,
        'version',
        defined($saved_version) ? $saved_version : 1,
    );

    croak "saved QUIC state belongs to version $saved_version, not version $version"
        if defined($saved_version) && $version != $saved_version;

    my $version_locked = defined($saved_version) ? 1 : 0;

    my $connection = Net::QUIC::Connection->_client_new(
        $args{local},
        $args{peer},
        $args{alpn},
        $args{server_name},
        $ca_file,
        $transport,
        $session_ticket,
        $early_transport,
        $address_token,
        $version,
        $version_locked,
    );

    return bless {
        mode       => 'client',
        connection => $connection,
    }, $class;
}

sub server {
    my ($class, %args) = @_;

    for my $name (qw(alpn certificate_file private_key_file)) {
        croak "missing required $name argument"
            if !defined $args{$name};
    }

    my $server_tls = Net::QUIC::_ServerTLS->_new(
        $args{certificate_file},
        $args{private_key_file},
        $args{accept_early_data} ? 1 : 0,
    );

    my $transport = $class->_transport_config(delete $args{transport});
    my $preferred_address = delete $args{preferred_address};
    my $preferred_version = delete $args{preferred_version};

    $preferred_version = $class->_quic_version(
        $preferred_version,
        'preferred_version',
        undef,
    ) if defined $preferred_version;

    $class->_require_concrete_local($preferred_address)
        if defined $preferred_address;

    return bless {
        mode                => 'server',
        alpn                => $args{alpn},
        server_tls          => $server_tls,
        cid_length          => $class->_server_cid_length,
        server_secret       => $class->_server_secret,
        validate_address    => $args{validate_address} ? 1 : 0,
        preferred_address   => $preferred_address,
        preferred_version   => $preferred_version,
        transport           => $transport,
        stateless_tx        => [],
        routes              => {},
        connections         => [],
        pending_connections => [],
        tx_cursor           => 0,
    }, $class;
}

sub _sync_server_routes {
    my ($self, $connection) = @_;

    while (my $event = $connection->_take_cid_event) {
        my ($add, $cid) = @$event;

        if ($add) {
            $self->{routes}{$cid} = $connection;
        } else {
            delete $self->{routes}{$cid};
        }
    }

    return;
}

sub _retire_server_connections {
    my ($self) = @_;
    my %retired;

    for my $connection (@{$self->{connections}}) {
        next if !$connection->_retired;
        $retired{refaddr($connection)} = 1;
    }

    return if !%retired;

    @{$self->{connections}} = grep {
        !$retired{refaddr($_)}
    } @{$self->{connections}};

    @{$self->{pending_connections}} = grep {
        !$retired{refaddr($_)}
    } @{$self->{pending_connections}};

    for my $cid (keys %{$self->{routes}}) {
        my $connection = $self->{routes}{$cid};
        delete $self->{routes}{$cid}
            if $retired{refaddr($connection)};
    }

    my $count = @{$self->{connections}};
    $self->{tx_cursor} = $count
        ? $self->{tx_cursor} % $count
        : 0;

    return;
}

sub _managed_connection_count {
    my ($self) = @_;
    return scalar @{$self->{connections}};
}

sub _route_count {
    my ($self) = @_;
    return scalar keys %{$self->{routes}};
}

sub _server_receive_datagram {
    my ($self, $bytes, $local, $peer, $ecn) = @_;
    $ecn = 0 if !defined $ecn;

    my $dcid = $self->_packet_dcid($bytes, $self->{cid_length});
    return if !defined $dcid;

    my $connection = $self->{routes}{$dcid};

    if (!$connection) {
        my $front = $self->_server_front_door(
            $bytes,
            $peer,
            $self->{server_secret},
            $self->{validate_address},
        );

        return if $front->[0] == 0;

        if ($front->[0] == 1) {
            push @{$self->{stateless_tx}},
                Net::QUIC::Datagram->_new($front->[1], $local, $peer);
            return;
        }

        my $initial_dcid = $self->_initial_dcid($bytes);
        return if !defined $initial_dcid;

        $connection = Net::QUIC::Connection->_server_new(
            $bytes,
            $local,
            $peer,
            $self->{alpn},
            $self->{server_tls},
            $front->[1],
            $self->{server_secret},
            $self->{transport},
            $self->{preferred_address},
            $front->[2] // 0,
            $self->{validate_address},
            $self->{preferred_version} // 0,
        );

        $connection->_receive_datagram($bytes, $local, $peer, $ecn);
        $connection->_dispatch_stream_activity;
        $connection->_dispatch_stream_availability;
        $connection->_dispatch_datagrams;

        $self->{routes}{$initial_dcid} = $connection;
        push @{$self->{connections}}, $connection;
        push @{$self->{pending_connections}}, $connection;
        $self->_sync_server_routes($connection);
        $self->_retire_server_connections;
        return;
    }

    $connection->_receive_datagram($bytes, $local, $peer, $ecn);
    $connection->_dispatch_stream_activity;
    $connection->_dispatch_stream_availability;
    $connection->_dispatch_datagrams;
    $self->_sync_server_routes($connection);
    $self->_retire_server_connections;
    return;
}

sub _server_next_datagram {
    my ($self) = @_;

    $self->_retire_server_connections;

    if (@{$self->{stateless_tx}}) {
        return shift @{$self->{stateless_tx}};
    }

    my $connections = $self->{connections};
    my $count = @$connections;

    return if !$count;

    for (1 .. $count) {
        my $index = $self->{tx_cursor} % $count;
        $self->{tx_cursor} = ($index + 1) % $count;

        my $connection = $connections->[$index];
        my $datagram = $connection->_next_datagram;
        $self->_sync_server_routes($connection);

        return $datagram if defined $datagram;
    }

    return;
}

sub _server_timeout_after {
    my ($self) = @_;
    my $minimum;

    $self->_retire_server_connections;

    for my $connection (@{$self->{connections}}) {
        my $after = $connection->_timeout_after;
        next if !defined $after;

        $minimum = $after
            if !defined($minimum) || $after < $minimum;
    }

    return $minimum;
}

sub _server_handle_timeout {
    my ($self) = @_;

    for my $connection (@{$self->{connections}}) {
        my $after = $connection->_timeout_after;
        next if !defined($after) || $after > 0;

        $connection->_handle_timeout;
        $self->_sync_server_routes($connection);
    }

    $self->_retire_server_connections;
    return;
}

sub connection {
    my ($self) = @_;

    croak "server endpoint manages multiple connections; use next_connection"
        if $self->{mode} eq 'server';

    return $self->{connection};
}

sub next_connection {
    my ($self) = @_;

    croak "next_connection is only available on a server endpoint"
        if $self->{mode} ne 'server';

    return shift @{$self->{pending_connections}};
}

sub receive_datagram {
    my ($self, $bytes, $local, $peer, $ecn) = @_;

    __PACKAGE__->_require_concrete_local($local);

    $ecn = 0 if !defined $ecn;
    croak "ECN codepoint must be an integer from 0 through 3"
        if ref($ecn) || $ecn !~ /\A[0-3]\z/;

    return $self->_server_receive_datagram(
        $bytes,
        $local,
        $peer,
        0 + $ecn,
    ) if $self->{mode} eq 'server';

    $self->{connection}->_receive_datagram(
        $bytes,
        $local,
        $peer,
        0 + $ecn,
    );
    $self->{connection}->_dispatch_stream_activity;
    $self->{connection}->_dispatch_stream_availability;
    $self->{connection}->_dispatch_datagrams;
    return;
}

sub next_datagram {
    my ($self) = @_;

    return $self->_server_next_datagram
        if $self->{mode} eq 'server';

    return $self->{connection}->_next_datagram;
}

sub timeout_after {
    my ($self) = @_;

    return $self->_server_timeout_after
        if $self->{mode} eq 'server';

    return $self->{connection}->_timeout_after;
}

sub handle_timeout {
    my ($self) = @_;

    return $self->_server_handle_timeout
        if $self->{mode} eq 'server';

    return $self->{connection}->_handle_timeout;
}

1;

__END__

=head1 NAME

Net::QUIC::Endpoint - lower-level QUIC engine

=head1 DESCRIPTION

Endpoint is the low-level transport API underneath L<Net::QUIC::Driver>.

Most applications should use Driver.

Use Endpoint directly only when you want to manage the QUIC service cycle
yourself.

The caller owns:

    the UDP socket
    sending every outgoing datagram
    draining all pending output
    scheduling the next QUIC timeout
    calling handle_timeout when that timer fires

Endpoint owns the QUIC protocol state.

A client Endpoint has one L<Net::QUIC::Connection>.

A server Endpoint can manage many Connections behind one UDP socket.

=head1 BASIC CYCLE

A direct client integration looks like this:

    receive one UDP packet
        -> receive_datagram

    send all pending output
        -> next_datagram until undef

    ask when QUIC next needs a timer
        -> timeout_after

    timer fires
        -> handle_timeout

Then drain C<next_datagram> again and schedule the new C<timeout_after>.

Driver exists so most event-loop adapters do not have to repeat this logic.

=head1 SYNOPSIS

    use Net::QUIC::Endpoint;

    my $endpoint = Net::QUIC::Endpoint->client(
        local       => $packed_local_address,
        peer        => $packed_peer_address,
        alpn        => 'my-protocol',
        server_name => 'example.com',
    );

    my $connection = $endpoint->connection;

    while (my $datagram = $endpoint->next_datagram) {
        send_udp($datagram);
    }

    my $seconds = $endpoint->timeout_after;

=head1 ADDRESSES

C<local> and C<peer> are packed IPv4 or IPv6 socket addresses.

C<local> must be the actual local address used by the packet.

Wildcard bind addresses such as:

    0.0.0.0
    ::

are not concrete QUIC paths.

If a server UDP socket is bound to a wildcard address, the integration must
recover the real destination address of each received packet.

=head1 METHODS

=head2 client

    my $endpoint = Net::QUIC::Endpoint->client(
        local       => $packed_local_address,
        peer        => $packed_peer_address,
        alpn        => 'my-protocol',
        server_name => 'example.com',
    );

Creates a client Endpoint and its Connection.

Required options are:

=over 4

=item * C<local>

Packed local UDP address.

=item * C<peer>

Packed server UDP address.

=item * C<alpn>

Application protocol name.

=item * C<server_name>

Name expected in the server certificate.

=back

Server certificates are verified by default.

For a private or test CA:

    ca_file => '/path/to/private-ca.pem'

adds that PEM file to the normal trust store.

Net::QUIC does not provide an insecure skip-verification option.

=head3 Optional client features

Choose the first QUIC version:

    version => 2

Supported values are 1 and 2. The default is 1.

Resume a previous TLS session:

    session_ticket => $saved_ticket

Reuse a previous address-validation token:

    address_token => $saved_address_token

Attempt 0-RTT early data:

    early_data => $saved_early_data_state

C<early_data> already contains its matching session ticket, so it cannot be
combined with C<session_ticket>.

Saved session, address-token, and early-data values are opaque. Net::QUIC
remembers the QUIC version inside them and automatically uses the correct
version.

0-RTT data can be replayed. Only send operations that are safe to repeat.

=head3 Transport limits

Client and server both accept:

    transport => {
        handshake_timeout       => 10,
        idle_timeout            => 30,
        connection_window       => 1024 * 1024,
        stream_window           => 256 * 1024,
        max_bidi_streams        => 100,
        max_uni_streams         => 100,
        max_datagram_frame_size => 0,
    }

These are the defaults.

C<handshake_timeout> is how long the initial connection setup may take.

C<idle_timeout> is how long an otherwise established connection may stay idle.
A value of zero disables the advertised idle timeout.

C<connection_window> is the starting receive allowance for the whole
connection.

C<stream_window> is the starting receive allowance for each Stream.

C<max_bidi_streams> and C<max_uni_streams> are the initial numbers of
peer-created streams that may exist at once.

C<max_datagram_frame_size> advertises this endpoint's RFC 9221 QUIC DATAGRAM
receive limit. Zero disables QUIC DATAGRAM receive support. A value such as
65535 enables it while the actual sendable payload is still limited by the
peer and the current network path.

See L<Net::QUIC::Connection/QUIC DATAGRAM>.

The Stream values are flow-control starting values, not lifetime byte or
stream limits.

=head2 server

    my $endpoint = Net::QUIC::Endpoint->server(
        alpn             => 'my-protocol',
        certificate_file => 'server-cert.pem',
        private_key_file => 'server-key.pem',
    );

Creates a server Endpoint.

One server Endpoint can manage many QUIC Connections.

Required options are:

    alpn
    certificate_file
    private_key_file

=head3 Address validation

To require a new client to prove that it can receive packets at its source
address:

    validate_address => 1

A new client may receive QUIC Retry before a full Connection is created.

After a validated handshake, Net::QUIC can issue NEW_TOKEN so a returning
client can prove the same address without another Retry round trip.

The client exposes that opaque value through
L<Net::QUIC::Connection/address_token>.

=head3 0-RTT

To allow replayable early data:

    accept_early_data => 1

Only enable this when the application knows how to handle operations that may
be repeated.

=head3 QUIC version preference

A server accepts QUIC v1 and v2.

To prefer v2 when a compatible client starts with v1:

    preferred_version => 2

If this option is omitted, the server keeps the client's chosen supported
version.

=head3 Preferred server address

A server can advertise another address for the same Connection:

    preferred_address => $packed_server_address

The client validates that path before switching to it.

The UDP integration must actually be able to send and receive on the advertised
address.

=head2 connection

    my $connection = $endpoint->connection;

Client only.

Returns the client's Connection.

A server manages many Connections, so server code uses
L</next_connection> instead.

=head2 next_connection

    while (my $connection = $endpoint->next_connection) {
        ...
    }

Server only.

Returns the next newly created Connection, or undef when none is waiting.

A new Connection can be returned before its TLS handshake is complete. Check:

    $connection->ready

before ordinary application work.

=head2 receive_datagram

    $endpoint->receive_datagram($bytes, $local, $peer);

Feeds one received UDP datagram into QUIC.

C<$local> must be the concrete local destination address for this packet.

C<$peer> is the remote sender address.

An ECN-aware integration can pass the packet's two-bit IP-header ECN value as a
fourth argument:

    $endpoint->receive_datagram($bytes, $local, $peer, $ecn);

The values are:

    0   Not-ECT
    1   ECT(1)
    2   ECT(0)
    3   CE

Omitting C<$ecn> is equivalent to zero.

=head2 next_datagram

    while (my $datagram = $endpoint->next_datagram) {
        ...
    }

Returns the next complete UDP datagram QUIC wants sent.

Returns undef when no output is waiting.

The returned L<Net::QUIC::Datagram> contains the payload, local address, peer
address, and ECN mark for the packet.

=head2 timeout_after

    my $seconds = $endpoint->timeout_after;

Returns the number of seconds until QUIC next needs timer service.

It can return:

=over 4

=item * a positive number

Schedule a one-shot timer for that many seconds.

=item * zero

The timeout is already due.

=item * undef

No timer is currently needed.

=back

For a server this is the earliest deadline among all managed Connections, so
the integration still needs only one Endpoint timer.

=head2 handle_timeout

    $endpoint->handle_timeout;

Reports that the Endpoint timer fired.

After calling it:

    drain next_datagram
    ask timeout_after again

=head1 WHEN TO USE ENDPOINT DIRECTLY

Endpoint is useful for:

    tests
    unusual event-loop integrations
    integrations that already have their own QUIC service loop

For ordinary event-loop code, L<Net::QUIC::Driver> is simpler.

=head1 SEE ALSO

L<Net::QUIC>

L<Net::QUIC::Driver>

L<Net::QUIC::Connection>

L<Net::QUIC::Datagram>

=cut
