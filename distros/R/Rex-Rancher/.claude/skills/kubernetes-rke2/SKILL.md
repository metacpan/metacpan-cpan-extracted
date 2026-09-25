---
name: kubernetes-rke2
description: "Use when installing or configuring RKE2 or K3s — config.yaml, joining agents, replacing the bundled CNI or kube-proxy, registries.yaml, airgap installs, a node stuck NotReady."
---

# RKE2 and K3s — Operating Reference

Two distributions, one agent codebase. RKE2 is K3s' agent code with a
conventional control plane; almost everything below is identical apart from
paths. Where they differ, the difference is named.

## The config file is the interface

`/etc/rancher/rke2/config.yaml` (K3s: `/etc/rancher/k3s/config.yaml`) holds the
same keys as the CLI flags, minus the leading dashes. Files in
`config.yaml.d/*.yaml` merge alphabetically; **the last value for a key wins**,
so a drop-in silently replaces a list rather than extending it. Append with the
`+` suffix (`disable+:`) when you mean "and also".

The file must exist **before** the service starts. Nothing rereads it — a
changed `config.yaml` means `systemctl restart rke2-server`.

```yaml
# server
token: <shared-secret>
node-name: cp1
tls-san:
  - cluster.example.com     # every name a kubeconfig might use, or TLS fails later
write-kubeconfig-mode: "0644"
cni: none                   # none | calico | canal (default) | cilium | flannel
disable-kube-proxy: true
disable:
  - rke2-ingress-nginx
```

```yaml
# agent — only ever these two
server: https://cp1.example.com:9345
token: <shared-secret>
```

**9345, not 6443.** The server listens on 9345 for node registration; 6443 is
the Kubernetes API and will not accept a join. The token is generated on first
start and readable at `/var/lib/rancher/rke2/server/node-token`.

## Replacing the bundled networking

`cni: none` leaves the cluster **deliberately broken** until you install a CNI:
nodes stay `NotReady`, CoreDNS stays `Pending`. That is the expected middle
state, not a failed install — do not restart the service to "fix" it.

Pairing `cni: none` with `disable-kube-proxy: true` is the normal shape when the
CNI replaces kube-proxy (Cilium eBPF, Calico eBPF). Then the CNI needs to reach
the API server without a Service IP, because nothing is translating them yet —
Cilium wants `k8sServiceHost` and `k8sServicePort` explicitly. See skill
`kubernetes-cilium-concepts`.

`disable:` only removes RKE2's *packaged* components — `rke2-ingress-nginx`,
`rke2-coredns`, `rke2-metrics-server`, `rke2-snapshot-controller`. It does not
touch anything you installed yourself.

## registries.yaml — mirrors for containerd

`/etc/rancher/rke2/registries.yaml`, on **every** node that pulls images,
servers included. RKE2 translates it into containerd's `hosts.toml` at startup;
editing it needs a service restart, same as the config.

```yaml
mirrors:
  docker.io:
    endpoint:
      - http://cache.internal:5000
configs:
  cache.internal:5000:
    auth:
      username: u
      password: p
    tls:
      insecure_skip_verify: true
```

The trap: **the upstream default endpoint is always tried last, even when you
listed mirrors.** A mirror that is merely unreachable therefore looks like it
works — pulls quietly go out to the internet. An airgap check has to watch
egress, not just `crictl pull` exit status.

Two keys, two meanings: `mirrors` decides *where to look*, `configs` carries
credentials and TLS and is keyed by the **endpoint host**, not the mirrored
name.

## Installing without a working network

The install script fetches with `curl -s`, which prints nothing. Over a
long-running SSH automation session (Rex, Ansible with a low timeout) the silent
minutes read as a hung connection. Pre-download with a progress bar and point
the script at the artifacts:

```bash
curl -L --progress-bar -o /tmp/rke2-artifacts/rke2.linux-amd64.tar.gz <url>
INSTALL_RKE2_ARTIFACT_PATH=/tmp/rke2-artifacts sh /tmp/rke2-install.sh
```

`INSTALL_RKE2_TYPE=agent` selects the agent; server is the default.

## What differs in K3s

| | RKE2 | K3s |
|---|---|---|
| config dir | `/etc/rancher/rke2/` | `/etc/rancher/k3s/` |
| kubeconfig | `/etc/rancher/rke2/rke2.yaml` | `/etc/rancher/k3s/k3s.yaml` |
| kubectl | `/var/lib/rancher/rke2/bin/kubectl` | on `PATH` |
| node token | `/var/lib/rancher/rke2/server/node-token` | `/var/lib/rancher/k3s/server/node-token` |
| install | `INSTALL_RKE2_TYPE=… sh install.sh` | `curl -sfL https://get.k3s.io \| sh -s - server --disable=traefik` |
| agent env | config.yaml | `K3S_URL=… K3S_TOKEN=… sh -s - agent` |
| unit PATH | **empty** | populated |

That last row bites: RKE2's systemd unit sets no `PATH`, so anything the agent
shells out to must be found by absolute path or added via
`/etc/default/rke2-server` / `-agent`. The NVIDIA container runtime detection is
the usual casualty — see skill `kubernetes-gpu`.

The containerd socket is `/run/k3s/containerd/containerd.sock` on **both**,
because RKE2 runs K3s' agent code. Only the generated containerd config path
follows the distribution:
`/var/lib/rancher/{k3s,rke2}/agent/etc/containerd/config.toml`.

## Never ship a partial containerd template

A `config.toml.tmpl` (or `config-v3.toml.tmpl`) is rendered **instead of** the
generated config, not merged into it. Without `{{ template "base" . }}` at the
top it silently drops the registry mirrors, the sandbox image and the CNI
settings — a cluster that pulls from the wrong place and cannot start pods, with
nothing in the logs pointing at the template.

## Related

- `kubernetes-concepts` — the resource model underneath.
- `kubernetes-cilium-concepts` — the usual `cni: none` follow-up.
- `kubernetes-gpu` — GPU nodes, RuntimeClass, the empty-PATH consequence.
- `docker-registry` — running the mirror that `registries.yaml` points at.
