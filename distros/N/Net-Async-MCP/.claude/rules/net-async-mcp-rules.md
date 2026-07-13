# Net::Async::MCP House Rules

Apply to every task in this distribution unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks.

## Engineering discipline

1. **Think before coding** — State assumptions explicitly. When uncertain, ask rather than
   guess. Present multiple interpretations when ambiguous. Push back when a simpler approach
   exists. Stop when confused; name what's unclear.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative. No
   abstractions for single-use code.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code, comments,
   or formatting. Match existing style.
4. **Goal-driven execution** — Define success criteria, loop until verified.
5. **Surface conflicts, don't average them** — Contradicting patterns: pick one (more
   recent / more tested), explain why, flag the other for cleanup. Don't blend.
6. **Read before you write** — Before new code, read exports, immediate callers, shared
   utilities. "Looks orthogonal" is dangerous.
7. **Tests verify intent, not just behavior** — Tests encode WHY behavior matters. A test
   that can't fail when business logic changes is wrong.
8. **Checkpoint after every significant step** — Summarize: done / verified / left. Don't
   continue from a state you can't describe back.
9. **Match the codebase's conventions, even if you disagree** — Conformance > taste. Surface
   a harmful convention; don't fork silently.
10. **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" is wrong
    if any were skipped. Surface uncertainty, don't hide it.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): do NOT touch behavior-relevant code
  in this distribution yourself — delegate to `net-async-mcp-worker`. Your lane: coordinate,
  inspect, plan, review diffs, run tests, manage git, edit non-behavioral docs (README, POD via
  `pod-writer`). Why: only `net-async-mcp-worker` gets the full Perl/MCP/IO::Async skill set
  force-loaded via `briefing.skills`; you get no briefing and would touch internals with too
  little context.
- **You cannot spawn subagents** (you ARE `net-async-mcp-worker` or similar): the delegation
  lock does not apply to you — implement, refactor, debug, and test per these rules.

Behavior-relevant = runtime behavior of the three transports (InProcess, Stdio, HTTP), the
public API, MCP protocol handling, error handling, tests, performance.

## Release — never without permission

`dzil build` / `dzil test` are fine anytime. `dzil release` and any CPAN upload are STRICTLY
forbidden without the maintainer's explicit go-ahead — even if a plan or checklist lists
"release" as the next step. For anything heading toward release: stop and ask.

## Public issues (GitHub) — never act without instruction

`Getty/p5-net-async-mcp` on GitHub is a **public tracker for real humans** — users file bug
reports and feature requests there under their own accounts. It is not an AI work queue.

**Never act on a GitHub issue on your own initiative — not even to read it.** No listing,
viewing, commenting, editing, closing, or creating unless the user explicitly tells you to
handle a specific issue. Incoming user tickets are not a queue to drain automatically; touch
them only on direct instruction, and confirm before any write since it's visible under the
maintainer's name.

## Internal (AI-to-AI) coordination — karr

For coordination that stays between agents/sessions — not user-facing — use `karr`
(git-native kanban; state lives in `refs/karr/*`), skill hardlinked at `.claude/skills/karr/`.
This is a small, single-distribution repo with no driver family and typically one agent at a
time, so a board is rarely needed in practice — reach for it when work genuinely spans
multiple sessions or subagents and needs to survive a context reset, not for routine
single-session tasks. No board is initialized here yet; run `karr init` first if one becomes
useful. Full command surface: skill `karr`.
