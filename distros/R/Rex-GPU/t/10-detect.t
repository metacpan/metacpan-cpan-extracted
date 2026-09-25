use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# CHARACTERIZATION tests for Rex::GPU::Detect.
#
# These assert what the code does TODAY, not what it arguably should do. They
# exercise only the pure string functions (_parse_nvidia_line, _parse_amd_line,
# _is_nvidia_compute) and detect() with run()/is_installed() mocked out via a
# typeglob override. No hardware, no network, no package manager, no SSH.
#
# WHAT THESE TESTS DO NOT COVER — a maintainer MUST exercise the following on a
# real GPU node before a release; none of it runs here and a green `prove` is
# NOT evidence any of it works:
#   * real `lspci -nn` output on genuine hardware (these use hand-built
#     fixtures; a real card may emit a name format the regexes do not expect).
#   * install_driver on each distro family — Debian, Ubuntu, RHEL/Rocky/Alma,
#     openSUSE — including the per-family package lists and version branches.
#   * the Rex::Pkg-bypass verify seam (dpkg -l '^ii' / rpm -q) against a
#     partial/failed DKMS build.
#   * the nouveau blacklist + initramfs regeneration (Setup post_install:
#     update-initramfs / dracut).
#   * _reboot_and_wait: the shutdown, the disconnect/reconnect polling loop,
#     and that the NVIDIA module binds after nouveau is unloaded.
#   * install_container_toolkit and `nvidia-ctk cdi generate` (CDI specs).
#   * configure_containerd for rke2 / k3s / containerd / none.
# -----------------------------------------------------------------------------

use Rex::GPU;
use Rex::GPU::Detect;

# Mock seam: _has_lspci => 1 skips the pciutils bootstrap (karr #46; its
# host interactions are pinned in t/11-detect-pciutils.t); run => fixture feeds
# detect() the text that `lspci -nn | grep -E '[03(00|02)]'` would emit.
# local + dynamic scope means the overrides are live only while detect() runs.
sub detect_with {
  my ($output) = @_;
  no warnings 'redefine';
  local *Rex::GPU::Detect::_has_lspci   = sub { 1 };
  local *Rex::GPU::Detect::is_installed = sub { 1 };
  local *Rex::GPU::Detect::run          = sub { $output };
  return Rex::GPU::Detect::detect();
}

#### _is_nvidia_compute — the highest-risk branch (wrong answer => wrong driver)

