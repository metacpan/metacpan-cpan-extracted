# Fleet rollouts, concurrency, and recovery plans

## A recommended workflow, not a built-in transactional engine

Rex tasks, groups, hooks, and parallel execution are building blocks. They do not
automatically supply health-gated deployment waves, rollback, approval, or a durable
state machine. Design those policies explicitly in the orchestration layer.

Start with an immutable target snapshot and approved desired-state version. Perform
read-only preflight on all selected hosts, report unsupported or unreachable hosts,
and stop or exclude them according to an explicit policy. Apply to one canary,
verify application health and unchanged reapplication, then proceed in bounded waves.
For a quorum service, derive the wave size from its availability constraints rather
than from the controller CPU count.

## Define barriers and ownership

A per-host sequence might be preflight → drain → stage → validate → apply → activate
→ health → rejoin. Each arrow needs a success condition and a timeout/reconciliation
path. A batch of "stage all, then restart all" tasks is not equivalent to this
per-host sequence. A concurrent central controller and ad-hoc laptop run can also
race; define who holds the deployment lease and what stale-lease recovery means.

Do not use a shared package variable to aggregate worker results. Use per-host
structured records and an explicit aggregation step. A lock on the controller does
not necessarily protect a target from another controller. A target lock should
have a defined owner, operation ID, lifetime, and safe recovery policy.

## Recovery and scale

**Practice:** classify steps as reversible, resumable, or irreversible. Store the
last verified stage without embedding secrets. On reconnect, re-observe reality;
a stored stage is not proof that a process or node stayed healthy. Preserve old
artifacts until the rollback window closes. Plan for a controller failure midway
through a remote installer and for a host reboot that changes its SSH key or address.

Bound concurrency against remote package mirrors, bastions, authentication services,
controller memory, output volume, and application availability. A transport that
buffers whole outputs can multiply memory use across workers. Tune from measured
stage durations and failure rates, not a single-host benchmark.

Before production, inject a canary failure and prove later waves do not start.
Inject an unreachable node and verify partial success is reported honestly. Test
rollback/recovery independently from the happy-path installation.

## Evidence and scope

- [Rex::Commands (release documentation)](https://metacpan.org/pod/Rex::Commands)
- [lib/Rex/Commands/Run.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Commands/Run.pm)
- [lib/Rex/Interface/Exec/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Exec/LibSSH.pm)
