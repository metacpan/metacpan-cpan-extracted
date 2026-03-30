# Net::LibSSH

XS Perl binding for libssh — SSH library without SFTP dependency.

## What It Is

Net::LibSSH wraps the C libssh library (NOT libssh2). Key difference from
Net::SSH2: file operations use SSH exec channels, not SFTP. The SFTP support
is optional and returns `undef` gracefully when the subsystem is absent.

## Module Structure

- `Net::LibSSH` — session: connect, auth, channel(), sftp()
- `Net::LibSSH::Channel` — exec, read, write, send_eof, exit_status, close
- `Net::LibSSH::SFTP` — stat() (optional, undef if no SFTP subsystem)

## Usage

```perl
use Net::LibSSH;

my $ssh = Net::LibSSH->new;
$ssh->option(host => 'server.example.com');
$ssh->option(user => 'root');
$ssh->connect or die $ssh->error;
$ssh->auth_agent or die $ssh->error;

my $ch = $ssh->channel;
$ch->exec('uname -r');
print $ch->read;
print "exit: ", $ch->exit_status, "\n";
$ch->close;
```

## Build (XS)

This is an XS module — requires a C compiler and libssh headers.

```bash
# Alien::libssh provides libssh if not available system-wide
perl Makefile.PL
make
make test
```

Or via Dist::Zilla (uses `[@Author::GETTY]` bundle with `xs_alien = Alien::libssh`):

```bash
dzil build
dzil test
```

## XS Conventions

### Object lifecycle: `sv_magicext` + MGVTBL (no DESTROY needed)

Objects are stored using `sv_magicext` with a type-specific `MGVTBL` (magic
vtable). The C pointer lives in `mg->mg_ptr`; Perl's GC calls `svt_free`
automatically when the SV is collected.

```c
static int nlss_session_free(pTHX_ SV *sv, MAGIC *mg) {
    NLSS_Session *self = (NLSS_Session *)(void *)mg->mg_ptr;
    ssh_disconnect(self->session);
    ssh_free(self->session);
    Safefree(self);
    return 0;
}
static const MGVTBL Net__LibSSH_magic = { .svt_free = nlss_session_free };
```

Benefits over `sv_setref_pv` + `DESTROY`:
- **No DESTROY in XS** — `svt_free` is more reliable than `DESTROY` (fires even
  if `DESTROY` is overridden or during global destruction)
- **Strict type safety** — `mg_findext(..., &Net__LibSSH_magic)` matches only
  magic with that exact vtable address; two different types can never be confused
- **Thread-safe cleanup** — vtable is the right hook for `CLONE_PARAMS` if needed

### Typemap: INPUT via `mg_findext`, OUTPUT via `sv_magicext`

Each type gets a named typemap entry (not the generic `T_PTROBJ`):

```
Net::LibSSH          T_NET_LIBSSH
Net::LibSSH::Channel T_NET_LIBSSH_CHANNEL
Net::LibSSH::SFTP    T_NET_LIBSSH_SFTP
```

INPUT checks for magic with the correct vtable; OUTPUT creates the blessed
magic SV. `new()`, `channel()`, `sftp()` just set `RETVAL` — the OUTPUT section
handles all blessing automatically.

### Struct and typedef layout

Two layers of typedef are used:

```c
typedef struct { ssh_session session; } NLSS_Session;   /* named, for Newxz */
typedef NLSS_Session *Net__LibSSH;                       /* pointer typedef for XS */
```

`NLSS_Session` is named so `Newxz(RETVAL, 1, NLSS_Session)` has a concrete type.
`Net__LibSSH` is the pointer typedef xsubpp uses for C declarations
(`Net__LibSSH self` in generated C corresponds to `Net::LibSSH self` in XS).

### Typemap template escaping

xsubpp evaluates typemap INPUT/OUTPUT templates as **Perl double-quoted strings**.
Any `"` that should appear in generated C code must be written as `\"`.
Unescaped `"` ends the Perl string early and causes parse errors:

```
# Wrong:
sv_magicext(newSVrv($arg, "Net::LibSSH"), ...);

# Correct:
sv_magicext(newSVrv($arg, \"Net::LibSSH\"), ...);
```

### Why not generic `T_MAGICEXT` with `${type}_magic`?

`Crypt::OpenSSL3` uses a single `T_MAGICEXT` entry with `&${type}_magic` in the
template, where `${type}` gets the `::` → `__` transformation automatically.
**This only works in xsubpp ≥ 3.60** (hence their `REQUIRE: 3.60`). On xsubpp
3.45 (Perl 5.36), `${type}` is still `Net::LibSSH` (with `::`) — invalid as a C
identifier. We use per-type entries that hardcode the vtable pointers instead.

### Why not `T_PTROBJ` builtin?

`T_PTROBJ` appends `Ptr` to the type name (`Net__LibSSHPtr` instead of
`Net::LibSSH`) and uses `sv_setref_pv`/`INT2PTR` — no svt_free, no vtable-based
type checking. Don't use it.

### Why not `COUNTING_TYPE` / `DUPLICATING_TYPE` macros?

`Crypt::OpenSSL3` generates `make_T`/`get_T` helpers and vtables via macros for
its many types (`COUNTING_TYPE` for refcounted C objects, `DUPLICATING_TYPE` for
ones with a `_dup` function). Not applicable here: libssh has no
`ssh_session_dup` / `ssh_session_up_ref`, and with only three types the macro
machinery would add more complexity than it removes.

### Other rules

- **`#define NEED_mg_findext`** before `ppport.h` — provides `mg_findext` as a
  compatibility shim for Perl < 5.14.
- **`#define undef &PL_sv_undef`** — shorthand for returning undef; avoids
  repeating the literal `&PL_sv_undef` everywhere.
- **No `PREINIT`**: Declare variables directly in `CODE` blocks (C89 restriction,
  not needed on C99+ compilers).
- **`PROTOTYPES: DISABLE`**: Written once after the first `MODULE =` line;
  xsubpp inherits it for subsequent packages in the same file.
- **`VERSION_FROM`** in `Makefile.PL` (not a hardcoded `VERSION =>`): keeps
  the compiled `.so` version in sync with `lib/Net/LibSSH.pm`.

## Key Implementation Notes

- XS file is `LibSSH.xs` — generated C is `LibSSH.c` (not committed)
- `ppport.h` generated by Devel::PPPort for backwards compatibility
- SFTP `stat()` returns undef (not die) when SFTP subsystem absent — this is
  intentional and used by Rex::LibSSH to detect SFTP availability

## Dependencies

- `Alien::libssh` (build dep — provides libssh C library and headers)
