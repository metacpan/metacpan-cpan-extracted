---
name: rex-rancher-core
description: Load before editing Rex::Rancher — the six-module deploy pipeline (node-prep → install → kubeconfig patch → wait_for_api → Cilium → GPU device plugin), the rke2/k3s split, why there is no kubectl and no SFTP, and the idempotency and fresh-boot traps.
---

# Rex::Rancher — core

Zero-touch Kubernetes deployment for Rancher distributions (RKE2 and K3s) as a set of
Rex tasks. It takes a raw Linux host to a running cluster with CNI and optional GPU
support. Six modules, all exporting **plain functions** through `Rex::Exporter` (no OO):

| Module | Exports | Owns |
|---|---|---|
| `Rex::Rancher` | `rancher_deploy_server`, `rancher_deploy_agent` + re-exports | the two full pipelines, connection guard, kubeconfig save/patch |
| `Rex::Rancher::Node` | `prepare_node` | hostname, tz, locale, NTP, swap off, kernel modules, sysctl |
| `Rex::Rancher::Server` | `install_server`, `get_kubeconfig`, `get_token`, `update_registries` | control-plane install, `config.yaml`, `registries.yaml` |
| `Rex::Rancher::Agent` | `install_agent` | worker join |
| `Rex::Rancher::Cilium` | `install_cilium`, `upgrade_cilium` | Cilium CLI + Helm values |
| `Rex::Rancher::K8s` | `wait_for_api`, `deploy_nvidia_device_plugin`, `untaint_node` | local K8s API ops |

The distribution just wires these steps; the domain knowledge behind each step lives in
dedicated skills — RKE2/K3s config and joining: `kubernetes-rke2`; Cilium/eBPF/kube-proxy
replacement: `kubernetes-cilium-concepts`; the four things that must line up for
`nvidia.com/gpu`: `kubernetes-gpu`; building the typed K8s objects `K8s.pm` sends:
`perl-io-k8s-kubernetes-classes`. This skill is only what is true about *this* wiring.

## The pipeline is the product

`rancher_deploy_server` runs these steps in this order, and the order is load-bearing:

1. `_check_connection` — see "No SFTP" below.
2. `prepare_node(%opts)` — OS prep. Swap **off** and `br_netfilter`/`overlay` loaded are
   preconditions for kubelet; skipping them yields a cluster that half-comes-up.
3. `_gpu_setup_if_requested` — only with `gpu => 1`; `eval { require Rex::GPU }` and
   **die with an install hint** if it is absent. GPU is an optional peer dist, never a
   hard dep.
4. `install_server(%opts)` — writes `config.yaml`, runs the installer, waits for the
   kubeconfig *file* to appear on the remote. It does **not** confirm API readiness.
5. `_save_kubeconfig_locally` — fetch the remote kubeconfig, **rewrite `https://127.0.0.1`
   to the first `tls_san`** (or `kubeconfig_server`), write it to `kubeconfig_file`.
   Skipped silently when `kubeconfig_file` is not given.
6. `wait_for_api(kubeconfig => …)` — polls `list(Node)` **from the local machine** via
   `Kubernetes::REST`. This is the real readiness gate, which is why step 5 must run first.
7. `install_cilium(distribution => …)`.
8. `deploy_nvidia_device_plugin` — only with `gpu => 1` **and** a saved kubeconfig.

`rancher_deploy_agent` is the short arm: `prepare_node` → gpu → `install_agent`. No
kubeconfig, no Cilium, no device plugin — the worker joins an existing cluster.

## rke2 is the default; k3s is the parallel path

Every module that installs anything branches on `distribution` (`'rke2'` default,
`'k3s'`) through a private `_paths`/`_paths_for` table and `die`s on anything else. When
you touch one distribution's paths, service name, install URL, or ports, find the k3s
counterpart in the same file — they are meant to stay in lockstep. Server join port
differs (RKE2 `:9345`, K3s `:6443`); the API is `:6443` for both.

## No kubectl — the K8s API is spoken from the local machine

`Rex::Rancher::K8s` never shells out and never SSHes to the cluster. It builds a
`Kubernetes::REST::Kubeconfig` client from the saved kubeconfig and drives the API in
pure Perl (`Kubernetes::REST` + `IO::K8s`). `deploy_nvidia_device_plugin` constructs the
DaemonSet with `$api->new_object(DaemonSet => …)` and `create`s it, falling back to
get-resourceVersion-then-`update` on an "already exist" error — that is the idempotency
contract for the plugin. Adding a `kubectl` call anywhere breaks the promise that the
remote host needs no cluster tooling and the operator's machine needs no kubeconfig on
disk beyond what we wrote. Typed-object construction and the boolean/`\0` quirks:
`perl-io-k8s-kubernetes-classes`.

## No SFTP — this is a Hetzner-dedicated deployer

