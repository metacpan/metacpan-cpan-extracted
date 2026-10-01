use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# NVIDIA vGPU guest detection and the install_driver refusal (karr #24).
#
# CLAIMS:
#   * Rex::GPU::NVIDIA::VGPU->type_for knows a pair of NVIDIA's
#     sVgpuUsmTypes[] (20b0:146f => "GRID A100X-1-5C") and not a physical one
#     (B200 2901:1999); subsystem vendor other than 10de, malformed IDs =>
#     undef; a subclass can add a type;
#   * _parse_lspci_vmm reads Slot/Device/SVendor/SDevice per record, and a
#     slot with domain 0000 in one lspci form matches the other form without
#     it;
#   * detect() runs `lspci -vmmnn -d 10de:` only when an NVIDIA GPU was
#     found (goldens t/golden/detect/*vgpu*, *amd-only*), marks each NVIDIA
#     GPU vgpu 0|1 (+ vgpu_type) by slot, and leaves compute alone;
#   * install_driver with a vGPU and no working driver dies after the
#     nvidia-smi probe and before anything else, on every OS -- alone and
#     next to a non-vGPU GPU (message names both); with a working driver it
#     takes the already-installed path like any other GPU;
#   * a GPU without the vgpu key (callers that find GPUs themselves) or with
#     vgpu => 0 gets exactly the commands it got before.
#
# NOT covered -- no vGPU guest runs here, and a green prove is NOT evidence
# that this works on one:
#   * that a real vGPU guest (Azure NVadsA10 v5, AWS G6f, a VMware/KVM vGPU)
#     prints the subsystem ID in `lspci -vmmnn` as the hand-written fixtures
#     do, and that its pair is in NVIDIA's table;
#   * that the GRID guest driver passes already_installed (nvidia-smi -L and
#     libcuda.so.1 in ldconfig -p) and that toolkit/CDI/containerd then work.
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw(
  record_host golden_is host_names host_profile gpu_fixture working_driver
);
use Rex::GPU;
use Rex::GPU::Detect;
use Rex::GPU::NVIDIA;
use Rex::GPU::NVIDIA::VGPU;

my $VGPU = 'Rex::GPU::NVIDIA::VGPU';

#### The table

subtest 'type_for' => sub {
  is($VGPU->type_for('20b0', '146f'), 'GRID A100X-1-5C', '20b0:146f => GRID A100X-1-5C');
  is($VGPU->type_for('20B0', '146F', '10DE'), 'GRID A100X-1-5C', 'any case, vendor 10de');
  is($VGPU->type_for('2236', '14b9', '10de'), 'NVIDIA A10-2Q', 'A10-2Q');
  is($VGPU->type_for('2901', '1999', '10de'), undef, 'physical B200 2901:1999 => undef');
  is($VGPU->type_for('2236', '1482', '10de'), undef, 'physical A10 2236:1482 => undef');
  is($VGPU->type_for('20b0', '146f', '1028'), undef, 'subsystem vendor Dell => undef');
  is($VGPU->type_for('20b0', undef), undef, 'no subsystem ID => undef');
  is($VGPU->type_for(undef, '146f'), undef, 'no device ID => undef');
  is($VGPU->type_for('0x20b0', '146f'), undef, 'malformed device ID => undef');
  is($VGPU->type_for('20b0', "146f\n"), undef, 'malformed subsystem ID => undef');
  my %types = $VGPU->types;
  is(scalar keys %types, 1135, '1135 pairs');
  is($VGPU->source->{entries}, 1135, 'source counts them');
  is($VGPU->source->{tag}, '615.71.09', 'source tag');
  ok(!grep({ !/\A[0-9a-f]{4}:[0-9a-f]{4}\z/ } keys %types), 'every key is dddd:ssss lowercase');
};

{
  package Test::VGPU::Site;
  use parent -norequire, 'Rex::GPU::NVIDIA::VGPU';
  sub types { my ( $self ) = @_; return ( $self->SUPER::types, '2bb5:9999' => 'Site type' ) }
}

is(Test::VGPU::Site->type_for('2bb5', '9999'), 'Site type', 'a subclass adds a type');
is(Test::VGPU::Site->type_for('20b0', '146f'), 'GRID A100X-1-5C', '... and keeps the built-in ones');

#### lspci -vmmnn parsing

