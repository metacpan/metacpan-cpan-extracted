# Net::LibSSH House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Perl binding for libssh — SSH without SFTP dependency. Read first: `LibSSH.xs`, `typemap` and
the POD of the module you touch: in XS "looks orthogonal" is how use-after-free gets written.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `net-libssh-worker` (default) |
| Write/extend tests | `net-libssh-test-writer` |
| Write/maintain POD | `net-libssh-doc-writer` |
| Commits, `Changes`, card → done, pre-release audit | `net-libssh-release-manager` |
| Read-only research, audit, gap analysis | `net-libssh-worker` ("read-only, change nothing") |

Behavior-relevant = `LibSSH.xs`, `typemap`, object lifetime and refcounting, method contracts,
`dist.ini` wiring, the tests. POD claims belong to `net-libssh-doc-writer`; `Changes` prose is
not.

Cross-repo work (`Rex::LibSSH`, `Alien::libssh`) is a ticket on the *other* repo's board.
Public trackers here: GitHub (`Getty/p5-net-libssh`) and CPAN RT.

## Hazards

- **`dzil` is the only build path** — no hand-written `Makefile.PL` or `pkg-config` variant;
  config lives in `dist.ini`.
- **A stale `blib/` runs the previous `.so`** — recompile after touching `LibSSH.xs` or
  `typemap`.
- **In XS a segfault and a wrong return value both look like a failing `is()`** — say which
  one a red test is before turning it green.
- **The integration files `skip_all` into a green run** — without `sshd`/`ssh-keygen`,
  `t/02-integration.t`, `t/03-channel-after-close.t` and `t/04-no-sftp.t` plan zero tests —
  always state which ran.
- **`close()` NULLs the channel pointer** — later channel methods croak; read `exit_status()`
  first.
- **The session refcount chain is load-bearing** — `Channel` and `SFTP` hold `SvREFCNT_inc` on
  the session SV; breaking it crashes far away.
- **SFTP must never become mandatory** — exec-channel work without an SFTP subsystem is why
  this distribution exists; `Rex::LibSSH` needs `sftp()` to return undef, not die.
- **`LibSSH.c` is generated, never committed** — a diff containing it means someone forced it
  in.

## Perl / XS specifics — reference, don't restate

Perl style in skill `getty-perl-core`; release in `getty-perl-release-author-getty`; XS in
`net-libssh-core` and `perl-xs` (force-loaded for `net-libssh-*` agents).
