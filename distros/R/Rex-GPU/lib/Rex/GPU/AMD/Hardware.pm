# ABSTRACT: AMD GPU hardware data: PCI device ID to gfx target, gfx target to ROCm support (experimental)

package Rex::GPU::AMD::Hardware;
our $VERSION = '0.006';
use v5.14.4;
use warnings;

use Carp qw( croak );
use Rex::Logger;

# ============================================================
#  Sources
# ============================================================
#
# Every row names its source (source => '...'), a primary one: AMD's ROCm
# documentation (compatibility matrix, GPU specifications, release notes),
# the Linux kernel / libdrm sources, or a live read of the hardware. A GPU
# without a row stays unknown -- compute undef, no driver from gpu_setup --
# never a guessed row. Rows are added by research with a citation, not from
# memory.
#
# All checked 2026-10-31 (karr k1, hardware curator):
#
#   [rocm-10.1-matrix]  https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html
#                       ROCm Core SDK 10.1.0 (2026-10-05), the latest release. The
#                       docs-10.0.0, docs-7.14.1 and docs-7.14.0 matrices list the
#                       same targets.
#   [rocm-10.1-specs]   https://rocm.docs.amd.com/en/latest/reference/gpu-arch-specs.html
#                       (10.1.0): product -> LLVM target
#   [rocm-10.1-install] https://rocm.docs.amd.com/en/latest/install/rocm.html (10.1.0):
#                       "For Instinct and Radeon devices, install the AMD GPU Driver
#                       (amdgpu)"; "Supported Ryzen APUs require the inbox kernel
#                       driver included with Ubuntu" (amdgpu-install ... --no-dkms)
#   [amdgpu-31.60]      https://instinct.docs.amd.com/projects/amdgpu-docs/en/latest/install/detailed-install/package-manager/package-manager-ubuntu.html
#                       AMD GPU Driver (amdgpu) 31.60.0 is "apt install amdgpu-dkms"
#                       from repo.radeon.com/amdgpu/31.60
#   [rocm-hist]         https://rocm.docs.amd.com/en/docs-7.2.4/downloads/compatibility-matrix-historical-6.0.csv
#                       ROCm 6.0.0 .. 7.2.4 (7.2.4, 2026-05-29: last release of the
#                       old ROCm line)
#   [rocm-sysreq]       https://rocm.docs.amd.com/projects/install-on-linux/en/docs-VERSION/reference/system-requirements.html
#                       for 6.0.0 6.1.0 6.1.2 6.2.0 6.2.4 6.3.0 6.3.3 6.4.0 6.4.3 7.0.0,
#                       and https://rocm.docs.amd.com/en/docs-5.7.1/release/gpu_os_support.html
#   [rocm-ryzen]        https://rocm.docs.amd.com/projects/radeon-ryzen/en/latest/docs/compatibility/compatibilityryz/native_linux/native_linux_compatibility.html
#                       (ROCm on Ryzen, Linux: 6.4.4, 7.0.2, 7.1.1, 7.2.1)
#   [rocm-all]          all of the release lists above: 5.7.1, 6.0.0 .. 7.2.4,
#                       7.14.0 .. 10.1.0 (5.0 .. 5.7.0 and older not checked)
#   [llvm]              https://llvm.org/docs/AMDGPUUsage.html, processor table,
#                       column "dGPU/APU" (LLVM 24.0.0git docs)
#   [kernel]            Linux, torvalds master a9547379cb38 (2026-10-30, 7.3.0-dev):
#                       drivers/gpu/drm/amd/amdgpu/amdgpu_drv.c pciidlist (ID ->
#                       CHIP_*), amdgpu_discovery.c (the GC version of the chips
#                       without a discovery table), amdkfd/kfd_device.c
#                       kgd2kfd_probe (chip or GC version -> gfx_target_version)
#   [rae]               github.com/ROCm/rocm-systems develop,
#                       projects/rocminfo/rocm_agent_enumerator @ bde60920b5a5
#                       (2026-09-22): ISA_TO_ID, gfx target -> device IDs
#   [hsakmt]            github.com/ROCm/rocm-systems develop @ 6a167157e268
#                       (2026-10-30), projects/rocr-runtime/libhsakmt/src/topology.c:
#                       gfxip_lookup_table, device ID -> gfx version
#   [rocprof]           github.com/ROCm/rocm-systems develop @ 9d29a1da3124
#                       (2026-08-07), projects/rocprofiler-compute/src/utils/
#                       mi_gpu_spec.yaml: gpu_arch -> chip_ids (decimal)
#   [libdrm]            gitlab.freedesktop.org/mesa/drm main @ 3b5e41a44cd1
#                       (2026-10-27), data/amdgpu.ids: (device ID, revision) ->
#                       marketing name
#   [synapse-kfd]       live read on a Strix Halo test host, 2026-10-31: PCI 1002:1586,
#                       class 0380, rev da; KFD gfx_target_version 110501 (gfx1151);
#                       Ryzen AI Max+ PRO 495 / Radeon 8065S
#   pci.ids 2026.10.30  names and codenames only; it never decides a row.
#
# Two tables, both lists of hashrefs returned by an overridable class method
# (like Rex::GPU::NVIDIA::Requirement's generations): targets() says what AMD
# supports for an LLVM gfx target, devices() which gfx target a PCI device ID
# is. A subclass adds or replaces rows by returning its own rows before
# $class->SUPER::targets / ->SUPER::devices -- the first matching row wins.
#
# targets, compute: 1 for a gfx target listed for Linux in the latest release
# of a ROCm line AMD still ships -- ROCm Core SDK 10.1.0 [rocm-10.1-matrix];
# the old line's last release, 7.2.4, with its Ryzen/Radeon 7.2.1 pages, lists
# no target that 10.1.0 lacks. 0 for a released target that no current release
# lists: gfx906 (deprecated 6.0.0-6.3.3, "Unsupported" from 6.4.0), gfx900
# ("Unsupported" in every release checked), and the older and integrated
# targets that no release of [rocm-all] lists. The host gets only the kernel
# driver, but compute means "ROCm-capable today", as for NVIDIA (Kepler is 0
# though old CUDA still runs on it); rocm_last names the last release where
# one is known, for a subclass that wants an older ROCm. gfx1154, gfx1170,
# gfx1171, gfx1172, gfx1250 and gfx1251 (KFD and LLVM know them, AMD makes no
# support statement) have no row: unknown. The verdict is per gfx target, not
# per product -- ROCm ships code per target -- so the Radeon RX 6800/6900
# (gfx1030) and the W7500/W7400 (gfx1102) are 1 although AMD names other
# products of those targets.
#
# targets, integrated: LLVM's dGPU/APU column [llvm]. gfx942 covers the
# MI300X (discrete) and the MI300A (an APU); LLVM files it as dGPU, and the
# MI300A is a datacenter accelerator, not client integrated graphics:
# integrated => 0 (karr k1). gfx942 is the only target covering both.
#
# targets, driver: 'dkms' for every target of the 10.1.0 Instinct and Radeon
# tables ([rocm-10.1-matrix] "Supported AMD GPU Driver (amdgpu) versions"
# 31.60.0 ...; [rocm-10.1-install] "For Instinct and Radeon devices, install
# the AMD GPU Driver (amdgpu)", which is amdgpu-dkms [amdgpu-31.60]); 'inbox'
# for the Ryzen APU table ([rocm-10.1-matrix] "Inbox kernel driver in supported
# Ubuntu version"; [rocm-10.1-install]); undef where AMD says nothing, i.e.
# every compute 0 target.
#
# targets, matrix: the table of [rocm-10.1-matrix] that lists the gfx target,
# as the row's source names it -- 'instinct' (Instinct table), 'radeon'
# (Radeon table), 'ryzen' (Ryzen APU table) -- and undef for every compute 0
# target (no table lists it). Each table has its own operating systems, so
# this field, never the free text in family, tells an Instinct from a Radeon
# (karr k82). Per target, like compute: the RX 6800/6900 are 'radeon' with
# gfx1030. No compute 1 target is in two tables: gfx942 covers the MI300X and
# the MI300A, both in the Instinct table; gfx906 (MI50/MI60 and Radeon VII)
# is in none. In the rows below matrix is set exactly when compute is 1,
# 'ryzen' goes with driver 'inbox', 'instinct' and 'radeon' with 'dkms'.
# _check_target_row checks only the value, as for driver: a subclass row
# written without the field stays valid.
#
# devices: an ID gets a row only when (a) a source maps it to its gfx target --
# the kernel (pciidlist chip -> KFD case), [rae], [hsakmt], [rocprof], or an
# AMD product -> target list ([rocm-10.1-matrix], [rocm-10.1-specs], [llvm])
# joined with [libdrm]'s (ID, revision) -> product name; (b) the kernel's
# pciidlist, [libdrm] or pci.ids lists the ID; and (c) no source contradicts
# it. Every ID below has one gfx target across all its known revisions, so no
# row needs the PCI revision. Left out on purpose -- they fall back to what the
# running driver reports (KFD), else stay unknown:
#   1902        [rocprof] gfx1153 ("rdna35_gorgon_point"), but [libdrm] puts the
#               Radeon 820M on 1902, and [rocm-10.1-matrix] and
#               [rocm-10.1-specs] list the 820M (Ryzen AI 5 330) as gfx1152. The
#               two disagree on the 840M too: the matrix files Ryzen AI 7 445,
#               AI 5 PRO 435, AI 5 435 and AI 5 430 as gfx1153, the specs page
#               as gfx1152 (it has no gfx1153 at all). The gfx target picks the
#               ROCm package, so no guess.
#   7460 7461   Radeon PRO V710 (and MxGPU): gfx1101 per [rocm-10.1-matrix],
#               [rocm-10.1-specs] and [rocm-sysreq] 6.4.3, gfx1100 per [rae]
#               ("Navi31 ... Pro V710").
#   98e4        Stoney: [rae] gfx801, [llvm] stoney = gfx810, and the [kernel]
#               KFD has no Stoney case (no KFD node at all).
#   164e 1506 13c0
#               Raphael, Mendocino, Granite Ridge (Ryzen 7000/9000 desktop and
#               server CPUs, "Radeon 610M"): no AMD source maps these IDs. A
#               running amdgpu reports Raphael and Mendocino (GC 10.3.6/10.3.7)
#               as gfx1036 [kernel] -- compute 0.
#   744b 73f0 7487 748b 749f
#               W7900D and Navi 33 SKUs: names only ([libdrm], pci.ids).
#   74b4 74bc 75a2 75b2
#               only in [rocprof] (MI300A VF, MI308X HF VF, "MI358" and its VF),
#               in no device listing; its VF IDs follow a pattern (physical +
#               0x14 for gfx942, + 0x10 for gfx950).
#   75c1 75d1   [rocprof] gfx1250, a target without a row.
#   13f3        only [rae] (gfx1013), in no device listing.
#   SI, Bonaire, Kabini, Mullins, Topaz: the [kernel] KFD has no case for them.

