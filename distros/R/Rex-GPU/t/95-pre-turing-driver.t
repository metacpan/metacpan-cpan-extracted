use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Unit tests for the pre-Turing driver selection (karr #26, interim hotfix
# ahead of epic karr #25).
#
# Maxwell/Pascal/Volta (10de 1340..1DF6, e.g. V100/P100) only work with the
# PROPRIETARY kernel module, and 580 is their last branch. Kepler and older
# (below 1340) stop at 470, which Rex::GPU refuses to install. Ranges from the
# legacy sections of NVIDIA's 615.71.09 supportedchips README.
#
# Everything under test runs offline (no run/dpkg/rpm reaches a host):
#   * Rex::GPU::Detect::legacy_driver_requirement — device-ID ranges
#   * Rex::GPU::NVIDIA::_reject_unsupported_legacy_gpu — the Kepler die
#   * the per-distro selection: the source the Ubuntu/RHEL/SUSE Setup plan
#     picks, with os/release/kernel injected (karr #33: the requirement-driven
#     source selection replaced _ubuntu_legacy_driver_package,
#     _rhel_legacy_driver_plan and _suse_nvidia_repo_params($release,
#     $legacy); the claims are kept, asserted on the chosen source now)
#   * _apt_candidate_present, _rpm_version_in_branch — verify predicates
# The non-regression claim: Turing-and-later and unknown IDs get the
# unchanged default source from every distro.
#
# NOT covered here (needs a real pre-Turing host; none was available):
#   * that nvidia-driver-580-server installs and its DKMS module binds on a
#     real Ubuntu V100 host (package + dependencies checked on Launchpad /
#     packages.ubuntu.com for jammy and noble, not run)
#   * that `dnf module enable nvidia-driver:580-dkms` / `dnf versionlock add
#     '*nvidia*580*'` behave as written against the live CUDA repos (checked
#     against modules.yaml and the rhel10 package index, not run)
#   * that nvidia-driver-G06-kmp-meta installs on Leap 15.6/16.0 (checked in
#     primary.xml, not run), incl. under Secure Boot
#   * the commands install_driver emits (needs a live connection)
# -----------------------------------------------------------------------------

use Rex::GPU::Detect;
use Rex::GPU::NVIDIA;
use Rex::GPU::NVIDIA::Requirement;
use Rex::GPU::NVIDIA::Setup;
use Rex::GPU::NVIDIA::Setup::Apt;
use Rex::GPU::NVIDIA::Setup::Rpm;

# The source a Setup class's plan picks for $gpu, facts injected, no host.
{
  package T::Ubuntu;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Setup::Ubuntu';
  # The B200's NVLink fabric source (karr #56) is t/94's claim; this test is
  # about the driver choice only (and its arch x86_64 is not dpkg's amd64).
  sub nvlink_fabric_unavailable { return }
  sub run_cmd { $? = 0; return 'nvidia-driver-590-server' }
}

sub plan_for {
  my ( $class, $gpu, %facts ) = @_;
  no warnings 'redefine';
  local *Rex::Logger::info = sub { };
  return $class->new(gpu => $gpu, kernel => '6.8.0-1', arch => 'x86_64', %facts)->plan;
}

sub req { scalar Rex::GPU::Detect::legacy_driver_requirement(@_) }

sub gpu {
  my ($id, $name) = @_;
  return { name => $name // 'test', vendor => 'nvidia', pci_class => '0302',
           compute => 1, device_id => $id };
}

my $v100    = gpu('1db4', 'GV100GL [Tesla V100 PCIe 16GB]');
my $p100    = gpu('15f8', 'GP100GL [Tesla P100 PCIe 16GB]');
my $k80     = gpu('102d', 'GK210GL [Tesla K80]');
my $c2050   = gpu('06d1', 'GF100GL [Tesla C2050 / C2070]');
my $t4      = gpu('1eb8', 'TU104GL [Tesla T4]');
my $rtx4000 = gpu('27b0', 'AD104GL [RTX 4000 SFF Ada Generation]');
my $b200    = gpu('2901', 'GB100 [B200]');

subtest 'legacy_driver_requirement — Maxwell/Pascal/Volta => 580' => sub {
  for my $id (qw( 1340 13f2 17fd 15f7 15F8 1b38 1bb3 1d81 1db1 1db4 1db5 1db6 1df6 )) {
    is_deeply(req($id), { generation => 'Maxwell/Pascal/Volta', max_branch => 580 },
      "$id => 580");
  }
};

subtest 'legacy_driver_requirement — Kepler or older => 470' => sub {
  for my $id (qw( 0fc6 1023 1024 1028 102d 12ba 1091 06d1 0020 0000 133f )) {
    is(req($id)->{max_branch}, 470, "$id => 470");
  }
};

subtest 'legacy_driver_requirement — Turing and later / unknown => undef' => sub {
  for my $id (qw( 1df7 1e01 1e02 1eb8 1f82 2182 21c4 20b0 2330 27b0 2684 2901 2e12 3182 9999 ffff )) {
    is(req($id), undef, "$id => undef (default selection)");
  }
  is(req(undef), undef, 'undef => undef');
  is(req(''),    undef, 'empty => undef');
  is(req('1db'), undef, 'three digits => undef');
  is(req('zzzz'), undef, 'non-hex => undef');
  is(req('1db40'), undef, 'five digits => undef');
};

subtest 'real lspci line => device id => requirement' => sub {
  my $g = Rex::GPU::Detect->_parse_nvidia_line(
    '3b:00.0 3D controller [0302]: NVIDIA Corporation GV100GL [Tesla V100 PCIe 32GB] [10de:1db6] (rev a1)'
  );
  is($g->{compute}, 1, 'V100 is compute (class 0302)');
  is(Rex::GPU::NVIDIA::Requirement->from_gpu($g)->max_branch, 580, 'V100 => 580');
};

subtest '_reject_unsupported_legacy_gpu' => sub {
  my $rej = sub { Rex::GPU::NVIDIA::Setup->_reject_unsupported_gpu(@_) };
  ok(!eval { $rej->($k80); 1 }, 'Tesla K80 dies');
  like($@, qr/Kepler or older.*470.*No driver package was installed and no package source was added/s, 'message names generation, branch, no change');
  ok(!eval { $rej->($c2050); 1 }, 'Fermi Tesla C2050 dies');
  for my $g ($v100, $p100, $t4, $rtx4000, $b200, undef, {}, 'x') {
    my $label = ref $g ? ($g->{device_id} // 'no device_id') : ($g // 'undef');
    ok(eval { $rej->($g); 1 }, "$label passes");
  }
};

subtest 'Ubuntu: pinned proprietary 580 -server for pre-Turing only' => sub {
  my $pkg = sub {
    my $plan = plan_for('T::Ubuntu', $_[0], os => 'Ubuntu', release => '24.04');
    return $plan->{source}{check_candidate};
  };
  is($pkg->($v100), 'nvidia-driver-580-server', 'V100 => nvidia-driver-580-server');
  is($pkg->($p100), 'nvidia-driver-580-server', 'P100 => nvidia-driver-580-server');
  is($pkg->($_), undef, "$_->{device_id} => not pinned (newest -server path)")
    for $t4, $rtx4000, $b200;
  is($pkg->(undef), undef, 'no GPU => not pinned');
  is_deeply(plan_for('T::Ubuntu', $v100, os => 'Ubuntu', release => '24.04')->{verify},
    [ 'nvidia-driver-580-server' ], 'V100: the pinned package is verified');
};

subtest 'RHEL: stream on 8/9, versionlock on 10, proprietary kmod' => sub {
  my $RHEL = 'Rex::GPU::NVIDIA::Setup::RHEL';
  # os_release injected: left lazy, plan() runs `cat /etc/os-release` on the
  # machine running the test, and Rex's local exec reads that output with an
  # unlocalised while(<$fh>), clobbering the caller's $_ (karr #59).
  my $plan = sub {
    plan_for($RHEL, $_[1], os => 'Redhat', release => $_[0].'.0', os_release => {})->{source}
  };
  for my $major (8, 9) {
    my $p = $plan->($major, $v100);
    is($p->{module_stream}, '580-dkms', "RHEL $major => stream 580-dkms");
    is($p->{versionlock},   undef,      "RHEL $major => no versionlock");
    is_deeply($p->{packages}, [qw( kmod-nvidia-latest-dkms nvidia-driver nvidia-driver-cuda )],
      "RHEL $major => proprietary package set");
    is_deeply($p->{verify}, [qw( nvidia-driver kmod-nvidia-latest-dkms )],
      "RHEL $major => verifies proprietary kmod");
  }
  my $p = $plan->(10, $v100);
  is($p->{module_stream}, undef,          'RHEL 10 => no module stream');
  is($p->{versionlock},   '*nvidia*580*', 'RHEL 10 => versionlock *nvidia*580*');
  is($p->{pin_branch},    580,            'branch 580 checked after install');
  is($plan->($_->[0], $_->[1])->{name}, 'cuda-open-dkms',
    "RHEL $_->[0] + " . ($_->[1] ? $_->[1]{device_id} : "no GPU") . " => open path")
    for [9, $t4], [10, $rtx4000], [10, $b200], [9, undef];
};

subtest 'SUSE: proprietary G06 for pre-Turing, default otherwise' => sub {
  my $SUSE = 'Rex::GPU::NVIDIA::Setup::SUSE';
  my $params = sub {
    my $plan = plan_for($SUSE, $_[1], os => 'SuSE', release => $_[0]);
    return [ $plan->{repo_url}, @{ $plan->{packages} } ];
  };
  is_deeply($params->('15.6', $v100),
    [ 'https://download.nvidia.com/opensuse/leap/15.6/', 'nvidia-driver-G06-kmp-meta' ],
    'Leap 15.6 + V100 => leap/15.6 + proprietary G06');
  is_deeply($params->('16.0', $v100),
    [ 'https://download.nvidia.com/opensuse/leap/16.0/', 'nvidia-driver-G06-kmp-meta' ],
    'Leap 16.0 + V100 => leap/16.0 + proprietary G06 (not open G07)');
  is_deeply($params->('15.6', undef),
    [ 'https://download.nvidia.com/opensuse/leap/15.6/', 'nvidia-open-driver-G06-signed-kmp-meta' ],
    'Leap 15.6, no legacy => unchanged');
  is_deeply($params->('16.0', undef),
    [ 'https://download.nvidia.com/opensuse/leap/16.0/', 'nvidia-open-driver-G07-signed-kmp-meta' ],
    'Leap 16.0, no legacy => unchanged');
};

subtest '_apt_candidate_present' => sub {
  my $c = sub { Rex::GPU::NVIDIA::Setup::Apt->_apt_candidate_present(@_) };
  is($c->("nvidia-driver-580-server:\n  Installed: (none)\n  Candidate: 580.178.04-0ubuntu0.24.04.1\n"), 1,
    'real candidate => 1');
  is($c->("nvidia-driver-580-server:\n  Installed: (none)\n  Candidate: (none)\n"), 0,
    'Candidate: (none) => 0');
  is($c->(''),    0, 'unknown package (empty output) => 0');
  is($c->(undef), 0, 'undef => 0');
};

subtest '_rpm_version_in_branch' => sub {
  my $v = sub { Rex::GPU::NVIDIA::Setup::Rpm->_rpm_version_in_branch(@_) };
  is($v->('580.178.04', 580), 1, '580.178.04 in 580');
  is($v->('595.91.07',  580), 0, '595 not in 580');
  is($v->('5800.1',     580), 0, '5800.1 not in 580');
  is($v->('package nvidia-driver is not installed', 580), 0, 'not installed => 0');
  is($v->(undef, 580), 0, 'undef => 0');
};

done_testing;
