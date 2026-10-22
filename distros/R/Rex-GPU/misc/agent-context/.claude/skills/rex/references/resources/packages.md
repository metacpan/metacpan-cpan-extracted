# Package resources and repositories

## Declare the desired package state precisely

`pkg` supports present, absent, latest, and version-oriented state in its documented
API. `present` is not an upgrade policy; `latest` is a moving target. An arrayref is
the multi-package form used by the original skill. Confirm the installed provider's
version syntax and return behavior; package naming and dependency resolution are
provider-specific.

```perl
# Mutating example: only inside an approved task.
pkg ['curl', 'ca-certificates'], ensure => 'present';
```

Do not interpret `auto_die` on `run` as a universal setting that makes every package
resource throw on every failure. Verify the package resource and provider contracts,
then verify installed state explicitly. Record the requested version, repository
source, actual installed version, and any required reboot without treating a
successful package-manager command as application readiness.

## Separate repository configuration from installation

**Practice:** establish package sources, signing-key trust, architecture, release,
and version policy before installing. Repositories and local package files add
filesystem and transfer requirements. Package helpers may also gather platform
facts. A blanket "pkg never needs SFTP" claim is therefore unsafe even when a simple
provider executes a shell command for installation.

Do not automatically import a key fetched from the same untrusted channel as the
package or disable signature validation to resolve a failure. Use the site's
approved repository policy. Avoid embedding platform-specific shell installers in
a generic Rex skill; put them behind a checked application adapter and pin the
artifact or release selected by that adapter.

## Operational sequencing

Treat package-manager locks as evidence of concurrent work, not stale files to delete
without investigation. Bound index refreshes; refreshing once per package wastes
time and increases load. Reconcile interrupted installation before retrying. Do not
perform fleet-wide upgrades and configuration changes simultaneously without a
canary and a tested recovery path.

Test first installation, already-present state, exact-version mismatch, missing
repository, signature failure, lock contention, and post-install service behavior.
A package rollback may be unavailable or may not reverse data/configuration changes.
For drivers and kernel-related packages, plan the reboot boundary explicitly.

## Evidence and scope

- [Rex::Commands::Pkg (release documentation)](https://metacpan.org/pod/Rex::Commands::Pkg)
- [lib/Rex/Commands/Run.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Commands/Run.pm)
- [lib/Rex/GPU.pm](https://github.com/Getty/rex-gpu/blob/bded1977b558c2fb6a46ae09ad2379acc5287775/lib/Rex/GPU.pm)
