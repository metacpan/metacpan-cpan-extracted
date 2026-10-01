use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# NVSwitch detection and NVIDIA Fabric Manager (karr #23).
#
# CLAIMS:
#   * detect() reports NVIDIA [0680] bridges as nvswitch only by a known
#     NVSwitch ID (1ac2/1af1/22a3) or an "NVSwitch" name; another NVIDIA
#     bridge is skipped; the extra lspci runs only when an NVIDIA GPU was
#     found; nvidia/amd are unchanged;
#   * an HGX B200 (8x B200, its NVSwitches are not PCI devices) yields no
#     nvswitch -- the install is exactly the one without it;
#   * gpu_setup passes nvswitches to install_driver only when there is one;
#   * with nvswitches the driver source must name a Fabric Manager: Debian
#     non-free is skipped for the CUDA repo, Debian 11 / openSUSE die with
#     read-only probes only; on apt a missing Fabric Manager candidate dies
#     after apt-get update and before any install;
#   * Fabric Manager is installed AFTER the driver is verified, at exactly
#     the installed driver's upstream version (apt: PKG=<madison version>,
#     rpm: PKG-<version>), verified with dpkg/rpm, and the unit is enabled,
#     not started, before post_install; install_driver starts it after
#     modprobe and checks is-active (warns only);
#   * no version match / a mismatched result dies, naming both versions,
#     with no install of another version;
#   * an already-installed driver (karr #50) gets Fabric Manager only from the
#     host's own sources at the loaded version, else a warning; then the
#     is-active check (warn).
#
# NOT covered -- none of it runs without a real HGX host: that the package
# names exist in the repos at those versions, that the lspci -nn line of a
# real NVSwitch looks like the hand-built fixture (NVIDIA's docs only show
# plain lspci), that Fabric Manager starts and the GPUs reach Fabric State
# "Completed", or anything on HGX B200/B300 (NVLSM, CX7 bridges).
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw(
  record_host golden_is host_profile gpu_fixture mutating_lines working_driver
);
use Rex::GPU;
use Rex::GPU::Detect;
use Rex::GPU::NVIDIA;
use Rex::GPU::NVIDIA::Setup::RHEL;

my $H100_LINE = '18:00.0 3D controller [0302]: NVIDIA Corporation GH100 [H100 SXM5 80GB] [10de:2330] (rev a1)';
my @NVSWITCH_LINES = map {
  sprintf('%02x:00.0 Bridge [0680]: NVIDIA Corporation GH100 [H100 NVSwitch] [10de:22a3] (rev a1)', $_)
} 5 .. 8;

my $LSPCI_PROBE   = 'command -v lspci >/dev/null 2>&1';
my $DISPLAY_READ  = q{lspci -nn 2>&1 | grep -E '\[03(00|02)\]'};
my $NVSWITCH_READ = q{lspci -nn -d 10de: 2>/dev/null | grep -F '[0680]'};

# detect() with run() answering per command; records the commands. lspci is
# on the PATH (karr #46's probe exits 0), so nothing is installed.
sub detect_on {
  my ( %answer ) = @_;
  my @cmds;
  no warnings 'redefine';
  local *Rex::GPU::Detect::is_installed = sub { 1 };
  local *Rex::GPU::Detect::run = sub {
    my ( $cmd ) = @_;
    push @cmds, $cmd;
    $? = 0;
    return $cmd eq $LSPCI_PROBE ? ''
      : $cmd =~ /\[0680\]/ ? $answer{nvswitch}
      : $answer{display};
  };
  local *Rex::Logger::info = sub { };
  return ( Rex::GPU::Detect::detect(), \@cmds );
}

#### Detection

subtest 'HGX H100: 8 GPUs + 4 NVSwitches' => sub {
  my ( $r, $cmds ) = detect_on(
    display  => join("\n", ($H100_LINE) x 8),
    nvswitch => join("\n", @NVSWITCH_LINES)
  );
  is(scalar @{ $r->{nvidia} }, 8, '8 GPUs');
  is(scalar @{ $r->{nvswitch} }, 4, '4 NVSwitches');
  is_deeply($r->{nvswitch}[0], { name => 'GH100 [H100 NVSwitch]', vendor => 'nvidia',
    pci_class => '0680', device_id => '22a3' }, 'NVSwitch element');
  # karr #24 appends the read-only vGPU subsystem read on NVIDIA hosts
  is_deeply($cmds, [ $LSPCI_PROBE, $DISPLAY_READ, $NVSWITCH_READ,
    'lspci -vmmnn -d 10de: 2>/dev/null' ],
    'probe, display lspci, then the second and third, read-only lspci');
};

