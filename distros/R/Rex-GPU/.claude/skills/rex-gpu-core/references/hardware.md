# Rex::GPU — hardware and distro combinations

Read the section you are about to change. Every entry here is a solved trap in the code;
do not "simplify" one away without a ticket.

## GPU generations — `Rex::GPU::NVIDIA::Requirement`

`generations` (overridable) maps the PCI device ID to `{kernel_module open|proprietary|either,
min_branch, max_branch, compute}`. Rows cover 0000–2FFF gap-free plus 3182 / 31C2–31C3; narrower rows (2E12, 2342, 2348, the 88 single-ID floors of k107) sit ahead of the block they are in.

| Device IDs | Generation | Module | Branch | `compute` |
|---|---|---|---|---|
| < 1340 | Kepler or older | — | ≤ 470 (rejected) | 0 |
| 1340–1DF6 | Maxwell / Pascal / Volta | proprietary | ≤ 580 | 1 |
| 1DF7–22FF, 2400–25FF | Turing / Ampere | either | unbounded (floors below 470 not researched) | 1 |
| 2300–23FF | Hopper (2331 H100 PCIe first in 520.56.06) | either | ≥ 520 | 1 |
| 2600–28FF | Ada (2684 RTX 4090 first in 520.56.06) | either | ≥ 520 | 1 |
| 88 single IDs in those blocks | first listed after the block floor (k107: e.g. H200 2335 ≥ 550, RTX 4070 SUPER 2783 ≥ 550, H20 NVL16 230E ≥ 580, RTX A1000 25B0 ≥ 550) | either | ≥ 510 … 580 | 1 |
| 2342 | GH200 120GB/480GB (maintainer decision k72; driver README still lists Hopper as proprietary-supported) | open | ≥ 535 | 1 |
| 2348 | GH200 144G HBM3e (same) | open | ≥ 565 | 1 |
| 2900–2FFF | Blackwell (B200 2901/2909, GB200 2941, RTX 50xx, RTX PRO) | open | ≥ 570 | 1 |
| 2E12 | GB10 (DGX Spark) | open | ≥ 580 | 1 |
| 3182, 31C2–31C3 | B300 / GB300 | open | ≥ 580 | 1 |

Unknown ID ⇒ `either`, no bounds, `compute` undef → name rules.

**Floors from `supportedchips` (k107, checked 2026-11-26):** an ID's `min_branch` is the
branch of the first README that lists it (143 x86_64 + 137 aarch64 READMEs, 470.42.01 to
620.73.04, identical floors). It is a floor, never a ceiling: IDs drop out of single
releases and return (T4 `1EB8` absent 495.29.05–570.211.01, 2685 RTX 4090 D in 535.154.05
only, then from 550.40.07; 2336 listed only in 525.85.05). Whole branches only: Debian's
non-free is 470 (11), 535.261.03 (12), 550.163.01 (13), each listing every ID of its floor
branch. Effect: Ada/Hopper die on Debian 11 and on Debian releases without a known branch;
on Debian 12 (and 13 for 2689/233B/230E) IDs floored above the non-free branch take
NVIDIA's CUDA repo.

**Detection order in `_is_nvidia_compute`** (k45/k54/k55): Kepler-or-older row (`compute 0`)
first — skipped with warning "needs branch 470 … skipped", a skip not a die, so a K80 next
to an Ada leaves the Ada alone; then class `[0302]` ⇒ compute; then name rules naming only
Maxwell+ products (RTX, GTX 1xxx/9xx/745/750, GT 1xxx, GeForce MX, TITAN X/Xp/V/RTX,
Quadro M/P/T/GP/GV, Tesla M/P/V/T4, A100-style codes), no negative rules. Unknown ⇒ `0`
with a warning — keep it 0. `plan` still rejects a Kepler passed to `install_driver`
directly.

**Mixed GPUs:** `intersect` over all GPUs croaks on conflict (V100 proprietary + B200 open)
— `plan` dies before any host change.

## AMD GPUs — `Rex::GPU::AMD::Hardware` (k1)

Two overridable tables, first match wins: `targets` (gfx target → `compute`, `integrated`,
`driver`, `matrix`, `family`, `source`, optional `rocm_last`) and `devices` (explicit `ids` lists →
`gfx_target`, `product`, `source`). **Never ID ranges**: AMD interleaves families (`73F0`
is Navi 33 inside the Navi 23 `73E0`–`73FF` area). Every row cites its source; URLs and
revisions are in the comment above the tables (all checked 2026-10-31).

