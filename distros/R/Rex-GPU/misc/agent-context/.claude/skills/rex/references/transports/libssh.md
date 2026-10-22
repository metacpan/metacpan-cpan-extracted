# Rex::LibSSH — capabilities and implementation limits

## Scope and security baseline

Rex::LibSSH is an optional distribution, not the core SSH/libssh2 backend. It uses
Net::LibSSH/libssh and exec-based filesystem operations. The researched release is
0.004; the inspected main commit has a post-release 0.005 literal. Do not describe
that literal as an available release.

The inspected connection verifies host keys by default. An explicit per-connect
`strict_hostkeycheck` overrides `StrictHostKeyChecking` from `openssh_opt`; `no` or
`off` disables the latter. A per-connect `knownhosts` overrides `UserKnownHostsFile`.
This limited option mapping is not proof of full OpenSSH configuration compatibility.
Net::LibSSH 0.004 or newer is required for the documented verification behavior.
Unknown or changed host keys must fail before authentication in a secure test.

```perl
use Rex -feature => ['1.4'];
use Rex::LibSSH;
set connection => 'LibSSH';
# Provision and verify known_hosts separately; do not disable checking here.
```

## Important implementation differences

- **Exit status:** `_exec` writes `$exit << 8` into `$?`, unlike core OpenSSH's direct
  exit code. Preserve the raw value and compare zero/nonzero unless a pinned,
  tested adapter explicitly decodes the effective driver's status contract.
- **Streaming:** command output is read before `continuous_read` callbacks run.
  This is not a live line stream, and a callback is not proven remote cancellation.
- **Timeouts:** the connection timeout is reset to unlimited after connection so
  long channel operations can continue. Define and test a separate command deadline.
- **Portability:** Fs uses commands including GNU-style `stat -c`. Minimal shells,
  BusyBox applets, BSD utilities, and Windows need explicit capability tests.
- **Memory:** Fs upload/download and File read paths buffer whole content on the
  controller. File write uses a channel; do not incorrectly call every write a
  whole-file buffer. Neither API is an all-purpose large-object streaming design.
- **Sudo:** a normal factory can select the Sudo driver. The explicitly forced
  Fs::LibSSH `_run` path chooses Exec::LibSSH directly and bypasses that dispatch.

## File correctness boundaries

Line/whitespace-delimited listing and globbing cannot represent every valid filename.
Use trusted, absolute application paths; quoting does not prevent option injection
from a leading dash. The File implementation's read/open and write/close paths do
not show the same explicit exit-status checks as Fs upload/download. Treat this as
an inspection finding requiring failure-injection tests, not a claim that every
failed write succeeds. Verify readback and resulting application behavior.

**Practice:** test this backend as its own platform combination. Run the contract
matrix with denied writes, full storage, non-ASCII bytes, large output, nonzero exit,
sudo, and SFTP disabled before standardizing on it. Do not silently change transports
in production to suppress an exception.

## Evidence and scope

- [lib/Rex/Interface/Connection/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Connection/LibSSH.pm)
- [lib/Rex/Interface/Exec/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Exec/LibSSH.pm)
- [lib/Rex/Interface/Fs/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Fs/LibSSH.pm)
- [lib/Rex/Interface/File/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/File/LibSSH.pm)
- [Rex::LibSSH (release documentation)](https://metacpan.org/pod/Rex::LibSSH)