subtest 'NVSwitch recognised by ID with a stale pci.ids, and by name' => sub {
  my $sw = Rex::GPU::Detect->_parse_nvswitch_line(
    '07:00.0 Bridge [0680]: NVIDIA Corporation Device [10de:1af1] (rev a1)');
  is($sw->{device_id}, '1af1', 'A100 NVSwitch by ID, name "Device"');
  $sw = Rex::GPU::Detect->_parse_nvswitch_line(
    '07:00.0 Bridge [0680]: NVIDIA Corporation GXXX [Future NVSwitch] [10de:ffff] (rev a1)');
  is($sw->{device_id}, 'ffff', 'unknown ID named NVSwitch');
};

subtest 'other NVIDIA bridges and other classes are not NVSwitches' => sub {
  my @log;
  no warnings 'redefine';
  local *Rex::Logger::info = sub { push @log, $_[0] };
  is(Rex::GPU::Detect->_parse_nvswitch_line(
    '00:08.0 Bridge [0680]: NVIDIA Corporation MCP55 Ethernet [10de:0373] (rev a3)'), undef,
    'nForce bridge (10de:0373) skipped');
  like($log[0], qr/not known as an NVSwitch/, '... and logged');
  is(Rex::GPU::Detect->_parse_nvswitch_line($H100_LINE), undef, 'a GPU line is not an NVSwitch');
  is(Rex::GPU::Detect->_parse_nvswitch_line(
    '07:00.0 Bridge [0680]: Mellanox Technologies Device [15b3:1021]'), undef, 'non-NVIDIA bridge');
};

subtest 'no NVIDIA GPU => no NVSwitch probe' => sub {
  my ( $r, $cmds ) = detect_on(
    display  => '0a:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 31 [Radeon RX 7900 XTX] [1002:744c] (rev c8)',
    nvswitch => join("\n", @NVSWITCH_LINES)
  );
  is_deeply($cmds, [ $LSPCI_PROBE, $DISPLAY_READ ], 'only the probe and the display lspci ran');
  is_deeply($r->{nvswitch}, [], 'nvswitch => []');
  ( $r ) = detect_on(display => '', nvswitch => '');
  is_deeply($r->{nvswitch}, [], 'empty lspci => nvswitch => []');
};

subtest 'HGX B200: no NVSwitch on the host PCI bus' => sub {
  # Per NVIDIA's Fabric Manager guide the gen4 NVSwitches are behind CX-7
  # bridge functions; the host's lspci shows those (15b3), not a 10de [0680].
  my ( $r ) = detect_on(
    display  => join("\n", ('18:00.0 3D controller [0302]: NVIDIA Corporation GB100 [B200] [10de:2901] (rev a1)') x 8),
    nvswitch => ''
  );
  is(scalar @{ $r->{nvidia} }, 8, '8 B200');
  is_deeply($r->{nvswitch}, [], 'no NVSwitch detected -- no Fabric Manager (documented gap)');
};

#### gpu_setup passes nvswitches only when there is one

subtest 'gpu_setup -> install_driver' => sub {
  my @calls;
  no warnings 'redefine';
  local *Rex::GPU::_check_connection = sub { };
  local *Rex::GPU::NVIDIA::install_driver = sub { push @calls, { @_ } };
  local *Rex::GPU::NVIDIA::install_container_toolkit = sub { };
  local *Rex::GPU::NVIDIA::generate_cdi_specs = sub { };
  local *Rex::GPU::NVIDIA::configure_containerd = sub { };
  local *Rex::GPU::NVIDIA::verify_nvidia = sub { };
  local *Rex::Logger::info = sub { };
  my $switches = [ { name => 'GH100 [H100 NVSwitch]', device_id => '22a3' } ];
  my $gpu = gpu_fixture('h100');
  local *Rex::GPU::gpu_detect = sub { { nvidia => [ $gpu ], amd => [], nvswitch => $switches } };
  Rex::GPU::gpu_setup();
  is($calls[0]{nvswitches}, $switches, 'NVSwitch host: nvswitches passed');
  local *Rex::GPU::gpu_detect = sub { { nvidia => [ $gpu ], amd => [], nvswitch => [] } };
  Rex::GPU::gpu_setup();
  ok(!exists $calls[1]{nvswitches}, 'no NVSwitch: the call is what it was before');
};

#### install_driver with nvswitches

