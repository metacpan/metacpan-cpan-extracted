---
name: rex-gpu-core
description: Load before editing Rex::GPU — the detect→driver→toolkit→CDI→containerd pipeline, PCI-class detection, the per-distro driver matrix, why every install bypasses Rex::Pkg, and the RKE2/K3s containerd include mechanism.
---

# Rex::GPU — core

A Rex distribution that makes an NVIDIA GPU on a bare-metal host usable by Kubernetes
workloads. `gpu_setup()` is the single entry point; everything else is one stage of one
pipeline. AMD is *detected* but never installed — `compute => 0` always, a warning, no
driver path. Do not add AMD install code without a ticket that says to.

Consumes `Rex::LibSSH` (`recommends`, not a pin) because the target hosts — Hetzner
dedicated servers — ship without an SFTP subsystem. Every file op in this distribution
therefore has to survive on exec channels; Rex idioms and the SFTP question live in skill
`rex`. Downstream, `Rex::Rancher` calls `gpu_setup` via its optional `gpu => 1`.

## The pipeline — order is load-bearing

`gpu_setup(%opts)` in `lib/Rex/GPU.pm`:

1. `_check_connection` — die early if the backend is neither LibSSH nor SFTP-capable.
2. `gpu_detect` → `Rex::GPU::Detect::detect`.
3. Only if a **CUDA-capable** NVIDIA GPU is present (`grep { $_->{compute} }`):
   `install_driver(gpus => \@compute)` (all of them; `gpu =>` is the one-GPU alias) → `install_container_toolkit` → `generate_cdi_specs` →
   `configure_containerd($runtime)` unless `containerd_config eq 'none'`.

The order is not cosmetic. CDI generation runs `nvidia-ctk cdi generate`, which
enumerates *physical* devices — so it must come after the toolkit provides `nvidia-ctk`
**and**, on a first deploy, after the reboot that unloads nouveau and binds the NVIDIA
module. Reorder these and CDI writes an empty spec on a cold host. `containerd_config`
default is `rke2`; values `rke2` | `k3s` | `containerd` | `none`.

## Detection — PCI class codes, not nvidia-smi

