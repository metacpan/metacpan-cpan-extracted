# Net::QUIC

Net::QUIC is a QUIC transport library for Perl.

It gives Perl applications QUIC connections and QUIC streams without choosing
an event loop for them.

Net::QUIC handles:

- QUIC packet and connection state
- TLS 1.3
- certificate verification
- stream flow control
- retransmission and acknowledgement state
- connection IDs
- timers required by QUIC

Your event loop still owns the UDP socket.

Net::QUIC is not HTTP/3, a web framework, or an application message protocol.
QUIC streams carry ordered bytes. Applications decide what those bytes mean.

## Installation

From CPAN:

```text
cpanm Net::QUIC
```

Net::QUIC uses `Alien::ngtcp2` for its native QUIC and TLS dependencies.
A normal Net::QUIC install does not require you to separately find or configure
ngtcp2.

The event-loop modules shown in `examples/` are optional. Net::QUIC itself
does not require Linux::Event, AnyEvent, IO::Async, Mojolicious, or EV.

## Start here

Most applications only need to understand three objects:

```text
Net::QUIC::Driver
        |
        +-- Net::QUIC::Connection
                    |
                    +-- Net::QUIC::Stream
```

Use `Net::QUIC::Driver` to connect Net::QUIC to an event loop.

Use `Net::QUIC::Connection` to open or accept QUIC streams.

Use `Net::QUIC::Stream` to send and receive application bytes.

There is also a lower-level `Net::QUIC::Endpoint`. Most applications do not
need to drive it directly.

The full internal relationship is:

```text
Net::QUIC::Driver
        |
        +-- Net::QUIC::Endpoint
                |
                +-- Net::QUIC::Connection
                            |
                            +-- Net::QUIC::Stream
```

## The event-loop contract

A Net::QUIC adapter needs only:

- one UDP socket
- one replaceable one-shot timer

The adapter gives Driver two callbacks:

```perl
send => sub {
    my ($datagram) = @_;

    # Accept one complete UDP datagram for output.
    # Return true when another datagram can be accepted immediately.
    # Return false after accepting this datagram if output is backpressured.
},

set_timeout => sub {
    my ($seconds) = @_;

    # Replace the current one-shot QUIC timeout.
    # undef means cancel the current timeout.
},
```

The `send` callback receives one complete `Net::QUIC::Datagram`.

Its useful values are:

```perl
$datagram->data;     # complete UDP payload bytes
$datagram->peer;     # packed destination socket address
$datagram->local;    # packed local socket address chosen by QUIC
```

The adapter sends `data` as one UDP datagram to `peer`. `local` describes
the local path associated with that packet and is useful to integrations that
manage more than one local address.

The event loop reports four events back to Driver:

```perl
$driver->start;

$driver->receive(
    $bytes,
    $packed_local_address,
    $packed_peer_address,
);

$driver->timeout;

$driver->writable;
```

That is the complete ordinary adapter contract.

There is no application-visible QUIC pump loop.

Driver drains QUIC output, pauses when the adapter reports backpressure,
resumes when `writable` is called, and replaces the QUIC timer whenever the
deadline changes.

Stream operations such as `send`, `finish`, `reset`, and `next_data`
automatically notify Driver when more QUIC work may be needed.

Driver handles transport servicing; it does not decide what your application
should do. After `receive`, `timeout`, or `writable` returns, application
code can inspect the Connection and Streams normally:

```perl
$driver->receive($bytes, $local, $peer);

if ($connection->ready) {
    while (my $stream = $connection->next_stream) {
        ...
    }
}
```

The examples use this pattern through a small application-service callback.

## Local addresses and wildcard UDP sockets

The `local` address passed to Net::QUIC is part of the QUIC network path. It
must be the concrete IPv4 or IPv6 address for that packet.

These are not valid QUIC local paths:

```text
0.0.0.0
::
```

They are wildcard bind addresses. They mean "accept traffic for any local
address"; they do not identify the address on which one particular UDP packet
arrived.

A client normally avoids this issue by connecting its UDP socket first and
using `getsockname` after the kernel has selected the concrete local address.

A server may bind its UDP socket to a wildcard address, but its adapter must
recover the actual destination address of every received packet and pass that
packed address to:

```perl
$driver->receive($bytes, $local, $peer);
```

The adapter must also send each outbound Datagram using the local source address
reported by:

```perl
$datagram->local;
```

For a socket bound to one concrete address, the socket already fixes the local
path and no special source-address selection is normally needed.

