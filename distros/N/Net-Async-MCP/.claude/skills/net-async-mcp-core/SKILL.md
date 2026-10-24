---
name: net-async-mcp-core
description: "Use when working on Net::Async::MCP — the async MCP client for IO::Async with three transports (InProcess, Stdio, HTTP): the two protocol eras and their handshake, the JSON-RPC request path, the failure convention, and the traps that break silently."
---

# net-async-mcp — Kern

Async MCP (Model Context Protocol) **client** for `IO::Async`, built on `Future` and `Future::AsyncAwait`. Three pluggable transports sit behind one client API: a caller writes to `Net::Async::MCP`
and swaps the transport underneath. No `Moo` anywhere — do not introduce it.

## Module map

| Module | Owns |
|---|---|
| `Net::Async::MCP` | the public client API and the JSON-RPC layer; negotiates the protocol version, dispatches over the transport it holds |
| `Transport::InProcess` | embeds an `MCP::Server` and calls it directly — the only transport with a server in-process |
| `Transport::Stdio` | pure client: newline-delimited JSON-RPC over a subprocess's stdio |
| `Transport::HTTP` | pure client: Streamable HTTP over `Net::Async::HTTP` |
| `Net::Async::MCP::JSONRPC` | internal helper, no public API: `error_failure` and `error_text`, which all three transports read a response's `error` with |

The constructor argument picks the transport: `server` → InProcess, `command` → Stdio, `url` → HTTP. Stdio and HTTP need the client in an `IO::Async::Loop` before the transport
can be built; InProcess does not and is no notifier, so it has no place in the loop.

## The two protocol eras

Which era is spoken is a property of the **server**, decided once by the handshake and kept for the client's life (`is_legacy`).

| | Modern | Legacy |
|---|---|---|
| Revision | `2026-07-28` | `2025-11-25`, `2025-06-18`, `2025-03-26`, `2024-11-05` |
| Handshake | one `server/discover` | `initialize` + `notifications/initialized` |
| `_meta` per request | the three `io.modelcontextprotocol/*` keys | none; a caller's own travels as it is |
| Session | stateless | over HTTP a session (`Mcp-Session-Id`) |
| Server asks the client | through `input_required` results | with requests of its own — `ping` answered, the rest refused with `-32601` |
| Subscriptions | `subscriptions/listen` | none; a legacy server sends notifications unasked |

`protocol_version` names a revision and is a **pin**: a legacy revision goes straight to `initialize`, anything else speaks the modern revision only. Unpinned, the client probes
with `server/discover`. **An answer** means the server is modern, and that answer *is* the handshake. **A refusal with `-32020`, `-32021` or `-32022`** means a modern server too —
except a `-32022` naming only legacy revisions, which leads to an `initialize` for the newest legacy revision this client speaks. **Any other error, or no answer within
`discover_timeout`**, means a legacy server, and the `initialize` follows with the newest legacy revision. The timeout applies to stdio only, since over HTTP every request gets a
status. A failure the server did not send — a process gone, a connection refused — is no sign of a legacy server, and no `initialize` follows it.

## The request path

Every public method goes through the client's `_request`, the one place that holds what is true of all of them:

- the `_meta` every request carries (modern only);
- the `input_required` round trip (SEP-2322): a server that needs something answers with `resultType: input_required` and `inputRequests`; the client asks `on_input_request` and sends the answers back under the very keys
  the server used, so the caller never sees an `input_required`; more than eight in a row fails;
- the one retry a refused protocol version is worth: `-32022` names the revisions the server speaks in `error.data.supported`, and one this client speaks too is taken up and kept,
  so later requests carry it;
- the legacy session renewal: a `404` to a request in a session fails it in category `mcp_session_expired`, and the client starts one new session and sends the request once
  more.

List methods (`list_tools`, `list_prompts`, `list_resources`) walk `nextCursor` to the end. A cursor that comes round again, or more than 100 pages, fails the call: a quietly truncated list looks
like a complete one.

## Events — and which transport fires them

