# 04 – WebSocket Echo

Handles the WebSocket protocol:
1. Waits for `websocket.connect`.
2. Sends `websocket.accept` to complete the handshake.
3. Echoes incoming frames back via `websocket.send` — text frames are echoed with an `echo: ` prefix, binary frames are echoed unchanged.
4. Skips any `websocket.receive` frame that carries neither `text` nor `bytes`, and stops the loop only when `websocket.disconnect` arrives.

## Quick Start

**1. Start the server:**

```bash
pagi-server --app examples/04-websocket-echo/app.pl --port 5000
```

**2. Demo with websocat:**

```bash
# Install websocat if needed
brew install websocat        # macOS
# or: cargo install websocat  # with Rust

# Connect and send messages
websocat ws://localhost:5000/
# Type: Hello
# => echo: Hello
# Type: PAGI WebSocket!
# => echo: PAGI WebSocket!
```

**3. Or use JavaScript in browser console:**

```javascript
const ws = new WebSocket('ws://localhost:5000/');
ws.onmessage = (e) => console.log('Received:', e.data);
ws.onopen = () => ws.send('Hello from browser!');
```

## Spec References

Covered by the PAGI specification in the upstream PAGI distribution
(`PAGI::Spec` POD and protocol documents, https://github.com/jjn1056/pagi):

- WebSocket scope & events
