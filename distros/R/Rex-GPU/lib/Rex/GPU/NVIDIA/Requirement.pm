# ABSTRACT: What NVIDIA driver a GPU generation needs (experimental)

package Rex::GPU::NVIDIA::Requirement;
our $VERSION = '0.006';
use Moo;
use Carp qw( croak );
use Scalar::Util qw( blessed );
use namespace::autoclean;

my %KERNEL_MODULES = map { $_ => 1 } qw( open proprietary either );


has generation => ( is => 'ro' );


has kernel_module => (
  is      => 'ro',
  default => 'either',
  isa     => sub {
    croak __PACKAGE__.'->kernel_module must be open, proprietary or either, not '
      .( defined $_[0] ? "'".$_[0]."'" : 'undef' )
      unless defined $_[0] && $KERNEL_MODULES{ $_[0] };
  }
);


has min_branch => ( is => 'ro', isa => \&_check_branch );
has max_branch => ( is => 'ro', isa => \&_check_branch );

sub _check_branch {
  my ( $branch ) = @_;
  croak __PACKAGE__.': a driver branch is an integer like 580, not '."'".$branch."'"
    if defined $branch && $branch !~ /^\d+\z/;
}


has device_id => (
  is  => 'ro',
  isa => sub {
    croak __PACKAGE__.'->device_id must be four lowercase hex digits, not '."'".$_[0]."'"
      if defined $_[0] && $_[0] !~ /^[0-9a-f]{4}\z/;
  }
);


has name    => ( is => 'ro' );
has members => ( is => 'ro', default => sub { [] } );


has compute => ( is => 'ro' );

sub BUILD {
  my ( $self ) = @_;
  croak __PACKAGE__.': min_branch '.$self->min_branch.' is above max_branch '
    .$self->max_branch.': no driver branch can satisfy that'
    if defined $self->min_branch && defined $self->max_branch
      && $self->min_branch > $self->max_branch;
}


