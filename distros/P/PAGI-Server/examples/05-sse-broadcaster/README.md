# 05 – SSE Broadcaster

Streams `text/event-stream` data by emitting:
- `sse.start` (replaces `http.response.start` for SSE).
- Multiple `sse.send` events with UTF-8 text payloads.
- Stops early if `sse.disconnect` arrives.

## Quick Start

**1. Start the server:**

```bash
pagi-server --app examples/05-sse-broadcaster/app.pl --port 5000
```

**2. Demo with curl:**

```bash
# Subscribe to SSE stream (one event per second)
curl -N -v -H "Accept: text/event-stream" http://localhost:5000/
# => event: tick
# => data: 1
# =>
# => event: tick
# => data: 2
# =>
# => event: done
# => data: finished

# Press Ctrl+C to disconnect early
```

**3. Or use JavaScript in browser console:**

```javascript
const es = new EventSource('http://localhost:5000/');
es.addEventListener('tick', (e) => console.log('Tick:', e.data));
es.addEventListener('done', (e) => { console.log('Done:', e.data); es.close(); });
es.onerror = () => console.log('Connection lost');
```

## Spec References

Covered by the PAGI specification in the upstream PAGI distribution
(`PAGI::Spec` POD and protocol documents, https://github.com/jjn1056/pagi):

- SSE scope/events
