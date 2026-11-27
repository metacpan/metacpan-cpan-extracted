#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# AMD enrichment of Rex::GPU::Detect and Rex::GPU::Detect::Sysfs (karr k1),
# against a scripted host: the lspci / sysfs read, then the one AMD state read
# (Rex::GPU::AMD->state_script).
#
# CLAIMS:
#   * every AMD element, on both paths, has exactly the keys vendor name
#     pci_class slot device_id gfx_target compute integrated -- all present,
#     also where the value is undef;
#   * a synapse-like host (0000:95:00.0, 1002:1586, class 0380, KFD
#     110501) is gfx1151, compute 1, integrated 1; lspci's bare placeholder
#     name "Device" becomes "AMD GPU [1002:1586]", the name the sysfs path
#     builds, and both paths then return the SAME hash;
#   * AMD is found at classes 0300, 0380 and 1200 (lspci: the new grep; sysfs:
#     the class filter); an NVIDIA device at 0380 or 1200 is not listed, and
#     the host without an AMD GPU runs no state read;
#   * the KFD topology's gfx_target_version wins over the device table
#     (110501 -> gfx1151, 90402 -> gfx942, 100306 -> gfx1036 => compute 0), a
#     disagreement logs a warning naming both, and each GPU of a multi-GPU
#     host gets the node at its own PCI address;
#   * no row and no KFD node -> gfx_target, compute and integrated undef
#     ("unknown", never 0) and an [undecided] status line; an unreadable
#     state read leaves the table's values and detect() lives;
#   * the read-only state script is the only command added: lspci host =
#     probe, display grep, state; sysfs host = the sysfs read, state.
#
# NOT covered -- scripted host, hand-written output:
#   * real lspci / sysfs / KFD output of a real AMD host (synapse's lines are
#     imitations of what was read there on 2026-10-31, see Test::RexGPU::AMD;
#     the Instinct lines are invented in the same shape);
#   * what the state script does in a real shell -- it is a shell string,
#     recorded and fed canned output here, never run (a wrong test(1) or
#     read in it is invisible to this file);
#   * that the verdicts are true (t/13-amd-hardware.t only reads rows back).
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host host_profile );
use Test::RexGPU::AMD qw( amd_state );
use Rex::GPU::Detect;
use Rex::GPU::Detect::Sysfs;
use Rex::GPU::AMD;

my $STATE_CMD = Rex::GPU::AMD->state_script;
my $LSPCI_GREP = qr{^lspci -nn 2>&1 \| grep -E '\\\[03\(00\|02\)\\\]\|\\\[\(0380\|1200\)\\\]\.\*\\\[1002:'$};
my @GPU_KEYS = sort qw( vendor name pci_class slot device_id gfx_target compute integrated );

my %LSPCI = (
  # synapse: Ubuntu 24.04's pci.ids does not know 1002:1586, lspci prints the
  # placeholder "Device" (live read, 2026-10-31)
  synapse  => '95:00.0 Display controller [0380]: Advanced Micro Devices, Inc. [AMD/ATI] Device [1002:1586] (rev da)',
  # with a pci.ids that does (name hand-written)
  synapse_named => '95:00.0 Display controller [0380]: Advanced Micro Devices, Inc. [AMD/ATI] Strix Halo [Radeon Graphics / Radeon 8050S / 8060S Graphics] [1002:1586] (rev da)',
  mi300x   => 'c1:00.0 Processing accelerators [1200]: Advanced Micro Devices, Inc. [AMD/ATI] Aqua Vanjaram [Instinct MI300X] [1002:74a1]',
  navi31   => '0a:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 31 [Radeon RX 7900 XTX] [1002:744c] (rev c8)',
  navi48   => '0b:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 48 [Radeon RX 9070 XT] [1002:7550] (rev c1)',
  unknown  => '03:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Device [1002:1902] (rev 01)',
  nv_1200  => '02:00.0 Processing accelerators [1200]: NVIDIA Corporation Device [10de:9999]',
  nv_0380  => '0d:00.0 Display controller [0380]: NVIDIA Corporation GA102 [GeForce RTX 3090] [10de:2204] (rev a1)',
);
my %SYSFS = (
  synapse => '0000:95:00.0 0x038000 0x1002 0x1586 0x1002 0x0000',
  mi300x  => '0000:c1:00.0 0x120000 0x1002 0x74a1 0x1002 0x74a1',
  navi31  => '0000:0a:00.0 0x030000 0x1002 0x744c 0x1002 0x0000',
  navi48  => '0000:0b:00.0 0x030000 0x1002 0x7550 0x1002 0x0000',
  unknown => '0000:03:00.0 0x030000 0x1002 0x1902 0x1002 0x0000',
  nv_1200 => '0000:02:00.0 0x120000 0x10de 0x9999 0x10de 0x0000',
  nv_0380 => '0000:0d:00.0 0x038000 0x10de 0x2204 0x1043 0x8782',
  bridge  => '0000:00:00.0 0x060000 0x1022 0x14e8 0x1022 0x14e8',
);

