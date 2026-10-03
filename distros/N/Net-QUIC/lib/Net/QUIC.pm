package Net::QUIC;

use strict;
use warnings;

use XSLoader ();

our $VERSION = '0.03';

XSLoader::load(__PACKAGE__, $VERSION);

1;

__END__

=head1 NAME

Net::QUIC - QUIC transport for Perl

=head1 DESCRIPTION

Net::QUIC gives Perl applications secure QUIC connections and byte streams.

If QUIC is new to you, the useful model is:

    one Connection
        |
        +-- Stream
        +-- Stream
        +-- Stream

A Connection is one secure relationship with a peer.

A Stream is one reliable ordered sequence of bytes inside that Connection.

Net::QUIC handles the QUIC protocol, TLS 1.3, retransmission, flow control,
timers, connection IDs, migration, and the other transport details.

Your event loop still owns the UDP socket.

You do not need to know ngtcp2 to use Net::QUIC. It is an internal native
dependency.

Net::QUIC is not HTTP/3 and is not a web framework. It provides connections
and byte streams. Your application decides what the bytes mean.

=head1 START HERE

Most applications use three classes:

    Net::QUIC::Driver
        |
        +-- Net::QUIC::Connection
                    |
                    +-- Net::QUIC::Stream

L<Net::QUIC::Driver> connects Net::QUIC to UDP and a timer.

L<Net::QUIC::Connection> represents one QUIC connection.

L<Net::QUIC::Stream> sends and receives application bytes.

L<Net::QUIC::Endpoint> is the lower-level engine under Driver. Most
applications do not need to use Endpoint directly.

=head1 SYNOPSIS

Create a client Driver:

    use Net::QUIC::Driver;

    my $driver = Net::QUIC::Driver->client(
        local       => $packed_local_address,
        peer        => $packed_peer_address,
        alpn        => 'my-protocol',
        server_name => 'example.com',

        send => sub {
            my ($datagram) = @_;
            ...
        },

        set_timeout => sub {
            my ($seconds) = @_;
            ...
        },
    );

    my $connection = $driver->connection;

    $driver->start;

After the handshake is ready:

    return if !$connection->ready;

    my $stream = $connection->open_bidi_stream;

    if ($stream) {
        $stream->send("hello\n");
        $stream->finish;
    }

Read streams opened by the peer:

    while (my $stream = $connection->next_stream) {
        while (defined(my $bytes = $stream->next_data)) {
            handle_bytes($bytes);
        }
    }

=head1 QUIC STREAMS ARE BYTE STREAMS

A QUIC Stream is an ordered sequence of bytes.

It is not a sequence of application messages.

One call to:

    $stream->send($message);

does not guarantee one matching C<next_data> result on the peer.

If the application needs messages, add framing above the Stream, such as a
newline, fixed record size, or length prefix.

=head1 WHAT DRIVER NEEDS

Driver is the recommended event-loop integration layer.

The event loop owns:

    UDP I/O
    one replaceable one-shot timer

The adapter supplies two callbacks:

    send
    set_timeout

and reports four events:

    start
    receive
    timeout
    writable

Conceptually:

    UDP transport ready
        -> $driver->start

    UDP packet received
        -> $driver->receive($bytes, $local, $peer)

    requested timer fired
        -> $driver->timeout

    UDP output became writable again
        -> $driver->writable

That is the ordinary Driver contract.

There is no application-visible QUIC pump loop.

Driver automatically drains pending output, updates the timer, pauses for UDP
backpressure, and resumes after C<writable>.

The optional fourth argument to C<receive> is the packet's ECN codepoint:

    $driver->receive($bytes, $local, $peer, $ecn);

Adapters that do not support ECN can keep using the three-argument form.

See L<Net::QUIC::Driver> for the full adapter contract.

=head1 LOCAL AND PEER ADDRESSES

C<local> and C<peer> are packed IPv4 or IPv6 socket addresses.

C<local> must be the actual local address used by that packet.

Wildcard bind addresses such as:

    0.0.0.0
    ::

are not concrete QUIC paths.

A server may bind its UDP socket to a wildcard address, but the adapter must
recover the real destination address for each received packet.

If the event system cannot do that, bind the QUIC socket to one concrete local
address instead.

