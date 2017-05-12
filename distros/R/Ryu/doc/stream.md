Names:

* Aliran
* Nagare
* Ryu

Concepts:

* Listen for connection, emit a TCP stream for each one
* Connect to TCP, generate two streams: one that emits bytes, one that receives

Streams are unidirectional. There's two streams for a TCP connection.

Ryu::Async::TCP::Client
Ryu::Async::TCP::Server
Ryu::Async::TCP

# Ryu::Source

A source emits a stream of events.

* Ryu::Source::Bytes
* Ryu::Source::Chars

A byte stream can be adapted to a char stream.

```perl
my $cs = Ryu::Source::Chars->from($bs, as => 'UTF-8');
```

Byte streams are intended for dealing with protocols.

```perl
$src->packed(C1 => sub {
 my ($type) = @_;
});
```

There's also some common stream facilities:

```perl
$src->gather(4 => sub {
 my $items = shift; # arrayref
});
```

# Ryu::Sink

Sinks receive events.

* Ryu::Sink::Bytes

Each stream has related streams.

Iterating via ->each:

```perl
 $thing->each(sub { $ui->notify($_) })->on_ready(sub { $ui->notify_done })
```

Attaching the stream:

```perl
 $thing->notify($ui)
```

Components:

* Next item - the most important part is usually the items that we're trying to deliver
* Finished - inform things when we're not going to see any more results. This always happens, and it happens after everything else
* Completed - we finished with no problems
* Cancelled - we were asked to cancel before we finished
* Failed - something went wrong so we stopped early
* Progress - we're still active, it's unlikely anything's wrong, and progress is being made, but we don't have a new item yet

UI elements will typically attach their own listeners for all the components.
Plain processing may only want ->next and ->done.


