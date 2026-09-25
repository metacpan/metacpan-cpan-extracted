use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# NVLink platforms by GPU device ID (karr #49) and the HGX B200/B300 NVLink
# fabric set up with the driver (karr #56).
#
# CLAIMS:
#   * Setup->nvlink_platforms maps the GPUs' device IDs, and nothing else:
#     B200 2901/2909 and B300 3182 => hgx-nvlink5, GB200 2941 and GB300
#     31c2/31c3 => nvl72, each platform once however many GPUs; H100, RTX
#     5090, no GPU => nothing. A subclass can override the ID list.
#     nvlink_fabric_needed (and so fabric_manager_needed) only for
#     hgx-nvlink5;
#   * `nvidia-smi -q` Fabric sections parse per GPU; the fabric counts as up
#     only when every GPU (at least as many as were passed) reports
#     Completed / Success;
#   * the kernel warning fires below 5.17 only, never on the RHEL family,
#     and on an unreadable version;
#   * fresh install on an HGX B200/B300 (goldens): the k23 Fabric Manager
#     path runs (Ubuntu's nvidia-fabricmanager-NNN, CUDA repo
#     nvidia-fabricmanager on Debian/RHEL, at the driver's exact version),
#     then nvlsm + infiniband-diags + libibumad(3) (+ Ubuntu
#     linux-modules-extra-$kernel) unversioned through apt-get/dnf and
#     verified with dpkg/rpm, then ib_umad persisted and loaded, all before
#     the nouveau blacklist; install_driver starts Fabric Manager after
#     modprobe and reads the Fabric State last;
#   * Ubuntu: NVIDIA's CUDA repo is added only after the driver and Fabric
#     Manager are verified (the driver search ran without it), the
#     cuda-keyring package is NOT installed (its pin 600 would prefer
#     NVIDIA's packages), the -1 / nvlsm-500 pin is written before the
#     source; a host with cuda-keyring installed gets no pin or source;
#   * no known nvlsm source (Ubuntu 26.04, arm64, RHEL 8) dies in plan with
#     read-only commands only; openSUSE dies there for the missing Fabric
#     Manager source; a failed key fetch or an nvlsm not ii dies after the
#     driver, naming it;
#   * the Fabric State check polls while Fabric Manager is active, warns
#     loudly once when the fabric is not up, and never dies;
#   * already-installed driver: the missing fabric packages come from the
#     host's own sources only (no source added), a still-missing one only
#     warns; a complete host is read-only;
#   * GB200: only the nvidia-imex info line; H100 without nvswitches: none
#     of this.
#
# NOT covered -- none of it runs without a real HGX B200/B300: that
# 2901/2909/3182 are the IDs lspci reports there, that the repositories carry
# these package names at install time, that apt honours the pin as described
# on a real Ubuntu host, that the tar path inside cuda-keyring stays the same,
# that ib_umad loads from linux-modules-extra, that nvidia-fabricmanager.service
# starts nvlsm and the GPUs reach Fabric State Completed, and what nvidia-smi
# -q prints on those hosts beyond NVIDIA's documented Fabric block.
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw(
  record_host golden_is host_profile gpu_fixture mutating_lines working_driver
);
use Rex::GPU::NVIDIA;
use Rex::GPU::NVIDIA::Setup;
use Rex::GPU::NVIDIA::Setup::RHEL;
use Rex::GPU::NVIDIA::Setup::Ubuntu;

my $IS_ACTIVE  = 'systemctl is-active --quiet nvidia-fabricmanager.service';
my $SMI_Q      = 'nvidia-smi -q 2>&1';
my $KEYRING_Q  = q{dpkg -l cuda-keyring 2>/dev/null | grep -q '^ii'};
my $FABRIC_BAD = qr/^HGX B200\/B300: the NVLink fabric is not up/;
my $KERNEL_RE  = qr/^HGX B200\/B300: kernel \S+ is older than 5\.17/;
my $IMEX_RE    = qr/^GB200\/GB300 NVL72 compute tray: multi-node NVLink needs nvidia-imex/;

