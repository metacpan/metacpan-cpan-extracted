# Rex::LibSSH House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Rex connection backend using Net::LibSSH (no SFTP required). Read first — the caller before
the callee: this distribution implements Rex's interfaces, and `Rex::Interface::*::Base` is
almost entirely `die("Must be implemented")` stubs. The real contract lives in the sibling
implementations and in `Rex::Commands::{Run,Fs,File}` under `~/perl5/lib/perl5/Rex/`.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug anything under `lib/` | `rex-libssh-worker` (default) |
| Write/extend tests, reproduce connection failures | `rex-libssh-test-writer` |
| POD | `rex-libssh-doc-writer` |
| Commits, `Changes`, card → done, pre-release audit | `rex-libssh-release-manager` |
| Read-only research, audit, gap analysis | `rex-libssh-worker` ("read-only, change nothing") |

Behavior-relevant = anything under `lib/`, the tests, and any change to a return convention,
`$?`, an emitted shell command, path quoting, the connection or auth sequence, or a timeout.
`README.md` and `Changes` wording are not.

## Release

`Net::LibSSH` is a Getty-authored dependency and must be pinned to its latest *released* CPAN
version, never to the unreleased `$VERSION` in `../p5-net-libssh`.

## Hazards

- **The blast radius is a remote root shell.** Every method here emits a shell command that
  runs on someone else's server, usually as root: `Rex::GPU` and `Rex::Rancher` drive Hetzner
  dedicated machines through this backend. A mis-quoted path in `Fs::LibSSH`, a
  `File::LibSSH` write that never commits or an `rm -f` built from an unescaped variable does
  damage no local test reproduces. `_q()` single-quotes every interpolated path — except
  `glob`'s pattern, which must stay unquoted to expand remotely; that asymmetry is the
  security-relevant line in this distribution. When a change touches it, say what an odd
  path (spaces, quotes, `$`, newline) does to the emitted command. Details: skill
  `rex-libssh-core`.
- **Rex resolves this code by string, at runtime.** `Rex::Interface::{Exec,Fs,File}::create`
  builds a class name from `get_connection_type` and `eval "use $class_name"`. Renaming a
  module, moving a file or returning a different string breaks every Rexfile with
  `Error loading Fs interface …` — at runtime, on the remote deploy, never at compile time;
  `t/00-load.t` cannot see it. Contracts and the full dispatch path: skill `rex-libssh-core`.
- **A green suite is not a proof.** A test that never opens an SSH connection is not a test
  of this distribution. `t/01-rex-integration.t` is the only test that opens a connection,
  and it `plan skip_all`s when `sshd` or `ssh-keygen` is missing — the suite then prints
  `All tests successful` having connected to nothing. Never report green as evidence for an
  interface change; state which files ran (`prove -lr t/`, `prove -lv t/01-rex-integration.t`).
- **One sshd per test file.** The harness spawns a real sshd per test file: don't fan out
  test runs in parallel, each one forks a daemon and grabs a port, and a `DESTROY` that
  doesn't fire leaves it running. Run the suite once, sequentially. `Net::LibSSH` is likewise
  not fork- or thread-safe (one session per process) — relevant the moment anything here is
  exercised under Rex's `parallelism`.

## Perl / Rex specifics — reference, don't restate

Perl house style and cpanfile pinning: skills `getty-perl-core`,
`getty-perl-release-author-getty`. Rex idioms, connection types and command surface: skill
`rex`. This distribution's interface contracts and the Net::LibSSH channel API: skill
`rex-libssh-core`. All are force-loaded for `rex-libssh-*` agents.
