# SSE Dashboard Example

Live dashboard using PAGI::SSE for real-time metrics streaming.

## Run

```bash
pagi-server --app examples/sse-dashboard/app.pl --port 5000
```

Visit http://localhost:5000/

## Features

- Real-time server metrics streaming
- Automatic keepalive for proxy compatibility
- Reconnection support via `Last-Event-ID`
- Multiple event types (`connected`, `reconnected`, `metrics`)
- Subscriber tracking

## API

- `SSE /events` - Metrics stream (2-second updates)
- `GET /*` - Static files from `public/`

## Key Concepts

```perl
# Keepalive for proxies
$sse->keepalive(25);

# Handle reconnection
if (my $last_id = $sse->last_event_id) {
    await $sse->send_event(event => 'reconnected', ...);
}

# Cleanup on disconnect
$sse->on_close(sub { ... });

# Wait for disconnect
await $sse->run;
```