# The rows, and where they come from (moved here from Rex::GPU::Detect, karr
# #16 and #26). The compute flag decides Rex::GPU::Detect::_is_nvidia_compute
# before any name rule (karr #45, #54). Maintainer decision (karr #54): every
# GPU usable for AI is compute -- MX, GT and GTX 9xx with 2 GB included -- as
# long as a current driver branch supports it; the criterion is the
# generation, not the marketing name. So Maxwell through Blackwell Ultra carry
# compute => 1 and the Kepler-or-older row compute => 0 (skipped with a
# warning, not a die, before the PCI class rule (karr #55): gpu_setup /
# Rex::Rancher gpu => 1 keep going without the old card, a K80 included). An ID no row covers (0x3000+
# except Blackwell Ultra) has no verdict; Detect uses its name rules and its
# unknown-model default compute => 0 there.
#
# Checked 2026-09-24 against NVIDIA's supportedchips READMEs (Linux-x86_64
# 615.71.09, 580.95.05, 580.126.09, 550.163.01, 535.247.01) and pci.ids of
# 2026-09-24:
#   * 580.95.05 / 580.126.09 "current" list starts at 1340: every ID of the
#     615 legacy_580 list (1340..1DF6) is current there -- incl. Maxwell Gen1
#     GM107/GM108: GTX 750 Ti 1380, GTX 745 1382, 940MX 134D, MX130 174D,
#     MX110 174E -- except 137D (GeForce 940A, subsystem entry only) and 1DF5
#     (V100-SXM2-16GB), which only the 615 legacy_580 list names.
#   * No legacy_470-or-older ID is >= 1340; no current/legacy_580 ID < 1340.
#   * pci.ids: no 10de ID >= 1340 carries a Kepler-or-older codename (GK, GF,
#     GT2xx, G8x/G9x, NVxx), and no Maxwell-or-newer codename sits below 1340
#     except HD-audio functions (PCI class 0403, never read by detection).
#     pci.ids does name two Kepler IDs like Maxwell/Pascal products -- 0FC5
#     "GK107 [GeForce GT 1030]", 11C7 "GK106 [GeForce GTX 750 Ti]" -- which is
#     why the ID row decides before any name rule.
#
# Blackwell (karr #16): NO proprietary kernel module — NVIDIA's open GPU
# kernel modules are the only ones that bind — on every architecture, x86_64
# included. Source: the supported-GPU table in NVIDIA's open-gpu-kernel-modules
# README.md (github.com/NVIDIA/open-gpu-kernel-modules, driver 615.71.09). In
# that table the last pre-Blackwell (Ada) ID is 28F8, and every listed ID from
# 2901 up to 2F58 is Blackwell: B200 (2901, 2909), GB200 (2941), GeForce RTX
# 50xx desktop/laptop and RTX PRO Blackwell (2B85..2F58), GB10 (2E12).
# 0x2900-0x2FFF is therefore taken as a block: an unlisted ID inside it is
# post-Ada silicon and gets the open module (which supports every GPU from
# Turing on). Blackwell Ultra (B300 3182, GB300 31C2/31C3) is listed
# explicitly, NOT as a block — whatever else lands at 0x3000+ is unknown.
# min_branch 570 / 580: the first branch with Blackwell / Blackwell Ultra
# support (research for epic karr #25).
#
# GB10 (2E12, DGX Spark) is the exception inside the Blackwell block: min 580
# (karr #33, checked 2026-09-23 against NVIDIA's primary sources). 2E12 is
# absent from the open-gpu-kernel-modules README.md of every 570.x and 575.x
# tag and of 580.65.06 .. 580.105.08; it first appears in tag 580.119.02
# ("NVIDIA GB10 | 2E12 10DE 21EC"), and is in 580.126.09, 590.48.01, 595.44.02
# and 615.71.09 -- but NOT in 590.44.01. The aarch64 driver README
# (us.download.nvidia.com/XFree86/aarch64/<ver>/README/supportedchips.html)
# agrees: absent in 580.95.05 and 590.44.01, present in 580.119.02 and
# 590.48.01. A branch-granular row cannot express "580.119.02 or newer".
#
# Pre-Turing (karr #26). Source: the legacy sections of NVIDIA's
# supportedchips README (driver 615.71.09, us.download.nvidia.com/XFree86/
# Linux-x86_64/615.71.09/README/supportedchips.html), checked 2026-09-23:
#   * "current" list: lowest ID 1E02 (TITAN RTX, Turing). No current ID < 1E02.
#   * 580.xx legacy list (Maxwell/Pascal/Volta): exactly 1340..1DF6, e.g.
#     Tesla M60 13F2, M40 17FD, P100 15F7/15F8, P40 1B38, P4 1BB3, TITAN V
#     1D81, V100 1DB1/1DB4-1DB6, V100S 1DF6. Proprietary kernel module only —
#     the open module needs GSP, which these chips lack — and 580 is their last
#     branch (595+ dropped them).
#   * 470.xx list (Kepler): 0FC6..12BA. The 390.xx (Fermi) list interleaves
#     with it (1040..1251) and goes down to 06C0; older legacy lists reach
#     down to 0020. No list has an ID in 12BB..133F or 1DF7..1E01.
# So every ID below 1340 is Kepler or older and no driver newer than 470
# supports it: one block, not a Kepler-only range, so a Fermi Tesla (C2050
# 06D1, M2090 1091) is rejected too. 1340..1DF6 is taken as a block like the
# Blackwell one: an unlisted ID inside it is Maxwell..Volta silicon.
#
# Turing, Ampere, Ada, Hopper (karr #54): 1DF7..28FF, compute 1. One block
# without bounds until k107; now four blocks, and an ID that NVIDIA lists
# first in a later branch than its block's floor has a row of its own with that
# branch as min_branch. Checked 2026-11-26 against the "current" list of
# NVIDIA's supportedchips README (us.download.nvidia.com/XFree86/<arch>/
# <version>/README/supportedchips.html) of every Linux-x86_64 release in
# download.nvidia.com/XFree86/Linux-x86_64/ from 470.42.01 to 620.73.04 (143
# READMEs; 470.82.01 and 525.60.13 have none) and of the aarch64 ones of the
# same versions (137; every floor below is the same on aarch64):
#   * 470.256.02, the last 470 and the one Debian 11 ships, lists nothing above
#     25FA: no Hopper (23xx), no Ada (26xx..28xx). Neither does 515.105.01, the
#     last 515. Both first appear in 520.56.06: H100 PCIe 2331 (as 2331 10DE
#     1626) and GeForce RTX 4090 2684. The open-gpu-kernel-modules README
#     agrees: no 23xx or 26xx..28xx ID in tags 515.43.04, 515.65.01 and
#     515.105.01; 2331 from 520.56.06.
#   * Block edges, over every section of all 143 READMEs: nothing is listed in
#     2239..230D, 2349..2413, 25FC..2683 or 28F9..2900. Below 2300 the highest
#     ID is 2238 (A10M, Ampere), above 23FF the lowest 2414 (RTX 3060 Ti,
#     Ampere); everything from 230E to 2348 is Hopper, from 2684 to 28F8 Ada.
#     So 2300..23FF is taken as Hopper and 2600..28FF as Ada, blocks like the
#     Blackwell one: an unlisted ID inside gets the generation's oldest branch,
#     520. pci.ids (version 2026.11.26, names only) has nothing else there
#     either: only GH100 names in 2300..23FF, only AD102 (2681, 2682) in
#     2600..2683, and in 2239..22FF no display device (HD audio, NVSwitch,
#     Tegra bridges) except 223F GA102GL.
#   * Turing/Ampere, 1DF7..22FF and 2400..25FF: no bound. Every ID listed
#     there is in 470.256.02 -- 470 is the oldest branch a built-in source
#     installs -- except the IDs with their own rows in generations. Floors
#     below 470 were not researched.
#   * The row floor is the oldest branch whose LAST release lists the ID; the
#     comment above each group of rows names the release that first lists it.
#     Whole branches only: an earlier point release of that branch can lack
#     the ID. The releases Debian ships list every ID whose row their branch
#     passes (sources.debian.org, 2026-11-26: bullseye 470.256.02, bookworm
#     535.261.03, trixie 550.163.01).
#   * A floor, never a ceiling: some IDs are missing again from a later
#     branch's README ("not in NNN" in the group comments; no built-in source
#     installs 515..530, 545 or 555..565), and the lists drop GPUs that are
#     still supported (Tesla T4 1EB8 is missing from 495.29.05 to 570.211.01).
#   * Sources disagree: 2685 (RTX 4090 D) is in 535.154.05 but in no other 535
#     release, then from 550.40.07 on -- min 550, as 535's last release lacks
#     it. 2336 (H100 80GB HBM2e) is listed in 525.85.05 only: no row of its
#     own, it gets the Hopper block's 520.
#
# Grace Hopper GH200 (karr #72): 2342 and 2348 sit inside the Hopper block but
# get their own rows ahead of it -- open kernel module only, by MAINTAINER
# DECISION, not by NVIDIA's driver documentation. The open-only evidence is
# NVIDIA's blog post "NVIDIA Transitions Fully Towards Open-Source GPU Kernel
# Modules" (2024), which says Grace Hopper and Blackwell platforms must use
# the open modules. NVIDIA's driver README disagrees: kernel_open.html
# ("Open Linux Kernel Modules", aarch64 and Linux-x86_64 alike) of 560.35.03
# .. 580.126.09 says the proprietary flavor supports "later GPUs until
# Blackwell", of 590.48.01 and 615.71.09 "Turing, Ampere, Ada, and Hopper",
# with no Grace exception in any of them; and NVIDIA-Linux-aarch64-615.71.09
# .run ships a proprietary kernel/nv-kernel.o_binary. Checked 2026-09-26.
# IDs, from NVIDIA's supportedchips READMEs (aarch64 and Linux-x86_64,
# checked 2026-09-26); no other product uses them:
#   * 2342 GH200 120GB (10DE:16EB, 10DE:1805), GH200 480GB (10DE:1809):
#     in 535.247.01, 545.29.06 (16EB and 1809 only), 550.54.14, 560.35.03,
#     565.77, 570.86.16, 570.172.08, 615.71.09; NOT in 535.104.05. In the
#     open-gpu-kernel-modules README from tag 550.54.14 on (not up to
#     545.23.06). min_branch 535: whole branches only, so an early 535
#     point release (535.104.05) is not caught here. Every 535 release was
#     checked on 2026-11-26 (k107): the first to list 2342 is
#     535.129.03, on Linux-x86_64 and aarch64; 535.113.01 does not.
#   * 2348 GH200 144G HBM3e (10DE:18D2): from 565.77 on (not in 560.35.03);
#     open-gpu-kernel-modules README of 570.172.08, 580.95.05, 615.71.09.
#     min_branch 565. On 2026-11-26 (k107): already in 565.57.01, the
#     first 565 release, on both architectures.
#
# Everything else — the gaps above 2FFF and any future ID — has no row:
# either kernel module, no bounds, no compute verdict.
sub generations {
  return (
    { generation => 'Blackwell', first => 0x2e12, last => 0x2e12,       # GB10, see above
      kernel_module => 'open', min_branch => 580, compute => 1 },
    { generation => 'Blackwell', first => 0x2900, last => 0x2fff,       # GB100/GB102, GB20x, GB10
      kernel_module => 'open', min_branch => 570, compute => 1 },
    { generation => 'Blackwell Ultra', first => 0x3182, last => 0x3182, # B300 SXM6 AC
      kernel_module => 'open', min_branch => 580, compute => 1 },
    { generation => 'Blackwell Ultra', first => 0x31c2, last => 0x31c3, # GB300
      kernel_module => 'open', min_branch => 580, compute => 1 },
    { generation => 'Grace Hopper', first => 0x2342, last => 0x2342,    # GH200 120GB/480GB, see above
      kernel_module => 'open', min_branch => 535, compute => 1 },
    { generation => 'Grace Hopper', first => 0x2348, last => 0x2348,    # GH200 144G HBM3e
      kernel_module => 'open', min_branch => 565, compute => 1 },
    # Hopper, Ada and Turing/Ampere IDs NVIDIA lists first in a branch newer
    # than their block's floor (k107, see above): one row per ID, as
    # [ generation, min_branch, device IDs ]. Per group, the release that first
    # lists each ID, and the later branches whose last release lacks one.
    ( map {
        my ( $generation, $branch, @ids ) = @$_;
        map { +{ generation => $generation, first => hex $_, last => hex $_,
          min_branch => $branch, compute => 1 } } @ids
      }
      # 525.85.05 2330 H100 80GB HBM3; 525.105.17 2322 H800 PCIe, 2324 H800,
      # 2339 H100.
      [ 'Hopper', 525, qw( 2322 2324 2330 2339 ) ],
      # 535.104.05 2321 H100 NVL, 233A H800 NVL; 535.161.07 2329 H20;
      # 535.230.02 232C H20-3e. Not in 545: 2329 232C; 555, 560: 232C.
      [ 'Hopper', 535, qw( 2321 2329 232c 233a ) ],
      # 550.90.07 2335 H200.
      [ 'Hopper', 550, qw( 2335 ) ],
      # 565.57.01 233B H200 NVL.
      [ 'Hopper', 565, qw( 233b ) ],
      # 580.82.07 230E H20 NVL16.
      [ 'Hopper', 580, qw( 230e ) ],
      # 525.60.11 26B1 RTX 6000 Ada, 26B5 L40, 2704 RTX 4080; 525.78.01 2782 RTX
      # 4070 Ti; 525.89.02 2717/2757 RTX 4090 Laptop, 27A0/27E0 RTX 4080 Laptop,
      # 2820/2860 RTX 4070 Laptop, 28A0/28E0 RTX 4060 Laptop, 28A1/28E1 RTX 4050
      # Laptop; 525.105.17 27B0 RTX 4000 SFF Ada, 27B8 L4; 525.116.03 2730 RTX
      # 5000 Ada Laptop, 2786 RTX 4070, 27BA RTX 4000 Ada Laptop, 27BB RTX 3500
      # Ada Laptop, 2838 RTX 3000 Ada Laptop, 28B8 RTX 2000 Ada Laptop;
      # 525.125.06 2803 RTX 4060 Ti; 525.147.05 2770 RTX 5000 Ada Embedded, 2805
      # RTX 4060 Ti, 2882 RTX 4060, 28F8 RTX 2000 Ada Embedded. Not in 530: 2730
      # 2770 2786 27BA 27BB 2803 2805 2838 2882 28B8 28F8.
      [ 'Ada', 525, qw( 26b1 26b5 2704 2717 2730 2757 2770 2782 2786 27a0 27b0 27b8 27ba
                        27bb 27e0 2803 2805 2820 2838 2860 2882 28a0 28a1 28b8 28e0 28e1
                        28f8 ) ],
      # 535.98 26B2 RTX 5000 Ada, 27B2 RTX 4000 Ada; 535.104.05 26B9 L40S, 27FB
      # RTX 3500 Ada Embedded; 535.113.01 27B1 RTX 4500 Ada; 535.146.02 26B3 RTX
      # 5880 Ada; 535.154.05 26BA L20, 27B6 L2; 535.171.04 28B9 RTX 1000 Ada
      # Laptop, 28BB RTX 500 Ada Laptop; 535.183.01 28BA RTX 500 Ada Laptop. Not
      # in 545: 26B3 26BA 27B6 28B9 28BA 28BB.
      [ 'Ada', 535, qw( 26b2 26b3 26b9 26ba 27b1 27b2 27b6 27fb 28b9 28ba 28bb ) ],
      # 550.40.07 2685 RTX 4090 D (see above), 2705 RTX 4070 Ti SUPER, 2783 RTX
      # 4070 SUPER; 550.54.14 2702 RTX 4080 SUPER, 28B0 RTX 2000/2000E Ada;
      # 550.67 2709 RTX 4070, 2788 RTX 4060 Ti, 2808 RTX 4060; 550.107.02 2822,
      # 550.142 28A3, 550.163.01 28E3 RTX 3050 A Laptop. Not in 555: 2822 28A3
      # 28E3; 560, 565: 28A3 28E3.
      [ 'Ada', 550, qw( 2685 2702 2705 2709 2783 2788 2808 2822 28a3 28b0 28e3 ) ],
      # 555.42.02 2689 RTX 4070 Ti SUPER.
      [ 'Ada', 555, qw( 2689 ) ],
      # 510.47.03 2233 RTX A5500, 2238 A10M; 510.60.02 24B1 RTX A4000H, 25AA
      # MX570 A; 510.85.02 1F83 GTX 1630; 510.108.03 20F3 A800-SXM4-80GB, 20F5
      # A800 80GB PCIe, 20F6 A800 40GB PCIe/Active, 2207 RTX 3070 Ti, 24C9 RTX
      # 3060 Ti, 2521 RTX 3060 Laptop, 2544 RTX 3060. Not in 520: 20F3 20F5
      # 20F6; 515, 525, 530: 20F6.
      [ 'Turing/Ampere', 510, qw( 1f83 20f3 20f5 20f6 2207 2233 2238 24b1 24c9 2521 2544
                                  25aa ) ],
      # 515.105.01 2582 RTX 3050, 25AB RTX 3050 4GB Laptop, 25AC/25EC RTX 3050
      # 6GB Laptop, 25AD/25ED RTX 2050, 25FB RTX A500 Embedded. Not in 520: all.
      [ 'Turing/Ampere', 515, qw( 2582 25ab 25ac 25ad 25ec 25ed 25fb ) ],
      # 525.116.03 24C7 RTX 3060, 25BC RTX A1000 6GB Laptop, 25BD RTX A500
      # Laptop. Not in 530: all.
      [ 'Turing/Ampere', 525, qw( 24c7 25bc 25bd ) ],
      # 535.104.05 20BD A800-SXM4-40GB; 535.154.05 20FD AX800; 535.161.07 2584
      # RTX 3050. Not in 545: 20FD 2584.
      [ 'Turing/Ampere', 535, qw( 20bd 20fd 2584 ) ],
      # 550.76 25B0 RTX A1000, 25B2 RTX A400.
      [ 'Turing/Ampere', 550, qw( 25b0 25b2 ) ]
    ),
    { generation => 'Hopper', first => 0x2300, last => 0x23ff,          # GH100; 2331 H100 PCIe, 520.56.06
      min_branch => 520, compute => 1 },
    { generation => 'Ada', first => 0x2600, last => 0x28ff,             # AD10x; 2684 RTX 4090, 520.56.06
      min_branch => 520, compute => 1 },
    { generation => 'Turing/Ampere', first => 0x1df7, last => 0x22ff,   # TU10x/TU11x, GA100, GA102
      compute => 1 },
    { generation => 'Turing/Ampere', first => 0x2400, last => 0x25ff,   # GA103..GA107
      compute => 1 },
    { generation => 'Maxwell/Pascal/Volta', first => 0x1340, last => 0x1df6,
      kernel_module => 'proprietary', max_branch => 580, compute => 1 },
    { generation => 'Kepler or older', first => 0x0000, last => 0x133f,
      kernel_module => 'proprietary', max_branch => 470, compute => 0 }
  );
}


