---
title: The live tier
order: 2
---

# The live tier

A WebSocket route is declared like any other route, because it is one:

```perl
websocket '/ws/:room' => 'WS::Chat#join_room', {
    protocols        => [ 'punk.chat.v1' ],
    max_message_size => 65_536,
};
```

## Why it routes like a GET

An upgrade request *is* a GET, so the route sits in the same router as
everything else and under the same scopes and guards. A guard can therefore
reject a client with an ordinary HTTP response before the handshake happens,
which is the only point at which refusing is cheap.

## The handler

Once Punk has validated and answered the handshake, the handler is called with
the context and the connection:

```perl
sub join_room {
    my ($c, $ws) = @_;
    my $room = Chat::Bus->room($c->param('room'));
    $room->add($ws);
    $ws->on(message => sub {
        my ($conn, $text) = @_;
        $room->broadcast($text);
    });
}
```

It wires the events it wants and returns. The connection then lives on the
server's event loop rather than in the handler's stack frame, so a worker is
not pinned per connection.

## Broadcasting

`Chat::Bus` keeps one `Punk::WebSocket::Room` per room name. Anything that can
reach the bus can broadcast, which is how a message arriving through the API
reaches open browser tabs. See [the API tier](/guide/api).

## The browser side

`root/static/chat.js` is a plain `WebSocket` client with no framework. It
offers the `punk.chat.v1` subprotocol, which the route requires, so a client
that offers none of the protocols listed is refused at the handshake.
