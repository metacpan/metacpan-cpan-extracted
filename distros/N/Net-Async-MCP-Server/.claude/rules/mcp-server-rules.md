# Net::Async::MCP::Server House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their discipline from the skills
force-loaded via `briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions. When uncertain, ask rather than guess.
   Push back when a simpler approach exists. Stop when confused; name what's unclear.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code,
   comments, or formatting. Match existing style.
4. **Goal-driven execution** — Define success criteria, loop until verified.
5. **Surface conflicts, don't average them** — Contradicting patterns: pick one (more
   recent / more tested), explain why, flag the other for cleanup. Don't blend.
6. **Read before you write** — Before new code, read the seam you're touching: the
   JSON-RPC dispatch in `handle()`, the tool registry, the Stdio transport loop.
7. **Tests verify intent, not just behavior** — Reproduce a bug before fixing it; leave
   a regression test behind. A test that can't fail when the logic changes is wrong.
8. **Checkpoint after every significant step** — Summarize: done / verified / left.
9. **Match the codebase's conventions, even if you disagree** — Conformance > taste.
10. **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" is
    wrong if any were skipped — and wrong if a new test file was never gathered.
11. **A red test is a claim before it is a failure** — Before changing code to turn a
    test green, state what the test asserts and whether your fix keeps that claim or
    replaces it. If the claim is wrong, fix the claim and say so.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  code yourself — delegate to `mcp-server-worker`. Your lane: coordinate, inspect, plan,
  review diffs, run tests, edit non-behavioral docs. When in doubt, delegate.
  Why: only the `mcp-server-*` agents get their skills force-loaded via `briefing.skills`;
  you get no briefing and would touch the protocol internals with too little context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug behavior-relevant code | `mcp-server-worker` (default) |
  | Write/extend tests | `mcp-server-test-writer` |
  | POD in the house format (`=method`/`=attr`) + README.md | `mcp-server-pod-writer` |
  | Commits, `Changes`, card → done, pre-release audit | `mcp-server-release-manager` |

- **You cannot spawn subagents** (you ARE an `mcp-server-*` agent): The delegation lock
  does not apply to you — implement, refactor, debug, and test per these rules.

Behavior-relevant = the JSON-RPC dispatch and error mapping in `handle()`, the tool
registry and `call_tool` semantics, `initialize` / capability negotiation, the Stdio
transport loop, Future and error semantics, tests, performance. Pure prose docs, POD
wording, and `Changes` notes are not.

**Only `mcp-server-release-manager` commits.** A worker leaves a commit-ready tree and hands its card
to `review`; you then dispatch `mcp-server-release-manager` to cut the commit and close the card.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope —
don't invoke the `kanban-issues-karr-coordination` skill first, just use it. Git-native kanban; state lives in
`refs/karr/*`. This repo has its own board — no cross-repo handoff, but see the sibling
note below. Day-to-day:

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b --body '…'` — new ticket
- `karr edit ID -a "note"` · `--claim NAME` · `--block "why"` — update
- `karr move ID in-progress --claim NAME` — start · `karr handoff ID --claim NAME --note "…"` — to review
- mutating commands auto-sync; `karr sync --pull|--push` for explicit exchange

**Serialize board mutations when fanning out.** Parallel implementation is fine; N
concurrent `karr move`/`handoff`/`sync` calls landing together is a resource event —
collect results, then loop the board writes sequentially.

## Release — never without permission

`dzil build` / `dzil test` / `prove` are fine anytime. `dzil release` and any CPAN
upload are STRICTLY forbidden without the maintainer's explicit go-ahead — even if a
plan or TODO lists "release" as the next step. For anything heading toward release:
stop and ask.

## Public issues (GitHub) — never act without instruction

**karr** is the agent work board — internal, churned freely. **GitHub issues**
(`github.com/Getty/p5-net-async-mcp-server`) carry real humans' reports, written under
the maintainer's account. **Never act on a GitHub issue or PR on your own initiative —
not even to read it.** No listing, viewing, commenting, closing, or creating unless the
user explicitly says to handle a specific item; every write is confirmed first.

## Hazards — what actually goes wrong here

- **An untracked test file is silently skipped.** `[@Author::GETTY]` gathers via
  `Git::GatherDir`, so a new `t/*.t` that was never `git add`ed does not reach the build
  — `dzil test` then reports a green run that never executed it. `git add -N` the file as
  soon as it exists.
- **This dist implements MCP itself.** It does not use SRI's `MCP`/`MCP::Server`
  distribution; the `perl-mcp` skill describes that one and is protocol reference only.
  Don't "reuse" an API from it that this code has never called.
- **The sibling client dist is a separate repo.** `Net::Async::MCP`
  (`~/dev/p5-net-async-mcp`) is the client half these two are meant to interoperate
  with. Read it to check wire format; never edit it from this session.
- **The dispatch path is not actually concurrent.** `handle()` calls `->get` on the
  `async sub`s and the Stdio response write is a blocking `print` (k18). Treat any claim
  of concurrency here as false until that changes — full list of known gaps in
  `.claude/agents/mcp-server-worker.md`.

## Perl specifics — reference, don't restate

Module loading, cpanfile pinning, and house style: skill `getty-perl-core`. Async/Future
lifecycle: skill `perl-io-async-future`. MCP protocol surface: skill `perl-mcp`. Release
conventions: `getty-perl-release-author-getty` + `perl-release-dist-ini`. All force-loaded for
`mcp-server-*` agents — do not duplicate here.
