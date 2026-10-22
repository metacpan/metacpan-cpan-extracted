# Errors, timeouts, retries, and recovery

## Model separate failure domains

Distinguish resolution/routing, host identity, authentication, command execution,
application exit status, filesystem permission, artifact validation, and post-change
health. Preserve these categories in reports. A missing file, a denied stat, and a
broken transport must not all become "not installed" followed by a reinstall.

`auto_die => 0` only suppresses the automatic exception for a nonzero command status.
Other exceptions still propagate. `auto_die => 1` exceptions can include command,
stdout, and stderr; sanitize before posting them. Do not overwrite the original
exception with a failure in logging or cleanup. Capture raw status immediately and
capture the exception separately, then restore the original failure after cleanup.

## Timeout does not mean cancelled

The inspected `run` timeout path uses a local alarm and the sentinel status 300.
It does not establish that the remote process stopped, released locks, or rolled
back partial writes. LibSSH separately resets its connection timeout after connecting.
A connection timeout is therefore not a reliable upper bound on the remote job.

**Practice:** assign deadlines to connection, individual operations, and the overall
workflow. Use a remote job supervisor or a tool-specific timeout mechanism where
needed and verify its termination behavior. After a timeout, query whether the
operation is still running before retrying. Never start a second package manager,
database migration, or installer merely because the controller stopped waiting.

## Retry policy by semantics

Retry a read-only transient probe within a bounded budget. Retry an idempotent
convergent operation only after establishing the current state. Retry a non-idempotent
operation only with an operation identifier, deduplication mechanism, or human
reconciliation. Authentication failures, changed host keys, validation failures, and
unsupported configurations are not transient errors to hide with retries.

A safe recovery record includes the last completed stage, first failed stage,
observed current state, still-running operations, rollback availability, and the
conditions under which resumption is permitted. Do not call an orchestration of
independent Rex resources transactional. A file restore cannot undo a schema change
or a kernel-driver installation.

## Error-message interpretation

A suffix such as `<> line N` can identify Perl's input-position context, not the
location of the primary error. It does not prove a native C crash. Inspect the full
Perl error, actual file/line, stack information when available, process termination
signal, and core dump evidence before assigning a cause.

## Evidence and scope

- [lib/Rex/Commands/Run.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Commands/Run.pm)
- [lib/Rex/Interface/Connection/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Connection/LibSSH.pm)
- [lib/Rex/Interface/Exec/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Exec/LibSSH.pm)
