use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# Distro failure paths of install_driver, and the EL8 branch (karr #64).
#
# CLAIMS:
#   * RHEL 10, V100: `dnf versionlock add '*nvidia*580*'` fails -> dies naming
#     the lock, after the versionlock helper and before `dnf install` of any
#     driver package (golden rocky-10--volta--versionlock-failed);
#   * EL8 (Rocky 8.10, reported "Redhat" like Rocky 9): EPEL, then
#     `powertools` (not crb), kernel-devel-$(uname -r) (not
#     kernel-devel-matched), the rhel8 CUDA repo and the open-dkms module
#     stream (golden rocky-8--ada);
#   * Debian 12, RTX 5090: cuda-keyring not ii after its install -> dies
#     naming the keyring URL, before apt-get update and any driver install
#     (golden debian-12--blackwell--keyring-failed);
#   * a repository step that fails with EMPTY output -- dnf config-manager
#     --add-repo, zypper addrepo, zypper refresh -- dies with the same
#     message minus the ": <output>" part, and emits exactly the commands
#     the same failure with output emits.
#
# NOT covered -- none of this runs without a real GPU host, and a green
# prove is NOT evidence that a driver installs: whether `powertools` is the
# repo id on a given EL8 point release (CentOS 8.0-8.2 spelled it
# PowerTools; the enable is `|| true` there), whether dnf versionlock or
# the cuda-keyring .deb fail the way scripted here, what a real Rocky 8
# answers to `uname -r` / os-release (hand-written stand-ins).
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw(
  record_host golden_is host_profile gpu_fixture
);
use Rex::GPU::NVIDIA;

sub driver_on {
  my ( $host, $gpu ) = @_;
  return record_host(
    host => $host,
    code => sub { Rex::GPU::NVIDIA::install_driver(gpu => $gpu) }
  );
}

sub installs { grep { / install -y / } @{ $_[0]{lines} } }

#### RHEL 10: dnf versionlock add fails

{
  my $rec = driver_on(host_profile('rocky-10', responses => [
    [ q{dnf versionlock add '*nvidia*580*'} => 'Error: No matching packages to lock', 1 ]
  ]), gpu_fixture('volta'));
  is($rec->{error}, q{dnf versionlock add '*nvidia*580*' failed; no driver was installed},
    'rocky-10 + V100, versionlock fails: dies naming the lock');
  is_deeply([ installs($rec) ], [], '... no dnf install of any package');
  like($rec->{lines}[-1], qr/^run: dnf versionlock add /, '... the lock is the last command');
  ok((grep { $_ eq 'pkg: python3-dnf-plugin-versionlock ensure=present' } @{ $rec->{lines} }),
    '... after the versionlock helper');
  golden_is($rec, 'driver/rocky-10--volta--versionlock-failed');
}

#### EL8: powertools, kernel-devel-$(uname -r)

{
  my $os_release = join("\n",
    'NAME="Rocky Linux"', 'VERSION="8.10 (Green Obsidian)"', 'ID="rocky"',
    'ID_LIKE="rhel centos fedora"', 'VERSION_ID="8.10"');
  my $rec = driver_on(host_profile('rocky-9', release => '8.10', responses => [
    [ 'uname -r' => '4.18.0-553.el8_10.x86_64', 0 ],
    [ 'cat /etc/os-release 2>/dev/null' => $os_release, 0 ]
  ]), gpu_fixture('ada'));
  is($rec->{error}, undef, 'rocky-8 + Ada: lives');
  my @l = @{ $rec->{lines} };
  ok((grep { $_ eq 'run: dnf config-manager --set-enabled powertools 2>/dev/null || true' } @l),
    '... enables powertools');
  ok(!(grep { /--set-enabled crb/ } @l), '... not crb');
  ok((grep { /install -y kernel-devel-4\.18\.0-553\.el8_10\.x86_64 kernel-headers nvidia-open$/ } @l),
    '... kernel-devel of the running kernel, not kernel-devel-matched');
  ok((grep { m{/repos/rhel8/x86_64/cuda-rhel8\.repo } } @l), '... the rhel8 CUDA repo');
  golden_is($rec, 'driver/rocky-8--ada');
}