my %DRIVERS  = map { $_ => 1 } qw( inbox dkms );
my %MATRICES = map { $_ => 1 } qw( instinct radeon ryzen );


sub targets {
  return (
    # --- CDNA, Instinct (discrete; AMD: AMD GPU Driver = amdgpu-dkms) ----------
    { gfx_target => 'gfx950', compute => 1, integrated => 0, driver => 'dkms', matrix => 'instinct',
      family     => 'CDNA 4 (Instinct MI350X, MI355X, MI350P)',
      source     => '[rocm-10.1-matrix] Instinct table, AMD GPU Driver 31.60.0..30.10.2; '
        .'listed 7.0.0-7.2.4 [rocm-hist] and 7.14.0-10.1.0; [llvm] dGPU' },
    { gfx_target => 'gfx942', compute => 1, integrated => 0, driver => 'dkms', matrix => 'instinct',
      family     => 'CDNA 3 (Instinct MI300X, MI300A, MI325X)',
      source     => '[rocm-10.1-matrix] Instinct table, AMD GPU Driver 31.60.0..30.10.2; '
        .'listed 6.0.0-7.2.4 [rocm-hist] and 7.14.0-10.1.0; [llvm] dGPU (the MI300A is an '
        .'APU, but a datacenter accelerator: integrated 0, karr k1)' },
    { gfx_target => 'gfx90a', compute => 1, integrated => 0, driver => 'dkms', matrix => 'instinct',
      family     => 'CDNA 2 (Instinct MI250X, MI250, MI210)',
      source     => '[rocm-10.1-matrix] Instinct table, AMD GPU Driver 31.60.0..30.10.2; '
        .'listed 5.7.1 [rocm-sysreq], 6.0.0-7.2.4 [rocm-hist] and 7.14.0-10.1.0; [llvm] dGPU' },
    { gfx_target => 'gfx908', compute => 1, integrated => 0, driver => 'dkms', matrix => 'instinct',
      family     => 'CDNA (Instinct MI100)',
      source     => '[rocm-10.1-matrix] Instinct table, AMD GPU Driver 31.60.0..30.10.2; '
        .'listed 5.7.1 [rocm-sysreq], 6.0.0-7.2.4 [rocm-hist] and 7.14.0-10.1.0; [llvm] dGPU' },

    # --- RDNA, Radeon (discrete; AMD: AMD GPU Driver = amdgpu-dkms) -----------
    { gfx_target => 'gfx1201', compute => 1, integrated => 0, driver => 'dkms', matrix => 'radeon',
      family     => 'RDNA 4 (Navi 48: Radeon RX 9070 XT/GRE/9070, '
        .'AI PRO R9700/R9700S/R9600D/R9600)',
      source     => '[rocm-10.1-matrix] Radeon table, AMD GPU Driver 31.60.0/31.50.0; '
        .'listed 6.4.1-7.2.4 [rocm-hist] and 7.14.0-10.1.0; [llvm] dGPU' },
    { gfx_target => 'gfx1200', compute => 1, integrated => 0, driver => 'dkms', matrix => 'radeon',
      family     => 'RDNA 4 (Navi 44: Radeon RX 9060 XT/9060, RX 9050)',
      source     => '[rocm-10.1-matrix] Radeon table, AMD GPU Driver 31.60.0/31.50.0; '
        .'listed 6.4.1-7.2.4 [rocm-hist] and 7.14.0-10.1.0; [llvm] dGPU' },
    { gfx_target => 'gfx1100', compute => 1, integrated => 0, driver => 'dkms', matrix => 'radeon',
      family     => 'RDNA 3 (Navi 31: Radeon RX 7900 XTX/XT/GRE, PRO W7900, PRO W7800)',
      source     => '[rocm-10.1-matrix] Radeon table, AMD GPU Driver 31.60.0/31.50.0; '
        .'listed 5.7.1 [rocm-sysreq], 6.0.0-7.2.4 [rocm-hist] and 7.14.0-10.1.0; [llvm] dGPU' },
    { gfx_target => 'gfx1101', compute => 1, integrated => 0, driver => 'dkms', matrix => 'radeon',
      family     => 'RDNA 3 (Navi 32: Radeon RX 7800 XT/7700 XT/7700, PRO W7700, PRO V710)',
      source     => '[rocm-10.1-matrix] Radeon table, AMD GPU Driver 31.60.0/31.50.0; '
        .'listed 6.4.1-7.2.4 [rocm-hist] and 7.14.0-10.1.0; [llvm] dGPU' },
    { gfx_target => 'gfx1102', compute => 1, integrated => 0, driver => 'dkms', matrix => 'radeon',
      family     => 'RDNA 3 (Navi 33: Radeon RX 7600)',
      source     => '[rocm-10.1-matrix] Radeon table (RX 7600 only), AMD GPU Driver '
        .'31.60.0/31.50.0; listed 7.14.0-10.1.0 only, not in [rocm-hist]; [llvm] dGPU' },
    { gfx_target => 'gfx1030', compute => 1, integrated => 0, driver => 'dkms', matrix => 'radeon',
      family     => 'RDNA 2 (Navi 21: Radeon PRO W6800, PRO V620, RX 6800/6900)',
      source     => '[rocm-10.1-matrix] Radeon table (PRO W6800 and PRO V620 only), AMD GPU '
        .'Driver 31.60.0/31.50.0; listed 5.7.1 [rocm-sysreq], 6.0.0-7.2.4 [rocm-hist] and '
        .'7.14.0-10.1.0; [llvm] dGPU' },

    # --- RDNA 3.5 / 3, Ryzen APUs (integrated; AMD: inbox driver only) --------
    { gfx_target => 'gfx1151', compute => 1, integrated => 1, driver => 'inbox', matrix => 'ryzen',
      family     => 'RDNA 3.5 Ryzen AI Max APU (Strix Halo / Gorgon Halo)',
      source     => '[rocm-10.1-matrix] Ryzen APU table: gfx1151, "Inbox kernel driver in '
        .'supported Ubuntu version"; listed [rocm-ryzen] 6.4.4-7.2.1 and 7.14.0-10.1.0; '
        .'[llvm] APU; [synapse-kfd]' },
    { gfx_target => 'gfx1150', compute => 1, integrated => 1, driver => 'inbox', matrix => 'ryzen',
      family     => 'RDNA 3.5 Ryzen AI APU (Strix Point / Gorgon Point: Radeon 890M, 880M)',
      source     => '[rocm-10.1-matrix] Ryzen APU table, inbox kernel driver; listed '
        .'[rocm-ryzen] 6.4.4-7.2.1 and 7.14.0-10.1.0; [llvm] APU' },
    { gfx_target => 'gfx1152', compute => 1, integrated => 1, driver => 'inbox', matrix => 'ryzen',
      family     => 'RDNA 3.5 Ryzen AI APU (Krackan Point: Radeon 860M, 840M, 820M)',
      source     => '[rocm-10.1-matrix] Ryzen APU table, inbox kernel driver; listed '
        .'7.14.0-10.1.0 only; [llvm] APU' },
    { gfx_target => 'gfx1153', compute => 1, integrated => 1, driver => 'inbox', matrix => 'ryzen',
      family     => 'RDNA 3.5 Ryzen AI 400 APU (Radeon 840M)',
      source     => '[rocm-10.1-matrix] Ryzen APU table (Ryzen AI 7 445, AI 5 PRO 435, '
        .'AI 5 435, AI 5 430), inbox kernel driver; listed 7.14.0-10.1.0 only; '
        .'[rocm-10.1-specs] lists those parts as gfx1152 and has no gfx1153; [llvm] APU' },
    { gfx_target => 'gfx1103', compute => 1, integrated => 1, driver => 'inbox', matrix => 'ryzen',
      family     => 'RDNA 3 Ryzen APU (Phoenix / Hawk Point: Radeon 780M, 760M, 740M)',
      source     => '[rocm-10.1-matrix] Ryzen APU table (Ryzen 200 / PRO 200), inbox kernel '
        .'driver; [rocm-10.1-specs] also the Ryzen 7 7840U; listed 7.14.0-10.1.0 only; '
        .'[llvm] APU' },

    # --- known, not supported by any current ROCm release ---------------------
    { gfx_target => 'gfx906', compute => 0, integrated => 0, driver => undef, matrix => undef,
      rocm_last  => '6.3.3',
      family     => 'GCN 5.1 (Vega 20: Instinct MI50/MI60, Radeon VII, Radeon PRO VII)',
      source     => '[rocm-sysreq] supported 5.7.1, deprecated 6.0.0-6.3.3 (6.0.0: MI50 '
        .'deprecated, PRO VII and VII supported), "Unsupported" 6.4.0-7.0.0; absent from '
        .'[rocm-hist] and [rocm-10.1-matrix]; [llvm] dGPU' },
    { gfx_target => 'gfx900', compute => 0, integrated => 0, driver => undef, matrix => undef,
      family     => 'GCN 5 (Vega 10: Instinct MI25, Radeon RX Vega 56/64)',
      source     => '[rocm-sysreq] "Unsupported" 5.7.1-7.0.0; [llvm] dGPU' },
    { gfx_target => 'gfx904', compute => 0, integrated => 0, driver => undef, matrix => undef,
      family     => 'GCN 5 (Vega 12)',
      source     => 'in no release of [rocm-all]; [kernel] KFD 90004; [llvm] dGPU' },
    { gfx_target => 'gfx902', compute => 0, integrated => 1, driver => undef, matrix => undef,
      family     => 'GCN 5 Ryzen APU (Raven Ridge / Picasso)',
      source     => 'in no release of [rocm-all]; [kernel] KFD 90002; [llvm] APU' },
    { gfx_target => 'gfx90c', compute => 0, integrated => 1, driver => undef, matrix => undef,
      family     => 'GCN 5 Ryzen APU (Renoir / Lucienne / Cezanne / Barcelo)',
      source     => 'in no release of [rocm-all]; [kernel] KFD 90012; [llvm] APU' },
    { gfx_target => 'gfx803', compute => 0, integrated => 0, driver => undef, matrix => undef,
      family     => 'GCN 3/4 (Fiji, Polaris, Vega M)',
      source     => 'in no release of [rocm-all]; [kernel] KFD 80003; [llvm] dGPU' },
    { gfx_target => 'gfx802', compute => 0, integrated => 0, driver => undef, matrix => undef,
      family     => 'GCN 3 (Tonga)',
      source     => 'in no release of [rocm-all]; [kernel] KFD 80002; [llvm] dGPU' },
    { gfx_target => 'gfx801', compute => 0, integrated => 1, driver => undef, matrix => undef,
      family     => 'GCN 3 APU (Carrizo)',
      source     => 'in no release of [rocm-all]; [kernel] KFD 80001; [llvm] APU' },
    { gfx_target => 'gfx701', compute => 0, integrated => 0, driver => undef, matrix => undef,
      family     => 'GCN 2 (Hawaii)',
      source     => 'in no release of [rocm-all]; [kernel] KFD 70001, only with '
        .'amdgpu.exp_hw_support; [llvm] dGPU' },
    { gfx_target => 'gfx700', compute => 0, integrated => 1, driver => undef, matrix => undef,
      family     => 'GCN 2 APU (Kaveri)',
      source     => 'in no release of [rocm-all]; [kernel] KFD 70000; [llvm] APU' },
    { gfx_target => 'gfx1010', compute => 0, integrated => 0, driver => undef, matrix => undef,
      family     => 'RDNA 1 (Navi 10)',
      source     => 'in no release of [rocm-all]; [kernel] KFD 100100; [llvm] dGPU' },
    { gfx_target => 'gfx1011', compute => 0, integrated => 0, driver => undef, matrix => undef,
      family     => 'RDNA 1 (Navi 12)',
      source     => 'in no release of [rocm-all]; [kernel] KFD 100101; [llvm] dGPU' },
    { gfx_target => 'gfx1012', compute => 0, integrated => 0, driver => undef, matrix => undef,
      family     => 'RDNA 1 (Navi 14)',
      source     => 'in no release of [rocm-all]; [kernel] KFD 100102; [llvm] dGPU' },
    { gfx_target => 'gfx1013', compute => 0, integrated => 1, driver => undef, matrix => undef,
      family     => 'RDNA 1 APU (Cyan Skillfish)',
      source     => 'in no release of [rocm-all]; [kernel] KFD 100103; [llvm] APU' },
    { gfx_target => 'gfx1031', compute => 0, integrated => 0, driver => undef, matrix => undef,
      family     => 'RDNA 2 (Navi 22)',
      source     => 'in no release of [rocm-all]; [kernel] KFD 100301; [llvm] dGPU' },
    { gfx_target => 'gfx1032', compute => 0, integrated => 0, driver => undef, matrix => undef,
      family     => 'RDNA 2 (Navi 23)',
      source     => 'in no release of [rocm-all]; [kernel] KFD 100302; [llvm] dGPU' },
    { gfx_target => 'gfx1033', compute => 0, integrated => 1, driver => undef, matrix => undef,
      family     => 'RDNA 2 APU (Van Gogh)',
      source     => 'in no release of [rocm-all]; [kernel] KFD 100303; [llvm] APU' },
    { gfx_target => 'gfx1034', compute => 0, integrated => 0, driver => undef, matrix => undef,
      family     => 'RDNA 2 (Navi 24)',
      source     => 'in no release of [rocm-all]; [kernel] KFD 100304; [llvm] dGPU' },
    { gfx_target => 'gfx1035', compute => 0, integrated => 1, driver => undef, matrix => undef,
      family     => 'RDNA 2 Ryzen APU (Rembrandt)',
      source     => 'in no release of [rocm-all]; [kernel] KFD 100305; [llvm] APU' },
    { gfx_target => 'gfx1036', compute => 0, integrated => 1, driver => undef, matrix => undef,
      family     => 'RDNA 2 Ryzen APU (Raphael / Mendocino)',
      source     => 'in no release of [rocm-all]; [kernel] KFD 100306 for GC 10.3.6 and '
        .'10.3.7; [llvm] APU' },
  );
}