# KFD states: the GPU's node carries gfx_target_version (a CPU node 0 first,
# as on an APU)
my %STATE = (
  synapse => amd_state(
    nodes => [ { id => 0, gfx => 0 } ],
    gpus  => [ { slot => '0000:95:00.0', class => '0380', device_id => '1586', kfd => 110501,
                 vram => 137438953472, gtt => 33535848448 } ]),
  mi300x  => amd_state(gpus => [ { slot => '0000:c1:00.0', class => '1200', device_id => '74a1', kfd => 90402 } ]),
  # the driver says gfx1036 for a device the table says gfx1201
  navi48_as_1036 => amd_state(gpus => [ { slot => '0000:0b:00.0', class => '0300', device_id => '7550', kfd => 100306 } ]),
  # an ID without a row that KFD knows
  unknown_kfd => amd_state(gpus => [ { slot => '0000:03:00.0', class => '0300', device_id => '1902', kfd => 110501 } ]),
  # no driver yet: nothing in the topology
  nodriver => amd_state(amdgpu => 0, kfd => 0, gpus => [
    { slot => '0000:c1:00.0', class => '1200', device_id => '74a1', driver => undef, render => undef } ]),
  two => amd_state(gpus => [
    { slot => '0000:0a:00.0', class => '0300', device_id => '744c', kfd => 110000, render => 128 },
    { slot => '0000:c1:00.0', class => '1200', device_id => '74a1', kfd => 90402, render => 129 } ]),
);

sub lspci_detect {
  my ( $lspci, $state, %opt ) = @_;
  my $result;
  my @responses = (
    [ $LSPCI_GREP => $lspci, 0 ],
    ( defined $state ? [ $STATE_CMD => $state, 0 ] : () ),
  );
  my $rec = record_host(
    host => host_profile('debian-12', responses => \@responses),
    code => sub { $result = Rex::GPU::Detect::detect() },
  );
  return ( $result, $rec );
}

sub sysfs_detect {
  my ( $lines, $state ) = @_;
  my $result;
  my @responses = (
    [ qr{^cd /sys/bus/pci/devices} => $lines, 0 ],
    ( defined $state ? [ $STATE_CMD => $state, 0 ] : () ),
  );
  my $rec = record_host(
    host => host_profile('debian-12', responses => \@responses),
    code => sub { $result = Rex::GPU::Detect::Sysfs->detect },
  );
  return ( $result, $rec );
}

sub logs_like { my ( $rec, $level, $re ) = @_; return scalar grep { $_->[0] eq $level && $_->[1] =~ $re } @{ $rec->{logs} } }

#### the synapse host, both paths

subtest 'synapse (lspci): gfx1151, compute 1, integrated 1; "Device" becomes a name' => sub {
  my ( $r, $rec ) = lspci_detect($LSPCI{synapse}, $STATE{synapse});
  is($rec->{error}, undef, 'lives');
  is(scalar @{ $r->{amd} }, 1, 'one AMD GPU');
  is_deeply($r->{amd}[0], {
    vendor => 'amd', name => 'AMD GPU [1002:1586]', pci_class => '0380',
    slot => '0000:95:00.0', device_id => '1586', gfx_target => 'gfx1151',
    compute => 1, integrated => 1,
  }, 'the whole element (slot normalised to its domain form)');
  is_deeply($rec->{lines}, [
    'run: command -v lspci >/dev/null 2>&1',
    'run: lspci -nn 2>&1 | grep -E \'\[03(00|02)\]|\[(0380|1200)\].*\[1002:\'',
    'run: '.$STATE_CMD,
  ], 'commands: the lspci probe, the display grep, then the one state read');
  ok(logs_like($rec, 'info', qr/\[ok\] AMD: AMD GPU \[1002:1586\] \(PCI class 0380, 0000:95:00\.0, gfx1151, integrated\)/),
    'status line: [ok], slot, gfx target, integrated');
};

