# Rex::LibSSH House Rules

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
4. **Read the caller before you change the callee** — This distribution implements
   Rex's interfaces, and `Rex::Interface::*::Base` is almost entirely
   `die("Must be implemented")` stubs. The real contract lives in the sibling
   implementations and in `Rex::Commands::{Run,Fs,File}` under `~/perl5/lib/perl5/Rex/`.
5. **Tests verify intent, not just behavior** — Reproduce a bug before fixing it; leave
   a regression test behind. A test that never opens an SSH connection is not a test of
   this distribution.
6. **Match the codebase's conventions, even if you disagree** — Conformance > taste.
   Surface a harmful convention; don't fork silently.
7. **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" is
   wrong if any were skipped. Surface uncertainty, don't hide it.
8. **A red test is a claim before it is a failure** — Before changing code to turn a
   test green, say what the test asserts and whether your fix keeps that claim or
   replaces it. If the claim is wrong, fix the claim and say so.

## Delegation

Depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  code yourself — delegate. Your lane: coordinate, inspect, plan, review diffs, run
  tests, manage git, edit non-behavioral docs. Why: only the `rex-libssh-*` agents get
  their skills force-loaded via `briefing.skills`; you get no briefing and would touch
  code that runs shell commands on production servers with too little context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug anything under `lib/` | `rex-libssh-worker` (default) |
  | Write/extend tests, reproduce connection failures | `rex-libssh-test-writer` |
  | Pre-release audit | `rex-libssh-release-checker` |
  | POD | `rex-libssh-doc-writer` |

- **You cannot spawn subagents** (you ARE a `rex-libssh-*` agent): The delegation lock
  does not apply — implement, refactor, debug and test per these rules.

Behavior-relevant = anything under `lib/`, the tests, and any change to a return
convention, `$?`, an emitted shell command, path quoting, the connection or auth
sequence, or a timeout. `README.md` and `Changes` wording are not.

## The blast radius is a remote root shell

Every method here emits a shell command that runs on someone else's server, usually as
root: `Rex::GPU` and `Rex::Rancher` drive Hetzner dedicated machines through this
backend. A mis-quoted path in `Fs::LibSSH`, a `File::LibSSH` write that never commits,
or an `rm -f` built from an unescaped variable does damage no local test reproduces.
`_q()` single-quotes every interpolated path — except `glob`'s pattern, which must stay
unquoted to expand remotely. That asymmetry is the security-relevant line in this
distribution; when a change touches it, say what an odd path (spaces, quotes, `$`,
newline) does to the emitted command.

## Rex resolves this code by string, at runtime

`Rex::Interface::{Exec,Fs,File}::create` builds a class name from
`get_connection_type` and `eval "use $class_name"`. Renaming a module, moving a file, or
returning a different string breaks every Rexfile with `Error loading Fs interface …` —
at runtime, on the remote deploy, never at compile time. `t/00-load.t` cannot see it.
Contracts and the full dispatch path: skill `rex-libssh-core`.

## A green suite is not a proof

`t/01-rex-integration.t` is the only test that opens a connection, and it
`plan skip_all`s when `sshd` or `ssh-keygen` is missing — the suite then prints
`All tests successful` having connected to nothing. Never report green as evidence for
an interface change; state which files ran.

```bash
prove -lr t/
prove -lv t/01-rex-integration.t
```

The harness spawns a **real sshd** per test file. Don't fan out test runs in parallel:
each one forks a daemon and grabs a port, and a `DESTROY` that doesn't fire leaves it
running. Run the suite once, sequentially. `Net::LibSSH` is likewise not fork- or
thread-safe (one session per process) — relevant the moment anything here is exercised
under Rex's `parallelism`.

## Release — never without permission

`dzil build` / `dzil test` / `prove -lr t/` are fine anytime. `dzil release` and any CPAN
upload are STRICTLY forbidden without the maintainer's explicit go-ahead — even if a plan
lists "release" as the next step. Stop and ask. `Net::LibSSH` is a Getty-authored
dependency and must be pinned to its latest *released* CPAN version, never to the
unreleased `$VERSION` in `~/dev/perl/p5-net-libssh`.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope —
don't invoke the skill first, just use it. Board state lives in `refs/karr/*`.

- `karr list --compact` / `karr board` · `karr show ID` · `karr create "Title" --priority high --body '…'`
- `karr edit ID -a "note"` · `karr move ID in-progress --claim NAME` · `karr handoff ID --claim NAME --note "…"`

Serialize board mutations when fanning out: keep implementation parallel, then loop the
`karr move`/`handoff`/`sync` calls sequentially. Full command surface: skill `kanban-issues-karr-cli`.

## GitHub issues — never act without instruction

`karr` is the internal agent board, churned freely. GitHub issues on `Getty/rex-libssh`
are the **public tracker**: real people's reports, written under the maintainer's
account. Never act on one on your own initiative — not even to read it. No listing,
viewing, commenting, closing or creating unless the user explicitly says to handle a
specific issue.

## Reference, don't restate

Perl house style and cpanfile pinning: skills `getty-perl-core`, `getty-perl-release-author-getty`.
Rex idioms, connection types and command surface: skill `rex`. This distribution's
interface contracts and the Net::LibSSH channel API: skill `rex-libssh-core`. All are
force-loaded for `rex-libssh-*` agents; do not duplicate them here.
