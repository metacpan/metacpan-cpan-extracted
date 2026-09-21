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

- Host key verified against `known_hosts` by default; opt out per-connection
  with `strict_hostkeycheck => 0` or Rexfile-wide with
  `-feature => ['disable_strict_host_key_checking']` (CWE-322 fix, requires
  Net::LibSSH >= 0.004)
- Public key auth via `Rex::Config->set_private_key` / `set_public_key`
- No SFTP subsystem needed on remote host
- Used by Rex::Rancher and Rex::GPU for Hetzner dedicated server deployments

## Dependencies

- `Net::LibSSH` (XS binding for libssh)
- `Alien::libssh` (provides the libssh C library, via Net::LibSSH)
- `Rex` (framework)

Consumed downstream by `Rex::GPU` and `Rex::Rancher`, which both
`recommends 'Rex::LibSSH'` for Hetzner dedicated servers.

## Build and test

Uses `[@Author::GETTY]` Dist::Zilla plugin bundle.

```bash
prove -lr t/                        # unit + integration
prove -lv t/01-rex-integration.t    # the only test that opens a connection
dzil build
dzil test
```

`t/01-rex-integration.t` spawns a real `sshd` via `t/lib/TestSSHD.pm` and
`plan skip_all`s without `sshd`/`ssh-keygen` — the suite then reports success
having connected to nothing. Always say whether it ran.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it
yourself — principle and lane are in `.claude/rules/rex-libssh-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug anything under `lib/` | `rex-libssh-worker` (default) |
| Write/extend tests, reproduce connection failures | `rex-libssh-test-writer` |
| Pre-release audit | `rex-libssh-release-checker` |
| POD | `rex-libssh-doc-writer` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`);
the main agent delegates rather than loading them. Skill sources live under
`.claude/skills/` — `rex-libssh-core` is owned here, the rest are hardlinks
(`manage-skills sync` after a clone).