**Resolution:** the KFD topology's gfx target for the GPU's node (amdgpu running) wins over
the device row, with a warning when they differ; else the device row; else undef. `compute`,
`integrated` and `driver` come from the target row; no row ⇒ all undef ⇒ `[undecided]`, no
install.

**Decoding `gfx_target_version`** (decimal, `/sys/class/kfd/kfd/topology/nodes/N/properties`):
`major*10000 + minor*100 + stepping` → `sprintf 'gfx%d%x%x'` — 110501 → gfx1151, 90010 →
gfx90a, 90402 → gfx942. Source: `rocm_agent_enumerator` (`readFromKFD`) and libhsakmt's
`HSA_GET_GFX_VERSION_*`. CPU nodes report 0. KFD reports the *compiler* target, not the GC
IP version: GC 11.0.3 → gfx1101, GC 11.0.1/11.0.4 → gfx1103, GC 10.3.6/10.3.7 → gfx1036,
Raven2 GC 9.2.2 → gfx902. `vendor_id` (4098), `device_id`, `domain`, `location_id`
(bus<<8 | devfn) are decimal too. `HSA_OVERRIDE_GFX_VERSION` never changes the sysfs value.

**PCI class:** the kernel's amdgpu binds any vendor-1002 device at class 0300, 0380 or
1200 (pciidlist class match), so newer ASICs are not listed by ID. AMD's acceptance guides:
MI100/MI210/MI250 at "Display controller" (0380); MI300A/MI300X/MI325X/MI350X/MI355X at
"Processing accelerators" (1200). Strix Halo `1586` sits at 0380 (live, synapse). Both
detection paths take 0380/1200 for vendor 1002 only.

**`compute`:** 1 = listed for Linux in the latest release of a ROCm line AMD still ships
(ROCm Core SDK 10.1.0, 2026-10-05; the old line ended at 7.2.4 and lists nothing 10.1.0
lacks); 0 = a released target no current release lists; no row = undef. Per target, not
per product (ROCm ships code per target).

| gfx targets | `compute` | `integrated` | `driver` | `matrix` | What |
|---|---|---|---|---|---|
| 950, 942, 90a, 908 | 1 | 0 | dkms | instinct | Instinct MI350/MI355, MI300X/MI300A/MI325X, MI250/MI210, MI100 |
| 1201, 1200, 1100, 1101, 1102, 1030 | 1 | 0 | dkms | radeon | Radeon RX 9070/9060, 7900/7800/7700/7600, PRO W7900/W7800/W7700/V710, W6800/V620 |
| 1151, 1150, 1152, 1153, 1103 | 1 | 1 | inbox | ryzen | Ryzen AI Max, Ryzen AI 300/400, Phoenix/Hawk Point (Ryzen 200, 7840U) |
| 906 (`rocm_last` 6.3.3), 900 | 0 | 0 | — | — | MI50/MI60/Radeon VII, MI25/Vega 10 |
| 904, 803, 802, 701, 1010–1012, 1031, 1032, 1034 | 0 | 0 | — | — | older Radeon (in no ROCm release checked) |
| 902, 90c, 801, 700, 1013, 1033, 1035, **1036** | 0 | 1 | — | — | older APUs; gfx1036 = Raphael/Mendocino |
| 1154, 1170–1172, 1250, 1251 | no row | | | | KFD/LLVM know them, AMD makes no statement |

- `integrated`: LLVM AMDGPUUsage's dGPU/APU column. gfx942 covers the MI300X and the
  MI300A (APU): 0 — LLVM says dGPU, and the MI300A is a datacenter accelerator (k1).
- `driver`: AMD's 10.1.0 install guide — Instinct/Radeon "install the AMD GPU Driver
  (amdgpu)" = `amdgpu-dkms` from `repo.radeon.com/amdgpu/31.60`; "Supported Ryzen APUs
  require the inbox kernel driver included with Ubuntu" (Ubuntu only — matrix: 26.04.1 GA
  7.0, 24.04.5 HWE 7.0; the install page also names 24.04.4 and the OEM 6.14 kernel).
  undef for every compute-0 target.