subtest '_is_nvidia_compute classification' => sub {
  # PCI class 0302 (3D controller) is compute whatever the name is, unless the
  # device ID is Kepler or older (karr #55, see below).
  is(Rex::GPU::Detect::_is_nvidia_compute('0302', 'anything at all'), 1,
    'class 0302, no ID => compute regardless of name');
  is(Rex::GPU::Detect::_is_nvidia_compute('0302', 'Device', '3aa0'), 1,
    'class 0302, ID without a generation row => compute by class');

  # Named compute families.
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'GA102 [GeForce RTX 3090]'), 1, 'RTX => compute');
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'TITAN V'),                  1, 'TITAN => compute');
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'Quadro P2000'),            1, 'Quadro => compute');
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'Tesla V100'),             1, 'Tesla => compute');

  # Datacenter short-codes via the /[AHLVP]\d{1,3}[GSi]?/ rule (note: the rule
  # is case-SENSITIVE — uppercase as real lspci emits).
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'A100'), 1, 'A100 => compute ([AHLVP]\d rule)');
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'H100'), 1, 'H100 => compute ([AHLVP]\d rule)');
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'L40'),  1, 'L40 => compute ([AHLVP]\d rule)');
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'V100'), 1, 'V100 => compute ([AHLVP]\d rule)');
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'P100'), 1, 'P100 => compute ([AHLVP]\d rule)');

  # GTX 10xx / 16xx are compute.
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'GeForce GTX 1080'), 1, 'GTX 1080 => compute');
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'GeForce GTX 1660'), 1, 'GTX 1660 => compute');

  # karr #54 REPLACES the claim "MX / GT / GTS / NVS / GTX 2xx-9xx are not
  # compute" (maintainer decision: every GPU usable for AI counts, as long as
  # a current driver branch supports it; the generation decides, not the
  # name). Without a device ID only the name is left: a name that reveals
  # Maxwell or later is compute, the negative name rules are gone, and a name
  # that reveals nothing (or only an old generation) falls to the unknown
  # default 0 -- as before for GT 710 / GTS 450 / NVS 310, now with the
  # unknown-model warning.
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'GP108M [GeForce MX150]'), 1, 'GeForce MX150 => compute (Pascal)');
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'GP108 [GeForce GT 1030]'), 1, 'GT 1030 => compute (Pascal)');
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'GeForce GTX 960'), 1, 'GTX 960 => compute (Maxwell)');
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'GM107 [GeForce GTX 750 Ti]'), 1, 'GTX 750 Ti => compute (Maxwell)');
  {
    no warnings 'redefine';
    local *Rex::Logger::info = sub { };
    is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'NV17 [GeForce4 MX 440]'), 0, 'GeForce4 MX 440 (2002) => not compute');
    is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'GT 710'),          0, 'GT 710, no ID => unknown default 0');
    is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'GeForce GTS 450'), 0, 'GTS 450, no ID => unknown default 0');
    is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'NVS 310'),         0, 'NVS 310, no ID => unknown default 0');
    is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'GK110 [GeForce GTX 780]'), 0, 'GTX 780, no ID => unknown default 0');
    is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'GK110 [GeForce GTX TITAN]'), 0, 'Kepler GTX TITAN, no ID => not the TITAN rule');
    is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'GK210GL [Tesla K80]'), 0, 'Tesla K80 at 0300, no ID => not the Tesla rule');
    is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'GF110GL [Tesla M2090]'), 0, 'Fermi Tesla M2090, no ID => not the Tesla rule');
  }

  # Unknown model at class 0300 => 0 is the safe, load-bearing default:
  # an unrecognised chip must NOT trigger a datacenter driver install.
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'FooBar 9000 Unknown Model'), 0,
    'unknown model at class 0300 => 0 (safe default, no install)');

  # Known-compute PCI device ID (3rd arg). GB10 (10de:2e12, DGX Spark, aarch64)
  # enumerates as VGA [0300] with the marketing name UNRESOLVED by a stale
  # pci.ids — lspci prints only "Device". Its device ID is in the Blackwell
  # range of the Requirement table, which makes it compute (karr #45) where
  # the name-token rules cannot. Verified live on cortex.
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'Device', '2e12'), 1,
    'GB10 device id 2e12 at class 0300 with name "Device" => compute');
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'Device', '2E12'), 1,
    'device-id match is case-insensitive');
  # An ID no generation row covers must NOT flip the unknown default (still 0).
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'Device', 'ffff'), 0,
    'device id outside every generation row => unknown default 0 preserved');
  # 2-arg calls (no device id) keep the exact prior behaviour.
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'Device'), 0,
    'no device id => unknown default 0 (back-compatible signature)');
};

#### _parse_nvidia_line

subtest '_parse_nvidia_line — datacenter (class 0302)' => sub {
  my $gpu = Rex::GPU::Detect::_parse_nvidia_line(
    '01:00.0 3D controller [0302]: NVIDIA Corporation AD104GL [RTX 4000 SFF Ada Generation] [10de:27b0] (rev a1)'
  );
  is($gpu->{vendor},    'nvidia', 'vendor nvidia');
  is($gpu->{pci_class}, '0302',   'pci_class 0302');
  is($gpu->{compute},   1,        'compute 1 (class 0302 short-circuit)');
  # The captured name keeps the codename AND the bracketed marketing name
  # verbatim (e.g. "AD104GL [RTX 4000 SFF Ada Generation]") — no "NVIDIA " prefix,
  # no de-bracketing. The POD SYNOPSIS in Detect.pm/GPU.pm documents this exact
  # form (karr #5); the name is a raw detection string and drives no branch
  # except the family-token match in _is_nvidia_compute.
  is($gpu->{name}, 'AD104GL [RTX 4000 SFF Ada Generation]',
    'name = codename + bracketed marketing string (matches POD SYNOPSIS)');
};

subtest '_parse_nvidia_line — consumer (class 0300)' => sub {
  my $gpu = Rex::GPU::Detect::_parse_nvidia_line(
    '65:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA102 [GeForce RTX 3090] [10de:2204] (rev a1)'
  );
  is($gpu->{vendor},    'nvidia',                   'vendor nvidia');
  is($gpu->{pci_class}, '0300',                     'pci_class 0300');
  is($gpu->{compute},   1,                          'compute 1 (RTX name match)');
  is($gpu->{name},      'GA102 [GeForce RTX 3090]', 'name = codename + bracketed marketing string');
};

