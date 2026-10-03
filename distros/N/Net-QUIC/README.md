# Net::QUIC

[![CPAN version](https://badge.fury.io/pl/Net-QUIC.svg)](https://metacpan.org/dist/Net-QUIC)
[![CPANTS Kwalitee](https://cpants.cpanauthors.org/dist/Net-QUIC.svg)](https://cpants.cpanauthors.org/dist/Net-QUIC)
[![CI](https://github.com/haxmeister/perl-Net-QUIC/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/haxmeister/perl-Net-QUIC/actions/workflows/test.yml)
[![License](https://img.shields.io/cpan/l/Net-QUIC.svg)](https://github.com/haxmeister/perl-Net-QUIC/blob/main/LICENSE)
[![Perl](https://img.shields.io/badge/perl-5.20%2B-blue.svg)](https://www.perl.org/)
[![ngtcp2](https://img.shields.io/badge/ngtcp2-1.25.0-blue.svg)](https://github.com/ngtcp2/ngtcp2)
[![QUIC](https://img.shields.io/badge/QUIC-v1%20%2B%20v2-blue.svg)](https://www.rfc-editor.org/rfc/rfc9000)


Net::QUIC is a QUIC transport library for Perl.

QUIC is a secure network transport built on UDP. A QUIC connection can carry
many independent byte streams at the same time.

If you are new to QUIC, the useful mental model is:

```text
one QUIC connection
    |
    +-- stream
    +-- stream
    +-- stream
```

Each stream is a reliable ordered sequence of bytes.

Net::QUIC handles the difficult transport work:

- QUIC packets and connection state
- TLS 1.3 encryption
- certificate verification
- streams and flow control
- retransmission and loss recovery
- connection IDs
- timers
- migration between network paths
- QUIC v1 and QUIC v2

Your event loop still owns the UDP socket.

You do not need to know ngtcp2 to use Net::QUIC. It is an internal native
dependency.

Net::QUIC is not HTTP/3 and is not a web framework. It gives applications
connections and byte streams. Your application decides what the bytes mean.

## Installation

From CPAN:

```text
cpanm Net::QUIC
```

Net::QUIC uses `Alien::ngtcp2` to provide its native dependencies. A normal
installation does not require you to find or configure ngtcp2 yourself.

The event-loop modules used in `examples/` are optional. Net::QUIC itself
does not require Linux::Event, AnyEvent, IO::Async, Mojolicious, or EV.

## Start here

Most application code only needs three classes:

```text
Net::QUIC::Driver
        |
        +-- Net::QUIC::Connection
                    |
                    +-- Net::QUIC::Stream
```

Use:

- `Net::QUIC::Driver` to connect Net::QUIC to UDP and a timer
- `Net::QUIC::Connection` to represent one QUIC connection
- `Net::QUIC::Stream` to send and receive application bytes

There is also a lower-level `Net::QUIC::Endpoint`. Most applications should
use Driver instead.

## What application code looks like

Once a connection is ready, application code is simple.

Open a stream:

```perl
my $stream = $connection->open_bidi_stream;

if ($stream) {
    $stream->send("hello\n");
    $stream->finish;
}
```

Accept streams opened by the peer:

```perl
while (my $stream = $connection->next_stream) {
    while (defined(my $bytes = $stream->next_data)) {
        handle_bytes($bytes);
    }
}
```

Close the connection:

```perl
$connection->close;
```

The UDP socket and QUIC timer normally stay in your event-loop adapter rather
than in the application protocol code.

## QUIC streams are byte streams

A QUIC stream is an ordered sequence of bytes.

It is not a sequence of messages.

This:

```perl
$stream->send("one");
$stream->send("two");
```

does not guarantee that the peer receives exactly two `next_data` results.

If your application needs messages, add its own framing. For example, it could
use newline-delimited messages, fixed-size records, or a length prefix.

QUIC gives each stream its own ordering and flow control. A blocked or lost
packet on one stream does not turn all other streams into one shared byte
stream.

## Bidirectional and unidirectional streams

A bidirectional stream allows both endpoints to send:

```perl
my $stream = $connection->open_bidi_stream;
```

A unidirectional stream allows only the endpoint that created it to send:

```perl
my $stream = $connection->open_uni_stream;
```

A stream can also tell you what this endpoint is allowed to do:

```perl
$stream->can_send;
$stream->can_receive;
```

## Waiting for the connection

A new QUIC connection performs a TLS handshake before normal application work
begins.

Check:

```perl
if ($connection->ready) {
    ...
}
```

A server can receive a new Connection object before its handshake has
completed. This is normal.

## A client

A client Driver needs:

- `local` - the packed local UDP socket address
- `peer` - the packed server UDP address
- `alpn` - the name of the application protocol carried over QUIC
- `server_name` - the name expected in the server certificate
- `send` - a callback that transmits one UDP datagram
- `set_timeout` - a callback that replaces the QUIC timer

For example:

```perl
use Net::QUIC::Driver;

my $driver = Net::QUIC::Driver->client(
    local       => $packed_local_address,
    peer        => $packed_peer_address,
    alpn        => 'my-protocol',
    server_name => 'example.com',

    send => sub {
        my ($datagram) = @_;
        send_udp($datagram);
        return 1;
    },

    set_timeout => sub {
        my ($seconds) = @_;
        replace_timer($seconds);
    },
);

my $connection = $driver->connection;

$driver->start;
```

`start` tells Driver that the UDP transport is ready. The client can then
produce its first QUIC packet.

### What is ALPN?

ALPN is simply a short protocol name agreed on by the client and server.

For a custom protocol you might use:

```perl
alpn => 'my-protocol'
```

It prevents two unrelated protocols from accidentally using the same QUIC
connection.

### What is server_name?

`server_name` is the DNS name or IP address that the server certificate must
represent.

For example, the UDP peer can be a numeric address:

```text
192.0.2.20:4433
```

while certificate verification uses:

```perl
server_name => 'service.example.com'
```

## A server

A server Driver uses the same UDP/timer contract:

```perl
my $driver = Net::QUIC::Driver->server(
    alpn             => 'my-protocol',
    certificate_file => 'server-cert.pem',
    private_key_file => 'server-key.pem',

    send => sub {
        my ($datagram) = @_;
        send_udp($datagram);
        return 1;
    },

    set_timeout => sub {
        my ($seconds) = @_;
        replace_timer($seconds);
    },
);

$driver->start;
```

Feed received UDP packets into Driver:

```perl
$driver->receive($bytes, $local, $peer);
```

Pull newly created connections with:

```perl
while (my $connection = $driver->next_connection) {
    ...
}
```

One server Driver can manage many QUIC connections on one UDP socket.

## The event-loop contract

Net::QUIC deliberately does not choose an event loop.

The event loop owns:

- UDP I/O
- one replaceable one-shot timer

Driver needs two callbacks from the adapter:

```perl
send => sub {
    my ($datagram) = @_;

    # Send one complete UDP datagram.
    #
    # Return true if another datagram can be accepted immediately.
    # Return false if this datagram was accepted but output is now blocked.
},

set_timeout => sub {
    my ($seconds) = @_;

    # Replace the current one-shot QUIC timer.
    # undef means cancel it.
},
```

The event loop reports four events to Driver:

```perl
$driver->start;
$driver->receive($bytes, $local, $peer);
$driver->timeout;
$driver->writable;
```

That is the normal Driver contract.

There is no application-visible QUIC pump loop.

Driver automatically drains pending QUIC output, updates the timer, pauses for
UDP backpressure, and resumes after `writable`.

Application operations such as:

```perl
$stream->send(...);
$stream->finish;
$stream->reset(...);
$connection->close;
```

also notify Driver automatically when transport work is needed.

## Net::QUIC::Datagram

The `send` callback receives a `Net::QUIC::Datagram`.

Useful fields are:

```perl
$datagram->data;   # complete UDP payload
$datagram->local;  # packed local source address
$datagram->peer;   # packed destination address
$datagram->ecn;    # ECN codepoint for the IP header
```

Do not split `data`. It is one complete UDP datagram.

For the common case of a socket bound to one concrete local address, the socket
already supplies the correct source address.

The `local` value becomes especially important for wildcard sockets and
connection migration.

## Local addresses

QUIC needs to know the actual network path used by each packet.

The `local` value passed to Net::QUIC must therefore be a concrete IPv4 or
IPv6 address.

These are wildcard bind addresses, not concrete QUIC paths:

```text
0.0.0.0
::
```

A client normally avoids this problem by connecting its UDP socket and using
`getsockname` after the kernel chooses a local address.

A server can still bind to a wildcard address, but its adapter must discover
the actual destination address of each received packet and pass that concrete
address to:

```perl
$driver->receive($bytes, $local, $peer);
```

On Linux this is commonly done with packet-info ancillary data and
`recvmsg` / `sendmsg`.

If an event system cannot report the actual destination address, bind the QUIC
socket to one concrete local address instead.

## UDP backpressure

A UDP send can temporarily be unable to accept another packet.

The Driver `send` callback uses its return value to report that condition:

- true - another datagram can be accepted immediately
- false - this datagram was accepted, but stop sending more for now

When output becomes writable again, call:

```perl
$driver->writable;
```

Driver then continues where it stopped.

## TLS and certificate verification

QUIC always uses TLS 1.3.

Clients verify server certificates by default.

`server_name` is the name checked against the certificate:

```perl
server_name => 'example.com'
```

OpenSSL's normal trust locations are used.

For a private or test CA:

```perl
ca_file => '/path/to/private-ca.pem'
```

adds that PEM file to the trust store.

Net::QUIC does not provide an insecure "skip certificate verification" switch.

Server certificate and key files are loaded when the server is created and
shared by connections accepted by that server.

## Closing streams

A normal stream finish is:

```perl
$stream->finish;
```

This means "I am done sending after the bytes already queued."

On a bidirectional stream, the peer can still send data back.

Abort this endpoint's send side:

```perl
$stream->reset($application_error_code);
```

Stop receiving and ask the peer to stop its send side:

```perl
$stream->stop_sending($application_error_code);
```

The send and receive directions are independent.

For normal code, `finish` is usually what you want. `reset` and
`stop_sending` are abrupt error/abort operations.

## Stream limits

QUIC limits how many streams can be open at once.

Therefore:

```perl
my $stream = $connection->open_bidi_stream;
```

can return `undef`.

That does not mean the connection failed. It means the peer has not currently
given this endpoint permission to open another stream.

To wait for more stream credit:

```perl
$connection->on_stream_available(sub {
    my ($connection, $type) = @_;

    return if $type ne 'bidi';

    my $stream = $connection->open_bidi_stream;
    return if !defined $stream;

    ...
});
```

## Advanced protocol-engine integration

Ordinary applications do not need these APIs.

A protocol engine that needs tighter control over receive consumption,
acknowledgement progress, Stream wake-ups, or transmit memory can use:

```text
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
```

The ordinary `send`, `finish`, and `next_data` API remains unchanged.

These are transport primitives only. Net::QUIC does not add HTTP/3 or other
application-protocol semantics.

See the `Net::QUIC::Connection` and `Net::QUIC::Stream` POD for the exact
contracts.

## Closing a connection

Start a normal application close with:

```perl
$connection->close;
```

or:

```perl
$connection->close($application_error_code);
```

QUIC does not destroy the connection immediately. It has a short
closing/draining period so late packets can still be handled correctly.

`$connection->closed` becomes true when the connection no longer needs UDP or
timer service.

## Connection errors

Remote errors and normal close conditions are stored on the Connection rather
than thrown as ordinary Perl exceptions.

Inspect them with:

```perl
my $info = $connection->close_info;
```

For example:

```perl
{
    type      => 'application',
    initiator => 'peer',
    code      => 0,
}
```

Possible `type` values include:

```text
application
transport
tls
certificate
handshake
idle
drop
```

Programming mistakes, invalid local configuration, allocation failures, and
internal failures still throw Perl exceptions.

## QUIC v1 and v2

Net::QUIC supports QUIC v1 and QUIC v2.

Clients use v1 by default:

```perl
version => 1
```

To start directly with v2:

```perl
version => 2
```

A server can prefer v2:

```perl
preferred_version => 2
```

while still accepting compatible v1 clients.

Normally you do not need to care which version was used.

For diagnostics:

```perl
$connection->client_chosen_version;
$connection->version;
```

## Session resumption

A completed client connection can receive an opaque TLS session ticket:

```perl
my $ticket = $connection->session_ticket;
```

A later connection can offer it:

```perl
session_ticket => $ticket
```

After the handshake:

```perl
if ($connection->resumed) {
    ...
}
```

reports whether TLS actually resumed the old session.

Treat the ticket as opaque bytes. Net::QUIC remembers the QUIC version inside
the opaque value.

If the ticket is expired or no longer valid, the connection falls back to a
normal full handshake.

## 0-RTT / early data

0-RTT lets a returning client send some application data before the new
handshake has completed.

It is optional because early data can be replayed by the network.

Only use 0-RTT for operations that are safe to repeat.

Save the opaque state:

```perl
my $state = $connection->early_data_state;
```

Use it on a later client:

```perl
early_data => $state
```

The server must also allow it:

```perl
accept_early_data => 1
```

Check what happened:

```perl
$connection->early_data_status;
```

Possible values are:

```text
none
pending
accepted
rejected
```

If early data is rejected, the ordinary handshake can still succeed. Open new
streams after the connection becomes ready and resend only operations that are
safe to repeat.

On a server, a received stream can be checked with:

```perl
$stream->early_data;
```

## Retry and NEW_TOKEN

A server can require clients to prove that they can receive packets at their
source address before it allocates full connection state:

```perl
validate_address => 1
```

A new client may then receive a QUIC Retry packet and repeat its Initial.

After a validated connection succeeds, the server can give the client a
NEW_TOKEN.

The client exposes that opaque token as:

```perl
my $token = $connection->address_token;
```

A later connection can reuse it:

```perl
address_token => $token
```

A valid token can avoid another Retry round trip.

Most applications can simply cache this opaque value alongside the session
ticket if they want faster returning connections.

## Network migration

QUIC can keep a connection alive when the client's local network path changes.

For example, an application can move an established connection to another
local address:

```perl
$connection->migrate($new_packed_local_address);
```

Net::QUIC tests the new path before switching to it.

Check progress with:

```perl
$connection->path_validation_status;
```

Possible values are:

```text
none
validating
succeeded
failed
aborted
```

If validation fails, the old working path remains active.

The current path is available from:

```perl
my $path = $connection->path;
```

## Preferred server address

A server can tell the client that another server address is preferred:

```perl
preferred_address => $packed_server_address
```

The client tests that path before switching.

The UDP adapter must actually be able to send and receive on the advertised
address.

## PMTU discovery

Different network paths can safely carry different UDP packet sizes.

Net::QUIC automatically discovers a useful packet size for the current path.

For diagnostics:

```perl
my $bytes = $connection->path_max_udp_payload_size;
```

A new path starts at QUIC's safe 1200-byte baseline. Discovery can raise that
value when larger packets work.

Most applications do not need to manage this themselves.

## ECN

ECN is an IP feature that can report congestion without requiring a packet to
be dropped.

ECN support is optional at the adapter boundary.

An ECN-aware adapter can pass the two-bit codepoint from the received IP packet:

```perl
$driver->receive($bytes, $local, $peer, $ecn);
```

For outgoing traffic it applies:

```perl
$datagram->ecn;
```

to the IP header.

The wire values are:

```text
0   Not-ECT
1   ECT(1)
2   ECT(0)
3   CE
```

If the adapter does not provide ECN metadata, the normal three-argument
`receive` form remains valid.

Net::QUIC tests whether ECN works correctly on the path and automatically
stops using it when necessary.

## Lower-level Endpoint API

`Net::QUIC::Endpoint` is the engine underneath Driver.

It exposes:

```text
receive_datagram
next_datagram
timeout_after
handle_timeout
```

Use Endpoint directly only when you want to own output draining,
backpressure handling, and timer replacement yourself.

Most event-loop integrations are simpler with Driver.

## Examples

The `examples/` directory contains complete integrations for:

- Linux::Event
- AnyEvent
- IO::Async
- IO::Async with Future::AsyncAwait
- Mojo::IOLoop
- EV
- a small IO::Select echo server

All client examples implement the same Driver contract.

See `examples/README.md` for commands and notes.

## What is not part of Net::QUIC

Net::QUIC is the base QUIC transport.

It does not define:

- HTTP/3
- an RPC protocol
- an application message format
- a web framework

QUIC DATAGRAM is a separate optional QUIC extension and is not required for the
base transport implemented here.

qlog and advanced congestion-control configuration are also separate tooling or
advanced configuration work.

## Native implementation

Net::QUIC uses ngtcp2 for the native QUIC transport and Picotls/OpenSSL for
QUIC TLS.

Most application code does not need to know those APIs.

The important public boundary remains:

```text
event loop / UDP
        |
        v
Net::QUIC::Driver
        |
        v
Net::QUIC::Connection
        |
        v
Net::QUIC::Stream
```

## License

MIT
