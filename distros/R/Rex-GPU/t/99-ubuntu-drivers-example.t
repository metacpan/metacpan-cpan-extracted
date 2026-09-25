use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib", "$Bin/../eg/ubuntu-drivers/lib";

# -----------------------------------------------------------------------------
# eg/ubuntu-drivers (karr #42): a custom Ubuntu setup whose resolve_source
# asks `ubuntu-drivers list --gpgpu` for the package.
#
# CLAIM: with that class, install_driver installs (and verifies) the newest
# -server package of the chosen source's flavour that ubuntu-drivers names,
# never runs apt-cache search, still refuses a flavour the GPU cannot use,
# and dies before any driver install when ubuntu-drivers names nothing. The
# pre-Turing pinned source still takes its candidate check.
#
# NOT covered: the real output format of ubuntu-drivers on 22.04/24.04 (the
# lines below are hand-written after its "PKG, (kernel modules provided by
# ...)" form), and whether it lists anything for a given GPU.
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host host_profile gpu_fixture );
use Rex::GPU::NVIDIA;
use My::GPU::UbuntuDrivers;

my $LIST = join("\n",
  'nvidia-driver-570-server, (kernel modules provided by linux-modules-nvidia-570-server-generic)',
  'nvidia-driver-580-server, (kernel modules provided by linux-modules-nvidia-580-server-generic)',
  'nvidia-driver-580-server-open, (kernel modules provided by linux-modules-nvidia-580-server-open-generic)',
  'nvidia-driver-570-server-open'
);

sub driver_with {
  my ( $list, $gpu ) = @_;
  return record_host(
    host => host_profile('ubuntu-24.04', responses => [
      [ 'ubuntu-drivers list --gpgpu 2>/dev/null' => $list, 0 ]
    ]),
    code => sub { Rex::GPU::NVIDIA::install_driver(gpu => $gpu, setup => 'My::GPU::UbuntuDrivers') }
  );
}

sub installs { grep { / install -y / && !/ubuntu-drivers-common/ } @{ $_[0]{lines} } }

{
  my $rec = driver_with($LIST, gpu_fixture('ada'));
  is($rec->{error}, undef, 'Ada: lives');
  like((installs($rec))[0], qr/ install -y linux-headers-\S+ linux-headers-generic nvidia-driver-580-server$/,
    'Ada: installs the newest proprietary -server package ubuntu-drivers names');
  ok((grep { $_ eq q{run: dpkg -l nvidia-driver-580-server 2>/dev/null | grep -q '^ii'} } @{ $rec->{lines} }),
    '... and verifies it');
  is_deeply([ grep { /apt-cache search/ } @{ $rec->{lines} } ], [], '... without apt-cache search');
  my @l = @{ $rec->{lines} };
  my ( $update ) = grep { $l[$_] =~ / update -q$/ } 0 .. $#l;
  my ( $list )   = grep { $l[$_] =~ /ubuntu-drivers list/ } 0 .. $#l;
  ok($update < $list, '... asking ubuntu-drivers after apt-get update');

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
  is_deeply([ grep { /ubuntu-drivers list/ } @{ $rec->{lines} } ], [], '... not asking ubuntu-drivers');
}

done_testing;
