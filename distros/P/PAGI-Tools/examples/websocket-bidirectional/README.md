# websocket-bidirectional — full-duplex WebSocket with PAGI::Context

Send **and** receive at the same time. After accepting, the handler runs two
concurrent branches on one connection:

- **incoming** — echo each client message back, uppercased.
- **outgoing** — push an unsolicited server `tick` every second.

You see the server's ticks interleaved with echoes of whatever you type — both
directions live at once.

This is the same demo as the raw-protocol
[`examples/18-bidirectional-websocket`](../../../PAGI/examples/18-bidirectional-websocket)
in the `PAGI` distribution, rewritten with **`PAGI::Context`** to show how much it
folds away.

## What PAGI::Context gives you here

One object (`$ctx`) wraps `$scope`/`$receive`/`$send` and hands you exactly the
pieces a bidirectional handler needs:

| `PAGI::Context` | does |
|---|---|
| `$ctx->each_text(sub {...})` | the **receive-loop**, returned as a Future that completes when the client disconnects — no manual `websocket.connect`/`receive`/`disconnect` handling |
| `$ctx->send_text_if_connected(...)` | a send that becomes a **no-op once the socket is closing**, so the concurrent send-loop never races the teardown (no `eval`, no guards) |
| `$ctx->is_connected` | a clean loop guard |
| `$ctx->accept` | the handshake |

Compare with the raw version, which spells out the `websocket.connect` →
`websocket.accept` handshake, the `websocket.receive`/`websocket.disconnect`
dispatch, and its own helper to race without cancelling `$receive`.

The two branches are joined with `Future->wait_any`: a client disconnect ends
`incoming`, and `wait_any` then cancels the idle `outgoing` tick-loop. (That
cancel is the right call here because the losers are *our own branches* — unlike
a receive-multiplex, where the raced future is the live `$receive` that must not
be cancelled.)

## Run

```bash
pagi-server --app examples/websocket-bidirectional/app.pl --port 5000
```

From an uninstalled checkout, add the dist libs:

```bash
perl -I /path/to/PAGI-Server/lib -I /path/to/PAGI-Tools/lib \
  /path/to/PAGI-Server/bin/pagi-server \
  --app examples/websocket-bidirectional/app.pl --port 5000
```

## Test

Use a **WebSocket-aware** client — not `curl` or `socat`, which can't do the
WebSocket `Upgrade` handshake or frame masking. With
[`websocat`](https://github.com/vi/websocat):

```bash
websocat ws://localhost:5000/
# server tick #1          <- arrives on its own every second
hello                     <- you type this
you said: HELLO           <- echoed back, uppercased
# server tick #2
```

...or a browser console, nothing to install:

```js
let ws = new WebSocket('ws://localhost:5000/');
ws.onmessage = e => console.log(e.data);
ws.onopen    = () => ws.send('hello');
```

The `tick` lines keep arriving whether or not you type — that's the outgoing
branch running concurrently with the incoming one.
