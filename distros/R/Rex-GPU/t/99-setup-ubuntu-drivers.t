use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# Rex::GPU::NVIDIA::Setup::UbuntuDrivers (karr #69) -- the built-in, opt-in
# successor to the eg/ubuntu-drivers/ example class of karr #42: a
# Setup::Ubuntu subclass whose resolve_source asks `ubuntu-drivers list
# --gpgpu` for the package instead of apt-cache search.
#
# CLAIMS:
#   * with this class, install_driver installs (and verifies) the newest
#     -server package of the chosen source's flavour that ubuntu-drivers
#     names, never runs apt-cache search, still refuses a flavour the GPU
#     cannot use, and dies before any driver install when ubuntu-drivers
#     names nothing; the pre-Turing pinned source still takes its own
#     candidate check (apt-cache policy), not ubuntu-drivers;
#   * ubuntu-drivers-common is only installed (an inert helper,
#     `apt-get install -y --no-upgrade`, run only when ubuntu-drivers is not
#     already on the PATH) for a source with a search pattern -- the pinned
#     580 source (Maxwell/Pascal/Volta) never touches ubuntu-drivers at all,
#     neither the helper install nor `ubuntu-drivers list`;
#   * command -v ubuntu-drivers still failing after that install, or
#     ubuntu-drivers list --gpgpu exiting non-zero, makes the source
#     unavailable: resolve_plan dies before any driver package is installed;
#   * this class is opt-in: Rex::GPU::NVIDIA->setup_class_for_os on Ubuntu is
#     still Rex::GPU::NVIDIA::Setup::Ubuntu (apt-cache search) unless chosen
#     with the setup option or set gpu_nvidia_setup.
#
# NOT covered: the real output format of ubuntu-drivers on 22.04/24.04 (the
# lines below are hand-written after its "PKG, (kernel modules provided by
# ...)" form), whether it lists anything for a given GPU, whether
# ubuntu-drivers-common installs cleanly on a fresh image, and
# eg/ubuntu-drivers/Rexfile itself (only perl -c'd by hand, not by any test
# in this suite).
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host host_profile gpu_fixture );
use Rex::GPU::NVIDIA;
use Rex::GPU::NVIDIA::Setup::UbuntuDrivers;

my $SETUP = 'Rex::GPU::NVIDIA::Setup::UbuntuDrivers';

my $LIST = join("\n",
  'nvidia-driver-570-server, (kernel modules provided by linux-modules-nvidia-570-server-generic)',
  'nvidia-driver-580-server, (kernel modules provided by linux-modules-nvidia-580-server-generic)',
  'nvidia-driver-580-server-open, (kernel modules provided by linux-modules-nvidia-580-server-open-generic)',
  'nvidia-driver-570-server-open'
);