sub for_device_id {
  my ( $self, $device_id ) = @_;
  return ( ref $self || $self )->new( $self->_lookup( $device_id ) );
}

sub from_gpu {
  my ( $self, $gpu ) = @_;
  croak __PACKAGE__.'->from_gpu needs a GPU hashref from Rex::GPU::Detect::detect'
    unless ref $gpu eq 'HASH';
  return ( ref $self || $self )->new(
    $self->_lookup( $gpu->{device_id} ),
    defined $gpu->{name} ? ( name => $gpu->{name} ) : ()
  );
}

# Constructor arguments for a device ID. The format check is the one
# Rex::GPU::Detect used before this table existed, kept as it was so the
# wrappers there return exactly what they did.
sub _lookup {
  my ( $self, $device_id ) = @_;
  return () unless defined $device_id && $device_id =~ /^[0-9a-f]{4}$/i;
  my $id = hex $device_id;
  my %args = ( device_id => lc substr( $device_id, 0, 4 ) );
  for my $row ( $self->generations ) {
    croak __PACKAGE__.'->generations: every row needs first and last'
      unless defined $row->{first} && defined $row->{last};
    next unless $id >= $row->{first} && $id <= $row->{last};
    return (
      %args,
      generation    => $row->{generation},
      kernel_module => $row->{kernel_module} // 'either',
      defined $row->{min_branch} ? ( min_branch => $row->{min_branch} ) : (),
      defined $row->{max_branch} ? ( max_branch => $row->{max_branch} ) : (),
      defined $row->{compute} ? ( compute => $row->{compute} ? 1 : 0 ) : ()
    );
  }
  return %args;
}


