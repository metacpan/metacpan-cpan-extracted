# PAGI-Tools Examples

This directory contains example applications built on the PAGI toolkit — the
higher-level components (Endpoint, Middleware, Apps, Context, Request/Response,
etc.) that live in this distribution.

## Requirements

- Perl 5.18+ with `Future::AsyncAwait`
- A PAGI server to run examples against:
  ```
  cpanm PAGI::Server
  ```
  Then launch any example with:
  ```
  pagi-server examples/<name>/app.pl --port 5000
  ```

Examples assume you understand the core spec
(see the [PAGI project](https://github.com/jjn1056/pagi) for spec documents)
plus the relevant protocol documents.

Note: Low-level protocol examples (hello-http, streaming-response, websocket-echo
handshake, SSE broadcaster, lifespan-state, extension-fullflush, tls-introspection,
job-runner, utf8) shipped with the `PAGI-Server` distribution — they demonstrate
raw PAGI protocol details that belong alongside the server implementation.

## Example List

1. `09-psgi-bridge` - wraps a PSGI app for PAGI use (via `PAGI::App::WrapPSGI`)
2. `10-chat-showcase` - WebSocket chat demo with multiple clients
3. `13-contact-form` - form parsing and file uploads
4. `14-lifespan-utils` - lifespan hooks via `PAGI::Utils`
5. `app-01-file` - static file serving with `PAGI::App::File`
6. `background-tasks` - running background work from within a PAGI app
7. `endpoint-demo` - high-level HTTP endpoint with `PAGI::Endpoint::HTTP`
8. `endpoint-router-demo` - composing routes with `PAGI::Endpoint::Router`
9. `full-demo` - kitchen-sink demo combining multiple toolkit features
10. `sse-dashboard` - server-sent events dashboard with `PAGI::Endpoint::SSE`
11. `test-lifespan-shutdown` - testing graceful lifespan shutdown hooks
12. `websocket-chat-v2` - WebSocket chat using `PAGI::Endpoint::WebSocket`
13. `websocket-echo-v2` - WebSocket echo using `PAGI::Endpoint::WebSocket`
14. `websocket-bidirectional` - full-duplex WebSocket with `PAGI::Context`: a receive-loop (`each_text`) and an unsolicited server send-loop running concurrently

**Note on `websocket-chat-v2/public`:** this directory is a symlink to
`10-chat-showcase/public`. It works in git checkouts but is omitted from the
distribution tarball; copy the `public/` directory manually if you need it
outside a checkout.

Each example has its own `README.md` explaining how to run it.
