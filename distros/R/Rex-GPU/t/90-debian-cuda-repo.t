use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Unit tests for the Debian Blackwell driver source selection (karr #18).
#
# The Debian (non-Ubuntu) branch of install_driver installs Debian's own
# nvidia-driver from non-free. No Debian-packaged version supports Blackwell
# (bookworm 535, trixie/sid 550; Blackwell needs >= 570 and the open kernel
# module), so for a Blackwell GPU the install comes from NVIDIA's CUDA apt
# repo instead: cuda-keyring for debian12|debian13 / x86_64|sbsa, then
# nvidia-driver-cuda + nvidia-kernel-open-dkms.
#
# The decision is Rex::GPU::NVIDIA::Setup::Debian's plan (karr #33: the
# requirement-driven source selection replaced _debian_nvidia_cuda_repo; the
# claims below are kept, asserted on the plan now). With os/release/arch/
# kernel injected into new() the plan reads nothing from the host, so it is
# unit-testable offline. Claims asserted:
#   * non-Blackwell GPU or no GPU => $plan->{cuda_repo} undef => the unchanged
#     Debian non-free path, whatever the release or architecture
#   * Blackwell on Debian 12/13 amd64/arm64 => the right repo + package set
#   * Blackwell on any other release/arch => dies (fail loud, before any
#     host change) rather than falling back to a driver that cannot bind
#
# NOT covered here (needs a real Debian Blackwell host; none was available):
#   * that cuda-keyring installs and `apt-get install nvidia-driver-cuda
#     nvidia-kernel-open-dkms` resolves on a real host (the dependency closure
#     was checked against NVIDIA's and Debian's Packages indexes, not run)
#   * that nvidia-kernel-open-dkms DKMS-builds against the running kernel and
#     the module binds after the nouveau reboot
#   * the exact commands install_driver emits: t/96 (goldens)
# -----------------------------------------------------------------------------

use Rex::GPU::NVIDIA;

# The CUDA repo the plan chose, undef on the non-free path.
sub repo {
  my ( $gpu, $release, $arch ) = @_;
  no warnings 'redefine';
  local *Rex::Logger::info = sub { };
  my $plan = Rex::GPU::NVIDIA::Setup::Debian->new(gpu => $gpu, os => 'Debian',
    release => $release, arch => $arch, kernel => '6.12.0-test')->plan;
  return undef unless $plan->{cuda_repo};
  return { %{ $plan->{cuda_repo} }, packages => $plan->{source}{packages} };
}

my $rtx5090 = { name => 'GB202 [GeForce RTX 5090]', vendor => 'nvidia',
                pci_class => '0300', compute => 1, device_id => '2b85' };
my $b200    = { name => 'GB100 [B200]', vendor => 'nvidia',
                pci_class => '0302', compute => 1, device_id => '2901' };
my $rtx4000 = { name => 'AD104GL [RTX 4000 SFF Ada Generation]', vendor => 'nvidia',
                pci_class => '0302', compute => 1, device_id => '27b0' };

subtest 'non-Blackwell / no GPU => undef (Debian non-free path unchanged)' => sub {
  is(repo($rtx4000, '12.11', 'amd64'), undef, 'RTX 4000 Ada on Debian 12 => undef');
  is(repo($rtx4000, '13.1',  'amd64'), undef, 'RTX 4000 Ada on Debian 13 => undef');
  is(repo(undef,    '13.1',  'amd64'), undef, 'no GPU passed => undef');
  is(repo({},       '13.1',  'amd64'), undef, 'GPU without device_id => undef');
  # A GPU without constraints takes non-free whatever its branch: an unknown
  # release keeps today's behaviour instead of dying.
  is(repo($rtx4000, 'forky/sid', 'ppc64el'), undef,
    'non-Blackwell on unknown release/arch => undef, no die');
};

subtest 'Blackwell on Debian 13 amd64' => sub {
  my $r = repo($rtx5090, '13.1', 'amd64');
  is($r->{distro}, 'debian13', 'distro debian13');
  is($r->{arch},   'x86_64',   'amd64 => x86_64 repo tree');
  is($r->{keyring_url},
    'https://developer.download.nvidia.com/compute/cuda/repos/debian13/x86_64/cuda-keyring_1.1-1_all.deb',
    'keyring URL');
  is_deeply($r->{packages}, [ 'nvidia-driver-cuda', 'nvidia-kernel-open-dkms' ],
    'compute-only open set; no Debian nvidia-driver / nvidia-smi');
};

subtest 'Blackwell on Debian 12, both architectures' => sub {
  my $r = repo($b200, '12.11', 'amd64');
  is($r->{distro}, 'debian12', '12.11 => debian12 (dots kept: not 1211)');
  is($r->{arch},   'x86_64',   'amd64 => x86_64');
  $r = repo($b200, '12.7', 'arm64');
  is($r->{arch}, 'sbsa', 'arm64 => sbsa repo tree');
  is($r->{keyring_url},
    'https://developer.download.nvidia.com/compute/cuda/repos/debian12/sbsa/cuda-keyring_1.1-1_all.deb',
    'sbsa keyring URL');
  is(repo($b200, '13', 'arm64')->{distro}, 'debian13', 'bare "13" => debian13');
};

subtest 'Blackwell on an unsupported release/arch => dies (fail loud)' => sub {
  for my $rel ('11.11', '14.0', 'forky/sid', 'trixie/sid', '', undef) {
    my $label = defined $rel ? "'$rel'" : 'undef';
    ok(!eval { repo($rtx5090, $rel, 'amd64'); 1 }, "release $label dies");
    like($@, qr/Debian 12 and 13/, "release $label: message names the supported releases");
    like($@, qr/No driver package was installed and no package source was added/, "release $label: ... and that no driver package was installed");
  }
  for my $arch ('i386', 'ppc64el', '', undef) {
    my $label = defined $arch ? "'$arch'" : 'undef';
    ok(!eval { repo($rtx5090, '13.1', $arch); 1 }, "arch $label dies");
    like($@, qr/amd64 and arm64/, "arch $label: message names the supported archs");
  }
};

done_testing;
