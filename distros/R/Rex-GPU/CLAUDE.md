# Rex::GPU

GPU detection and driver management for Rex. Works with any Kubernetes setup
(RKE2, K3s, kubeadm, standalone containerd) or standalone.

## Module Structure

```
Rex::GPU              — gpu_detect(), gpu_setup() — main entry points
Rex::GPU::Detect      — PCI class code based GPU detection (NVIDIA, AMD)
Rex::GPU::NVIDIA — NVIDIA driver, container toolkit, CDI specs, containerd config
```

Requires `Rex::LibSSH` for deployment to hosts without SFTP (e.g. Hetzner
dedicated servers). Use `set connection => 'LibSSH'` in your Rexfile.

## Usage

```perl
use Rex::GPU;

# Detect GPUs
my $gpus = gpu_detect();
# { nvidia => [{name => "RTX 4000 SFF Ada", compute => 1}], amd => [...] }

# Full setup: drivers + toolkit + CDI + containerd runtime config
gpu_setup(containerd_config => 'rke2');  # or 'k3s', 'containerd', 'none'
gpu_setup(containerd_config => 'rke2', reboot => 1);
```

## Supported Distros

| Distro | Notes |
|--------|-------|
| Debian 12/13 | non-free repo required (Hetzner image has it pre-enabled) |
| Ubuntu 22.04/24.04 | auto-detect nvidia-driver-NNN-server; no nvidia-smi (virtual pkg on 24.04) |
| RHEL/Rocky/Alma 8-10 | EPEL + CUDA repo; kmod-nvidia-open-dkms on RHEL 10+ |
| openSUSE Leap 15.6/16.0 | nvidia-open-driver-G06/G07-signed-kmp-meta |

## Key Implementation Details

- All NVIDIA installs use `run "apt-get/dnf install -y ..."` directly, NOT Rex::Pkg —
  Rex::Pkg dies on non-zero exit from DKMS/grub/initramfs post-install scripts
- `DPkg::Lock::Timeout=120` on all apt-get calls — prevents failures on fresh-boot
  systems where unattended-upgrades/cloud-init holds the dpkg lock
- `apt-get update` uses `auto_die => 0` — returns non-zero on snap/PPA repo warnings

## Testing

```bash
prove -l t/
```

## Build

```bash
dzil build && dzil test && dzil release
```

## Used By

- `Rex::Rancher` — optional GPU support via `gpu => 1`
