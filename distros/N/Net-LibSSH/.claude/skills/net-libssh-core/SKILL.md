---
name: net-libssh-core
description: Load before editing Net::LibSSH — what this distribution's three XS object types are, the generation counter that survives disconnect(), the API contracts Rex::LibSSH depends on, and the dzil-only build path.
metadata:
  type: project
---

# Net::LibSSH — core architecture

This skill is loaded into every `net-libssh-*` agent's context before its first
turn. Do not duplicate its content in the agent body.

**The general Perl/C boundary rules live in `perl-xs`** — magic-based objects and
their free hooks, typemap syntax and its escaping trap, refcounting, `XSRETURN_UNDEF`,
`ppport.h`, and how to test for crashes and leaks. This skill holds only what is
specific to this distribution: which types exist, what libssh does that the general
rules do not cover, and the behaviour callers depend on.

## What this distribution is

An XS binding to **libssh** (`https://www.libssh.org/`) — *not* libssh2, which is
what `Net::SSH2` wraps, and not the system `ssh` binary, which is what
`Net::OpenSSH` drives. The C library comes from `Alien::libssh`.

The product claim: **commands run over SSH exec channels, and file operations are
built on those channels rather than on an SFTP subsystem.** There is no file transfer
API in here — no put, no get, no scp; `Rex::LibSSH` builds its own on top of `exec`.
SFTP exists as an optional extra and degrades to `undef` rather than dying. If a code path in here ever makes SFTP
mandatory, the distribution has lost the thing it exists for.

Downstream consumer: `Rex::LibSSH` (`~/dev/perl/rex-libssh`), which reimplements
Rex's four connection interfaces on top of this module, for Hetzner dedicated
servers whose sshd ships without `Subsystem sftp`. `Rex::LibSSH` pins this
distribution in its `cpanfile`, so a behaviour change here reaches its deploys.

Upstream: `Alien::libssh` (`~/dev/perl/p5-alien-libssh`), also Getty-authored.

## Module map

| File | Owns |
|---|---|
| `LibSSH.xs` | **all** implementation — three `MODULE`/`PACKAGE` sections in one file |
| `typemap` | the three named typemap entries; INPUT/OUTPUT for every object crossing the XS boundary |
| `lib/Net/LibSSH.pm` | `XSLoader::load`, `$VERSION`, POD for the session API. No logic. |
| `lib/Net/LibSSH/Channel.pm` | POD only — the package exists in XS, this file documents it |
| `lib/Net/LibSSH/SFTP.pm` | POD only — same |

The three `.pm` files each carry their own `our $VERSION`; there is no shared
version module. All three must move together.

`LibSSH.c` is generated from `LibSSH.xs` by xsubpp and is **not** committed.

## The three object types

| XS type | Struct | Vtable | Wraps |
|---|---|---|---|
| `Net::LibSSH` | `NLSS_Session` | `Net__LibSSH_magic` | `ssh_session` |
| `Net::LibSSH::Channel` | `NLSS_Channel` | `Net__LibSSH__Channel_magic` | `ssh_channel` |
| `Net::LibSSH::SFTP` | `NLSS_SFTP` | `Net__LibSSH__SFTP_magic` | `sftp_session` |

Each has a pointer typedef (`typedef NLSS_Session *Net__LibSSH;`) so XS signatures
need no `*`, one `typemap` entry pair, and a `svt_free` that tears the C object down.
`new()`, `channel()` and `sftp()` only ever set `RETVAL` — the typemap blesses. Never
bless by hand, and never add a `DESTROY` sub.

Two decisions worth not relitigating:

- **The typemap spells every vtable pointer out literally** instead of using one
  generic `T_MAGICEXT` entry with `&${type}_magic`. That expansion needs xsubpp's
  `::` → `__` transformation, which exists from 3.60 on; this distribution supports
  older toolchains, where the generic form emits `&Net::LibSSH_magic` and does not
  compile.
- **No `COUNTING_TYPE` / `DUPLICATING_TYPE` macro machinery.** Those generate
  `make_T`/`get_T` helpers for C objects that can be refcounted or duplicated;
  libssh has neither `ssh_session_up_ref` nor `ssh_session_dup`, and with three
  types the macros cost more than they save.

## The session refcount chain — do not break it

`NLSS_Channel` and `NLSS_SFTP` each hold `SV *session_sv`, incremented at
construction and released in their `svt_free`, so the `ssh_session` outlives every
object opened on it. **Any new object type that borrows the session takes the same
reference** — on `SvRV(ST(0))`, the blessed referent, never on `ST(0)`.

