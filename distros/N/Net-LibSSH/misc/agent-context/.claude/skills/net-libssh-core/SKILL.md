---
name: net-libssh-core
description: Load before editing Net::LibSSH — what this distribution's three XS object types are, the generation counter that survives disconnect(), the API contracts Rex::LibSSH depends on, and the dzil-only build path.
metadata:
  type: project
---

# Net::LibSSH — core architecture

This skill is loaded into every `net-libssh-*` agent's context before its first turn; do not
duplicate its content in the agent body. **The general Perl/C boundary rules live in `perl-xs`**
— magic objects and their free hooks, typemap syntax and its escaping trap, refcounting,
`XSRETURN_UNDEF`, `ppport.h`, and how to test for crashes and leaks. This skill holds only the
distribution-specific part: which types exist, what libssh does that the general rules do not
cover, and the behaviour callers depend on.

## What this distribution is

An XS binding to **libssh** (`https://www.libssh.org/`) — *not* libssh2, which is what
`Net::SSH2` wraps, and not the system `ssh` binary, which is what `Net::OpenSSH` drives. The C
library comes from `Alien::libssh`.

The product claim: **commands run over SSH exec channels, and file operations are built on those
channels rather than on an SFTP subsystem.** There is no file transfer API in here — no put,
no get, no scp; `Rex::LibSSH` builds its own on top of `exec`. SFTP exists as an optional extra
and degrades to `undef` rather than dying. If a code path in here ever makes SFTP mandatory, the
distribution has lost the thing it exists for.

Downstream consumer: `Rex::LibSSH` (`../rex-libssh`), which reimplements Rex's four
connection interfaces on top of this module, for Hetzner dedicated servers whose sshd ships
without `Subsystem sftp`, and pins it in its `cpanfile` — so a behaviour change here reaches
its deploys. Upstream: `Alien::libssh` (`../p5-alien-libssh`), also Getty-authored.

## Module map

| File | Owns |
|---|---|
| `LibSSH.xs` | **all** implementation — three `MODULE`/`PACKAGE` sections in one file |
| `typemap` | the three named typemap entries; INPUT/OUTPUT for every object crossing the XS boundary |
| `lib/Net/LibSSH.pm` | `XSLoader::load`, `$VERSION`, POD for the session API. No logic. |
| `lib/Net/LibSSH/Channel.pm` | POD only — the package exists in XS, this file documents it |
| `lib/Net/LibSSH/SFTP.pm` | POD only — same |

The three `.pm` files each carry their own `our $VERSION`; there is no shared version module —
all three must move together. `LibSSH.c` is generated from `LibSSH.xs` by xsubpp and is **not**
committed.

## The three object types

| XS type | Struct | Vtable | Wraps |
|---|---|---|---|
| `Net::LibSSH` | `NLSS_Session` | `Net__LibSSH_magic` | `ssh_session` |
| `Net::LibSSH::Channel` | `NLSS_Channel` | `Net__LibSSH__Channel_magic` | `ssh_channel` |
| `Net::LibSSH::SFTP` | `NLSS_SFTP` | `Net__LibSSH__SFTP_magic` | `sftp_session` |

Each has a pointer typedef (`typedef NLSS_Session *Net__LibSSH;`) so XS signatures need no `*`,
one `typemap` entry pair, and a `svt_free` that tears the C object down. `new()`, `channel()`
and `sftp()` only ever set `RETVAL` — the typemap blesses. Never bless by hand, and never add
a `DESTROY` sub.

Two decisions worth not relitigating:

- **The typemap spells every vtable pointer out literally** instead of using one generic
  `T_MAGICEXT` entry with `&${type}_magic`. That expansion needs xsubpp's `::` → `__`
  transformation, which exists from 3.60 on; this distribution supports older toolchains, where
  the generic form emits `&Net::LibSSH_magic` and does not compile.
- **No `COUNTING_TYPE` / `DUPLICATING_TYPE` macro machinery.** Those generate `make_T`/`get_T`
  helpers for C objects that can be refcounted or duplicated; libssh has neither
  `ssh_session_up_ref` nor `ssh_session_dup`, and with three types the macros cost more than
  they save.

## The session refcount chain — do not break it

`NLSS_Channel` and `NLSS_SFTP` each hold `SV *session_sv`, incremented at construction and
released in their `svt_free`, so the `ssh_session` outlives every object opened on it. **Any new
object type that borrows the session takes the same reference** — on `SvRV(ST(0))`, the
blessed referent, never on `ST(0)`.

Through 0.002 the increment was on `ST(0)`, and only the scope-exit case survived; `undef $ssh`
and `$ssh = anything_else` both segfaulted. `t/07-refcount-chain.t` covers all three ways of
losing the variable, times both object types, each in a forked child.

## disconnect() invalidates every child — the generation counter