my $NVSW = [ { name => 'GH100 [H100 NVSwitch]', device_id => '22a3', pci_class => '0680', vendor => 'nvidia' } ];

sub hgx_on {
  my ( $host, %opt ) = @_;
  return record_host(host => $host, code => sub {
    Rex::GPU::NVIDIA::install_driver(gpus => [ gpu_fixture('h100') ], nvswitches => $NVSW, %opt) });
}

my @UBUNTU_FM = (
  [ q{dpkg-query -W -f='${Version}' nvidia-driver-590-server 2>/dev/null} => '590.48.01-0ubuntu0.24.04.1', 0 ],
  [ q{dpkg-query -W -f='${Version}' nvidia-fabricmanager-590 2>/dev/null} => '590.48.01-0ubuntu0.24.04.1', 0 ],
  [ 'apt-cache madison nvidia-fabricmanager-590 2>/dev/null' =>
      " nvidia-fabricmanager-590 | 590.48.02-0ubuntu0.24.04.1 | http://archive.ubuntu.com/ubuntu noble-updates/multiverse amd64 Packages\n"
    . " nvidia-fabricmanager-590 | 590.48.01-0ubuntu0.24.04.1 | http://archive.ubuntu.com/ubuntu noble-updates/multiverse amd64 Packages", 0 ]
);
my @RHEL_FM = (
  [ q{rpm -q --qf '%{VERSION}' nvidia-fabricmanager 2>&1} => '580.95.05', 0 ]
);
my @DEBIAN_FM = (
  [ 'LC_ALL=C apt-cache policy nvidia-fabricmanager 2>/dev/null' =>
      "nvidia-fabricmanager:\n  Installed: (none)\n  Candidate: 615.71.09-1\n", 0 ],
  [ q{dpkg-query -W -f='${Version}' nvidia-kernel-open-dkms 2>/dev/null} => '615.71.09-1', 0 ],
  [ q{dpkg-query -W -f='${Version}' nvidia-fabricmanager 2>/dev/null} => '615.71.09-1', 0 ],
  [ 'apt-cache madison nvidia-fabricmanager 2>/dev/null' =>
      " nvidia-fabricmanager | 615.71.09-1 | https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64  Packages", 0 ]
);

{
  my $rec = hgx_on(host_profile('ubuntu-24.04', responses => [ @UBUNTU_FM ]));
  is($rec->{error}, undef, 'ubuntu-24.04 HGX H100: lives');
  golden_is($rec, 'driver/ubuntu-24.04--hgx-h100');
  my @l = @{ $rec->{lines} };
  my ( $drv ) = grep { $l[$_] =~ /install -y linux-headers/ } 0 .. $#l;
  my ( $fm )  = grep { $l[$_] =~ /install -y nvidia-fabricmanager-590=590\.48\.01-0ubuntu0\.24\.04\.1$/ } 0 .. $#l;
  my ( $nou ) = grep { $l[$_] =~ /blacklist-nouveau/ } 0 .. $#l;
  ok(defined $drv && defined $fm && $drv < $fm && $fm < $nou,
    '... Fabric Manager pinned to the driver\'s upstream version, after the driver, before nouveau');
}

golden_is(hgx_on(host_profile('rocky-9', responses => [ @RHEL_FM ])), 'driver/rocky-9--hgx-h100');
golden_is(hgx_on(host_profile('rocky-10', responses => [ @RHEL_FM ])), 'driver/rocky-10--hgx-h100');

{
  my $rec = hgx_on(host_profile('debian-12', responses => [ @DEBIAN_FM ]));
  is($rec->{error}, undef, 'debian-12 HGX H100: lives');
  ok(!(grep { /nvidia-driver nvidia-smi libcuda1/ } @{ $rec->{lines} }), '... non-free is not used');
  golden_is($rec, 'driver/debian-12--hgx-h100');
}

# No source with a Fabric Manager: dies in plan, read-only probes only.
for my $case ([ 'debian-12', release => '11.11' ], [ 'leap-15.6' ], [ 'leap-16.0' ]) {
  my ( $os, @over ) = @$case;
  my $rec = hgx_on(host_profile($os, @over));
  like($rec->{error}, qr/no NVIDIA Fabric Manager package for the NVSwitch on this host.*No driver package was installed and no package source was added/,
    "$os @over HGX H100: dies naming the missing Fabric Manager");
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... only read-only probes');
}

