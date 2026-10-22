---
name: rex-libssh-testing
description: "How Rex::LibSSH is verified — the prove commands, the integration test against a real sshd, the skip_all trap that makes an untested suite report success, and why the harness cannot prove the SFTP-free claim."
---

# Rex::LibSSH — Prüfung

Wie dieses Backend geprüft wird und was ein grüner Lauf tatsächlich belegt. Die
Modul-Verträge stehen in `rex-libssh-core`, die Net::LibSSH-Fallen in
`rex-libssh-channel`.

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
