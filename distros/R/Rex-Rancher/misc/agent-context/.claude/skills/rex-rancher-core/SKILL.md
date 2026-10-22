---
name: rex-rancher-core
description: Load before editing Rex::Rancher — the RKE2/K3s deploy pipeline, the rke2/k3s split, why there is no kubectl and no SFTP, and the idempotency and fresh-boot traps.
---

# Rex::Rancher — core

Zero-touch Kubernetes deployment for Rancher distributions (RKE2 and K3s) as Rex tasks: it
takes a raw Linux host to a running cluster with CNI and optional GPU support. The public
API is **plain functions** via `Rex::Exporter`; rke2 and k3s differ in one Moo object,
`Rex::Rancher::Distribution`:

| Module | Exports | Owns |
|---|---|---|
| `Rex::Rancher` | `rancher_deploy_server`, `rancher_deploy_agent`, `rancher_scan_known_hosts` (+ re-exports of `wait_for_api`, `untaint_node`, `deploy_nvidia_device_plugin`) | the two full pipelines, connection guard, kubeconfig save/patch |
| `Rex::Rancher::Node` | `prepare_node` | hostname, tz, locale, NTP, swap off, kernel modules, sysctl |
| `Rex::Rancher::Server` | `install_server`, `get_kubeconfig`, `fetch_kubeconfig`, `patch_kubeconfig_server`, `get_token`, `update_registries` | control-plane install, `config.yaml`, `registries.yaml` |
| `Rex::Rancher::Agent` | `install_agent` | worker join |
| `Rex::Rancher::Cilium` | `install_cilium`, `upgrade_cilium`, `ensure_gateway_api_crds` | Cilium CLI + Helm values |
| `Rex::Rancher::K8s` | `wait_for_api`, `control_plane_version`, `deploy_nvidia_device_plugin`, `untaint_node` | local K8s API ops |
| `Rex::Rancher::Distribution` (+ `::RKE2`, `::K3s`) | — (Moo, `new_for($name, role => 'server'\|'agent')`, class loaded via `use_module`) | per-distribution paths, service, installer lines, start verb, version skew, the host steps server and agent share; `cilium_helm_defaults`, `needs_k8s_service_host`, `gateway_api_crd_chart`, `live_verified`, `unknown_distribution` |
| `Rex::Rancher::Uninstall` | `uninstall_node` | `uninstall_cmd` (the uninstaller one-liner incl. Cilium state: ip rules IPv4 and IPv6, `/run/cilium`; GPU Operator leftovers `/usr/local/nvidia` + `/var/run/cdi/{k8s.device-plugin.nvidia.com-gpu.json,management.nvidia.com-gpu.yaml}`, never `/etc/cdi` or `/var/run/cdi` whole), `uninstall_failure`, `check_cilium_residue` / `cilium_residue` (install guard: Cilium datapath state an earlier cluster left behind) |
| `Rex::Rancher::Options` | — | pure option checks: `resolve_install_method`, `check_cluster_cidr`, `check_kubeconfig_mode`, `check_ipam_mode` |
| `Rex::Rancher::Checksum` | — | `expected_sha256`, `sha256_of`, `verify_sha256` for the artifact install |

The distribution just wires these steps; the domain knowledge behind each step lives in
dedicated skills — RKE2/K3s config and joining: `kubernetes-rke2`; Cilium/eBPF/kube-proxy
replacement: `kubernetes-cilium-concepts`; the four things that must line up for
`nvidia.com/gpu`: `kubernetes-gpu`; the typed K8s objects `K8s.pm` sends:
`perl-io-k8s-kubernetes-classes`. Only what is true about this wiring belongs here.

## The pipeline is the product

`rancher_deploy_server` runs these steps in this order, and the order is load-bearing:

1. Option checks — unknown `distribution`, missing `Rex::GPU` under `gpu => 1`, a bad
   `cluster_cidr`, Cilium options contradicting `cilium => 0`: all die before the host is touched.
2. `_check_connection` — see "No SFTP" below.
3. `preflight_server` — the host is asked everything `install_server` would refuse it for,
   in the same order (Cilium residue, version skew, an established server's
   `cluster-cidr`). It only reads: a refused host keeps its packages, its swap setting,
   its GPU driver. `install_server` asks again, after node prep and GPU setup.