# Without nvswitches the same GPU on the same host is the plain install.
{
  my $with_empty = record_host(host => host_profile('debian-12'), code => sub {
    Rex::GPU::NVIDIA::install_driver(gpus => [ gpu_fixture('h100') ], nvswitches => []) });
  my $without = record_host(host => host_profile('debian-12'), code => sub {
    Rex::GPU::NVIDIA::install_driver(gpus => [ gpu_fixture('h100') ]) });
  is_deeply($with_empty->{lines}, $without->{lines}, 'nvswitches => [] changes nothing');
  ok(!(grep { /fabricmanager/ } @{ $without->{lines} }), '... and emits no Fabric Manager command');
}

# apt: no candidate for the Fabric Manager after apt-get update -> dies
# before any install.
{
  my $rec = hgx_on(host_profile('ubuntu-24.04', responses => [
    [ 'LC_ALL=C apt-cache policy nvidia-fabricmanager-590 2>/dev/null' => '', 0 ], @UBUNTU_FM ]));
  like($rec->{error}, qr/has no Fabric Manager for the NVSwitch.*nvidia-fabricmanager-590 has no installation candidate.*No driver package was installed/,
    'ubuntu: no Fabric Manager candidate dies');
  is_deeply([ grep { / install / } @{ $rec->{lines} } ], [], '... before any install');
}

# apt: madison has no Fabric Manager of the driver's version -> dies after
# the driver, installs no other version.
{
  my $rec = hgx_on(host_profile('ubuntu-24.04', responses => [
    [ 'apt-cache madison nvidia-fabricmanager-590 2>/dev/null' =>
        " nvidia-fabricmanager-590 | 590.48.02-0ubuntu0.24.04.1 | http://archive.ubuntu.com/ubuntu noble-updates/multiverse amd64 Packages", 0 ],
    @UBUNTU_FM ]));
  like($rec->{error}, qr/apt has no nvidia-fabricmanager-590 of driver version 590\.48\.01/,
    'ubuntu: no matching Fabric Manager version dies');
  ok(!(grep { /install -y nvidia-fabricmanager/ } @{ $rec->{lines} }), '... no Fabric Manager install');
  ok(!(grep { /blacklist-nouveau/ } @{ $rec->{lines} }), '... before post_install');
}

# rpm: dnf installed some other version -> dies naming both.
{
  my $rec = hgx_on(host_profile('rocky-9', responses => [
    [ q{rpm -q --qf '%{VERSION}' nvidia-fabricmanager 2>&1} => '615.71.09', 0 ] ]));
  like($rec->{error}, qr/nvidia-fabricmanager is 615\.71\.09 after dnf install, not the driver's 580\.95\.05/,
    'rocky-9: mismatched Fabric Manager dies');
}

# rpm: the driver version cannot be read -> dies, no Fabric Manager install.
{
  my $rec = hgx_on(host_profile('rocky-9', responses => [
    [ q{rpm -q --qf '%{VERSION}' nvidia-driver 2>&1} => 'package nvidia-driver is not installed', 1 ],
    [ 'rpm -q nvidia-driver 2>&1' => 'nvidia-driver-580.95.05', 0 ] ]));
  like($rec->{error}, qr/Cannot read the installed NVIDIA driver version/, 'rocky-9: unreadable driver version dies');
  ok(!(grep { /install -y nvidia-fabricmanager/ } @{ $rec->{lines} }), '... no Fabric Manager install');
}

# The unit cannot be enabled -> dies.
{
  my $rec = hgx_on(host_profile('rocky-9', responses => [
    [ 'systemctl enable nvidia-fabricmanager.service' => 'Failed to enable unit', 1 ], @RHEL_FM ]));
  like($rec->{error}, qr/systemctl enable nvidia-fabricmanager\.service failed/, 'enable failure dies');
}

# Fabric Manager not active after modprobe: warns, does not die.
{
  my $rec = hgx_on(host_profile('rocky-9', responses => [
    [ 'systemctl is-active --quiet nvidia-fabricmanager.service' => '', 3 ], @RHEL_FM ]));
  is($rec->{error}, undef, 'inactive Fabric Manager after install: no die');
  ok((grep { $_->[0] eq 'warn' && $_->[1] =~ /NVSwitch present but nvidia-fabricmanager\.service is not active/ } @{ $rec->{logs} }),
    '... warns');
}

#### Already-installed driver (karr #50)
#
# CLAIM: the driver is never touched and no package source is added. Fabric
# Manager is installed only when none is on the host and the host's current
# sources offer the package name a fresh install uses at exactly the loaded
# driver's version (nvidia-smi --query-gpu); apt refreshes its index first
# and simulates the install (no removals). An FM already there is left
# alone (warn on a version mismatch); not offered => warn, no install, no die.

