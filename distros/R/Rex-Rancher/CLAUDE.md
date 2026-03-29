# Rex::Rancher

Rancher Kubernetes (RKE2/K3s) deployment automation for Rex. Handles everything
from raw Linux node preparation to a running cluster with CNI and GPU support.

## Module Structure

```
Rex::Rancher              — Main: rancher_deploy_server, rancher_deploy_agent
Rex::Rancher::Node        — Node prep (hostname, NTP, sysctl, swap, kernel modules)
Rex::Rancher::Server      — Control plane install (RKE2 + K3s), kubeconfig retrieval
Rex::Rancher::Agent       — Worker node join (RKE2 + K3s)
Rex::Rancher::Cilium      — Cilium CNI installation and upgrades (idempotent)
Rex::Rancher::K8s         — K8s API ops via Kubernetes::REST (no kubectl anywhere)
```

## Full Deploy Pipeline

`rancher_deploy_server` steps:

1. `prepare_node` — hostname, timezone, NTP, swap off, kernel modules, sysctl
2. GPU setup (only with `gpu => 1`, requires Rex::GPU)
3. `install_server` — write config, run installer, wait for kubeconfig file
4. Fetch kubeconfig, patch 127.0.0.1 → real server addr, save to `kubeconfig_file`
5. `wait_for_api` — poll K8s API locally via Kubernetes::REST
6. `install_cilium` — Cilium CLI on remote, deploy via cilium install
7. `deploy_nvidia_device_plugin` (only with `gpu => 1` + `kubeconfig_file`)

## Usage

```perl
use Rex -feature => ['1.4'];
use Rex::Rancher;

task "deploy", sub {
  rancher_deploy_server(
    distribution    => 'rke2',
    gpu             => 1,             # requires Rex::GPU
    reboot          => 1,
    hostname        => 'cp-01',
    domain          => 'k8s.example.com',
    token           => 'my-secret',
    tls_san         => 'cp-01.k8s.example.com',
    kubeconfig_file => "$ENV{HOME}/.kube/mycluster.yaml",
  );
  untaint_node(kubeconfig => "$ENV{HOME}/.kube/mycluster.yaml");
};
```

## Key Implementation Details

- **No kubectl** — all K8s API ops use Kubernetes::REST locally
- **No SFTP required** — use `set connection => 'LibSSH'` with Rex::LibSSH
  (common requirement on Hetzner dedicated servers)
- `install_cilium` is idempotent — handles "cannot re-use a name" Helm error silently
- `DPkg::Lock::Timeout=120` on apt-get calls for fresh-boot resilience
- RKE2 install: `auto_die => 0` + `command -v rke2` verify (GPG STDERR on Rocky 10)
- `apt-get update` before `pkg` calls uses `auto_die => 0` (snap/PPA warnings on Ubuntu)

## Rex::Rancher::K8s — Local K8s API

```perl
wait_for_api(kubeconfig => "~/.kube/mycluster.yaml");
deploy_nvidia_device_plugin(kubeconfig => "~/.kube/mycluster.yaml");
untaint_node(kubeconfig => "~/.kube/mycluster.yaml");  # single-node clusters
```

## Testing

```bash
prove -l t/
```

## Build

```bash
dzil build && dzil test && dzil release
```

## Live Testing (Hetzner)

```bash
# Dev path must come BEFORE installed versions:
PERL5LIB=/path/to/rex-gpu/lib:/path/to/rex-rancher/lib \
  rex -f eg/hetzner-gpu-rke2.Rexfile -H myserver deploy
```

Verified: Debian 13, Rocky Linux 10.1, Ubuntu 24.04 LTS — all with nvidia.com/gpu: 1.
