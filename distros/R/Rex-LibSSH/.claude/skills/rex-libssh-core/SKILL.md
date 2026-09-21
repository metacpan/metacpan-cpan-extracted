---
name: rex-libssh-core
description: Load before editing Rex::LibSSH — the four Rex interfaces on Net::LibSSH exec channels, the exec() signature Rex actually calls, the channel traps, why sudo bypasses this backend.
---

# Rex::LibSSH — core

A Rex connection backend. Rex's built-in `SSH` and `OpenSSH` backends route every file
operation through SFTP; on a host whose sshd has no `Subsystem sftp`, `Rex::get_sftp()`
returns undef and Rex dies with

    Can't call method "stat" on an undefined value at Rex/Interface/Fs/OpenSSH.pm line 82

This distribution replaces all four interfaces with implementations that use nothing but
SSH exec channels. **That is the entire product**: if a code path in here ever needs
SFTP, the distribution has failed at the one thing it exists for.

Consumers: `Rex::GPU` and `Rex::Rancher` (both `recommends 'Rex::LibSSH'` in their
cpanfiles) for Hetzner dedicated servers, which ship without an SFTP subsystem.

## How Rex reaches this code

Nothing here is registered. Rex builds a class name from a string:

```perl
# Rex::Interface::{Exec,Fs,File}::create($type)
$type ||= Rex::get_current_connection()->{conn}->get_connection_type;
my $class_name = "Rex::Interface::$kind::$type";
eval "use $class_name;";
```

So `set connection => 'LibSSH'` makes Rex load `Rex::Interface::Connection::LibSSH`, and
that object's `get_connection_type` decides which Exec/Fs/File class every later call
lands in. Ours returns:

```perl
sub get_connection_type { Rex::is_sudo() ? 'Sudo' : 'LibSSH' }
```

Two consequences worth holding onto:

- **The name is the API.** Renaming a module, or returning a different string from
  `get_connection_type`, breaks dispatch at runtime with `Error loading Fs interface …`,
  never at compile time. No test that only loads modules can catch it.
- **`get_fs_connection_object` returns `$self`**, not an SFTP handle — the exec-based Fs
  needs no separate object. Rex only ever passes it around.

`Rex::is_ssh()` returns the raw `Net::LibSSH` session; that is how `Fs`, `File` and
`Exec` get at the connection. It dies-by-`or` in every one of them:

```perl
my $ssh = Rex::is_ssh() or die "LibSSH …: no active SSH connection";
```

## The exec() signature — the contract that is not in the base class

`Rex::Interface::Exec::Base::exec` is a `die("Must be implemented")` stub with no
signature, so the base class documents nothing. What `Rex::Commands::Run::run` actually
invokes, and what `Rex::Interface::Exec::SSH` implements, is **four arguments**:

```perl
sub exec { my ( $self, $cmd, $path, $option ) = @_; ... }
```

A three-argument implementation (`$self, $cmd, $option`) does not fail loudly — it binds
`$path` to the option hashref, so `$option` ends up undef and the `env` key, the
`continuous_read` callback and `_force_sh` are silently dropped. `run 'x', env => {...}`
appears to work while the environment never reaches the remote shell.

The environment routing is not ours to invent; it goes through a Rex shell wrapper,
mirroring `Exec::SSH`:

```perl
my $shell = $option->{_force_sh} ? Rex::Interface::Shell->create("Sh") : $self->shell;
$shell->set_locale("C");
$shell->path($path);
$shell->source_global_profile(1) if Rex::Config->get_source_global_profile;
$shell->source_profile(1)        if Rex::Config->get_source_profile;
$shell->set_environment( $option->{env} ) if exists $option->{env};
my $wrapped = $shell->exec( $cmd, $option );
```

**But `exec` is also called with one argument.** `Rex::Interface::Fs::Base::_exec` and
our own `Fs::LibSSH::_run` both call `$exec->exec($cmd)` — so `$path` and `$option`
arrive undef on every `is_file`, `stat`, `ls`, `mkdir` call. Any code added to `exec`
must survive that; guard with `$option &&`/`defined $path` rather than dereferencing.

## Net::LibSSH — the surface this backend uses

`Net::LibSSH` 0.002, XS over libssh (not libssh2 — that is `Net::SSH2`).

```perl
my $ssh = Net::LibSSH->new;
$ssh->option( host => $h, port => $p, user => $u, timeout => $t );
$ssh->option( strict_hostkeycheck => 0 );
$ssh->connect       or die $ssh->error;   # 1 / 0
$ssh->auth_publickey($privkey) || $ssh->auth_agent || $ssh->auth_password($pw);

my $ch = $ssh->channel;          # one channel = one command, for its whole lifetime
$ch->exec($cmd);                 # exactly once per channel
my $out = $ch->read;             # slurp stdout to EOF
my $err = $ch->read( -1, 1 );    # slurp stderr
$ch->write($data); $ch->send_eof;  # stdin, for `cat > file`
my $rc = $ch->exit_status;       # AFTER reading; -1 until the remote process exits
$ch->close;
```

Four traps in that API:

1. **`read(undef)` reads nothing.** undef numifies to 0 and the call returns an empty
   string. Pass `-1` or no argument to slurp. A `$len` threaded through from a caller
   that may be undef silently yields empty files.
2. **`exit_status` before EOF returns `-1`.** Read all output first, then ask. `-1`
   shifted into `$?` looks like a wildly wrong exit code rather than "not finished".
3. **stdout then stderr, sequentially, is safe** — libssh pumps all protocol messages
   (including stderr window adjustments) while blocking in the stdout read, so this does
   not deadlock the way a naive select loop over two pipes would. Don't "fix" it into
   interleaved reads.