my $DRIVER_VERSION_Q = 'nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>&1';
my $DPKG_FM_Q = q{dpkg-query -W -f='${Package} ${db:Status-Abbrev} ${Version}\n' 'nvidia-fabric*manager*' 2>/dev/null};
my $RPM_FM_Q  = q{rpm -qa --qf '%{NAME} %{VERSION}\n' 'nvidia-fabric*manager*' 2>/dev/null};
my $DNF_FM_Q  = 'dnf -q list --showduplicates --available nvidia-fabricmanager 2>/dev/null';

sub installed_hgx_on {
  my ( $os, $version, @responses ) = @_;
  return hgx_on(host_profile($os, responses => [
    working_driver(), [ $DRIVER_VERSION_Q => join("\n", ($version) x 8), 0 ], @responses ]));
}

sub warned {
  my ( $rec, $re ) = @_;
  return scalar grep { $_->[0] eq 'warn' && $_->[1] =~ $re } @{ $rec->{logs} };
}

sub installs { grep { / install -y / } @{ $_[0]{lines} } }

my %RETROFIT = (
  'ubuntu-24.04' => {
    available => [
      [ $DPKG_FM_Q => '', 1 ],
      [ 'apt-cache madison nvidia-fabricmanager-580 2>/dev/null' =>
          " nvidia-fabricmanager-580 | 580.126.09-0ubuntu0.24.04.1 | http://archive.ubuntu.com/ubuntu noble-updates/multiverse amd64 Packages\n"
        . " nvidia-fabricmanager-580 | 580.95.05-0ubuntu0.24.04.1 | http://archive.ubuntu.com/ubuntu noble-updates/multiverse amd64 Packages", 0 ],
      [ q{dpkg-query -W -f='${Version}' nvidia-fabricmanager-580 2>/dev/null} => '580.95.05-0ubuntu0.24.04.1', 0 ]
    ],
    unavailable => [
      [ $DPKG_FM_Q => '', 1 ],
      [ 'apt-cache madison nvidia-fabricmanager-580 2>/dev/null' =>
          " nvidia-fabricmanager-580 | 580.126.09-0ubuntu0.24.04.1 | http://archive.ubuntu.com/ubuntu noble-updates/multiverse amd64 Packages", 0 ]
    ],
    present => [
      [ $DPKG_FM_Q => "nvidia-fabricmanager-580 ii  580.95.05-0ubuntu0.24.04.1\n"
        . "nvidia-fabricmanager-dev-580 ii  580.95.05-0ubuntu0.24.04.1", 0 ]
    ],
    install => qr/install -y nvidia-fabricmanager-580=580\.95\.05-0ubuntu0\.24\.04\.1$/
  },
  'rocky-9' => {
    available => [
      [ $RPM_FM_Q => '', 0 ],
      [ $DNF_FM_Q => "Available Packages\n"
        . "nvidia-fabricmanager.x86_64              580.82.07-1              cuda-rhel9-x86_64\n"
        . "nvidia-fabricmanager.x86_64              580.95.05-1              cuda-rhel9-x86_64", 0 ],
      [ q{rpm -q --qf '%{VERSION}' nvidia-fabricmanager 2>&1} => '580.95.05', 0 ]
    ],
    unavailable => [
      [ $RPM_FM_Q => '', 0 ],
      [ $DNF_FM_Q => '', 1 ]
    ],
    present => [
      [ $RPM_FM_Q => 'nvidia-fabricmanager 580.95.05', 0 ]
    ],
    install => qr/dnf install -y nvidia-fabricmanager-580\.95\.05$/
  },
  # available: a host whose driver came from NVIDIA's CUDA repo (k18);
  # unavailable: the pre-k23 non-free 535 driver, no CUDA repo configured
  'debian-12' => {
    available => [
      [ $DPKG_FM_Q => '', 1 ],
      [ 'apt-cache madison nvidia-fabricmanager 2>/dev/null' =>
          " nvidia-fabricmanager | 580.95.05-1 | https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64  Packages", 0 ],
      [ q{dpkg-query -W -f='${Version}' nvidia-fabricmanager 2>/dev/null} => '580.95.05-1', 0 ]
    ],
    unavailable => [
      [ $DPKG_FM_Q => '', 1 ],
      [ 'apt-cache madison nvidia-fabricmanager 2>/dev/null' => '', 0 ]
    ],
    present => [
      [ $DPKG_FM_Q => 'nvidia-fabricmanager ii  580.95.05-1', 0 ]
    ],
    install => qr/install -y nvidia-fabricmanager=580\.95\.05-1$/
  }
);
my %LOADED = ( 'debian-12' => { unavailable => '535.247.01' } );

