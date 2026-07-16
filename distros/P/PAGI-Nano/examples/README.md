# PAGI::Nano examples

Each directory is a runnable single-file app. Run any of them with:

```
pagi-server app.pl
```

Handlers that use `await` are written `async sub` and the file adds
`use Future::AsyncAwait` alongside `use PAGI::Nano`.

All of these are exercised by `t/08-examples.t` (and the run shapes by
`t/07-run-shapes.t`), loaded the same way `pagi-server` loads them.

## Ported from the PAGI / PAGI-Server / PAGI-Tools example suites

These port the **distinct, app-level** examples across the three upstream
repositories into PAGI::Nano. Where several upstream examples demonstrated the
same thing (e.g. two WebSocket echoes, two chat apps), they are merged into one.

| Nano example | Ports | Demonstrates |
|---|---|---|
| `hello-http` | PAGI 01-hello-http | the minimal app: one route, text response |
| `request-body` | PAGI 03-request-body | reading and echoing the request body |
| `utf8-echo` | PAGI 12-utf8 | UTF-8 round-trip across path and query |
| `websocket-echo` | PAGI 04 / Tools websocket-echo-v2 | a WebSocket echo handler |
| `static-file` | Tools app-01-file | static serving at root via `static` (PAGI::App::File) |
| `lifespan-state` | PAGI 06 / Tools 14-lifespan-utils | startup/shutdown + shared `$c->state` |
| `streaming-response` | PAGI 02-streaming-response | chunked streaming + `on_disconnect` |
| `sse-broadcaster` | PAGI 05 / Tools sse-dashboard | SSE events with ids (reconnect-aware) |
| `connection-introspection` | PAGI 08-tls-introspection | reading scheme/client/TLS off the scope |
| `bidirectional-websocket` | PAGI 18 / Tools websocket-bidirectional | concurrent echo + server-push branches |
| `mini-framework` | PAGI mini-framework | Nano *is* the hand-rolled mini-framework |
| `psgi-bridge` | Tools 09-psgi-bridge | mounting a legacy PSGI app via WrapPSGI |
| `background-tasks` | Tools background-tasks | respond now, run a retained Future after |
| `flow-control` | PAGI 13-flow-control | SSE conflation under transport backpressure |
| `sse-custom-events` | PAGI 17-event-middleware (evolved to SSE) | two custom SSE event types on one channel — `tick` (periodic source) and `message` (user-driven: `POST /say` broadcast to all subscribers) — folded into `$receive` by a coderef middleware using the race-without-cancel technique; includes `probe.pl` |
| `custom-send-events` | the send-side mirror of `sse-custom-events` | one wire-agnostic handler emits semantic `app.*` events on the raw send channel; two route-scoped renderer middlewares serve the **same `/feed` URL** as **SSE** (on `Accept: text/event-stream`) or **NDJSON** (plain HTTP, via the `raw` route), each enriching with a server-assigned sequence number — the handler never names a wire format |
| `full-demo` | Tools full-demo | HTTP + WS + SSE + lifespan in one app |
| `contact-form` | Tools 13-contact-form | form strong-params + 400 + multipart upload |
| `periodic-events` | PAGI 14-periodic-events | lifespan ticker + long-poll + NDJSON stream |
| `job-runner` | PAGI 11-job-runner | REST + SSE progress + WS stats + worker |
| `chat-showcase` | PAGI 10-chat-showcase / Tools websocket-chat-v2 | rooms API + WS broadcast + SSE + logger middleware |

Plus the two run-shape examples from the original build: `quickstart` (single
file) and `tasks-modulino` (a dual-use `lib/MyApp.pm`).

One further example beyond the upstream ports:

| Nano example | Demonstrates |
|---|---|
| `mounted-stash-state` | a mounted sub-app reading the request stash set by parent middleware and the lifecycle objects the parent put in app state at startup (the same shared instance) |
| `named-routes` | naming routes with `name(...)` and building links with `$c->uri_for`, including across a mount in both directions (parent ↔ mount) |
| `duplex-http-stream` | full-duplex over a single HTTP request — read the streaming request body while streaming the response (the HTTP analog of `bidirectional-websocket`). Includes `probe.pl`, a raw-socket client that proves pagi-server pumps both directions concurrently on HTTP/1.1 |

## Intentionally **not** ported — infrastructure-level

PAGI::Nano produces an app value; it does not own the event loop, the server, or
the wire protocol. These upstream examples are about exactly those layers, so
they have no PAGI::Nano form — you run a Nano app *under* them unchanged.

| Upstream example | Why it is out of scope for Nano |
|---|---|
| PAGI 07-extension-fullflush | drives the `http.fullflush` protocol extension; Nano apps stream via the response writer and leave flush control to the server |
| PAGI 15-embedded-ioasync | embeds `PAGI::Server` in an IO::Async program — a server/loop-embedding concern |
| PAGI 16-foreign-loop | runs the server under a foreign (EV) loop — an event-loop concern |
| PAGI-Server backpressure-test | stress-tests the server's send-side backpressure kernel |
| PAGI-Server worker-pool-prototype | a fork-based server worker pool prototype |
| PAGI-Tools test-lifespan-shutdown | validates the server's multi-worker signal/shutdown handling |

The PAGI-Tools `endpoint-demo` / `endpoint-router-demo` use the class-based
`PAGI::Endpoint(::Router)` API; PAGI::Nano is the DSL alternative to that style,
so their routes are expressed here by `full-demo`, `job-runner`, and
`chat-showcase` rather than ported one-to-one.