sub devices {
  return (
    # --- Instinct ---------------------------------------------------------------
    { ids => [qw( 75a0 75a3 75a8 )], gfx_target => 'gfx950',
      product => 'Instinct MI350X (75a0), MI355X (75a3), MI350P (75a8)',
      source  => '[rocprof] gfx950; [libdrm] names, gfx950 per [rocm-10.1-matrix]' },
    { ids => [qw( 75b0 75b3 75b8 )], gfx_target => 'gfx950',
      product => 'Instinct MI350X / MI355X / MI350P VF (SR-IOV)',
      source  => '[rocprof] gfx950 (virtual); [libdrm] names' },
    { ids => [qw( 74a0 74a1 74a2 74a5 74a8 74a9 )], gfx_target => 'gfx942',
      product => 'Instinct MI300A (74a0), MI300X (74a1), MI308X (74a2; rev A1: MI300X), '
        .'MI325X (74a5), MI308X HF (74a8), MI300X HF (74a9)',
      source  => '[rocprof] gfx942; [rae] gfx942 (74a1 74a2 74a5 74a9); [libdrm] names' },
    { ids => [qw( 74b5 74b6 74b9 74bd )], gfx_target => 'gfx942',
      product => 'Instinct MI300X (74b5), MI308X (74b6), MI325X (74b9), MI300X HF (74bd) '
        .'VF (SR-IOV)',
      source  => '[rocprof] gfx942 (virtual); [rae] gfx942 (74b5 74b6 74bd); [libdrm] names' },
    { ids => [qw( 7408 740c 740f 7410 )], gfx_target => 'gfx90a',
      product => 'Instinct MI250X (7408), MI250X / MI250 (740c), MI210 (740f), MI210 VF (7410)',
      source  => '[kernel] CHIP_ALDEBARAN, KFD 90010; [rae]; [hsakmt]; [libdrm] names' },
    { ids => [qw( 738c 7388 738e 7390 )], gfx_target => 'gfx908',
      product => 'Instinct MI100 (Arcturus)',
      source  => '[kernel] CHIP_ARCTURUS, KFD 90008; [rae]; [hsakmt]; [rocprof] (738c)' },

    # --- Radeon -----------------------------------------------------------------
    { ids => [qw( 7550 7551 )], gfx_target => 'gfx1201',
      product => 'Navi 48: Radeon RX 9070 XT/GRE/9070 (7550), AI PRO R9700/R9700S/R9600D (7551)',
      source  => '[rae] gfx1201; [libdrm] names, gfx1201 per [rocm-10.1-matrix]' },
    { ids => [qw( 7590 )], gfx_target => 'gfx1200',
      product => 'Navi 44: Radeon RX 9060 XT/XT LP/9060, RX 9050',
      source  => '[rae] gfx1200; [libdrm] names, gfx1200 per [rocm-10.1-matrix]' },
    { ids => [qw( 7448 7449 744a 744c 745e )], gfx_target => 'gfx1100',
      product => 'Navi 31: Radeon PRO W7900 (7448), PRO W7800 48GB (7449), PRO W7900 Dual Slot '
        .'(744a), RX 7900 XTX/XT/GRE/7900M (744c), PRO W7800 (745e)',
      source  => '[rae] gfx1100; [libdrm] names, gfx1100 per [rocm-10.1-matrix]' },
    { ids => [qw( 7470 747e )], gfx_target => 'gfx1101',
      product => 'Navi 32: Radeon PRO W7700 (7470), RX 7800 XT/7700 XT/7700/7800M (747e)',
      source  => '[rae] gfx1101; [libdrm] names, gfx1101 per [rocm-10.1-matrix]' },
    { ids => [qw( 7480 7481 7483 7489 7499 )], gfx_target => 'gfx1102',
      product => 'Navi 33: Radeon RX 7600/7600 XT/7650 GRE, PRO W7600 (7480), Steam Machine '
        .'(7481), RX 7600M (7483), PRO W7500 (7489), PRO W7400, RX 7400/7300 (7499)',
      source  => '[rae] gfx1102; [libdrm] names: RX 7600 (7480 rev CF) gfx1102 per '
        .'[rocm-10.1-matrix], RX 7600 XT (7480 rev C0) per [llvm]' },
    { ids => [qw( 73a0 73a1 73a2 73a3 73a5 73a8 73a9 73ab 73ac 73ad 73ae 73af 73bf )],
      gfx_target => 'gfx1030',
      product => 'Navi 21: Radeon PRO V620 (73a1, MxGPU 73ae), PRO W6800 (73a3), RX 6950 XT '
        .'(73a5), RX 6900 XT (73af), RX 6800/6800 XT/6900 XT (73bf)',
      source  => '[kernel] CHIP_SIENNA_CICHLID, KFD 100300; [rae]; [hsakmt] (not 73af); '
        .'[libdrm] names' },

    # --- Ryzen APUs ---------------------------------------------------------------
    { ids => [qw( 1586 )], gfx_target => 'gfx1151',
      product => 'Strix Halo iGPU (seen as Radeon 8065S, Ryzen AI Max+ PRO 495)',
      source  => '[synapse-kfd]; [rocprof] gfx1151; [libdrm] Radeon 8060S/8050S, gfx1151 per '
        .'[rocm-10.1-matrix]' },
    { ids => [qw( 150e )], gfx_target => 'gfx1150',
      product => 'Strix Point iGPU (Radeon 890M / 880M)',
      source  => '[rocprof] gfx1150; [libdrm] Radeon 890M/880M, gfx1150 per [rocm-10.1-matrix] '
        .'and [rocm-10.1-specs]' },
    { ids => [qw( 1114 )], gfx_target => 'gfx1152',
      product => 'Krackan Point iGPU (Radeon 860M / 840M)',
      source  => '[rocprof] gfx1152; [libdrm] Radeon 860M/840M -- the 860M is gfx1152 only, in '
        .'[rocm-10.1-matrix] and [rocm-10.1-specs]' },
    { ids => [qw( 15bf 15c8 1900 1901 )], gfx_target => 'gfx1103',
      product => 'Phoenix1 (15bf), Phoenix2 (15c8), HawkPoint1 (1900), HawkPoint2 (1901) iGPU: '
        .'Radeon 780M / 760M / 740M',
      source  => '[libdrm] Radeon 780M/760M/740M -- gfx1103 only, in [rocm-10.1-matrix] (Ryzen '
        .'200 / PRO 200) and [rocm-10.1-specs] (also Ryzen 7 7840U); [kernel] KFD 110003 for '
        .'GC 11.0.1 and 11.0.4; codenames: pci.ids' },

    # --- compute 0 targets ----------------------------------------------------------
    { ids => [qw( 66a0 66a1 66a2 66a3 66a4 66a7 66af )], gfx_target => 'gfx906',
      product => 'Vega 20: Instinct MI50/MI60, Radeon PRO VII (66a1), Radeon VII (66af)',
      source  => '[kernel] CHIP_VEGA20, KFD 90006; [rae]; [hsakmt]' },
    { ids => [qw( 6860 6861 6862 6863 6864 6867 6868 6869 686a 686b 686c 686d 686e 686f 687f )],
      gfx_target => 'gfx900',
      product => 'Vega 10: Instinct MI25, PRO V340 (6860), Vega Frontier Edition (6863), '
        .'RX Vega 56/64 (687f)',
      source  => '[kernel] CHIP_VEGA10, KFD 90000; [rae]; [hsakmt] (not 686f)' },
    { ids => [qw( 69a0 69a1 69a2 69a3 69af )], gfx_target => 'gfx904',
      product => 'Vega 12',
      source  => '[kernel] CHIP_VEGA12, KFD 90004; [rae]; [hsakmt]' },
    { ids => [qw( 15dd 15d8 )], gfx_target => 'gfx902',
      product => 'Raven Ridge (15dd), Picasso / Raven 2 (15d8) iGPU',
      source  => '[kernel] CHIP_RAVEN, KFD 90002; [rae]; [hsakmt]' },
    { ids => [qw( 15e7 1636 1638 164c )], gfx_target => 'gfx90c',
      product => 'Barcelo (15e7), Renoir (1636), Cezanne (1638), Lucienne (164c) iGPU',
      source  => '[kernel] CHIP_RENOIR, KFD 90012; [rae]; [hsakmt]' },
    { ids => [qw( 7300 730f 67c0 67c1 67c2 67c4 67c7 67c8 67c9 67ca 67cc 67cf 67d0 67d4 67df
                  6fdf 67e0 67e1 67e3 67e7 67e8 67e9 67eb 67ef 67ff 6980 6981 6985 6986 6987
                  698f 6995 6997 699f 694c 694e 694f )],
      gfx_target => 'gfx803',
      product => 'Fiji, Polaris 10/11/12, Vega M',
      source  => '[kernel] CHIP_FIJI/POLARIS10/POLARIS11/POLARIS12/VEGAM, KFD 80003; [rae] and '
        .'[hsakmt] (not 67d4, 698f)' },
    { ids => [qw( 6920 6921 6928 6929 692b 692f 6930 6938 6939 693b )], gfx_target => 'gfx802',
      product => 'Tonga',
      source  => '[kernel] CHIP_TONGA, KFD 80002; [rae] and [hsakmt] (not 693b)' },
    { ids => [qw( 9870 9874 9875 9876 9877 )], gfx_target => 'gfx801',
      product => 'Carrizo iGPU',
      source  => '[kernel] CHIP_CARRIZO, KFD 80001; [rae]; [hsakmt]' },
    { ids => [qw( 67a0 67a1 67a2 67a8 67a9 67aa 67b0 67b1 67b8 67b9 67ba 67be )],
      gfx_target => 'gfx701',
      product => 'Hawaii: FirePro W9100, Radeon R9 290/390',
      source  => '[kernel] CHIP_HAWAII, KFD 70001 (only with amdgpu.exp_hw_support); [rae]; '
        .'[hsakmt]' },
    { ids => [qw( 1304 1305 1306 1307 1309 130a 130b 130c 130d 130e 130f 1310 1311 1312 1313
                  1315 1316 1317 1318 131b 131c 131d )],
      gfx_target => 'gfx700',
      product => 'Kaveri iGPU',
      source  => '[kernel] CHIP_KAVERI, KFD 70000; [rae]; [hsakmt]' },
    { ids => [qw( 7310 7312 7318 7319 731a 731b 731e 731f )], gfx_target => 'gfx1010',
      product => 'Navi 10: Radeon RX 5700/5700 XT/5600 XT, PRO W5700X',
      source  => '[kernel] CHIP_NAVI10, KFD 100100; [rae]; [hsakmt] (not 7319, 731b)' },
    { ids => [qw( 7360 7362 )], gfx_target => 'gfx1011',
      product => 'Navi 12: Radeon PRO V520/V540, PRO 5600M',
      source  => '[kernel] CHIP_NAVI12, KFD 100101; [rae]; [hsakmt]' },
    { ids => [qw( 7340 7341 7347 734f )], gfx_target => 'gfx1012',
      product => 'Navi 14: Radeon RX 5500/5500 XT/5300M, PRO W5300M',
      source  => '[kernel] CHIP_NAVI14, KFD 100102; [rae]; [hsakmt] (not 734f)' },
    { ids => [qw( 13db 13f9 13fa 13fb 13fc 13fe 143f )], gfx_target => 'gfx1013',
      product => 'Cyan Skillfish APU',
      source  => '[kernel] CHIP_CYAN_SKILLFISH, KFD 100103 for both its GC versions, 10.1.3 '
        .'and 10.1.4 (13fe/143f read theirs from the hardware); [rae] (13f9 13fa 13fb 13fc); '
        .'[hsakmt] (not 13db)' },
    { ids => [qw( 73c0 73c1 73c3 73da 73db 73dc 73dd 73de 73df )], gfx_target => 'gfx1031',
      product => 'Navi 22: Radeon RX 6700/6700 XT/6750 XT',
      source  => '[kernel] CHIP_NAVY_FLOUNDER, KFD 100301; [rae]; [hsakmt]' },
    { ids => [qw( 73e0 73e1 73e2 73e3 73e8 73e9 73ea 73eb 73ec 73ed 73ef 73ff )],
      gfx_target => 'gfx1032',
      product => 'Navi 23: Radeon RX 6600/6600 XT',
      source  => '[kernel] CHIP_DIMGREY_CAVEFISH, KFD 100302; [rae]; [hsakmt] (not 73e3)' },
    { ids => [qw( 163f )], gfx_target => 'gfx1033',
      product => 'Van Gogh APU (AMD Custom GPU 0405)',
      source  => '[rae]; [hsakmt]; [kernel] KFD 100303 for GC 10.3.1 (Van Gogh)' },
    { ids => [qw( 7420 7421 7422 7423 7424 743f )], gfx_target => 'gfx1034',
      product => 'Navi 24: Radeon RX 6300 (7424), RX 6400/6500 XT (743f)',
      source  => '[kernel] CHIP_BEIGE_GOBY, KFD 100304; [rae] and [hsakmt] (not 7424)' },
    { ids => [qw( 164d 1681 )], gfx_target => 'gfx1035',
      product => 'Rembrandt iGPU (Radeon 660M / 680M)',
      source  => '[kernel] CHIP_YELLOW_CARP, KFD 100305; [rae]; [hsakmt]' },
  );
}


