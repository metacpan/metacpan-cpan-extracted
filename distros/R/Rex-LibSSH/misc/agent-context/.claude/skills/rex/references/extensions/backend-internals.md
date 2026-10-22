# Backend internals and extension contracts

## Trace the layers instead of patching at random

The relevant path is task context → connection wrapper → effective driver selection
→ Exec/Fs/File implementation → native SSH library/client or local operations.
Factories can resolve a Sudo driver rather than the underlying transport. An explicit
factory argument can bypass that resolution. A new backend must account for all
operations the high-level DSL and providers will call, not merely implement `run`.

The connection wrapper exposes connection/authentication state and transport objects.
`get_fs_connection_object` is an extension seam; `get_sftp` forwarding does not prove
the returned object implements an SFTP protocol client. A success check that merely
receives a truthy object is not a complete capability test.

## Contracts to specify for a new backend

**Practice:** define authentication and host-key policy first, then command execution
signature, shell/env/cwd behavior, status encoding, stderr handling, streaming,
timeouts, cancellation, reconnect, and cleanup. Define separate metadata and file
handle contracts: missing vs denied access, stat representation, symlinks, filenames,
encoding, binary data, partial writes, flush/close errors, rename semantics, and
transfer memory bounds. Specify how sudo changes each of these paths.

The inspected LibSSH history illustrates why signatures matter: Exec receives
`($cmd, $path, $options)`. Losing the middle argument can silently lose environment
options. Its current status encoding differs from core OpenSSH. These are concrete
compatibility considerations, not a reason to bypass the public API everywhere.

## Review and regression process

Create a small conformance suite against each backend. Test all nonzero/error cases
before claiming parity. For large-output tests, measure memory and callback timing;
reading all output before replaying callbacks is not streaming. Test denied reads
and writes through both File and Fs because their validation can differ.

Pin the implementation during investigation, link exact methods in bug reports,
and include the failing test with any proposed change. Do not rewrite the user's
installed backend or publish a security fix as part of creating a skill unless
separately asked. This package records observations and recommended tests; it does
not patch upstream Rex, Rex::LibSSH, or any target system.

## Evidence and scope

- [lib/Rex/Interface/Fs.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Fs.pm)
- [lib/Rex.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex.pm)
- [lib/Rex/Interface/Exec/OpenSSH.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Exec/OpenSSH.pm)
- [lib/Rex/Interface/Exec/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Exec/LibSSH.pm)
- [lib/Rex/Interface/File/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/File/LibSSH.pm)