subtest '_parse_nvidia_line — GB10 aarch64 (name unresolved by pci.ids)' => sub {
  # EXACT class-03 line captured live from cortex (NVIDIA DGX Spark, GB10,
  # aarch64). pci.ids lacks 10de:2e12, so lspci renders the name as "Device";
  # the device ID drives the compute classification.
  my $gpu = Rex::GPU::Detect::_parse_nvidia_line(
    '000f:01:00.0 VGA compatible controller [0300]: NVIDIA Corporation Device [10de:2e12] (rev a1)'
  );
  is($gpu->{vendor},    'nvidia', 'vendor nvidia');
  is($gpu->{pci_class}, '0300',   'pci_class 0300 (GB10 enumerates as VGA, not 3D)');
  is($gpu->{name},      'Device', 'name = "Device" (pci.ids cannot resolve 10de:2e12)');
  is($gpu->{compute},   1,        'compute 1 via the Blackwell device-id range — pipeline runs on a Spark');
};

#### _parse_amd_line

subtest '_parse_amd_line — standard lspci format' => sub {
  my $gpu = Rex::GPU::Detect::_parse_amd_line(
    '0a:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 31 [Radeon RX 7900 XTX] [1002:744c] (rev c8)'
  );
  is($gpu->{vendor},    'amd',  'vendor amd');
  is($gpu->{pci_class}, '0300', 'pci_class 0300');
  is($gpu->{compute},   0,      'compute 0 (AMD never compute by decision)');
  # XXX characterization BUG: the name regex
  #   /:\s+(?:Advanced Micro Devices|AMD\/ATI)\s+.*?\s+(.+?)\s*\[1002:/
  # never matches the real lspci format, because "Advanced Micro Devices" is
  # followed by ", Inc." (comma, not whitespace), so the required \s+ after the
  # vendor literal fails; the "AMD/ATI" alternative is inside brackets and has
  # no ":\s+" immediately before it. Result: name falls back to the default
  # 'Unknown AMD GPU' for a perfectly ordinary AMD card. Detect-only today, so
  # it changes no install decision — but it is a real parse bug. Reported.
  is($gpu->{name}, 'Unknown AMD GPU',
    'name => "Unknown AMD GPU" (regex fails on standard format — XXX, see report)');
};

#### detect() end-to-end with run()/is_installed() mocked

subtest 'detect — NVIDIA only' => sub {
  my $r = detect_with(
    '65:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA102 [GeForce RTX 3090] [10de:2204] (rev a1)'
  );
  is(scalar @{$r->{nvidia}}, 1,        'one nvidia gpu');
  is(scalar @{$r->{amd}},    0,        'no amd gpu');
  is($r->{nvidia}[0]{vendor}, 'nvidia', 'element vendor nvidia');
  is($r->{nvidia}[0]{compute}, 1,       'element compute 1');
};

subtest 'detect — GB10 aarch64 (real cortex string) => compute' => sub {
  my $r = detect_with(
    '000f:01:00.0 VGA compatible controller [0300]: NVIDIA Corporation Device [10de:2e12] (rev a1)'
  );
  is(scalar @{$r->{nvidia}},   1,      'one nvidia gpu');
  is($r->{nvidia}[0]{name},   'Device','name "Device" (unresolved by pci.ids)');
  is($r->{nvidia}[0]{compute}, 1,      'compute 1 — gpu_setup runs the full pipeline on a Spark');
};

#### karr #21 / #45: every Blackwell GPU is compute by device ID
#
# karr #21 put desktop RTX 50xx and RTX PRO Blackwell workstation/server IDs
# on an explicit allowlist and deliberately LEFT OUT laptop and "Embedded"
# chips: this file asserted that an unresolved "Device [10de:2c18]" (RTX 5090
# Laptop) was compute 0. karr #45 REPLACES that claim by maintainer decision
# ("every GPU usable for AI counts, RTX for sure"): every ID in the Blackwell /
# Blackwell Ultra rows of Rex::GPU::NVIDIA::Requirement is compute, whatever
# the class and whether pci.ids resolved the name. The result no longer
# depends on how old the host's pci.ids is.