`_check_connection` (in `Rex::Rancher`) dies before doing anything unless the connection
is `LibSSH` or a working SFTP subsystem is present, pointing the user at
`set connection => 'LibSSH'` and `Rex::LibSSH` (a `recommends`, not a `requires`). The
target environment is Hetzner dedicated servers, which ship without `Subsystem sftp`.
Never assume `file`/`upload` can rely on SFTP here. Connection backends and why: skill
`rex`.

## Idempotency and the fresh-boot traps — do not "clean these up"

These look like sloppy error handling and are deliberate; each exists because the naive
version broke a real deploy:

- **Cilium re-deploy** (`install_cilium`): with a local `kubeconfig` the Helm release
  Secrets are read and `_release_action` picks install / noop / upgrade / reinstall, or
  dies on `pending-upgrade`/`pending-rollback` (the deployed revision still carries the
  pod network). Only *without* `kubeconfig` does `cilium install` still run with
  `auto_die => 0` and swallow `/cannot re-use a name/i` as success — removing that makes
  every re-run without `kubeconfig_file` fail. `rancher_deploy_server` passes the
  kubeconfig only once `wait_for_api` answered.
- **RKE2 installer** (`_install_rke2`, `install_method => 'script'`): `curl … | sh -` runs
  with `auto_die => 0` because the script prints GPG key-import noise to STDERR (seen on
  Rocky 10); success is confirmed with `command -v rke2` and, when `version` is pinned,
  `_verify_installed_version` (a failed pinned upgrade leaves the old binary). The
  `artifact` method uses the tarball path (no GPG import) and runs with `auto_die => 1`.
- **Secrets on disk**: `config.yaml` (join token) and `registries.yaml` go through
  `_write_secret_file` (0600 root:root, pre-created Rex tmp file). The token never goes
  on an installer command line (`ps`), for either distribution.
- **Fresh Hetzner boot** (`_install_base_packages`): on Debian/Ubuntu, `unattended-upgrades`
  and the `apt-daily` timers are stopped first, then `apt-get update` runs with
  `-o DPkg::Lock::Timeout=120` and `auto_die => 0`. `DPkg::Lock::Timeout` covers only the
  dpkg lock, not the apt *frontend* lock that unattended-upgrades holds on a cold boot.
- **Config writes** use `YAML::PP->new(boolean => 'JSON::PP')` so `disable-kube-proxy`
  and friends serialise as real YAML booleans, not `1`/`0` strings.

When `cilium => 1` (default), `install_server` writes `cni: none` +
`disable-kube-proxy: true` into `config.yaml`, and Cilium is brought up with
`kubeProxyReplacement: true` / `k8sServiceHost: 127.0.0.1`. The two halves must agree:
disabling the bundled CNI without installing Cilium leaves the cluster with no network.

## Options that have sharp edges

- `token` — when omitted, the host's existing `server/token` is reused
  (`_resolve_token`); only a fresh server gets `_generate_token` (≥32 chars). Rotating
  it on a live control plane kills the next restart ("encrypted with different token").
  A worker join needs the *same* token, fetched with `get_token`.
- `version` — the RKE2/K3s version. Cilium's is `cilium_version` on
  `rancher_deploy_server`; never reuse `version` for it.
- `tls_san` — accepts a string, comma-separated list, or arrayref; **the first entry
  doubles as the kubeconfig server address** in step 5. A missing/oddly-ordered `tls_san`
  produces a kubeconfig still pointing at `127.0.0.1`.
- `kubeconfig_file` — its absence silently disables both the local save and the GPU
  device-plugin step, even under `gpu => 1`. Not an error, but say so if a user expects a
  file.

## Conventions in this distribution

Plain functions exported via `Rex::Exporter` (`require Rex::Exporter; use base
qw(Rex::Exporter); use vars qw(@EXPORT);`), **not** standard `Exporter` and no Moo/Moose.
`# ABSTRACT:` first line, `our $VERSION` right after `package`, `use v5.14.4`, POD with
`=method` at the end of each file. `Rex::Logger::info(…, 'warn')` for soft failures,
`die "…\n"` for hard ones. `$VERSION` is repeated in **all six** files under `lib/`; a
partial bump ships modules that disagree about their version — `grep -rn 'our $VERSION'
lib/` and change them together. Everything else Perl: skill `getty-perl-core`. Rex idioms,
connection types, `run`/`pkg`/`auto_die`: skill `rex`.

## Verification

```bash
prove -lr t/        # -r so any future t/ subdirs run
```

`t/00-load.t` is a compile check; the other files are offline unit tests of the pure
parts (config builders, installer command strings, release decisions) with `run`/`file`
replaced by fakes (pattern: `t/token.t`). None of it says anything about a deploy. There is no integration test and no way to exercise a real install without a
throwaway host. A green suite here is not evidence that a pipeline change works; a change
to install ordering, the kubeconfig patch, or the K8s API objects can only be trusted
after a live deploy against a real node (see `eg/hetzner-gpu.Rexfile`). Say plainly that
the suite proves compilation, not behaviour.
