# Net::Async::Kubernetes House Rules

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
   Kubernetes::REST request-building calls, the duplex transport, `t/lib/`.
7. **Tests verify intent, not just behavior** — Reproduce a bug before fixing it; leave
   a regression test behind. A test that can't fail when the logic changes is wrong.
8. **Checkpoint after every significant step** — Summarize: done / verified / left.
9. **Match the codebase's conventions, even if you disagree** — Conformance > taste.
10. **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" must
    say which mode ran (mock or live) — see hazards below.
11. **A red test is a claim before it is a failure** — Before changing code to turn a
    test green, state what the test asserts and whether your fix keeps that claim or
    replaces it. If the claim is wrong, fix the claim and say so.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  code yourself — delegate to `nak-worker`. Your lane: coordinate, inspect, plan, review
  diffs, run tests, manage git, edit non-behavioral docs. When in doubt, delegate. Why:
  only the `nak-*` agents get their skills force-loaded via `briefing.skills`; you get
  no briefing and would touch the async internals with too little context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug behavior-relevant code | `nak-worker` (default) |
  | Write/extend tests (mock harness, dual-mode) | `nak-test-writer` |
  | Pre-release audit | `nak-release-checker` |
  | POD in the house format (`=attr`/`=method`) | `nak-pod-writer` |

- **You cannot spawn subagents** (you ARE a `nak-*` agent): The delegation lock does not
  apply to you — implement, refactor, debug, and test per these rules.

Behavior-relevant = the request/response pipeline (Kubernetes::REST seam, IO::K8s
inflation), Watcher reconnect and resourceVersion handling, the Controller runtime
(workqueue, reconcile dispatch), the websocket duplex transport (exec/attach/
port-forward/cp), TLS/kubeconfig/PEM handling, error and Future semantics, tests,
performance. Pure prose docs, POD wording, and `Changes` notes are not.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope —
don't invoke the `kanban-issues-karr-cli` skill first, just use it. Git-native kanban; state lives in
`refs/karr/*`; this repo has its own board (single distribution — no cross-repo
handoff). Day-to-day:

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
(`github.com/Getty/p5-net-async-kubernetes`) carry real humans' reports, written under
the maintainer's account. **Never act on a GitHub issue or PR on your own initiative —
not even to read it.** No listing, viewing, commenting, closing, or creating unless the
user explicitly says to handle a specific item; every write is confirmed first.

## Hazards — what actually goes wrong here

- **Live tests mutate a real cluster.** With `TEST_KUBERNETES_REST_KUBECONFIG` set, the
  same `t/*.t` files run against whatever cluster that kubeconfig points to — creating
  and deleting real resources. Only ever point it at a disposable cluster (minikube).
  Never set it on your own initiative; unset, the suite runs mock-only, so always
  report *which mode* was green.
- **Getty-dist version trap.** `Kubernetes::REST` and `IO::K8s` are Getty dists: the
  repo `$VERSION` is always one ahead of CPAN, so a version copied from a sibling repo
  into `cpanfile` is uninstallable. Pin to the released version (`cpanm --info`) — full
  rule in skill `getty-perl-core`.

## Perl specifics — reference, don't restate

Module loading, cpanfile pinning, and house style: skill `getty-perl-core`. Async/Future
lifecycle: skill `perl-io-async-future`. K8s API usage: skills `perl-kubernetes-rest` +
`perl-io-k8s-kubernetes-classes`. Release conventions: `getty-perl-release-author-getty` +
`perl-release-dist-ini`. All force-loaded for `nak-*` agents — do not duplicate here.
