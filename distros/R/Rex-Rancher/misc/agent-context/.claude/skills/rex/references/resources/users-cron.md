# Users, scheduled jobs, and administrative resources

## Use the appropriate resource rather than unsafe text surgery

Rex has User and Cron command modules alongside Host, Sysctl, Kernel, and filesystem
resources. Their signatures and provider behavior differ. Read the installed module
POD for the resource you will invoke; do not invent a unified `ensure` schema for
all of them or translate another configuration-management system's YAML directly.

This reference provides a design procedure, not an unverified cross-platform API
catalog. Exact user/password hashing, group membership, cron syntax, and platform
service behavior must be verified for the selected provider and current OS.

## Identity changes

**Practice:** distinguish account creation, UID/GID selection, primary group,
supplementary groups, home ownership, shell, expiration, and authorized keys.
Specify whether group membership is additive or authoritative before changing it.
Do not remove administrator access in the same unchecked step that deploys a new
login method. Keep an independently verified recovery path for SSH changes.

Never log passwords or private keys. Do not insert plaintext passwords where an API
expects a hash, or assume every platform accepts the same hash format. Prefer
explicit external secret retrieval in the approved execution stage over hardcoded
credentials in CMDB, examples, or tests.

## Scheduled work

A scheduled process has a different environment from an interactive Rex session.
Specify executable paths, user, working directory, environment, locking, time zone,
output retention, and failure reporting. Give managed jobs stable identifiers so
updates replace the intended job rather than appending duplicates. Prevent overlap
when a job exceeds its interval and decide whether skipped runs should queue.

A scheduled Rex invocation loads executable code with that account's privileges.
Pin the project and controller environment; do not pull and execute an unreviewed
branch automatically under root. Keep secrets and logs outside broadly readable
crontab text. Verify the installed schedule and a representative execution separately.

## Kernel, sysctl, and host identity

Runtime and persistent configuration are different states. Check both when changing
sysctl or kernel modules. For hostname and hosts-file updates, preserve remote access,
DNS assumptions, TLS names, and cluster identity. Treat network/firewall changes as
a separate change class with an out-of-band recovery plan, not routine housekeeping.

## Evidence and scope

- [Rex::Commands::User (release documentation)](https://metacpan.org/pod/Rex::Commands::User)
- [Rex::Commands::Cron (release documentation)](https://metacpan.org/pod/Rex::Commands::Cron)
- [lib/Rex.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex.pm)