sub satisfied_by {
  my ( $self, $source ) = @_;
  return defined $self->why_not( $source ) ? 0 : 1;
}

sub why_not {
  my ( $self, $source ) = @_;
  croak __PACKAGE__.'->satisfied_by needs a source hashref { kernel_module, branch }'
    unless ref $source eq 'HASH';
  my ( $branch, $floor ) = @{ $source }{qw( branch branch_at_least )};
  for my $n ( $branch, $floor ) {
    croak __PACKAGE__.'->satisfied_by: branch must be an integer like 580, not '."'".$n."'"
      if defined $n && $n !~ /^\d+\z/;
  }

  if ( $self->kernel_module ne 'either' ) {
    my $module = $source->{kernel_module};
    return ( defined $module ? $module : 'unknown' ).' kernel module, the '
        .$self->kernel_module.' one is needed'
      unless defined $module && $module eq $self->kernel_module;
  }
  my ( $min, $max ) = ( $self->min_branch, $self->max_branch );
  return unless defined $min || defined $max;

  if ( defined $branch ) {
    return 'branch '.$branch.' is older than '.$min if defined $min && $branch < $min;
    return 'branch '.$branch.' is newer than '.$max if defined $max && $branch > $max;
    return;
  }
  return 'driver branch not known, '.( defined $min ? $min.' or newer' : $max.' or older' )
      .' is needed'
    unless defined $floor;
  return 'installs the newest branch it carries, which can be newer than '.$max
    if defined $max;
  return 'installs the newest branch it carries, known only to be '.$floor
      .' or newer; '.$min.' is needed'
    if $floor < $min;
  return;
}