for my $os (sort keys %RETROFIT) {
  my $case = $RETROFIT{$os};
  for my $state (qw( available unavailable present )) {
    my $version = $LOADED{$os}{$state} // '580.95.05';
    my $rec = installed_hgx_on($os, $version, @{ $case->{$state} });
    is($rec->{error}, undef, "$os installed driver, FM $state: no die");
    golden_is($rec, "driver/$os--hgx-h100--installed--fm-$state");
    ok(!(grep { /nvidia-driver|linux-headers|kmod|blacklist-nouveau|cuda-keyring|config-manager/ } installs($rec)),
      '... the driver is not touched');
    ok(!(grep { /cuda-keyring|config-manager|addrepo|sources\.list/ } @{ $rec->{lines} }),
      '... no package source added');
    if ($state eq 'available') {
      my @l = @{ $rec->{lines} };
      my ( $inst )  = grep { $l[$_] =~ $case->{install} } 0 .. $#l;
      my ( $start ) = grep { $l[$_] eq 'run: systemctl start nvidia-fabricmanager.service' } 0 .. $#l;
      my ( $en )    = grep { $l[$_] eq 'run: systemctl enable nvidia-fabricmanager.service' } 0 .. $#l;
      ok(defined $inst && defined $en && defined $start && $inst < $en && $en < $start,
        '... Fabric Manager at the loaded version, then enabled, then started');
      is(scalar(installs($rec)), 1, '... one install, nothing else');
    }
    elsif ($state eq 'unavailable') {
      is_deeply([ installs($rec) ], [], '... nothing installed');
      ok(warned($rec, qr/offer none for the loaded driver $version.*No package source was added/),
        '... warns naming the version');
    }
    else {
      is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... only read-only probes');
      ok(!warned($rec, qr/Fabric Manager .* is installed, but/), '... no mismatch warning');
    }
  }
}

# apt: the index is refreshed before madison is asked.
{
  my $rec = installed_hgx_on('ubuntu-24.04', '580.95.05', @{ $RETROFIT{'ubuntu-24.04'}{available} });
  my @l = @{ $rec->{lines} };
  my ( $upd ) = grep { $l[$_] =~ /apt-get .* update -q$/ } 0 .. $#l;
  my ( $mad ) = grep { $l[$_] =~ /apt-cache madison/ } 0 .. $#l;
  ok(defined $upd && $upd < $mad, 'ubuntu: apt-get update before apt-cache madison');
}

# Fabric Manager of another branch installed: warn, leave it alone.
{
  my $rec = installed_hgx_on('ubuntu-24.04', '580.95.05',
    [ $DPKG_FM_Q => 'nvidia-fabricmanager-570 ii  570.172.08-0ubuntu0.24.04.1', 0 ]);
  is($rec->{error}, undef, 'ubuntu FM 570 next to driver 580: no die');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... nothing changed');
  ok(warned($rec, qr/nvidia-fabricmanager-570 570\.172\.08 is installed, but the loaded NVIDIA driver is 580\.95\.05/),
    '... warns naming both versions');
}

# Only config files left (rc): not installed -- the retrofit proceeds.
{
  my $rec = installed_hgx_on('ubuntu-24.04', '580.95.05',
    [ $DPKG_FM_Q => 'nvidia-fabricmanager-580 rc  580.82.07-0ubuntu0.24.04.1', 0 ],
    @{ $RETROFIT{'ubuntu-24.04'}{available} });
  ok((grep { $_ =~ $RETROFIT{"ubuntu-24.04"}{install} } installs($rec)), 'ubuntu: an rc Fabric Manager counts as absent');
}

# apt: installing it would remove packages (another driver flavour) -> no install.
{
  my $rec = installed_hgx_on('ubuntu-24.04', '580.95.05',
    [ qr{^LC_ALL=C apt-get .* -s install nvidia-fabricmanager-580=} =>
        "Remv nvidia-kernel-common-580 [580.95.05-0ubuntu0.24.04.1]\nInst nvidia-kernel-common-580-server", 0 ],
    @{ $RETROFIT{'ubuntu-24.04'}{available} });
  is($rec->{error}, undef, 'ubuntu: simulated removal: no die');
  is_deeply([ installs($rec) ], [], '... nothing installed');
  ok(warned($rec, qr/would remove nvidia-kernel-common-580/), '... warns naming the removal');
}