- `matrix`: the table of AMD's ROCm 10.1.0 compatibility matrix (`[rocm-10.1-matrix]`)
  that lists the target — `instinct`, `radeon` or `ryzen` (Ryzen APU), each table with its
  own OS list. `matrix`, not the free text in `family`, tells Instinct, Radeon and Ryzen APU
  apart (k82). No compute-1 target is in two tables (gfx942 = MI300X and MI300A, both
  Instinct). undef = in no table: every compute-0 target, and a subclass row written
  without the field (only the value is checked).

**`devices`** (229 IDs, 35 rows): an ID gets a row only when a source maps it to its target
(kernel pciidlist chip → KFD case, `rocm_agent_enumerator`, libhsakmt, rocprofiler-compute,
or an AMD product → target list joined with libdrm `amdgpu.ids` names), the kernel/libdrm/
`pci.ids` lists the ID, and nothing contradicts. No listed ID changes target by revision.
Left out on purpose (KFD decides, else unknown):

- `1902` (Radeon 820M/840M): gfx1153 per rocprofiler-compute, gfx1152 per AMD's matrix and
  spec page for the 820M; matrix and spec page disagree on the 840M parts too. The gfx
  target picks the ROCm package (`amdrocm10.1-gfxNNNN`) — no guess.
- `7460`/`7461` PRO V710: gfx1101 (AMD docs) vs gfx1100 (`rocm_agent_enumerator`).
- `164E` Raphael, `1506` Mendocino, `13C0` Granite Ridge: no source maps them.
- `98E4` Stoney (sources disagree, no KFD); name-only `744B`, `73F0`, `7487`, `748B`,
  `749F`; one-tool-only `74B4`, `74BC`, `75A2`, `75B2`, `75C1`, `75D1`, `13F3`.

`15BF`/`15C8`/`1900`/`1901` (Phoenix/Hawk Point) have rows but no ID-level source: libdrm
names them 780M/760M/740M, and AMD lists those iGPUs only as gfx1103.

**Hetzner AX iGPUs (blast radius).** Rex::Rancher deploys AX servers with `gpu => 1`:

| CPU — iGPU ID | amdgpu not running | amdgpu running (KFD) | `gpu_setup` |
|---|---|---|---|
| Ryzen 7 7700 / 9 7950X — Raphael `164E` | undef, `[undecided]` | gfx1036 → 0, `[skip]` | nothing |
| Ryzen 9000 — Granite Ridge `13C0` | undef | what KFD reports (gfx1036 expected, unverified) | nothing |
| Ryzen 7 PRO 8700GE — Phoenix (`15BF` expected, unverified) | gfx1103 → 1, integrated 1 | same | **only with `amd_integrated => 1`** |

`compute` stays truthful; the guard is `integrated`: `gpu_setup` passes an integrated GPU to
`install_driver` only with `amd_integrated => 1`, else warns. Never set an APU target's
`integrated => 0` to unlock it or `compute => 0` to protect it — the Strix Halo host
(`1586`, gfx1151) is an APU that must install with `amd_integrated => 1`.

**Confirming a row on a host:** `lspci -nn -d 1002:` (class, `[1002:XXXX] (rev YY)`),
`grep -H . /sys/class/kfd/kfd/topology/nodes/*/properties | grep -E
'gfx_target_version|device_id|location_id|domain'`, `rocminfo` or `amd-smi static --asic`.

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
- **`Detect::Sysfs`** (k73): the same list (`virtual_display_vendor_ids`) per device, and
  the subsystem IDs straight from sysfs `subsystem_vendor`/`subsystem_device` (no slot
  matching) into the same `_mark_vgpu`. NVSwitch: class `0680` + an ID in
  `nvswitch_device_ids` only — no name to accept by.

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
  Headers: the *running* kernel's `linux-headers-$kernel` only (inherited from Setup::Apt,
  k69) — **never `linux-headers-generic`**: it follows the GA kernel and brings the wrong
  tree on HWE and vendor kernels (DGX Spark `6.17.0-1029-nvidia`). Accepted cost: a later
  kernel's headers are not pulled. Opt-in `Setup::UbuntuDrivers` (k69, not the
  `setup_class_for_os` default) resolves the `search` sources via read-only
  `ubuntu-drivers list --gpgpu` (no apt-cache fallback; missing command, non-zero exit or
  nothing named ⇒ unavailable ⇒ die before install); pinned-580 keeps its candidate check.
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