sub intersect {
  my ( $self, @requirements ) = @_;
  unshift @requirements, $self if ref $self;
  my @members = $self->_members_of( @requirements );
  return $requirements[0] if @requirements == 1;

  my @conflicts = $self->conflicts( @members );
  croak __PACKAGE__.'->intersect: no single NVIDIA driver supports all GPUs on this host: '
    .join( '; ', @conflicts )
    if @conflicts;

  my %module = map { $_->kernel_module => 1 } @members;
  my ( $lower, $upper ) = $self->_bounds( @members );
  my $class = ref $self || $self;
  return $class->new(
    kernel_module => $module{open}        ? 'open'
                   : $module{proprietary} ? 'proprietary'
                   :                        'either',
    $lower ? ( min_branch => $lower->min_branch ) : (),
    $upper ? ( max_branch => $upper->max_branch ) : (),
    members => \@members
  );
}

sub conflicts {
  my ( $self, @requirements ) = @_;
  unshift @requirements, $self if ref $self;
  my @members = $self->_members_of( @requirements );

  my %by_module;
  push @{ $by_module{ $_->kernel_module } }, $_ for @members;
  my ( $lower, $upper ) = $self->_bounds( @members );

  my @conflicts;
  push @conflicts, join( ', ', map { $_->who } @{ $by_module{open} } )
      .' need'.( @{ $by_module{open} } == 1 ? 's' : '' ).' the open kernel module, but '
      .join( ', ', map { $_->who } @{ $by_module{proprietary} } )
      .' need'.( @{ $by_module{proprietary} } == 1 ? 's' : '' ).' the proprietary one'
    if $by_module{open} && $by_module{proprietary};
  push @conflicts, $lower->who.' needs driver branch '.$lower->min_branch
      .' or newer, but '.$upper->who.' is supported only up to branch '.$upper->max_branch
    if $lower && $upper && $lower->min_branch > $upper->max_branch;
  return @conflicts;
}

