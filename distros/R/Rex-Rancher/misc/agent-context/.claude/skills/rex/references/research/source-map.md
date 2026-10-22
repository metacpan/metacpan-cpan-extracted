# Source map and review scope

Research date: **2026-10-09**. Source files were read through the GitHub connector.
The working environment could not clone/download dependencies; no complete local checkout
is claimed. The source lock is a research ledger, not a reproducible package-install lock.

## Evidence labels

**Documentation:** published API/POD for the indexed release. **Implementation:** the
specific methods/ranges at a pinned commit. **Practice:** original engineering guidance
derived from those contracts and general defensive design. **Tested here:** only the
checks explicitly listed in [VALIDATION.md](../../VALIDATION.md).

A source comment or a README test claim is not a test executed by this package.
An observed limitation is not a security advisory or proof of exploitability.
No complete review of every provider, native library, or extension is claimed.

## RexOps/Rex

Pinned commit: `e2d7836bb9040429b96cf79c213adc9385274c88`. CPAN snapshot: `1.16.1` (2025-07-05); repository literal: `9999.99.99_99`.

| File | Reviewed coverage | Focus |
|---|---|---|
| [lib/Rex.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex.pm) | lines 1–720 | Module loading, connection stack/local fallback, imports and feature-bundle implementation; later code not fully reviewed |
| [lib/Rex/Commands.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Commands.pm) | lines 500–670 | Task/group auth implementation and documentation; task composition additionally read in release POD |
| [lib/Rex/Commands/Run.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Commands/Run.pm) | run implementation and run/can_run/sudo POD; sudo tail partial | Quoting, status policy, guards, timeout, callbacks, notifications and report semantics |
| [lib/Rex/Exporter.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Exporter.pm) | complete | Import option contract and symbol export behavior |
| [lib/Rex/Commands/Service.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Commands/Service.pm) | lines 200–470 | Ensure and legacy action paths, return values and change reporting |
| [lib/Rex/Interface/Fs.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Fs.pm) | complete | Factory dispatch |
| [lib/Rex/Interface/Fs/SSH.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Fs/SSH.pm) | complete | SFTP metadata, Perl/exec helpers and SCP transfer branches |
| [lib/Rex/Interface/Fs/OpenSSH.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Fs/OpenSSH.pm) | complete | Metadata and SFTP transfer paths |
| [lib/Rex/Interface/Connection/OpenSSH.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Connection/OpenSSH.pm) | complete | Options/authentication, independent SFTP initialization, lifecycle and Sudo type |
| [lib/Rex/Interface/Exec/SSH.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Exec/SSH.pm) | complete | Shell/path/env wrapper and SSH2 helper delegation; delegated helper not audited |
| [lib/Rex/Interface/Exec/OpenSSH.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Exec/OpenSSH.pm) | complete | open3/waitpid and direct status normalization |

## Getty/rex-libssh

Pinned commit: `32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab`. CPAN snapshot: `0.004` (2026-09-20); repository literal: `0.005`.

| File | Reviewed coverage | Focus |
|---|---|---|
| [lib/Rex/Interface/Connection/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Connection/LibSSH.pm) | complete | Host-key defaults/precedence, authentication, timeout reset and driver type |
| [lib/Rex/Interface/Exec/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Exec/LibSSH.pm) | complete | Three-argument wrapper, buffered output, callbacks, shifted status |
| [lib/Rex/Interface/Fs/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Fs/LibSSH.pm) | complete | Exec file operations, quoting, GNU stat, glob/list limits, buffering and forced driver |
| [lib/Rex/Interface/File/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/File/LibSSH.pm) | complete | Read buffer, write channel, path quoting, limited explicit status checks |

## Getty/rex-gpu

Pinned commit: `bded1977b558c2fb6a46ae09ad2379acc5287775`. CPAN snapshot: `0.004` (2026-10-01); repository literal: `0.005`.

| File | Reviewed coverage | Focus |
|---|---|---|
| [lib/Rex/GPU.pm](https://github.com/Getty/rex-gpu/blob/bded1977b558c2fb6a46ae09ad2379acc5287775/lib/Rex/GPU.pm) | lines 1–310; tail truncated near start of gpu_setup | Public API/POD, exports, detector dispatch, connection precheck; full driver implementation not reviewed |

## Getty/rex-rancher

Pinned commit: `cb4df5cbaf6f62ff1de943cd54f0ed5c8ddc652e`. CPAN snapshot: `0.003` (2026-10-01); repository literal: `0.004`.

| File | Reviewed coverage | Focus |
|---|---|---|
| [lib/Rex/Rancher.pm](https://github.com/Getty/rex-rancher/blob/cb4df5cbaf6f62ff1de943cd54f0ed5c8ddc652e/lib/Rex/Rancher.pm) | lines 1–220 and 360–560 | Public API/POD, connection/distribution checks, server orchestration and agent POD; other helper implementations not exhaustively reviewed |

## Release documentation consulted

- [Rex](https://metacpan.org/pod/Rex)
- [Rex::Commands](https://metacpan.org/pod/Rex::Commands)
- [Rex::Commands::Run](https://metacpan.org/pod/Rex::Commands::Run)
- [Rex::Commands::File](https://metacpan.org/pod/Rex::Commands::File)
- [Rex::Commands::Pkg](https://metacpan.org/pod/Rex::Commands::Pkg)
- [Rex::Commands::Service](https://metacpan.org/pod/Rex::Commands::Service)
- [Rex::Commands::Gather](https://metacpan.org/pod/Rex::Commands::Gather)
- [Rex::Commands::Notify](https://metacpan.org/pod/Rex::Commands::Notify)
- [Rex::CMDB](https://metacpan.org/pod/Rex::CMDB)
- [Rex::Test::Base](https://metacpan.org/pod/Rex::Test::Base)
- [Rex::LibSSH](https://metacpan.org/pod/Rex::LibSSH)
- [Rex::GPU](https://metacpan.org/pod/Rex::GPU)
- [Rex::Rancher](https://metacpan.org/pod/Rex::Rancher)
- [distribution/Rex/bin/rex](https://metacpan.org/pod/distribution/Rex/bin/rex)

## Rechecking an observation

Match your installed module and native dependency versions. Read the relevant method
in the installed file, compare to the pinned source, and run the associated backend
contract tests. Update the source lock and claim audit when behavior changes; do not
silently apply a source finding to all older or newer releases.

[Version matrix](version-matrix.md) · [Claim audit](claim-audit.md) · [Machine-readable lock](../../SOURCE_LOCK.json)