`on_notification`, `on_subscription_end`, `on_stderr` and `on_input_request` are `IO::Async::Notifier` events. A handler set on the client is called **with the client**, even where the transport received the thing; a handler set
on a transport object is that transport's own event and is called with the transport.

| Event | InProcess | Stdio | HTTP |
|---|---|---|---|
| `on_notification` | no — nothing arrives | yes | yes |
| `on_stderr` | no | yes | no |
| `on_subscription_end` | no | no | yes — the only transport with a stream |

Settings reach a transport only when the caller gave them **and** the transport's class matches: `headers` and `stall_timeout` to HTTP, `env`, `cwd` to Stdio, `timeout` to both wire transports. A setting
the caller never named is left alone, so the transport's own default survives.

## Failure convention

Every transport fails a JSON-RPC error the way `Future`'s `( $message, $category, @details )` convention asks for it:

```perl
my ( $message, $category, $error ) = $future->failure;
if (($category // '') eq 'mcp') {
  my $code      = $error->{code};          # -32601, -32602, ...
  my $supported = $error->{data}{supported};
}
```

The `mcp` category marks a genuine JSON-RPC error and nothing else; the raw error object travels as the details and the message stays what it was. A failure
that is no server error carries no category — except `timeout` for a request that ran out of `timeout` (HTTP and stdio; over stdio the server is sent `notifications/cancelled`, and a timed-out `server/discover` probe counts as no answer), `connect` for an HTTP connection that could not be made, `mcp_probe_timeout` for an unanswered stdio probe and `mcp_session_expired` for an
ended legacy session.

An `error` is read through `Net::Async::MCP::JSONRPC`, never reached into: only a hash with a defined `code` is a JSON-RPC error. Any other defined `error` — a string, a
number, an array, a hash without `code` — fails without category as `MCP {stdio,HTTP,in-process} error response: TEXT`. `"error": null` next to a `result` is a success, alone it fails as
`MCP … invalid response: a null error and no result`.

## Invariants to keep

- **The version list is this distribution's own.** `@MODERN_PROTOCOL_VERSIONS` and `@LEGACY_PROTOCOL_VERSIONS` say what *this client builds*: an entry means the request shapes of that revision are built
  here — deliberately not `MCP::Constants::SUPPORTED_VERSIONS` or `MCP::Constants::PROTOCOL_VERSION`.
- **One request path.** A new method goes through `_request`, never its own dispatch.
- **`_meta` is rebuilt per request**, so a renegotiated version reaches every later request.
- **Capabilities are a promise.** `client_capabilities` tells the server what it may ask for; an input request for an undeclared capability is refused as a server violation,
  not passed to the handler.
- **The tool-header cache serves only mirroring bindings.** `call_tool` resolves the `x-mcp-header` annotations from the tool's input schema; a transport that does not mirror
  headers never fetches a tool list for it.
- **Weak references across the client/transport edge.** The client holds the transport, so the transport must not hold the client.
- **Single `$VERSION`.** `dist.ini` has `version_finder = :MainModule`: `our $VERSION` lives only in `lib/Net/Async/MCP.pm`, the transport modules and `JSONRPC` deliberately carry none. This diverges from the general `[@Author::GETTY]` convention (skill
  `getty-perl-release-author-getty`) and is intentional.

## Traps — what breaks silently