my $A10_NN  = '0002:00:00.0 3D controller [0302]: NVIDIA Corporation GA102GL [A10] [10de:2236] (rev a1)';
my $ADA_NN  = '0000:01:00.0 VGA compatible controller [0300]: NVIDIA Corporation AD104GL [RTX 4000 SFF Ada Generation] [10de:27b0] (rev a1)';
my $AMD_NN  = '0a:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 31 [Radeon RX 7900 XTX] [1002:744c] (rev c8)';
my $A10_VMM = join("\n",
  "Slot:\t0002:00:00.0",
  "Class:\t3D controller [0302]",
  "Vendor:\tNVIDIA Corporation [10de]",
  "Device:\tGA102GL [A10] [2236]",
  "SVendor:\tNVIDIA Corporation [10de]",
  "SDevice:\tDevice [14b9]",
  "Rev:\ta1");
# lspci -vmm omits the 0000 domain that lspci -nn prints once any device has
# a non-zero one
my $ADA_VMM = join("\n",
  "Slot:\t01:00.0",
  "Class:\tVGA compatible controller [0300]",
  "Vendor:\tNVIDIA Corporation [10de]",
  "Device:\tAD104GL [RTX 4000 SFF Ada Generation] [27b0]",
  "SVendor:\tNVIDIA Corporation [10de]",
  "SDevice:\tDevice [16fa]",
  "Rev:\ta1",
  "ProgIf:\t00");

subtest '_parse_lspci_vmm' => sub {
  my $r = Rex::GPU::Detect->_parse_lspci_vmm($A10_VMM."\n\n".$ADA_VMM."\n");
  is_deeply($r, {
    '0002:00:00.0' => { device_id => '2236', subsystem_vendor_id => '10de', subsystem_id => '14b9' },
    '01:00.0'      => { device_id => '27b0', subsystem_vendor_id => '10de', subsystem_id => '16fa' }
  }, 'two records by slot');
  is_deeply(Rex::GPU::Detect->_parse_lspci_vmm("Slot:\t05:00.0\nDevice:\tDevice [1db4]"),
    { '05:00.0' => { device_id => '1db4', subsystem_vendor_id => undef, subsystem_id => undef } },
    'no subsystem lines => undef');
  is_deeply(Rex::GPU::Detect->_parse_lspci_vmm(undef), {}, 'no output => {}');
  is_deeply(Rex::GPU::Detect->_parse_lspci_vmm($ADA_NN), {}, 'lspci -nn text => {}');
  is(Rex::GPU::Detect->_pci_slot($ADA_NN), '01:00.0', '-nn slot 0000:01:00.0 => 01:00.0');
  is(Rex::GPU::Detect->_pci_slot($A10_NN), '0002:00:00.0', 'non-zero domain kept');
  is(Rex::GPU::Detect->_pci_slot($AMD_NN), '0a:00.0', 'no domain');
};

#### detect()

my $LSPCI_READ = q{lspci -nn 2>&1 | grep -E '\[03(00|02)\]'};
my $VMM_READ   = 'lspci -vmmnn -d 10de: 2>/dev/null';

sub detect_on {
  my ( $name, $display, $vmm ) = @_;
  my $result;
  my $rec = record_host(
    host => host_profile('debian-12', responses => [
      [ 'command -v lspci >/dev/null 2>&1' => '', 0 ],
      [ $LSPCI_READ => $display, 0 ],
      [ $VMM_READ   => $vmm, 0 ]
    ]),
    code => sub { $result = Rex::GPU::Detect::detect() });
  golden_is($rec, "detect/debian-12--$name");
  return ( $result, $rec );
}

subtest 'vGPU guest (A10-2Q)' => sub {
  my ( $r ) = detect_on('vgpu-a10', $A10_NN, $A10_VMM);
  my $g = $r->{nvidia}[0];
  is($g->{vgpu}, 1, 'vgpu 1');
  is($g->{vgpu_type}, 'NVIDIA A10-2Q', 'vgpu_type');
  is($g->{subsystem_id}, '14b9', 'subsystem_id');
  is($g->{subsystem_vendor_id}, '10de', 'subsystem_vendor_id');
  is($g->{compute}, 1, 'compute unchanged (Ampere, class 0302)');
};

subtest 'mixed: vGPU next to a physical card' => sub {
  my ( $r ) = detect_on('vgpu-a10+ada', "$A10_NN\n$ADA_NN", "$A10_VMM\n\n$ADA_VMM");
  is_deeply([ map { $_->{vgpu} } @{ $r->{nvidia} } ], [ 1, 0 ], 'A10 vGPU, Ada not');
  ok(!exists $r->{nvidia}[1]{vgpu_type}, 'no vgpu_type on the physical card');
  is($r->{nvidia}[1]{subsystem_id}, '16fa', '... but its subsystem_id');
};

