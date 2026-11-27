#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# sleep() is a builtin; see t/17-amd-install-driver.t. Nothing here reboots,
# but a stray reboot path must not sleep for real.
our @SLEPT;
BEGIN { *CORE::GLOBAL::sleep = sub (;$) { push @SLEPT, $_[0]; return $_[0] // 0 } }

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# Radeon GPUs (hardware row `matrix => 'radeon'`) in Rex::GPU::AMD::install_driver
# (karr k82), against a scripted host, as goldens under t/golden/amd/ and
# asserts.
#
# CLAIMS:
#   * a Radeon GPU (Navi 31, 1002:744c, gfx1100) is refused BEFORE any change,
#     for method 'dkms' and 'inbox' alike, with "Nothing was changed on the
#     host" and the literal reason, on: Debian 13 (never, no Radeon on Debian);
#     Ubuntu 24.04 GA kernel 6.8; Ubuntu 22.04 GA kernel 5.15; RHEL 9.6 (a
#     release AMD does not list); RHEL 9.8 with kernel 5.14.0-570 (the kernel
#     message naming 5.14.0-687);
#   * it is let through (method dkms, the full install transcript) on: Ubuntu
#     22.04 HWE 6.8, Ubuntu 26.04 GA 7.0 (24.04 HWE 7.0 is the existing golden
#     in t/17), RHEL 9.8 with 5.14.0-687, AlmaLinux 9.8 with 5.14.0-687;
#   * "refused before any change" is checked as: no line that mutates the host
#     (mutating_lines), and none of apt-get / dnf / systemctl / curl / gpg /
#     the signing key / the repository files / modprobe appears;
#   * a Proxmox VE host (pve-firmware) with a Radeon dies with the Proxmox
#     reason, not the Radeon one (host_unsupported is asked first);
#   * `present` comes first: a working amdgpu on Debian 13 with a Radeon is
#     answered with `present`, the state read only (golden);
#   * a mixed host, Ryzen APU (synapse, gfx1151) + Radeon, method auto:
#     Ubuntu 24.04 GA 6.8 dies with the Radeon reason and names NO way out (no
#     method => 'inbox', no gpus =>), since both GPUs would include the Radeon;
#     24.04 HWE 7.0 gets the k85 advice "Pass method => 'inbox'" unchanged;
#     22.04 HWE 6.8 dies with the APU reason plus `gpus =>` naming only the
#     Radeon (all goldens);
#   * the Instinct GPU (MI300X) is untouched: it still installs on Debian 13,
#     Ubuntu 24.04 GA 6.8, Ubuntu 22.04 GA 5.15 and RHEL 9.6;
#   * a row of your own (a Rex::GPU::AMD subclass with its own hardware_class)
#     for a Radeon product WITHOUT `matrix` is not taken for a Radeon: on
#     Debian 13 it installs, where the built-in row is refused.
#
# NOT covered -- scripted host, hand-written output (Test::RexGPU::AMD says
# which real host each canned answer imitates):
#   * that AMD's matrix lists what the code says it lists, and that the Radeon
#     table binds C<inbox> too -- the reading is this distribution's (k82), the
#     test pins the reading, not the fact;
#   * the kernels and os-release texts here are GUESSES in the shape of the
#     real ones: 6.8.0-85-generic and 5.15.0-151-generic and 7.0.0-12-generic
#     (the existing profiles), 7.0.0-42-generic (read on synapse), 6.8.0-85-generic
#     as the 22.04 HWE kernel (the HWE stack carries the 24.04 build number
#     scheme; the exact build is invented), 5.14.0-687.12.1.el9_8.x86_64 (the
#     -687 series is AMD's, the .12.1.el9_8 tail is invented), the RHEL 9.8
#     /etc/os-release (VERSION="9.8 (Plow)") and the AlmaLinux 9.8 one
#     (PRETTY_NAME without a codename -- the real one has one); the NEVRA
#     lines for kernel-devel & co. are the same guesses as in t/17;
#   * what apt/dnf/DKMS do with the install commands that go through; the
#     key/repo/dearmor shell chains are recorded and never evaluated;
#   * the hardware: no Radeon was involved, the Navi 31 state is an invented
#     node (t/17's navi31, KFD 110000).
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host golden_is mutating_lines );
use Test::RexGPU::AMD qw( amd_host amd_state gpu_synapse gpu_mi300x gpu_navi31 sequence os_kernel );
use Rex::GPU::AMD;
use Rex::GPU::AMD::Hardware;

my $STATE_CMD = Rex::GPU::AMD->state_script;

{
  package Local::FakeConn;
  sub new { bless { disconnects => 0, reconnects => 0 }, shift }
  sub disconnect { $_[0]{disconnects}++; return 1 }
  sub reconnect  { $_[0]{reconnects}++; return 1 }
}

sub masked {
  my ( $rec ) = @_;
  return { %$rec, lines => [ map { $_ eq 'run: '.$STATE_CMD ? 'run: <AMD state script>' : $_ } @{ $rec->{lines} } ] };
}

my %SLOT = (
  mi300x  => { slot => '0000:c1:00.0', class => '1200', device_id => '74a1' },
  navi31  => { slot => '0000:0a:00.0', class => '0300', device_id => '744c' },
  synapse => { slot => '0000:95:00.0', class => '0380', device_id => '1586' },
);
my %KFD = ( mi300x => 90402, navi31 => 110000, synapse => 110501 );
my %GPU = ( mi300x => \&gpu_mi300x, navi31 => \&gpu_navi31, synapse => \&gpu_synapse );

# a fresh host: amdgpu not loaded, no /dev/kfd, the devices unbound
sub fresh {
  my ( @gpu ) = @_;
  return amd_state(amdgpu => 0, kfd => 0,
    gpus => [ map { { %{ $SLOT{$_} }, driver => undef, render => undef } } @gpu ]);
}
sub working {
  my ( @gpu ) = @_;
  return amd_state(gpus => [ map { { %{ $SLOT{$_} }, kfd => $KFD{$_}, vram => 137438953472, gtt => 33535848448 } } @gpu ]);
}

sub dkms_status {
  my ( $kernel ) = @_;
  return [ qr{^dkms status -m amdgpu -k } => sequence(
    [ '', 0 ],
    [ "amdgpu/6.16.13-2255209.24.04, $kernel, x86_64: installed", 0 ]), 0 ];
}

# RHEL, the dkms packages not installed before the run, offered by the
# repositories (as t/17 rhel_packages; GUESSED NEVRA lines)
sub rhel_packages {
  my ( $kernel ) = @_;
  my @pkg = ( ( map { $_.'-'.$kernel } qw( kernel-headers kernel-devel kernel-devel-matched ) ), 'amdgpu-dkms' );
  my @r;
  for my $pkg (@pkg) {
    my $nevra = $pkg eq 'amdgpu-dkms' ? 'amdgpu-dkms-1:6.16.13-2255209.el9.noarch'
      : $pkg =~ s/-\Q$kernel\E\z/-0:$kernel/r;
    push @r,
      [ qr{^rpm -q \Q$pkg\E 2>&1$} => sequence([ 'package '.$pkg.' is not installed', 1 ], [ $pkg, 0 ]), 0 ],
      [ 'dnf -q repoquery --available '.$pkg.' 2>&1' => $nevra, 0 ];
  }
  return @r;
}

sub install {
  my ( $host, %args ) = @_;
  my $class = delete $args{class} // 'Rex::GPU::AMD';
  my $conn = Local::FakeConn->new;
  my $how;
  @SLEPT = ();
  my $rec = record_host(
    host => $host,
    subs => { 'Rex::get_current_connection' => sub { return { conn => $conn } } },
    code => sub { $how = $class->install_driver(%args) },
  );
  return ( $rec, $how );
}

sub no_pkg { my ( $rec ) = @_; return !grep { /^pkg:/ } @{ $rec->{lines} } }
sub warns  { my ( $rec ) = @_; return [ map { $_->[1] } grep { $_->[0] eq 'warn' } @{ $rec->{logs} } ] }

# What "refused before any change" means here, beyond mutating_lines: no
# package manager, no timer stop, no key download or GnuPG, no repository
# file, no modprobe, no shutdown.
sub refused_cleanly {
  my ( $rec, $label ) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  like($rec->{error}, qr/\. Nothing was changed on the host\z/, "$label: dies with \"Nothing was changed on the host\"");
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... no command that changes the host ran');
  my @bad = grep { /apt-get|dnf |systemctl|curl|gpg|rocm\.gpg|RPM-GPG-KEY|amdgpu\.list|amdgpu\.repo|modprobe amdgpu|shutdown|printf|\bmv\b/ }
    grep { $_ ne 'run: '.$STATE_CMD } @{ $rec->{lines} };
  is_deeply(\@bad, [], '... no package manager, key, repository file, modprobe or reboot in the transcript');
  ok(no_pkg($rec), '... no pkg: line');
  ok(!$rec->{trapped}, '... no unmocked Rex function reached');
}

# /etc/os-release texts that replace the profile's
my %OSREL = (
  'rhel-9.8' => join("\n", 'NAME="Red Hat Enterprise Linux"', 'VERSION="9.8 (Plow)"', 'ID="rhel"',
    'ID_LIKE="fedora"', 'VERSION_ID="9.8"', 'PRETTY_NAME="Red Hat Enterprise Linux 9.8 (Plow)"'),
  'alma-9.8' => join("\n", 'NAME="AlmaLinux"', 'VERSION="9.8"', 'ID="almalinux"',
    'ID_LIKE="rhel centos fedora"', 'VERSION_ID="9.8"', 'PRETTY_NAME="AlmaLinux 9.8"'),
);

my $K_HWE_2204 = '6.8.0-85-generic';
my $K_RHEL98   = '5.14.0-687.12.1.el9_8.x86_64';
my $K_RHEL98_OLD = '5.14.0-570.12.1.el9_6.x86_64';

# A host that is fresh (state 1) and works after the install (state 2).
#   os      Test::RexGPU::AMD profile; osrel replaces its os-release
#   gpus    names in %SLOT
sub host {
  my ( $os, %o ) = @_;
  my $kernel = $o{kernel} // os_kernel($os);
  my @gpu = @{ $o{gpus} // [ 'navi31' ] };
  return amd_host($os,
    kernel => $kernel,
    state  => $o{state} // [ fresh(@gpu), working(@gpu) ],
    module => $o{module} // 'dkms',
    responses => [
      @{ $o{responses} // [] },
      ( $o{osrel} ? [ 'cat /etc/os-release 2>/dev/null' => $OSREL{ $o{osrel} } // $o{osrel}, 0 ] : () ),
      ( $os =~ /^(?:rhel|rocky)/ ? rhel_packages($kernel) : () ),
      dkms_status($kernel),
    ]);
}

sub pve_status {
  my ( $status ) = @_;
  return [ qr{^dpkg-query -W -f='\$\{Status\}\\n' pve-firmware 2>/dev/null$} => $status, 0 ];
}

# the literal pieces of the reason; the wording is the contract being pinned
my $SUPPORTED = 'Ubuntu 26.04 (GA kernel 7.0), Ubuntu 24.04 (HWE kernel 7.0), Ubuntu 22.04 (HWE kernel 6.8), '
  .'RHEL 10.2 (kernel 6.12.0-211) and RHEL 9.8 (kernel 5.14.0-687), per the ROCm 10.1 compatibility matrix';
my $NAVI = 'AMD GPU 0000:0a:00.0 [1002:744c] (gfx1100)';
my $APU  = 'AMD GPU 0000:95:00.0 [1002:1586] (gfx1151)';

#### refused

my $U2404 = "install_driver: $NAVI: AMD (Radeon GPUs) supports Ubuntu 24.04.5 LTS with kernel 7.0 (-generic); "
  ."this host runs 6.8.0-85-generic -- $SUPPORTED. Nothing was changed on the host";
my $U2204 = "install_driver: $NAVI: AMD (Radeon GPUs) supports Ubuntu 22.04.5 LTS with kernel 6.8 (-generic); "
  ."this host runs 5.15.0-151-generic -- $SUPPORTED. Nothing was changed on the host";
my $R96 = "install_driver: $NAVI: AMD supports Radeon GPUs only on $SUPPORTED; this host runs "
  ."Red Hat Enterprise Linux 9.6 (Plow) with kernel 5.14.0-570.12.1.el9_6.x86_64. Nothing was changed on the host";
my $R98_570 = "install_driver: $NAVI: AMD supports Radeon GPUs on Red Hat Enterprise Linux 9.8 (Plow) with kernel "
  ."5.14.0-687 only; this host runs $K_RHEL98_OLD. Nothing was changed on the host";

subtest 'a Radeon GPU is refused before any change (dkms and inbox; goldens for the dkms ones)' => sub {
  my @case = (
    # [ name, golden?, error, host, method ]
    [ 'debian-13--dkms--navi31', 1,
      "install_driver: $NAVI: AMD supports Radeon GPUs only on $SUPPORTED; this host runs Debian GNU/Linux 13 (trixie) with kernel 6.12.48+deb13-amd64. Nothing was changed on the host",
      host('debian-13'), 'dkms' ],
    [ 'debian-13--inbox--navi31', 0,
      "install_driver: $NAVI: AMD supports Radeon GPUs only on $SUPPORTED; this host runs Debian GNU/Linux 13 (trixie) with kernel 6.12.48+deb13-amd64. Nothing was changed on the host",
      host('debian-13', module => 'inbox'), 'inbox' ],
    [ 'ubuntu-24.04--dkms--navi31--kernel-6.8', 1, $U2404,
      host('ubuntu-24.04'), 'dkms' ],
    [ 'ubuntu-24.04--inbox--navi31--kernel-6.8', 0, $U2404,
      host('ubuntu-24.04', module => 'inbox'), 'inbox' ],
    [ 'ubuntu-22.04--dkms--navi31--kernel-5.15', 0, $U2204,
      host('ubuntu-22.04'), 'dkms' ],
    [ 'ubuntu-22.04--inbox--navi31--kernel-5.15', 0, $U2204,
      host('ubuntu-22.04', module => 'inbox'), 'inbox' ],
    [ 'rhel-9.6--dkms--navi31', 1,
      $R96,
      host('rhel-9'), 'dkms' ],
    [ 'rhel-9.6--inbox--navi31', 0, $R96,
      host('rhel-9', module => 'inbox'), 'inbox' ],
    [ 'rhel-9.8--dkms--navi31--kernel-570', 1,
      $R98_570,
      host('rhel-9', osrel => 'rhel-9.8', kernel => $K_RHEL98_OLD), 'dkms' ],
    [ 'rhel-9.8--inbox--navi31--kernel-570', 0, $R98_570,
      host('rhel-9', osrel => 'rhel-9.8', kernel => $K_RHEL98_OLD, module => 'inbox'), 'inbox' ],
  );
  for my $c (@case) {
    my ( $name, $golden, $want, $host, $method ) = @$c;
    my ( $rec ) = install($host, gpus => [ gpu_navi31() ], method => $method);
    is($rec->{error}, $want, "$name: the literal message");
    refused_cleanly($rec, $name);
    golden_is(masked($rec), "amd/$name") if $golden;
  }
};

subtest 'the Ubuntu reasons, literally' => sub {
  my ( $rec ) = install(host('ubuntu-24.04'), gpus => [ gpu_navi31() ], method => 'dkms');
  like($rec->{error}, qr/this host runs 6\.8\.0-85-generic -- /, '24.04 GA: names the running kernel 6.8.0-85-generic');
  like($rec->{error}, qr/\bkernel 7\.0\b/, '... and the series AMD lists, 7.0');
  ( $rec ) = install(host('ubuntu-22.04'), gpus => [ gpu_navi31() ], method => 'dkms');
  like($rec->{error}, qr/this host runs 5\.15\.0-151-generic -- /, '22.04 GA: names the running kernel 5.15.0-151-generic');
  like($rec->{error}, qr/\bkernel 6\.8\b/, '... and the series AMD lists, 6.8');
  diag($rec->{error}) if $ENV{REX_GPU_TEST_VERBOSE};
};

subtest 'Proxmox VE (pve-firmware) with a Radeon: the Proxmox reason first' => sub {
  for my $method (qw( dkms inbox )) {
    my ( $rec ) = install(host('debian-13', module => $method, responses => [ pve_status('install ok installed') ]),
      gpus => [ gpu_navi31() ], method => $method);
    like($rec->{error}, qr/this is a Proxmox VE host \(pve-firmware is installed\)/, "$method: the Proxmox reason");
    unlike($rec->{error}, qr/Radeon/, '... not the Radeon one');
    refused_cleanly($rec, "$method on Proxmox");
  }
  my ( $rec ) = install(host('debian-13', responses => [ pve_status('install ok installed') ]),
    gpus => [ gpu_navi31() ], method => 'dkms');
  golden_is(masked($rec), 'amd/debian-13--dkms--navi31--proxmox');
};

#### let through

subtest 'a Radeon GPU AMD lists is let through (dkms; goldens)' => sub {
  my @case = (
    [ 'ubuntu-22.04--dkms--navi31--hwe-6.8',  host('ubuntu-22.04', kernel => $K_HWE_2204) ],
    [ 'ubuntu-26.04--dkms--navi31',           host('ubuntu-26.04') ],
    [ 'rhel-9.8--dkms--navi31',               host('rhel-9', osrel => 'rhel-9.8', kernel => $K_RHEL98) ],
    [ 'alma-9.8--dkms--navi31',               host('rhel-9', osrel => 'alma-9.8', kernel => $K_RHEL98) ],
  );
  for my $c (@case) {
    my ( $name, $host ) = @$c;
    my ( $rec, $how ) = install($host, gpus => [ gpu_navi31() ], method => 'dkms');
    is($rec->{error}, undef, "$name: lives");
    is($how, 'dkms', '... returns dkms');
    ok(no_pkg($rec), '... no pkg: line');
    my ( $install ) = grep { /^run: (?:DEBIAN_FRONTEND=noninteractive apt-get .* install|dnf install) -y / && /amdgpu-dkms/ } @{ $rec->{lines} };
    like($install, qr/ amdgpu-dkms\b/, '... the amdgpu-dkms install ran');
    golden_is(masked($rec), "amd/$name");
  }
};

#### present first

subtest 'present before Radeon: a working amdgpu on Debian 13 is answered with present, state read only (golden)' => sub {
  my $host = amd_host('debian-13', state => [ working('navi31') ], module => 'inbox');
  my ( $rec, $how ) = install($host, gpus => [ gpu_navi31() ]);
  is($rec->{error}, undef, 'lives');
  is($how, 'present', 'present');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], 'no change');
  is_deeply($rec->{lines}, [ 'run: '.$STATE_CMD ], 'the transcript is the one state read (no os-release, no uname -r)');
  golden_is(masked($rec), 'amd/debian-13--present--navi31');
};

#### mixed

subtest 'mixed Ryzen APU + Radeon, method auto (goldens)' => sub {
  my @both = ( gpu_synapse(), gpu_navi31() );
  my @mixed = (qw( synapse navi31 ));
  # 24.04 GA 6.8: the Radeon reason, no way out named
  my ( $rec ) = install(host('ubuntu-24.04', gpus => \@mixed, module => 'inbox'), gpus => \@both);
  is($rec->{error}, $U2404, '24.04 GA 6.8: the Radeon reason');
  unlike($rec->{error}, qr/inbox driver and|no way out|Pass method|Pass gpus|\Q$APU\E/, '... names no way out, not the APU');
  refused_cleanly($rec, '24.04 GA 6.8 mixed');
  golden_is(masked($rec), 'amd/ubuntu-24.04--auto--synapse-navi31--kernel-6.8');

  # 24.04 HWE 7.0: both are fine with inbox -- the k85 advice, unchanged
  ( $rec ) = install(host('ubuntu-24.04', gpus => \@mixed, kernel => '7.0.0-42-generic', module => 'inbox'), gpus => \@both);
  is($rec->{error},
    "install_driver: AMD supports $APU only with the inbox driver and $NAVI with amdgpu-dkms, and one amdgpu drives every GPU of a host. "
    ."Pass method => 'inbox' to drive all of them with the inbox driver. Nothing was changed on the host",
    '24.04 HWE 7.0: dies with the k85 advice (method => inbox)');
  unlike($rec->{error}, qr/Radeon/, '... no Radeon reason');
  refused_cleanly($rec, '24.04 HWE 7.0 mixed');
  golden_is(masked($rec), 'amd/ubuntu-24.04--auto--synapse-navi31--kernel-7.0');

  # 22.04 HWE 6.8: the APU is not supported (inbox), the Radeon is
  ( $rec ) = install(host('ubuntu-22.04', gpus => \@mixed, kernel => $K_HWE_2204, module => 'inbox'), gpus => \@both);
  like($rec->{error}, qr/\Ainstall_driver: AMD supports \Q$APU\E only with the inbox driver and \Q$NAVI\E with amdgpu-dkms, and one amdgpu drives every GPU of a host\. method => 'inbox' is no way out on this host for \Q$APU\E: /,
    '22.04 HWE 6.8: the APU reason, inbox is no way out');
  like($rec->{error}, qr/ Pass gpus => with \Q$NAVI\E only to leave \Q$APU\E out\. Nothing was changed on the host\z/,
    '... and gpus => with the Radeon only');
  unlike($rec->{error}, qr/Radeon/, '... no Radeon reason: the Radeon is fine here');
  refused_cleanly($rec, '22.04 HWE 6.8 mixed');
  golden_is(masked($rec), 'amd/ubuntu-22.04--auto--synapse-navi31--hwe-6.8');
};

#### Instinct is untouched

subtest 'Instinct (MI300X) is not touched by the Radeon check' => sub {
  my @case = (
    [ 'debian-13',    host('debian-13',    gpus => ['mi300x']) ],
    [ 'ubuntu-24.04 GA 6.8',  host('ubuntu-24.04', gpus => ['mi300x']) ],
    [ 'ubuntu-22.04 GA 5.15', host('ubuntu-22.04', gpus => ['mi300x']) ],
    [ 'rhel-9.6',     host('rhel-9',       gpus => ['mi300x']) ],
  );
  for my $c (@case) {
    my ( $name, $host ) = @$c;
    my ( $rec, $how ) = install($host, gpus => [ gpu_mi300x() ], method => 'dkms');
    is($rec->{error}, undef, "$name: lives");
    is($how, 'dkms', '... dkms');
    unlike(join("\n", @{ warns($rec) }), qr/Radeon/, '... no word about Radeon');
  }
};

#### a row of your own

{
  package Local::HW::NoMatrix;
  our @ISA = ('Rex::GPU::AMD::Hardware');
  # the Navi 31 as a row of your own: compute 1, dkms, but no `matrix`
  sub targets {
    return ( { gfx_target => 'gfx1100', compute => 1, integrated => 0, driver => 'dkms', family => 'RDNA 3 (own row)' } );
  }
  package Local::AMD::NoMatrix;
  our @ISA = ('Rex::GPU::AMD');
  sub hardware_class { 'Local::HW::NoMatrix' }
}

subtest 'a subclass row with compute 1 and a Radeon product but no matrix is let through' => sub {
  # the built-in row is refused on this very host ...
  my ( $rec ) = install(host('debian-13'), gpus => [ gpu_navi31() ], method => 'dkms');
  like($rec->{error}, qr/AMD supports Radeon GPUs only on/, 'built-in row, Debian 13: refused');
  # ... a row of your own without `matrix` is not guessed to be a Radeon
  my $how;
  ( $rec, $how ) = install(host('debian-13'), class => 'Local::AMD::NoMatrix', gpus => [ gpu_navi31() ], method => 'dkms');
  is($rec->{error}, undef, 'own row without matrix, Debian 13: lives');
  is($how, 'dkms', '... returns dkms');
  ok(( grep { /apt-get .* install -y .*amdgpu-dkms/ } @{ $rec->{lines} } ), '... the amdgpu-dkms install ran');
  ok(no_pkg($rec), '... no pkg: line');
  unlike(join("\n", @{ warns($rec) }), qr/Radeon/, '... no Radeon warning');
};

done_testing;