- **InProcess needs a real `MCP::Server::Context`.** From `MCP` (SRI's distribution, not Getty-authored) >= 0.10 the server calls methods (`progress_token`, `has_scope`, `insufficient_scope`) straight on the
  context object for nearly every request beyond `initialize`/`ping`; a hashref passes `initialize` and dies on the first real request. `cpanfile` pins `MCP` >= 0.15 (a `recommends` plus a test
  `requires`, because only InProcess needs it) — do not lower it. The context class is loaded at the first request, not at compile time, so the module still
  loads without `MCP` and `handle()` is then called with the request alone.
- **The wire transports never touch `MCP::Server`** — only InProcess embeds a server.
- **Cancellation reaches the transport only on perl 5.24+.** `Future::AsyncAwait` hands a cancel of an `async sub`'s future on to the future it awaits only there; on older perls
  the request stays pending in the transport, and `t/15_client.t` skips those two checks.
- **Stdio drains stderr even without a handler** — a server whose stderr nobody drains stalls once the pipe is full. The last 20 stderr lines are quoted
  in the failure of every request the subprocess leaves unanswered. Shutdown takes up to 4 seconds: stdin closed first, SIGTERM after 2 s, SIGKILL 2 s
  after that.
- **HTTP: the body is the truth.** The metadata headers (`MCP-Protocol-Version`, `Mcp-Method`, `Mcp-Name`, `Mcp-Param-{Name}`) are derived from the body, and a conforming server answers `-32020` for a missing
  or diverging one. A configured header may not take one over: it is dropped, not overridden — `HTTP::Headers` keeps a field given twice as two values of one header.
  A JSON-RPC error in the body wins over the status, since MCP servers render errors such as `METHOD_NOT_FOUND` with a 404 and a rejected `_meta` with a 400.
- **Loading `MCP::Server` inside a test process can hang the suite.** It loads Mojolicious, which loads EV where it is installed, and EV takes over `SIGCHLD` — after
  IO::Async has started watching children, no exit is ever reaped again and every later `close` hangs. `t/25_legacy.t` and `t/35_http_legacy.t` ask for MCP in a child perl for that reason.
- **InProcess blocks on a `Mojo::Promise`.** A tool answering with one is resolved with `wait()`, which blocks the loop; a fully non-blocking tool wants the Stdio transport
  with a subprocess.

## Commands

```bash
prove -lr t                    # the whole suite, offline
prove -lv t/30_http.t          # one file
dzil build                     # checks the single-$VERSION style via MetaProvides
```

Everything runs offline. The suite needs `MCP` (the in-process, client and stdio files skip without it), `HTTP::Message` (the HTTP files) and `Mojolicious` (the legacy HTTP test
server).

## File map

- `lib/Net/Async/MCP.pm` — the client: public API, `_request`, the handshake, the era.
- `lib/Net/Async/MCP/Transport/{InProcess,Stdio,HTTP}.pm` — the three transports.
- `lib/Net/Async/MCP/JSONRPC.pm` — how every transport reads the `error` of a response.
- `t/10_inprocess.t`, `t/11_context.t` — a real `MCP::Server` in process; the context rule, both halves.
- `t/15_client.t` — transport-independent client behaviour against stub servers.
- `t/20_stdio.t` — a real `MCP::Server` in a subprocess; cancellation, stderr, shutdown.
- `t/25_legacy.t`, `t/35_http_legacy.t` — the legacy eras against the hand-rolled servers in `t/bin/`.
- `t/30_http.t` — the response handling, driven directly; the suite has no HTTP server.
- `t/40_errors.t`, `t/50_subscriptions.t` — the failure convention per transport; subscriptions over a hand-driven stream.
- `t/bin/test_mcp_server.pl` — the stdio test server: `MCP::Server` over stdin/stdout.
- `t/bin/legacy_mcp_server.pl`, `t/bin/legacy_http_server.pl` — hand-rolled legacy servers, no part of `MCP`.

## Boundaries

- **This is the client half.** The server counterpart is `Net::Async::MCP::Server` in the separate repo `p5-net-async-mcp-server`; the two are meant to interoperate and neither is edited from the
  other. Building an MCP server in Perl is the skill `perl-mcp`; the wire protocol in general is not this repo's business.
- **Out of scope in the HTTP transport**: the standalone `GET` stream a server may offer for messages outside any request, resuming a broken stream with `Last-Event-ID`,
  and the HTTP+SSE transport of `2024-11-05` — a server of that revision is reachable over stdio.
- **No server-to-client requests on a modern connection**: the modern revision has none, a server asks through `input_required` results instead. Lifecycle and
  cancellation belong to `perl-io-async-future`, the Perl baseline to `getty-perl-core`.
