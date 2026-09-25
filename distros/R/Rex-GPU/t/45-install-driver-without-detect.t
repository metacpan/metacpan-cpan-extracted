use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# install_driver without gpu_detect (karr #42, for kubernetes-ocp k155).
#
# CLAIM: a caller that finds the GPU itself (OCP reads sysfs; its tests forbid
# pciutils) can call install_driver(gpu => { device_id, name }) and
#   * nothing on the way -- setup_for, plan, Requirement, install, verify --
#     runs lspci, installs pciutils or calls Rex::GPU::Detect::detect;
#   * the minimal hash (no compute/pci_class/vendor keys) gets exactly the
#     transcript the full lspci-parsed fixture gets, on every OS;
#   * a device_id that is there but not four hex digits (sysfs "0x2b85", a
#     trailing newline) dies before any host interaction instead of silently
#     counting as an unknown GPU (which would lose the Kepler refusal and the
#     Blackwell open-module choice); a missing device_id is an unknown GPU.
#
# NOT covered: whether the device_id a real caller reads from sysfs is the
# one lspci prints -- no GPU host runs here, and the transcript is command
# strings, never executed.
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host host_names host_profile gpu_fixture );
use Rex::GPU::NVIDIA;

my $detect_called = 0;
{
  no warnings 'redefine';
  *Rex::GPU::Detect::detect = sub { $detect_called++; die "Rex::GPU::Detect::detect called\n" };
}

sub minimal {
  my ( $name ) = @_;
  my $full = gpu_fixture($name);
  return { device_id => $full->{device_id}, name => $full->{name} };
}

sub driver_on {
  my ( $os, %opt ) = @_;
  return record_host(host => host_profile($os),
    code => sub { Rex::GPU::NVIDIA::install_driver(%opt) });
}

sub pci_lines { grep { /lspci|pciutils/ } @{ $_[0]{lines} } }

for my $os (host_names()) {
  for my $g (qw( ada blackwell volta )) {
    my $min  = driver_on($os, gpu => minimal($g));
    my $full = driver_on($os, gpu => gpu_fixture($g));
    ok(!$min->{trapped}, "$os + minimal $g: no unmocked Rex call");
    is_deeply([ pci_lines($min) ], [], "$os + minimal $g: no lspci / pciutils line");
    is($min->{error}, $full->{error}, "$os + minimal $g: dies/lives like the detected GPU");
    is_deeply($min->{lines}, $full->{lines}, "$os + minimal $g: same commands as the detected GPU");
  }

  my $rec = driver_on($os, gpus => [ minimal('ada'), minimal('blackwell') ]);
  is_deeply($rec->{lines}, driver_on($os, gpu => gpu_fixture('blackwell'))->{lines},
    "$os + minimal Ada+Blackwell: gets what Blackwell gets");
  is_deeply([ pci_lines($rec) ], [], '... no lspci / pciutils line');

  $rec = driver_on($os, gpu => minimal('kepler'));
  like($rec->{error}, qr/Kepler or older.*No driver package was installed and no package source was added/,
    "$os + minimal K80: refused like the detected one");
  is_deeply($rec->{lines}, [ 'run: nvidia-smi -L 2>&1' ], '... after the nvidia-smi probe only');

  $rec = driver_on($os, gpus => [ minimal('volta'), minimal('b200') ]);
  like($rec->{error}, qr/^No single NVIDIA driver supports all GPUs/, "$os + minimal V100+B200: conflict dies");
}

is($detect_called, 0, 'Rex::GPU::Detect::detect was never called');

#### device_id format

for my $bad ('0x2b85', "2b85\n", '2b8', '2b855', 'GB202', '') {
  ( my $shown = $bad ) =~ s/\n/\\n/;
  my $rec = driver_on('ubuntu-24.04', gpu => { device_id => $bad, name => 'NVIDIA GeForce RTX 5090' });
  like($rec->{error}, qr/device_id '.*' is not a PCI device ID of four hex digits.*No driver package was installed and no package source was added/s,
    "device_id '$shown' dies");
  is_deeply($rec->{lines}, [], '... before any host interaction');
}

{
  my $rec = driver_on('ubuntu-24.04', gpu => { device_id => '2B85', name => 'NVIDIA GeForce RTX 5090' });
  is_deeply($rec->{lines}, driver_on('ubuntu-24.04', gpu => minimal('blackwell'))->{lines},
    'upper-case hex is the same GPU');

  # no device_id: an unknown GPU -- no constraint, the GPU-agnostic choice
  $rec = driver_on('ubuntu-24.04', gpu => { name => 'NVIDIA Something' });
  is($rec->{error}, undef, 'no device_id: accepted');
  is_deeply($rec->{lines}, driver_on('ubuntu-24.04')->{lines}, '... and installs what no GPU gets');

  # the setup => object path checks the GPUs it is handed as well
  my $obj = Rex::GPU::NVIDIA::Setup::Ubuntu->new;
  $rec = driver_on('ubuntu-24.04', gpu => { device_id => '0x2b85' }, setup => $obj);
  like($rec->{error}, qr/device_id '0x2b85' is not a PCI device ID/, 'setup => object: bad device_id dies');
  is_deeply($rec->{lines}, [], '... before any host interaction');

  ok(!eval { Rex::GPU::NVIDIA::Setup::Debian->new(gpus => [ { device_id => '0x1db4' } ]); 1 },
    'Setup->new croaks on a bad device_id');
  like($@, qr/device_id '0x1db4'/, '... naming it');
}

done_testing;
