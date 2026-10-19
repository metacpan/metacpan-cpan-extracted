# Net::Async::MCP

Async MCP (Model Context Protocol) client for `IO::Async` with three pluggable transports
(InProcess, Stdio, HTTP). Released to CPAN as `Net-Async-MCP`, built and released with
`Dist::Zilla` via `[@Author::GETTY]`.

The architecture — the InProcess-embeds-a-server concern, the pure-client transport
boundary, the known gaps, and the single-`$VERSION` `:MainModule` style — lives in skill
`net-async-mcp-core`, not here. Engineering discipline, the release-permission rule and the
public-issues rule live in `.claude/rules/net-async-mcp-rules.md`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself — the
principle and the lane boundaries are in `.claude/rules/net-async-mcp-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug / test anything under `lib/` | `net-async-mcp-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `net-async-mcp-release-manager` |
| POD | `net-async-mcp-doc-writer` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main agent
delegates rather than loading them. Skill sources live under `.claude/skills/` —
`getty-perl-core`, `getty-perl-release-author-getty`, `perl-release-dist-ini`,
`perl-io-async-future` and `perl-mcp` are hardlinked shared skills, `kanban-issues-karr-coordination`
from the karr source; `net-async-mcp-core` is owned by this repo.

Internal AI-to-AI work is coordinated on the repo's `karr` board (`karr board`). GitHub
Issues on `Getty/p5-net-async-mcp` are a public tracker for real users — never act on one
without explicit instruction (see the rules file).
