# Rex::GPU — hardware and distro combinations

Read the section you are about to change. Every entry here is a solved trap in the code;
do not "simplify" one away without a ticket.

## GPU generations — `Rex::GPU::NVIDIA::Requirement`

`generations` (overridable) maps the PCI device ID to `{kernel_module open|proprietary|either,
min_branch, max_branch, compute}`. Rows cover 0000–2FFF gap-free plus 3182 / 31C2–31C3.

| Device IDs | Generation | Module | Branch | `compute` |
|---|---|---|---|---|
| < 1340 | Kepler or older | — | ≤ 470 (rejected) | 0 |
| 1340–1DF6 | Maxwell / Pascal / Volta | proprietary | ≤ 580 | 1 |
| 1DF7–28FF | Turing .. Hopper | either | unbounded | 1 |
| 2900–2FFF | Blackwell (B200 2901/2909, GB200 2941, RTX 50xx, RTX PRO) | open | ≥ 570 | 1 |
| 2E12 | GB10 (DGX Spark) | open | ≥ 580 | 1 |
| 3182, 31C2–31C3 | B300 / GB300 | open | ≥ 580 | 1 |

Unknown ID ⇒ `either`, no bounds, `compute` undef → name rules.

**Detection order in `_is_nvidia_compute`** (k45/k54/k55): Kepler-or-older row (`compute 0`)
first — skipped with warning "needs branch 470 … skipped", a skip not a die, so a K80 next
to an Ada leaves the Ada alone; then class `[0302]` ⇒ compute; then name rules naming only
Maxwell+ products (RTX, GTX 1xxx/9xx/745/750, GT 1xxx, GeForce MX, TITAN X/Xp/V/RTX,
Quadro M/P/T/GP/GV, Tesla M/P/V/T4, A100-style codes), no negative rules. Unknown ⇒ `0`
with a warning — keep it 0. `plan` still rejects a Kepler passed to `install_driver`
directly.

**Mixed GPUs:** `intersect` over all GPUs croaks on conflict (V100 proprietary + B200 open)
— `plan` dies before any host change.

## Virtual displays and vGPU guests

- **Virtual displays skipped per line** (k17): `1af4` virtio, `1b36` QEMU, `15ad` VMware,
  `80ee` VirtualBox. Vendor checks first, so passthrough next to an emulated console still
  detects the real card; only-virtual ⇒ empty arrays.
- **vGPU by (device, subsystem) pair** (k24): only with an NVIDIA GPU, read-only
  `lspci -vmmnn -d 10de:` gives `subsystem_(vendor_)id` per slot (`0000:` domain
  normalised); `Rex::GPU::NVIDIA::VGPU` (NVIDIA's `sVgpuUsmTypes[]`, regenerate with
  `maint/gen-vgpu-types.pl`) sets `vgpu 0|1` (+`vgpu_type`). Unknown pair ⇒ 0, `compute`
  untouched. `plan` dies for any `vgpu` GPU after `already_installed`, so a working GRID
  driver passes.

## Multi-GPU fabrics

| Platform | How recognised | What Rex::GPU does |
|---|---|---|
| HGX A100/H100/H200 (NVSwitch on PCI) | `lspci -nn -d 10de:` class `0680`, IDs 1ac2/1af1/22a3 → `nvswitch => [...]` (k23) | Fabric Manager at exactly the driver version, service enabled/started |
| HGX B200/B300 (`hgx-nvlink5`) | GPU IDs 2901/2909/3182 via `Setup::nvlink_platform_ids` (overridable) — their NVSwitches are **not** on the host PCI bus | Fabric Manager + NVLink fabric (below, k56) |
| GB200/GB300 NVL72 (`nvl72`) | GPU IDs 2941/31c2/31c3 | info line only: multi-node NVLink needs `nvidia-imex`; no FM (it runs on the switch trays) |

**B200/B300 fabric (k56):**
- `fabric_manager_needed` is true for NVSwitch hosts **and** `nvlink_fabric_needed`. FM is
  the k23 path: candidate checked after the index refresh, installed at the driver's exact
  version, `nvidia-fabricmanager.service` enabled.
- nvlsm has **no own service**: FM's `nvidia-fabricmanager-start.sh` detects NVL5 (CX-7
  bridge `SW_MNG` VPD + `ibstat`) and starts nvlsm before `nv-fabricmanager`. FM stays
  required on 610+.
- `install_nvlink_fabric`: `warn_nvlink_kernel` (kernel < 5.17 warns unless
  `nvlink_kernel_backported` — the RHEL family, whose 5.14 carries backports and is
  NVIDIA-supported); `prepare_nvlink_fabric_source`; `nvlink_fabric_packages` **unversioned**
  (maintainer decision, as NVIDIA's gpu-driver-container does — nvlsm is not tied to the
  driver version); `load_ib_umad` (modules-load.d + `modprobe`, a failed modprobe warns).
