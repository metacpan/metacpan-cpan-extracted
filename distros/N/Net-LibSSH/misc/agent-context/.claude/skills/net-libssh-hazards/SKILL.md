---
name: net-libssh-hazards
description: "Use when a Net::LibSSH change touches option(), read(), exit_status(), close() or disconnect() — the closed option key set and its measured strictness, the EOF-versus-error trap in read(), the exit_status ordering, the stale-session answers, the one libssh internal the SFTP teardown leans on and the one-command-per-channel rule."
metadata:
  type: project
---

# Net::LibSSH — the API traps

The architecture, the object types, the refcount chain and the API contracts a
caller depends on live in `net-libssh-core`. The house rules are in
`.claude/rules/net-libssh-rules.md`. This skill carries the traps around those
contracts — the ones that answer with a plausible wrong result instead of a croak.

## `option()` — a closed key set, and where libssh does the validating

`option()` croaks on an unknown key and again on a value libssh rejects. The key
set is a closed `strcmp` chain in `LibSSH.xs`; extending it means extending the POD
in the same change.

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

## `read()` cannot tell EOF from an error

`read()` with no argument (or `-1`) slurps until EOF. `read(undef)` is a trap:
`SvIV(undef)` is 0, so it takes the fixed-length branch with length 0, reads
nothing and returns the empty string. Both branches end on `ssh_channel_read() <= 0`
and yield a string either way, so **`read()` cannot distinguish EOF from a read
error** — neither returns undef, neither croaks. Documented in the POD; keep it
documented.

## `exit_status()` returns -1 until the remote process has exited

The POD tells callers to drain the output first, but that is advice, not a
requirement: on libssh 0.10.6, `ssh_channel_get_exit_status()` pumps the
session's packet loop itself, so calling it first returns the right code and
leaves the undrained output buffered for a later `read()`. Measured in
`t/06-exit-status-ordering.t`, which guards every such call with `alarm()`
precisely because a libssh build that blocks instead would hang the suite rather
than fail it. Treat the drain-first order as the supported one.

## `close()` NULLs the channel — every other method croaks

`close()` sets `self->channel = NULL`; every other channel method croaks from
then on. The message is `"<fully qualified method>: channel is closed"`.
`exit_status()` must still be read *before* `close()` — it now fails loudly
instead of returning -1, which a caller cannot tell apart from "the process has
not exited yet". `close()` itself is idempotent and deliberately unguarded,
because `svt_free` walks the same path when the SV is collected.

## A spent session answers "session was disconnected"

A connected session is spent by `disconnect()`, and `connect()` afterwards returns
0 immediately. Since 0.003 the SPENT state is checked before libssh is called at
all, and `error()` reads `session was disconnected and cannot be reconnected`. Left
to libssh, `ssh_connect()` waits out the full timeout and then reports `Timeout
connecting to <host>`, which names the wrong problem. Note what did *not* become
terminal: `disconnect()` on a session that was never connected leaves it fully
connectable — measured on libssh 0.10.6 — and only the `CONNECTED → SPENT` transition
spends it. What a stale child answers is in `net-libssh-core`.

## The one place that touches a libssh internal

`nlss_sftp_free` sets `self->sftp->channel = NULL` before `sftp_free()` when the
session was disconnected. `ssh_disconnect()` frees the sftp session's channel but
not the struct around it, so skipping `sftp_free()` entirely would trade the
crash for a leak (~1.6 kB per dropped object). libssh declares
`struct sftp_session_struct` in its public `sftp.h`, so this breaks as a compile
error rather than silently — but it is the only thing here that depends on a
libssh internal, and it is what to check first when a new libssh fails to build.

## Two silent fallbacks

- **`auth_agent()` silently falls back to `ssh_userauth_publickey_auto`** when the
  agent is missing or refuses. A return of 1 is not evidence that an agent was used.
- **A channel runs one command per lifetime.** `exec` is called once; a second
  command needs a new `$ssh->channel`.

## Not fork-safe, not thread-safe

One session per process, as the POD says.

## Where the rest of the conventions live

- the architecture, the object types, the refcount chain, the API contracts —
  `net-libssh-core`
- the general Perl/C boundary — `perl-xs`
- house style and POD — `getty-perl-core`, `getty-perl-pod`
- the house rules — `.claude/rules/net-libssh-rules.md`