sub target {
  my ( $class, $gfx ) = @_;
  return unless defined $gfx && $gfx =~ /\Agfx[0-9a-f]+\z/i;
  $gfx = lc $gfx;
  for my $row ($class->targets) {
    $class->_check_target_row($row);
    return $row if $row->{gfx_target} eq $gfx;
  }
  return;
}


sub for_device_id {
  my ( $class, $id ) = @_;
  $id = $class->_device_id($id) // return;
  for my $row ($class->devices) {
    $class->_check_device_row($row);
    return $row if grep { lc($_) eq $id } @{ $row->{ids} };
  }
  return;
}

sub gfx_target_for_device_id {
  my ( $class, $id ) = @_;
  my $row = $class->for_device_id($id) or return;
  return lc $row->{gfx_target};
}


sub gfx_target_from_version {
  my ( $class, $version ) = @_;
  return unless defined $version && $version =~ /\A\d+\z/ && $version > 0;
  my $major    = int($version / 10000) % 100;
  my $minor    = int($version / 100) % 100;
  my $stepping = $version % 100;
  return if $major == 0 || $minor > 15 || $stepping > 15;
  return sprintf 'gfx%d%x%x', $major, $minor, $stepping;
}


sub resolve {
  my ( $class, %arg ) = @_;
  my $table = $class->gfx_target_for_device_id($arg{device_id});
  my $kfd   = defined $arg{kfd_gfx_target} ? lc $arg{kfd_gfx_target} : undef;
  if (defined $kfd && defined $table && $kfd ne $table) {
    Rex::Logger::info('  AMD '.( $arg{name} // 'GPU' ).' [1002:'.$class->_device_id($arg{device_id})
      .']: the running driver (KFD) reports '.$kfd.', the device table says '.$table
      .' -- using '.$kfd, 'warn');
  }
  my $gfx = $kfd // $table;
  my $row = $class->target($gfx);
  return {
    gfx_target => $gfx,
    map { $_ => ( $row ? $row->{$_} : undef ) } qw( compute integrated driver matrix family )
  };
}

# '0x1586' / '1586' / '1586\n' => '1586'; anything else => undef.
sub _device_id {
  my ( $class, $id ) = @_;
  return defined $id && $id =~ /\A(?:0x)?([0-9a-f]{4})\s*\z/i ? lc $1 : undef;
}

sub _check_target_row {
  my ( $class, $row ) = @_;
  croak $class.'->targets: every row needs a gfx_target like gfx1151'
    unless ref $row eq 'HASH' && defined $row->{gfx_target}
      && $row->{gfx_target} =~ /\Agfx[0-9a-f]+\z/;
  for my $flag (qw( compute integrated )) {
    croak $class.'->targets: '.$row->{gfx_target}.' '.$flag.' must be 0, 1 or undef'
      if defined $row->{$flag} && $row->{$flag} !~ /\A[01]\z/;
  }
  croak $class.'->targets: '.$row->{gfx_target}.' driver must be inbox, dkms or undef'
    if defined $row->{driver} && !$DRIVERS{ $row->{driver} };
  croak $class.'->targets: '.$row->{gfx_target}.' matrix must be instinct, radeon, ryzen or undef'
    if defined $row->{matrix} && !$MATRICES{ $row->{matrix} };
  return;
}

sub _check_device_row {
  my ( $class, $row ) = @_;
  croak $class.'->devices: every row needs ids => [...] and a gfx_target like gfx1151'
    unless ref $row eq 'HASH' && ref $row->{ids} eq 'ARRAY' && @{ $row->{ids} }
      && defined $row->{gfx_target} && $row->{gfx_target} =~ /\Agfx[0-9a-f]+\z/;
  for my $id (@{ $row->{ids} }) {
    croak $class.'->devices: '.$row->{gfx_target}.' has a device ID that is not four hex '
      .'digits: '.( $id // 'undef' )
      unless defined $id && $id =~ /\A[0-9a-f]{4}\z/i;
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::GPU::AMD::Hardware - AMD GPU hardware data: PCI device ID to gfx target, gfx target to ROCm support (experimental)

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  use Rex::GPU::AMD::Hardware;

  my $gfx = Rex::GPU::AMD::Hardware->gfx_target_for_device_id('1586');   # 'gfx1151'
  my $row = Rex::GPU::AMD::Hardware->target($gfx);
  print "ROCm-capable\n" if $row && $row->{compute};

  # Your own rows, kept in your project's lib/
  package My::AMD::Hardware;
  use parent 'Rex::GPU::AMD::Hardware';
  sub devices {
    my ( $class ) = @_;
    return (
      { ids => [qw( 744c )], gfx_target => 'gfx1100', product => 'RX 7900 XTX',
        source => 'site inventory' },
      $class->SUPER::devices,
    );
  }

=head1 DESCRIPTION

B<Experimental.> The AMD hardware knowledge of L<Rex::GPU>: which LLVM gfx
target a PCI device ID is (L</devices>), and what AMD supports for a gfx
target (L</targets>) -- whether it is ROCm-capable (C<compute>), integrated,
and which kernel driver AMD supports for it. L<Rex::GPU::Detect> asks it
for every AMD GPU it finds (through L<Rex::GPU::Detect/amd_hardware_class>),
L<Rex::GPU::AMD> for L<Rex::GPU::AMD/install_driver>'s choice of driver
(through L<Rex::GPU::AMD/hardware_class>).

A device ID without a row is unknown: C<gfx_target> comes from the running
driver if there is one, everything else stays C<undef>, and
L<Rex::GPU/gpu_setup> installs no driver for it.

=head2 targets

  my @rows = Rex::GPU::AMD::Hardware->targets;

B<Experimental.> What AMD supports for each LLVM gfx target, one hashref per
target:

  { gfx_target => 'gfx1151',            # required, "gfx" and lowercase hex
    compute    => 1,                    # 1 ROCm-capable, 0 known not, undef unknown
    integrated => 1,                    # 1 integrated (APU), 0 discrete, undef unknown
    driver     => 'inbox',              # kernel driver AMD supports: 'inbox' (the
                                        # distribution kernel's amdgpu), 'dkms'
                                        # (amdgpu-dkms from repo.radeon.com), undef
    matrix     => 'ryzen',              # the table of AMD's ROCm compatibility
                                        # matrix listing it: 'instinct', 'radeon',
                                        # 'ryzen' (Ryzen APU), undef (none)
    family     => 'RDNA 3.5 ...',       # for messages
    source     => '...',                # where the row comes from
    rocm_last  => '6.4',                # optional: last ROCm release supporting it
  }

C<compute> is the truthful "ROCm-capable" flag: L<Rex::GPU/gpu_setup>
installs a driver only for C<compute =E<gt> 1> (and an C<integrated> one only
with C<amd_integrated =E<gt> 1>). C<driver> is what
L<Rex::GPU::AMD/install_driver>'s C<method =E<gt> 'auto'> follows. A target
without a row has all three C<undef>. Croaks, naming the row, for a row
without a valid C<gfx_target>, a C<compute> or C<integrated> other than 0, 1
or C<undef>, a C<driver> other than C<inbox>, C<dkms> or C<undef>, or a
C<matrix> other than C<instinct>, C<radeon>, C<ryzen> or C<undef>.

The built-in rows, all checked 2026-10-31 (the source comment above the
tables in the module has every URL and revision):

=over

=item * C<compute =E<gt> 1>: every target AMD lists for Linux in ROCm Core
SDK 10.1.0, the latest release -- Instinct C<gfx950>, C<gfx942>, C<gfx90a>,
C<gfx908>; Radeon C<gfx1201>, C<gfx1200>, C<gfx1100>, C<gfx1101>,
C<gfx1102>, C<gfx1030>; Ryzen APUs C<gfx1151>, C<gfx1150>, C<gfx1152>,
C<gfx1153>, C<gfx1103>. The old ROCm line's last release (7.2.4) lists none
that 10.1.0 lacks. The verdict is per target: the Radeon RX 6800/6900
(C<gfx1030>) count although AMD names only the PRO W6800 and V620 for it.

=item * C<compute =E<gt> 0>: C<gfx906> (MI50/MI60, Radeon VII; deprecated in
ROCm 6.0-6.3.3, unsupported from 6.4.0, C<rocm_last =E<gt> '6.3.3'>),
C<gfx900> (MI25, Vega 10; unsupported in every release checked), and the
older or integrated targets no release checked (5.7.1, 6.0.0-7.2.4,
7.14.0-10.1.0) lists: C<gfx700>, C<gfx701>, C<gfx801>, C<gfx802>, C<gfx803>,
C<gfx902>, C<gfx904>, C<gfx90c>, C<gfx1010>-C<gfx1013>, C<gfx1031>-C<gfx1036>.
C<gfx1036> is what the running driver reports for the Raphael and Mendocino
iGPUs (Ryzen 7000 desktop and server CPUs).

=item * No row (unknown): targets the kernel and LLVM know but AMD makes no
support statement for -- C<gfx1154>, C<gfx1170>-C<gfx1172>, C<gfx1250>,
C<gfx1251>.

=item * C<integrated>: LLVM's dGPU/APU column (AMDGPUUsage). C<gfx942> covers
the MI300X and the MI300A (an APU); it is C<0> -- LLVM files it as dGPU, and
the MI300A is a datacenter accelerator, not client integrated graphics.

=item * C<driver>: C<dkms> for the Instinct and Radeon targets (AMD: "For
Instinct and Radeon devices, install the AMD GPU Driver (amdgpu)", which is
C<amdgpu-dkms>), C<inbox> for the Ryzen APU targets (AMD: "Supported Ryzen
APUs require the inbox kernel driver included with Ubuntu"), C<undef> for
every C<compute =E<gt> 0> target.

=item * C<matrix>: the table of AMD's ROCm 10.1.0 compatibility matrix that
lists the target -- C<instinct> (C<gfx950>, C<gfx942>, C<gfx90a>,
C<gfx908>), C<radeon> (C<gfx1201>, C<gfx1200>, C<gfx1100>, C<gfx1101>,
C<gfx1102>, C<gfx1030>), C<ryzen> (the Ryzen APU table: C<gfx1151>,
C<gfx1150>, C<gfx1152>, C<gfx1153>, C<gfx1103>) -- and C<undef> for every
C<compute =E<gt> 0> target. Each table has its own supported operating
systems; this field, not C<family>, tells an Instinct from a Radeon. No
built-in target is in two tables (C<gfx942> is the MI300X and the MI300A,
both Instinct). Only the value is checked: a row of your own without
C<matrix> stays valid.

=back

=head2 devices

  my @rows = Rex::GPU::AMD::Hardware->devices;

B<Experimental.> Which gfx target a PCI device ID (vendor C<1002>) is, one
hashref per group of IDs:

  { ids        => [qw( 1586 )],         # required: explicit four-hex-digit IDs
    gfx_target => 'gfx1151',            # required
    product    => 'Radeon 8065S ...',   # for messages
    source     => '...' }

The IDs are an explicit list, never a range: AMD interleaves GPU families
in its device ID space. Croaks, naming the row, for a row without IDs, with
an ID that is not four hex digits, or without a valid C<gfx_target>.

The built-in rows, all checked 2026-10-31: an ID is listed only when a
source maps it to its gfx target (the Linux kernel's C<amdgpu> ID table and
KFD, AMD's C<rocm_agent_enumerator>, libhsakmt or rocprofiler-compute, or an
AMD product list joined with libdrm's C<amdgpu.ids> names), the ID itself is
known (kernel, libdrm or C<pci.ids>), and no source contradicts it. Every
listed ID has one gfx target across all its known revisions. Left out on
purpose, so they fall back to the running driver's report, else stay unknown:

=over

=item * C<1902> (Radeon 820M/840M): rocprofiler-compute says C<gfx1153>, but
AMD's own pages list the 820M on it as C<gfx1152>, and disagree with each
other for the 840M.

=item * C<7460>, C<7461> (Radeon PRO V710): C<gfx1101> per AMD's ROCm
documentation, C<gfx1100> per C<rocm_agent_enumerator>.

=item * C<164E> Raphael, C<1506> Mendocino, C<13C0> Granite Ridge -- the
Radeon 610M iGPUs of Ryzen 7000/9000 desktop and server CPUs: no AMD source
maps them. Once C<amdgpu> runs, it reports Raphael and Mendocino as
C<gfx1036> (C<compute =E<gt> 0>).

=item * C<98E4> (Stoney, sources disagree), IDs only named in libdrm or
C<pci.ids> (C<744B> W7900D, Navi 33 C<73F0>, C<7487>, C<748B>, C<749F>), and
IDs found in one tool's table and in no device list (C<74B4>, C<74BC>,
C<75A2>, C<75B2>, C<75C1>, C<75D1>, C<13F3>).

=back

=head2 target

  my $row = Rex::GPU::AMD::Hardware->target('gfx1151');   # hashref or undef

B<Experimental.> The first L</targets> row for a gfx target (case does not
matter), or C<undef>.

=head2 for_device_id

  my $row = Rex::GPU::AMD::Hardware->for_device_id('1586');   # hashref or undef

B<Experimental.> The first L</devices> row listing a PCI device ID (four hex
digits, with or without C<0x>, any case), or C<undef> -- also for C<undef>
and anything malformed.

=head2 gfx_target_for_device_id

  my $gfx = Rex::GPU::AMD::Hardware->gfx_target_for_device_id('1586');   # 'gfx1151'

B<Experimental.> The C<gfx_target> of L</for_device_id>, or C<undef>.

=head2 gfx_target_from_version

  my $gfx = Rex::GPU::AMD::Hardware->gfx_target_from_version(110501);   # 'gfx1151'

B<Experimental.> The LLVM target name for a KFD topology
C<gfx_target_version> (decimal C<major*10000 + minor*100 + stepping>):
C<gfx>, the major version in decimal, minor and stepping as one hex digit
each -- C<110501> is C<gfx1151>, C<90010> C<gfx90a>, C<90402> C<gfx942>.
C<undef> for C<0> (a CPU node), C<undef> and anything that is not a number,
or a minor/stepping above 15.

=head2 resolve

  my $hw = Rex::GPU::AMD::Hardware->resolve(
    device_id      => '1586',      # optional
    kfd_gfx_target => 'gfx1151',   # optional: what the running driver reports
    name           => '...',       # optional, for the message
  );
  # { gfx_target => 'gfx1151', compute => 1, integrated => 1, driver => 'inbox',
  #   matrix => 'ryzen', family => '...' }

B<Experimental.> The verdict for one GPU: the gfx target the running driver
reports (KFD topology) wins over the L</devices> table; when both are known
and differ, a warning names both and the KFD one is used. The other keys
(C<compute>, C<integrated>, C<driver>, C<matrix>, C<family>) come from that
target's L</targets> row, all C<undef> without one (and without a gfx
target).

=head1 SEE ALSO

L<Rex::GPU::AMD>, L<Rex::GPU::Detect>,
L<https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/rex-gpu/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