#### Debian: cuda-keyring not installed

{
  my $rec = driver_on(host_profile('debian-12', responses => [
    [ q{dpkg -l cuda-keyring 2>/dev/null | grep -q '^ii'} => '', 1 ]
  ]), gpu_fixture('blackwell'));
  like($rec->{error},
    qr{^cuda-keyring not installed .* cannot add NVIDIA's CUDA repo \(https://developer\.download\.nvidia\.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1\.1-1_all\.deb\)$},
    'debian-12 + RTX 5090, cuda-keyring missing: dies naming the keyring URL');
  is_deeply([ grep { / update -q$| install -y (?!"\$t\/cuda-keyring\.deb")/ } @{ $rec->{lines} } ], [],
    '... no apt-get update, no driver install');
  golden_is($rec, 'driver/debian-12--blackwell--keyring-failed');
}

#### Repository steps failing with empty output

# dnf config-manager --add-repo: same commands as with output, message
# without ": ...".
{
  my $url = 'https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo';
  my $empty = driver_on(host_profile('rocky-9', responses => [
    [ qr{^dnf config-manager --add-repo } => '', 1 ]
  ]), gpu_fixture('ada'));
  is($empty->{error}, "dnf config-manager --add-repo $url failed (exit 1); no driver was installed",
    'rocky-9 + Ada, add-repo fails silently: message without dnf output');
  my $noisy = driver_on(host_profile('rocky-9', responses => [
    [ qr{^dnf config-manager --add-repo } => "Error: Configuration of repo failed\n", 1 ]
  ]), gpu_fixture('ada'));
  is_deeply($empty->{lines}, $noisy->{lines}, '... same commands as with output');
  is_deeply([ installs($empty) ], [], '... no dnf install');
}

# zypper addrepo / refresh: likewise.
{
  my $url = 'https://download.nvidia.com/opensuse/leap/16.0/';
  my $addrepo = qr{^ZYPP_LOCK_TIMEOUT=120 zypper addrepo --refresh };
  my $refresh = 'ZYPP_LOCK_TIMEOUT=120 zypper --gpg-auto-import-keys refresh nvidia-gfx 2>&1';

  my $empty = driver_on(host_profile('leap-16.0', responses => [ [ $addrepo => '', 7 ] ]),
    gpu_fixture('ada'));
  is($empty->{error},
    "zypper addrepo of repository nvidia-gfx ($url) failed (exit 7); nothing was installed from it",
    'leap-16.0 + Ada, addrepo fails silently: message without zypper output');
  my $noisy = driver_on(host_profile('leap-16.0', responses => [ [ $addrepo => "locked\n", 7 ] ]),
    gpu_fixture('ada'));
  is_deeply($empty->{lines}, $noisy->{lines}, '... same commands as with output');
  is_deeply([ installs($empty) ], [], '... no install');

  $empty = driver_on(host_profile('leap-16.0', responses => [ [ $refresh => "  \n", 4 ] ]),
    gpu_fixture('ada'));
  is($empty->{error},
    "zypper refresh of repository nvidia-gfx ($url) failed (exit 4); the repository was removed again; nothing was installed from it",
    'leap-16.0 + Ada, refresh fails with blank output: message without zypper output');
  $noisy = driver_on(host_profile('leap-16.0', responses => [ [ $refresh => "Repository 'nvidia-gfx' is invalid.", 4 ] ]),
    gpu_fixture('ada'));
  is_deeply($empty->{lines}, $noisy->{lines}, '... same commands as with output');
  like($empty->{lines}[-1], qr{^run: ZYPP_LOCK_TIMEOUT=120 zypper rr nvidia-gfx }, '... the entry is removed again');
  is_deeply([ installs($empty) ], [], '... no install');
}

done_testing;
