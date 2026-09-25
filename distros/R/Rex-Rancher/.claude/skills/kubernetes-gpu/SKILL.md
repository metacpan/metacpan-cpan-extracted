---
name: kubernetes-gpu
description: "Use when getting NVIDIA GPUs onto Kubernetes — host driver vs GPU Operator, container toolkit, ClusterPolicy, RuntimeClass, CDI, or nvidia.com/gpu missing from node capacity."
---

# NVIDIA GPUs on Kubernetes

Four things must line up before a pod can use a GPU: a **kernel driver** on the
host, a **container runtime** that can inject devices, a **device plugin** that
advertises `nvidia.com/gpu`, and a **scheduling request** for it. Every failure
below is one of the four missing, or two of them installed twice.

## Detect the card from sysfs, never from a model list

```bash
# vendor 0x10de = NVIDIA; class 0x0300xx = VGA, 0x0302xx = 3D controller
for d in /sys/bus/pci/devices/*; do
  printf '%s %s %s\n' "$(cat $d/vendor)" "$(cat $d/class)" "$d"
done | grep -E '^0x10de 0x030[02]'
```

`lspci` renders names from the host's `pci.ids`, which is always older than the
newest card — a GB10 shows up as `Device [10de:2e12]` and matches no marketing
name. Vendor and class come from the hardware and keep working.

Exclude virtual display adapters by vendor (`1af4` virtio, `1b36` QEMU, `15ad`
VMware, `80ee` VirtualBox), and let a real NVIDIA card win over them: a VM with
a passed-through GPU has both.

Whether a **driver** is already there is a different question, and package state
is the wrong way to ask it — vendor appliances (DGX OS) install outside the
distro's package namespace. Ask the system: `nvidia-smi` enumerates GPUs *and*
`libcuda.so` is in the linker cache.

## Host driver, or operator driver — never both

`driver.enabled` in the ClusterPolicy and a host-installed driver are two
implementations of the same job. Pick one:

- **Host driver** (`driver.enabled: false`): the node owns it, survives operator
  changes, and is the only option for vendor images that ship their own.
- **Operator driver** (`driver.enabled: true`): a DaemonSet builds and loads it.
  Its init container detects a preinstalled driver, labels the node, and
  terminates itself — so the mistake is survivable, but it means the pin in your
  ClusterPolicy is silently doing nothing.

On Ubuntu, install by letting the system resolve the package:

```bash
apt install -y linux-headers-$(uname -r)
ubuntu-drivers install          # let it fail loudly rather than guessing a name
```

Never hardcode a branch number. The branch, open-vs-proprietary, and the
architecture are three separate questions and all three are part of the package
*name*: Grace Hopper and Blackwell run only the open kernel modules, Maxwell
through Volta only the proprietary ones, arm64 packages come from ports, and a
transitional package like `nvidia-driver-535` on 24.04 pulls something entirely
different. `ubuntu-drivers` resolves all three from the card's PCI modalias.

Never install `linux-headers-generic`: on a vendor kernel (`6.17.0-1029-nvidia`)
it pulls headers for a *different* kernel and DKMS builds against the wrong tree.

## The container toolkit and the runtime handler

The toolkit gives containerd an `nvidia` runtime that injects devices. K3s and
RKE2 scan `PATH` for `nvidia-container-runtime` **at service start only** —
including `/usr/local/nvidia/toolkit`, where the operator's toolkit DaemonSet
installs it — write the matching containerd config themselves, and ship the
`nvidia` RuntimeClass. So: install the runtime *before* the service, or restart
the service afterwards. RKE2's unit sets no `PATH` at all; add one in
`/etc/default/rke2-{server,agent}` (see skill `kubernetes-rke2`).

Neither distribution makes nvidia the **default** runtime, and you should not
either. Workloads opt in:

```yaml
spec:
  runtimeClassName: nvidia
  containers:
    - name: cuda
      resources:
        limits:
          nvidia.com/gpu: 1      # a limit, not a request — GPUs are not shareable by default
```

With CDI enabled — the operator's default — the operator deliberately stops
configuring `nvidia` as the default runtime handler and hands the toolkit
`NVIDIA_RUNTIME_SET_AS_DEFAULT=false`. That, not the absence of
`CONTAINERD_SET_AS_DEFAULT`, is what keeps runc the default: the toolkit's own
default for `--set-as-default` is *true*. Leaving the variable out is a
preference, not a guard.

## Telling the operator where containerd lives

`toolkit.env` needs `CONTAINERD_SOCKET` and `CONTAINERD_CONFIG` on K3s/RKE2,
because the defaults (`/run/containerd/...`, `/etc/containerd/...`) are right on
neither. The operator derives its `RUNTIME_*` variables from them and mounts the
**directory** of each into the toolkit DaemonSet — which is why a wrong-but-
existing path is the worst case: the hostPath mounts cleanly and the failure
only appears when the toolkit tries to reach containerd through it.

## Discovery labels

Node Feature Discovery labels nodes from PCI data:
`feature.node.kubernetes.io/pci-0300_10de.present` (or `pci-0302_10de`) — the
same evidence as the sysfs scan, from inside the cluster. GPU Feature Discovery
adds product-level labels (`nvidia.com/gpu.product`, `.memory`, `.count`).

Run **one** of NFD and the operator's bundled `nfd.enabled` — two NFD masters
fight over the same labels. Same for `gfd`.

## Verify from the outside in

Everything before this is a prediction; these two are proof:

```bash
kubectl get nodes -o jsonpath='{.items[*].status.capacity.nvidia\.com/gpu}'
kubectl run cuda --rm -it --restart=Never --overrides='{"spec":{"runtimeClassName":"nvidia"}}' \
  --image=nvidia/cuda:12.4.0-base-ubuntu22.04 --limits=nvidia.com/gpu=1 -- nvidia-smi
```

An empty capacity means the device plugin never started or found no driver.
`Init:ImagePullBackOff` across several DaemonSets means the **validator** image
tag is wrong — from operator v25.10 the validator lives in the operator image
and carries the operator's own version; a separately pinned
`gpu-operator-validator` stops at v25.3.4 and every operand's init container
fails on it.

## Related

- `kubernetes-rke2` — the empty unit PATH and the containerd config paths.
- `kubernetes-concepts` — scheduling, DaemonSets, node capacity.
