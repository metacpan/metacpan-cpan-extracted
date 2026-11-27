#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# karr k110: gpu_setup on a mixed NVIDIA + AMD host -- the dies of the AMD
# install_driver that come AFTER `apt-get update` (the amdgpu repository is in
# place, no AMD package was installed) are said "for the AMD GPU", because by
# then the NVIDIA steps may have installed their driver and gpu_detect
# pciutils. Same pattern as t/21-amd-gpu-setup-mixed.t (k104): the REAL
# Rex::GPU::gpu_setup and the REAL Rex::GPU::AMD::install_driver on a scripted
# host; only detection, the connection check and the NVIDIA steps are
# replaced (the NVIDIA ones by recorders).
#
# CLAIMS:
#   * dkms (Ubuntu 24.04, MI300X), amdgpu-dkms without a candidate: the die
#     under gpu_setup reads `... (no candidate). No driver package was
#     installed for the AMD GPU; the amdgpu repository ... a re-run accepts
#     them` -- the whole message, with the NVIDIA steps having run first;
#   * inbox (Ubuntu 24.04 HWE 7.0, an APU with amd_integrated => 1), the
#     module package without a candidate: `... (no candidate). Nothing was
#     installed for the AMD GPU`;
#   * RHEL 9, `dnf repoquery` failing with exit 1: `... failed (<why>). No
#     driver package was installed for the AMD GPU`;
#   * two AMD GPUs: "GPUs" in the same places (dkms, where the phrase sits
#     before a ";", and RHEL, where it ends the message);
#   * the standalone Rex::GPU::AMD::install_driver keeps the old wording in
#     the very same cases -- "No driver package was installed;" / "... was
#     installed" / "Nothing was installed" with no "for the AMD GPU" -- and
#     $Rex::GPU::AMD::GPU_SETUP is undef after every call;
#   * no `pkg:` line and no unmocked Rex function in any of them.
#
# NOT covered -- scripted host, hand-written output:
#   * a real apt/dnf: that the repository is in place, that "a re-run accepts
#     them" is true; the apt-cache policy and dnf repoquery answers are
#     hand-written (no candidate: `Candidate: (none)`; a metadata failure
#     with an invented error text);
#   * the NVIDIA steps are recorders: that one of them installed a driver
#     before the AMD die is what the message says, not something shown here;
#   * the Rex::Rancher side (gpu => 1): nothing there matches these texts
#     (the worker grepped it on 2026-11-26; not re-checked here);
#   * the rewrite of a die that is not these (that is t/21-amd-gpu-setup-mixed.t,
#     k104) and other dies after apt-get update that carry neither sentence.
# This fails against HEAD: gpu_setup there rewrites only "Nothing was changed
# on the host".
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host );
use Test::RexGPU::AMD qw( amd_host amd_state gpu_synapse gpu_mi300x os_kernel );
use Rex::GPU;
use Rex::GPU::AMD;

{
  package Local::FakeConn;
  sub new { bless {}, shift }
  sub disconnect { 1 }
  sub reconnect  { 1 }
}

my %BROKEN = (
  mi300x  => { slot => '0000:c1:00.0', class => '1200', device_id => '74a1', driver => undef, kfd => undef, render => undef },
  mi300x2 => { slot => '0000:c2:00.0', class => '1200', device_id => '74a1', driver => undef, kfd => undef, render => undef },
  synapse => { slot => '0000:95:00.0', class => '0380', device_id => '1586', driver => undef, kfd => undef, render => undef,
               vram => undef, gtt => undef },
);
sub fresh { my ( @gpus ) = @_; return amd_state(amdgpu => 0, kfd => 0, gpus => [ map { $BROKEN{$_} } @gpus ]) }
sub mi300x_two { return ( gpu_mi300x(), { %{ gpu_mi300x() }, slot => '0000:c2:00.0' } ) }

# a package no source carries, as apt-cache policy prints it
sub policy_none {
  my ( $pkg ) = @_;
  return [ "LC_ALL=C apt-cache policy $pkg 2>/dev/null" => "$pkg:\n  Installed: (none)\n  Candidate: (none)\n  Version table:\n", 0 ];
}
# dnf repoquery failing for kernel-headers (and rpm -q finding it missing)
my $WHY = "Error: Failed to download metadata for repo 'amdgpu'";
my @RHEL_FAILS = (
  [ qr{^rpm -q kernel-headers-} => 'package kernel-headers is not installed', 1 ],
  [ qr{^dnf -q repoquery --available } => $WHY, 1 ],
);

my @NV_STEPS = qw( install_driver install_container_toolkit generate_cdi_specs configure_containerd verify_nvidia );

