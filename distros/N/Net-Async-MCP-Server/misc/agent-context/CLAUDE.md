# CLAUDE.md

## Distribution

Net::Async::MCP::Server — async MCP (Model Context Protocol) **server** base class for
Perl, built on IO::Async and Future::AsyncAwait. Subclasses register tools; the base
class handles per-request JSON-RPC dispatch on the 2026-07-28 wire protocol.

Uses Dist::Zilla with `[@Author::GETTY]`. The repo is currently at `0.002`
(matches the wire-format version of MCP 2026-07-28; the repo always runs one ahead of
the next release).

**This is a standalone implementation** — it does not build on SRI's `MCP` /
`MCP::Server` distribution. The sibling dist `Net::Async::MCP`
(`~/dev/p5-net-async-mcp`) is the *client* half the two are meant to interoperate
with; it lives in its own repo and is never edited from here.

## Protocol

MCP 2026-07-28 is **stateless**. There is no `initialize` handshake, no session id,
no `ping`. Every request carries `protocolVersion` and `clientCapabilities` in
`params._meta.io.modelcontextprotocol/*`; every result carries `resultType` and
`io.modelcontextprotocol/serverInfo` in `_meta`. The new pre-flight RPC is
`server/discover`; the legacy `initialize`/`ping`/`notifications/initialized` are
rejected with `-32601 Method not found`.

## Structure

- `lib/Net/Async/MCP/Server.pm` — the server (`IO::Async::Notifier`): the tool registry
  (`register_tool` / `list_tools` / `call_tool`), `discover` / `list_tools` /
  `call_tool` async methods, and `handle()`, the JSON-RPC dispatch that maps
  `server/discover` · `tools/list` · `tools/call` to responses or errors. Per-request
  `_meta` validation lives at the top of `handle()`; tool errors are mapped to
  `isError: true` content blocks; protocol-level errors stay on the JSON-RPC error
  channel.
- `lib/Net/Async/MCP/Server/Transport/Stdio.pm` — newline-delimited JSON-RPC over
  stdin/stdout. Per-request, stateless, EOF-as-graceful-shutdown.
- `lib/Net/Async/MCP/Server/Transport/StreamableHTTP.pm` — Streamable HTTP transport
  (POST single endpoint, SSE for long-lived streams). Implements the spec's
  request-metadata headers (`MCP-Protocol-Version`, `Mcp-Method`, `Mcp-Name`,
  `Mcp-Param-*` from `x-mcp-header` annotations) and the `-32020 HeaderMismatch`
  parity check.

Each `lib/*.pm` carries its own `our $VERSION`, and `dist.ini` sets no `version_finder`
— that is the house convention for a CPAN dist (`:MainModule` is the `no_cpan` default).
A new module needs its own `$VERSION`, and one package per file: only the first
`our $VERSION` in a file is rewritten at release time.

## Dependencies

**IO::Async** (base class / event loop) · **Future** + **Future::AsyncAwait** (the
`async sub` methods) · **JSON::MaybeXS** (wire encoding) · **Plack** +
**HTTP::Server::PSGI** (Streamable HTTP transport) · **Test2::V0** on test (plus
**Plack::Test** + **HTTP::Request::Common** for the HTTP transport tests).

## Testing

```bash
prove -l t/     # whole suite — no network, no spawned process
dzil test       # builds first; the closer-to-release check
```

**A new test file must be `git add`ed before `dzil test` runs it.** The bundle gathers
via `Git::GatherDir`, so an untracked `t/*.t` is silently left out of the build —
`dzil test` then reports a green run that never executed the new file. Use
`git add -N t/NN-name.t` (intent-to-add, no commit) as soon as the file exists.

`README.md` is hand-maintained: `[@Author::GETTY]` excludes it from the tarball
(`include_readme` is off) and ships a POD-generated plain `README` instead. Keep the
hand-maintained `README.md` version in lockstep with `$VERSION` in
`Net::Async::MCP::Server`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/mcp-server-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `mcp-server-worker` (default) |
| Write/extend tests | `mcp-server-test-writer` |
| POD in the house format + README.md | `mcp-server-pod-writer` |
| Commits, `Changes`, card → done, pre-release audit | `mcp-server-release-manager` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/`,
hardlink-shared with the other Perl repos.

Known gaps in the current implementation — flag before "fixing" — are listed in
`.claude/agents/mcp-server-worker.md`.

## PodWeaver

`[@Author::GETTY]` conventions: inline `=method`, `=attr`, `=seealso`. No manual
NAME/VERSION/AUTHOR sections. Full rules: skill `getty-perl-release-author-getty`.
