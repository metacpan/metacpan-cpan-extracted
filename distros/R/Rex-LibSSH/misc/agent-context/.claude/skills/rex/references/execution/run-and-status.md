# run(), return values, and exit status

## Return values and failure policy

In the inspected implementation, scalar `run` returns stdout, list context splits
output into lines, and a callback can receive stdout/stderr. The implementation
chomps trailing line endings from the captured streams; do not use it as a generic
binary transport or depend on POD wording such as "raw output" for byte fidelity.
When a callback is supplied, its return value becomes the return from `run`.
TTY settings affect stream separation; the 1.4 bundle includes no-tty behavior.

Choose a policy for each command. A required successful step should specify
`auto_die => 1`. An expected-failure probe should use `auto_die => 0`, immediately
capture `$?`, and classify the result. The fallback is `get_exec_autodie()`, not
`set_fail_flag`. Disabling automatic status-based exceptions does not disable
exceptions raised by the transport, filesystem, timeout setup, or callback.

```perl
my $output = run 'test', ['-d', '/opt/example'], auto_die => 0;
my $raw_status = $?;
if ($raw_status == 0) {
    # The check succeeded.
} else {
    # Investigate or branch using the known command/driver contract.
}
```

## Do not normalize blindly

| Inspected implementation | Assignment to `$?` | Example command exits 7 |
|---|---|---|
| Core Exec::OpenSSH | Wait status shifted right by 8 | Expected raw 7 |
| Extension Exec::LibSSH | Channel exit status shifted left by 8 | Expected raw 1792 |
| Run timeout branch | Sentinel 300 | Not a normal remote exit code |
| Other/effective Sudo drivers | Not established by these two observations | Must test independently |

These are pinned source observations, not live measurements from this build. A
portable wrapper should preserve raw status, driver, transport error, and timeout
classification separately. Zero/nonzero is a useful common success test for ordinary
completed commands; it does not diagnose the kind of failure. Only decode numeric
exit codes in a version-aware adapter with backend contract tests. Never assume a
value above 255 is necessarily a shifted wait status: 300 is a counterexample.

## Additional contracts

`creates` checks file existence through Fs and skips execution when present; it does
not establish that the artifact is correct. `only_if` and `unless` execute condition
commands themselves. A skipped command is not equivalent to an executed command
whose stdout was empty. `run` reports a change when it executes, even for a read-only
command, so resource reports require interpretation rather than blind counting.

## Evidence and scope

- [lib/Rex/Commands/Run.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Commands/Run.pm)
- [lib/Rex/Interface/Exec/OpenSSH.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Exec/OpenSSH.pm)
- [lib/Rex/Interface/Exec/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Exec/LibSSH.pm)