For a wildcard-bound socket this usually requires packet-info support. On
Linux, IPv4 adapters can use `IP_PKTINFO` with `recvmsg` / `sendmsg`;
IPv6 has the corresponding packet-info mechanism. Other operating systems have
their own destination-address ancillary-data APIs.

Net::QUIC deliberately does not implement those socket operations. The event
loop or UDP adapter owns the socket. Net::QUIC rejects wildcard addresses at
its QUIC path boundary so an adapter cannot accidentally give ngtcp2 an
incorrect network path.

If an event system cannot report the destination address for a wildcard-bound
socket, bind the QUIC socket to one concrete local address instead.

## Event-loop examples

The `examples/` directory contains complete client integrations for common
Perl event systems:

```text
examples/linux-event-client.pl
examples/anyevent-client.pl
examples/io-async-client.pl
examples/io-async-async-await-client.pl
examples/mojo-ioloop-client.pl
examples/ev-client.pl
```

They all implement the same Driver contract so the event-loop-specific part is
easy to compare.

The two IO::Async examples deliberately show both styles: one keeps the
application callback-driven, while the other uses Future::AsyncAwait so the
application flow can be written sequentially without changing the Net::QUIC
Driver API.

See `examples/README.md` for how to run them.

## A client connection

A client Driver is created after the UDP socket addresses are known.

The four values that identify the connection are straightforward:

- `local` is this UDP socket's packed local address.
- `peer` is the server's packed UDP address.
- `alpn` names the application protocol carried over QUIC. Client and server
  must use a compatible ALPN value.
- `server_name` is the DNS name or IP address that the server certificate is
  expected to represent. It is used for certificate verification.

For example, a client can connect to the numeric peer address
`192.0.2.20:4433` while using `server_name => 'service.example.com'` when
that is the name on the server certificate.

The packed addresses are the ordinary native socket-address values used by
Perl's `Socket` APIs. Event-loop socket objects can often provide them
directly.


```perl
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
```

`local` and `peer` are packed IPv4 or IPv6 socket addresses.

The Driver constructor does not send packets. `start` tells it the UDP
transport is ready. A client normally produces its first QUIC Initial packet at
that point.

The cryptographic handshake completes asynchronously:

```perl
if ($connection->ready) {
    ...
}
```

## A server

A server uses the same Driver contract:

```perl
my $driver = Net::QUIC::Driver->server(
    alpn             => 'my-protocol',
    certificate_file => 'server-cert.pem',
    private_key_file => 'server-key.pem',

    send => sub {
        my ($datagram) = @_;
        ...
    },

    set_timeout => sub {
        my ($seconds) = @_;
        ...
    },
);

$driver->start;
```

Feed each received UDP packet to the same Driver:

```perl
$driver->receive($bytes, $local, $peer);
```

A server Driver can own many QUIC connections. Pull newly created connections
with:

```perl
while (my $connection = $driver->next_connection) {
    ...
}
```

A server Connection may be returned before its handshake is complete. Check
`ready` before beginning application work that requires an established
connection.

Set:

```perl
validate_address => 1
```

to require QUIC Retry/address validation before allocating a new Connection.

Without that option, address validation is off and the extra Retry round trip
is avoided.

## Sending on a stream

Open a bidirectional stream:

```perl
my $stream = $connection->open_bidi_stream;

if ($stream) {
    $stream->send("hello\n");
    $stream->finish;
}
```

`finish` sends QUIC FIN after the already queued bytes. It closes only this
endpoint's send side. The peer can still reply on the same bidirectional
stream.

A local unidirectional stream is opened with:

```perl
my $stream = $connection->open_uni_stream;
```

This endpoint can send on that stream but cannot receive application bytes from
it.

## When opening a stream returns undef

QUIC limits how many streams an endpoint may have open at once.

Therefore:

```perl
my $stream = $connection->open_bidi_stream;
```

can return `undef`.

That is normal flow control. It does not mean the Connection failed.

If the application needs to wait for more stream credit:

```perl
$connection->on_stream_available(sub {
    my ($connection, $type) = @_;

    return if $type ne 'bidi';

    my $stream = $connection->open_bidi_stream;
    return if !defined $stream;

    ...
});
```

`$type` is `bidi` or `uni`.

## Receiving peer streams

Streams opened by the peer are pulled from the Connection:

```perl
while (my $stream = $connection->next_stream) {
    ...
}
```

Read available bytes with:

```perl
while (defined(my $bytes = $stream->next_data)) {
    handle_bytes($bytes);
}
```

QUIC streams are byte streams, not message streams.

One call to:

```perl
$stream->send($message);
```

does not guarantee one matching `next_data` call on the peer.