4. **Not thread-safe, no fork support — one connection per process.** Rex's
   `parallelism` forks per host. Each child must build its own session; a session
   inherited across a fork is a use-after-free in C, not a Perl error.

## Invariants of the four modules

**`Connection::LibSSH`** — the timeout is set twice on purpose:

```perl
$ssh->option( timeout => $timeout );   # short: unreachable hosts must fail fast
$ssh->connect or return;
$ssh->option( timeout => 0 );          # infinite: apt-get with a DKMS build must not time out
```

libssh's `timeout` governs both connect and channel reads. Collapsing this to one value
picks a bug either way: a long connect hang, or a `run` that dies mid-provisioning.
`strict_hostkeycheck => 0` is deliberate (non-interactive deploys), documented in POD,
and is a security tradeoff — do not silently make it configurable-but-defaulting-on.

**`Exec::LibSSH`** — sets `$? = $exit << 8` after every command. Every `Fs` predicate
below reads `$?`, and `Rex::Commands::Run` exposes it to Rexfiles. If a code path
returns without setting `$?`, callers see the *previous* command's status.

**`Fs::LibSSH`** — every operation is a small shell command:

| Method | Command | Result convention |
|---|---|---|
| `is_file` | `test -f \|\| test -c \|\| test -b \|\| test -p \|\| test -S` | `$? == 0 ? 1 : undef` |
| `is_dir` / `is_readable` / `is_writable` | `test -d` / `-r` / `-w` | same |
| `stat` | `stat -c '%a %s %u %g %X %Y'` | **flat list**, not a hashref: `(mode => …, size => …, uid, gid, atime, mtime)` |
| `ls` | `ls -1a` | list, `.` and `..` filtered |
| `glob` | `echo $pattern` | **unquoted on purpose** — the remote shell expands it |
| `upload` / `download` | `cat > $remote` / `cat $remote` | dies on non-zero exit |

`stat` returning a list is what `Rex::Commands::Fs::stat` expects; wrapping it in a
hashref breaks every caller. `mode` is `sprintf '%04o', oct($mode)` — `stat -c %a`
already prints octal, so the `oct()` round-trip is what normalises `644` to `0644`.

`_q()` single-quotes and escapes embedded quotes; **every path interpolated into a
command goes through it** — except `glob`'s pattern, which must stay unquoted to expand.
That asymmetry is the security-relevant line in this distribution.

**`File::LibSSH`** — a remote filehandle over `cat`:

- `>` / `>>` open a channel running `cat > path` / `cat >> path` and keep it open;
  `write` streams into it; **`close` is what commits the file** (`send_eof`, drain,
  close). A write path that never calls `close` writes nothing and reports no error.
- `<` slurps the whole file into a local buffer at `open` time; `read`/`seek` operate on
  that buffer, not the remote.
- `write` honours `Rex::Config->get_write_utf8_files` by encoding before sending.

## What this backend does NOT do

- **No sudo.** `get_connection_type` returns `'Sudo'` under `Rex::is_sudo()`, which
  sends Rex to `Rex::Interface::Fs::Sudo` — but `Fs::LibSSH::_run` hardcodes
  `Rex::Interface::Exec->create('LibSSH')` instead of letting `create()` resolve the
  type, so an Fs operation reached from inside this class never gets sudo-wrapped.
  Known limitation, not an oversight to "just fix": routing it through the resolving
  form changes behaviour for every existing caller.
- **No `Fs::Sudo`/`File::Sudo` counterparts** ship here.
- **No streaming.** `upload`, `download` and read-mode `open` hold the whole file in
  memory on both ends.
- **No `chown`/`chmod`/`ln`/`rmdir` of our own** — those come from `Fs::Base`, which
  builds shell commands and calls `Fs::Base::_exec` (the resolving form). They work
  because `Exec::LibSSH` tolerates the one-argument call.

## Verification

```bash
prove -lr t/            # -r matters: t/lib/ holds the harness, plain -l t/ is not recursive
prove -lv t/01-rex-integration.t
```

`t/00-load.t` only checks that four modules compile. The proof is
`t/01-rex-integration.t`, which starts a **real sshd** on a free port via
`t/lib/TestSSHD.pm` — ed25519 host and client keys in a tempdir, `StrictModes no`,
`AllowUsers $current_user`, killed via `SIGTERM` in `DESTROY` — and drives `run`,
`is_file`, `is_dir`, `mkdir`, `file`, `stat`, `upload` and `download` against it.

Two things about that harness:

- It **`plan skip_all`s** when `sshd` or `ssh-keygen` is missing, and the suite then
  reports success having connected to nothing. Always say whether it ran.
- `TestSSHD` adds `Subsystem sftp` when it finds an sftp-server binary, so the test host
  usually *has* SFTP. The suite therefore cannot prove the SFTP-free claim by itself —
  it proves the exec paths work. To test the actual target environment, drop the
  `Subsystem` line (`has_sftp` is exposed for exactly this) or point at a real host
  without one.

## Conventions in this distribution

Plain `bless`, no Moo/Moose — these are Rex interface classes and follow Rex's own
shape: `sub new { my ($that,%args)=@_; bless {%args}, ref($that)||$that }`, `use base`
on the matching `Rex::Interface::*::Base`. `# ABSTRACT:` first line, `our $VERSION`
right after `package`, POD at the end of the file. `Rex::Logger::debug` for tracing,
`Rex::Logger::info(..., 'warn')` for connection failures. Everything else: skill
`getty-perl-core`. Rex's own idioms, connection types and command surface: skill `rex`.