# Loaded driver version unreadable / inconsistent: warn, nothing touched.
for my $out ('', "580.95.05\n570.172.08") {
  my $rec = hgx_on(host_profile('rocky-9', responses => [
    working_driver(), [ $DRIVER_VERSION_Q => $out, 0 ], @{ $RETROFIT{'rocky-9'}{available} } ]));
  is($rec->{error}, undef, 'rocky-9, driver version '.( $out =~ s/\n/,/r || 'empty' ).': no die');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... nothing changed');
  ok(warned($rec, qr/loaded driver version cannot be read/), '... warns');
}

# openSUSE: no source names a Fabric Manager -- warn, no query, no install.
{
  my $rec = installed_hgx_on('leap-15.6', '580.95.05', [ $RPM_FM_Q => '', 0 ]);
  is($rec->{error}, undef, 'leap-15.6 installed driver + NVSwitch: no die');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... nothing changed');
  ok(warned($rec, qr/no driver source Rex::GPU knows .* has a Fabric Manager package/), '... warns');
}

# Offered, but the install does not verify -> dies (the host was changed);
# the driver stays untouched.
{
  my $rec = installed_hgx_on('rocky-9', '580.95.05',
    [ 'rpm -q nvidia-fabricmanager 2>&1' => 'package nvidia-fabricmanager is not installed', 1 ],
    @{ $RETROFIT{'rocky-9'}{available} });
  like($rec->{error}, qr/nvidia-fabricmanager not installed after dnf install/, 'rocky-9: failed retrofit dies');
  ok(!(grep { /systemctl (?:enable|start)/ } @{ $rec->{lines} }), '... unit neither enabled nor started');
}

# Not active afterwards: warns, as before.
{
  my $rec = installed_hgx_on('ubuntu-24.04', '580.95.05', @{ $RETROFIT{'ubuntu-24.04'}{unavailable} },
    [ 'systemctl is-active --quiet nvidia-fabricmanager.service' => '', 3 ]);
  ok(warned($rec, qr/is not active/), 'installed driver, no FM: is-active warning');
}

#### Fabric Manager failure paths (karr #64)
#
# CLAIM: each one names what failed and installs no package it was not
# already installing -- never a driver package, never a second Fabric
# Manager, never another version.

# Retrofit: installed and verified, but the unit cannot be enabled -> dies
# (the host was changed), the unit is not started, the driver untouched.
{
  my $rec = installed_hgx_on('rocky-9', '580.95.05',
    [ 'systemctl enable nvidia-fabricmanager.service' => 'Failed to enable unit: Unit file nvidia-fabricmanager.service does not exist.', 1 ],
    @{ $RETROFIT{'rocky-9'}{available} });
  is($rec->{error}, 'systemctl enable nvidia-fabricmanager.service failed after installing '
    .'nvidia-fabricmanager 580.95.05; the driver is unchanged', 'retrofit, enable fails: dies');
  is_deeply([ installs($rec) ], [ 'run: dnf install -y nvidia-fabricmanager-580.95.05' ],
    '... the one Fabric Manager install, nothing else');
  ok(!(grep { /systemctl start/ } @{ $rec->{lines} }), '... unit not started');
}

# nvidia-smi --query-gpu exits non-zero: its output is not trusted, even a
# version-shaped one -- warn, nothing touched.
{
  my $rec = hgx_on(host_profile('rocky-9', responses => [
    working_driver(), [ $DRIVER_VERSION_Q => '580.95.05', 9 ], @{ $RETROFIT{'rocky-9'}{available} } ]));
  is($rec->{error}, undef, 'rocky-9, --query-gpu exit 9: no die');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... nothing changed');
  ok(!(grep { /dnf -q list/ } @{ $rec->{lines} }), '... no package source asked');
  ok(warned($rec, qr/loaded driver version cannot be read/), '... warns');
}

# A Fabric Manager dpkg lists without a version: "unknown", left alone.
{
  my $rec = installed_hgx_on('ubuntu-24.04', '580.95.05',
    [ $DPKG_FM_Q => 'nvidia-fabricmanager-580 iU', 0 ]);
  is($rec->{error}, undef, 'ubuntu, FM without a version: no die');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... nothing changed');
  ok(warned($rec, qr/Fabric Manager nvidia-fabricmanager-580 unknown is installed, but the loaded NVIDIA driver is 580\.95\.05/),
    '... warns, version unknown');
}

