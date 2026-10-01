use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# Rex::GPU::Detect::Sysfs (karr #73, escalated from kubernetes-ocp k196): GPU
# detection from /sys/bus/pci/devices, no lspci, nothing installed.
#
# CLAIMS:
#   * detect() emits exactly ONE host command, the sysfs read, with
#     auto_die => 0 -- no lspci, no `command -v`, no pkg/is_installed
#     (t/golden/detect/sysfs--rtx3090.txt);
#   * a sample line decodes to the documented hash (name, vendor, pci_class,
#     compute, device_id, subsystem_vendor_id, subsystem_id, vgpu) -- IDs are
#     four lowercase hex digits, never 0x, whatever case sysfs used;
#   * compute: the generation row / PCI class decide exactly as for lspci
#     (Kepler => 0 with the warning, class 0302 => 1); where lspci would fall
#     back to naming the product, Sysfs has no name and returns undef
#     ("undecided") with its own warning instead of 0; _is_nvidia_compute
#     always returns exactly one value, even in list context; gpu_setup's
#     compute-only grep (undef counts as false) skips install_driver for an
#     all-0/undef host and calls it with only the compute-1 GPUs on a mixed
#     one;
#   * vGPU: the device-id/subsystem-id pair is looked up in the same table as
#     the lspci path, from the sysfs subsystem fields directly (no slot
#     matching needed);
#   * NVSwitch: only a known device ID at class 0680 counts, no name to fall
#     back on; nvswitch stays [] with no NVIDIA GPU on the host, as for lspci;
#   * virtual displays (virtio/QEMU/VMware/VBox) are skipped per device, never
#     hiding a real card, and an all-virtual host logs the same "skipping"
#     line as an all-virtual lspci host, empty arrays;
#   * other devices: PCI domains other than 0000: are reported, sorted after
#     it; an AMD GPU decodes with compute 0; a device of class 0380 and an
#     ASPEED [1a03] VGA are silently ignored -- today's behaviour (0380 is
#     card k75; not judged here);
#   * dies before anything is installed or changed -- never "no GPU found" --
#     when the read exits non-zero, when a line has fewer than six fields,
#     and when ANY device's class or vendor (a NIC included) is unreadable or
#     malformed; a readable, empty /sys/bus/pci/devices returns empty arrays
#     and only an info log;
#   * every selection path (direct ->detect, gpu_detect(detect => ...),
#     gpu_setup(detect => ...), set gpu_detect_class + bare detect(),
#     Rex::GPU::Detect::Sysfs::detect()) runs the sysfs command and never
#     lspci;
#   * nvswitch_device_ids / virtual_display_vendor_ids are the documented
#     lists, and overriding either in a subclass changes both the lspci path
#     and the Sysfs path -- one list, one override point;
#   * the SYNOPSIS's compute-or-undecided filter, run over a mixed host, and
#     the resulting hashes pass Rex::GPU::NVIDIA::Setup->new(gpus => ...)'s
#     device_id check without dying.
#
# NOT covered -- no host, real or otherwise, runs here, and a green prove is
# NOT evidence any of it works:
#   * a real kernel's /sys/bus/pci/devices -- every line here is a hand-built
#     fixture, not a capture;
#   * the shell loop in $SYSFS_READ actually running under dash/bash/busybox
#     on a host: goldens record the command STRING handed to Rex, never what
#     a real shell does with the `for`/`read`/`printf` inside it;
#   * Rex::LibSSH vs plain SSH exec-channel behaviour for this command;
#   * a real vGPU guest's or HGX host's actual sysfs content -- only the
#     hand-written A10-2Q pair (t/94-vgpu.t's table) and the known NVSwitch
#     IDs are exercised;
#   * gpu_setup's driver/toolkit/CDI/containerd pipeline once install_driver
#     is reached (covered for the lspci path elsewhere, e.g.
#     t/96-golden-driver.t) -- here install_driver is either never reached
#     (compute 0/undef) or stubbed out;
#   * kubernetes-ocp's own Rexfile -- only the filter shown in Sysfs.pm's own
#     SYNOPSIS is run here, against fixtures built for this file.
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host golden_is host_profile );
use Rex::GPU;
use Rex::GPU::Detect;
use Rex::GPU::Detect::Sysfs;
use Rex::GPU::NVIDIA::Setup;