subtest 'synapse (sysfs) returns the same element as lspci' => sub {
  my ( $r, $rec ) = sysfs_detect($SYSFS{synapse}, $STATE{synapse});
  is($rec->{error}, undef, 'lives');
  is_deeply($r->{amd}, [ {
    vendor => 'amd', name => 'AMD GPU [1002:1586]', pci_class => '0380',
    slot => '0000:95:00.0', device_id => '1586', gfx_target => 'gfx1151',
    compute => 1, integrated => 1,
  } ], 'gfx1151 / compute 1 / integrated 1');
  is(scalar @{ $rec->{lines} }, 2, 'two commands: the sysfs read and the state read');
  is($rec->{lines}[1], 'run: '.$STATE_CMD, '... the second is the state script');

  my ( $l ) = lspci_detect($LSPCI{synapse}, $STATE{synapse});
  is_deeply($r->{amd}, $l->{amd}, 'sysfs and lspci(placeholder name) agree on the whole hash');
};

subtest 'a named lspci GPU keeps lspci\'s name' => sub {
  my ( $r ) = lspci_detect($LSPCI{synapse_named}, $STATE{synapse});
  is($r->{amd}[0]{name}, 'Strix Halo [Radeon Graphics / Radeon 8050S / 8060S Graphics]', 'pci.ids name kept');
  is($r->{amd}[0]{gfx_target}, 'gfx1151', '... same verdict');
};

#### classes

subtest 'classes 0300, 0380 and 1200 (both paths)' => sub {
  my @case = (
    [ 'mi300x', '1200', 'gfx942',  1, 0 ],
    [ 'navi31', '0300', 'gfx1100', 1, 0 ],
    [ 'synapse', '0380', 'gfx1151', 1, 1 ],
  );
  for my $c (@case) {
    my ( $key, $class, $gfx, $compute, $integrated ) = @$c;
    my $state = $key eq 'navi31' ? amd_state(gpus => [ { slot => '0000:0a:00.0', class => '0300', device_id => '744c', kfd => 110000 } ])
                                 : $STATE{$key};
    for my $path ([ lspci => sub { lspci_detect($LSPCI{$key}, $state) } ],
                  [ sysfs => sub { sysfs_detect($SYSFS{$key}, $state) } ]) {
      my ( $r ) = $path->[1]->();
      is(scalar @{ $r->{amd} }, 1, "$key via $path->[0]: listed");
      is_deeply([ @{ $r->{amd}[0] }{qw( pci_class gfx_target compute integrated )} ],
        [ $class, $gfx, $compute, $integrated ], "... class $class, $gfx, compute $compute, integrated $integrated");
      is_deeply([ sort keys %{ $r->{amd}[0] } ], \@GPU_KEYS, '... exactly the documented keys');
    }
  }
};

subtest 'NVIDIA at 0380 / 1200 is not listed; a host without AMD runs no state read' => sub {
  for my $pair ([ lspci => sub { lspci_detect(join("\n", @LSPCI{qw( nv_1200 nv_0380 )}), $STATE{synapse}) } ],
                [ sysfs => sub { sysfs_detect(join("\n", @SYSFS{qw( bridge nv_1200 nv_0380 )}), $STATE{synapse}) } ]) {
    my ( $r, $rec ) = $pair->[1]->();
    is_deeply([ scalar @{ $r->{nvidia} }, scalar @{ $r->{amd} } ], [ 0, 0 ], "$pair->[0]: neither listed");
    ok(!( grep { $_ eq 'run: '.$STATE_CMD } @{ $rec->{lines} }), '... and no AMD state read');
  }
  my ( $r ) = lspci_detect(join("\n", $LSPCI{nv_0380}, $LSPCI{synapse}), $STATE{synapse});
  is(scalar @{ $r->{amd} }, 1, 'mixed: the AMD one at 0380 is listed');
  is(scalar @{ $r->{nvidia} }, 0, '... the NVIDIA one is not');
};

#### KFD wins over the table

