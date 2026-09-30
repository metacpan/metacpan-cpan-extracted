# Net::QUIC examples

These examples show how Net::QUIC fits into common Perl event systems.

The event-loop modules used here are optional example dependencies. Net::QUIC
does not require Linux::Event, AnyEvent, IO::Async, Mojolicious, or EV.

Install only the event system you want to try. For example:

```text
cpanm Linux::Event
cpanm AnyEvent
cpanm IO::Async
cpanm Future::AsyncAwait
cpanm Mojolicious
cpanm EV
```

The important part is that every event loop implements the same small
Net::QUIC::Driver contract:

```text
event loop -> Driver

UDP ready       -> start
UDP packet      -> receive
timer expired   -> timeout
UDP writable    -> writable

Driver -> event loop

UDP datagram    -> send callback
next deadline   -> set_timeout callback
```

The QUIC application code is otherwise the same.

## Files

```text
linux-event-client.pl
    Linux::Event client integration.

anyevent-client.pl
    AnyEvent client integration.

io-async-client.pl
    IO::Async client integration using callback APIs.

io-async-async-await-client.pl
    IO::Async transport integration with a Future::AsyncAwait application.

mojo-ioloop-client.pl
    Mojolicious / Mojo::IOLoop client integration.

ev-client.pl
    Direct EV client integration.

io-select-echo-server.pl
    Small echo server using core IO::Select. This is mainly a convenient
    local test target for the client examples.
```

The examples intentionally do not hide the Driver calls inside another
Net::QUIC wrapper. The point is to show exactly how little event-loop glue is
required.

## Running the local echo server

From a Net::QUIC source checkout:

```text
perl examples/io-select-echo-server.pl \
    127.0.0.1 \
    4433 \
    net-quic-example \
    t/data/server-cert.pem \
    t/data/server-key.pem
```

The test certificate is for `localhost`.

This simple server example intentionally requires a concrete bind address such
as `127.0.0.1`. It does not implement destination-address ancillary data for
a wildcard bind.

A production server may bind to `0.0.0.0` or `::`, but the UDP integration
must then recover the concrete destination address of each received packet and
pass that address as the Driver's `local` value. It must also preserve
`$datagram->local` as the source address for outbound packets.

On Linux, this is typically implemented with packet-info ancillary data and
`recvmsg` / `sendmsg`. The exact socket API is deliberately outside
Net::QUIC because the event loop owns UDP I/O.

## Running a client

Each client accepts the same arguments:

```text
HOST PORT ALPN SERVER_NAME CA_FILE MESSAGE
```

For example:

```text
perl examples/anyevent-client.pl \
    127.0.0.1 \
    4433 \
    net-quic-example \
    localhost \
    t/data/server-cert.pem \
    "hello from AnyEvent"
```

Equivalent commands can be used with:

```text
linux-event-client.pl
io-async-client.pl
io-async-async-await-client.pl
mojo-ioloop-client.pl
ev-client.pl
```

If `CA_FILE` is `-`, the client uses OpenSSL's normal system trust
locations instead of adding a private CA file.

## What the client examples do

Each client:

1. creates one connected UDP socket
2. gives its packed local and peer addresses to Net::QUIC::Driver
3. connects the event loop's readable, writable, and timer events to Driver
4. waits for the QUIC/TLS handshake
5. opens one bidirectional QUIC stream
6. sends the supplied message and FIN
7. prints the echoed bytes
8. performs a normal QUIC connection close

The UDP output adapters preserve whole-datagram backpressure semantics. If the
kernel cannot immediately accept a UDP packet, the adapter retains that packet,
reports backpressure to Driver, and later calls `writable` after the queue
drains.

## Linux::Event

The Linux::Event example is shorter because
`Linux::Event::IO::Sock::Dgram` already provides packet queues,
backpressure, `on_drain`, packed addresses, and timer integration.

## AnyEvent

The AnyEvent example uses an I/O watcher for UDP reads, a second watcher only
while UDP output is backpressured, and one replaceable timer watcher for QUIC.

Replacing the QUIC timer is simply a matter of dropping the previous timer
watcher and creating the new one requested by Driver.

## IO::Async

There are two IO::Async examples because they show two useful application
styles over the same Net::QUIC Driver contract.

`io-async-client.pl` keeps both the transport integration and application
logic callback-driven. It does not require Future::AsyncAwait.

`io-async-async-await-client.pl` keeps the same callback-driven UDP and timer
adapter, but turns QUIC state changes into IO::Async Futures. The application
side can then use Future::AsyncAwait:

```perl
async sub run_client {
    await wait_for_handshake();

    my $stream = await open_bidi_stream();

    $stream->send($message);
    $stream->finish;

    my $reply = await read_until_fin($stream);

    $connection->close;
    await wait_for_connection_close();

    return $reply;
}
```

This does not make Net::QUIC itself depend on Futures or async/await. It is
only an application-layer style built on top of the same Driver events.

Both examples map UDP readiness through `watch_io` and the QUIC deadline
through `watch_time` / `unwatch_time`.

## Mojo::IOLoop

The Mojolicious example uses `Mojo::IOLoop` and its reactor directly. The
reactor watches the UDP handle for reads, enables write readiness only during
backpressure, and `Mojo::IOLoop->timer` supplies the one-shot QUIC timer.

No Mojolicious web application or HTTP layer is involved.

## EV

The EV example maps the Driver contract directly onto `EV::io` and
`EV::timer` watchers.

Like the other raw-socket examples, it keeps one unsent UDP datagram queued
when the kernel would block and calls `writable` after write readiness returns.

## Server examples in applications

A real server normally uses the same event-loop UDP integration but constructs:

```perl
Net::QUIC::Driver->server(...)
```

instead of `client`.

The UDP receive and timer wiring does not change. New QUIC connections are
pulled with:

```perl
while (my $connection = $driver->next_connection) {
    ...
}
```

The `io-select-echo-server.pl` example shows that server-side Connection and
Stream handling in full.