# Validated, flattened members of a list of requirements.
sub _members_of {
  my ( $self, @requirements ) = @_;
  croak __PACKAGE__.'->intersect needs at least one requirement'
    unless @requirements;
  for my $req ( @requirements ) {
    croak __PACKAGE__.'->intersect: not a '.__PACKAGE__.' object: '.( $req // 'undef' )
      unless blessed( $req ) && $req->isa( __PACKAGE__ );
  }
  return map { @{ $_->members } ? @{ $_->members } : $_ } @requirements;
}

# The member with the highest lower bound and the one with the lowest upper
# bound (either may be undef).
sub _bounds {
  my ( $self, @members ) = @_;
  my ( $lower ) = sort { $b->min_branch <=> $a->min_branch }
    grep { defined $_->min_branch } @members;
  my ( $upper ) = sort { $a->max_branch <=> $b->max_branch }
    grep { defined $_->max_branch } @members;
  return ( $lower, $upper );
}


sub describe {
  my ( $self ) = @_;
  my $module = $self->kernel_module eq 'either'
    ? 'any kernel module'
    : $self->kernel_module.' kernel module';
  my ( $min, $max ) = ( $self->min_branch, $self->max_branch );
  my $branch = defined $min && defined $max ? 'driver branch '.$min.' to '.$max
             : defined $min                 ? 'driver branch '.$min.' or newer'
             : defined $max                 ? 'driver branch '.$max.' or older'
             :                                'any driver branch';
  return $module.', '.$branch;
}


sub who {
  my ( $self ) = @_;
  return join( ', ', map { $_->who } @{ $self->members } ) if @{ $self->members };
  my @what = grep { defined } $self->generation,
    defined $self->device_id ? '10de:'.$self->device_id : undef;
  my $who = $self->name // 'NVIDIA GPU';
  return @what ? $who.' ('.join( ', ', @what ).')' : $who;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::GPU::NVIDIA::Requirement - What NVIDIA driver a GPU generation needs (experimental)

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  use Rex::GPU::NVIDIA::Requirement;

  my $req = Rex::GPU::NVIDIA::Requirement->from_gpu($gpu);
  say $req->generation // 'unknown generation', ': ', $req->describe;

  $req->satisfied_by({ kernel_module => 'open', branch => 580 })
    or die "the -open 580 driver cannot drive this GPU\n";

  # several GPUs, one driver
  my $all = Rex::GPU::NVIDIA::Requirement->intersect(
    map { Rex::GPU::NVIDIA::Requirement->from_gpu($_) } @compute_gpus
  );

=head1 DESCRIPTION

B<Experimental.> This API may change without a deprecation cycle for one
release. L<Rex::GPU::NVIDIA/install_driver> chooses the driver with it: the
L<Rex::GPU::NVIDIA::Setup> classes intersect the requirements of every GPU
they install for and take the first of their driver sources that
L</satisfied_by> accepts. L<Rex::GPU::Detect/open_kernel_module_required>
and L<Rex::GPU::Detect/legacy_driver_requirement> read from it too.

A requirement says which NVIDIA driver a GPU can work with: the kernel module
(L</kernel_module>) and the range of driver branches
(L</min_branch>..L</max_branch>). It is keyed on the PCI device ID, the one
signal C<lspci -nn> prints even when the host's C<pci.ids> predates the
silicon. Objects are immutable.

The table in L</generations> is a method, not a global, so a subclass can add
a row for silicon this release does not know yet without touching the
module.

=head2 generation

A label for the GPU generation (C<Blackwell>, C<Maxwell/Pascal/Volta>, ...)
taken from L</generations>, for messages. C<undef> for a device ID the table
does not know, and for a requirement built by L</intersect> from several
GPUs.

=head2 kernel_module

Which NVIDIA kernel module the GPU binds with: C<open> (NVIDIA's open GPU
kernel modules only — Blackwell has no proprietary module),
C<proprietary> (the closed module only — pre-Turing silicon lacks the GSP the
open module needs) or C<either>. Defaults to C<either>.

=head2 min_branch

The oldest driver branch (an integer, e.g. C<570>) that supports the GPU, or
C<undef> for no lower bound.

=head2 max_branch

The newest driver branch that still supports the GPU (e.g. C<580> for
Maxwell/Pascal/Volta, whose support ends there), or C<undef> for no upper
bound.

=head2 device_id

The lowercase PCI device ID (the C<XXXX> in C<[10de:XXXX]>) the requirement
was looked up for, or C<undef> (no or malformed ID, or an intersected
requirement).

=head2 name

The GPU name from detection (L</from_gpu>), for messages only. Never used to
decide anything.

=head2 members

For a requirement built by L</intersect> from several GPUs: an arrayref of
the per-GPU requirements it combines, so a message can name every GPU that
constrained it. Empty for a per-GPU requirement.

=head2 compute

Whether the GPU generation is one to install a driver for, as the
L</generations> row for L</device_id> declares it:

=over

=item * C<1> -- a generation a current driver branch supports: every GPU
NVIDIA has published with an ID in that row can run CUDA, so
L<Rex::GPU::Detect> counts the device as compute whatever its PCI class, its
marketing name (GeForce MX, GT, ... included) and whether C<lspci> could
resolve that name. The built-in table marks Maxwell through Blackwell Ultra.

=item * C<0> -- the row says the generation is not to be installed for: the
built-in table marks Kepler and older, whose last driver branch (470) the
current distributions no longer package. L<Rex::GPU::Detect> reports such a
GPU as not compute whatever its PCI class (a class-C<0302> Tesla K80 too),
with a warning naming the generation and branch.

=item * C<undef> -- no row covers the ID (or it is missing or malformed), the
row has no C<compute> key, or the requirement was built by L</intersect>.
The table has no opinion; L<Rex::GPU::Detect> falls back to its name rules.

=back

=head2 generations

  my @rows = $class->generations;

The generation table: an ordered list of hashrefs, each covering the
inclusive PCI device-ID range C<first>..C<last> (numbers) with a
C<generation> label, a C<kernel_module> (default C<either>), optional
C<min_branch>/C<max_branch> and an optional C<compute> flag (see L</compute>).
The B<first> row whose range contains an ID
wins, so a narrower row goes before a block it sits in. An ID no row covers
gets C<either> with no bounds and no C<compute> verdict. The built-in rows
cover every ID from C<0000> to C<2FFF> without a gap, plus the Blackwell
Ultra IDs. From Turing to Ada and Hopper only C<min_branch> is set (C<either>
kernel module, no upper bound): the Turing/Ampere blocks have none either,
Hopper and Ada are 520 or newer, and a GPU NVIDIA lists first in a later
branch has a row of its own with that branch -- except the GH200 IDs C<2342>
and C<2348>, whose rows are open-only as well.

Override it in a subclass to add or replace rows; prepend to
C<< $self->SUPER::generations >> to keep the built-in ones:

  package My::GPU::Requirement;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Requirement';

  sub generations {
    my ( $self ) = @_;
    return (
      { generation => 'Hopper (site policy)', first => 0x2330, last => 0x2330,
        kernel_module => 'open', min_branch => 575 },
      $self->SUPER::generations
    );
  }

The table chooses a driver, and its C<compute> flags also decide detection:
L<Rex::GPU::Detect> asks this class (the built-in table, not a subclass) for
L</compute> before its name rules. The criterion is the
generation, not the marketing name: Maxwell, Pascal, Volta, Turing, Ampere,
Ada, Hopper, Blackwell and Blackwell Ultra rows are C<compute =E<gt> 1>, the
Kepler-or-older row C<compute =E<gt> 0>. A subclass that adds or replaces rows
changes the driver choice only, not detection.

Sources, all checked 2026-09-23 (Blackwell, pre-Turing), 2026-09-24
(compute flags) and 2026-11-26 (Turing to Hopper):

=over

=item * Blackwell C<2900>-C<2FFF> (B200 C<2901>, GB200 C<2941>, GeForce RTX 50xx,
RTX PRO Blackwell, GB10 C<2E12>) and Blackwell Ultra (B300 C<3182>, GB300
C<31C2>/C<31C3>, listed one by one, not as a block): the supported-GPU table
in NVIDIA's open-gpu-kernel-modules README (driver 615.71.09). The last Ada ID
there is C<28F8>, and every listed ID from C<2901> to C<2F58> is Blackwell,
so an unlisted ID in C<2900>-C<2FFF> is taken as Blackwell too. Open kernel
module only; oldest branch 570 (Blackwell; GB10: 580, next item) and 580
(Blackwell Ultra).

=item * GB10 C<2E12> (DGX Spark, aarch64) has its own row ahead of the
Blackwell block: open kernel module, oldest branch B<580>, not 570. NVIDIA
lists C<2E12> first in driver 580.119.02 (open-gpu-kernel-modules README of
tag C<580.119.02>, and the aarch64 C<supportedchips> README of that driver);
580.105.08 and every 570/575 release lack it, and so does 590.44.01 (590.48.01
has it). The table counts whole branches, so it cannot say "580.119.02 or
newer": a host that installs an older 580 point release is not caught here.

=item * Maxwell/Pascal/Volta C<1340>-C<1DF6> (Tesla M60/M40, P100, P40, P4, V100,
V100S, TITAN V, ...): the 580 legacy list of NVIDIA's C<supportedchips>
README (615.71.09). Proprietary kernel module only; 580 is the last branch.
Compute: the entry-level parts in it (GeForce GT 1030, MX110/MX130/MX150,
GTX 750 Ti, GTX 9xx) included -- the 580 README lists every one of those IDs
as current, Maxwell Gen1 (GM107/GM108) too.

=item * Turing, Ampere, Ada, Hopper C<1DF7>-C<28FF>: the current list of
NVIDIA's C<supportedchips> README of every Linux-x86_64 and aarch64 driver
release from 470.42.01 to 620.73.04. Compute, GeForce MX450/MX550/MX570 and
GTX 16xx included. Kernel module C<either> (except GH200, next item), no
upper bound, and as lower bound the oldest branch whose last release lists
the GPU:

=over

=item * Hopper C<2300>-C<23FF> and Ada C<2600>-C<28FF>: B<520>. Driver
470.256.02 -- the last 470, Debian 11's -- lists no ID above C<25FA>, 515.105.01
no Hopper or Ada either; 520.56.06 is the first with H100 PCIe C<2331> and
GeForce RTX 4090 C<2684>. The lists have nothing in C<2239>-C<230D>,
C<2349>-C<2413> or C<25FC>-C<2683>, so both ranges are taken as blocks: an
unlisted ID inside one gets 520 too.

=item * Turing/Ampere C<1DF7>-C<22FF> and C<2400>-C<25FF>: no bound. Every
GPU listed there is in 470.256.02, the oldest branch a built-in source
installs, unless it has a row of its own; floors below 470 were not looked
up.

=item * 88 GPUs that NVIDIA lists first in a newer branch than their block's
have a row each: 525 (H100 80GB HBM3 C<2330>, H800, L40, L4, RTX 6000 Ada, most of
the GeForce RTX 40xx ...), 535 (H100 NVL C<2321>, H20, L40S C<26B9>, L20, L2,
RTX 5000/4500/4000 Ada, ...), 550 (H200 C<2335>, RTX 40xx SUPER, RTX 4090 D,
RTX A1000/A400, ...), 555 (RTX 4070 Ti SUPER C<2689>), 565 (H200 NVL
C<233B>), 580 (H20 NVL16 C<230E>), and for Turing/Ampere 510 (A800, GTX 1630,
...), 515 (RTX 2050, RTX 3050 C<2582>, ...), 525, 535 and 550. The complete
list, with the release that first lists each GPU, is the comment in the
source.

=back

The table counts whole branches: an earlier point release of the floor branch
can lack the GPU. The releases Debian ships (11: 470.256.02, 12: 535.261.03,
13: 550.163.01) list every GPU whose row their branch passes.

=item * Grace Hopper GH200 C<2342> (120GB, 480GB) and C<2348> (144G HBM3e)
have their own rows ahead of the Hopper block: open kernel module only,
oldest branch 535 (C<2342>) and 565 (C<2348>). The IDs are from NVIDIA's
C<supportedchips> READMEs (C<2342> first in 535.129.03, not in 535.113.01;
C<2348> first in 565.57.01), checked 2026-09-26 and 2026-11-26. Open-only is a maintainer
decision following NVIDIA's blog post "NVIDIA Transitions Fully
Towards Open-Source GPU Kernel Modules"; NVIDIA's driver README
(C<kernel_open.html>, up to 615.71.09) still lists Hopper as supported by the
proprietary flavor, with no Grace exception.

=item * Kepler or older, every ID below C<1340> (Kepler C<0FC6>-C<12BA>, Fermi and
earlier): the 470 and older legacy lists. Proprietary only, nothing newer
than 470. Not compute, at any PCI class (the class-C<0302> Tesla
K80/K40/K20 included): L<Rex::GPU::Detect> skips them with a
warning, and L<Rex::GPU::NVIDIA> refuses to install for one passed to it
anyway.

=back

=head2 for_device_id

  my $req = Rex::GPU::NVIDIA::Requirement->for_device_id('1db4');

The requirement for one NVIDIA PCI device ID (the C<XXXX> in C<[10de:XXXX]>,
any case), looked up in L</generations>. C<undef>, a malformed ID and an ID
no row covers all return a requirement of C<either> with no bounds. Called on
a subclass, it returns an object of that subclass and uses its table.

=head2 from_gpu

  my $req = Rex::GPU::NVIDIA::Requirement->from_gpu($gpu);

The same for a GPU hashref as returned by L<Rex::GPU::Detect/detect>: looks
up its C<device_id> and carries its C<name> along for messages. Croaks unless
C<$gpu> is a hashref.

=head2 satisfied_by

  $req->satisfied_by({ kernel_module => 'open', branch => 580 });   # 1 or 0
  $req->satisfied_by({ kernel_module => 'open', branch_at_least => 590 });

Whether a driver source satisfies this requirement: 1 or 0, the negation of
L</why_not>. A source is a hashref with a C<kernel_module> (C<open> or
C<proprietary>) and what is known about its driver branch, one of:

=over

=item * C<branch> -- an integer: the source installs exactly that branch
(C<nvidia-driver-580-server>, Debian 12's C<nvidia-driver> 535).

=item * C<branch_at_least> -- an integer, C<branch> undefined: the source
installs the B<newest> branch its repository carries, which is not known
before the install but is known to be at least this one (the repository
carries it, and a repository does not lose its newest branch). It satisfies
a L</min_branch> up to that floor and B<never> a L</max_branch>: a newer
branch can appear in the repository at any time and move past the bound.

=item * neither -- the branch is not known at all. That satisfies only a
requirement with no bounds.

=back

A requirement of C<either> takes any kernel module; otherwise the module must
match exactly. An exact C<branch> must lie within
L</min_branch>..L</max_branch>, both inclusive. A missing C<kernel_module>
satisfies only C<either>: an unknown never passes a real constraint. Croaks
unless C<$source> is a hashref, or if C<branch> or C<branch_at_least> is not
an integer.

=head2 why_not

  my $reason = $req->why_not($source);   # undef if it fits

C<undef> if L</satisfied_by> would say 1, otherwise a short reason for
messages (C<"proprietary kernel module, the open one is needed">,
C<"branch 590 is newer than 580">).

=head2 intersect

  my $req = Rex::GPU::NVIDIA::Requirement->intersect(@requirements);
  my $req = $v100->intersect($b200);   # invocant included: croaks here

The one requirement that satisfies all given ones, for a host with several
GPUs: one driver has to drive them all. Called on an object, that object is
one of the requirements. The kernel module is the one any member insists on
(C<either> only if all say C<either>); C<min_branch> is the highest lower
bound, C<max_branch> the lowest upper bound. A single requirement comes back
unchanged; several give a new object whose L</members> lists them (nested
intersections flattened) and whose C<generation>, C<device_id> and C<name>
are C<undef>.

Croaks with the L</conflicts>, naming the GPUs on each side, if members need
different kernel modules (a V100 needs C<proprietary>, a B200 C<open>) or the
bounds leave no branch (one GPU needs at least 590, another at most 580).
Also croaks for an empty list or anything that is not a requirement object.

=head2 conflicts

  my @why = Rex::GPU::NVIDIA::Requirement->conflicts(@requirements);

What L</intersect> would croak about, as a list of messages, one per
conflict; empty when the requirements can be combined. For a caller that
wants to phrase the failure itself.

=head2 describe

  print $req->describe;   # "open kernel module, driver branch 570 or newer"

A short human-readable form of the constraint, for log lines and error
messages.

=head2 who

  print $req->who;   # "GV100GL [Tesla V100] (Maxwell/Pascal/Volta, 10de:1db4)"

Who the requirement is for, for messages: the GPU's name, generation and
device ID, or for an intersected requirement the L</members>, comma
separated. C<NVIDIA GPU> when nothing is known.

=head1 SEE ALSO

L<Rex::GPU::NVIDIA>, L<Rex::GPU::Detect>,
L<https://github.com/NVIDIA/open-gpu-kernel-modules>

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