4. `prepare_node(%opts)` — OS prep. Swap **off** and `br_netfilter`/`overlay` loaded are
   preconditions for kubelet; skipping them yields a cluster that half-comes-up.
5. `_gpu_setup_if_requested` — only with `gpu => 1`; `eval { require Rex::GPU }` and
   **die with an install hint** if it is absent. GPU is an optional peer dist, not a hard dep.
6. `install_server(%opts)` — writes `config.yaml`, runs the installer, waits for the
   service to be active, then for the kubeconfig *file* to appear. **No** API readiness yet.
7. `_save_kubeconfig_locally` — fetch the remote kubeconfig, **rewrite
   `https://127.0.0.1` to the first `tls_san`** (or `kubeconfig_server`), write it to
   `kubeconfig_file`. Skipped silently when `kubeconfig_file` is not given.
8. `wait_for_api(kubeconfig => …)` — polls `list(Node)` **from the local machine** via
   `Kubernetes::REST`: the real readiness gate, which is why step 7 must run first. A
   kubeconfig whose API never answered stops the deploy there — the server is installed,
   Cilium and the device plugin are not, a re-run picks up.
9. `install_cilium(distribution => …)`.
10. `deploy_nvidia_device_plugin` — only with `gpu => 1` **and** a saved kubeconfig.

`rancher_deploy_agent` is the short arm: `preflight_agent` → `prepare_node` → gpu →
`install_agent`. No kubeconfig, no Cilium, no device plugin — the worker joins an
existing cluster; its preflight reads the control plane's version through the API (with
`kubeconfig_file`), and an agent is never taken to a newer minor than the control plane.

## The CNI contract: `config.yaml` and Cilium must agree

With `cilium => 1` (the default) the distribution's own CNI and kube-proxy are switched
off in `config.yaml` — rke2 `cni: none` + `disable-kube-proxy: true` (the shape in skill
`kubernetes-rke2`), k3s `flannel-backend: none` + `disable-network-policy: true` +
`disable-kube-proxy: true` + `cluster-cidr: 10.42.0.0/16` — and Cilium comes up with
`kubeProxyReplacement: true` and `k8sServiceHost: 127.0.0.1` (rke2, where servers and
agents alike serve the API) or the control plane's address (k3s, whose agents serve it on
`127.0.0.1:6444`). The two halves must agree: disabling the bundled CNI without
installing Cilium leaves the cluster with no network. With `cilium => 0` the
distribution's built-in CNI comes up and Rex::Rancher does nothing CNI-related. With
`gateway_api` the rke2 `disable` list also holds `rke2-gateway-api-crd`, or rke2 v1.37+
installs that chart over Cilium's CRDs.

## rke2 is the default; k3s is the parallel path

Every module that installs anything asks a `Rex::Rancher::Distribution` object
(`new_for($distribution)`, `'rke2'` default, `'k3s'`; anything else dies via
`unknown_distribution`). A difference between the two is a method overridden in both
`Distribution/RKE2.pm` and `Distribution/K3s.pm` — never an `eq 'k3s'` in a caller. When
you touch one distribution's paths, service name, install URL, or ports, change the other
class in the same edit. Server join port differs (RKE2 `:9345`, K3s `:6443`); the API is
`:6443` for both.

## No kubectl — the K8s API is spoken from the local machine

`Rex::Rancher::K8s` never shells out and never SSHes to the cluster. It builds a
`Kubernetes::REST::Kubeconfig` client from the saved kubeconfig and drives the API in
pure Perl (`Kubernetes::REST` + `IO::K8s`). `deploy_nvidia_device_plugin` constructs the
DaemonSet with `$api->new_object(DaemonSet => …)` and `create`s it, falling back to
get-resourceVersion-then-`update` on an "already exist" error — the idempotency contract
for the plugin. A `kubectl` call anywhere breaks the promise that the remote host needs no
cluster tooling and the operator's machine no kubeconfig on disk beyond what we wrote.
Typed objects and the boolean/`\0` quirks: `perl-io-k8s-kubernetes-classes`.

## No SFTP — this is a Hetzner-dedicated deployer

