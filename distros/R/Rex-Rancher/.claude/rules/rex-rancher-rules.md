# Rex::Rancher House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their conventions from the skills
force-loaded via `briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions. When uncertain, ask rather than guess.
   Push back when a simpler approach exists. Stop when confused; name what's unclear.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code,
   comments or formatting. Match existing style.
4. **rke2 and k3s move together** — Every install module branches on `distribution`. A
   change to one distribution's paths, ports, service name or install URL wants the k3s
   counterpart in the same edit. A half-change ships a cluster that only comes up on one.
5. **Tests verify intent, not just behavior** — Reproduce a bug before fixing it; leave a
   regression test behind where a test can even reach it (see below — most of this dist
   can't be unit-tested).
6. **Match the codebase's conventions, even if you disagree** — Conformance > taste.
   Surface a harmful convention; don't fork silently.
7. **Fail loud** — "Done" is wrong if anything was skipped silently. Surface uncertainty.

## Delegation

Depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  code yourself — delegate. Your lane: coordinate, inspect, plan, review diffs, run tests,
  manage git, edit non-behavioral docs. Why: only the `rex-rancher-*` agents get their
  skills force-loaded via `briefing.skills`; you get no briefing and would touch code that
  provisions production clusters over SSH with too little context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug anything under `lib/` | `rex-rancher-worker` (default) |
  | Pre-release audit | `rex-rancher-release-checker` |

- **You cannot spawn subagents** (you ARE a `rex-rancher-*` agent): The delegation lock
  does not apply — implement, refactor, debug and test per these rules.

Behavior-relevant = anything under `lib/`, the tests, and any change to the pipeline step
order, an install command, an `auto_die` decision, the kubeconfig patch, a `config.yaml`
key, or a `K8s.pm` API object. `README.md` and `Changes` wording are not.

## The blast radius is a remote root shell driving a cluster

Every install function runs an OS installer, `modprobe`, `swapoff` and `systemctl` on a
remote host as root, then drives its Kubernetes API. A wrong step order or a swallowed
error leaves a half-provisioned node, not a red test. The `auto_die => 0` sites are
deliberate — the Cilium "cannot re-use a name" swallow (now only without a kubeconfig),
the RKE2 `command -v rke2` verify, the unattended-upgrades stop before `apt-get` — each
exists because the strict version broke a real deploy. Don't tighten one without naming the failure it re-opens. Details:
skill `rex-rancher-core`.

## A green suite proves the pure logic, not a deploy

`t/` holds a compile check (`t/00-load.t`) and offline unit tests with `run` faked.
There is no integration test and no way to exercise a real install without a throwaway host. Never
report green as evidence for a pipeline change; a change to install ordering, the
`127.0.0.1` kubeconfig patch, or a `K8s.pm` object is only trustworthy after a live run
against a real node (`eg/hetzner-gpu.Rexfile`).

```bash
prove -lr t/
```

## Release — never without permission

`dzil build` / `dzil test` / `prove -lr t/` are fine anytime. `dzil release` and any CPAN
upload are STRICTLY forbidden without the maintainer's explicit go-ahead — even if a plan
lists "release" as the next step. Stop and ask. `Kubernetes::REST`, `IO::K8s` and
`Rex::LibSSH` are Getty-authored; if pinned, pin to the latest *released* CPAN version,
never to an unreleased `$VERSION` in a local `~/dev` checkout.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — don't
invoke the skill first, just use it. Board state lives in `refs/karr/*`.

- `karr list --compact` / `karr board` · `karr show ID` · `karr create "Title" --priority high --body '…'`
- `karr edit ID -a "note"` · `karr move ID in-progress --claim NAME` · `karr handoff ID --claim NAME --note "…"`

Serialize board mutations when fanning out: keep implementation parallel, then loop the
`karr move`/`handoff`/`sync` calls sequentially. Full command surface: skill `kanban-issues-karr-cli`.

## GitHub issues — never act without instruction

`karr` is the internal agent board, churned freely. GitHub issues on `Getty/rex-rancher`
are the **public tracker**: real people's reports, written under the maintainer's account.
Never act on one on your own initiative — not even to read it. No listing, viewing,
commenting, closing or creating unless the user explicitly says to handle a specific issue.

## Reference, don't restate

Perl house style and cpanfile pinning: skills `getty-perl-core`,
`getty-perl-release-author-getty`. Rex idioms and connection types: skill `rex`.
RKE2/K3s, Cilium and GPU domain knowledge: skills `kubernetes-rke2`,
`kubernetes-cilium-concepts`, `kubernetes-gpu`. This distribution's pipeline invariants:
skill `rex-rancher-core`. All are force-loaded for `rex-rancher-*` agents; do not
duplicate them here.