# Captures every Rex::Logger::info call made while $code runs.
sub logged {
  my ($code) = @_;
  my @log;
  no warnings 'redefine';
  local *Rex::Logger::info = sub { push @log, [ @_ ] };
  my $ret = $code->();
  return ($ret, \@log);
}

subtest 'unresolved name at class 0300 — every Blackwell ID => compute' => sub {
  # IDs from NVIDIA's supportedchips table, driver 615.71.09. The line is what
  # lspci prints when pci.ids does not know the ID: just "Device".
  my %ids = (
    '2b85' => 'GeForce RTX 5090',
    '2b8c' => 'GeForce RTX 5090 D v2',
    '2c02' => 'GeForce RTX 5080',
    '2f04' => 'GeForce RTX 5070',
    '2d83' => 'GeForce RTX 5050',
    '2bb1' => 'RTX PRO 6000 Blackwell Workstation Edition',
    '2bb5' => 'RTX PRO 6000 Blackwell Server Edition',
    '2c3a' => 'RTX PRO 4500 Blackwell Server Edition',
    '2d30' => 'RTX PRO 2000 Blackwell',
    # laptop chips (compute 0 under karr #21, compute 1 since karr #45)
    '2c18' => 'GeForce RTX 5090 Laptop GPU',
    '2f58' => 'GeForce RTX 5070 Ti Laptop GPU',
    '2d98' => 'GeForce RTX 5050 Laptop GPU',
    '2c38' => 'RTX PRO 5000 Blackwell Generation Laptop GPU',
    # RTX PRO Blackwell Embedded modules, RTX 6000D
    '2c77' => 'RTX PRO 5000 Blackwell Embedded GPU',
    '2c79' => 'RTX PRO 4000 Blackwell Embedded GPU',
    '2d79' => 'RTX PRO 2000 Blackwell Embedded GPU',
    '2df9' => 'RTX PRO 500 Blackwell Embedded GPU',
    '2bb9' => 'RTX 6000D',
    # Blackwell Ultra, should one ever enumerate as VGA
    '3182' => 'B300 SXM6 AC',
    '31c2' => 'GB300'
  );
  for my $id (sort keys %ids) {
    my ($gpu, $log) = logged(sub {
      Rex::GPU::Detect::_parse_nvidia_line(
        '01:00.0 VGA compatible controller [0300]: NVIDIA Corporation Device [10de:'.$id.'] (rev a1)'
      );
    });
    is($gpu->{name},      'Device', $id.' name unresolved');
    is($gpu->{device_id}, $id,      $id.' device_id');
    is($gpu->{compute},   1,        $id.' ('.$ids{$id}.') => compute via the Blackwell device-id range');
    ok(!(grep { ($_->[1] // '') eq 'warn' } @$log), $id.' no unknown-model warning');
  }
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'Device', '2B85'), 1,
    'upper-case device id matches too');

  # Range edges: the Blackwell block is 2900-2FFF; 28ff just below is the end
  # of the Turing..Hopper row (compute since karr #54), 3000 just above and
  # the neighbours of the Blackwell Ultra IDs are in no row at all.
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'Device', '2900'), 1, '2900 (block start) => compute');
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'Device', '2fff'), 1, '2fff (block end) => compute');
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'Device', '28ff'), 1, '28ff (Turing..Hopper row end) => compute');
  {
    no warnings 'redefine';
    local *Rex::Logger::info = sub { };
    for my $id (qw( 3000 3181 3183 31c1 31c4 )) {
      is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'Device', $id), 0,
        $id.' (in no generation row) with no name => unknown default 0');
    }
  }

  for my $id (qw( 2b85 2c18 )) {
    my $r = detect_with(
      '01:00.0 VGA compatible controller [0300]: NVIDIA Corporation Device [10de:'.$id.'] (rev a1)'
    );
    is($r->{nvidia}[0]{compute}, 1, 'detect: '.$id.' with unresolved name => compute, pipeline runs');
  }
};

