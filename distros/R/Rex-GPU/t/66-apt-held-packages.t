#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# The NVIDIA apt layer counts a held package as installed (k94), as the AMD
# apt layer does since k89.
#
# `apt-mark hold nvidia-driver-580-server` (or cuda-keyring) leaves the package
# in dpkg state `hi`: installed and configured, only pinned against upgrades.
# `dpkg -l PKG | grep -q '^ii'` called it missing -- on a host whose operator
# held the driver, gpu_setup died with "not installed after apt-get install".
#
# CLAIMS (the host answers `dpkg -l PKG | grep -q PATTERN` the way the real
# grep would answer a `dpkg -l` row in the given status, see dpkg_l):
#   * Setup::Apt->verify_packages: a package in `ii` or `hi` passes; `iF`,
#     `hF` (half-configured, e.g. a failed DKMS postinst) and `iU` (unpacked)
#     die with a message naming the package;
#   * Setup::Debian->add_nvidia_cuda_apt_repo: cuda-keyring `hi` after the
#     install does not die, `iF` dies;
#   * Setup::Ubuntu->prepare_nvlink_fabric_source: cuda-keyring `hi` takes the
#     "already configured" branch (no key fetch, no pin, no source file, only
#     the index refresh); `iF` is treated as not installed (key fetched, pin
#     and source file written).
#
# NOT covered:
#   * the grep itself: the commands are recorded, never run, and the host's
#     answer is derived from the status column by dpkg_l. A real `dpkg -l`
#     row is not read here;
#   * that apt-mark hold really produces `hi` on a given release, or what
#     apt-get does with a held package it is asked to install;
#   * `ri`, `ic`, `pn` and the other states are not enumerated: only those
#     above; any state beyond ii/hi counts as not installed in dpkg_l;
#   * the rest of install_driver on a host with a held driver (version check,
#     DKMS against the running kernel): t/96 goldens record the commands only.
# This test fails against the code before k94 (grep '^ii') and passes after.
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host host_profile dpkg_l );
use Rex::GPU::NVIDIA;
use Rex::GPU::NVIDIA::Setup::Apt;
use Rex::GPU::NVIDIA::Setup::Debian;
use Rex::GPU::NVIDIA::Setup::Ubuntu;

my $DEBIAN_REPO = {
  distro => 'debian12', arch => 'x86_64',
  keyring_url => 'https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb'
};

sub on_host {
  my ( $os, $states, $code ) = @_;
  return record_host(
    host => host_profile($os, responses => [ dpkg_l(%$states) ]),
    code => $code);
}

sub verify {
  my ( $state ) = @_;
  return on_host('ubuntu-24.04', { 'nvidia-driver-580-server' => $state }, sub {
    Rex::GPU::NVIDIA::Setup::Ubuntu->new->verify_packages({ verify => [ 'nvidia-driver-580-server' ] });
  });
}

subtest 'verify_packages: ii and hi are installed' => sub {
  for my $state (qw( ii hi )) {
    my $rec = verify($state);
    is($rec->{error}, undef, "$state passes");
    ok(!$rec->{trapped}, 'nothing unmocked reached');
  }
};

subtest 'verify_packages: half-installed / half-configured states die' => sub {
  for my $state (qw( iF hF iU )) {
    my $rec = verify($state);
    like($rec->{error}, qr/^nvidia-driver-580-server not installed after apt-get install/,
      "$state dies and names the package");
  }
};

subtest 'verify_packages: every package of the plan is checked' => sub {
  my $rec = on_host('ubuntu-24.04', { 'pkg-a' => 'hi', 'pkg-b' => 'iF' }, sub {
    Rex::GPU::NVIDIA::Setup::Ubuntu->new->verify_packages({ verify => [ 'pkg-a', 'pkg-b' ] });
  });
  like($rec->{error}, qr/^pkg-b not installed/, 'the held package passes, the broken one is named');
};

subtest 'Debian add_nvidia_cuda_apt_repo: cuda-keyring state after the install' => sub {
  my $add = sub {
    my ( $state ) = @_;
    return on_host('debian-12', { 'cuda-keyring' => $state }, sub {
      Rex::GPU::NVIDIA::Setup::Debian->new->add_nvidia_cuda_apt_repo($DEBIAN_REPO);
    });
  };
  for my $state (qw( ii hi )) {
    is($add->($state)->{error}, undef, "$state: no die");
  }
  like($add->('iF')->{error}, qr/^cuda-keyring not installed/, 'iF dies');
};

subtest 'Ubuntu prepare_nvlink_fabric_source: cuda-keyring decides the branch' => sub {
  my $prepare = sub {
    my ( $state ) = @_;
    return on_host('ubuntu-24.04', { 'cuda-keyring' => $state, curl => 'ii' }, sub {
      my $setup = Rex::GPU::NVIDIA::Setup::Ubuntu->new(release => '24.04', arch => 'amd64');
      $setup->prepare_nvlink_fabric_source({});
    });
  };
  my $keyfetch = qr/^run(?:\([^)]*\))?: t=\$\(mktemp -d\) && curl /;
  my $update   = qr/^run(?:\([^)]*\))?: apt-get .* update -q$/;
  for my $state (qw( ii hi )) {
    my $rec = $prepare->($state);
    is($rec->{error}, undef, "$state: no die");
    is(scalar(grep { /^file: / } @{ $rec->{lines} }), 0, "$state: no pin, no source file written");
    is(scalar(grep { $_ =~ $keyfetch } @{ $rec->{lines} }), 0, "$state: no key fetched");
    is(scalar(grep { $_ =~ $update } @{ $rec->{lines} }), 1, "$state: only the index refresh");
  }
  my $rec = $prepare->('iF');
  is($rec->{error}, undef, 'iF: no die');
  is(scalar(grep { $_ =~ $keyfetch } @{ $rec->{lines} }), 1, 'iF: treated as not installed, key fetched');
  is_deeply([ map { /^file: (\S+)/ } grep { /^file: / } @{ $rec->{lines} } ],
    [ '/etc/apt/preferences.d/rex-gpu-nvlsm.pref', '/etc/apt/sources.list.d/rex-gpu-nvlsm.list' ],
    'iF: pin and source file written');
};

done_testing;
