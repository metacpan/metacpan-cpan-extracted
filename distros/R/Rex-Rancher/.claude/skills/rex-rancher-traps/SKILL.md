---
name: rex-rancher-traps
description: Load before changing Rex::Rancher's install path — the options with sharp edges and the traps of the install: the guards and their order, the stuck Cilium release, the Cilium CLI, the secret files, the config writes.
---

# Rex::Rancher — traps

The sharp edges of this distribution: the options whose edges are not where a Rexfile
author expects them, and the traps in the install path. The pipeline, the boundaries and
the deliberate `auto_die => 0` sites stand in skill `rex-rancher-core`.

## Options with sharp edges

| Option | The edge |
|---|---|
| `token` | two different secrets: the control plane's cluster secret (`server/token`, written into `config.yaml`) and the **node join token** (`server/node-token`) a worker joins with, read with `get_token`. The server reuses the existing `server/token` when the option is omitted (`_resolve_token`); only a fresh server gets `_generate_token` (≥32 chars). Rotating the cluster secret on a live control plane kills the next restart ("encrypted with different token"). An agent needs the node token, not the secret. |
| `version` | the RKE2/K3s version. Cilium's is `cilium_version` on `rancher_deploy_server`; never reuse `version` for it, and never move Cilium more than one minor: pinned, at most one minor away (further dies before the host is touched); unpinned, a patch release of the running minor is taken, a newer minor or an older version is not — the running version stays, a newer minor with a warning. A re-run follows the Kubernetes version skew policy against the running (or, if stopped, installed) version, rke2 and k3s alike: patch → restart; +1 minor → restart only when `version` is pinned, else warn and keep the old one running; >1 minor or any downgrade → die before installing. Unpinned, the target is resolved from the stable channel first. An agent is never taken to a newer minor than the control plane (checkable only with `kubeconfig`). |
| `install_method` | `script` (default) or `artifact`; anything else dies, and so does `artifact` without a `version`. `script` runs the distribution's install script (the RKE2 GPG noise, see `rex-rancher-core`), `artifact` the release tarball, checked against its sha256sum. |
| `hold_running` | a server already on the node keeps the version it runs (or, stopped, the installed one) and that version counts as `version`; a `version` given as well applies only to a node with nothing to hold. Held, the service is restarted only for a changed configuration — K3s included, which otherwise restarts every run. |
| Re-run restarts | rke2 gets `start` (a running control plane is left alone) unless `restart_reasons` finds something it must re-read (config/registries/env file or containerd drop-in newer than the main PID, a new binary within the skew rules, a Rex::GPU 0.001 containerd config). k3s restarts every run (its installer rewrites the unit). |
| `tls_san` | accepts a string, comma-separated list, or arrayref; **the first entry doubles as the kubeconfig server address** (pipeline step 7) and as k3s's `k8s_service_host`. A missing/oddly-ordered `tls_san` produces a kubeconfig still pointing at `127.0.0.1`. |
| `cluster_cidr` | on an established server (service active, or `server/token` present) a value that differs from the one in `config.yaml` + `config.yaml.d` dies (`check_established_cluster_cidr`); changing it on a live cluster breaks pod routing. It is also Cilium's pool in `ipam_mode => 'cluster-pool'` — but a running Cilium keeps its pool, and the new value is only warned about, not applied. |
| `kubeconfig_server` | may carry a port (`cp:7443`, `[v6]:7443`); without one the kubeconfig keeps its 6443. Split by `Rex::Rancher::Server::split_server_address`. |
| `kubeconfig_file` | its absence silently disables both the local save and the GPU device-plugin step, even under `gpu => 1`. Not an error, but say so if a user expects a file. `kubeconfig_mode` sets the mode of the kubeconfig the *server* writes on the node (`rke2.yaml` / `k3s.yaml`), a string of an octal mode such as `'0640'`; the default is the distribution's own `0600 root:root`, which keeps the cluster admin's key in that file away from the node's other accounts. |
| `ipam_mode` | Cilium's IPAM mode on a fresh install: `kubernetes` (the default on rke2 — the node podCIDRs the cluster cuts from `cluster_cidr`) or `cluster-pool` (the default on k3s — the ranges Cilium cuts from its own pool). Any other mode needs more than a name and dies; `multi-pool` and friends belong in `cilium_helm_values`. A running cluster keeps its mode: an upgrade that changes it dies (`_refuse_ipam_change`, the pods would lose their addresses), a fresh install onto a running Cilium only warns. |
| `k8s_service_host` | k3s only: the address Cilium reaches the API server at from every node. Default: the first `tls_san`; without one the k3s deploy with Cilium dies, since k3s agents serve the API on `127.0.0.1:6444`. On rke2 it is not an option at all. |

## The install guards, in order

`install_server`, from the first host read onwards: `check_cilium_residue` →
`check_version_skew` → `check_established_cluster_cidr` (server only);
`remove_bare_containerd_template` runs before `start_verb`. Agents have the first two.
They die before anything changes on the host — keep them ahead of the installer.

## The stuck Cilium release

`_refuse_stuck_release`: `install_cilium` and `upgrade_cilium` die right after the
release read, before the host is touched, on `pending-upgrade`, `pending-rollback` and
`pending-install` over a deployed revision. `pending-install` without a deployed revision
is still purged and reinstalled.

## The Cilium CLI

`_install_cilium_cli`: downloaded into a `mktemp -d` directory and checked against the
release's `.sha256sum` before it lands in `/usr/local/bin`; a missing or wrong sum dies.
Never go back to fixed `/tmp` names.

## The secret files on disk

`config.yaml` (join token) and `registries.yaml` go through the distribution's
`write_secret_file` (0600 root:root, pre-created Rex tmp file). The token never goes on
an installer command line (`ps`), for either distribution.

## The config writes

Config writes use `YAML::PP->new(boolean => 'JSON::PP')` so `disable-kube-proxy` and
friends serialise as real YAML booleans, not `1`/`0` strings.
