package Net::QUIC::Endpoint;

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(looks_like_number refaddr);
use Net::QUIC ();
use Net::QUIC::Connection ();
use Net::QUIC::Datagram ();

our $VERSION = '0.01';

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
        max_bidi_streams  => 100,
        max_uni_streams   => 100,
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
    )) {
        my $number = $config{$name};

        croak "$name must be a non-negative integer"
            if !defined($number)
            || $number !~ /\A\d+\z/;

        $config{$name} = 0 + $number;
    }

    return [
        $config{handshake_timeout},
        $config{idle_timeout},
        $config{connection_window},
        $config{stream_window},
        $config{max_bidi_streams},
        $config{max_uni_streams},
    ];
}

sub _require_concrete_local {
    my ($class, $local) = @_;

    croak "local must be a concrete IPv4 or IPv6 address; "
        . "0.0.0.0 and :: are wildcard bind addresses, not QUIC paths"
        if Net::QUIC::_local_address_is_unspecified($local);

    return;
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

    my $connection = Net::QUIC::Connection->_client_new(
        $args{local},
        $args{peer},
        $args{alpn},
        $args{server_name},
        $ca_file,
        $transport,
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
    );

    my $transport = $class->_transport_config(delete $args{transport});

    return bless {
        mode                => 'server',
        alpn                => $args{alpn},
        server_tls          => $server_tls,
        cid_length          => $class->_server_cid_length,
        server_secret       => $class->_server_secret,
        validate_address    => $args{validate_address} ? 1 : 0,
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
    my ($self, $bytes, $local, $peer) = @_;

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
        );

        $connection->_receive_datagram($bytes, $local, $peer);
        $connection->_dispatch_stream_availability;

        $self->{routes}{$initial_dcid} = $connection;
        push @{$self->{connections}}, $connection;
        push @{$self->{pending_connections}}, $connection;
        $self->_sync_server_routes($connection);
        $self->_retire_server_connections;
        return;
    }

    $connection->_receive_datagram($bytes, $local, $peer);
    $connection->_dispatch_stream_availability;
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
    my ($self, @args) = @_;

    __PACKAGE__->_require_concrete_local($args[1]);

    return $self->_server_receive_datagram(@args)
        if $self->{mode} eq 'server';

    $self->{connection}->_receive_datagram(@args);
    $self->{connection}->_dispatch_stream_availability;
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

Net::QUIC::Endpoint - low-level QUIC transport boundary

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
        $udp->send($datagram->data, $datagram->peer);
    }

    my $after = $endpoint->timeout_after;

=head1 DESCRIPTION

Net::QUIC::Endpoint is the low-level boundary between QUIC and an event loop.

Most integrations should use L<Net::QUIC::Driver>, which owns Endpoint output
draining, backpressure pause/resume, and timeout replacement.

Direct Endpoint users own those rules themselves.

The event-loop integration owns the UDP socket and its timer. Endpoint owns the
transport-facing side of QUIC and gives the integration datagrams to send and
a timeout to schedule.

A QUIC connection is represented separately by L<Net::QUIC::Connection>.
A client endpoint owns one connection. A server endpoint can manage several
connections behind one UDP socket and routes incoming packets by QUIC
destination connection ID.

For a client integration, the basic cycle is:

    UDP readable
        -> receive_datagram
        -> send each next_datagram
        -> arm a timer for timeout_after

    timer fires
        -> handle_timeout
        -> send each next_datagram
        -> arm the timer again

The C<local> and C<peer> addresses are packed socket addresses such as those
returned by Perl's L<Socket> functions or by the networking framework in use.
They must be IPv4 or IPv6 addresses.

C<local> must identify the concrete local endpoint for the packet. Wildcard
bind addresses C<0.0.0.0> and C<::> are rejected because they do not identify
a QUIC network path.

=head1 METHODS

=head2 client

    my $endpoint = Net::QUIC::Endpoint->client(
        local       => $packed_local_address,
        peer        => $packed_peer_address,
        alpn        => 'my-protocol',
        server_name => 'example.com',
    );

Creates a client endpoint and its first L<Net::QUIC::Connection>.

C<local>, C<peer>, C<alpn>, and C<server_name> are required.

Server certificates are verified by default. Net::QUIC uses Picotls' OpenSSL
certificate verifier, including certificate-chain validation and DNS-name or
IP-address verification against C<server_name>. The verifier uses OpenSSL's
default trust locations.

For a private or test certificate authority, C<ca_file> adds certificates from
a PEM file to the default trust store:

    my $endpoint = Net::QUIC::Endpoint->client(
        local       => $packed_local_address,
        peer        => $packed_peer_address,
        alpn        => 'my-protocol',
        server_name => 'internal.example',
        ca_file     => '/path/to/private-ca.pem',
    );