# apt: the simulated install fails -> that is the reason, no install.
{
  my $rec = installed_hgx_on('ubuntu-24.04', '580.95.05',
    [ qr{^LC_ALL=C apt-get .* -s install nvidia-fabricmanager-580=} =>
        "E: Unable to correct problems, you have held broken packages.", 100 ],
    @{ $RETROFIT{'ubuntu-24.04'}{available} });
  is($rec->{error}, undef, 'ubuntu, apt-get -s fails: no die');
  is_deeply([ installs($rec) ], [], '... nothing installed');
  ok(warned($rec, qr/\(apt-get -s install nvidia-fabricmanager-580=580\.95\.05-0ubuntu0\.24\.04\.1 fails\)/),
    '... warns naming the failed simulation');
}

# A source without fabric_manager_match (a subclass's): dies before any
# host interaction, on both packaging layers.
for my $class (qw( Rex::GPU::NVIDIA::Setup::Ubuntu Rex::GPU::NVIDIA::Setup::RHEL )) {
  my $rec = record_host(host => host_profile($class =~ /Ubuntu/ ? 'ubuntu-24.04' : 'rocky-9'),
    code => sub { $class->new->install_fabric_manager({ source => { fabric_manager => 'nvidia-fabricmanager' } }) });
  is($rec->{error}, 'The driver source names no package to read the driver version from '
    .'(fabric_manager_match); the driver is installed, Fabric Manager is not',
    "$class, no fabric_manager_match: dies");
  is_deeply($rec->{lines}, [], '... before any host interaction');
}

# apt: Fabric Manager installed, but dpkg reports another upstream version
# -> dies naming both, before post_install, no second install.
{
  my $rec = hgx_on(host_profile('ubuntu-24.04', responses => [
    [ q{dpkg-query -W -f='${Version}' nvidia-fabricmanager-590 2>/dev/null} => '590.48.02-0ubuntu0.24.04.1', 0 ],
    @UBUNTU_FM ]));
  is($rec->{error}, "nvidia-fabricmanager-590 is 590.48.02 after apt-get install, not the driver's 590.48.01",
    'ubuntu: Fabric Manager of another version after install dies');
  is(scalar(grep { /install -y nvidia-fabricmanager/ } @{ $rec->{lines} }), 1, '... one Fabric Manager install');
  ok(!(grep { /blacklist-nouveau|systemctl enable/ } @{ $rec->{lines} }), '... not enabled, before post_install');
}

is_deeply([ Rex::GPU::NVIDIA::Setup::RHEL->_dnf_list_versions(
  "Available Packages\nnvidia-fabricmanager.x86_64  3:580.95.05-1.el9  cuda\n"
  ."nvidia-fabricmanager-devel.x86_64  580.95.05-1  cuda\n", 'nvidia-fabricmanager') ],
  [ '580.95.05' ], 'dnf list: epoch and release stripped, other packages ignored');
ok(Rex::GPU::NVIDIA::Setup->_is_fabric_manager_name($_), "$_ is a Fabric Manager")
  for qw( nvidia-fabricmanager nvidia-fabricmanager-580 nvidia-fabric-manager );
ok(!Rex::GPU::NVIDIA::Setup->_is_fabric_manager_name($_), "$_ is not")
  for qw( nvidia-fabricmanager-dev-580 libnvidia-nscq-580 nvidia-fabricmanager-devel );

#### Setup unit bits

is(Rex::GPU::NVIDIA::Setup::Apt->_dpkg_upstream_version('1:580.95.05-0ubuntu1'), '580.95.05', 'epoch + revision stripped');
is(Rex::GPU::NVIDIA::Setup::Apt->_dpkg_upstream_version(''), undef, 'empty => undef');
is(Rex::GPU::NVIDIA::Setup->_is_driver_version('580.95.05'), 1, '580.95.05 is a driver version');
is(Rex::GPU::NVIDIA::Setup->_is_driver_version('package nvidia-driver is not installed'), 0, 'rpm error is not');
is(Rex::GPU::NVIDIA::Setup->fabric_manager_package({ fabric_manager => 'nvidia-fabricmanager-%s', branch_at_least => 580 }),
  undef, 'no exact branch => no package name');

{
  my $setup = Rex::GPU::NVIDIA::Setup::Ubuntu->new;
  $setup->adopt(nvswitches => $NVSW);
  ok($setup->fabric_manager_needed, 'adopt hands NVSwitches to an object without any');
  eval { Rex::GPU::NVIDIA::Setup->new(nvswitches => {}) };
  like($@, qr/nvswitches must be an arrayref/, 'new: nvswitches must be an arrayref');
}

done_testing;
