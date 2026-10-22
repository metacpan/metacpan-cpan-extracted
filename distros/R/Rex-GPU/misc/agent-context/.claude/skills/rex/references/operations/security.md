# Security and trust boundaries

## Controller trust comes first

A Rexfile, imported Perl module, and template can run code with controller privileges.
Project-local library paths can shadow installed modules. Review the project and
its dependency provenance before loading it with credentials, even to list tasks.
Do not treat this skill's frontmatter or a static lint result as an execution sandbox.

**Practice:** separate reviewing untrusted projects from operating approved ones.
Use a restricted controller account, scoped credentials, pinned artifacts, and
reviewed module search paths. Avoid privileged execution from a writable untrusted
working directory. Do not assume compiling Perl prevents compile-time side effects.

## Verify endpoints and scope credentials

Keep SSH host-key checking enabled and use an independently verified trust source.
`ssh-keyscan` collects a candidate key but does not authenticate its owner. A changed
key requires investigation and authorized trust-store rotation, not an automatic
`known_hosts` deletion. Authentication succeeds only after endpoint identity is
established in the inspected modern LibSSH path.

Separate controller-to-host SSH access, sudo rights, repository credentials, and
Kubernetes API credentials. The controller may contact a Kubernetes API directly
while the remote host executes installers; each connection has different endpoints
and authorization. Do not send all credentials to every target.

## Treat observability as a data-exposure path

Commands, stdout/stderr, auto-die exceptions, option dumps, template diffs, and CI
artifacts can reveal secrets. Redact at the source where feasible. Avoid serializing
complete connection objects or full CMDB data. A kubeconfig can contain an admin
private key; mode 0600 and careful artifact handling matter even on the controller.

Prefer protected files or the tool's native credential facility over command-line
secrets. Define deletion and retention, avoid logging content during readback, and
use synthetic values in tests. Environment variables are still visible to some
processes and error-reporting paths; they are not automatically secret-safe.

## Authorization is independent of technical capability

Being able to run `reboot`, uninstall a cluster, replace SSH settings, or delete a
lock does not authorize it. Require a separate destructive-change decision with
scope, backups, recovery access, and a rollback/resume boundary. Never silently
weaken trust, disable signature checks, broaden sudo, or switch transports to make
a failing playbook look successful.

## Evidence and scope

- [lib/Rex.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex.pm)
- [lib/Rex/Commands/Run.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Commands/Run.pm)
- [lib/Rex/Interface/Connection/OpenSSH.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Connection/OpenSSH.pm)
- [lib/Rex/Interface/Connection/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Connection/LibSSH.pm)
- [lib/Rex/Rancher.pm](https://github.com/Getty/rex-rancher/blob/cb4df5cbaf6f62ff1de943cd54f0ed5c8ddc652e/lib/Rex/Rancher.pm)