# Rex::Config->set(...) is shared by every host of a Rexfile; reset it after
# each case even if the case dies (t/99-class-dispatch.t's with_config).
sub with_config {
  my ( $key, $value, $code ) = @_;
  Rex::Config->set($key => $value);
  my $ok  = eval { $code->(); 1 };
  my $err = $@;
  Rex::Config->set($key => undef);
  die $err unless $ok;
}

# One line of $Rex::GPU::Detect::Sysfs's sysfs read: "slot class vendor
# device subsystem_vendor subsystem_device", hand-built (not a capture).
my %DEV = (
  rtx3090          => '0000:01:00.0 0x030000 0x10de 0x2204 0x1043 0x87b5',
  rtx3090_upper    => '0000:01:00.0 0X030000 0x10DE 0x2204 0X1043 0x87B5',
  kepler_k80       => '0000:02:00.0 0x030000 0x10de 0x102d 0x0000 0x0000',
  unreadable_0302  => '0000:03:00.0 0x030200 0x10de - - -',
  unreadable_0300  => '0000:04:00.0 0x030000 0x10de - - -',
  unknown_3a00_300 => '0000:05:00.0 0x030000 0x10de 0x3a00 0x0000 0x0000',
  unknown_3a00_302 => '0000:06:00.0 0x030200 0x10de 0x3a00 0x0000 0x0000',
  vgpu_a10         => '0000:07:00.0 0x030200 0x10de 0x2236 0x10de 0x14b9',
  vgpu_a10_not     => '0000:08:00.0 0x030200 0x10de 0x2236 0x10de 0x1234',
  nvswitch_known   => '0000:09:00.0 0x068000 0x10de 0x22a3 0x0000 0x0000',
  nvswitch_unknown => '0000:0a:00.0 0x068000 0x10de 0x0369 0x0000 0x0000',
  virtio           => '0000:0b:00.0 0x030000 0x1af4 0x1050 0x1af4 0x1100',
  amd              => '0000:0c:00.0 0x030000 0x1002 0x744c 0x0000 0x0000',
  class_0380       => '0000:0d:00.0 0x038000 0x10de 0x2204 0x1043 0x87b5',
  aspeed           => '0000:0e:00.0 0x030000 0x1a03 0x2000 0x0000 0x0000',
  domain1          => '0001:00:00.0 0x030000 0x10de 0x2205 0x0000 0x0000',
  domain2          => '10000:00:00.0 0x030000 0x10de 0x2206 0x0000 0x0000'
);