=head1 CONNECTIONS

A client Driver has one Connection:

    my $connection = $driver->connection;

A server Driver can create many:

    while (my $connection = $driver->next_connection) {
        ...
    }

Wait for the handshake before ordinary application work:

    if ($connection->ready) {
        ...
    }

Open streams with:

    $connection->open_bidi_stream;
    $connection->open_uni_stream;

These methods can return undef when the peer's current stream limit has been
reached. That is normal flow control, not a failed Connection.

=head1 ADVANCED PROTOCOL ENGINES

Ordinary applications can ignore this section.

Protocol engines that need explicit receive consumption, acknowledgement
progress, Stream wake-ups, or bounded transmit memory can use:

    Connection:
        on_stream_activity
        next_active_stream_id
        send_buffer_limit
        send_buffered_bytes

    Stream:
        next_data_chunk
        consume
        acked_offset
        send_some
        send_buffered_bytes

The ordinary C<send>, C<finish>, and C<next_data> API remains unchanged.

These are transport primitives. Net::QUIC does not add HTTP/3 or other
application-protocol semantics.

See L<Net::QUIC::Connection> and L<Net::QUIC::Stream> for the details.

=head1 CLOSING AND ERRORS

Start a normal close with:

    $connection->close;

Remote close conditions and protocol/TLS outcomes are available through:

    my $info = $connection->close_info;

Local programming mistakes and invalid local configuration still throw Perl
exceptions.

=head1 TLS

QUIC always uses TLS 1.3.

Clients verify server certificates by default.

C<server_name> is the DNS name or IP address expected in the certificate.

For a private CA, use:

    ca_file => '/path/to/private-ca.pem'

Net::QUIC does not provide an insecure skip-verification switch.

=head1 ADVANCED QUIC FEATURES

Net::QUIC also supports:

    QUIC v1 and QUIC v2
    session resumption
    optional 0-RTT early data
    Retry and NEW_TOKEN address validation
    active connection migration
    server preferred addresses
    PMTU discovery
    ECN

These features are documented in L<Net::QUIC::Connection>,
L<Net::QUIC::Endpoint>, and the main README.

Applications that only need ordinary reliable streams do not need to use most
of them directly.

=head1 INSTALLATION

Install from CPAN:

    cpanm Net::QUIC

Net::QUIC uses L<Alien::ngtcp2> for its native dependencies.

A normal installation does not require you to separately configure ngtcp2,
Picotls, or OpenSSL.

The event-loop modules shown in F<examples/> are optional example dependencies.

=head1 EXAMPLES

The distribution includes examples for:

    Linux::Event
    AnyEvent
    IO::Async
    Mojo::IOLoop
    EV

There is also a small IO::Select echo server.

See F<examples/README.md>.

=head1 LOW-LEVEL ENDPOINT

L<Net::QUIC::Endpoint> is available when an integration deliberately wants to
manage the lower-level cycle itself:

    receive_datagram
    next_datagram
    timeout_after
    handle_timeout

Most event-loop adapters are simpler with Driver.

=head1 NATIVE INFORMATION

These methods are mainly diagnostic.

=head2 ngtcp2_version

    my $version = Net::QUIC::ngtcp2_version();

Returns the version string reported by the linked ngtcp2 library.

=head2 ngtcp2_version_num

    my $version_num = Net::QUIC::ngtcp2_version_num();

Returns ngtcp2's numeric version value.

=head2 crypto_backend

    my $backend = Net::QUIC::crypto_backend();

Returns C<picotls>.

Application code normally does not need to branch on the native TLS
implementation.

=head1 NATIVE DEPENDENCY

Net::QUIC requires L<Alien::ngtcp2> 0.03 or newer.

Alien::ngtcp2 supplies the tested ngtcp2 and Picotls build.

=head1 SEE ALSO

L<Net::QUIC::Driver>

L<Net::QUIC::Endpoint>

L<Net::QUIC::Connection>

L<Net::QUIC::Stream>

L<Net::QUIC::Datagram>

L<Alien::ngtcp2>

=head1 AUTHOR

Joshua S. Day

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Joshua S. Day.

This is free software, licensed under:

    The MIT (X11) License

=cut