Through 0.002 the increment was on `ST(0)`, and only the scope-exit case survived;
`undef $ssh` and `$ssh = anything_else` both segfaulted. `t/07-refcount-chain.t`
covers all three ways of losing the variable, times both object types, each in a
forked child.

## disconnect() invalidates every child — the generation counter

`ssh_disconnect()` walks `session->channels` and frees them inside libssh, so a
pointer check cannot see it: `self->channel` stays non-NULL and points at freed
memory. libssh offers nothing to ask, either — `ssh_get_status()` reports
`SSH_CLOSED` for a spent session and for a never-connected one that saw a
`disconnect()` alike.

So the session counts its disconnects, each child copies the count it was born
under, and `nlss_session_stale()` compares. The rules that keep it correct:

- **`self->generation++` happens before `ssh_disconnect()`**, never after.
- **A stale child's `svt_free` skips only the C teardown.** It still
  `SvREFCNT_dec`s `session_sv` and still `Safefree`s its struct — skipping the body
  wholesale trades the crash for a leak.
- **`nlss_session_stale()` treats missing magic as stale.** A session SV that is not
  the one we stored cannot be verified, and refusing is the safe answer on both the
  method guard and the free path.
- Since 0.003 the child stores `SvRV(ST(0))`, so the magic sits on `session_sv`
  itself and `mg_findext` takes it directly — a further `SvRV()` there walks off the
  object.

`NLSS_Session` is a three-state enum (`FRESH`, `CONNECTED`, `SPENT`) rather than a
flag because only the `CONNECTED → SPENT` transition is terminal: measured on libssh
0.10.6, `disconnect()` on a never-connected session leaves it fully connectable,
while a session that was connected cannot be reconnected. `Newxz` gives `FRESH` for
free.

## The one place that touches a libssh internal

`nlss_sftp_free` sets `self->sftp->channel = NULL` before `sftp_free()` when the
session was disconnected. `ssh_disconnect()` frees the sftp session's channel but
not the struct around it, so skipping `sftp_free()` entirely would trade the
crash for a leak (~1.6 kB per dropped object). libssh declares
`struct sftp_session_struct` in its public `sftp.h`, so this breaks as a compile
error rather than silently — but it is the only thing here that depends on a
libssh internal, and it is what to check first when a new libssh fails to build.

## XS conventions in this file

- **`#define NEED_mg_findext` before `ppport.h`** — supplies `mg_findext` on
  Perl < 5.14.
- **`#define undef &PL_sv_undef`** — shorthand used throughout for returning
  undef.
- **No `PREINIT`.** Declare variables directly in `CODE` blocks.
- **`PROTOTYPES: DISABLE`** is written once after the first `MODULE =` line;
  xsubpp inherits it for the later packages in the same file.
- **Every channel method except `close` opens with
  `nlss_channel_check_open()`.** A closed channel has `self->channel == NULL`,
  and libssh absorbs a NULL channel rather than crashing on it: before the guard
  `exit_status()` returned -1 and `read()` returned `""`. The failure mode is a
  plausible wrong answer, not a segfault, so a missing guard on a new method is
  invisible in testing. `close()` is the exception — it must stay idempotent for
  `svt_free`.
- **`channel()`, `sftp()` and `stat()` return undef via `XSRETURN_UNDEF`**, and free
  the C resource they had already created before taking that branch.

## API contracts a caller depends on

These are behaviour, not style. Changing one is a breaking change for
`Rex::LibSSH`.

- **`sftp()` returns `undef`, never dies**, when the server has no SFTP
  subsystem. This is the documented detection mechanism downstream.
- **`stat()` returns `undef`** for a missing or inaccessible path — never a
  half-populated hashref.
- **`connect()` / `auth_*()` return 1 or 0 and do not die.** The message goes
  through `error()`, which returns `undef` — not the empty string — when there is
  nothing to say. A refused port must return 0, not croak. `error()` prefers
  `self->own_error` over `ssh_get_error()`, so one message is this binding's own
  rather than libssh's. **`own_error` is never cleared** — harmless only because
  the single case that sets it is terminal. A second own message on a
  non-terminal path has to reset it, or it masks every libssh error from then on.
- **`auth_agent()` silently falls back to `ssh_userauth_publickey_auto`** when
  the agent is missing or refuses. A return of 1 is not evidence that an agent
  was used.
