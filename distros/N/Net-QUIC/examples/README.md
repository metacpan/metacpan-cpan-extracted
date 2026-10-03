# Net::QUIC examples

These examples show how to connect Net::QUIC to common Perl event loops.

You do not need to understand ngtcp2 to follow them.

Every example does the same basic job:

1. create a UDP socket
2. create a `Net::QUIC::Driver`
3. connect UDP reads, writes, and one timer to Driver
4. wait for the QUIC handshake
5. open a Stream
6. send a message
7. read the echoed reply
8. close the Connection

Only the event-loop glue changes.

## Optional dependencies

Net::QUIC itself does not require these event-loop modules.

Install only the one you want to try:

```text
cpanm Linux::Event
cpanm AnyEvent
cpanm IO::Async
cpanm Future::AsyncAwait
cpanm Mojolicious
cpanm EV
```

## The Driver contract

All examples implement the same small contract.

The event loop reports events to Driver:

```text
UDP transport ready   -> start
UDP packet arrived    -> receive
timer fired           -> timeout
UDP writable again    -> writable
```

Driver asks the event loop to do two things:

```text
send one UDP packet   -> send callback
replace the timer     -> set_timeout callback
```

That is the part worth comparing between examples.

The application-side Connection and Stream code is almost the same in every
case.

## Example files

```text
linux-event-client.pl
    Linux::Event client.

anyevent-client.pl
    AnyEvent client.

io-async-client.pl
    IO::Async client using callbacks.

io-async-async-await-client.pl
    IO::Async transport with a Future::AsyncAwait application.

mojo-ioloop-client.pl
    Mojo::IOLoop client.

ev-client.pl
    Direct EV client.

io-select-echo-server.pl
    Small echo server using core IO::Select.
```

The examples intentionally show the Driver calls instead of hiding them behind
another wrapper.

## Start the local echo server

From a Net::QUIC source checkout:

```text
perl examples/io-select-echo-server.pl \
    127.0.0.1 \
    4433 \
    net-quic-example \
    t/data/server-cert.pem \
    t/data/server-key.pem
```

The included test certificate is for `localhost`.

The example server deliberately binds to one concrete address,
`127.0.0.1`.

That keeps the example small.

A production server can bind to `0.0.0.0` or `::`, but then the UDP adapter
must discover the actual local destination address of every packet and pass it
to Net::QUIC.

On Linux this is commonly done with packet information and
`recvmsg` / `sendmsg`.

If that sounds unfamiliar, ignore it for the first example and use the concrete
`127.0.0.1` address shown above.

## Run a client

Every client accepts:

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

Use the same arguments with:

```text
linux-event-client.pl
io-async-client.pl
io-async-async-await-client.pl
mojo-ioloop-client.pl
ev-client.pl
```

If `CA_FILE` is `-`, the client uses OpenSSL's normal system trust
locations instead of adding the supplied test CA file.

## What the clients do

Each client follows the same sequence.

First it creates a connected UDP socket and asks the kernel for the actual local
address.

Then it creates Driver:

```perl
my $driver = Net::QUIC::Driver->client(
    local       => $local,
    peer        => $peer,
    alpn        => $alpn,
    server_name => $server_name,
    send        => sub { ... },
    set_timeout => sub { ... },
);
```

When UDP is ready:

```perl
$driver->start;
```

When a packet arrives:

```perl
$driver->receive($bytes, $local, $peer);
```

When Driver's requested timer fires:

```perl
$driver->timeout;
```

If UDP output temporarily becomes blocked and later becomes writable:

```perl
$driver->writable;
```

Application code waits for:

```perl
$connection->ready
```

and then uses ordinary Stream methods.

## UDP backpressure

Sometimes the operating system cannot immediately accept another UDP packet.

The examples keep the unsent packet queued and tell Driver to stop producing
more output for the moment.

When the socket becomes writable again, they call:

```perl
$driver->writable;
```

This is what the Driver documentation calls backpressure.

## ECN

The small examples use ordinary `recv` and `send`.

They intentionally do not demonstrate ECN ancillary-data handling.

That is still a valid Net::QUIC integration.

An ECN-aware production adapter can use the event loop or platform equivalent
of `recvmsg` / `sendmsg` to:

- read the two ECN bits from the received IP packet and pass them as the
  optional fourth argument to `$driver->receive(...)`
- apply `$datagram->ecn` to the outgoing IP header

If the adapter does not provide ECN metadata, QUIC simply stops using ECN on
that path.

## Linux::Event

The Linux::Event example is shorter because
`Linux::Event::IO::Sock::Dgram` already provides useful UDP queueing,
backpressure, packed addresses, and timer integration.

## AnyEvent

The AnyEvent example uses:

- one watcher for UDP reads
- a write watcher only while output is blocked
- one replaceable timer watcher

## IO::Async

There are two IO::Async examples.

`io-async-client.pl` uses callbacks for both the transport and application
logic.

`io-async-async-await-client.pl` uses the same callback-driven UDP adapter but
uses Future::AsyncAwait for the application flow.

That means async/await is optional application style, not a Net::QUIC
requirement.

## Mojo::IOLoop

The Mojo example uses `Mojo::IOLoop` and its reactor directly.

No Mojolicious web application or HTTP layer is involved.

## EV

The EV example maps Driver directly to `EV::io` and `EV::timer` watchers.

## Server-side application code

A real server uses the same UDP/timer idea but constructs:

```perl
Net::QUIC::Driver->server(...)
```

instead of `client`.

New QUIC Connections are pulled with:

```perl
while (my $connection = $driver->next_connection) {
    ...
}
```

The IO::Select echo server shows complete server-side Connection and Stream
handling.

## What to read next

For ordinary applications:

1. read the top-level `README.md`
2. read `Net::QUIC::Driver`
3. read `Net::QUIC::Connection`
4. read `Net::QUIC::Stream`

Read `Net::QUIC::Endpoint` only if you deliberately want the lower-level
manual service-loop API.