Net::QUIC does not provide an insecure skip-verification switch.

Both client and server accept an optional C<transport> hash:

    transport => {
        handshake_timeout => 10,
        idle_timeout      => 30,
        connection_window => 1024 * 1024,
        stream_window     => 256 * 1024,
        max_bidi_streams  => 100,
        max_uni_streams   => 100,
    }

These are the Net::QUIC defaults.

C<handshake_timeout> and C<idle_timeout> are in seconds. Fractional seconds are
accepted to millisecond precision. C<handshake_timeout> must be greater than
zero. C<idle_timeout =E<gt> 0> disables the advertised idle timeout.

C<connection_window> is the initial connection-level receive flow-control
credit in bytes. C<stream_window> is the initial per-stream receive credit and
is used for bidirectional and unidirectional streams. Net::QUIC returns receive
credit as the application consumes data, so these are starting windows rather
than lifetime byte limits.

C<max_bidi_streams> and C<max_uni_streams> are the initial numbers of concurrent
peer-initiated streams allowed. Closed peer streams return stream credit, so
the values do not limit how many streams may exist over the life of a
connection.

Net::QUIC currently advertises active migration as disabled. Migration is not
exposed as a tuning option until the library implements and tests migration
semantics.

ACK timing, congestion control, packet sizing, PMTU behavior, and connection ID
management remain ngtcp2/Net::QUIC policy rather than public knobs at this
stage.

=head2 server

    my $endpoint = Net::QUIC::Endpoint->server(
        alpn             => 'my-protocol',
        certificate_file => 'server-cert.pem',
        private_key_file => 'server-key.pem',
        validate_address => 1,
    );

Creates a server endpoint. The UDP socket still belongs to the integration
layer. One server endpoint can route packets for multiple QUIC connections.

Unsupported QUIC versions are answered statelessly with Version Negotiation
before a Connection object is created.

C<validate_address> is optional and defaults to false. When true, the first
acceptable Initial from a new peer receives Retry instead of creating a
Connection. The Retry token is authenticated, bound to the peer socket address,
and valid for 10 seconds. Net::QUIC creates the Connection only after the peer
returns a valid token. A token replayed from a different peer address is
rejected without creating connection state.

Finished Connections are retired automatically after QUIC's closing or
draining period, and all of their CID routes are removed from the Endpoint at
the same time.

Server certificate and private-key files are loaded once when the Endpoint is
constructed. Accepted Connections create their own Picotls sessions from that
shared server TLS context instead of reopening or reparsing the credential
files. Connections retain the shared context for as long as they need it.

Unknown short-header packets that cannot be routed to a live Connection can
receive a Stateless Reset when they are large enough to do so safely. The
Endpoint derives reset tokens from its private server secret and the destination
connection ID, so it does not recreate Connection state just to send the reset.
Unknown long-header packets and packets that are too small are dropped.

=head2 connection

    my $connection = $endpoint->connection;

Returns the client connection owned by a client endpoint.

A server endpoint manages multiple connections, so calling C<connection> on a
server endpoint is an error. Use C<next_connection> instead.

=head2 next_connection

    while (my $connection = $endpoint->next_connection) {
        ...
    }

Server only. Returns the next newly created connection, or undef when there is
none waiting.

A connection can be returned before its TLS handshake is complete. Use
C<$connection-E<gt>ready> when the application needs handshake readiness.

=head2 receive_datagram

    $endpoint->receive_datagram($bytes, $local, $peer);

Feeds one received UDP datagram into QUIC.

C<$local> must be the packed concrete destination address on which the packet
arrived. It must not be C<0.0.0.0> or C<::>.

If the UDP socket is bound to a wildcard address, the integration must use the
platform's packet-info or destination-address mechanism to recover this value.
The Endpoint intentionally does not own or inspect the UDP socket.

C<$peer> is the packed address of the remote sender.

=head2 next_datagram

    while (my $datagram = $endpoint->next_datagram) {
        ...
    }

Returns the next UDP datagram QUIC wants sent, or undef if none is ready.

=head2 timeout_after

    my $seconds = $endpoint->timeout_after;

Returns the number of seconds until QUIC next needs timer service. It may
return zero when the timeout is already due, or undef when no timeout is
currently needed.

For a server endpoint this is the earliest timeout among all managed
connections, so the integration still needs only one endpoint timer.

=head2 handle_timeout

    $endpoint->handle_timeout;

Tells QUIC that its event-loop timer fired. After this call, drain
C<next_datagram> again and arrange the new C<timeout_after> value.

=cut
