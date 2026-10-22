# Optional Rex::Rancher integration

## Two control planes of execution

Rex::Rancher automates RKE2/K3s host preparation and cluster setup. It is not a
universal guarantee about every Rancher product or Kubernetes release. The researched
CPAN version is 0.003; inspected main declares post-release 0.004.

The inspected `rancher_deploy_server` validates distribution and options, checks the
connection, and runs server preflight before node preparation and optional GPU setup.
It then installs the server, optionally saves a controller-local kubeconfig and waits
for the API, installs Cilium when enabled, and optionally deploys a device plugin.
Remote host operations and controller-to-API operations are distinct network paths.

If a saved kubeconfig cannot reach the API, the code stops before later cluster
steps, but the server may already be installed. Report that partial state accurately.
Do not describe a failed final readiness check as "nothing happened". A worker
pipeline has different options and does not install Cilium as the server does.

## Preserve cluster invariants

**Practice:** pin and validate distribution, release, cluster identity, CIDRs, CNI,
join endpoint, TLS SANs, and API reachability. Use the module's preflight and current
version-skew checks, but do not infer that a helper's existence proves every upgrade
path safe. Preserve a running cluster's network mode/pool and established identity.
An authorization error is not the same as a missing Kubernetes object.

The top-level orchestration can pass `hold_running` and other options through to
installation helpers. Verify their semantics in the installed release before
re-running an existing cluster. A CNI change, cluster CIDR change, uninstall, and
node identity reset require their own operational plan. Do not automatically clean
up stale Cilium state or delete Helm release records to make deployment continue.

## Credentials and GPU ownership

A saved kubeconfig can hold an administrative client certificate/private key. The
module documents 0600 permissions and CA retention; still protect backups, logs,
CI artifacts, and any copied file. Ensure the patched API address is reachable
from the controller and appropriate for the certificate; node-to-API routing may
require a different address choice than controller-only routing.

When using an image or GPU Operator for the driver/toolkit, the module exposes
`gpu_setup => 0`; when another owner manages the device plugin, use its documented
`gpu_device_plugin` control. Do not enable duplicate owners. GPU-enabled setup has
module-version prerequisites and real hardware tests remain necessary.

Test fresh install, unchanged rerun, held version, rejected invalid options, API
unreachable/forbidden, failed canary, interrupted install, and recovery. No cluster
was provisioned or upgraded to validate this package.

## Evidence and scope

- [lib/Rex/Rancher.pm](https://github.com/Getty/rex-rancher/blob/cb4df5cbaf6f62ff1de943cd54f0ed5c8ddc652e/lib/Rex/Rancher.pm)
- [Rex::Rancher (release documentation)](https://metacpan.org/pod/Rex::Rancher)
- [0.003 release commit](https://github.com/Getty/rex-rancher/commit/bc09be4fcaa88f564806be4f8d4e0064ad6d9c08)
