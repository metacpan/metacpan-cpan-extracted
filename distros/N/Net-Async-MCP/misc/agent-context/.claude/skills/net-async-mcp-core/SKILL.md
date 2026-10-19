---
name: net-async-mcp-core
description: "Load before editing Net::Async::MCP — the async MCP client for IO::Async with three transports (InProcess, Stdio, HTTP): the InProcess-embeds-a-server concern, the pure-client boundary the wire transports keep, the known gaps that are scope decisions not bugs, and this dist's single-$VERSION style."
---

# Net::Async::MCP — core

Async MCP (Model Context Protocol) **client** for `IO::Async`, built on `Future` /
`Future::AsyncAwait`. Three pluggable transports sit behind one client API; the whole
point of the distribution is that a caller writes to `Net::Async::MCP` and swaps the
transport underneath. Every module is an `IO::Async::Notifier` (no `Moo` here — do not
introduce it).

## Module map

| Module | Owns |
|---|---|
| `Net::Async::MCP` | public client API and the JSON-RPC layer; negotiates protocol version, dispatches requests over whatever transport it holds |
| `Net::Async::MCP::Transport::InProcess` | embeds an `MCP::Server` instance and calls it directly — the only transport with a server in-process |
| `Net::Async::MCP::Transport::Stdio` | pure client: JSON-RPC over a subprocess's stdio |
| `Net::Async::MCP::Transport::HTTP` | pure client: Streamable HTTP over `Net::Async::HTTP` |

## The InProcess Context concern — the one that actually breaks

`InProcess` must pass a **real `MCP::Server::Context->new`, never a plain hashref**, to
`MCP::Server->handle()`. From `MCP` (SRI's distribution, not Getty-authored) >= 0.10 the
server calls methods (`progress_token`, `has_scope`, `insufficient_scope`) directly on
the context object for nearly every request beyond `initialize`/`ping`. A hashref passes
`initialize` and then dies the first time a real request lands. `cpanfile` pins `MCP`
accordingly (a `recommends` plus a test `requires`, because only `InProcess` needs it) —
do not lower it. Per the house rule, the CPAN release-stand of `MCP` is never itself a
blocker; the pin tracks the API this transport depends on.

## The wire transports are pure clients

`Stdio` and `HTTP` speak the wire protocol (JSON-RPC over stdio / Streamable HTTP) and
**never touch `MCP::Server`** — they do not share the Context concern above. Only
`InProcess` embeds a server. Keep that boundary: a wire transport that reaches for
`MCP::Server` is wrong.

## Known gaps — scope decisions, not bugs

Flag these to the user before "fixing" them; they are deliberate omissions, not defects:

- `Transport::HTTP` has **no way to attach auth headers** (e.g. an OAuth bearer token).
  SRI's own `MCP::Client` has a `headers` attribute for exactly this; ours doesn't yet.
- **Server-initiated notifications** (`notifications/progress`, `list_changed`) are
  silently dropped by both `Stdio` and `HTTP` — there is no callback/event API exposing
  them to callers.
- **No test coverage for `Transport::HTTP`** beyond the load check in `t/00_load.t`.

## Version style — single `$VERSION`, not per-file

This dist uses `version_finder = :MainModule` in `dist.ini`: `our $VERSION` lives **only
in `lib/Net/Async/MCP.pm`**, and the three transport modules deliberately carry none.
`[@Git::VersionManager]` rewrites/bumps only the main module on release; `MetaProvides`
still fills every package into `META.json` at the dist version.

This **diverges from the general `[@Author::GETTY]` convention** that every file carries
its own `$VERSION` (stated in skill `getty-perl-release-author-getty`). Here that is
intentional (migrated deliberately). Do **not** add `our $VERSION` to the transport
modules — that is the exception, verified via `dzil build`.
