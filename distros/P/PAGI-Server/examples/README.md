# PAGI Examples

This directory contains progressively more advanced PAGI examples. Each subdirectory is prefixed with a two-digit number so you can follow along in order.

## Requirements
- Perl 5.18+ with `Future::AsyncAwait`
- For timers/sleeps: `Future::IO` (loop-agnostic)
- Run examples with: `pagi-server examples/01-hello-http/app.pl --port 5000`

These are raw PAGI applications and run with `pagi-server` alone — no other
distribution required. (In development mode the runner auto-enables Lint
middleware if the PAGI-Tools distribution happens to be installed, and
silently skips it otherwise.)

Note: Some advanced examples (job-runner, chat) use `IO::Async` directly for
timer and subprocess features. These are PAGI::Server-specific patterns.

Examples assume you understand the core PAGI specification (see the `PAGI::Spec` POD from the `PAGI` distribution on CPAN, https://github.com/jjn1056/pagi) plus the relevant protocol documents.

## Example List
1. `01-hello-http` - minimal HTTP response
2. `02-streaming-response` - chunked body, trailers, disconnect handling
3. `03-request-body` - reads multi-event request bodies
4. `04-websocket-echo` - handshake and echo loop
5. `05-sse-broadcaster` - server-sent events
6. `06-lifespan-state` - lifespan protocol with shared state
7. `07-extension-fullflush` - middleware using the `fullflush` extension
8. `08-tls-introspection` - prints TLS metadata when present
9. `11-job-runner` - background job processing example
10. `12-utf8` - UTF-8 handling demonstration

Also included: `backpressure-test` - demonstrates backpressure handling (unnumbered utility example)

(Framework-level examples — routers, endpoints, middleware, chat apps — live with the PAGI-Tools distribution.)

Each example has its own `README.md` explaining how to run it and which spec sections to review.

## worker-pool-prototype.pl

A standalone prototype exploring worker-pool design for the server. It is
not a runnable PAGI example; it is kept for reference.