sub sysfs_host {
  my ( $output, $exit ) = @_;
  return host_profile('debian-12',
    responses => [ [ qr{^cd /sys/bus/pci/devices }, $output, $exit // 0 ] ]);
}

sub sysfs_detect {
  my ( $output, $exit ) = @_;
  my $result;
  my $rec = record_host(host => sysfs_host($output, $exit),
    code => sub { $result = Rex::GPU::Detect::Sysfs->detect });
  return ( $result, $rec );
}

#### 1. exactly one host command #############################################

subtest 'detect() emits exactly one host command, auto_die => 0, no lspci/pciutils' => sub {
  my ( $result, $rec ) = sysfs_detect($DEV{rtx3090});
  golden_is($rec, 'detect/sysfs--rtx3090');
  is($rec->{error}, undef, 'lives');
  is(scalar @{$rec->{lines}}, 1, 'exactly one host interaction');
  ok(!(grep { /lspci|command -v|^pkg:|^is_installed:/ } @{$rec->{lines}}),
    'no lspci, no command -v, no pkg, no is_installed');
};

#### 2. sample -> hash #########################################################

subtest 'RTX 3090 line decodes to the documented hash' => sub {
  my ( $result ) = sysfs_detect($DEV{rtx3090});
  is_deeply($result->{nvidia}[0], {
    name                => 'NVIDIA GPU [10de:2204]',
    vendor              => 'nvidia',
    pci_class           => '0300',
    compute             => 1,
    device_id           => '2204',
    subsystem_vendor_id => '1043',
    subsystem_id        => '87b5',
    vgpu                => 0
  }, 'the whole hash, as documented');

  my ( $upper ) = sysfs_detect($DEV{rtx3090_upper});
  is_deeply($upper->{nvidia}[0], $result->{nvidia}[0],
    'uppercase 0X.../0x...-style input (class, vendor, subsystem IDs) decodes identically -- lowercase, no 0x');
};

#### 3. compute #################################################################

subtest 'compute: generation row / PCI class decide as for lspci; undecided has no name to fall back on' => sub {
  my $KEPLER_WARN = qr/is Kepler or older silicon.*skipped, no driver installed/;
  my ( $kepler, $krec ) = sysfs_detect($DEV{kepler_k80});
  is($kepler->{nvidia}[0]{compute}, 0, 'Kepler K80 => compute 0');
  ok((grep { $_->[1] =~ $KEPLER_WARN } @{$krec->{logs}}), '... with the Kepler warning');

  my ( $r302 ) = sysfs_detect($DEV{unreadable_0302});
  is($r302->{nvidia}[0]{compute}, 1, 'unreadable device ID at class 0302 => compute 1 (class decides)');
  is($r302->{nvidia}[0]{device_id}, undef, '... device_id undef');

  my ( $r300, $urec ) = sysfs_detect($DEV{unreadable_0300});
  is($r300->{nvidia}[0]{compute}, undef, 'unreadable device ID at class 0300 => compute undef (undecided, no name to judge)');
  ok((grep { $_->[1] =~ /no generation row for its device ID and no name in sysfs to judge it by/ } @{$urec->{logs}}),
    '... with the "undecided" warning');

  my ( $unk300 ) = sysfs_detect($DEV{unknown_3a00_300});
  is($unk300->{nvidia}[0]{compute}, undef, 'known-but-uncovered ID 3a00 at class 0300 => undef too');

  my ( $unk302 ) = sysfs_detect($DEV{unknown_3a00_302});
  is($unk302->{nvidia}[0]{compute}, 1, '... same ID at class 0302 => compute 1 (class decides first)');

  my @vals;
  {
    no warnings 'redefine';
    local *Rex::Logger::info = sub { };
    @vals = Rex::GPU::Detect::Sysfs->_is_nvidia_compute('0300', 'NVIDIA GPU [10de:3a00]', '3a00');
  }
  is(scalar @vals, 1, '_is_nvidia_compute on Sysfs returns exactly one value, even in list context');
  is($vals[0], undef, '... that value is undef here');
};

subtest 'gpu_setup(detect => Sysfs): compute-only grep skips undef/0, keeps only compute 1' => sub {
  my $mixed = join("\n", $DEV{kepler_k80}, $DEV{rtx3090}, $DEV{unknown_3a00_300});
  my @install_calls;
  my $rec;
  {
    no warnings 'redefine';
    local *Rex::GPU::_check_connection                 = sub { };
    local *Rex::GPU::NVIDIA::install_driver            = sub { push @install_calls, { @_ } };
    local *Rex::GPU::NVIDIA::install_container_toolkit = sub { };
    local *Rex::GPU::NVIDIA::generate_cdi_specs        = sub { };
    local *Rex::GPU::NVIDIA::configure_containerd      = sub { };
    local *Rex::GPU::NVIDIA::verify_nvidia             = sub { };
    $rec = record_host(host => sysfs_host($mixed),
      code => sub {
        Rex::GPU::gpu_setup(detect => 'Rex::GPU::Detect::Sysfs', containerd_config => 'none');
      });
  }
  is($rec->{error}, undef, 'gpu_setup lives');
  is(scalar @install_calls, 1, 'install_driver called once');
  is_deeply([ map { $_->{device_id} } @{ $install_calls[0]{gpus} } ], [ '2204' ],
    '... with only the compute-1 GPU (Kepler=0 and 3a00=undef both dropped)');

  my $none = join("\n", $DEV{kepler_k80}, $DEV{unknown_3a00_300});
  @install_calls = ();
  {
    no warnings 'redefine';
    local *Rex::GPU::_check_connection = sub { };
    $rec = record_host(host => sysfs_host($none),
      code => sub {
        Rex::GPU::gpu_setup(detect => 'Rex::GPU::Detect::Sysfs', containerd_config => 'none');
      });
  }
  is($rec->{error}, undef, 'gpu_setup lives on an all-0/undef host');
  is(scalar @install_calls, 0, '... and install_driver is never called');
};

#### 4. vGPU #####################################################################

subtest 'vGPU: subsystem IDs come straight from sysfs, same table as lspci' => sub {
  my ( $a10 ) = sysfs_detect($DEV{vgpu_a10});
  is($a10->{nvidia}[0]{vgpu}, 1, 'A10 2236:10de:14b9 => vgpu 1');
  is($a10->{nvidia}[0]{vgpu_type}, 'NVIDIA A10-2Q', '... vgpu_type NVIDIA A10-2Q');

  my ( $not ) = sysfs_detect($DEV{vgpu_a10_not});
  is($not->{nvidia}[0]{vgpu}, 0, 'same device, subsystem 1234 => vgpu 0');
  ok(!exists $not->{nvidia}[0]{vgpu_type}, '... no vgpu_type key');
};

#### 5. NVSwitch #################################################################

subtest 'NVSwitch: known device ID only, no name to fall back on; [] with no NVIDIA GPU' => sub {
  my ( $r ) = sysfs_detect(join("\n", $DEV{rtx3090}, $DEV{nvswitch_known}));
  is_deeply($r->{nvswitch}, [ {
    name => 'NVIDIA NVSwitch [10de:22a3]', vendor => 'nvidia', pci_class => '0680', device_id => '22a3'
  } ], 'one recognised NVSwitch');

  my ( $skip, $srec ) = sysfs_detect(join("\n", $DEV{rtx3090}, $DEV{nvswitch_unknown}));
  is_deeply($skip->{nvswitch}, [], 'unknown NVIDIA bridge device ID => not an NVSwitch');
  ok((grep { $_->[1] =~ /NVIDIA bridge device not known as an NVSwitch.*10de:0369/ } @{$srec->{logs}}),
    '... logged as skipped');

  my ( $nogpu ) = sysfs_detect($DEV{nvswitch_known});
  is_deeply($nogpu->{nvswitch}, [], 'a known NVSwitch with no NVIDIA GPU on the host => still []');
};

#### 6. virtual displays #########################################################

subtest 'virtual displays: skipped per device, never hiding a real card' => sub {
  my ( $mixed, $mrec ) = sysfs_detect(join("\n", $DEV{virtio}, $DEV{rtx3090}));
  is(scalar @{$mixed->{nvidia}}, 1, 'virtio + real NVIDIA card => the card is still reported');
  is($mixed->{nvidia}[0]{device_id}, '2204', '... the real one');
  ok((grep { $_->[1] =~ /\[skip\] virtual display: 1af4:1050/ } @{$mrec->{logs}}),
    '... virtio logged as skipped');

  my ( $only, $orec ) = sysfs_detect($DEV{virtio});
  is_deeply($only->{nvidia}, [], 'virtio only => no nvidia');
  is_deeply($only->{amd}, [], '... no amd');
  ok((grep { $_->[1] =~ /Virtual GPU detected.*skipping/ } @{$orec->{logs}}),
    '... "virtual only" logged');
};

#### 7. other devices #############################################################

subtest 'other devices: domains, AMD, class 0380 and ASPEED ignored (today\'s behaviour)' => sub {
  my ( $r ) = sysfs_detect(join("\n", $DEV{domain2}, $DEV{domain1}, $DEV{rtx3090}));
  is_deeply([ map { $_->{device_id} } @{$r->{nvidia}} ], [ '2204', '2205', '2206' ],
    '0000: sorts first, then 0001:, then 10000: (string order on the PCI slot)');

  my ( $amd ) = sysfs_detect($DEV{amd});
  is_deeply($amd->{amd}[0], {
    name => 'AMD GPU [1002:744c]', vendor => 'amd', pci_class => '0300', compute => 0
  }, 'AMD device decodes with compute 0');

  # class 0380 is not a display class this code recognises at all (0300/0302
  # only) -- an NVIDIA-vendor device there is dropped just like anything
  # else outside those two classes. Not a judgement on whether it should be
  # (card k75); pinning today's behaviour only.
  my ( $c0380 ) = sysfs_detect($DEV{class_0380});
  is_deeply($c0380->{nvidia}, [], 'class 0380 NVIDIA-vendor device => ignored, not reported');

  my ( $aspeed ) = sysfs_detect($DEV{aspeed});
  is_deeply($aspeed->{nvidia}, [], 'ASPEED [1a03] at class 0300 => no nvidia');
  is_deeply($aspeed->{amd}, [], '... no amd (neither NVIDIA, AMD nor a virtual vendor)');
};

#### 8. dies ######################################################################

subtest 'dies before anything changes -- never "no GPU found"' => sub {
  my ( undef, $rec3 ) = sysfs_detect('irrelevant', 3);
  like($rec3->{error}, qr{could not read /sys/bus/pci/devices}, 'exit 3 => croak naming the path');
  like($rec3->{error}, qr/exit 3/, '... and the exit code');

  my ( undef, $short ) = sysfs_detect('0000:0f:00.0 0x030000 0x10de 0x2204 0x1043');
  like($short->{error}, qr/unexpected line from \/sys\/bus\/pci\/devices/, 'fewer than six fields => croak');

  my ( undef, $nic ) = sysfs_detect('0000:10:00.0 0x020000 - 0x1234 0x0000 0x0000');
  like($nic->{error}, qr/unreadable class or vendor/, 'unreadable vendor on a plain NIC (class 0200) => croak too');
  like($nic->{error}, qr/0000:10:00\.0/, '... naming the slot');

  my ( undef, $badclass ) = sysfs_detect('0000:11:00.0 0x0300 0x10de 0x2204 0x0000 0x0000');
  like($badclass->{error}, qr/unreadable class or vendor/, 'malformed class (wrong length) => croak');

  for my $die_rec ($rec3, $short, $nic, $badclass) {
    unlike($die_rec->{error}, qr/no GPU found/i, '... never says "no GPU found"');
  }

  my ( $empty, $erec ) = sysfs_detect('');
  is($erec->{error}, undef, 'readable, empty /sys/bus/pci/devices lives');
  is_deeply($empty, { nvidia => [], amd => [], nvswitch => [] }, '... empty arrays');
  ok((grep { $_->[1] =~ /no PCI device listed under \/sys\/bus\/pci\/devices/ } @{$erec->{logs}}),
    '... and an info log, not a die');
};

#### 9. selection: every path runs the sysfs command, never lspci ###############

subtest 'every selection path runs the sysfs command and never lspci' => sub {
  # direct
  my $rec = record_host(host => sysfs_host($DEV{rtx3090}),
    code => sub { Rex::GPU::Detect::Sysfs->detect });
  is($rec->{error}, undef, 'Rex::GPU::Detect::Sysfs->detect: lives');
  ok((grep { /cd \/sys\/bus\/pci\/devices/ } @{$rec->{lines}}), '... ran the sysfs read');
  ok(!(grep { /lspci/ } @{$rec->{lines}}), '... never lspci');

  # gpu_detect(detect => ...)
  $rec = record_host(host => sysfs_host($DEV{rtx3090}),
    code => sub { Rex::GPU::gpu_detect(detect => 'Rex::GPU::Detect::Sysfs') });
  is($rec->{error}, undef, "gpu_detect(detect => 'Rex::GPU::Detect::Sysfs'): lives");
  ok((grep { /cd \/sys\/bus\/pci\/devices/ } @{$rec->{lines}}), '... ran the sysfs read');
  ok(!(grep { /lspci/ } @{$rec->{lines}}), '... never lspci');

  # gpu_setup(detect => ...), Kepler-only so install_driver is never reached
  {
    no warnings 'redefine';
    local *Rex::GPU::_check_connection = sub { };
    $rec = record_host(host => sysfs_host($DEV{kepler_k80}),
      code => sub { Rex::GPU::gpu_setup(detect => 'Rex::GPU::Detect::Sysfs', containerd_config => 'none') });
  }
  is($rec->{error}, undef, "gpu_setup(detect => 'Rex::GPU::Detect::Sysfs'): lives");
  ok((grep { /cd \/sys\/bus\/pci\/devices/ } @{$rec->{lines}}), '... ran the sysfs read');
  ok(!(grep { /lspci/ } @{$rec->{lines}}), '... never lspci');

  # set gpu_detect_class + bare detect()
  with_config(gpu_detect_class => 'Rex::GPU::Detect::Sysfs', sub {
    $rec = record_host(host => sysfs_host($DEV{rtx3090}),
      code => sub { Rex::GPU::Detect::detect() });
  });
  is($rec->{error}, undef, 'set gpu_detect_class + bare detect(): lives');
  ok((grep { /cd \/sys\/bus\/pci\/devices/ } @{$rec->{lines}}), '... ran the sysfs read');
  ok(!(grep { /lspci/ } @{$rec->{lines}}), '... never lspci');

  # Rex::GPU::Detect::Sysfs::detect() -- fully-qualified function call
  $rec = record_host(host => sysfs_host($DEV{rtx3090}),
    code => sub { Rex::GPU::Detect::Sysfs::detect() });
  is($rec->{error}, undef, 'Rex::GPU::Detect::Sysfs::detect(): lives');
  ok((grep { /cd \/sys\/bus\/pci\/devices/ } @{$rec->{lines}}), '... ran the sysfs read');
  ok(!(grep { /lspci/ } @{$rec->{lines}}), '... never lspci');
};

#### 10. the shared lists, and one override point for both paths ###############

subtest 'nvswitch_device_ids / virtual_display_vendor_ids: documented lists, one override point' => sub {
  is_deeply([ Rex::GPU::Detect->nvswitch_device_ids ], [ qw( 1ac2 1af1 22a3 ) ], 'the documented NVSwitch IDs');
  is_deeply([ Rex::GPU::Detect->virtual_display_vendor_ids ], [ qw( 1af4 1b36 15ad 80ee ) ],
    'the documented virtual display vendor IDs');
  is_deeply([ Rex::GPU::Detect::Sysfs->nvswitch_device_ids ], [ Rex::GPU::Detect->nvswitch_device_ids ],
    'Sysfs inherits the same list (no override of its own)');
  is_deeply([ Rex::GPU::Detect::Sysfs->virtual_display_vendor_ids ], [ Rex::GPU::Detect->virtual_display_vendor_ids ],
    '... likewise for virtual_display_vendor_ids');

  {
    package Test::DetectSysfs::LspciIDs;
    use parent -norequire, 'Rex::GPU::Detect';
    sub nvswitch_device_ids { ( 'dead' ) }
  }
  {
    package Test::DetectSysfs::SysfsIDs;
    use parent -norequire, 'Rex::GPU::Detect::Sysfs';
    sub nvswitch_device_ids { ( 'dead' ) }
  }

  no warnings 'redefine';
  local *Rex::Logger::info = sub { };
  my $switch = Test::DetectSysfs::LspciIDs->_parse_nvswitch_line(
    '05:00.0 Bridge [0680]: NVIDIA Corporation Site Special Bridge [10de:dead] (rev a1)');
  ok($switch, 'lspci path: a subclass overriding nvswitch_device_ids recognises "dead" as an NVSwitch');
  is($switch->{device_id}, 'dead', '... device_id dead');
  ok(!Rex::GPU::Detect->_parse_nvswitch_line(
    '05:00.0 Bridge [0680]: NVIDIA Corporation Site Special Bridge [10de:dead] (rev a1)'),
    '... the base class does not (this is the override, not a coincidence)');

  my ( $r ) = sysfs_detect(join("\n", $DEV{rtx3090}, '0000:0f:00.0 0x068000 0x10de 0xdead 0x0000 0x0000'));
  is_deeply($r->{nvswitch}, [], 'sysfs path, base class: "dead" is not a known NVSwitch ID');
  my $result;
  my $rec = record_host(host => sysfs_host(join("\n", $DEV{rtx3090}, '0000:0f:00.0 0x068000 0x10de 0xdead 0x0000 0x0000')),
    code => sub { $result = Test::DetectSysfs::SysfsIDs->detect });
  is($rec->{error}, undef, 'sysfs path, overridden subclass: lives');
  is_deeply($result->{nvswitch}, [ {
    name => 'NVIDIA NVSwitch [10de:dead]', vendor => 'nvidia', pci_class => '0680', device_id => 'dead'
  } ], '... the SAME override point recognises "dead" for the sysfs path too');
};

#### 11. the OCP SYNOPSIS use ###################################################

subtest "Sysfs.pm's SYNOPSIS filter, and the kept hashes pass Setup->new" => sub {
  my $mixed = join("\n", $DEV{kepler_k80}, $DEV{rtx3090}, $DEV{unknown_3a00_300});
  my ( $gpus ) = sysfs_detect($mixed);
  my @kept = grep { !defined $_->{compute} || $_->{compute} } @{ $gpus->{nvidia} };
  is_deeply([ sort map { $_->{device_id} } @kept ], [ '2204', '3a00' ],
    'the filter keeps compute 1 and undef, drops compute 0 (Kepler)');

  my $setup = eval { Rex::GPU::NVIDIA::Setup->new(gpus => \@kept) };
  ok(!$@, 'Rex::GPU::NVIDIA::Setup->new(gpus => ...) with the kept hashes does not die: '.($@ // ''));
  is_deeply($setup->gpus, \@kept, '... and keeps exactly those GPUs');
};

done_testing;
