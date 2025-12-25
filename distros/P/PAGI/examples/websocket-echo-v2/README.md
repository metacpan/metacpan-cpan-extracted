# WebSocket Echo (v2)

Clean WebSocket echo server using PAGI::WebSocket.

Compare with `examples/04-websocket-echo/` which uses the raw PAGI protocol.

## Run

```bash
pagi-server --app examples/websocket-echo-v2/app.pl --port 5000
```

Test with:
```bash
websocat ws://localhost:5000/
```

## Code

```perl
my $ws = PAGI::WebSocket->new($scope, $receive, $send);
await $ws->accept;

$ws->on_close(sub {
    my ($code) = @_;
    print "Client disconnected: $code\n";
});

await $ws->each_text(async sub {
    my ($text) = @_;
    await $ws->send_text("echo: $text");
});
```

## vs Raw Protocol

| PAGI::WebSocket | Raw Protocol |
|-----------------|--------------|
| `await $ws->accept` | Manual handshake events |
| `$ws->each_text(...)` | Manual event loop |
| `$ws->send_text(...)` | Build event hashref |
| `$ws->on_close(...)` | Check disconnect events |
