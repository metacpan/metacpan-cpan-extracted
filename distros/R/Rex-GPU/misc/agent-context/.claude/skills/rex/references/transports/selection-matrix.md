# Connection and operation capability matrix

## Select the actual operation path

A connection transport is not the same object as an Exec, Fs, or File driver. Sudo
can change the effective driver. Backend factories use the current connection's
reported type unless explicitly overridden. `get_sftp()` is only an accessor name:
LibSSH returns its connection wrapper from that method, not an SFTP client.

| Path | SSH / Net::SSH2 | OpenSSH / Net::OpenSSH | Rex::LibSSH | Local |
|---|---|---|---|---|
| Plain command | Exec channel, shell wrapper | System SSH channel, shell wrapper | libssh channel, shell wrapper | Controller process |
| Stat/list/type checks | Generally SFTP | Generally SFTP | Shell commands | Local filesystem |
| Low-level upload/download | SCP in inspected Unix branch; exceptions exist | SFTP put/get | Buffered file transfer via exec | Local paths |
| Remote file handle | Separate File interface | Separate File interface | Read buffer; write channel | Local file handle |
| `run` with `creates` | Fs check added | Fs check added | Fs check added | Local Fs check |
| Sudo filesystem | Effective Sudo interface; test dependencies | Effective Sudo interface; test dependencies | Factory can choose Sudo; forced LibSSH Fs bypasses it | Local privilege context |

This matrix describes inspected code paths, not a guarantee of every high-level
resource on every platform. For example, rename may execute `mv` and then use SFTP
metadata checks. A package action can invoke facts, download a local artifact, or
manage repository files even when a simple install command uses only exec.

## Capability assessment procedure

Record the exact backend and native library/client versions. Test authentication
and a harmless exec separately from `is_file`/`stat`, then an approved small transfer
and byte-for-byte readback. Repeat required operations in the real sudo context.
Test the actual target tools: a working POSIX shell does not imply GNU `stat -c`.
Do not choose a backend based solely on the hosting company or hardware model.

**Practice:** maintain a per-project capability record: required operations, supporting
backend/OS combination, test evidence, known limits, and alternative. An exec-only
workflow can avoid filesystem abstractions, but hidden `creates`, facts, or resource
calls must first be traced. Switching to LibSSH is one option for SFTP-less targets,
not an automatic or universally compatible remedy.

## Evidence and scope

- [lib/Rex/Interface/Fs.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Fs.pm)
- [lib/Rex/Interface/Fs/SSH.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Fs/SSH.pm)
- [lib/Rex/Interface/Fs/OpenSSH.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Fs/OpenSSH.pm)
- [lib/Rex/Interface/Fs/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Fs/LibSSH.pm)