subtest 'physical card, and a slot lspci -vmmnn did not list' => sub {
  my ( $r ) = detect_on('ada-physical', $ADA_NN, $ADA_VMM);
  is($r->{nvidia}[0]{vgpu}, 0, 'physical Ada => vgpu 0');
  ( $r ) = detect_on('vgpu-a10--vmm-empty', $A10_NN, '');
  is($r->{nvidia}[0]{vgpu}, 0, 'no -vmm record => vgpu 0 (as before karr #24)');
  is($r->{nvidia}[0]{subsystem_id}, undef, '... subsystem_id undef');
  # a record for the slot but another device: not this GPU
  ( my $other = $A10_VMM ) =~ s/\[2236\]/[2204]/;
  ( $r ) = detect_on('vgpu-a10--vmm-other-device', $A10_NN, $other);
  is($r->{nvidia}[0]{vgpu}, 0, 'slot with another device ID => vgpu 0');
};

# karr #64: a slot that is not a PCI address -- on the -nn line or in a -vmm
# record -- matches nothing. The GPU is still reported, as vgpu 0, even if a
# vGPU subsystem ID sits next to the garbage.
subtest 'unparseable slots are ignored' => sub {
  my $detect = sub {
    my ( $display, $vmm ) = @_;
    my $result;
    my $rec = record_host(
      host => host_profile('debian-12', responses => [
        [ 'command -v lspci >/dev/null 2>&1' => '', 0 ],
        [ $LSPCI_READ => $display, 0 ],
        [ $VMM_READ   => $vmm, 0 ]
      ]),
      code => sub { $result = Rex::GPU::Detect::detect() });
    is($rec->{error}, undef, '... detect lives');
    return ( $result, $rec );
  };

  # the GPU's own -nn slot does not parse; -vmm has a valid vGPU record
  ( my $bad_nn = $A10_NN ) =~ s/\A0002:00:00\.0/zz:00.0/;
  isnt($bad_nn, $A10_NN, "fixture with -nn slot zz:00.0 built");
  my ( $r, $rec ) = $detect->($bad_nn, $A10_VMM);
  is(scalar @{ $r->{nvidia} }, 1, 'GPU with an unparseable -nn slot: still reported');
  is($r->{nvidia}[0]{vgpu}, 0, '... vgpu 0');
  is($r->{nvidia}[0]{subsystem_id}, undef, '... subsystem_id undef');
  ok(!exists $r->{nvidia}[0]{vgpu_type}, '... no vgpu_type');
  is($r->{nvidia}[0]{compute}, 1, '... compute unchanged');
  is($rec->{lines}[-1], "run: $VMM_READ", '... after the one -vmm read');

  # -vmm records whose Slot: is not a PCI address, carrying the A10-2Q IDs
  for my $slot ('garbage', '0002:00:00.0.1', '0002:00:00.8', '') {
    ( my $vmm = $A10_VMM ) =~ s/\ASlot:\t\S+/Slot:\t$slot/;
    isnt($vmm, $A10_VMM, "fixture with Slot: '$slot' built");
    ( $r ) = $detect->($A10_NN, $vmm);
    is($r->{nvidia}[0]{vgpu}, 0, "-vmm Slot: '$slot' => vgpu 0");
    is($r->{nvidia}[0]{subsystem_id}, undef, '... subsystem_id undef');
  }
  is_deeply(Rex::GPU::Detect->_parse_lspci_vmm("Slot:\tgarbage\nDevice:\tGA102GL [A10] [2236]\n"
    ."SVendor:\tNVIDIA Corporation [10de]\nSDevice:\tDevice [14b9]"), {}, '_parse_lspci_vmm drops the record');
};

subtest 'no NVIDIA GPU => no vGPU read' => sub {
  my ( $r, $rec ) = detect_on('amd-only', $AMD_NN, $A10_VMM);
  ok(!grep({ /lspci -vmmnn|lspci -nn -d 10de:/ } @{ $rec->{lines} }), 'no 10de lspci at all');
};

#### install_driver

sub detect_quiet {
  my ( $display, $vmm ) = @_;
  my $result;
  record_host(
    host => host_profile('debian-12', responses => [
      [ 'command -v lspci >/dev/null 2>&1' => '', 0 ],
      [ $LSPCI_READ => $display, 0 ],
      [ $VMM_READ   => $vmm, 0 ]
    ]),
    code => sub { $result = Rex::GPU::Detect::detect() });
  return $result;
}

