use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Unit tests for the Ubuntu Blackwell open-kernel-module driver selection
# (karr #15, part 2 of #14; generalised to every CPU architecture in #16).
#
# karr #14 made Rex::GPU::Detect classify the GB10 (10de:2e12, NVIDIA DGX
# Spark, aarch64) as compute => 1 via a device-ID allowlist. That activated
# install_driver on a fresh Ubuntu arm64 Spark — and the Ubuntu branch used to
# always filter OUT *-open package candidates, which is correct for the
# verified x86_64 path (RTX 4000 Ada et al.) but wrong for Blackwell-class
# silicon: the GB10 has no proprietary kernel module at all, only the -open
# variant builds/loads for it.
#
# Under test, offline:
#   * Rex::GPU::Detect::open_kernel_module_required -- the device-ID lookup
#   * which source Rex::GPU::NVIDIA::Setup::Ubuntu's plan picks for a GPU
#     (karr #33: the requirement-driven selection replaced the
#     _ubuntu_needs_open_kernel_module gate; same claims, asserted on the
#     chosen source now). The host is faked by overriding run_cmd; since
#     karr #35 plan does not run the apt-cache search (it runs after
#     apt-get update, in resolve_plan), so only the source is asserted.
#
# karr #16: Blackwell has no proprietary kernel module on x86_64 either
# (GeForce RTX 50xx, RTX PRO Blackwell, B200/GB200). The arm64-only gate k15
# had is gone; the decision keys on the PCI device ID alone, against the
# Blackwell ranges in Detect.pm taken from NVIDIA's open-gpu-kernel-modules
# supported-GPU table. The k15 assertion "amd64 + GB10 ID => not open (arch
# gates first)" is deliberately REPLACED: the device ID decides, not the arch.
# The non-regression claim is kept: a non-Blackwell GPU stays on -server.
#
# NOT covered here (needs a real Ubuntu Blackwell host — none was available
# for k15 or k16; see the t/10-detect.t header for the wider "what prove
# cannot see"):
#   * that `apt-cache search '^nvidia-driver-[0-9].*-server-open$'` actually
#     finds a candidate on a real host (repo metadata checked, not exercised
#     against apt); since karr #35 an empty search dies instead of falling
#     back to "nvidia-driver-570-server-open".
#   * that the lspci lines below for RTX 5090 / B200 match a real host: they
#     are built from the pci.ids naming pattern, not captured live.
#   * that the -open package DKMS-builds against a stock Ubuntu kernel (cortex
#     uses DGX-OS prebuilt modules, not this code path — see karr #15).
#   * that the x86_64 RTX 4000 Ada install is unaffected end-to-end (only the
#     selection logic is asserted here, not a live apt-get run).
# -----------------------------------------------------------------------------

use Rex::GPU::Detect;
use Rex::GPU::NVIDIA;

#### Rex::GPU::Detect::open_kernel_module_required

subtest 'open_kernel_module_required' => sub {
  is(Rex::GPU::Detect::open_kernel_module_required('2e12'), 1,
    'GB10 device id 2e12 => open kernel module required');
  is(Rex::GPU::Detect::open_kernel_module_required('2E12'), 1,
    'lookup is case-insensitive');
  is(Rex::GPU::Detect::open_kernel_module_required('27b0'), 0,
    'RTX 4000 Ada device id (outside the Blackwell range) => 0');
  is(Rex::GPU::Detect::open_kernel_module_required('ffff'), 0,
    'unlisted device id => 0');
  is(Rex::GPU::Detect::open_kernel_module_required(undef), 0,
    'undef device id => 0');
};

subtest 'open_kernel_module_required — Blackwell device-ID ranges (karr #16)' => sub {
  my $okm = \&Rex::GPU::Detect::open_kernel_module_required;
  # Blackwell, from NVIDIA's open-gpu-kernel-modules supported-GPU table
  is($okm->('2b85'), 1, 'GeForce RTX 5090 (2b85) => open');
  is($okm->('2C02'), 1, 'GeForce RTX 5080 (2C02, uppercase) => open');
  is($okm->('2d04'), 1, 'GeForce RTX 5060 Ti (2d04) => open');
  is($okm->('2f04'), 1, 'GeForce RTX 5070 GB205 (2f04) => open');
  is($okm->('2bb1'), 1, 'RTX PRO 6000 Blackwell Workstation (2bb1) => open');
  is($okm->('2bb5'), 1, 'RTX PRO 6000 Blackwell Server Edition (2bb5) => open');
  is($okm->('2901'), 1, 'B200 (2901) => open');
  is($okm->('2941'), 1, 'GB200 (2941) => open');
  is($okm->('3182'), 1, 'B300 SXM6 AC (3182) => open');
  is($okm->('31c2'), 1, 'GB300 (31c2) => open');
  is($okm->('2900'), 1, 'range floor 2900 => open (unlisted, post-Ada block)');
  is($okm->('2fff'), 1, 'range ceiling 2fff => open (unlisted, post-Ada block)');
  # Non-Blackwell: must keep today's -server selection
  is($okm->('28f8'), 0, 'last Ada ID in the table (RTX 2000 Ada Embedded, 28f8) => 0');
  is($okm->('2684'), 0, 'GeForce RTX 4090 (Ada, 2684) => 0');
  is($okm->('26b9'), 0, 'L40S (Ada, 26b9) => 0');
  is($okm->('2330'), 0, 'H100 SXM (Hopper, 2330) => 0');
  is($okm->('2342'), 0, 'GH200 (Hopper, 2342) => 0');
  is($okm->('20b0'), 0, 'A100 (Ampere, 20b0) => 0');
  is($okm->('1eb0'), 0, 'Quadro RTX 5000 (Turing, 1eb0) => 0');
  # Unknown / future IDs outside the ranges: no guess
  is($okm->('3000'), 0, 'unknown 3000 (gap above the block) => 0');
  is($okm->('3181'), 0, 'unknown 3181 (next to B300) => 0');
  is($okm->('31c4'), 0, 'unknown 31c4 (next to GB300) => 0');
  is($okm->('9999'), 0, 'unknown future 9999 => 0');
  # Malformed input never reaches hex()
  is($okm->('2b8'),   0, 'three hex digits => 0');
  is($okm->('2b85x'), 0, 'trailing garbage => 0');
  is($okm->('zzzz'),  0, 'non-hex => 0');
  is($okm->(''),      0, 'empty string => 0');
};