# `nvidia-smi -q` as NVIDIA's Fabric Manager guide shows the block, one per
# GPU, with the fields newer drivers add after it.
sub smi_q {
  my ( @states ) = @_;
  my $i = 0;
  return join("\n", map {
    my ( $state, $status ) = @$_;
    sprintf("GPU 00000000:%02X:00.0\n    Product Name                          : NVIDIA B200\n"
      ."    Fabric\n        State                             : %s\n"
      ."        Status                            : %s\n        CliqueId                          : 0\n"
      ."        Health\n            Bandwidth                     : Full\n"
      ."    Performance State                     : P0", 0x18 + $i++, $state, $status)
  } @states);
}

my $UP = smi_q(( [ 'Completed', 'Success' ] ) x 8);

# The Fabric Manager answers of t/93 for the driver branch each profile's
# apt-cache search finds (24.04: 590, 22.04: 580).
my %FM = (
  'ubuntu-24.04' => [
    [ q{dpkg-query -W -f='${Version}' nvidia-driver-590-server-open 2>/dev/null} => '590.48.01-0ubuntu0.24.04.1', 0 ],
    [ q{dpkg-query -W -f='${Version}' nvidia-fabricmanager-590 2>/dev/null} => '590.48.01-0ubuntu0.24.04.1', 0 ],
    [ 'apt-cache madison nvidia-fabricmanager-590 2>/dev/null' =>
        " nvidia-fabricmanager-590 | 590.48.01-0ubuntu0.24.04.1 | http://archive.ubuntu.com/ubuntu noble-updates/multiverse amd64 Packages", 0 ]
  ],
  'ubuntu-22.04' => [
    [ q{dpkg-query -W -f='${Version}' nvidia-driver-580-server-open 2>/dev/null} => '580.95.05-0ubuntu0.22.04.1', 0 ],
    [ q{dpkg-query -W -f='${Version}' nvidia-fabricmanager-580 2>/dev/null} => '580.95.05-0ubuntu0.22.04.1', 0 ],
    [ 'apt-cache madison nvidia-fabricmanager-580 2>/dev/null' =>
        " nvidia-fabricmanager-580 | 580.95.05-0ubuntu0.22.04.1 | http://archive.ubuntu.com/ubuntu jammy-updates/multiverse amd64 Packages", 0 ]
  ],
  'debian-12' => [
    [ 'LC_ALL=C apt-cache policy nvidia-fabricmanager 2>/dev/null' =>
        "nvidia-fabricmanager:\n  Installed: (none)\n  Candidate: 615.71.09-1\n", 0 ],
    [ q{dpkg-query -W -f='${Version}' nvidia-kernel-open-dkms 2>/dev/null} => '615.71.09-1', 0 ],
    [ q{dpkg-query -W -f='${Version}' nvidia-fabricmanager 2>/dev/null} => '615.71.09-1', 0 ],
    [ 'apt-cache madison nvidia-fabricmanager 2>/dev/null' =>
        " nvidia-fabricmanager | 615.71.09-1 | https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64  Packages", 0 ]
  ],
  'rocky-9' => [ [ q{rpm -q --qf '%{VERSION}' nvidia-fabricmanager 2>&1} => '580.95.05', 0 ] ],
  'rhel-9'  => [ [ q{rpm -q --qf '%{VERSION}' nvidia-fabricmanager 2>&1} => '580.95.05', 0 ] ]
);

