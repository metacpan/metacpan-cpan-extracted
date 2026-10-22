# Diagnosing and operating SFTP-less targets

## Work from the first failed layer

An SSH server may allow exec while lacking a usable SFTP subsystem. That is one
possible environment, not a fact implied by a provider name. Start by identifying
whether the request requires only commands or also metadata, handles, transfers,
package/repository files, templates, and sudo operations.

**Procedure:** reproduce on one authorized target using the same controller account,
backend, host key store, and identity. Run a harmless command. Next read metadata on
an existing non-secret file. If exec passes and metadata fails, inspect the SFTP
initialization and returned filesystem object. Confirm server subsystem policy and
client-side dependencies independently; do not overwrite server SSH configuration
as an automatic diagnostic step.

If both steps fail, investigate authentication, trust, routing, and shell access
before focusing on SFTP. If only privileged writes fail, diagnose escalation and
destination permissions. An empty result, permission denial, and missing file are
not equivalent states.

## Choose a remedy deliberately

| Remedy | Appropriate when | Preconditions |
|---|---|---|
| Enable/fix server SFTP | Server policy permits it and broad file management is required | Change authorization, tested SSH configuration, retained access path |
| Use an exec-only workflow | Only a few known commands are needed | Trace and remove hidden filesystem assumptions; validate quoting and exit status |
| Use Rex::LibSSH | Target supports the commands its implementation requires | Install approved versions, verify trust, test files/sudo/status/encoding |
| Use another transfer mechanism | Large artifacts or special targets exceed backend limits | Independently verify integrity, credentials, lifecycle, and resume behavior |

Do not claim `pkg`, `can_run`, or OS facts are universally SFTP-free from their names.
Trace provider calls in the installed version. In particular, `run ... creates =>`
uses the filesystem interface, even though the main command itself uses exec.

## Minimal evidence to retain

Keep the failing operation, target OS/tool capabilities, controller and backend
versions, effective Exec/Fs driver, full sanitized exception, and successful earlier
probe. Do not publish host private keys, complete connection dumps, application
configuration, or sudo secrets. Add a regression test for the actual missing
subsystem rather than a test that merely mocks `run` returning success.

## Evidence and scope

- [lib/Rex/Interface/Connection/OpenSSH.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Connection/OpenSSH.pm)
- [lib/Rex/Interface/Fs/OpenSSH.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Fs/OpenSSH.pm)
- [lib/Rex/Commands/Run.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Commands/Run.pm)
- [lib/Rex/Interface/Fs/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Fs/LibSSH.pm)