- `check_nvlink_fabric` replaces a warning: `nvidia-smi -q` must show State `Completed` /
  Status `Success` for every GPU; re-read `fabric_state_poll` (12 × 10 s) while FM is
  active. Failure = one loud warning, never a die, `verify` unaffected.
- `nvlink_fabric_unavailable` dies in `plan`, read-only, where no nvlsm source is known:
  Ubuntu other than 22.04/24.04 or non-amd64, RHEL < 9, openSUSE, Debian without the
  CUDA-repo source.
- Retrofit (driver already installed): missing packages from the host's **own** sources
  only, no repo added (k50 rule); still missing ⇒ warning.

| Family | nvlink fabric packages | nvlsm source |
|---|---|---|
| Ubuntu | `nvlsm infiniband-diags libibumad3 linux-modules-extra-$kernel` | CUDA repo, B200/B300 only, see Ubuntu below |
| Debian | `nvlsm infiniband-diags libibumad3` | CUDA repo the driver already uses |
| RHEL | `nvlsm infiniband-diags libibumad` | CUDA repo the driver already uses |

FM package names: Ubuntu/Debian CUDA repo `nvidia-fabricmanager-570/575`, from 580
`nvidia-fabricmanager`; RHEL 9 `nvidia-fabric-manager` (570/575), from 580
`nvidia-fabricmanager`. `nvlink5[-NNN]` is an empty dummy from 610 (Ubuntu/Debian) and
absent on RHEL — never use it. NVIDIA announces `*-direct` FM names for RHEL from 620;
not handled until they exist.

## Distro matrix — `setup_class_for_os`

- **Debian** — enable `contrib non-free non-free-firmware` first, per recognised Debian
  archive entry in both `sources.list` and deb822 `*.sources` (k36/k40/k41: a `signed-by`
  naming only `debian-archive-*` keyrings decides alone; without it the URI must pass the
  overridable `is_debian_archive_uri`; keyring check `is_debian_archive_keyring`
  overridable too; unknown mirrors are left alone and warn with the override hint).
  Install `nvidia-driver` + `nvidia-smi` + the *running* kernel's headers only; non-free
  branch from a fixed table (11→470, 12→535, 13→550, else unknown). Blackwell on Debian
  12/13 uses NVIDIA's CUDA repo (`cuda-keyring`, `nvidia-driver-cuda` +
  `nvidia-kernel-open-dkms`, no non-free; k18). Never the `linux-headers-$arch`
  metapackage — it pulls a new kernel whose grub/initramfs post-install returns non-zero.
- **Ubuntu** — sources `-server` (newest via `apt-cache search`, `-open` filtered, ≥580),
  `-server-open` (≥580; Blackwell), pinned `nvidia-driver-580-server` (pre-Turing,
  candidate checked after `apt-get update`); empty search ⇒ die (no 570 fallback: the
  search matches 570 too). **No `nvidia-smi` in the package list**: on 24.04 it is a
  virtual package with no candidate and the metapackage pulls it anyway.
  B200/B300 only: the CUDA repo is added **after** driver + FM are verified (so the
  driver search never sees it), key extracted from the `cuda-keyring` deb — **never
  install `cuda-keyring`** here: its `Package: *` pin 600 would outrank Ubuntu's driver.
  `rex-gpu-nvlsm.pref` pins the origin to -1 and `nvlsm` alone to 500. If `cuda-keyring`
  is already installed, nothing is added.
- **RHEL/Rocky/Alma/CentOS** — EPEL + `crb`(≥9)/`powertools`(<9) + the CUDA repo. **v10+
  has no module streams**: install `kmod-nvidia-open-dkms` + `nvidia-driver` +
  `nvidia-driver-cuda` directly; <10 uses `dnf module enable nvidia-driver:open-dkms` +
  `nvidia-open`. Pre-Turing: stream `580-dkms` (<10) or a `*nvidia*580*` versionlock (10)
  with the proprietary `kmod-nvidia-latest-dkms` (k26). Major version from
  `_rhel_major_version`. lsb_release names (Rocky, RockyLinux, AlmaLinux, CentOSStream)
  are mapped locally because Rex's `is_redhat` misses them (k39, upstream RexOps/Rex#1661).
- **openSUSE Leap** — `rpm -e` stale `nvidia*`/`libnvidia*` first, add the GFX repo by
  **baseurl** (zypper can't parse yum `.repo` files), install the `signed-kmp-meta`
  package (`G06` for 15.x, `G07` for 16.x; pre-Turing: proprietary
  `nvidia-driver-G06-kmp-meta`), then `zypper addlock libnvidia-ml libnvidia-cfg` — the
  meta package co-installs kmp + userspace at one version; the lock stops a later update
  re-splitting them into a `Driver/library version mismatch`. No Fabric Manager source.