# A fresh HGX host: no cuda-keyring on Ubuntu (Debian installs it itself and
# the harness answers its dpkg check with ii), Fabric Manager active after
# the start, the fabric up.
sub hgx_host {
  my ( $os, %opt ) = @_;
  my @keyring = $os =~ /^ubuntu/ ? ( [ $KEYRING_Q => '', 1 ] ) : ();
  return host_profile($os, ( map { $_ => $opt{$_} } grep { $_ ne 'responses' } keys %opt ),
    responses => [
      @{ $opt{responses} // [] },
      @{ $FM{$os} // [] },
      @keyring,
      [ $SMI_Q     => $UP, 0 ],
      [ $IS_ACTIVE => '', 0 ]
    ]);
}

sub platforms_of {
  my ( @ids ) = @_;
  return [ Rex::GPU::NVIDIA::Setup->new(gpus => [ map { { device_id => $_ } } @ids ])->nvlink_platforms ];
}

sub driver {
  my ( $host, @gpus ) = @_;
  return record_host(host => $host, code => sub { Rex::GPU::NVIDIA::install_driver(gpus => [ @gpus ]) });
}

sub driver_with {
  my ( $host, $setup, @gpus ) = @_;
  return record_host(host => $host,
    code => sub { Rex::GPU::NVIDIA::install_driver(gpus => [ @gpus ], setup => $setup) });
}

sub logs_like {
  my ( $rec, $re ) = @_;
  return [ grep { $_->[1] =~ $re } @{ $rec->{logs} } ];
}

sub index_of {
  my ( $lines, $re ) = @_;
  my ( $i ) = grep { $lines->[$_] =~ $re } 0 .. $#$lines;
  return $i;
}

my @B200 = ( gpu_fixture('b200') ) x 8;

#### Pure mapping

subtest 'nvlink_platforms by device ID' => sub {
  is_deeply(platforms_of(('2901') x 8), [ 'hgx-nvlink5' ], '8x B200 2901: hgx-nvlink5 once');
  is_deeply(platforms_of('2909'), [ 'hgx-nvlink5' ], 'B200 2909');
  is_deeply(platforms_of('3182'), [ 'hgx-nvlink5' ], 'B300 3182');
  is_deeply(platforms_of('2941'), [ 'nvl72' ], 'GB200 2941');
  is_deeply(platforms_of('31C2', '31c3'), [ 'nvl72' ], 'GB300 31C2/31c3, any case');
  is_deeply(platforms_of('2330'), [], 'H100: none');
  is_deeply(platforms_of('2b85'), [], 'RTX 5090 (Blackwell, not HGX): none');
  is_deeply(platforms_of(undef), [], 'no device_id: none');
  is_deeply(platforms_of(), [], 'no GPU: none');
  is_deeply(
    [ Rex::GPU::NVIDIA::Setup->new(gpus => [ 'junk', { device_id => '2901' } ])->nvlink_platforms ],
    [ 'hgx-nvlink5' ], 'non-hashref elements are ignored');

  {
    package My::Setup::NoHGX;
    use Moo;
    extends 'Rex::GPU::NVIDIA::Setup';
    sub nvlink_platform_ids { () }
  }
  my $no = My::Setup::NoHGX->new(gpus => [ { device_id => '2901' } ]);
  is_deeply([ $no->nvlink_platforms ], [], 'a subclass overrides the ID list');
  ok(!$no->fabric_manager_needed, '... and then needs no Fabric Manager');

  my $b200 = Rex::GPU::NVIDIA::Setup->new(gpus => [ { device_id => '2901' } ]);
  ok($b200->nvlink_fabric_needed, 'B200: nvlink_fabric_needed');
  ok($b200->fabric_manager_needed, '... and fabric_manager_needed');
  is($b200->fabric_label, 'HGX B200/B300 NVLink fabric', '... labelled as such');
  for my $id (qw( 2941 2330 2b85 )) {
    my $s = Rex::GPU::NVIDIA::Setup->new(gpus => [ { device_id => $id } ]);
    ok(!$s->nvlink_fabric_needed && !$s->fabric_manager_needed, "$id: neither");
  }
  is(Rex::GPU::NVIDIA::Setup->new(nvswitches => [ {} ])->fabric_label, 'NVSwitch',
    'a host with nvswitches keeps the NVSwitch label');
};

#### Fabric State parsing

subtest '_fabric_states / _fabric_complete' => sub {
  my $S = 'Rex::GPU::NVIDIA::Setup';
  is_deeply([ $S->_fabric_states($UP) ], [ ( { state => 'Completed', status => 'Success' } ) x 8 ],
    'eight Fabric blocks, State/Status each, Health and Performance State ignored');
  ok($S->_fabric_complete(8, $S->_fabric_states($UP)), '8 of 8 Completed/Success: up');
  ok(!$S->_fabric_complete(9, $S->_fabric_states($UP)), 'fewer blocks than GPUs: not up');
  my @mixed = $S->_fabric_states(smi_q([ 'Completed', 'Success' ], [ 'In Progress', 'N/A' ]));
  is($mixed[1]{state}, 'In Progress', 'a GPU still registering');
  ok(!$S->_fabric_complete(2, @mixed), '... is not up');
  ok(!$S->_fabric_complete(1, $S->_fabric_states(smi_q([ 'Completed', 'Failure' ]))),
    'Completed with a failed Status: not up');
  is_deeply([ $S->_fabric_states("NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver") ],
    [], 'nvidia-smi without a driver: no block');
  ok(!$S->_fabric_complete(0), 'no block at all: not up, even with no GPU expected');
  is_deeply([ $S->_fabric_states("    Fabric\n        CliqueId : 0\n    State : Completed") ], [ {} ],
    'a State outside the Fabric block does not count');
};

#### Kernel warning

subtest 'warn_nvlink_kernel' => sub {
  my @logs;
  no warnings 'redefine';
  local *Rex::Logger::info = sub { push @logs, [ $_[1] // 'info', $_[0] ] };
  my $warns = sub {
    my ( $class, $kernel ) = @_;
    @logs = ();
    $class->new(kernel => $kernel)->warn_nvlink_kernel;
    return [ map { $_->[1] } grep { $_->[0] eq 'warn' } @logs ];
  };
  like($warns->('Rex::GPU::NVIDIA::Setup::Ubuntu', '5.15.0-151-generic')->[0],
    qr/kernel 5\.15\.0-151-generic is older than 5\.17.*linux-generic-hwe-22\.04/, 'Ubuntu 5.15: warns');
  is_deeply($warns->('Rex::GPU::NVIDIA::Setup::Ubuntu', '5.17.0-1-generic'), [], '5.17: quiet');
  is_deeply($warns->('Rex::GPU::NVIDIA::Setup::Ubuntu', '6.8.0-85-generic'), [], '6.8: quiet');
  is(scalar @{ $warns->('Rex::GPU::NVIDIA::Setup::Ubuntu', '4.19.0') }, 1, '4.19: warns');
  is_deeply($warns->('Rex::GPU::NVIDIA::Setup::RHEL', '5.14.0-570.12.1.el9_6.x86_64'), [],
    'RHEL family 5.14: quiet (backported, maintainer decision)');
  like($warns->('Rex::GPU::NVIDIA::Setup::Ubuntu', 'garbage')->[0], qr/cannot read the kernel version/,
    'unreadable version: warns');
};

#### Fresh install on HGX B200 / B300

for my $case (
  [ 'ubuntu-24.04', 'b200' ],
  [ 'ubuntu-22.04', 'b200' ],
  [ 'ubuntu-24.04', 'b300' ],
  [ 'debian-12',    'b200' ],
  [ 'rocky-9',      'b200' ],
  [ 'rhel-9',       'b200' ]
) {
  my ( $os, $gpu ) = @$case;
  my $rec = driver(hgx_host($os), ( gpu_fixture($gpu) ) x 8);
  is($rec->{error}, undef, "$os 8x $gpu: lives");
  golden_is($rec, "driver/$os--hgx-$gpu");
  my $l = $rec->{lines};

  my $drv    = index_of($l, qr/install -y (?:linux-headers|kernel-devel)/);
  my $fm     = index_of($l, qr/install -y nvidia-fabricmanager/);
  my $nvlsm  = index_of($l, qr/install -y nvlsm infiniband-diags libibumad/);
  my $umad   = index_of($l, qr{^file: /etc/modules-load\.d/ib_umad\.conf$});
  my $probe  = index_of($l, qr/^run: modprobe ib_umad$/);
  my $nou    = index_of($l, qr/blacklist-nouveau/);
  my $start  = index_of($l, qr/^run: systemctl start nvidia-fabricmanager\.service$/);
  ok(defined $_, "... step present") for $drv, $fm, $nvlsm, $umad, $probe, $nou, $start;
  ok($drv < $fm && $fm < $nvlsm && $nvlsm < $umad && $umad < $probe && $probe < $nou && $nou < $start,
    '... driver, Fabric Manager, nvlsm & co., ib_umad, nouveau, start -- in that order');
  like($l->[$nvlsm], qr/install -y nvlsm infiniband-diags libibumad3?(?: linux-modules-extra-\S+)?$/,
    '... nvlsm & co. unversioned');
  ok(!(grep { /nvlsm[=-]\d/ } @$l), '... no version on nvlsm');
  is($l->[-1], "run: $SMI_Q", '... the Fabric State read is the last host command');
  is(scalar(grep { $_ eq "run: $SMI_Q" } @$l), 1, '... read once: the fabric is up');
  is(scalar @{ logs_like($rec, qr/\[ok\] NVLink fabric: Fabric State Completed, Status Success on 8 GPUs/) }, 1,
    '... logged as up');
  is(scalar @{ logs_like($rec, $FABRIC_BAD) }, 0, '... no fabric warning');
  ok(!(grep { /pkg: (?:nvlsm|infiniband|libibumad|nvidia-fabric)/ } @$l), '... none of it through Rex::Pkg');

  my $kernel_warn = logs_like($rec, $KERNEL_RE);
  if ($os eq 'ubuntu-22.04') {
    is(scalar @$kernel_warn, 1, '... GA kernel 5.15: the kernel warning, once');
    is($kernel_warn->[0][0], 'warn', '... at warn level');
  }
  else {
    is(scalar @$kernel_warn, 0, '... no kernel warning');
  }

  if ($os =~ /^ubuntu-(\d+)\.(\d+)$/) {
    my $distro = "ubuntu$1$2";
    my $search = index_of($l, qr/apt-cache search/);
    my $pin    = index_of($l, qr{^file: /etc/apt/preferences\.d/rex-gpu-nvlsm\.pref mode=644$});
    my $list   = index_of($l, qr{^file: /etc/apt/sources\.list\.d/rex-gpu-nvlsm\.list mode=644$});
    my $key    = index_of($l, qr{cuda-keyring_1\.1-1_all\.deb && dpkg-deb --fsys-tarfile});
    ok(defined $pin && defined $list && defined $key, '... Ubuntu: key, pin and source written');
    ok($search < $fm && $fm < $key && $key < $pin && $pin < $list && $list < $nvlsm,
      '... after the driver search and Fabric Manager; pin before source; before nvlsm');
    is_deeply([ @$l[$pin + 1 .. $pin + 9] ], [
      "  | Explanation: Rex::GPU (HGX B200/B300): NVIDIA's CUDA repository is here for nvlsm only.",
      "  | Explanation: Nothing else is installed or upgraded from it; the NVIDIA driver stays Ubuntu's.",
      '  | Package: *',
      '  | Pin: origin developer.download.nvidia.com',
      '  | Pin-Priority: -1',
      '  | ',
      '  | Package: nvlsm',
      '  | Pin: origin developer.download.nvidia.com',
      '  | Pin-Priority: 500'
    ], '... everything of that origin at -1, nvlsm at 500');
    is($l->[$list + 1],
      "  | deb [signed-by=/usr/share/keyrings/cuda-archive-keyring.gpg] https://developer.download.nvidia.com/compute/cuda/repos/$distro/x86_64/ /",
      "... the $distro/x86_64 repository");
    like($l->[$list + 2], qr/apt-get .* update -q$/, '... then apt-get update');
    ok(!(grep { /apt-get .* install -y "\$t\/cuda-keyring\.deb"|install -y cuda-keyring/ } @$l),
      '... the cuda-keyring package (pin 600) is NOT installed');
    like($l->[$nvlsm], qr/ linux-modules-extra-\S+-generic$/, '... linux-modules-extra of the running kernel');
  }
  else {
    ok(!(grep { /rex-gpu-nvlsm/ } @$l), '... not Ubuntu: no extra source or pin');
  }
}

#### Ubuntu: cuda-keyring already installed

{
  my $rec = driver(hgx_host('ubuntu-24.04', responses => [ [ $KEYRING_Q => '', 0 ] ]), @B200);
  is($rec->{error}, undef, 'Ubuntu with cuda-keyring installed: lives');
  ok(!(grep { /rex-gpu-nvlsm|cuda-archive-keyring|install -y --no-upgrade curl/ } @{ $rec->{lines} }),
    '... no key, pin or source of our own');
  my $k = index_of($rec->{lines}, qr/^run: \Q$KEYRING_Q\E$/);
  like($rec->{lines}[$k + 1], qr/apt-get .* update -q$/, '... only apt-get update');
}

#### Dies in plan: no nvlsm source (read-only commands only)

for my $case (
  [ 'Ubuntu 26.04', 'ubuntu-24.04', { release => '26.04' }, qr/Ubuntu 22\.04 and 24\.04 \(amd64\) only, not on release '26\.04'/ ],
  [ 'Ubuntu arm64', 'ubuntu-24.04', { responses => [ [ 'dpkg --print-architecture' => 'arm64', 0 ] ] }, qr/\(arm64\)/ ],
  [ 'Rocky 8',      'rocky-9',      { release => '8.10' }, qr/RHEL 9 and 10 only, not for release 8\.10/ ]
) {
  my ( $label, $os, $over, $re ) = @$case;
  my $rec = driver(hgx_host($os, %$over), @B200);
  like($rec->{error}, qr/^HGX B200\/B300 on this .*$re.*no driver package was installed and no package source was added/s, "$label: dies");
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... after read-only commands only');
}

{
  my $rec = driver(host_profile('leap-15.6'), @B200);
  like($rec->{error}, qr/no NVIDIA Fabric Manager package for the HGX B200\/B300 NVLink fabric on this host.*No driver package was installed and no package source was added/s,
    'openSUSE: dies, no Fabric Manager source');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... after read-only commands only');
}

#### Dies after the driver: key fetch, nvlsm not installed

{
  my $rec = driver(hgx_host('ubuntu-24.04', responses => [
    [ qr/cuda-keyring_1\.1-1_all\.deb && dpkg-deb/ => '', 22 ]
  ]), @B200);
  like($rec->{error}, qr/Could not fetch the signing key of NVIDIA's CUDA repository .*the driver and Fabric Manager are installed, nvlsm is not/,
    'Ubuntu, key fetch fails: dies naming what is installed');
  ok(!(grep { /rex-gpu-nvlsm/ } @{ $rec->{lines} }), '... no pin or source written');
  ok(!(grep { /blacklist-nouveau/ } @{ $rec->{lines} }), '... stops before the nouveau step');
}

{
  my $rec = driver(hgx_host('rocky-9', responses => [ [ 'rpm -q nvlsm 2>&1' => 'package nvlsm is not installed', 1 ] ]), @B200);
  like($rec->{error}, qr/^nvlsm not installed after dnf install/, 'RHEL, nvlsm missing after dnf: dies');
  ok((grep { /install -y nvidia-fabricmanager-580\.95\.05/ } @{ $rec->{lines} }), '... after Fabric Manager went in');
}

#### Fabric State check

# A setup of our own that polls 3 times without sleeping; the default is 12
# reads 10 s apart.
{
  package My::Setup::FastPoll;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Setup::Ubuntu';
  sub fabric_state_poll { ( 3, 0 ) }
}
is_deeply([ Rex::GPU::NVIDIA::Setup->fabric_state_poll ], [ 12, 10 ], 'default poll: 12 reads, 10 s apart');

{
  my $rec = driver_with(hgx_host('ubuntu-24.04', responses => [
    [ $SMI_Q => smi_q([ 'Completed', 'Success' ], ( [ 'Not Started', 'N/A' ] ) x 7), 0 ]
  ]), 'My::Setup::FastPoll', @B200);
  is($rec->{error}, undef, 'fabric not up: lives');
  my $warn = logs_like($rec, $FABRIC_BAD);
  is(scalar @$warn, 1, '... one warning');
  is($warn->[0][0], 'warn', '... at warn level');
  like($warn->[0][1], qr/GPU 0: Completed \/ Success; GPU 1: Not Started \/ N\/A.*cudaErrorSystemNotReady.*\/var\/log\/nvlsm\.log/,
    '... naming each GPU\'s state, the CUDA error and where to look');
  is(scalar(grep { $_ eq "run: $SMI_Q" } @{ $rec->{lines} }), 3, '... after every read of the poll (Fabric Manager active)');
  is_deeply([ mutating_lines(grep { $_ eq "run: $SMI_Q" } @{ $rec->{lines} }) ], [], '... all read-only');
}

{
  my @answers = ( smi_q(( [ 'In Progress', 'N/A' ] ) x 8), $UP );
  my $rec = driver_with(hgx_host('ubuntu-24.04', responses => [
    [ $SMI_Q => sub { ( shift(@answers) // $UP, 0 ) } ]
  ]), 'My::Setup::FastPoll', @B200);
  is($rec->{error}, undef, 'fabric registering, then up: lives');
  is(scalar(grep { $_ eq "run: $SMI_Q" } @{ $rec->{lines} }), 2, '... read twice');
  is(scalar @{ logs_like($rec, $FABRIC_BAD) }, 0, '... no warning');
}

{
  my $rec = driver(hgx_host('ubuntu-24.04', responses => [
    [ $IS_ACTIVE => '', 3 ],
    [ $SMI_Q => 'No devices were found', 6 ]
  ]), @B200);
  is($rec->{error}, undef, 'Fabric Manager not active, no fabric: lives');
  is(scalar(grep { $_ eq "run: $SMI_Q" } @{ $rec->{lines} }), 1, '... one read, no polling');
  like(logs_like($rec, $FABRIC_BAD)->[0][1], qr/reports no Fabric section \(8 GPUs expected\)/, '... warns');
  like(logs_like($rec, qr/present but nvidia-fabricmanager\.service is not active/)->[0][1],
    qr/^HGX B200\/B300 NVLink fabric present/, '... and the is-active warning names the platform');
}

#### Already-installed driver

{
  # everything there: nvlsm & co. ii (harness default), ib_umad loaded, fabric up
  my $rec = driver(hgx_host('ubuntu-24.04', responses => [
    working_driver(),
    [ 'nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>&1' => join("\n", ('590.48.01') x 8), 0 ],
    [ q{dpkg-query -W -f='${Package} ${db:Status-Abbrev} ${Version}\n' 'nvidia-fabric*manager*' 2>/dev/null}
      => 'nvidia-fabricmanager-590 ii  590.48.01-0ubuntu0.24.04.1', 0 ],
    [ q{lsmod | grep -q '^ib_umad '} => '', 0 ]
  ]), @B200);
  is($rec->{error}, undef, 'already installed, fabric complete: lives');
  golden_is($rec, 'driver/ubuntu-24.04--hgx-b200--installed--complete');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... read-only');
  is(scalar @{ logs_like($rec, qr/\[ok\] NVLink fabric/) }, 1, '... fabric checked and up');
}

{
  # nvlsm not offered by the host's sources (no CUDA repo): warns only
  my $nvlsm_ii = 1;
  my $rec = driver(hgx_host('ubuntu-24.04', responses => [
    working_driver(),
    [ 'nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>&1' => join("\n", ('590.48.01') x 8), 0 ],
    [ q{dpkg-query -W -f='${Package} ${db:Status-Abbrev} ${Version}\n' 'nvidia-fabric*manager*' 2>/dev/null}
      => 'nvidia-fabricmanager-590 ii  590.48.01-0ubuntu0.24.04.1', 0 ],
    [ q{dpkg -l nvlsm 2>/dev/null | grep -q '^ii'} => '', 1 ],
    [ q{lsmod | grep -q '^ib_umad '} => '', 1 ],
    [ $IS_ACTIVE => '', 3 ],
    [ $SMI_Q => smi_q(( [ 'Not Started', 'N/A' ] ) x 8), 0 ]
  ]), @B200);
  is($rec->{error}, undef, 'already installed, nvlsm not offered: lives');
  golden_is($rec, 'driver/ubuntu-24.04--hgx-b200--installed--nvlsm-unavailable');
  my @l = @{ $rec->{lines} };
  ok(!(grep { /rex-gpu-nvlsm|cuda-keyring|cuda-archive-keyring/ } @l), '... no package source added');
  ok((grep { /install -y nvlsm$/ } @l), '... tries only the missing nvlsm, from the host\'s sources');
  like(logs_like($rec, qr/^HGX B200\/B300: nvlsm not installed/)->[0][1],
    qr/do not offer it .*No package source was added/, '... warns');
  ok((grep { $_ eq 'run: systemctl start nvidia-fabricmanager.service' } @l), '... starts Fabric Manager');
  is(scalar @{ logs_like($rec, $FABRIC_BAD) }, 1, '... and warns that the fabric is not up');
}

#### GB200 compute tray, H100

{
  my $rec = driver(host_profile('ubuntu-24.04'), ( gpu_fixture('gb200') ) x 4);
  is($rec->{error}, undef, 'GB200: lives');
  ok(!(grep { /fabricmanager|nvlsm|nvidia-smi -q/ } @{ $rec->{lines} }), '... no Fabric Manager or fabric command');
  is_deeply($rec->{lines}, driver(host_profile('ubuntu-24.04'), gpu_fixture('blackwell'))->{lines},
    '... exactly the RTX 5090 install');
  my $imex = logs_like($rec, $IMEX_RE);
  is(scalar @$imex, 1, '... the IMEX note once');
  is($imex->[0][0], 'info', '... at info level');
}

{
  my $rec = driver(host_profile('ubuntu-24.04'), ( gpu_fixture('h100') ) x 8);
  is($rec->{error}, undef, 'H100 without nvswitches: lives');
  ok(!(grep { /fabricmanager|nvlsm|nvidia-smi -q/ } @{ $rec->{lines} }), '... no Fabric Manager or fabric command');
  is(scalar @{ logs_like($rec, qr/NVLink|nvidia-imex/) }, 0, '... none of these messages');
}

done_testing;
