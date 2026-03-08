# Net::Async::NATS

Async [NATS](https://nats.io) messaging client for [IO::Async](https://metacpan.org/pod/IO::Async).

## Synopsis

```perl
use IO::Async::Loop;
use Net::Async::NATS;

my $loop = IO::Async::Loop->new;
my $nats = Net::Async::NATS->new(
    host => 'localhost',
    port => 4222,
);
$loop->add($nats);

await $nats->connect;

# Subscribe
my $sub = await $nats->subscribe('greet.*', sub {
    my ($subject, $payload, $reply_to) = @_;
    print "Got: $payload on $subject\n";
});

# Publish
await $nats->publish('greet.world', 'Hello!');

# Request/Reply
my ($payload) = await $nats->request('service.echo', 'ping', timeout => 5);

# Unsubscribe
await $nats->unsubscribe($sub);

# Disconnect
await $nats->disconnect;
```

## Features

- Publish/Subscribe messaging
- Request/Reply with auto-generated inbox subjects
- Wildcard subscriptions (`*` and `>`)
- Queue group subscriptions
- Automatic PING/PONG keepalive handling
- Reconnect with subscription replay
- Server INFO processing and cluster URL discovery

## Installation

```bash
cpanm Net::Async::NATS
```

Or from source:

```bash
cpanm --installdeps .
dzil install
```

## Testing

Unit tests (no NATS server required):

```bash
prove -l t/
```

Live integration tests (requires a running NATS server):

```bash
TEST_NATS_HOST=localhost prove -lv t/03-live.t
```

## See Also

- [NATS.io](https://nats.io) — NATS messaging system
- [NATS wire protocol](https://docs.nats.io/reference/reference-protocols/nats-protocol)
- [IO::Async](https://metacpan.org/pod/IO::Async) — Async framework
- [Net::Async::NATS on CPAN](https://metacpan.org/pod/Net::Async::NATS)

## Author

Torsten Raudssus <torsten@raudssus.de>

## License

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
