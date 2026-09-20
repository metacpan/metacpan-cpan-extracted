# Net::Async::WebSearch House Rules

Apply to every task in this distribution unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their conventions from the skills force-loaded
via `briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions; ask rather than guess. Push back when a
   simpler approach exists. Stop when confused; name what's unclear.
2. **Simplicity first, surgically applied** — Minimum code that solves the problem, nothing
   speculative. Touch only what you must; don't "improve" adjacent code or formatting.
3. **Goal-driven execution** — Define success criteria, loop until verified.
4. **Surface conflicts, don't average them** — Contradicting patterns: pick one (more recent
   / more tested), explain why, flag the other. Don't blend.
5. **Read before you write** — Before new code, read the orchestrator's merge/dedup path in
   `lib/Net/Async/WebSearch.pm` (`_select_providers` → `search`/`search_stream`/`search_race`
   → `_normalize_url` → RRF) and the base class `Provider.pm`. Registration, selection,
   merge and fetch are one mechanism; "looks orthogonal" is dangerous here.
6. **Tests verify intent, not just behavior** — A test that only checks a result count can't
   fail when dedup keys or RRF scoring break, which is the failure that actually reaches the
   caller. Reproduce a bug before fixing it; leave the regression test behind.
7. **A red test is a claim before it is a failure** — Before changing code to turn a test
   green, say what the test asserts and whether your fix keeps that claim or replaces it.
8. **Checkpoint and fail loud** — Summarize done / verified / left after each significant
   step. "Done" is wrong if anything was skipped silently; "tests pass" is wrong if any were
   skipped — say so.
9. **Match the codebase's conventions, even if you disagree** — Conformance > taste.

## Delegation

Depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  code yourself — delegate. Your lane: coordinate, inspect, plan, review diffs, run tests,
  manage git, edit `Changes`/`README`. When in doubt, delegate. Why: only the
  `net-async-websearch-*` agents get their skills force-loaded via `briefing.skills`; you get
  no briefing and would touch the provider mesh and the merge path with too little context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug anything under `lib/` or a provider | `net-async-websearch-worker` (default) |
  | Pre-release audit | `net-async-websearch-release-checker` |

- **You cannot spawn subagents** (you ARE a `net-async-websearch-*` agent): the lock does not
  apply — implement, refactor, debug and test per these rules.

Behavior-relevant = everything under `lib/`, the orchestrator's three modes, the provider
base class and every `::Provider::` backend, RRF merge, URL normalization/dedup, the Result
contract, the fetch pipeline, and the tests. Prose in `README.md` and `Changes` bullets are
not.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — don't
invoke the skill first, just use it. Git-native kanban; state lives in `refs/karr/*` in this
repo.

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b --body '…'` · `karr edit ID -a "note"`
  · `--claim NAME` · `karr move ID in-progress` — full surface: skill `kanban-issues-karr-cli`

Record drift and follow-up work as tickets rather than growing the current change.
**Serialize board mutations when fanning out** — parallel implementation is fine, but collect
results and then loop `karr move`/`handoff`/`sync` sequentially; N landing at once is a
resource event, not a cheap command.

## Release — never without permission

`dzil build` / `dzil test` are fine anytime. `dzil release` and any CPAN upload are STRICTLY
forbidden without the maintainer's explicit go-ahead — even if a plan or STATUS document
lists "release" as the next step. For anything heading toward release: stop and ask.

**Only the local state counts.** The CPAN-published version is never a blocker and never a
ticket — this distribution releases together with its siblings from local working state. A
dep pin or `$VERSION` ahead of what PAUSE indexed is expected; do not "fix" it or file it.

## Public issues (GitHub) — never act without instruction

`github.com/Getty/p5-net-async-websearch` is a **public tracker**. Never act on an issue or
PR there on your own initiative — not even to read it. No listing, viewing, commenting,
editing, closing or creating unless explicitly told to handle a specific item. karr is the
internal agent board; GitHub Issues carries real humans' reports written under the
maintainer's account. Every write there publishes as the maintainer.

## Hazards specific to this distribution

- **`$loop->add($ws)` is mandatory.** `Net::Async::WebSearch` is an `IO::Async::Notifier`;
  omit it and every returned Future hangs with no error. Providers are added as children with
  the parent — never `add` a provider to the loop directly.
- **Dedup and ranking hide in the URL key.** `_normalize_url` (canonicalize → strip fragment
  → strip trailing slash → lowercase) is the identity for all three modes; a change there
  silently re-buckets results and shifts RRF scores. `$RRF_K = 60` behind `rrf_k` is likewise
  load-bearing — both are public behavior, not tuning knobs to touch casually.
- **`fetch => N` is additive, never filtering.** Non-fetched results still appear without
  `$r->fetched`. `fetch_max_bytes` is enforced on the *decoded* body — `Net::Async::HTTP`
  does not cap the on-the-wire length, so a "cap" that assumes it will leak memory.
- **Live tests never run by default.** `t/50-live.t` is gated behind `TEST_WEBSEARCH_LIVE`
  and per-provider `TEST_WEBSEARCH_*` keys, deliberately so nobody hits real search APIs
  (and burns quota) by accident. The mock-driven suite is the only path; never widen a test
  to depend on a live var, never set one to make a suite "pass".
- **`our $VERSION` in all 11 modules, all identical.** This ships to CPAN, so the bundle
  rewrites every package — a per-file `$VERSION` is required and must not be collapsed to the
  main module. Every `.pm` also needs a `# ABSTRACT:` line for PodWeaver.

## Perl conventions — reference, don't restate

Module loading, dependency pinning, house style and the distribution's own architecture live
in skills `getty-perl-core`, `net-async-websearch-core`, `perl-io-async-future`,
`getty-perl-release-author-getty` and `perl-release-dist-ini` (force-loaded per lane via
`briefing.skills` — `.claude/agents/` defines which agent briefs which). Do not duplicate
that content here.
