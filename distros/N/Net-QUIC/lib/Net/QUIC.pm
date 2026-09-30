package Net::QUIC;

use strict;
use warnings;

use XSLoader ();

our $VERSION = '0.01';

XSLoader::load(__PACKAGE__, $VERSION);

1;

__END__

=head1 NAME

Net::QUIC - QUIC transport for Perl

=head1 SYNOPSIS

Most applications start with L<Net::QUIC::Driver>:

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

=head1 DESCRIPTION

Net::QUIC is a QUIC transport library for Perl.

It owns QUIC and TLS protocol state but does not choose an event loop or own
the application's UDP socket.

The ordinary public model is:

    Driver
      |
      +-- Connection
              |
              +-- Stream

L<Net::QUIC::Driver> connects QUIC to an event loop.

L<Net::QUIC::Connection> represents one QUIC connection.

L<Net::QUIC::Stream> sends and receives ordered application bytes.

L<Net::QUIC::Endpoint> exists underneath Driver as the lower-level transport
engine. Most applications do not need to drive Endpoint directly.

=head1 WHAT NET::QUIC DOES

Net::QUIC handles the QUIC-specific work, including:

    QUIC packet processing
    TLS 1.3
    certificate verification
    stream flow control
    retransmission state
    connection IDs
    QUIC timers
    connection close and draining

The event-loop integration supplies:

    one UDP socket
    readable and writable readiness
    one replaceable one-shot timer

QUIC streams carry ordered bytes. They do not provide application message
boundaries.

Net::QUIC is not HTTP/3 and is not a web framework.

=head1 INSTALLATION

Install from CPAN in the usual way:

    cpanm Net::QUIC

Net::QUIC uses L<Alien::ngtcp2> for its native QUIC and TLS dependencies. A
normal installation does not require the application developer to separately
configure ngtcp2.

Event-loop modules shown in F<examples/> are optional integrations rather than
Net::QUIC runtime dependencies.

=head1 EVENT LOOP INTEGRATION

Driver is the recommended integration layer.

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

    requested QUIC timeout fired
        -> $driver->timeout

    UDP output recovered from backpressure
        -> $driver->writable

Driver owns output draining, backpressure pause/resume state, and timeout
replacement.

Application Stream operations automatically notify Driver when they may create
new QUIC output.

There is no ordinary application-visible QUIC pump loop.

The packed C<local> address passed with a received UDP packet is part of the
QUIC network path. It must be the concrete local destination address, not a
wildcard bind address such as C<0.0.0.0> or C<::>.

A wildcard-bound UDP adapter must therefore recover the packet's actual local
destination address with the operating system's packet-info mechanism and
preserve the selected local source address when sending Net::QUIC Datagrams.

Net::QUIC leaves these socket operations to the event-loop adapter.

See L<Net::QUIC::Driver> for the full contract.

=head1 CONNECTIONS AND STREAMS

A client Driver exposes its Connection with:

    my $connection = $driver->connection;

A server Driver can expose many Connections:

    while (my $connection = $driver->next_connection) {
        ...
    }

Check handshake readiness with:

    if ($connection->ready) {
        ...
    }

Open a bidirectional stream with:

    my $stream = $connection->open_bidi_stream;

    if ($stream) {
        $stream->send("hello");
        $stream->finish;
    }

C<open_bidi_stream> and C<open_uni_stream> can return undef when the peer's
current stream limit has been reached. That is normal QUIC flow control, not a
Connection failure.

Peer-created streams are returned by:

    while (my $stream = $connection->next_stream) {
        ...
    }

Received stream bytes are read with:

    while (defined(my $bytes = $stream->next_data)) {
        ...
    }

See L<Net::QUIC::Connection> and L<Net::QUIC::Stream>.

=head1 CONNECTION OUTCOMES

A normal application close is started with:

    $connection->close;

Connection close and remote protocol/TLS outcomes can be inspected with:

    my $info = $connection->close_info;

C<close_info> distinguishes application close, transport errors, TLS errors,
certificate failures, handshake timeout, idle timeout, and dropped
Connections.

Local API misuse and local implementation failures remain Perl exceptions.

=head1 TLS

QUIC always uses TLS 1.3.

Net::QUIC uses Picotls for QUIC TLS, with OpenSSL underneath for cryptography
and certificate verification.

Client certificate verification is enabled by default.

C<server_name> is used for DNS-name or IP-address verification. A private CA
may be added with C<ca_file>.

There is no insecure skip-verification option.

=head1 EXAMPLES

The distribution includes complete event-loop examples in F<examples/>.

The current examples cover:

    Linux::Event
    AnyEvent
    IO::Async
    Mojo::IOLoop
    EV

There is also a small IO::Select QUIC echo server that can be used as a local
test target for the client examples.

See F<examples/README.md>.

=head1 LOW-LEVEL ENDPOINT

L<Net::QUIC::Endpoint> remains available for integrations that deliberately
want direct control over:

    receive_datagram
    next_datagram
    timeout_after
    handle_timeout

Endpoint callers are responsible for draining QUIC output and maintaining its
timer themselves.

Driver exists so ordinary event-loop adapters do not need to repeat that
logic.

=head1 NATIVE INFORMATION

=head2 ngtcp2_version

    my $version = Net::QUIC::ngtcp2_version();

Returns the version string reported by the linked ngtcp2 library.

=head2 ngtcp2_version_num

    my $version_num = Net::QUIC::ngtcp2_version_num();

Returns ngtcp2's numeric version value.

=head2 crypto_backend

    my $backend = Net::QUIC::crypto_backend();

Returns C<picotls>.

This is diagnostic information. Application code normally does not need to
branch on the TLS implementation.

=head1 NATIVE DEPENDENCY

Net::QUIC requires L<Alien::ngtcp2> 0.03 or newer.

Alien::ngtcp2 supplies the tested ngtcp2 and Picotls build. Normal Net::QUIC
applications do not choose a TLS backend.

=head1 SEE ALSO

L<Net::QUIC::Driver>

L<Net::QUIC::Endpoint>

L<Net::QUIC::Connection>

L<Net::QUIC::Stream>

L<Net::QUIC::Datagram>

L<Alien::ngtcp2>

L<https://github.com/ngtcp2/ngtcp2>

=head1 AUTHOR

Joshua S. Day

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Joshua S. Day.

This is free software, licensed under:

    The MIT (X11) License

=cut
