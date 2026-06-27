# PAGI-Server

Reference [IO::Async](https://metacpan.org/pod/IO::Async) server for the
**PAGI** specification.

`PAGI::Server` is a reference implementation of a PAGI-compliant HTTP server.
It speaks HTTP/1.1, WebSocket, and Server-Sent Events (with experimental
HTTP/2), and prioritises spec compliance and code clarity over raw
performance — it is the canonical reference for how a PAGI server should
behave.

PAGI is an asynchronous Perl web-application interface in the spirit of
Python's ASGI: an application is a coderef invoked with a `scope`, a `receive`
callback, and a `send` callback. See the
[PAGI distribution](https://github.com/jjn1056/pagi) for the specification
itself.

## Features

- **HTTP/1.1** — full support including chunked encoding, trailers, and
  keep-alive.
- **WebSocket** — RFC 6455, including over HTTP/2 (RFC 8441).
- **Server-Sent Events** — including SSE over HTTP/2.
- **HTTP/2** (experimental) — via `nghttp2`, both `h2` over TLS and `h2c`
  cleartext.
- **TLS** — HTTPS with TLS 1.3 negotiation and optional client certificates.
- **Multi-worker pre-fork** mode with heartbeat-based liveness monitoring.
- **Backpressure** — a `pagi.transport` flow-control handle (buffered amount
  plus high/low watermark callbacks) on HTTP, WebSocket, and SSE scopes.
- **Lifespan protocol** — startup/shutdown hooks with shared application state.
- **Unix domain socket** and multi-listener support (experimental).
- **Request smuggling, Rapid Reset (CVE-2023-44487), and resource-exhaustion
  defenses** out of the box — see
  [`PAGI::Server::Compliance`](lib/PAGI/Server/Compliance.pod).

## Installation

PAGI-Server requires **Perl 5.18+**. Install the dependencies with
[`cpanm`](https://metacpan.org/pod/App::cpanminus):

```bash
cpanm --installdeps .
```

Optional features need extra modules:

```bash
# TLS / HTTPS
cpanm IO::Async::SSL IO::Socket::SSL

# HTTP/2 (experimental)
cpanm Net::HTTP2::nghttp2
```

`Future::IO` is recommended so application code can sleep and do I/O without
coupling to a specific event loop.

## Quick start

A PAGI application is an `async sub` that receives `($scope, $receive, $send)`.
Save this as `app.pl`:

```perl
use strict;
use warnings;
use Future::AsyncAwait;

my $app = async sub {
    my ($scope, $receive, $send) = @_;
    die "Unsupported scope type: $scope->{type}" if $scope->{type} ne 'http';

    await $send->({
        type    => 'http.response.start',
        status  => 200,
        headers => [ [ 'content-type', 'text/plain' ] ],
    });
    await $send->({
        type => 'http.response.body',
        body => 'Hello from PAGI',
        more => 0,
    });
};

$app;  # the file returns the coderef
```

Run it with the bundled `pagi-server` launcher:

```bash
pagi-server --app app.pl --port 5000
curl http://localhost:5000/
# => Hello from PAGI
```

### Running programmatically

You can also drive `PAGI::Server` directly from your own event loop:

```perl
use IO::Async::Loop;
use PAGI::Server;

# If you use Future::IO-based libraries, load this BEFORE them:
use Future::IO::Impl::IOAsync;

my $loop   = IO::Async::Loop->new;
my $server = PAGI::Server->new(
    app  => $app,
    host => '127.0.0.1',
    port => 5000,
);

$loop->add($server);
$server->listen->get;  # start accepting connections
```

## Command-line usage

```
pagi-server [options] [app] [key=value ...]

# Serve a PAGI app file
pagi-server ./app.pl

# Multi-worker, custom port
pagi-server --workers 4 --port 8080 ./app.pl

# Development mode (auto-enables Lint middleware when PAGI-Tools is installed)
pagi-server -E development ./app.pl

# HTTPS
pagi-server --ssl-cert cert.pem --ssl-key key.pem ./app.pl

# HTTP/2 over TLS (experimental)
pagi-server --http2 --ssl-cert cert.pem --ssl-key key.pem ./app.pl
```

Run `perldoc pagi-server` for the full list of options (workers, timeouts,
limits, watermarks, TLS, listeners, and more).

## Examples

The [`examples/`](examples/) directory contains progressively more advanced,
runnable applications — minimal HTTP, streaming with disconnect handling,
request-body draining, a WebSocket echo server, an SSE broadcaster,
lifespan/shared-state, extension-aware streaming, TLS introspection, a job
runner, UTF-8 handling, and a backpressure test harness. Each has its own
`README.md`. Start with [`examples/01-hello-http`](examples/01-hello-http/).

## Documentation

- [`PAGI::Server`](lib/PAGI/Server.pm) — the server class, constructor options,
  and operational notes (`perldoc PAGI::Server`).
- [`pagi-server`](bin/pagi-server) — the command-line launcher
  (`perldoc pagi-server`).
- [`PAGI::Server::Runner`](lib/PAGI/Server/Runner.pm) — application loading and
  server orchestration.
- [`PAGI::Server::Compliance`](lib/PAGI/Server/Compliance.pod) — HTTP/WebSocket
  compliance and the built-in security defenses.
- [`Changes`](Changes) — release history.
- [`SECURITY.md`](SECURITY.md) — how to report security issues.

## Relationship to PAGI and PAGI-Tools

PAGI-Server has **no runtime dependency** on other PAGI distributions — the
application runner (`PAGI::Server::Runner`) ships here. The framework-level
toolkit (routers, endpoints, middleware such as `PAGI::Middleware::Lint`, and
the `PAGI::App::*` apps) lives in the separate **PAGI-Tools** distribution and
is used only when present. The specification itself lives in the
[**PAGI**](https://github.com/jjn1056/pagi) distribution.

This distribution was split out of the PAGI distribution; its git history is
preserved from the [original repository](https://github.com/jjn1056/pagi).

## License

Copyright (C) John Napiorkowski.

This library is free software; you can redistribute it and/or modify it under
the terms of the [Artistic License 2.0](https://opensource.org/licenses/Artistic-2.0).
