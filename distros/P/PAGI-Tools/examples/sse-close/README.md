# Explicit SSE close (`sse.close`)

Demonstrates ending a Server-Sent Events stream **explicitly** with
`$sse->close(reason => ...)` rather than by returning from the handler.

```
pagi-server --app examples/sse-close/app.pl --port 5000
# then open http://localhost:5000/
```

The page opens an `EventSource` to `/jobs`. The server streams four `progress`
events, then a `done` sentinel, then calls `close(reason => 'job_complete')`.

What it shows:

- **`close(reason => ...)`** ends the stream immediately (decoupled from
  returning) and runs `on_close`. The `reason` is **server-side only** — printed
  to STDERR (`SSE stream closed: reason=job_complete`) and **never sent to the
  client**, because SSE has no close frame on the wire.
- **Client-facing "why" is a normal event.** The browser can't observe the
  close reason, so the app sends a `done` sentinel event; the client listens for
  it and calls `es.close()` to suppress the automatic reconnect.
- **`on_close` runs however the stream ends** — our `close()` here, or a client
  disconnect — so cleanup lives in one place.

See `PAGI::Tools::Cookbook` ("Closing an SSE stream, and recording why") and
`PAGI::Spec::Www` ("Close SSE - send event").