sub driver_with {
  my ( $list, $gpu, %opt ) = @_;
  return record_host(
    host => host_profile('ubuntu-24.04', responses => [
      @{ $opt{responses} // [] },
      [ 'ubuntu-drivers list --gpgpu 2>/dev/null' => $list, 0 ]
    ]),
    code => sub { Rex::GPU::NVIDIA::install_driver(gpu => $gpu, setup => $SETUP) }
  );
}

sub installs             { grep { / install -y / && !/ubuntu-drivers-common/ } @{ $_[0]{lines} } }
sub ubuntu_drivers_calls { grep { /ubuntu-drivers/ } @{ $_[0]{lines} } }

{
  my $rec = driver_with($LIST, gpu_fixture('ada'));
  is($rec->{error}, undef, 'Ada: lives');
  like((installs($rec))[0], qr/ install -y linux-headers-\S+ nvidia-driver-580-server$/,
    'Ada: installs the newest proprietary -server package ubuntu-drivers names, headers of the running kernel only (k69)');
  ok((grep { $_ eq q{run: dpkg -l nvidia-driver-580-server 2>/dev/null | grep -q '^ii'} } @{ $rec->{lines} }),
    '... and verifies it');
  is_deeply([ grep { /apt-cache search/ } @{ $rec->{lines} } ], [], '... without apt-cache search');
  my @l = @{ $rec->{lines} };
  my ( $update ) = grep { $l[$_] =~ / update -q$/ } 0 .. $#l;
  my ( $list )   = grep { $l[$_] =~ /ubuntu-drivers list/ } 0 .. $#l;
  ok($update < $list, '... asking ubuntu-drivers after apt-get update');
  ok((grep { /command -v ubuntu-drivers >\/dev\/null \|\| .*install -y --no-upgrade ubuntu-drivers-common/ } @{ $rec->{lines} }),
    '... installing ubuntu-drivers-common with --no-upgrade, an inert helper, unless already on the PATH');

  $rec = driver_with($LIST, { device_id => '2b85', name => 'NVIDIA GeForce RTX 5090' });
  like((installs($rec))[0], qr/ nvidia-driver-580-server-open$/, 'Blackwell (minimal hash): the -open package');

  $rec = driver_with('', gpu_fixture('ada'));
  like($rec->{error}, qr/ubuntu-drivers list --gpgpu names no nvidia-driver-NNN-server package.*No driver package was installed/,
    'nothing listed: dies');
  is_deeply([ installs($rec) ], [], '... before any driver install');

  $rec = driver_with("nvidia-driver-570-server-open\n", { device_id => '3182', name => 'B300' });
  like($rec->{error}, qr/ubuntu-server-open chosen for B300.*branch 570 is older than 580.*No driver package was installed/, 'B300 with only a 570 listed: the requirement check refuses it');
  is_deeply([ installs($rec) ], [], '... before any driver install');

  $rec = driver_with($LIST, gpu_fixture('volta'));
  like((installs($rec))[0], qr/ nvidia-driver-580-server$/, 'V100: the pinned 580 source, as upstream');
  ok((grep { /apt-cache policy nvidia-driver-580-server/ } @{ $rec->{lines} }), '... with its candidate check');
  is_deeply([ ubuntu_drivers_calls($rec) ], [],
    '... V100 (pinned 580 source): no ubuntu-drivers-common install and no ubuntu-drivers call at all (k69)');
}

#### k69: ubuntu-drivers missing or broken makes the source unavailable,
#### before any driver package is installed

{
  my $rec = driver_with($LIST, gpu_fixture('ada'), responses => [
    [ 'command -v ubuntu-drivers >/dev/null' => '', 1 ]
  ]);
  like($rec->{error}, qr/ubuntu-drivers is not installed \(installing ubuntu-drivers-common failed\).*No driver package was installed/,
    'ubuntu-drivers still missing after the helper install: dies naming it');
  is_deeply([ installs($rec) ], [], '... before any driver install');
  is_deeply([ grep { /ubuntu-drivers list/ } @{ $rec->{lines} } ], [], '... never calling ubuntu-drivers list');

  $rec = driver_with($LIST, gpu_fixture('ada'), responses => [
    [ 'ubuntu-drivers list --gpgpu 2>/dev/null' => 'ERROR: no GPU detected', 1 ]
  ]);
  like($rec->{error}, qr/ubuntu-drivers list --gpgpu failed \(exit 1\).*No driver package was installed/,
    'ubuntu-drivers list --gpgpu exits non-zero: dies naming the exit code');
  is_deeply([ installs($rec) ], [], '... before any driver install');
}

#### k69: opt-in only -- the Ubuntu default is unchanged

{
  my $class;
  my $rec = record_host(host => host_profile('ubuntu-24.04'),
    code => sub { $class = Rex::GPU::NVIDIA->setup_class_for_os });
  is($class, 'Rex::GPU::NVIDIA::Setup::Ubuntu',
    'Ubuntu setup_class_for_os default stays Setup::Ubuntu (apt-cache search): UbuntuDrivers is opt-in only');
}

done_testing;
