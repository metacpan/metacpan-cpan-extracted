# PAGI - Perl Asynchronous Gateway Interface

<a href="https://github.com/jjn1056/PAGI/actions"><img src="https://github.com/jjn1056/PAGI/actions/workflows/ci.yml/badge.svg"></a>
<a href="https://metacpan.org/pod/PAGI"><img src="https://badge.fury.io/pl/PAGI.svg"></a>

PAGI is a specification for asynchronous Perl web applications, designed as a spiritual successor to PSGI. It defines a standard interface between async-capable Perl web servers, frameworks, and applications, supporting HTTP/1.1, WebSocket, and Server-Sent Events (SSE).

## ⚠️ Beta Software

This distribution has different stability levels:

| Component | Stability | Notes |
|-----------|-----------|-------|
| **PAGI Specification** | Stable | The `$scope`/`$receive`/`$send` interface won't change except for critical security fixes |
| **PAGI::Server** | Stable | Compliance-tested, but run behind nginx/Caddy for production |
| **Everything else** | Unstable | Request/Response wrappers, routers, middleware, apps may change between releases |

## Repository Contents

- **docs/** - PAGI specification documents
- **examples/** - Reference PAGI applications demonstrating the raw protocol
- **lib/** - Reference server implementation (PAGI::Server) and middleware
- **bin/** - CLI launcher (pagi-server)
- **t/** - Test suite

## Requirements

- Perl 5.18+
- cpanminus (for dependency installation)

## Quick Start

```bash
# Install dependencies
cpanm --installdeps .

# For best performance (fast JSON, TLS support):
cpanm --installdeps . --with-recommends

# Run tests
prove -l t/

# Start the server with a PAGI app
pagi-server --app examples/01-hello-http/app.pl --port 5000

# Test it
curl http://localhost:5000/
```

## Optional Performance Dependencies

PAGI uses `JSON::MaybeXS` for JSON encoding/decoding, which automatically uses the fastest available backend:

| Module | Speed | Notes |
|--------|-------|-------|
| **Cpanel::JSON::XS** | Fastest | Recommended for production |
| **JSON::XS** | Fast | Good alternative |
| **JSON::PP** | Baseline | Pure Perl fallback (always available) |

Install for best performance:
```bash
cpanm Cpanel::JSON::XS
```

Other optional dependencies:
- **IO::Async::SSL** + **IO::Socket::SSL** - TLS/HTTPS support (see below)

## Optional TLS/HTTPS Support

TLS support is **optional** and not installed by default. Most production deployments use a reverse proxy (nginx, Caddy, HAProxy) for TLS termination, so PAGI keeps the base installation minimal.

**To enable HTTPS support:**

```bash
# Using cpanm
cpanm IO::Async::SSL IO::Socket::SSL

# Or on Debian/Ubuntu
apt-get install libio-socket-ssl-perl
```

**When you need TLS in PAGI::Server:**
- Serving HTTPS directly without a reverse proxy
- Testing TLS locally during development
- Using client certificate authentication

**When you don't need it:**
- Behind nginx, Caddy, or other reverse proxy handling TLS
- Development on localhost with HTTP only
- Behind a cloud load balancer (AWS ALB, GCP LB)

The startup banner shows TLS status: `tls: on|available|not installed|disabled`

See `perldoc PAGI::Server` for TLS configuration details and certificate generation examples.

## PAGI Application Interface

PAGI applications are async coderefs with this signature:

```perl
use Future::AsyncAwait;

async sub app {
    my ($scope, $receive, $send) = @_;

    die "Unsupported: $scope->{type}" if $scope->{type} ne 'http';

    await $send->({
        type    => 'http.response.start',
        status  => 200,
        headers => [ ['content-type', 'text/plain'] ],
    });

    await $send->({
        type => 'http.response.body',
        body => "Hello from PAGI!",
        more => 0,
    });
}
```

### Parameters

- **$scope** - Hashref containing connection metadata (type, headers, path, etc.)
- **$receive** - Async coderef returning a Future that resolves to the next event
- **$send** - Async coderef taking an event hashref, returning a Future

### Scope Types

- `http` - HTTP request/response (one scope per request)
- `websocket` - Persistent WebSocket connection
- `sse` - Server-Sent Events stream
- `lifespan` - Process startup/shutdown lifecycle

## UTF-8 Handling

- `scope->{path}` is UTF-8 decoded from the percent-encoded `raw_path`. Use `raw_path` when you need on-the-wire bytes.
- `scope->{query_string}` and request bodies are byte data (often percent-encoded). Decode explicitly with `Encode` using replacement or strict modes as needed.
- Response bodies/headers must be bytes; set `Content-Length` from byte length. Encode with `Encode::encode('UTF-8', $str, FB_CROAK)` (or another charset you declare in `Content-Type`).

Minimal example with explicit UTF-8 handling:

```perl
use Future::AsyncAwait;
use experimental 'signatures';
use Encode qw(encode decode FB_DEFAULT FB_CROAK);

async sub app ($scope, $receive, $send) {
    die "Unsupported: $scope->{type}" if $scope->{type} ne 'http';

    my $text = '';
    if ($scope->{query_string} =~ /text=([^&]+)/) {
        my $bytes = $1; $bytes =~ s/%([0-9A-Fa-f]{2})/chr hex $1/eg;
        $text = decode('UTF-8', $bytes, FB_DEFAULT);  # replacement for invalid
    }

    my $body    = "You sent: $text";
    my $encoded = encode('UTF-8', $body, FB_CROAK);

    await $send->({
        type    => 'http.response.start',
        status  => 200,
        headers => [
            ['content-type',   'text/plain; charset=utf-8'],
            ['content-length', length($encoded)],
        ],
    });
    await $send->({
        type => 'http.response.body',
        body => $encoded,
        more => 0,
    });
}
```

## Example Applications

### Low-Level Protocol Examples

These examples demonstrate the raw PAGI protocol:

| Example | Description |
|---------|-------------|
| 01-hello-http | Basic HTTP response |
| 02-streaming-response | Chunked streaming with trailers |
| 03-request-body | POST body handling |
| 04-websocket-echo | WebSocket echo server |
| 05-sse-broadcaster | Server-Sent Events |
| 06-lifespan-state | Shared state via lifespan |
| 07-extension-fullflush | TCP flush extension |
| 08-tls-introspection | TLS connection info |
| 09-psgi-bridge | PSGI compatibility |

### Higher-Level Examples

| Example | Description |
|---------|-------------|
| endpoint-router-demo | Full app with HTTP, WebSocket, SSE using PAGI::Endpoint::Router |
| websocket-chat-v2 | Chat application using PAGI::WebSocket wrapper |
| sse-dashboard | Dashboard with SSE updates using PAGI::SSE wrapper |

## Components

PAGI includes convenience wrappers for common patterns:

| Component | Description |
|-----------|-------------|
| **PAGI::Lifespan** | Lifecycle management for apps (startup/shutdown callbacks, state injection) |
| **PAGI::Request** | HTTP request wrapper with body parsing, headers, state/stash accessors |
| **PAGI::WebSocket** | WebSocket wrapper with JSON support, heartbeat, message iteration |
| **PAGI::SSE** | SSE wrapper with event formatting, keepalive, periodic sending |
| **PAGI::Endpoint::Router** | Class-based router for HTTP, WebSocket, and SSE routes |
| **PAGI::App::Router** | Functional router with Express-style routing |

### Higher-Level Router Example

```perl
# lib/MyApp.pm
package MyApp;
use parent 'PAGI::Endpoint::Router';
use Future::AsyncAwait;

sub routes {
    my ($self, $r) = @_;
    $r->get('/' => 'home');
    $r->websocket('/ws/echo' => 'ws_echo');
    $r->sse('/events' => 'sse_stream');
}

async sub home {
    my ($self, $req, $res) = @_;
    await $res->html('<h1>Hello!</h1>');
}

async sub ws_echo {
    my ($self, $ws) = @_;
    await $ws->accept;
    await $ws->each_json(async sub {
        my ($data) = @_;
        await $ws->send_json({ echo => $data });
    });
}

async sub sse_stream {
    my ($self, $sse) = @_;
    await $sse->every(1, async sub {
        await $sse->send_event(event => 'tick', data => { time => time });
    });
}

1;

# app.pl
use PAGI::Lifespan;
use MyApp;

my $router = MyApp->new;

PAGI::Lifespan->wrap(
    $router->to_app,
    startup => async sub {
        my ($state) = @_;
        $state->{config} = { app_name => 'MyApp' };
    },
);
```

See `examples/endpoint-router-demo/` for a complete working example with HTTP, WebSocket, and SSE.

## Middleware

PAGI includes a collection of middleware components in `PAGI::Middleware::*`:

- Authentication (Basic, Digest, Bearer)
- Sessions and Cookies
- Security (CORS, CSRF, Rate Limiting)
- Compression (GZIP)
- Logging and Metrics
- And many more

See `lib/PAGI/Middleware/` for the full list.

## Development

```bash
# Install development dependencies
cpanm --installdeps . --with-develop

# Build distribution
dzil build

# Run distribution tests
dzil test
```

## Specification

See [docs/specs/main.mkdn](docs/specs/main.mkdn) for the complete PAGI specification.

## License

This software is licensed under the same terms as Perl itself.

## Author

John Napiorkowski <jjnapiork@cpan.org>
