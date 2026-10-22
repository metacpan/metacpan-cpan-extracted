# LAN live rig — runbook

`eg/lan.Rexfile` is the code side of karr k53: one machine in the local network
becomes a single-node RKE2 or K3s cluster, optionally a second host joins it as
an agent, optionally with a GTX-class consumer GPU. The rig is generic: the LAN
address is the `tls_san`, the connection is LibSSH, and no SFTP subsystem is
needed on the target.

This file is the checklist for the live run. The code side of the rig is
covered offline by `t/eg-lan-rexfile.t`.

The run took place on 2026-10-21: server on an Ubuntu 24.04 host with a
GeForce RTX 3090 (Ampere, consumer card), a second Ubuntu 24.04 host as agent,
RKE2 v1.36.5 and K3s v1.36.5, Cilium 1.20.0 -> 1.20.3. Every row below passed;
the RKE2 series with the driver already on the host, the K3s series from a
host without driver and toolkit (Rex::GPU installed `nvidia-driver-615-server`
and rebooted once). Not run live: the Maxwell/Pascal branch-580 path (needs an
older GTX card) and a GPU on the agent. Two findings came out of it: the first
`rerun` restarted the server (k92, fixed) and the wrong-address join reports
only after the full 600 s wait, although the agent's journal shows the failed
connection within seconds.

## Machine prep

- fresh Debian/Ubuntu/Rocky, root login with a key (`LAN_USER`, `LAN_KEY`)
- `Subsystem sftp` commented out in `/etc/ssh/sshd_config`, then
  `systemctl restart sshd` — this rehearses the SFTP-less host the deployer is
  built for
- from the operator's machine: port 6443 reachable (the API), port 9345
  reachable as well for an RKE2 agent join
- for the GPU: a GTX-class consumer card; the driver branch depends on the
  generation (Maxwell/Pascal only up to branch 580)
- on the operator's machine: `Rex::GPU` is a *recommends*, not a *requires* —
  `PERL5LIB=lib:../rex-gpu/lib:$PERL5LIB` when both repos are checked out

## The runs

rke2 (the default):

```bash
rex -f eg/lan.Rexfile -H <server-ip> deploy
rex -f eg/lan.Rexfile -H <server-ip> rerun
rex -f eg/lan.Rexfile -H <server-ip> check
LAN_CILIUM_UPGRADE_TO=1.20.2 rex -f eg/lan.Rexfile -H <server-ip> cilium_upgrade
LAN_SERVER=<server-ip> rex -f eg/lan.Rexfile -H <agent-ip> join_agent
```

k3s: the same series with `LAN_DIST=k3s`. Every run of a series needs the same
environment — `rerun` and `check` read it to know what they are looking at.

GPU: `LAN_GPU=1` on the server, `LAN_AGENT_GPU=1` on the agent (both reboot the
node once).

Agent join error case: `LAN_JOIN_URL=https://<wrong-address>:9345` — the join
fails with the hint of the wrong address, on purpose.

## The checklist

One line per sub-issue of karr k53. "Offline" names what the code and the
offline tests already cover; the rest is what only the live run proves.

| Card | Sub-issue | What to look at on the machine | Offline (code + `t/`) | Live only |
|---|---|---|---|---|
| k41 | `cluster_cidr` | `LAN_CLUSTER_CIDR=10.44.0.0/16` on the first deploy; a second deploy with a different value must die *before* the host changes — `network.pod_cidr` in `/etc/rancher/<dist>/config.yaml` and the `config.yaml.d/` drop-ins stay as they were | `Distribution::check_established_cluster_cidr`, `t/cluster-cidr-established.t` | that the guard fires before the installer, on a live server |
| k42 | `prepare_node` | hostname and timezone set, `swapon --show` empty, `lsmod` shows `br_netfilter` and `overlay`, the sysctl values, chrony or timesyncd running | `Rex::Rancher::Node`, `t/node.t` (NTP, `/etc/hosts`, locale) | swap off, the kernel modules, the sysctl values on a real host |
| k43, k51 | Cilium install/upgrade, IPAM kept, abort without kubeconfig | the `cilium` DaemonSet ready, the Helm release as `vN status chart`; after the upgrade `ipam.mode` and the pool in the ConfigMap `kube-system/cilium-config` are unchanged; without a kubeconfig `cilium install` runs and may swallow "cannot re-use a name" | `Rex::Rancher::Cilium`, `t/cilium.t` | the Helm release state and the ConfigMap on a running cluster |
| k44 | agent join (wrong address) | with `LAN_JOIN_URL` pointing at a wrong address the join dies with "It joins the cluster via … -- check that this node can reach that address" and the journal of the agent service; with the right address the agent turns Ready | `Rex::Rancher::Agent`, `t/agent-steps.t`, `t/agent-start.t` | the hint on a real join, and the working join |
| k46, k49 | re-run idempotency, restart logic | `rerun` against the running cluster: the service keeps running (rke2: `systemctl start`, no restart), the Cilium release stays untouched (noop); k3s restarts by design (the installer rewrites the unit). Compare `MainPID` and `ActiveEnterTimestamp` before and after | `Distribution::restart_reasons`, `t/restart-reasons.t`, `t/server-start.t`, `t/version-skew.t` | whether a live service is really left alone (or restarted) |
| k48 | distribution refactor | both distributions come up: `systemctl is-active rke2-server` vs `k3s`, the service names, the data and config dirs, the join port 9345 vs 6443. Every difference belongs in `Distribution/RKE2.pm` and `Distribution/K3s.pm`, none in a caller | `t/distribution.t`, `t/distribution-class.t` | k3s has never run live — the whole k3s path |
| GPU | single card: classification, driver, drop-in, device plugin, `nvidia.com/gpu` | `nvidia-smi` (name, driver, memory), the driver branch for the card's generation, `/var/lib/rancher/<dist>/agent/etc/containerd/config-v3.toml.d/99-nvidia.toml`, `libcuda.so.1` in `ldconfig -p`, the `nvidia-device-plugin-daemonset` ready, `nvidia.com/gpu` in the node's capacity | `t/gpu-steps.t`, `t/gpu-module-version.t`, `t/nvidia-device-plugin-spec.t`, `t/gpu-resource-wait.t`, `t/nvidia-runtime-path.t` | the driver install, Rex::GPU's classification of a consumer card, the advertised `nvidia.com/gpu` |

## Not in scope

Multi-GPU, HGX/NVSwitch/Fabric Manager, vGPU — the rig covers one card on one
node.

## Notes

- A green `prove -lr t/` says nothing about a deploy. The rows above marked
  "live only" are the reason this card stays open until a machine exists.
- The join token never appears in the output: `check` redacts it in the
  `config.yaml` dump, and the token is not put on a command line.
