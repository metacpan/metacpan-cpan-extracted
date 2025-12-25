# WebSocket Chat v2 - Using PAGI::WebSocket

This is a port of `examples/10-chat-showcase` that demonstrates how
`PAGI::WebSocket` simplifies WebSocket handling.

## Running

```bash
pagi-server --app examples/websocket-chat-v2/app.pl --port 5000
```

Then open http://localhost:5000 in your browser.

## Comparison

The HTTP, SSE, and State modules are **identical** to the original.
Only the WebSocket handler is rewritten.

### Original (raw protocol)

```perl
# Wait for connection event
my $event = await $receive->();
return unless $event->{type} eq 'websocket.connect';

await $send->({ type => 'websocket.accept' });

# Message loop
while (1) {
    my $event = await $receive->();

    if ($event->{type} eq 'websocket.receive') {
        my $msg = decode_json($event->{text});
        # handle message...
    }
    elsif ($event->{type} eq 'websocket.disconnect') {
        last;
    }
}

# Manual cleanup
set_session_disconnected($session_id, $broadcast_leave);
```

### With PAGI::WebSocket

```perl
my $ws = PAGI::WebSocket->new($scope, $receive, $send);

await $ws->accept;

$ws->on_close(sub {
    my ($code, $reason) = @_;
    set_session_disconnected($session_id, $broadcast_leave);
});

await $ws->each_json(async sub {
    my ($msg) = @_;
    # handle message...
});
```

## Key Improvements

| Feature | Raw Protocol | PAGI::WebSocket |
|---------|--------------|-----------------|
| Accept connection | Wait for `websocket.connect`, send `websocket.accept` | `$ws->accept` |
| Handle disconnect | Check for `websocket.disconnect` in loop | `$ws->on_close` callback |
| JSON messages | Manual `encode_json`/`decode_json` | `$ws->send_json`, `$ws->each_json` |
| Safe send | Try/catch around send | `$ws->try_send_json` returns false |

## Files

- `app.pl` - Main application with routing
- `lib/ChatApp/WebSocket.pm` - **PAGI::WebSocket version** (compare with original)
- `lib/ChatApp/HTTP.pm` - Same as original
- `lib/ChatApp/SSE.pm` - Same as original
- `lib/ChatApp/State.pm` - Same as original
- `public/` - Symlink to original frontend