`ssh_disconnect()` walks `session->channels` and frees them inside libssh, so a pointer check
cannot see it: `self->channel` stays non-NULL and points at freed memory. libssh offers nothing
to ask, either — `ssh_get_status()` reports `SSH_CLOSED` for a spent session and for a
never-connected one that saw a `disconnect()` alike.

So the session counts its disconnects, each child copies the count it was born under, and
`nlss_session_stale()` compares. The rules that keep it correct:

- **`self->generation++` happens before `ssh_disconnect()`**, never after.
- **A stale child's `svt_free` skips only the C teardown.** It still `SvREFCNT_dec`s
  `session_sv` and still `Safefree`s its struct — skipping the body wholesale trades the crash
  for a leak.
- **`nlss_session_stale()` treats missing magic as stale.** A session SV that is not the one we
  stored cannot be verified, and refusing is the safe answer on both the method guard and the
  free path.
- Since 0.003 the child stores `SvRV(ST(0))`, so the magic sits on `session_sv` itself and
  `mg_findext` takes it directly — a further `SvRV()` walks off the object.

A stale child croaks `"…: session was disconnected"` — deliberately a different message from
`"channel is closed"`, so a caller can tell its own teardown from libssh's. `close()` on a stale
channel is a no-op, not a croak.

`NLSS_Session` is a three-state enum (`FRESH`, `CONNECTED`, `SPENT`) rather than a flag because
only the `CONNECTED → SPENT` transition is terminal: a connected session cannot be reconnected
afterwards, and `Newxz` gives `FRESH` for free.

## XS conventions in this file

- **`#define NEED_mg_findext` before `ppport.h`** — supplies `mg_findext` on Perl < 5.14.
- **`#define undef &PL_sv_undef`** — shorthand used throughout for returning undef.
- **No `PREINIT`.** Declare variables directly in `CODE` blocks.
- **`PROTOTYPES: DISABLE`** is written once after the first `MODULE =` line; xsubpp inherits it
  for the later packages in the same file.
- **Every channel method except `close` opens with `nlss_channel_check_open()`.** A closed
  channel has `self->channel == NULL`, and libssh absorbs a NULL channel rather than crashing on
  it: before the guard `exit_status()` returned -1 and `read()` returned `""`. The failure mode
  is a plausible wrong answer, not a segfault, so a missing guard on a new method is invisible
  in testing. `close()` is the exception — it must stay idempotent for `svt_free`.
- **`channel()`, `sftp()` and `stat()` return undef via `XSRETURN_UNDEF`**, and free the C
  resource they had already created before taking that branch.

## API contracts a caller depends on

These are behaviour, not style. Changing one is a breaking change for `Rex::LibSSH`. The traps
around them — `option()`, `read()`, `exit_status()`, `close()`, `disconnect()` — are in
`net-libssh-hazards`.

- **`sftp()` returns `undef`, never dies**, when the server has no SFTP subsystem. This is the
  documented detection mechanism downstream.
- **`stat()` returns `undef`** for a missing or inaccessible path — never a half-populated
  hashref.
- **`connect()` / `auth_*()` return 1 or 0 and do not die.** The message goes through `error()`,
  which returns `undef` — not the empty string — when there is nothing to say. A refused
  port must return 0, not croak. `error()` prefers `self->own_error` over `ssh_get_error()`, so
  one message is this binding's own rather than libssh's. **`own_error` is never cleared** —
  harmless only because the single case that sets it is terminal. A second own message on a
  non-terminal path has to reset it, or it masks every libssh error from then on.
- **`option()` croaks on an unknown key, and again on a value libssh rejects.** The key set is a
  closed `strcmp` chain; extending it means extending the POD too. The key table and the
  measured strictness are in `net-libssh-hazards`.

## Build — dzil is the only path

The build is Dist::Zilla: `[@Author::GETTY]` with `xs_alien = Alien::libssh` and `xs_object =
LibSSH` in `dist.ini`. It generates a `Makefile.PL` that resolves flags via
`Alien::libssh->cflags` / `->libs`.

```bash
dzil build     # generates Makefile.PL, compiles, produces the tarball
dzil test      # the suite as it will be released
prove -lr t/   # needs a Makefile-built blib/ first
```

**There is deliberately no `Makefile.PL` in the working directory.** A hand-written one
resolving flags via `pkg-config` used to sit here; it built against whatever libssh `pkg-config`
found, which is not what the release links against, so a green local `make test` was no evidence
about the release. Don't reintroduce it — build configuration belongs in `dist.ini`, and
`dzil` overwrites any `Makefile.PL` in place anyway.

## Where the rest of the conventions live

- the API traps — `option()`, `read()`, `exit_status()`, `close()`, `disconnect()`,
  `auth_agent()` and the one libssh internal — `net-libssh-hazards`
- the general Perl/C boundary — `perl-xs`
- house style and POD — `getty-perl-core`, `getty-perl-pod`
- the house rules — `.claude/rules/net-libssh-rules.md`