`_check_connection` (in `Rex::Rancher`) dies before doing anything unless the connection
is `LibSSH` or a working SFTP subsystem is present, pointing the user at
`set connection => 'LibSSH'` and `Rex::LibSSH` (a `recommends`, not a `requires`). The
target is Hetzner dedicated servers, which ship without `Subsystem sftp`: never assume
`file`/`upload` can rely on SFTP here. Connection backends and why: skill `rex`.

`Rex::LibSSH` >= 0.004 verifies the host key against `known_hosts`; a fresh host has no
entry, so the first verified connect dies. `rancher_scan_known_hosts($host)` pre-seeds it
with a local `ssh-keyscan` — call it from a `before 'ALL'` hook, since Rex connects
before the task body runs. It is idempotent and only warns when `ssh-keyscan` is missing.
Prefer it over switching the check off.

## The deliberate `auto_die => 0` sites — do not "clean these up"

These look like sloppy error handling and are deliberate; each exists because the naive
version broke a real deploy:

- **Cilium re-deploy** (`install_cilium`): with a local `kubeconfig` the Helm release
  Secrets are read and `_release_action` picks install / noop / upgrade / reinstall, or
  dies on a stuck release (skill `rex-rancher-traps`). Only *without* `kubeconfig` does
  `cilium install` run with `auto_die => 0` and swallow `/cannot re-use a name/i` as
  success — removing that fails every re-run without `kubeconfig_file`. The deploy passes
  the kubeconfig only once `wait_for_api` answered.
- **RKE2 installer** (`run_server_install_script` on `Distribution::RKE2`,
  `install_method => 'script'`): `curl … | sh -` runs with `auto_die => 0` because the
  script prints GPG key-import noise to STDERR (seen on Rocky 10); success is confirmed
  with `command -v rke2` and, when `version` is pinned, `verify_installed_version` (a
  failed pinned upgrade leaves the old binary). The `artifact` method (tarball path, no
  GPG import) runs with `auto_die => 1`.
- **Fresh Hetzner boot** (`_install_base_packages`): on Debian/Ubuntu,
  `unattended-upgrades` and the `apt-daily` timers are stopped first, then `apt-get
  update` runs with `-o DPkg::Lock::Timeout=120` and `auto_die => 0`.
  `DPkg::Lock::Timeout` covers only the dpkg lock, not the apt *frontend* lock that
  unattended-upgrades holds on a cold boot.

The remaining traps — the options with sharp edges, the install guards and their order,
the stuck Cilium release, the Cilium CLI download, the secret files, the config writes —
stand in skill `rex-rancher-traps`.

## Conventions in this distribution

Public API: plain functions exported via `Rex::Exporter` (`require Rex::Exporter; use base
qw(Rex::Exporter); use vars qw(@EXPORT);`), **not** standard `Exporter`. Anything that
branches on rke2 vs k3s belongs on the `Rex::Rancher::Distribution` object (Moo), not in a
`%PATHS` hash or a call into another module's `_private` sub. `# ABSTRACT:` first line,
`our $VERSION` right after `package`, `use v5.14.4`, POD with `=method` at the end of
each file. `Rex::Logger::info(…, 'warn')` for soft failures, `die "…\n"` for hard ones.
`$VERSION` is repeated in **every** file under `lib/`; a partial bump ships modules that
disagree about their version — `grep -rn 'our $VERSION' lib/` and change them together.
Everything else Perl: skill `getty-perl-core`; Rex idioms, connection types,
`run`/`pkg`/`auto_die`: skill `rex`.

Local vs remote: `Rex::Commands::Fs` exports `chmod`, `stat`, `unlink` … into
`Server.pm`; a bare call runs on the **remote** host. For a file on the operator's
machine (the saved kubeconfig) use `CORE::chmod`, `CORE::stat`, `CORE::unlink`.

## Verification

`prove -lr t/` (`-r` so any future `t/` subdirs run) — `t/00-load.t` is a compile check,
the rest are offline unit tests of the pure parts (config builders, installer command
strings, release decisions) with `run`/`file` faked (pattern: `t/token.t`). What a green
suite proves — and what only a real deploy proves — stands in
`.claude/rules/rex-rancher-rules.md`.