#### Which Ubuntu source the plan picks

{
  package T::Ubuntu;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Setup::Ubuntu';
  # The B200's NVLink fabric source (karr #56, plan dies without one on
  # arm64) is t/94's claim; this test is about the driver choice only.
  sub nvlink_fabric_unavailable { return }
  sub run_cmd {
    my ( $self, $cmd ) = @_;
    $? = 0;
    return $cmd =~ /-server-open\$'/ ? 'nvidia-driver-590-server-open'
         : $cmd =~ /-server\$'/      ? 'nvidia-driver-590-server'
         :                              '';
  }
}

# 1 if the plan picks the -server-open driver, 0 if the -server one
sub needs_open {
  my ( $gpu ) = @_;
  no warnings 'redefine';
  local *Rex::Logger::info = sub { };
  my $plan = T::Ubuntu->new(gpu => $gpu, os => 'Ubuntu', release => '24.04',
    arch => 'arm64', kernel => '6.8.0-1')->plan;
  return $plan->{source}{name} eq 'ubuntu-server-open' ? 1
       : $plan->{source}{name} eq 'ubuntu-server'      ? 0
       : die "unexpected source $plan->{source}{name}\n";
}

my $gb10 = { name => 'Device', vendor => 'nvidia', pci_class => '0300',
             compute => 1, device_id => '2e12' };
my $rtx4000 = { name => 'AD104GL [RTX 4000 SFF Ada Generation]', vendor => 'nvidia',
                pci_class => '0302', compute => 1, device_id => '27b0' };

subtest 'GB10 (aarch64 Spark) => still open' => sub {
  is(needs_open($gb10), 1, 'GB10 device id => open');
};

subtest 'Blackwell on x86_64, via the real lspci parser => open (karr #16)' => sub {
  my $rtx5090 = Rex::GPU::Detect::_parse_nvidia_line(
    '01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GB202 [GeForce RTX 5090] [10de:2b85] (rev a1)'
  );
  is($rtx5090->{compute},   1,      'RTX 5090 is compute (RTX name match)');
  is($rtx5090->{device_id}, '2b85', 'device id parsed');
  is(needs_open($rtx5090),  1,      'RTX 5090 => open');

  my $b200 = Rex::GPU::Detect::_parse_nvidia_line(
    '18:00.0 3D controller [0302]: NVIDIA Corporation GB100 [B200] [10de:2901] (rev a1)'
  );
  is($b200->{compute},  1, 'B200 is compute (class 0302)');
  is(needs_open($b200), 1, 'B200 => open');

  my $pro6000 = Rex::GPU::Detect::_parse_nvidia_line(
    '41:00.0 3D controller [0302]: NVIDIA Corporation GB202GL [RTX PRO 6000 Blackwell Server Edition] [10de:2bb5] (rev a1)'
  );
  is(needs_open($pro6000), 1, 'RTX PRO 6000 Blackwell Server Edition => open');
};

subtest 'non-Blackwell GPUs stay on -server (the non-regression point)' => sub {
  is(needs_open($rtx4000), 0, 'RTX 4000 SFF Ada (27b0) => not open');
  my $h100 = Rex::GPU::Detect::_parse_nvidia_line(
    '17:00.0 3D controller [0302]: NVIDIA Corporation GH100 [H100 SXM5 80GB] [10de:2330] (rev a1)'
  );
  is(needs_open($h100), 0, 'H100 (Hopper, 2330) => not open');
  my $rtx4090 = Rex::GPU::Detect::_parse_nvidia_line(
    '01:00.0 VGA compatible controller [0300]: NVIDIA Corporation AD102 [GeForce RTX 4090] [10de:2684] (rev a1)'
  );
  is(needs_open($rtx4090), 0, 'RTX 4090 (Ada, 2684) => not open');
};

subtest 'missing/malformed inputs default to false (safe: keeps -server)' => sub {
  is(needs_open(undef),           0, 'no GPU passed (install_driver called without gpu =>) => not open');
  is(needs_open({}),              0, 'GPU hashref with no device_id => not open');
  is(needs_open('not-a-hashref'), 0, 'non-hashref $gpu => not open (no crash)');
};

done_testing;