- **`option()` croaks on an unknown key, and again on a value libssh rejects.**
  The key set is a closed `strcmp` chain; extending it means extending the POD
  too.

  | key | libssh option | conversion |
  |---|---|---|
  | `host` | `SSH_OPTIONS_HOST` | `SvPV_nolen` |
  | `user` | `SSH_OPTIONS_USER` | `SvPV_nolen` |
  | `port` | `SSH_OPTIONS_PORT` | `SvUV` |
  | `knownhosts` | `SSH_OPTIONS_KNOWNHOSTS` | `SvPV_nolen` |
  | `timeout` | `SSH_OPTIONS_TIMEOUT` | `SvIV` |
  | `compression` | `SSH_OPTIONS_COMPRESSION` | `SvPV_nolen` |
  | `log_verbosity` | `SSH_OPTIONS_LOG_VERBOSITY` | `SvIV` |
  | `strict_hostkeycheck` | `SSH_OPTIONS_STRICTHOSTKEYCHECK` | `SvTRUE` |

  The Perl-side conversion is silent: `SvUV`/`SvIV` of a non-numeric string is 0,
  with a runtime warning at most. Whether that becomes an error is libssh's
  decision, and it is not uniform — measured, not inferred:

  ```
  port          => 'nonsense'   croaks: Invalid argument in ssh_options_set
  timeout       => 'nonsense'   accepted silently as 0
  log_verbosity => 'nonsense'   accepted silently as 0
  ```

  `port` only croaks because libssh rejects port 0 in particular. There is no
  validation on this side of the boundary, so do not read the croak as one.
- **`read()` with no argument (or `-1`) slurps until EOF.** `read(undef)` is a
  trap: `SvIV(undef)` is 0, so it takes the fixed-length branch with length 0,
  reads nothing and returns the empty string. Both branches end on
  `ssh_channel_read() <= 0` and yield a string either way, so **`read()` cannot
  distinguish EOF from a read error** — neither returns undef, neither croaks.
  Documented in the POD; keep it documented.
- **`exit_status()` returns -1 until the remote process has exited.** The POD
  tells callers to drain the output first, but that is advice, not a
  requirement: on libssh 0.10.6, `ssh_channel_get_exit_status()` pumps the
  session's packet loop itself, so calling it first returns the right code and
  leaves the undrained output buffered for a later `read()`. Measured in
  `t/06-exit-status-ordering.t`, which guards every such call with `alarm()`
  precisely because a libssh build that blocks instead would hang the suite
  rather than fail it. Treat the drain-first order as the supported one.
- **`close()` sets `self->channel = NULL`; every other channel method croaks
  from then on.** The message is `"<fully qualified method>: channel is
  closed"`. `exit_status()` must still be read *before* `close()` — it now fails
  loudly instead of returning -1, which a caller cannot tell apart from "the
  process has not exited yet". `close()` itself is idempotent and deliberately
  unguarded, because `svt_free` walks the same path when the SV is collected.
- **`disconnect()` invalidates every live channel and SFTP session.**
  `ssh_disconnect()` walks `session->channels` and frees them inside libssh, so
  a pointer check cannot see it — `self->channel` stays non-NULL and points at
  freed memory. The session therefore counts its disconnects, children copy the
  count they were born under, and `nlss_session_stale()` compares.
  Stale methods croak `"…: session was disconnected"`, a deliberately separate
  message from `"channel is closed"` so a caller can tell its own teardown from
  libssh's; `close()` on a stale channel is a no-op, not a croak. The
  `svt_free` paths skip only the C teardown and still release `session_sv` and
  the struct.
- **A connected session is spent by `disconnect()`, and `connect()` afterwards
  returns 0 immediately.** Since 0.003 the SPENT state is checked before libssh is
  called at all, and `error()` reads `session was disconnected and cannot be
  reconnected`. Left to libssh, `ssh_connect()` waits out the full timeout and then
  reports `Timeout connecting to <host>`, which names the wrong problem. Note what
  did *not* become terminal: `disconnect()` on a session that was never connected
  leaves it fully connectable — only the `CONNECTED → SPENT` transition spends it.
- **A channel runs one command per lifetime.** `exec` is called once; a second
  command needs a new `$ssh->channel`.
- **Not fork-safe, not thread-safe.** One session per process, as the POD says.

## Build — dzil is the only path

The build is Dist::Zilla: `[@Author::GETTY]` with `xs_alien =
Alien::libssh` and `xs_object = LibSSH` in `dist.ini`. It generates a
`Makefile.PL` that resolves flags via `Alien::libssh->cflags` / `->libs`.

```bash
dzil build     # generates Makefile.PL, compiles, produces the tarball
dzil test      # the suite as it will be released
prove -lr t/   # needs a Makefile-built blib/ first
```

**There is deliberately no `Makefile.PL` in the working directory.** A
hand-written one resolving flags via `pkg-config` used to sit here; it built
against whatever libssh `pkg-config` found, which is not what the release links
against, so a green local `make test` was no evidence about the release. Don't
reintroduce it — build configuration belongs in `dist.ini`, and `dzil`
overwrites any `Makefile.PL` in place anyway.
