# Rex::LibSSH

Rex connection backend using Net::LibSSH (no SFTP required).

## Why This Exists

Rex's built-in `SSH` and `OpenSSH` backends hardcode SFTP for all file
operations (`file()`, `is_file()`, `stat()`, `ls()`, upload, download).
On hosts without an SFTP subsystem (common on Hetzner dedicated servers,
minimal containers), Rex crashes with:

  Can't call method "stat" on an undefined value at Rex/Interface/Fs/OpenSSH.pm line 82

Rex::LibSSH replaces all four Rex interfaces (Connection, Exec, Fs, File)
with implementations that use plain SSH exec channels only. No SFTP required.

## Usage

```perl
use Rex -feature => ['1.4'];
use Rex::LibSSH;

set connection => 'LibSSH';

task 'deploy', '10.0.0.1', sub {
  run 'uname -r';
  file '/etc/hostname', content => "myhost\n";  # works without SFTP
};
```

## Interface Modules

- `Rex::Interface::Connection::LibSSH` — SSH session lifecycle via Net::LibSSH
- `Rex::Interface::Exec::LibSSH` — command execution via SSH exec channels
- `Rex::Interface::Fs::LibSSH` — `is_file`, `stat`, `ls`, etc. via exec
- `Rex::Interface::File::LibSSH` — file upload/download via `cat`/heredoc exec

## Key Details

- `strict_hostkeycheck => 0` by default (non-interactive deploys)
- Public key auth via `Rex::Config->set_private_key` / `set_public_key`
- No SFTP subsystem needed on remote host
- Used by Rex::Rancher and Rex::GPU for Hetzner dedicated server deployments

## Dependencies

- `Net::LibSSH` (XS binding for libssh)
- `Alien::libssh` (provides the libssh C library)
- `Rex` (framework)

## Build

Uses `[@Author::GETTY]` Dist::Zilla plugin bundle.

```bash
dzil build
dzil test
```