`Rex::GPU::Detect` parses `lspci -nn`, never a driver tool (detection must work on a host
with no driver yet). The compiled regexes at the top of the file are the contract: display
class `[0300]`/`[0302]`, vendor `10de` NVIDIA / `1002` AMD. `compute` is decided by
**generation, not marketing name**; **unknown defaults to `0`** (safe: no install) with a
warning — keep it 0. `detect()` first ensures `lspci` (`command -v`, else pciutils via
dnf + `rpm -q` on RHEL names Rex::Pkg can't handle; k46).

**Hardware and distro combinations live in [references/hardware.md](references/hardware.md)**
(`.claude/skills/rex-gpu-core/references/hardware.md` from the repo root; not preloaded — Read it)
— generation/ID table, virtual displays, vGPU guests, NVSwitch / HGX B200/B300 NVLink
fabric / NVL72, and the per-distro driver matrix with its traps. Read the relevant section
before changing a detection rule, an ID range, a package list or a Setup class, and update
it in the same change.

**Which driver a GPU needs is a separate question** (epic #25): `Rex::GPU::NVIDIA::Requirement`
(Moo, experimental) maps the PCI device ID to `{kernel_module open|proprietary|either,
min_branch, max_branch}` via its overridable `generations` table (ranges in the reference).
Unknown ID ⇒ `either`, no bounds. `intersect` combines several GPUs and croaks on
conflict (`conflicts` lists without dying). The `compute` flag lives in these rows (one
table, no second list); Detect reads the base table, not a subclass.
`Detect::open_kernel_module_required` / `legacy_driver_requirement` are thin wrappers.

**Selection is data, not branches** (k33): each Setup class has ordered `sources`
(`{name, kernel_module, branch | branch_at_least, packages, verify, unavailable, …}`);
`plan` rejects Kepler (any GPU), builds `requirement` (intersection of **all** GPUs; conflict
dies untouched), then `select_source` takes the first candidate `satisfied_by` accepts on
its *declared* keys (no package index read) — else dies listing every candidate + reason.
The concrete package comes later (k35): `resolve_plan`, after `prepare_source`'s
`apt-get update`, runs `resolve_source` (Ubuntu's `apt-cache search` / `apt-cache policy`)
and re-checks it; `unavailable` or no fit dies before any install, no other candidate is
tried. Override `resolve_source` to choose packages another way (k42 `ubuntu-drivers`). `branch_at_least N` = "repo's newest, known ≥ N": passes
a min bound up to N, **never** a max bound; no branch at all passes only an unbounded
requirement. Don't invent a branch number for a "latest" source; give the floor the repo
provably carries.

## The driver matrix — one dispatch, three families

`install_driver` gets its Setup from `Rex::GPU::NVIDIA->setup_for` (k34), first hit wins:
`setup =>` option (class name or object) → `set gpu_nvidia_setup` (Rex::Config; how
Rancher's `gpu => 1` gets a custom setup) → overridable `setup_class_for_os`. Names load
via `use_module` unless the package is already defined (inline in a Rexfile; users drop
classes into the project's `lib/`), must `isa` Setup, and any failure croaks before the
`nvidia-smi` probe (`gpu_setup`: before detection). An object `adopt`s the detected GPUs
only if it has none. `requirement =>` → Setup `extra_requirement`, **intersected**, never
replacing: it tightens, a conflict dies in `plan`. Reboot/`modprobe`/`verify_nvidia` stay
in `install_driver` (connection + toolkit check). Every family runs through Moo Setup classes (`Rex::GPU::NVIDIA::Setup` →
`Setup::Apt` → `Setup::Debian` / `Setup::Ubuntu`; `Setup::Rpm` → `Setup::RHEL` /
`Setup::SUSE`; experimental, epic #25) with the fixed flow `already_installed → plan → prepare_host → prepare_source → resolve_plan → install_packages →
verify_packages → post_install`. `plan` is host-read-only; `run_cmd` / `pkg_cmd` /
`file_cmd` are the only routes to the host. No class for the OS ⇒ `install_driver`
still probes `nvidia-smi` and rejects Kepler, then dies. Each family (Debian, Ubuntu,
RHEL family, openSUSE) has traps already solved in the code — see
[references/hardware.md](references/hardware.md#distro-matrix--setup_class_for_os).

After the branch: Setup `post_install` (write the nouveau blacklist, regenerate initramfs
via `update-initramfs`/`dracut`), then reboot-and-verify or `modprobe nvidia`.

## Never Rex::Pkg for the driver/toolkit — the load-bearing invariant

Driver and toolkit installs call `run "apt-get/dnf/zypper install -y …", auto_die => 0`
directly, then verify with `dpkg -l | grep '^ii'` / `rpm -q`. **Not `pkg`.**
`Rex::Pkg::{Apt,Dnf}` dies on any non-zero exit, and DKMS module builds, grub updates and
initramfs regeneration routinely exit non-zero on success. `pkg` is fine only for
inert helpers (`pciutils`, `curl`, `gnupg`, `epel-release`). Route a real driver package
through `pkg` and every install "fails" on a working host.
In the Setup classes the bypass lives in `Setup::Apt::install_packages` /
`Setup::Rpm::install_packages`; `pkg_cmd` is for
inert helpers only.

Two more resilience rules baked into every apt path, both for **fresh-boot** Hetzner
hosts where cloud-init/unattended-upgrades still hold the dpkg lock:
- `-o DPkg::Lock::Timeout=120` on every `apt-get`. SUSE's twin: every zypper call goes
  through `Setup::SUSE->zypper` (`ZYPP_LOCK_TIMEOUT=120 zypper`; default is exit 7 at once; k53).
- `systemctl stop unattended-upgrades apt-daily* || true` before the first install.
- `apt-get update` runs `auto_die => 0` — it returns non-zero on snap/PPA repo warnings
  that are not real failures.

## Version-string trap — dots are stripped

`operating_system_version()` returns `101` for RHEL `10.1` (dots removed) — so the RHEL
path reads `operating_system_release()` and takes `/^(\d+)/` in `_rhel_major_version`.
The SUSE path *relies* on the stripping: `156 → 15.6` via `sprintf("%.1f", $version/10)`.
Know which function you are holding before you branch on a version.

## Kubernetes integration — CDI + the containerd include

- **CDI** (`generate_cdi_specs`): `nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml`.
  This is how the k8s device plugin enumerates GPUs *without a privileged container*.
- **RKE2 and K3s share one mechanism** (`_configure_containerd_rke2`): write
  `…/rke2/agent/etc/containerd/config.toml.tmpl` importing `/etc/containerd/conf.d/*.toml`,
  then drop `99-nvidia.toml` registering runtime `nvidia` as `io.containerd.runc.v2` with
  `BinaryName=/usr/bin/nvidia-container-runtime`. `k3s` deliberately falls through to the
  same code — do not fork it.
- **Standalone** (`containerd`): `nvidia-ctk runtime configure --runtime=containerd` +
  restart the service. `configure_containerd` returns early and silently if
  `nvidia-container-runtime` is not installed — a guard, not a bug.

## Reboot-and-wait

`_reboot_and_wait` schedules `shutdown -r now` 2s out (so `run` returns cleanly), sleeps
20s, then polls `disconnect`/`reconnect` on the live connection up to 60×5s, dying if the
host never returns. Reboot is required on first deploy only, to unload a previously-loaded
nouveau; without it the NVIDIA module can't bind. `verify_nvidia` (module loaded +
`nvidia-smi -L` shows a GPU + `nvidia-ctk` present) never dies — it warns and returns 0/1.

## Housekeeping

`$VERSION` is repeated in every module under `lib/` (`GPU.pm`, `Detect.pm`, `NVIDIA.pm`,
`NVIDIA/Requirement.pm`, `NVIDIA/VGPU.pm`, `NVIDIA/Setup.pm` and every `NVIDIA/Setup/*.pm`) — bump them together
(`grep -rn 'our \$VERSION' lib/`). A change to what a Rexfile author sees (a new option, a
detection outcome, a package choice) wants a `Changes` `{{$NEXT}}` entry naming the effect
and its POD updated in the same edit. Perl house style and dist mechanics: skills
`getty-perl-core`, `getty-perl-release-author-getty`, `perl-release-dist-ini`.