subtest 'unresolved name, ID in no generation row => still not compute' => sub {
  # Before karr #54 this asserted 2330/27b0/1db4 as "Device" => 0; the
  # Turing..Hopper and Maxwell/Pascal/Volta rows make those compute now (see
  # the k54 subtests below). Only an ID no row covers keeps the unknown
  # default, and warns.
  for my $id (qw( 3000 3183 3fff ffff )) {
    my ($gpu, $log) = logged(sub {
      Rex::GPU::Detect::_parse_nvidia_line(
        '01:00.0 VGA compatible controller [0300]: NVIDIA Corporation Device [10de:'.$id.'] (rev a1)'
      );
    });
    is($gpu->{compute}, 0, $id.' "Device" at class 0300 => not compute');
    ok((grep { ($_->[1] // '') eq 'warn' && $_->[0] =~ /Unknown NVIDIA GPU model: Device/ } @$log),
      $id.' warns "Unknown NVIDIA GPU model"');
  }
};

#### karr #54: compute by generation, not by marketing name
#
# Maintainer decision: every GPU usable for AI is compute -- GeForce MX, GT
# and GTX 9xx with 2 GB included -- as long as a current driver branch
# supports it. The device ID's generation row decides (Maxwell .. Blackwell
# Ultra => 1); Kepler or older (below 10de:1340; last branch 470, no longer
# packaged) => 0 with a warning, not a die. IDs and names: NVIDIA's
# supportedchips README 615.71.09 / 580.95.05 and pci.ids 2026-09-24.

my $KEPLER_WARN = qr/is Kepler or older silicon: it needs driver branch 470 or older, which current distributions no longer package -- skipped, no driver installed/;

subtest 'k54: Maxwell and later are compute, whatever the name' => sub {
  my @cases = (
    [ '1d01', 'GP108 [GeForce GT 1030]',    'Pascal' ],
    [ '1f97', 'TU117M [GeForce MX450]',     'Turing' ],
    [ '13c0', 'GM204 [GeForce GTX 980]',    'Maxwell' ],
    [ '1380', 'GM107 [GeForce GTX 750 Ti]', 'Maxwell Gen1' ],
    [ '174d', 'GM108M [GeForce MX130]',     'Maxwell Gen1' ]
  );
  for my $c (@cases) {
    my ($id, $name, $gen) = @$c;
    for my $shown ($name, 'Device') {
      my ($gpu, $log) = logged(sub {
        Rex::GPU::Detect::_parse_nvidia_line(
          '01:00.0 VGA compatible controller [0300]: NVIDIA Corporation '.$shown.' [10de:'.$id.'] (rev a1)'
        );
      });
      is($gpu->{compute}, 1, $id.' "'.$shown.'" ('.$gen.') => compute');
      ok(!(grep { ($_->[1] // '') eq 'warn' } @$log), $id.' "'.$shown.'" => no warning');
    }
  }
};

subtest 'k54: Kepler or older => not compute, with a warning' => sub {
  my @cases = (
    [ '128b', 'GK208B [GeForce GT 710]' ],
    [ '1004', 'GK110 [GeForce GTX 780]' ],
    # Kepler with names the old Quadro/TITAN rules counted as compute (and
    # install_driver then refused): the ID decides now.
    [ '11fa', 'GK106GL [Quadro K4000]' ],
    [ '1005', 'GK110 [GeForce GTX TITAN]' ],
    # pci.ids names this Kepler ID like the Pascal GT 1030: the ID decides.
    [ '0fc5', 'GK107 [GeForce GT 1030]' ]
  );
  for my $c (@cases) {
    my ($id, $name) = @$c;
    for my $shown ($name, 'Device') {
      my ($gpu, $log) = logged(sub {
        Rex::GPU::Detect::_parse_nvidia_line(
          '01:00.0 VGA compatible controller [0300]: NVIDIA Corporation '.$shown.' [10de:'.$id.'] (rev a1)'
        );
      });
      is($gpu->{compute}, 0, $id.' "'.$shown.'" => not compute');
      my @warn = grep { ($_->[1] // '') eq 'warn' } @$log;
      is(scalar @warn, 1, $id.' "'.$shown.'" => exactly one warning');
      like($warn[0][0] // '', qr/NVIDIA GPU \Q$shown\E \(10de:$id\) $KEPLER_WARN/,
        $id.' "'.$shown.'" => the Kepler skip message, naming GPU and ID');
    }
  }
};

subtest 'k54: unknown ID and unknown name => 0 with the unknown warning' => sub {
  my ($gpu, $log) = logged(sub {
    Rex::GPU::Detect::_parse_nvidia_line(
      '01:00.0 VGA compatible controller [0300]: NVIDIA Corporation Frobnicator 9000 [10de:3aa0] (rev a1)'
    );
  });
  is($gpu->{compute}, 0, '3aa0 "Frobnicator 9000" => not compute');
  ok((grep { ($_->[1] // '') eq 'warn' && $_->[0] =~ /Unknown NVIDIA GPU model: Frobnicator 9000/ } @$log),
    '... warns "Unknown NVIDIA GPU model"');
};

subtest 'k54: mixed host -- a Kepler display does not stop a newer GPU' => sub {
  my $gt710 = '02:00.0 VGA compatible controller [0300]: NVIDIA Corporation GK208B [GeForce GT 710] [10de:128b] (rev a1)';
  my $ada   = '01:00.0 3D controller [0302]: NVIDIA Corporation AD104GL [RTX 4000 SFF Ada Generation] [10de:27b0] (rev a1)';
  my ($r, $log) = logged(sub { detect_with($gt710."\n".$ada) });
  is(scalar @{$r->{nvidia}}, 2, 'both GPUs detected');
  is_deeply([ map { $_->{compute} } @{$r->{nvidia}} ], [ 0, 1 ], 'GT 710 not compute, RTX 4000 Ada compute');
  ok((grep { $_->[0] =~ $KEPLER_WARN } @$log), 'the Kepler skip is logged');

  my @calls;
  my $run_setup = sub {
    my ($detected) = @_;
    no warnings 'redefine';
    local *Rex::GPU::_check_connection                 = sub { };
    local *Rex::GPU::gpu_detect                        = sub { $detected };
    local *Rex::GPU::NVIDIA::install_driver            = sub { push @calls, { @_ } };
    local *Rex::GPU::NVIDIA::install_container_toolkit = sub { };
    local *Rex::GPU::NVIDIA::generate_cdi_specs        = sub { };
    local *Rex::GPU::NVIDIA::configure_containerd      = sub { };
    local *Rex::GPU::NVIDIA::verify_nvidia             = sub { };
    local *Rex::Logger::info                           = sub { };
    return eval { Rex::GPU::gpu_setup(); 1 };
  };
  ok($run_setup->($r), 'gpu_setup lives');
  is(scalar @calls, 1, 'install_driver called once');
  is_deeply([ map { $_->{device_id} } @{ $calls[0]{gpus} } ], [ '27b0' ],
    'install_driver gets only the Ada card -- the Kepler never reaches plan');

  @calls = ();
  my ($kepler_only) = logged(sub { detect_with($gt710) });
  ok($run_setup->($kepler_only), 'Kepler-only host: gpu_setup lives');
  is(scalar @calls, 0, '... and installs no driver');
};

subtest 'k55: class-0302 Kepler Tesla => not compute, with the Kepler warning' => sub {
  # Datacenter Keplers enumerate as 3D controller [0302]; the Kepler row is
  # checked before the class rule, so they are skipped like a GT 710.
  my @cases = (
    [ '102d', 'GK210GL [Tesla K80]' ],
    [ '1023', 'GK110BGL [Tesla K40m]' ],
    [ '1028', 'GK110GL [Tesla K20m]' ]
  );
  for my $c (@cases) {
    my ($id, $name) = @$c;
    for my $shown ($name, 'Device') {
      my ($gpu, $log) = logged(sub {
        Rex::GPU::Detect::_parse_nvidia_line(
          '04:00.0 3D controller [0302]: NVIDIA Corporation '.$shown.' [10de:'.$id.'] (rev a1)'
        );
      });
      is($gpu->{pci_class}, '0302', $id.' "'.$shown.'" => class 0302');
      is($gpu->{compute},   0,      $id.' "'.$shown.'" => not compute');
      my @warn = grep { ($_->[1] // '') eq 'warn' } @$log;
      is(scalar @warn, 1, $id.' "'.$shown.'" => exactly one warning');
      like($warn[0][0] // '', qr/NVIDIA GPU \Q$shown\E \(10de:$id\) $KEPLER_WARN/,
        $id.' "'.$shown.'" => the Kepler skip message, naming GPU and ID');
    }
  }
};

subtest 'k55: mixed host -- a K80 does not stop a newer GPU' => sub {
  my $k80 = '04:00.0 3D controller [0302]: NVIDIA Corporation GK210GL [Tesla K80] [10de:102d] (rev a1)';
  my $ada = '01:00.0 3D controller [0302]: NVIDIA Corporation AD104GL [RTX 4000 SFF Ada Generation] [10de:27b0] (rev a1)';
  my ($r, $log) = logged(sub { detect_with($k80."\n".$ada) });
  is(scalar @{$r->{nvidia}}, 2, 'both GPUs detected');
  is_deeply([ map { $_->{compute} } @{$r->{nvidia}} ], [ 0, 1 ], 'K80 not compute, RTX 4000 Ada compute');
  is(scalar(grep { $_->[0] =~ $KEPLER_WARN } @$log), 1, 'the Kepler skip is logged once');

  my @calls;
  my $run_setup = sub {
    my ($detected) = @_;
    no warnings 'redefine';
    local *Rex::GPU::_check_connection                 = sub { };
    local *Rex::GPU::gpu_detect                        = sub { $detected };
    local *Rex::GPU::NVIDIA::install_driver            = sub { push @calls, { @_ } };
    local *Rex::GPU::NVIDIA::install_container_toolkit = sub { };
    local *Rex::GPU::NVIDIA::generate_cdi_specs        = sub { };
    local *Rex::GPU::NVIDIA::configure_containerd      = sub { };
    local *Rex::GPU::NVIDIA::verify_nvidia             = sub { };
    local *Rex::Logger::info                           = sub { };
    return eval { Rex::GPU::gpu_setup(); 1 };
  };
  ok($run_setup->($r), 'gpu_setup lives');
  is(scalar @calls, 1, 'install_driver called once');
  is_deeply([ map { $_->{device_id} } @{ $calls[0]{gpus} } ], [ '27b0' ],
    'install_driver gets only the Ada card -- the K80 never reaches plan');

  @calls = ();
  my ($k80_only) = logged(sub { detect_with($k80) });
  ok($run_setup->($k80_only), 'K80-only host: gpu_setup lives');
  is(scalar @calls, 0, '... and installs no driver');
};

subtest 'resolved names: RTX laptop parts are compute by name' => sub {
  # The name rule \bRTX\b stays: a laptop RTX of any generation whose name
  # pci.ids resolves is compute — wanted (karr #45), not just tolerated.
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'GB202M [GeForce RTX 5090 Laptop GPU]', '2c18'), 1,
    'resolved "RTX 5090 Laptop GPU" => compute (range and name agree)');
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'AD103M / AD104M [GeForce RTX 4090 Laptop GPU]', '2717'), 1,
    'Ada "RTX 4090 Laptop GPU" => compute (Turing..Hopper row since karr #54, RTX name rule before)');
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'GB202 [GeForce RTX 5090]', '2b85'), 1,
    'resolved RTX 5090 => compute');
  no warnings 'redefine';
  local *Rex::Logger::info = sub { };
  is(Rex::GPU::Detect::_is_nvidia_compute('0300', 'GT 710', '128b'), 0,
    'GT 710 with its Kepler id => still 0 (by generation since karr #54)');
};

subtest 'detect — AMD only' => sub {
  my $r = detect_with(
    '0a:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 31 [Radeon RX 7900 XTX] [1002:744c] (rev c8)'
  );
  is(scalar @{$r->{nvidia}}, 0,     'no nvidia gpu');
  is(scalar @{$r->{amd}},    1,     'one amd gpu');
  is($r->{amd}[0]{vendor},  'amd',  'element vendor amd');
  is($r->{amd}[0]{compute}, 0,      'element compute 0');
};

subtest 'detect — virtual-only output => empty (unchanged)' => sub {
  # virtio [1af4] alone
  my $r = detect_with(
    '00:02.0 VGA compatible controller [0300]: Red Hat, Inc. Virtio GPU [1af4:1050] (rev 01)'
  );
  is(scalar @{$r->{nvidia}}, 0, 'virtio => no nvidia');
  is(scalar @{$r->{amd}},    0, 'virtio => no amd');

  # QEMU [1b36] alone
  my $q = detect_with(
    '00:01.0 VGA compatible controller [0300]: Device [1b36:0100] (rev 04)'
  );
  is(scalar @{$q->{nvidia}}, 0, 'qemu => no nvidia');
  is(scalar @{$q->{amd}},    0, 'qemu => no amd');

  # Several virtual displays and nothing else => still empty.
  my $vv = detect_with(
      "00:01.0 VGA compatible controller [0300]: Red Hat, Inc. QXL paravirtual graphic card [1b36:0100] (rev 05)\n"
    . "00:02.0 VGA compatible controller [0300]: Red Hat, Inc. Virtio 1.0 GPU [1af4:1050] (rev 01)"
  );
  is(scalar @{$vv->{nvidia}}, 0, 'qxl+virtio only => no nvidia');
  is(scalar @{$vv->{amd}},    0, 'qxl+virtio only => no amd');
};

# karr #17: a virtual line is skipped on its own; it no longer hides a real
# card elsewhere in the output. (Until k17 this block asserted the opposite —
# virtio+nvidia => empty — as a characterization of the blob-match bug.)
subtest 'detect — virtual console + passed-through NVIDIA (vfio / cloud GPU VM)' => sub {
  my $r = detect_with(
      "00:01.0 VGA compatible controller [0300]: Red Hat, Inc. QXL paravirtual graphic card [1b36:0100] (rev 05)\n"
    . "06:00.0 3D controller [0302]: NVIDIA Corporation AD102GL [L40S] [10de:26b9] (rev a1)"
  );
  is(scalar @{$r->{nvidia}},     1,      'QXL + L40S => one nvidia gpu');
  is(scalar @{$r->{amd}},        0,      'no amd gpu');
  is($r->{nvidia}[0]{name},      'AD102GL [L40S]', 'the real card is the one reported');
  is($r->{nvidia}[0]{pci_class}, '0302', 'pci_class 0302');
  is($r->{nvidia}[0]{device_id}, '26b9', 'device_id from [10de:26b9]');
  is($r->{nvidia}[0]{compute},   1,      'compute 1 — pipeline runs in the passthrough VM');

  # Order must not matter (virtual line after the real one).
  my $m = detect_with(
      "65:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA102 [GeForce RTX 3090] [10de:2204] (rev a1)\n"
    . "00:02.0 VGA compatible controller [0300]: Red Hat, Inc. Virtio GPU [1af4:1050] (rev 01)"
  );
  is(scalar @{$m->{nvidia}}, 1, 'nvidia+virtio => one nvidia gpu');
  is(scalar @{$m->{amd}},    0, 'nvidia+virtio => no amd');
};

subtest 'detect — bare metal BMC VGA (ASPEED) + RTX 4000 => unchanged' => sub {
  # ASPEED [1a03] is neither virtual nor NVIDIA/AMD: ignored, as before k17.
  my $r = detect_with(
      "02:00.0 VGA compatible controller [0300]: ASPEED Technology, Inc. ASPEED Graphics Family [1a03:2000] (rev 41)\n"
    . "01:00.0 3D controller [0302]: NVIDIA Corporation AD104GL [RTX 4000 SFF Ada Generation] [10de:27b0] (rev a1)"
  );
  is(scalar @{$r->{nvidia}},   1, 'one nvidia gpu');
  is(scalar @{$r->{amd}},      0, 'no amd gpu (ASPEED ignored)');
  is($r->{nvidia}[0]{name}, 'AD104GL [RTX 4000 SFF Ada Generation]', 'RTX 4000 reported');
  is($r->{nvidia}[0]{compute}, 1, 'compute 1');

  my $bmc = detect_with(
    "02:00.0 VGA compatible controller [0300]: ASPEED Technology, Inc. ASPEED Graphics Family [1a03:2000] (rev 41)"
  );
  is(scalar @{$bmc->{nvidia}}, 0, 'ASPEED only => no nvidia');
  is(scalar @{$bmc->{amd}},    0, 'ASPEED only => no amd');
};

subtest 'detect — mixed NVIDIA + AMD' => sub {
  my $r = detect_with(
      "65:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA102 [GeForce RTX 3090] [10de:2204] (rev a1)\n"
    . "0a:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 31 [Radeon RX 7900 XTX] [1002:744c] (rev c8)"
  );
  is(scalar @{$r->{nvidia}}, 1, 'one nvidia gpu');
  is(scalar @{$r->{amd}},    1, 'one amd gpu');
};

subtest 'detect — empty run output' => sub {
  my $empty = detect_with('');
  is(scalar @{$empty->{nvidia}}, 0, "empty string => no nvidia");
  is(scalar @{$empty->{amd}},    0, "empty string => no amd");

  my $undef = detect_with(undef);
  is(scalar @{$undef->{nvidia}}, 0, 'undef output => no nvidia');
  is(scalar @{$undef->{amd}},    0, 'undef output => no amd');
};

done_testing;