subtest 'KFD decode: 90402 -> gfx942, 110501 -> gfx1151, 100306 -> gfx1036 (compute 0)' => sub {
  my ( $r ) = lspci_detect($LSPCI{mi300x}, $STATE{mi300x});
  is($r->{amd}[0]{gfx_target}, 'gfx942', '90402 -> gfx942');

  my ( $rec );
  ( $r, $rec ) = lspci_detect($LSPCI{navi48}, $STATE{navi48_as_1036});
  is_deeply([ @{ $r->{amd}[0] }{qw( device_id gfx_target compute integrated )} ], [ '7550', 'gfx1036', 0, 1 ],
    '100306: the driver says gfx1036 for 1002:7550 (table: gfx1201) -> the driver wins, compute 0, integrated 1');
  is(logs_like($rec, 'warn', qr/KFD\) reports gfx1036, the device table says gfx1201 -- using gfx1036/), 1,
    '... a warning names both targets');
  ok(logs_like($rec, 'info', qr/\[skip\] AMD: Navi 48 \[Radeon RX 9070 XT\] \(PCI class 0300, 0000:0b:00\.0, gfx1036, integrated\)/), '... status [skip]');

  ( $r ) = sysfs_detect($SYSFS{navi48}, $STATE{navi48_as_1036});
  is($r->{amd}[0]{gfx_target}, 'gfx1036', 'the same on the sysfs path');
  is($r->{amd}[0]{compute}, 0, '... compute 0');

  ( $r ) = lspci_detect($LSPCI{unknown}, $STATE{unknown_kfd});
  is_deeply([ @{ $r->{amd}[0] }{qw( gfx_target compute integrated )} ], [ 'gfx1151', 1, 1 ],
    'an ID with no row, KFD 110501: gfx1151 from the driver, compute 1');
};

subtest 'two AMD GPUs: each gets the KFD node at its own PCI address' => sub {
  my ( $r ) = lspci_detect(join("\n", $LSPCI{navi31}, $LSPCI{mi300x}), $STATE{two});
  is_deeply([ map { [ @{$_}{qw( slot gfx_target )} ] } @{ $r->{amd} } ],
    [ [ '0000:0a:00.0', 'gfx1100' ], [ '0000:c1:00.0', 'gfx942' ] ], 'gfx1100 and gfx942');
  is(scalar(grep { $_->{compute} } @{ $r->{amd} }), 2, 'both compute');
};

#### unknown stays unknown

subtest 'no row and no KFD node: undef, never 0' => sub {
  my ( $r, $rec ) = lspci_detect($LSPCI{unknown}, amd_state(gpus => [ { slot => '0000:03:00.0', class => '0300', device_id => '1902' } ]));
  is_deeply($r->{amd}[0], {
    vendor => 'amd', name => 'AMD GPU [1002:1902]', pci_class => '0300',
    slot => '0000:03:00.0', device_id => '1902', gfx_target => undef,
    compute => undef, integrated => undef,
  }, 'every verdict undef, every key present');
  ok(logs_like($rec, 'info', qr/\[undecided\] AMD: AMD GPU \[1002:1902\] .*gfx target unknown\) -- no hardware row, compute left undecided/),
    '... an [undecided] status line');

  ( $r ) = sysfs_detect($SYSFS{unknown}, undef);
  is($r->{amd}[0]{compute}, undef, 'sysfs: compute undef too');
  ok(exists $r->{amd}[0]{integrated} && !defined $r->{amd}[0]{integrated}, '... integrated present and undef');
};

subtest 'a driver that is not there yet: the table decides' => sub {
  my ( $r ) = lspci_detect($LSPCI{mi300x}, $STATE{nodriver});
  is_deeply([ @{ $r->{amd}[0] }{qw( gfx_target compute integrated )} ], [ 'gfx942', 1, 0 ], 'no KFD node: gfx942 from the table');
};

subtest 'unreadable state read: table values, detect lives' => sub {
  for my $bad ('garbage', '', amd_state(gpus => [ { slot => '0000:c1:00.0', class => '1200', device_id => '74a1', kfd => 90402 } ], end => 0)) {
    my ( $r, $rec ) = lspci_detect($LSPCI{mi300x}, $bad);
    is($rec->{error}, undef, 'lives');
    is($r->{amd}[0]{gfx_target}, 'gfx942', '... table gfx target');
    ok(logs_like($rec, 'info', qr/AMD driver state not readable -- gfx targets from the device table only/),
      '... says the state was not readable');
  }
};

done_testing;