# What gpu_setup would pass: the GPUs as detect() returns them.
my ( $A10, $ADA ) = @{ detect_quiet("$A10_NN\n$ADA_NN", "$A10_VMM\n\n$ADA_VMM")->{nvidia} };

sub driver_on {
  my ( $os, $gpus, @responses ) = @_;
  return record_host(host => host_profile($os, responses => [ @responses ]),
    code => sub { Rex::GPU::NVIDIA::install_driver(gpus => $gpus) });
}

my $VGPU_DIE = qr/\ANVIDIA vGPU guest \(type NVIDIA A10-2Q, 10de:2236 sub 14b9\)/;

for my $os (host_names()) {
  my $rec = driver_on($os, [ $A10 ]);
  like($rec->{error}, qr/$VGPU_DIE: install the licensed NVIDIA vGPU guest driver, then run again\. No driver package was installed and no package source was added\z/,
    "$os + vGPU, no driver: dies");
  is_deeply($rec->{lines}, [ 'run: nvidia-smi -L 2>&1' ], '... after the nvidia-smi probe only');

  $rec = driver_on($os, [ $A10, $ADA ]);
  like($rec->{error}, qr/$VGPU_DIE next to NVIDIA GPU 'AD104GL \[RTX 4000 SFF Ada Generation\]' \(10de:27b0, not a vGPU\): one NVIDIA kernel module/,
    "$os + vGPU and a physical GPU, no driver: dies naming both");
  is_deeply($rec->{lines}, [ 'run: nvidia-smi -L 2>&1' ], '... after the nvidia-smi probe only');

  $rec = driver_on($os, [ $A10 ], working_driver());
  is($rec->{error}, undef, "$os + vGPU, working driver: goes on");
  is_deeply($rec->{lines}, driver_on($os, [ gpu_fixture('ada') ], working_driver())->{lines},
    '... the already-installed path any GPU gets');

  # vgpu => 0 and no vgpu key: what the GPU got before karr #24
  my %plain = %$ADA;
  delete @plain{qw( vgpu vgpu_type subsystem_id subsystem_vendor_id )};
  $rec = driver_on($os, [ $ADA ]);
  my $before = driver_on($os, [ \%plain ]);
  is($rec->{error}, $before->{error}, "$os + physical Ada, vgpu 0: dies/lives as without the key");
  is_deeply($rec->{lines}, $before->{lines}, '... same commands');
}

# One OS as goldens, so the transcripts are on file.
golden_is(driver_on('ubuntu-24.04', [ $A10 ]), 'driver/ubuntu-24.04--vgpu-a10');
golden_is(driver_on('ubuntu-24.04', [ $A10, $ADA ]), 'driver/ubuntu-24.04--vgpu-a10+ada');
golden_is(driver_on('ubuntu-24.04', [ $A10 ], working_driver()),
  'driver/ubuntu-24.04--vgpu-a10--installed');
golden_is(driver_on('ubuntu-24.04', [ $A10, $ADA ], working_driver()),
  'driver/ubuntu-24.04--vgpu-a10+ada--installed');

# An OS without a Setup class: the vGPU message, not "Unsupported OS".
{
  my $rec = record_host(host => host_profile('debian-12', os => 'Gentoo'),
    code => sub { Rex::GPU::NVIDIA::install_driver(gpus => [ $A10 ]) });
  like($rec->{error}, $VGPU_DIE, 'OS without a setup class: the vGPU refusal');
  is_deeply($rec->{lines}, [ 'run: nvidia-smi -L 2>&1' ], '... after the probe only');
}

#### gpu_setup: nothing after the refusal

subtest 'gpu_setup on a vGPU guest without driver' => sub {
  my @after;
  no warnings 'redefine';
  local *Rex::GPU::_check_connection = sub { };
  local *Rex::GPU::gpu_detect = sub { { nvidia => [ $A10 ], amd => [], nvswitch => [] } };
  local *Rex::GPU::NVIDIA::install_container_toolkit = sub { push @after, 'toolkit' };
  local *Rex::GPU::NVIDIA::generate_cdi_specs = sub { push @after, 'cdi' };
  local *Rex::GPU::NVIDIA::configure_containerd = sub { push @after, 'containerd' };
  local *Rex::GPU::NVIDIA::verify_nvidia = sub { push @after, 'verify' };
  my $rec = record_host(host => host_profile('ubuntu-24.04'), code => sub { Rex::GPU::gpu_setup() });
  like($rec->{error}, $VGPU_DIE, 'dies with the vGPU message');
  is_deeply(\@after, [], 'no toolkit, CDI, containerd');
};

done_testing;