# gpu_setup on a mixed host: NVIDIA recorders, the REAL AMD install_driver.
# Returns ( $rec, \@nvidia_steps_in_order ).
sub via_gpu_setup {
  my ( $host, $amd_gpus, %opt ) = @_;
  my @order;
  my %nv = map { my $s = $_; ( "Rex::GPU::NVIDIA::$s" => sub { push @order, $s; 1 } ) } @NV_STEPS;
  my $rec = record_host(host => $host,
    subs => {
      'Rex::GPU::gpu_detect'        => sub { return { nvidia => [ { name => 'NVIDIA Test GPU', compute => 1 } ], nvswitch => [], amd => [ @$amd_gpus ] } },
      'Rex::GPU::_check_connection' => sub { return },
      'Rex::get_current_connection' => sub { return { conn => Local::FakeConn->new } },
      %nv,
    },
    code => sub { Rex::GPU::gpu_setup(%{ $opt{args} // {} }) });
  return ( $rec, \@order );
}
# the standalone install_driver, same host, same GPUs
sub via_install_driver {
  my ( $host, $amd_gpus ) = @_;
  return record_host(host => $host,
    subs => { 'Rex::get_current_connection' => sub { return { conn => Local::FakeConn->new } } },
    code => sub { Rex::GPU::AMD::install_driver(gpus => [ @$amd_gpus ]) });
}

sub sane {
  my ( $rec, $label ) = @_;
  ok(!( grep { /^pkg:/ } @{ $rec->{lines} } ), "$label: no pkg: line");
  ok(!$rec->{trapped}, "$label: no unmocked Rex function reached");
  is($Rex::GPU::AMD::GPU_SETUP, undef, "$label: the gpu_setup flag is undef afterwards");
}

#### dkms, Ubuntu 24.04, MI300X: amdgpu-dkms has no candidate

my $REPO = 'the amdgpu repository /etc/apt/sources.list.d/amdgpu.list and its signing key /etc/apt/keyrings/rocm.gpg are in place, and a re-run accepts them';
my $DKMS_DIE = "install_driver: amdgpu-dkms cannot be installed from the host's package sources (no candidate). No driver package was installed";

sub dkms_host { my ( @gpus ) = @_; return amd_host('ubuntu-24.04', state => [ fresh(@gpus) ], module => 'none', responses => [ policy_none('amdgpu-dkms') ]) }

subtest 'dkms, one MI300X: "for the AMD GPU"; install_driver alone keeps the old wording' => sub {
  my ( $rec, $order ) = via_gpu_setup(dkms_host('mi300x'), [ gpu_mi300x() ]);
  is_deeply($order, \@NV_STEPS, 'the NVIDIA steps ran first, in order');
  is($rec->{error}, "$DKMS_DIE for the AMD GPU; $REPO", 'gpu_setup: the whole message');
  sane($rec, 'gpu_setup');

  $rec = via_install_driver(dkms_host('mi300x'), [ gpu_mi300x() ]);
  is($rec->{error}, "$DKMS_DIE; $REPO", 'install_driver alone: the old wording, character for character');
  unlike($rec->{error}, qr/for the AMD GPU/, '... no "for the AMD GPU"');
  sane($rec, 'direct');
};

#### inbox, Ubuntu 24.04 HWE 7.0, an APU: the module package has no candidate

subtest 'inbox, one APU: "Nothing was installed for the AMD GPU"; install_driver alone keeps the old wording' => sub {
  my $kernel = '7.0.0-42-generic';
  my $host = sub { amd_host('ubuntu-24.04', kernel => $kernel, state => [ fresh('synapse') ], module => 'none',
    responses => [ policy_none("linux-modules-extra-$kernel") ]) };
  my $die = "install_driver: linux-modules-extra-$kernel cannot be installed from the host's package sources (no candidate). Nothing was installed";

  my ( $rec, $order ) = via_gpu_setup($host->(), [ gpu_synapse() ], args => { amd_integrated => 1 });
  is_deeply($order, \@NV_STEPS, 'the NVIDIA steps ran first, in order');
  is($rec->{error}, "$die for the AMD GPU", 'gpu_setup: the whole message');
  sane($rec, 'gpu_setup');

  $rec = via_install_driver($host->(), [ gpu_synapse() ]);
  is($rec->{error}, $die, 'install_driver alone: the old wording');
  unlike($rec->{error}, qr/for the AMD GPU/, '... no "for the AMD GPU"');
  sane($rec, 'direct');
};

#### RHEL 9, dkms: dnf repoquery fails

subtest 'RHEL 9, repoquery exit 1: "... No driver package was installed for the AMD GPU"; install_driver alone keeps the old wording' => sub {
  my $kernel = os_kernel('rhel-9');
  my $host = sub { amd_host('rhel-9', state => [ fresh('mi300x') ], module => 'none', responses => [ @RHEL_FAILS ]) };
  my $die = "install_driver: looking up kernel-headers-$kernel with dnf failed ($WHY). No driver package was installed";

  my ( $rec, $order ) = via_gpu_setup($host->(), [ gpu_mi300x() ]);
  is_deeply($order, \@NV_STEPS, 'the NVIDIA steps ran first, in order');
  is($rec->{error}, "$die for the AMD GPU", 'gpu_setup: the whole message');
  sane($rec, 'gpu_setup');

  $rec = via_install_driver($host->(), [ gpu_mi300x() ]);
  is($rec->{error}, $die, 'install_driver alone: the old wording');
  unlike($rec->{error}, qr/for the AMD GPU/, '... no "for the AMD GPU"');
  sane($rec, 'direct');
};

#### two AMD GPUs: "GPUs"

subtest 'two AMD GPUs: "GPUs", before a ";" (dkms) and at the end (RHEL)' => sub {
  my ( $rec ) = via_gpu_setup(dkms_host(qw( mi300x mi300x2 )), [ mi300x_two() ]);
  is($rec->{error}, "$DKMS_DIE for the AMD GPUs; $REPO", 'dkms: "for the AMD GPUs;"');
  sane($rec, 'dkms');

  my $kernel = os_kernel('rhel-9');
  ( $rec ) = via_gpu_setup(amd_host('rhel-9', state => [ fresh(qw( mi300x mi300x2 )) ], module => 'none', responses => [ @RHEL_FAILS ]),
    [ mi300x_two() ]);
  is($rec->{error}, "install_driver: looking up kernel-headers-$kernel with dnf failed ($WHY). No driver package was installed for the AMD GPUs",
    'RHEL: ends "for the AMD GPUs"');
  sane($rec, 'RHEL');

  # the standalone call, two GPUs: still the old wording
  $rec = via_install_driver(dkms_host(qw( mi300x mi300x2 )), [ mi300x_two() ]);
  is($rec->{error}, "$DKMS_DIE; $REPO", 'install_driver alone, two GPUs: the old wording');
};

done_testing;
