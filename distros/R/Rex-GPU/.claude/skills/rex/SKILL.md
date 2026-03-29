---
name: rex
description: "Rex automation framework — Rexfiles, connection types, commands, SFTP limitations, and LibSSH backend"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

## Rex Basics

Rex is a Perl automation framework. Entry point is a `Rexfile` (or any `.pm`/`.pl` via `-f`).

```perl
use Rex -feature => ['1.4'];   # ALWAYS include feature flag
use Rex::Commands::Run;        # explicit imports
use Rex::Commands::File;

desc "Short description shown in rex --tasks";
task "taskname", sub {
  run "uname -r";
};
```

Run with: `rex -f Rexfile -H host taskname`

## Connection Types

```perl
# Default (Net::SSH2 / libssh2) — supports SFTP
set connection => 'SSH';

# System OpenSSH binary (ControlMaster) — NO SFTP unless server has subsystem
set connection => 'OpenSSH';

# LibSSH (Net::LibSSH / libssh) — no SFTP required
set connection => 'LibSSH';   # use this for Hetzner dedicated and SFTP-less hosts

# Local — no SSH at all
set connection => 'Local';
```

**Critical:** `set connection => 'OpenSSH'` causes `Rex::Interface::Fs::OpenSSH` to call
`Rex::get_sftp()` for EVERY file operation. If the server has no SFTP subsystem,
`get_sftp()` returns undef and `$sftp->stat(...)` crashes:
```
Can't call method "stat" on an undefined value at Rex/Interface/Fs/OpenSSH.pm line 82
```
**Solution:** use `set connection => 'LibSSH'` (from the `rex-libssh` distribution).

## Rex::Commands — What Needs SFTP

| Command | SFTP required? |
|---------|---------------|
| `run "cmd"` | No — exec channel |
| `file "/path", content => "..."` | SSH/OpenSSH only — LibSSH works without SFTP |
| `file "/dir", ensure => 'directory'` | SSH/OpenSSH only — LibSSH works without SFTP |
| `delete_lines_matching "/file", matching => qr/x/` | SSH/OpenSSH only |
| `host_entry ...` | SSH/OpenSSH only |
| `pkg ["curl"], ensure => "present"` | No |
| `can_run("cmd")` | No |
| `operating_system()` | No |
| `is_debian()`, `is_redhat()`, `is_suse()` | No |

## Rex::Commands::Run

```perl
use Rex::Commands::Run;

my $out = run "uname -r";               # returns stdout
my $out = run "cmd", auto_die => 1;     # croaks on non-zero exit
my $out = run "cmd", auto_die => 0;     # never croaks
# Check exit code:
run "cmd", auto_die => 0;
if ($? != 0) { ... }

# Array form (no shell injection):
run 'sh', ['-c', 'echo hi'], auto_die => 0;

can_run("nvidia-smi");   # returns path if found, undef if not
```

## Rex::Commands::Gather

```perl
use Rex::Commands::Gather;

my $os      = operating_system();         # 'Debian', 'Ubuntu', 'CentOS', ...
my $version = operating_system_version(); # '12', '22.04', '8', ...
is_debian();    # true for Debian + Ubuntu
is_redhat();    # true for RHEL/Rocky/Alma/CentOS
is_suse();      # true for openSUSE/SLES
```

## Rex::Interface Architecture

```
Rex::Interface::Connection::LibSSH  — wraps Net::LibSSH (libssh) — no SFTP needed
Rex::Interface::Connection::OpenSSH — wraps system ssh binary (ControlMaster)
Rex::Interface::Connection::SSH     — wraps Net::SSH2 / libssh2
Rex::Interface::Fs::LibSSH          — file ops via exec channels — no SFTP
Rex::Interface::Fs::OpenSSH         — file ops via get_sftp() → CRASHES if undef
Rex::Interface::Fs::SSH             — same problem as OpenSSH
```

## LibSSH Backend (Rex::LibSSH)

From the `rex-libssh` distribution. Use for any host without SFTP subsystem.

```perl
use Rex -feature => ['1.4'];
use Rex::LibSSH;

set connection => 'LibSSH';

# All Rex file operations now work without SFTP:
file '/etc/hostname', content => "myhost\n";
delete_lines_matching '/etc/fstab', matching => qr/\sswap\s/;
host_entry 'myhost.internal', ip => '127.0.1.1', aliases => ['myhost'];
```

Authentication:
```perl
Rex::Config->set_private_key('/root/.ssh/id_ed25519');
Rex::Config->set_public_key('/root/.ssh/id_ed25519.pub');
```

Host key checking is disabled by default (`strict_hostkeycheck => 0`).

## Workspace Distributions

### Rex::GPU (`rex-gpu`)

```perl
use Rex::GPU;

my $gpus = gpu_detect();
# { nvidia => [{name => "RTX 4090", compute => 1}], amd => [...] }

gpu_setup(containerd_config => 'rke2');  # detect + install + configure
# containerd_config: 'rke2', 'k3s', 'containerd', 'none'
```

Sub-modules:
- `Rex::GPU::Detect` — PCI class code based detection
- `Rex::GPU::NVIDIA` — driver install (Debian/Ubuntu/RHEL/SUSE), container toolkit, containerd config

Requires `Rex::LibSSH` connection for SFTP-less hosts. Dies with a helpful message if
neither LibSSH nor a working SFTP connection is present.

### Rex::Rancher (`rex-rancher`)

```perl
use Rex::Rancher::Node;
prepare_node(hostname => 'h', domain => 'd', timezone => 'UTC');

use Rex::Rancher::Server;
install_server(distribution => 'rke2', token => '...', tls_san => ['ip']);

use Rex::Rancher::Cilium;
install_cilium(distribution => 'rke2');
```

## Common Gotchas

1. **SFTP-less hosts** — use `set connection => 'LibSSH'` (from `rex-libssh`).
   Never use `set connection => 'OpenSSH'` for hosts without SFTP.

2. **`<> line N` in error messages** is Perl's `$.` tracker from `<ARGV>`, not a
   source line number. Misleading — the actual crash is in the C stack.

3. **`$?` after `run`** — Rex sets `$?` to the remote exit code (shifted left 8).
   Check with `$? != 0` or use `auto_die => 1`.

4. **`use Rex -feature => ['1.4']`** — without this, many modern Rex behaviors
   are disabled. Always include it.

5. **`Rex::Exporter` not `Exporter`** — Rex modules use `require Rex::Exporter;
   use base qw(Rex::Exporter); use vars qw(@EXPORT);` pattern, not standard
   `Exporter`.

6. **OpenSSH ControlMaster** — `set connection => 'OpenSSH'` uses SSH
   multiplexing. The master process stays alive between task calls. Clean up
   with `ssh -O exit` if connection gets stuck.

7. **`operating_system_version()`** returns a string like `'22.04'` or `'12'`.
   Use `int(operating_system_version())` for major version integer.

8. **`pkg \@array, ensure => "present"`** — pass arrayref, not list.
   `pkg ["curl", "wget"], ensure => "present"` is correct.

9. **`auto_die => 0` is not the default** — `run "cmd"` without `auto_die`
   uses Rex's global `set_fail_flag` setting. Always be explicit in library
   code.

10. **Rex task names must not clash with imported functions** — `task 'foo'`
    overwrites imported `foo()` in the namespace. Use distinct task names.