If an application needs messages, it should put its own framing on the QUIC
stream.

## Stream completion and reset

A clean peer FIN is visible through:

```perl
if ($stream->remote_finished) {
    ...
}
```

A stream can be aborted with:

```perl
$stream->reset($application_error_code);
```

The local and remote reset codes are available separately:

```perl
my $local_code  = $stream->local_reset_code;
my $remote_code = $stream->remote_reset_code;
```

`closed` becomes true after ngtcp2 reports the stream completely closed.

A Stream object keeps its Connection alive. Final stream state and unread
buffered receive data remain available while the Stream object still exists.

## Closing a connection

Start a normal application close with:

```perl
$connection->close;
```

or:

```perl
$connection->close($application_error_code);
```

The default application error code is zero.

Closing is not immediate destruction. QUIC has a closing/draining period during
which late packets still need to be handled.

`closed` becomes true only after the Connection no longer needs network or
timer service.

## Connection errors and close information

Remote protocol errors, TLS failures, certificate failures, idle timeout, and
normal application close are connection outcomes rather than generic Perl
exceptions.

Inspect them with:

```perl
my $info = $connection->close_info;
```

It returns `undef` while no close or failure has been recorded.

A normal peer application close can look like:

```perl
{
    type      => 'application',
    initiator => 'peer',
    code      => 0,
}
```

Possible `type` values are:

```text
application
transport
tls
certificate
handshake
idle
drop
```

`initiator` is `local` or `peer`.

Local API misuse, invalid configuration, allocation failure, and internal
implementation failures still throw exceptions. Those are programming or
system failures rather than normal remote connection outcomes.

## TLS and certificate verification

QUIC always uses TLS 1.3.

Net::QUIC uses Picotls for QUIC TLS. Picotls uses OpenSSL underneath for
cryptography and certificate verification.

Clients verify server certificates by default.

`server_name` is used for DNS-name or IP-address verification:

```perl
my $driver = Net::QUIC::Driver->client(
    ...
    server_name => 'example.com',
);
```

OpenSSL's default trust locations are used.

For a private or test CA:

```perl
ca_file => '/path/to/private-ca.pem'
```

adds that PEM file to the trust store.

Net::QUIC does not provide an insecure skip-verification switch.

Server certificate and key files are loaded when the server Endpoint is
created. Accepted Connections reuse the shared server TLS credential context;
the files are not reopened for every Connection.

## Transport defaults

Client and server constructors accept an optional `transport` hash:

```perl
transport => {
    handshake_timeout => 10,
    idle_timeout      => 30,
    connection_window => 1024 * 1024,
    stream_window     => 256 * 1024,
    max_bidi_streams  => 100,
    max_uni_streams   => 100,
}
```

Those values are the Net::QUIC defaults.

Timeout values are seconds and may be fractional.

`idle_timeout => 0` disables the advertised idle timeout.

The receive windows are bytes. They are starting flow-control windows, not
lifetime transfer limits. Net::QUIC returns receive credit as application data
is consumed.

The stream counts are initial concurrent peer-stream limits. Stream credit is
returned as peer streams close.

Active connection migration is currently advertised as disabled.

ACK timing, congestion control, PMTU policy, packet-size shaping, and
connection-ID management remain Net::QUIC/ngtcp2 policy rather than public
constructor knobs.

## The lower-level Endpoint

Most event-loop adapters should use Driver.

`Net::QUIC::Endpoint` remains available when direct control is needed.

Its integration API is:

```perl
$endpoint->receive_datagram($bytes, $local, $peer);

while (my $datagram = $endpoint->next_datagram) {
    ...
}

my $seconds = $endpoint->timeout_after;

$endpoint->handle_timeout;
```

When using Endpoint directly, the caller is responsible for repeatedly
draining output and replacing the timer after every state change.

Driver exists specifically so ordinary adapters do not have to repeat those
rules.

## Native dependency

Net::QUIC requires Alien::ngtcp2 0.03 or newer.

Alien::ngtcp2 supplies the tested ngtcp2 and Picotls build.

Normal Net::QUIC applications do not choose a TLS backend.

## Scope

Net::QUIC is the transport layer.

HTTP/3 belongs in a separate distribution above it.

The first transport release does not need to include later QUIC features such
as:

```text
session resumption and 0-RTT
connection migration
QUIC DATAGRAM
qlog
ECN exposure
advanced congestion-control tuning
```

These can be added without changing the basic Driver, Connection, and Stream
model.

## Development

```text
perl Makefile.PL
make
make test
```

## License

Net::QUIC is MIT licensed.
