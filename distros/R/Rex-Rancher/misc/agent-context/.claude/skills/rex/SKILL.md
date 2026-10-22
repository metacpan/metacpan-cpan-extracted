---
name: rex
description: Author, review, debug, and safely operate Perl Rex automation, Rexfiles, tasks, inventory, CMDB, resources, SSH/OpenSSH/LibSSH transports, sudo, modules, and optional Rex::GPU or Rex::Rancher integrations. Use for Rex execution semantics, filesystem/SFTP failures, idempotency, deployment, testing, and backend-level source investigation.
---

# Rex automation

## Working contract

Use this skill for the Perl automation framework, not unrelated products named Rex.
Identify the installed release, enabled feature flags, active connection, effective
Exec/Fs/File drivers, target OS, privilege context, and intended change scope first.
The researched baseline is Rex 1.16.1; repository observations are separately pinned
in [SOURCE_LOCK.json](SOURCE_LOCK.json). A development checkout is not a CPAN release.

Read only the relevant route below. Consult [the reference index](references/INDEX.md)
for narrower questions. Do not load the entire reference tree or the archived skill.

## Mandatory safeguards

1. A Rexfile is executable Perl. Inspect it before task listing, compilation, or execution;
   all can load code. Keep managed-host actions inside tasks, not at file load time.
2. Prove locality. No host can mean local execution; `run_task` has its own locality rules.
   Stop a remote-only task when `Rex::is_local()` is true. Confirm the resolved host set.
3. Keep host-key verification enabled. Obtain trusted fingerprints independently;
   `ssh-keyscan` alone does not establish server identity. Never "fix" failures by
   silently disabling verification, changing the transport, or forcing a lock.
4. Classify operations, not command names: exec, metadata, file handles, transfer,
   sudo, external tools. A successful `run 'true'` does not validate filesystem access.
5. Use `auto_die => 1` for required command success, or capture `$?` immediately after
   `auto_die => 0`. Zero/nonzero is portable across inspected backends; numeric decoding
   is not. Do not unconditionally shift `$?`; preserve raw status and driver identity.
6. Argument arrays are shell-quoted arguments, not shell-free `execve`. Keep the
   executable trusted; avoid interpolated shell programs and validate option operands.
7. Build repeatability explicitly. A marker file is not proof of a valid deployment;
   notifications are not a dependency scheduler; a running service is not application health.
8. Keep secrets out of code, command lines, debug output, reports, diffs, and fixtures.
   Authorize destructive actions separately. Define recovery before first mutation.
9. Do not claim a universal dry-run. `rex -c` enables caching; it is not check mode.
10. Distinguish documented behavior, pinned implementation observations, recommendations,
    and actual test results. Never turn an untested example into a compatibility claim.

## Read by task

| Task | Read first | Then, only as needed |
|---|---|---|
| New Rexfile or existing-project entry | [Execution model](references/foundations/execution-model.md) | [Installation and features](references/foundations/installation-features.md), [CLI](references/foundations/cli.md) |
| Groups, environments, task composition | [Tasks and inventory](references/foundations/tasks-inventory.md) | [CMDB](references/foundations/configuration-cmdb.md), [Rollouts](references/operations/rollouts.md) |
| Backend selection or SFTP failure | [Capability matrix](references/transports/selection-matrix.md) | [OpenSSH/SSH](references/transports/ssh-openssh.md), [SFTP-less procedure](references/transports/sftp-less.md) |
| Rex::LibSSH behavior | [LibSSH](references/transports/libssh.md) | [Source audit](references/research/claim-audit.md), [Sudo/local](references/transports/sudo-local.md) |
| Commands, status, injection, timeout | [Run and status](references/execution/run-and-status.md) | [Quoting](references/execution/quoting.md), [Errors/timeouts](references/execution/errors-timeouts.md) |
| Convergent configuration | [Idempotency](references/execution/idempotency-notifications.md) | [Files](references/resources/files-templates.md), [Packages](references/resources/packages.md), [Services](references/resources/services.md) |
| Platform-dependent administration | [Facts/platforms](references/resources/facts-platforms.md) | [Users/cron](references/resources/users-cron.md), [Resource routing](references/resources/catalog.md) |
| Diagnosis, testing, performance | [Debugging](references/operations/debugging-performance.md) | [Testing](references/operations/testing.md), [Security](references/operations/security.md) |
| Reusable modules or new backends | [Module authoring](references/extensions/module-authoring.md) | [Backend internals](references/extensions/backend-internals.md) |
| GPU or RKE2/K3s automation | [GPU integration](references/extensions/gpu.md) or [Rancher integration](references/extensions/rancher.md) | [Optional ecosystem](references/extensions/ecosystem.md) |

## Default procedure

Inspect → establish versions and context → classify capabilities → read the relevant
reference → define preconditions and recovery → implement the smallest change → test
on a disposable target → verify a second run → canary → approve wider execution.
For diagnosis, stop after the read-only evidence stage unless mutation was authorized.

## Minimal remote-only example

```perl
use strict;
use warnings;
use Rex -feature => ['1.4'];

# Explicitly select the backend only after checking the target's capabilities.
set connection => 'OpenSSH';
desc 'Read the kernel name on an explicitly selected remote host';
task 'inspect_kernel', sub {
    die "Remote host required\n" if Rex::is_local();
    my $output = run 'uname', ['-s'], auto_die => 1;
    print "$output\n";
};
```

Use `rex -f Rexfile -H approved-host inspect_kernel` only after inspecting the file,
verifying host identity, and resolving credentials. The feature bundle imports the
common DSL; normal `Exporter` selective-import syntax is not Rex::Exporter's API.

## Supporting assets

[Examples](examples/README.md) distinguish runnable lab assets from design skeletons.
[Static review](scripts/audit_rexfile.py) is a heuristic, not a Perl parser or security proof.
[Offline inventory](scripts/inspect_rex.pl) reads installed module text without loading Rex.
[Validation](VALIDATION.md) states what ran and what did not.
Use the [change brief](templates/change-brief.md) for operational handoff and the
[reproduction template](templates/bug-report.md) for backend issues.
