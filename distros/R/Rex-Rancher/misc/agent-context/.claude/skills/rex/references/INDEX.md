# Reference index

Read only the smallest group needed. Links below are the complete reference routing table.
The archived input is never required for normal task execution.

## Foundations

- [CLI and safe command selection](foundations/cli.md)
- [Configuration, CMDB, and template inputs](foundations/configuration-cmdb.md)
- [Execution model and locality](foundations/execution-model.md)
- [Installation, releases, and feature bundles](foundations/installation-features.md)
- [Tasks, inventory, composition, and hooks](foundations/tasks-inventory.md)

## Transports

- [Rex::LibSSH — capabilities and implementation limits](transports/libssh.md)
- [Connection and operation capability matrix](transports/selection-matrix.md)
- [Diagnosing and operating SFTP-less targets](transports/sftp-less.md)
- [SSH and OpenSSH backend distinctions](transports/ssh-openssh.md)
- [Privilege contexts and local execution](transports/sudo-local.md)

## Execution

- [Errors, timeouts, retries, and recovery](execution/errors-timeouts.md)
- [Idempotency, change detection, and notifications](execution/idempotency-notifications.md)
- [Shell quoting, injection, and data boundaries](execution/quoting.md)
- [run(), return values, and exit status](execution/run-and-status.md)

## Resources

- [Resource routing and the bounds of this skill](resources/catalog.md)
- [Facts, target tools, and platform compatibility](resources/facts-platforms.md)
- [Files, templates, byte fidelity, and ownership](resources/files-templates.md)
- [Package resources and repositories](resources/packages.md)
- [Services, activation, and health](resources/services.md)
- [Users, scheduled jobs, and administrative resources](resources/users-cron.md)

## Operations

- [Debugging and performance investigation](operations/debugging-performance.md)
- [Fleet rollouts, concurrency, and recovery plans](operations/rollouts.md)
- [Security and trust boundaries](operations/security.md)
- [Testing strategy and evidence levels](operations/testing.md)

## Extensions

- [Backend internals and extension contracts](extensions/backend-internals.md)
- [Optional ecosystem and companion skills](extensions/ecosystem.md)
- [Optional Rex::GPU integration](extensions/gpu.md)
- [Reusable module authoring and exports](extensions/module-authoring.md)
- [Optional Rex::Rancher integration](extensions/rancher.md)

## Research

- [Audit of the supplied Rex skill](research/claim-audit.md)
- [Source map and review scope](research/source-map.md)
- [Version and evidence matrix](research/version-matrix.md)
