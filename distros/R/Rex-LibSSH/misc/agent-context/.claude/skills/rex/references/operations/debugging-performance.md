# Debugging and performance investigation

## Diagnose one layer at a time

Capture the exact command, task, selected host, controller Perl/Rex, extension and
native-library versions, effective drivers, and first failing operation. Prefer a
small reproduction over a full deployment. Separate host resolution/trust/auth,
plain exec, filesystem metadata, content transfer, sudo, provider selection, and
application health. Preserve the original exception and raw status.

If exec works and stat fails, inspect filesystem initialization. If only sudo fails,
probe the effective sudo driver and remote dependencies. If a task unexpectedly
runs locally, inspect target selection, top-level calls, and task composition.
If command status is surprising, check the actual Exec driver before shifting `$?`.
An `<> line` suffix does not establish a native crash.

## Observe without leaking or perturbing too much

Use debug/profiling flags only with sanitized inputs and bounded capture. Debug
paths can print command strings, output, and constructor options. Do not repeatedly
run a destructive deployment merely to obtain more verbose logs. Add read-only
preflight tasks or a targeted adapter reproduction instead.

The shipped inventory script only scans candidate module files; for a trusted
runtime, also inspect loaded `%INC` paths to detect shadowing and record native
client/library versions. A module version printed by one Perl does not establish
what a different service account or CI executable loaded.

## Attribute latency before changing parallelism

**Practice:** measure DNS/connection/authentication, fact gathering, metadata round
trips, transfer bytes, package index refresh, command runtime, service stabilization,
and controller serialization separately. Cache stable facts per run, batch work
only where semantics permit, and avoid a remote round trip for every line in a file.
Do not trade correct quoting, explicit checks, or target isolation for speed.

Measure peak controller memory as well as elapsed time. Inspected LibSSH command
and read paths buffer data, so many noisy parallel commands can exhaust memory.
Its continuous-read callbacks are not live streaming in the pinned implementation;
a UI waiting for such callbacks may appear frozen although the command is running.

Set a baseline with one host and one worker. Increase concurrency in measured steps
while tracking errors, target availability, mirror/bastion saturation, and memory.
Record p50/p95 stage durations only from actual samples; do not invent performance
numbers from implementation inspection.

## Evidence and scope

- [lib/Rex/Commands/Run.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Commands/Run.pm)
- [lib/Rex/Interface/Connection/OpenSSH.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Connection/OpenSSH.pm)
- [lib/Rex/Interface/Exec/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Exec/LibSSH.pm)
- [lib/Rex/Interface/Fs/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Fs/LibSSH.pm)
- [distribution/Rex/bin/rex (release documentation)](https://metacpan.org/pod/distribution/Rex/bin/rex)
