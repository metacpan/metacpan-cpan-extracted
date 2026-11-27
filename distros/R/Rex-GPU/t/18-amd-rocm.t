#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# Rex::GPU::AMD::install_rocm (karr k1), against a scripted host. ROCm is the
# optional host userspace; gpu_setup never calls it.
#
# CLAIMS:
#   * the install on Ubuntu 24.04 (gfx1151, HWE kernel 7.0.0-42-generic) and on
#     Debian 13 (gfx942; the matrix lists gfx1151 only on Ubuntu, see k91 below)
#     emits exactly the commands in t/golden/amd/<os>--rocm-10.1--<gfx>.txt: the repository key checked
#     against AMD's pinned fingerprint before apt trusts it, the repository
#     file (printf + mv), apt-get update, ONE direct `apt-get install` of the
#     extra packages and amdrocm10.1-<gfx target>, verified by `dpkg -l` and a
#     version check -- never Rex::Pkg (no `pkg:` line);
#   * the targets come from `targets =>`, from each of `gpus =>` (their
#     gfx_target) or from the KFD nodes of the running driver; duplicates
#     collapse; `present` (nothing changed beyond reads) when every package is
#     installed at the release;
#   * an older ROCm line on the host (rocm-core 7.2.4) is REFUSED: dies, the
#     transcript has no mutating command, nothing is uninstalled;
#   * these die before anything is changed and, but for the OS/arch/ROCm-line
#     checks, before any command: a missing or unknown release, gpus together
#     with targets, gpus => [], a GPU without a gfx_target, a target AMD ships
#     no package for (gfx906), no target at all, an unknown option; and, after
#     only read-only commands: a non-apt OS (RHEL), an unsupported OS, a
#     foreign repository file, a non-amd64 host;
#   * Proxmox VE (k88; Debian 13 + pve-firmware on disk, kernel 7.0.14-20-pve)
#     is NOT refused for an Instinct target (gfx942; since k91 a Ryzen APU or
#     Radeon target is refused on any Debian, Proxmox included): install_rocm
#     runs the same commands as on plain Debian 13 (golden
#     amd/debian-13--rocm-10.1--gfx942--proxmox, moved from ...--gfx1151--...),
#     installs only libatomic1 libquadmath0 amdrocm10.1-<gfx>, no firmware-*
#     package, no `pkg:` line, never asks for pve-firmware, result `installed`.
#     Pins EXISTING behavior (green against the code before k88 too);
#   * a signing key that is not the pinned one dies; a package installed at
#     another version than the release dies after the install;
#   * the dpkg state counts (k89), by maintainer decision:
#       - rocm-core in ANY state but not-installed and config-files is the old
#         line and dies before any change: held (`hold ok installed`),
#         `install ok unpacked`, `install ok half-configured`, `install
#         reinstreq half-installed`; `deinstall ok config-files` (rc) and
#         `unknown ok not-installed` do not die (the install runs);
#       - `present` needs every target package installed AND configured at the
#         release, held (`hold ok installed`) or not: only read-only commands;
#         an unpacked, half-configured or half-installed one is not present
#         (the install runs);
#       - after the install a held package (`hi` in dpkg -l) passes
#         verify_packages and the version check; a half-configured one (`iF`)
#         dies. The host answers `grep -q '^ii'` and `grep -q '^[hi]i'` as the
#         real grep would (dpkg_l), so these fail against the code before k89
#         for the rating, not for a missing mock line.
#   * AMD's compatibility matrix binds install_rocm as it binds install_driver
#     (k91; Setup::check_rocm_matrix, asked after `present`, before the
#     repository file and any change). Per gfx target (from targets, gpus or
#     the KFD nodes alike): matrix 'radeon' (gfx1100 ...) needs Ubuntu 26.04 /
#     24.04 with a 7.0 -generic kernel or 22.04 with 6.8, no Debian; matrix
#     'ryzen' (gfx1151 ...) needs Ubuntu 26.04 / 24.04 with 7.0, no 22.04, no
#     Debian. Off the matrix: dies "install_rocm: AMD's ROCm compatibility
#     matrix does not list <targets> ... Nothing was changed on the host" after
#     read-only commands only (golden amd/debian-13--rocm-10.1--gfx1151 is that
#     refusal), the Radeon targets named before the Ryzen ones;
#   * the k91 controls: an Instinct target (gfx942) is not checked and `uname -r`
#     is never run for it; an already `present` install of an off-matrix target
#     stays `present`; a target without `matrix` (gfx1010 compute 0, gfx1250 no
#     row) and a subclass's own hardware_class are followed; the old rocm-core
#     refusal comes before the matrix, the matrix before the foreign repository
#     file (which is then not even read).
#
# NOT covered -- scripted host, hand-written output:
#   * k91: which kernels AMD's matrix really lists, and whether ROCm runs on
#     them -- the rows are the maintainer's reading of the ROCm 10.1 matrix in
#     Setup::Ubuntu; every kernel string but 7.0.0-42-generic (synapse) is
#     invented in its shape (6.8.0-85-generic, 5.15.0-151-generic,
#     7.0.0-12-generic, 6.14.0-1015-oem, 7.0.0-1005-oem, 7.0.14-20-pve); a
#     real HWE/OEM/Proxmox kernel name may differ;
#   * whether stable.repo.amd.com serves those package names and versions
#     (amdrocm10.1-gfx1151 at "10.1.0-..."; the version strings are invented
#     in shape), whether the key it serves is the pinned one, whether ROCm
#     then runs on the GPU;
#   * the shell behaviour of the key pipeline, printf quoting and dpkg-query
#     format string (recorded, never evaluated);
#   * Proxmox: that apt resolves those packages on a real PVE 9.2 (the Hub
#     read `apt-get -s`: 0 Remv, no firmware-* package -- a live finding, not
#     reproduced here), that ROCm then runs on the -pve kernel; the host
#     answers (pve-firmware `install ok installed`, kernel 7.0.14-20-pve) are
#     hand-written in the shape of t/17's pve_status;
#   * RHEL: install_rocm is refused there; no rpm path exists to test.
#   * the k89 states: the dpkg-query / `dpkg -l` answers for held, unpacked,
#     half-configured and half-installed packages are hand-written in dpkg's
#     documented format, not captured; the `grep` in `dpkg -l PKG | grep -q
#     '^[hi]i'` is never evaluated by a shell here (dpkg_l scripts what it
#     would answer); the cases `un`, `ri`, `hF` etc. beyond those named above
#     are not each tested; not a real dpkg on a held or interrupted host.
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host golden_is mutating_lines );
use Test::RexGPU::AMD qw( amd_host amd_state gpu_synapse gpu_mi300x gpu_navi31 sequence dpkg_l );
use Rex::GPU::AMD;

my $STATE_CMD = Rex::GPU::AMD->state_script;
my $ROCM_KEY  = 'D0F004A0025A1145C7807FCD0701EAC4D5E02107';
my $QUERY     = qr{^dpkg-query -W -f='};

sub masked {
  my ( $rec ) = @_;
  return { %$rec, lines => [ map { $_ eq 'run: '.$STATE_CMD ? 'run: <AMD state script>' : $_ } @{ $rec->{lines} } ] };
}
sub no_pkg { my ( $rec ) = @_; return !grep { /^pkg:/ } @{ $rec->{lines} } }

sub rocm {
  my ( $host, %args ) = @_;
  my $class = delete $args{class};
  my $how;
  my $rec = record_host(host => $host, code => sub {
    $how = $class ? $class->install_rocm(%args) : Rex::GPU::AMD::install_rocm(%args) });
  return ( $rec, $how );
}

# k91: AMD's matrix lists the Ryzen APU (gfx1151) on Ubuntu 24.04 only with the
# HWE kernel 7.0. 7.0.0-42-generic is the one kernel string of these fixtures
# read from a real host (synapse, 2026-10-31; see Test::RexGPU::AMD); the
# 6.8.0-85-generic default of amd_host('ubuntu-24.04') is invented in its shape
# and is a host the matrix does not list that target for.
my $HWE = '7.0.0-42-generic';

# the dpkg-query answers: nothing installed before, the packages at $version after
sub rocm_host {
  my ( $os, %o ) = @_;
  my @pkgs = @{ $o{packages} // [ 'amdrocm10.1-gfx1151' ] };
  my %kernel = $os eq 'ubuntu-24.04' ? ( kernel => $HWE ) : ();
  my $after = join "\n", map { "$_ install ok installed ".( $o{version} // '10.1.0-35' ) } @pkgs;
  return amd_host($os, key => $ROCM_KEY, state => $o{state}, %kernel, %{ $o{host} // {} },
    responses => [ @{ $o{responses} // [] },
      [ $QUERY => sequence([ $o{before} // '', 0 ], [ $after, 0 ]), 0 ] ]);
}

#### installs (goldens)

subtest 'install on Ubuntu 24.04 (gfx1151, HWE 7.0) and Debian 13 (gfx942) (goldens)' => sub {
  # Debian 13 takes an Instinct target: AMD's matrix lists the Ryzen APU gfx1151
  # only on Ubuntu (k91, below), so the Debian 13 install is pinned with gfx942.
  for my $c ([ 'ubuntu-24.04', 'ubuntu2404', 'gfx1151' ], [ 'debian-13', 'debian13', 'gfx942' ]) {
    my ( $os, $dir, $gfx ) = @$c;
    my ( $rec, $how ) = rocm(rocm_host($os, packages => [ "amdrocm10.1-$gfx" ]), release => '10.1', targets => [ $gfx ]);
    is($rec->{error}, undef, "$os: lives");
    is($how, 'installed', '... installed');
    ok(no_pkg($rec), '... no Rex::Pkg call');
    my ( $install ) = grep { /apt-get .* install / } @{ $rec->{lines} };
    like($install, qr/ install -y libatomic1 libquadmath0 amdrocm10\.1-\Q$gfx\E\z/, '... one direct install: the extras, then the target package');
    ok(( grep { /> \/etc\/apt\/sources\.list\.d\/amdrocm-stable\.sources\.tmp/ && /URIs: https:\/\/stable\.repo\.amd\.com\/rocm\/core\/packages\/\Q$dir\E\// } @{ $rec->{lines} }),
      "... the repository file points at the $dir directory");
    my ( $key ) = grep { /^run: mkdir .*curl -fsSL --proto =https https:\/\/stable\.repo\.amd\.com\/rocm\/gpg\/packages\.gpg / } @{ $rec->{lines} };
    ok($key, '... the key is fetched over https');
    my ( $at_key ) = grep { $rec->{lines}[$_] =~ /gpg --batch --with-colons --show-keys/ } 0 .. $#{ $rec->{lines} };
    my ( $at_install ) = grep { $rec->{lines}[$_] =~ /apt-get .* install / } 0 .. $#{ $rec->{lines} };
    ok($at_key < $at_install, '... and its fingerprint is read before anything is installed');
    golden_is(masked($rec), "amd/$os--rocm-10.1--$gfx");
  }
};

subtest 'Proxmox VE is not refused for an Instinct target: the Debian 13 commands, no firmware package (k88, golden)' => sub {
  # k88's claim, kept for the targets the matrix does not bind to Ubuntu
  # (Instinct); a Ryzen APU or Radeon target on Proxmox is refused (k91, below).
  my $pve = [ qr{^dpkg-query -W -f='\$\{Status\}\\n' pve-firmware 2>/dev/null$} => 'install ok installed', 0 ];
  my %o = ( packages => [ 'amdrocm10.1-gfx942' ] );
  my ( $rec, $how ) = rocm(rocm_host('debian-13', %o, host => { kernel => '7.0.14-20-pve', responses => [ $pve ] }),
    release => '10.1', targets => [ 'gfx942' ]);
  is($rec->{error}, undef, 'lives (no Proxmox refusal)');
  is($how, 'installed', '... installed');
  ok(no_pkg($rec), '... no Rex::Pkg call');
  ok(!$rec->{trapped}, '... no unmocked Rex function reached');
  my @install = grep { /apt-get .* install / } @{ $rec->{lines} };
  is(scalar @install, 1, '... one apt-get install');
  like($install[0], qr/ install -y libatomic1 libquadmath0 amdrocm10\.1-gfx942\z/, '... exactly the extras and the target package');
  ok(!( grep { /firmware-/ } @{ $rec->{lines} } ), '... no firmware-* package anywhere in the transcript');
  ok(!( grep { /pve-firmware/ } @{ $rec->{lines} } ), '... pve-firmware is not even asked');
  # the Debian 13 transcript with the Proxmox answers is the plain one, byte for byte
  my ( $plain ) = rocm(rocm_host('debian-13', %o), release => '10.1', targets => [ 'gfx942' ]);
  is_deeply($rec->{lines}, $plain->{lines}, '... identical to plain Debian 13');
  golden_is(masked($rec), 'amd/debian-13--rocm-10.1--gfx942--proxmox');
};

subtest 'Proxmox VE: a Ryzen APU target is refused like on any Debian (k91)' => sub {
  # the Debian answer, no Proxmox special case, and pve-firmware is still not asked
  my $pve = [ qr{^dpkg-query -W -f='\$\{Status\}\\n' pve-firmware 2>/dev/null$} => 'install ok installed', 0 ];
  my ( $rec ) = rocm(rocm_host('debian-13', host => { kernel => '7.0.14-20-pve', responses => [ $pve ] }),
    release => '10.1', targets => [ 'gfx1151' ]);
  like($rec->{error}, qr/\Ainstall_rocm: AMD's ROCm compatibility matrix does not list gfx1151 for this OS and kernel: .*7\.0\.14-20-pve\. Nothing was changed on the host\n?\z/,
    'gfx1151 on Proxmox VE: refused, naming the kernel');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... no command that changes the host');
  ok(!( grep { /pve-firmware/ } @{ $rec->{lines} } ), '... pve-firmware is not asked');
};

subtest 'targets from gpus, from the running driver, deduplicated' => sub {
  my $os = 'ubuntu-24.04';
  my ( $rec, $how ) = rocm(rocm_host($os), release => '10.1', gpus => [ gpu_synapse() ]);
  is($how, 'installed', 'gpus => [gfx1151 GPU]');
  like(( grep { /apt-get .* install / } @{ $rec->{lines} } )[0], qr/amdrocm10\.1-gfx1151\z/, '... its package');

  ( $rec, $how ) = rocm(rocm_host($os, packages => [ 'amdrocm10.1-gfx942', 'amdrocm10.1-gfx1151' ]),
    release => '10.1', gpus => [ gpu_mi300x(), gpu_synapse(), gpu_mi300x() ]);
  is($how, 'installed', 'two GPUs, one repeated');
  like(( grep { /apt-get .* install / } @{ $rec->{lines} } )[0], qr/ install -y libatomic1 libquadmath0 amdrocm10\.1-gfx942 amdrocm10\.1-gfx1151\z/,
    '... each package once, in the order given');

  ( $rec, $how ) = rocm(rocm_host($os, state => amd_state(gpus => [
      { slot => '0000:95:00.0', class => '0380', device_id => '1586', kfd => 110501 } ])),
    release => '10.1');
  is($how, 'installed', 'neither: the KFD nodes of the running driver');
  ok(( grep { $_ eq 'run: '.$STATE_CMD } @{ $rec->{lines} } ), '... via the state read');
  like(( grep { /apt-get .* install / } @{ $rec->{lines} } )[0], qr/amdrocm10\.1-gfx1151\z/, '... gfx1151 from node 110501');

  ( $rec, $how ) = rocm(rocm_host($os), release => '10.1', targets => [ 'GFX1151', 'gfx1151' ]);
  like(( grep { /apt-get .* install / } @{ $rec->{lines} } )[0], qr/ amdrocm10\.1-gfx1151\z/, 'targets are lower-cased and deduplicated');
};

subtest 'present: every package at the release, nothing changed' => sub {
  my $host = amd_host('ubuntu-24.04', responses => [
    [ $QUERY => 'amdrocm10.1-gfx1151 install ok installed 10.1.0-35', 0 ] ]);
  my ( $rec, $how ) = rocm($host, release => '10.1', targets => [ 'gfx1151' ]);
  is($rec->{error}, undef, 'lives');
  is($how, 'present', 'present');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], 'only read-only commands ran');
  ok(!( grep { /apt-get|curl|\.sources/ } @{ $rec->{lines} } ), '... no apt-get, no download, no repository file');

  # one package at the release, one not: that is not present
  $host = amd_host('ubuntu-24.04', key => $ROCM_KEY, kernel => $HWE, responses => [
    [ $QUERY => sequence(
        [ 'amdrocm10.1-gfx942 install ok installed 10.1.0-35', 0 ],
        [ "amdrocm10.1-gfx942 install ok installed 10.1.0-35\namdrocm10.1-gfx1151 install ok installed 10.1.0-35", 0 ]), 0 ] ]);
  ( $rec, $how ) = rocm($host, release => '10.1', targets => [ 'gfx942', 'gfx1151' ]);
  is($how, 'installed', 'one of two packages missing: installed');
};

subtest 'present: held target packages count as installed (k89)' => sub {
  my $host = amd_host('ubuntu-24.04', responses => [
    [ $QUERY => 'amdrocm10.1-gfx1151 hold ok installed 10.1.0-35', 0 ] ]);
  my ( $rec, $how ) = rocm($host, release => '10.1', targets => [ 'gfx1151' ]);
  is($rec->{error}, undef, 'lives');
  is($how, 'present', 'a held package at the release: present');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... only read-only commands ran');
  ok(!( grep { /apt-get|curl|\.sources/ } @{ $rec->{lines} } ), '... no apt-get, no download, no repository file');

  # held and not held, both at the release
  $host = amd_host('ubuntu-24.04', responses => [
    [ $QUERY => "amdrocm10.1-gfx942 install ok installed 10.1.0-35\namdrocm10.1-gfx1151 hold ok installed 10.1.0-35", 0 ] ]);
  ( $rec, $how ) = rocm($host, release => '10.1', targets => [ 'gfx942', 'gfx1151' ]);
  is($how, 'present', 'one held, one not: present');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... only read-only commands ran');

  # held, but at another release: not present
  $host = rocm_host('ubuntu-24.04', before => 'amdrocm10.1-gfx1151 hold ok installed 9.0.0-1');
  ( $rec, $how ) = rocm($host, release => '10.1', targets => [ 'gfx1151' ]);
  is($how, 'installed', 'held at another version: not present, installed');
};

subtest 'present: a half-installed target package is not present (k89)' => sub {
  for my $c ([ 'install ok unpacked', 'unpacked' ], [ 'install ok half-configured', 'half-configured' ],
             [ 'install reinstreq half-installed', 'half-installed' ], [ 'hold ok half-configured', 'held half-configured' ]) {
    my ( $status, $label ) = @$c;
    my ( $rec, $how ) = rocm(rocm_host('ubuntu-24.04', before => "amdrocm10.1-gfx1151 $status 10.1.0-35"),
      release => '10.1', targets => [ 'gfx1151' ]);
    is($rec->{error}, undef, "$label: lives");
    is($how, 'installed', '... not present: the install runs');
    ok(( grep { /apt-get .* install -y .*amdrocm10\.1-gfx1151\z/ } @{ $rec->{lines} } ), '... with apt-get install of the target');
  }

  # one held, one half-configured: not present
  my ( $rec, $how ) = rocm(rocm_host('ubuntu-24.04', packages => [ 'amdrocm10.1-gfx942', 'amdrocm10.1-gfx1151' ],
      before => "amdrocm10.1-gfx942 hold ok installed 10.1.0-35\namdrocm10.1-gfx1151 install ok half-configured 10.1.0-35"),
    release => '10.1', targets => [ 'gfx942', 'gfx1151' ]);
  is($how, 'installed', 'one held, one half-configured: not present');
};

subtest 'after the install: a held package passes verify, a half-configured one dies (k89)' => sub {
  # held before and after the install: dpkg -l says hi
  my ( $rec, $how ) = rocm(rocm_host('ubuntu-24.04', responses => [
      dpkg_l('amdrocm10.1-gfx1151' => 'hi'),
      [ $QUERY => sequence([ '', 0 ], [ 'amdrocm10.1-gfx1151 hold ok installed 10.1.0-35', 0 ]), 0 ] ]),
    release => '10.1', targets => [ 'gfx1151' ]);
  is($rec->{error}, undef, 'a held target package after the install: lives');
  is($how, 'installed', '... installed');
  ok(no_pkg($rec), '... verified by dpkg, not Rex::Pkg');
  ok(( grep { m{^run: dpkg -l amdrocm10\.1-gfx1151 2>/dev/null \| grep -q '\^\[hi\]i'$} } @{ $rec->{lines} } ), '... via the held-aware check');

  # a plain ii package still passes
  ( $rec, $how ) = rocm(rocm_host('ubuntu-24.04', responses => [ dpkg_l('amdrocm10.1-gfx1151' => 'ii') ]),
    release => '10.1', targets => [ 'gfx1151' ]);
  is($rec->{error}, undef, 'ii: lives');

  # half-configured (iF) after the install: both checks say no
  for my $state (qw( iF hF iU )) {
    ( $rec ) = rocm(rocm_host('ubuntu-24.04', responses => [ dpkg_l('amdrocm10.1-gfx1151' => $state) ]),
      release => '10.1', targets => [ 'gfx1151' ]);
    like($rec->{error}, qr/\Aamdrocm10\.1-gfx1151 not installed after apt-get install/, "$state: dies, naming the package");
  }

  # an extra package (libatomic1) held is fine too
  ( $rec ) = rocm(rocm_host('ubuntu-24.04', responses => [ dpkg_l('libatomic1' => 'hi') ]),
    release => '10.1', targets => [ 'gfx1151' ]);
  is($rec->{error}, undef, 'a held extra package: lives');
};

#### refusals

subtest 'an older ROCm line (rocm-core 7.2.4) is refused; nothing is changed (golden)' => sub {
  my $host = amd_host('ubuntu-24.04', responses => [
    [ $QUERY => "rocm-core install ok installed 7.2.4.70204-1\namdrocm10.1-gfx1151 install ok installed 10.1.0-35", 0 ] ]);
  my ( $rec, $how ) = rocm($host, release => '10.1', targets => [ 'gfx1151' ]);
  like($rec->{error}, qr/\Ainstall_rocm: ROCm 7\.2\.4\.70204-1 \(rocm-core\) is installed; AMD requires removing ROCm 7\.2\.4 or older before installing ROCm 10\.1, and install_rocm does not uninstall\. Nothing was changed on the host\n?\z/,
    'dies, naming the installed version');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], 'no command that changes the host');
  ok(!( grep { /remove|purge|apt-get/ } @{ $rec->{lines} } ), '... nothing removed, no apt-get at all');
  golden_is(masked($rec), 'amd/ubuntu-24.04--rocm-10.1--old-rocm-core');
};

subtest 'rocm-core in any dpkg state but not-installed / config-files is the old line: refused (k89)' => sub {
  my $VER = '7.2.4.70204-1';
  for my $c ([ 'hold ok installed', 'installed', 'held' ], [ 'install ok unpacked', 'unpacked', 'unpacked' ],
             [ 'install ok half-configured', 'half-configured', 'half-configured' ],
             [ 'install reinstreq half-installed', 'half-installed', 'half-installed' ],
             [ 'hold ok half-configured', 'half-configured', 'held and half-configured' ]) {
    my ( $status, $state, $label ) = @$c;
    my $host = amd_host('ubuntu-24.04', responses => [
      [ $QUERY => "rocm-core $status $VER\namdrocm10.1-gfx1151 install ok installed 10.1.0-35", 0 ] ]);
    my ( $rec, $how ) = rocm($host, release => '10.1', targets => [ 'gfx1151' ]);
    like($rec->{error}, qr/\Ainstall_rocm: ROCm \Q$VER\E \(rocm-core\) is \Q$state\E; AMD requires removing ROCm 7\.2\.4 or older before installing ROCm 10\.1, and install_rocm does not uninstall\. Nothing was changed on the host\n?\z/,
      "$label: dies, naming version and state");
    is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... no command that changes the host');
    ok(!( grep { /remove|purge|apt-get/ } @{ $rec->{lines} } ), '... nothing removed, no apt-get at all');
  }

  # dies before the present check, whatever the target packages say
  my $host = amd_host('ubuntu-24.04', responses => [
    [ $QUERY => "rocm-core hold ok installed $VER", 0 ] ]);
  my ( $rec ) = rocm($host, release => '10.1', targets => [ 'gfx1151' ]);
  like($rec->{error}, qr/\(rocm-core\) is installed; AMD requires removing/, 'held rocm-core with no target package: dies');

  # rc (config files left) and never-installed are not the old line: the install runs
  for my $c ([ 'deinstall ok config-files', 'config-files, rc' ], [ 'unknown ok not-installed', 'not-installed' ]) {
    my ( $status, $label ) = @$c;
    my ( $rec2, $how ) = rocm(rocm_host('ubuntu-24.04', before => "rocm-core $status $VER"),
      release => '10.1', targets => [ 'gfx1151' ]);
    is($rec2->{error}, undef, "$label: lives");
    is($how, 'installed', '... the install runs');
  }
  my ( $rec3, $how3 ) = rocm(rocm_host('ubuntu-24.04', before => "rocm-core unknown ok not-installed "),
    release => '10.1', targets => [ 'gfx1151' ]);
  is($how3, 'installed', 'not-installed with an empty version column (dpkg-query for a known-but-removed name): installed');
};

subtest 'arguments that die before any command' => sub {
  my @case = (
    [ 'no release',          [ targets => [ 'gfx1151' ] ],
      qr/\Ainstall_rocm: release => '\.\.\.' is required \(known: 10\.1\)\. Nothing was changed on the host\n?\z/ ],
    [ 'unknown release',     [ release => '9.9', targets => [ 'gfx1151' ] ],
      qr/\Ainstall_rocm: unknown ROCm release '9\.9' \(known: 10\.1\)\. Nothing was changed on the host\n?\z/ ],
    [ 'the old line is no release', [ release => '7.2.4', targets => [ 'gfx1151' ] ], qr/unknown ROCm release '7\.2\.4'/ ],
    [ 'unknown option',      [ release => '10.1', speed => 1 ],
      qr/\Ainstall_rocm: unknown option speed \(known: release, gpus, targets\)/ ],
    [ 'gpus and targets',    [ release => '10.1', gpus => [ gpu_synapse() ], targets => [ 'gfx1151' ] ],
      qr/pass gpus or targets, not both/ ],
    [ 'gpus => []',          [ release => '10.1', gpus => [] ],
      qr/\Ainstall_rocm: gpus is empty; omit gpus for every AMD GPU of the host\. Nothing was changed on the host\n?\z/ ],
    [ 'targets not an array', [ release => '10.1', targets => 'gfx1151' ], qr/targets must be an arrayref of gfx target names/ ],
    [ 'a GPU without a gfx_target', [ release => '10.1', gpus => [ { name => 'AMD GPU [1002:1902]', device_id => '1902', gfx_target => undef } ] ],
      qr/AMD GPU 0000:\?\?|AMD GPU \[1002:1902\] has no gfx_target; pass targets => \[\.\.\.\]/ ],
    [ 'a target AMD ships no package for', [ release => '10.1', targets => [ 'gfx906' ] ],
      qr/ROCm 10\.1 has no package for gfx906 \(it ships: gfx908 gfx90a gfx942 gfx950 / ],
    [ 'targets => []',       [ release => '10.1', targets => [] ], qr/no gfx target/ ],
  );
  for my $c (@case) {
    my ( $label, $args, $re ) = @$c;
    my ( $rec ) = rocm(amd_host('ubuntu-24.04'), @$args);
    like($rec->{error}, $re, "$label: dies");
    like($rec->{error}, qr/Nothing was changed on the host/, '... "Nothing was changed"');
    is_deeply($rec->{lines}, [], '... before any command');
  }
};

subtest 'no gfx target anywhere: dies after the one state read' => sub {
  my ( $rec ) = rocm(amd_host('ubuntu-24.04', state => amd_state(amdgpu => 0, kfd => 0, gpus => [])), release => '10.1');
  like($rec->{error}, qr/\Ainstall_rocm: no gfx target -- no AMD GPU with a running driver \(KFD\) found; pass targets => \[\.\.\.\]\. Nothing was changed on the host/,
    'dies');
  is_deeply($rec->{lines}, [ 'run: '.$STATE_CMD ], '... after the one read');
};

subtest 'OS, architecture, repository file: die after read-only commands only' => sub {
  my @case = (
    [ 'RHEL (apt hosts only)', amd_host('rhel-9'), qr/\Ainstall_rocm: supported on apt hosts only \(Ubuntu 22\.04, 24\.04, 26\.04; Debian 12, 13\), not Red Hat Enterprise Linux 9\.6 \(Plow\)\. Nothing was changed/ ],
    [ 'Fedora', amd_host('ubuntu-24.04', responses => [ [ 'cat /etc/os-release 2>/dev/null' => qq{NAME="Fedora Linux"\nID=fedora\nVERSION_ID="42"}, 0 ] ]),
      qr/Unsupported OS for the AMD driver: fedora/ ],
    [ 'arm64', amd_host('ubuntu-24.04', arch => 'arm64'), qr/ROCm 10\.1 is built for amd64 only; this host is arm64\. Nothing was changed/ ],
    [ 'a foreign repository file', amd_host('ubuntu-24.04', kernel => $HWE, responses => [
        [ 'cat /etc/apt/sources.list.d/amdrocm-stable.sources 2>/dev/null' => "Types: deb\nURIs: https://mirror.example.com/rocm/\n", 0 ] ]),
      qr{/etc/apt/sources\.list\.d/amdrocm-stable\.sources exists with other content than ROCm 10\.1 needs; install_rocm does not replace a repository it did not write\. Nothing was changed} ],
  );
  for my $c (@case) {
    my ( $label, $host, $re ) = @$c;
    my ( $rec ) = rocm($host, release => '10.1', targets => [ 'gfx1151' ]);
    like($rec->{error}, $re, "$label: dies");
    is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... no command that changes the host');
    ok(!$rec->{trapped}, '... no unmocked Rex function');
  }
};

subtest 'unsupported release of an apt OS: no ROCm repository' => sub {
  my ( $rec ) = rocm(amd_host('ubuntu-24.04', responses => [
      [ 'cat /etc/os-release 2>/dev/null' => qq{NAME="Ubuntu"\nID=ubuntu\nVERSION_ID="20.04"\nPRETTY_NAME="Ubuntu 20.04.6 LTS"}, 0 ] ]),
    release => '10.1', targets => [ 'gfx1151' ]);
  like($rec->{error}, qr/\Ainstall_rocm: AMD has no ROCm 10\.1 repository for Ubuntu 20\.04\.6 LTS\. Nothing was changed/, 'Ubuntu 20.04: dies');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... no command that changes the host');
};

#### k91: AMD's ROCm compatibility matrix binds install_rocm as it binds install_driver

sub uname_reads { my ( $rec ) = @_; return scalar grep { $_ eq 'run: uname -r' } @{ $rec->{lines} } }

# a refusal of the matrix: dies naming exactly @gfx, after read-only commands only
sub refused_ok {
  my ( $rec, $how, $label, @gfx ) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my $list = join ', ', @gfx;
  like($rec->{error}, qr/\Ainstall_rocm: AMD's ROCm compatibility matrix does not list \Q$list\E for this OS and kernel: .+\. Nothing was changed on the host\n?\z/,
    "$label: refused, naming $list");
  is($how, undef, '... no result');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... only read-only commands ran');
  ok(!( grep { /apt-get|curl|\.sources/ } @{ $rec->{lines} } ), '... no apt-get, no download, no repository file touched or read');
  ok(!$rec->{trapped}, '... no unmocked Rex function');
}

sub installed_ok {
  my ( $rec, $how, $label, @gfx ) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is($rec->{error}, undef, "$label: lives");
  is($how, 'installed', '... installed');
  like(( grep { /apt-get .* install / } @{ $rec->{lines} } )[0], qr/ install -y libatomic1 libquadmath0 \Q@{[ join ' ', map { "amdrocm10.1-$_" } @gfx ]}\E\z/,
    '... the install of '.join(', ', @gfx));
}

sub host_for {
  my ( $os, $kernel, @gfx ) = @_;
  return rocm_host($os, packages => [ map { "amdrocm10.1-$_" } @gfx ], host => ( defined $kernel ? { kernel => $kernel } : {} ));
}

subtest 'Debian 12 and 13: the Ryzen APU and a Radeon target are refused (k91, golden)' => sub {
  for my $os (qw( debian-12 debian-13 )) {
    for my $gfx (qw( gfx1151 gfx1100 )) {
      my ( $rec, $how ) = rocm(host_for($os, undef, $gfx), release => '10.1', targets => [ $gfx ]);
      refused_ok($rec, $how, "$os $gfx", $gfx);
      like($rec->{error}, $gfx eq 'gfx1100' ? qr/AMD supports Radeon GPUs only on / : qr/AMD supports them with the inbox driver only on /,
        '... with the matrix\'s own reason for that table');
      ok(uname_reads($rec) == 1, '... the kernel was read once');
      golden_is(masked($rec), 'amd/debian-13--rocm-10.1--gfx1151') if $os eq 'debian-13' && $gfx eq 'gfx1151';
    }
  }
};

subtest 'Ubuntu 22.04: gfx1151 never, a Radeon target only on the HWE kernel 6.8 (k91)' => sub {
  my ( $rec, $how );
  for my $kernel (qw( 5.15.0-151-generic 6.8.0-85-generic )) {
    ( $rec, $how ) = rocm(host_for('ubuntu-22.04', $kernel, 'gfx1151'), release => '10.1', targets => [ 'gfx1151' ]);
    refused_ok($rec, $how, "22.04 $kernel gfx1151", 'gfx1151');
  }
  ( $rec, $how ) = rocm(host_for('ubuntu-22.04', '5.15.0-151-generic', 'gfx1100'), release => '10.1', targets => [ 'gfx1100' ]);
  refused_ok($rec, $how, '22.04 GA 5.15 gfx1100', 'gfx1100');
  like($rec->{error}, qr/Ubuntu 22\.04.* with kernel 6\.8 \(-generic\); this host runs 5\.15\.0-151-generic/, '... naming the HWE kernel it needs');
  ( $rec, $how ) = rocm(host_for('ubuntu-22.04', '6.8.0-85-generic', 'gfx1100'), release => '10.1', targets => [ 'gfx1100' ]);
  installed_ok($rec, $how, '22.04 HWE 6.8 gfx1100', 'gfx1100');
  ok(uname_reads($rec) == 1, '... the kernel was read');
};

subtest 'Ubuntu 24.04: gfx1151 and a Radeon target need the HWE kernel 7.0 (-generic) (k91)' => sub {
  my ( $rec, $how );
  for my $gfx (qw( gfx1151 gfx1100 )) {
    ( $rec, $how ) = rocm(host_for('ubuntu-24.04', '6.8.0-85-generic', $gfx), release => '10.1', targets => [ $gfx ]);
    refused_ok($rec, $how, "24.04 GA 6.8 $gfx", $gfx);
    like($rec->{error}, qr/with kernel 7\.0 \(-generic\); this host runs 6\.8\.0-85-generic/, '... naming the HWE kernel it needs');
    ( $rec, $how ) = rocm(host_for('ubuntu-24.04', $HWE, $gfx), release => '10.1', targets => [ $gfx ]);
    installed_ok($rec, $how, "24.04 HWE 7.0 $gfx", $gfx);
    ok(uname_reads($rec) == 1, '... the kernel was read');
  }
  # a kernel that is not -generic is not in AMD's matrix, whatever its version
  ( $rec, $how ) = rocm(host_for('ubuntu-24.04', '6.14.0-1015-oem', 'gfx1151'), release => '10.1', targets => [ 'gfx1151' ]);
  refused_ok($rec, $how, '24.04 OEM 6.14 gfx1151', 'gfx1151');
  like($rec->{error}, qr/this host runs 6\.14\.0-1015-oem/, '... naming the running kernel');
  ( $rec, $how ) = rocm(host_for('ubuntu-24.04', '7.0.0-1005-oem', 'gfx1151'), release => '10.1', targets => [ 'gfx1151' ]);
  refused_ok($rec, $how, '24.04 OEM 7.0 gfx1151', 'gfx1151');
};

subtest 'Ubuntu 26.04 with kernel 7.0: gfx1151 and a Radeon target install (k91)' => sub {
  for my $gfx (qw( gfx1151 gfx1100 )) {
    my ( $rec, $how ) = rocm(host_for('ubuntu-26.04', undef, $gfx), release => '10.1', targets => [ $gfx ]);
    installed_ok($rec, $how, "26.04 7.0.0-12-generic $gfx", $gfx);
  }
};

subtest 'an Instinct target is not bound by the matrix: no kernel read (k91)' => sub {
  for my $c ([ 'debian-13', undef ], [ 'debian-12', undef ], [ 'ubuntu-24.04', '6.8.0-85-generic' ], [ 'ubuntu-22.04', '5.15.0-151-generic' ]) {
    my ( $os, $kernel ) = @$c;
    my ( $rec, $how ) = rocm(host_for($os, $kernel, 'gfx942'), release => '10.1', targets => [ 'gfx942' ]);
    installed_ok($rec, $how, "$os".( $kernel ? " $kernel" : '' )." gfx942", 'gfx942');
    is(uname_reads($rec), 0, '... uname -r was never run');
  }
};

subtest 'an Instinct target beside a refused one: only the refused one is named (k91)' => sub {
  my ( $rec, $how ) = rocm(host_for('debian-13', undef, 'gfx942', 'gfx1151'), release => '10.1', targets => [ 'gfx942', 'gfx1151' ]);
  refused_ok($rec, $how, 'debian-13 gfx942 + gfx1151', 'gfx1151');
};

subtest 'present comes before the matrix: an off-matrix target already installed is present (k91)' => sub {
  my $host = amd_host('debian-13', responses => [ [ $QUERY => 'amdrocm10.1-gfx1151 install ok installed 10.1.0-35', 0 ] ]);
  my ( $rec, $how ) = rocm($host, release => '10.1', targets => [ 'gfx1151' ]);
  is($rec->{error}, undef, 'gfx1151 on Debian 13, installed at the release: lives');
  is($how, 'present', '... present');
  is(uname_reads($rec), 0, '... the kernel was not read');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... only read-only commands ran');

};

subtest 'not present: the off-matrix target is refused (k91)' => sub {
  # the same host without the package is refused (so the target is off-matrix)
  my ( $rec, $how ) = rocm(amd_host('debian-13'), release => '10.1', targets => [ 'gfx1151' ]);
  refused_ok($rec, $how, 'the same host, nothing installed', 'gfx1151');

  # one of two packages missing: not present, so the matrix applies
  my $host = amd_host('debian-13', responses => [ [ $QUERY => 'amdrocm10.1-gfx942 install ok installed 10.1.0-35', 0 ] ]);
  ( $rec, $how ) = rocm($host, release => '10.1', targets => [ 'gfx942', 'gfx1151' ]);
  refused_ok($rec, $how, 'gfx942 installed, gfx1151 not', 'gfx1151');
};

subtest 'the matrix is asked after the old ROCm line and before the repository file (k91)' => sub {
  # the old line first: its error, not the matrix's
  my $old = [ $QUERY => 'rocm-core install ok installed 7.2.4.70204-1', 0 ];
  my ( $rec ) = rocm(amd_host('debian-13', responses => [ $old ]), release => '10.1', targets => [ 'gfx1151' ]);
  like($rec->{error}, qr/\Ainstall_rocm: ROCm 7\.2\.4\.70204-1 \(rocm-core\) is installed/, 'old rocm-core and an off-matrix target: the old-line error');
  is(uname_reads($rec), 0, '... the kernel was not read');

  # a foreign repository file: the matrix error, and the file is never read
  my $foreign = [ 'cat /etc/apt/sources.list.d/amdrocm-stable.sources 2>/dev/null' => "Types: deb\nURIs: https://mirror.example.com/rocm/\n", 0 ];
  my $how;
  ( $rec, $how ) = rocm(amd_host('debian-13', responses => [ $foreign ]), release => '10.1', targets => [ 'gfx1151' ]);
  refused_ok($rec, $how, 'foreign repository file and an off-matrix target', 'gfx1151');
  unlike($rec->{error}, qr/exists with other content/, '... not the foreign-file error');
  ok(!( grep { /amdrocm-stable\.sources/ } @{ $rec->{lines} } ), '... the repository file was not even read');
};

subtest 'a target without a matrix is not checked: no row, or compute 0 (k91)' => sub {
  # gfx1010 (compute 0, no matrix) and gfx1250 (no hardware row) ship a package in ROCm 10.1
  for my $gfx (qw( gfx1010 gfx1250 )) {
    ok($gfx, "$gfx: ships in ROCm 10.1") if grep { $_ eq $gfx } @{ Rex::GPU::AMD->rocm_releases->{'10.1'}{targets} };
    my ( $rec, $how ) = rocm(host_for('debian-13', undef, $gfx), release => '10.1', targets => [ $gfx ]);
    installed_ok($rec, $how, "debian-13 $gfx", $gfx);
    is(uname_reads($rec), 0, '... uname -r was never run');
  }
  ok(!Rex::GPU::AMD::Hardware->target('gfx1250'), 'gfx1250 has no hardware row');
  is(Rex::GPU::AMD::Hardware->target('gfx1010')->{matrix}, undef, 'gfx1010 has a row without matrix');
};

{
  package Local::HW::Own1151;
  our @ISA = ('Rex::GPU::AMD::Hardware');
  # gfx1151 as an Instinct-table GPU, gfx1100 as a row of your own without `matrix`
  sub targets {
    my ( $class ) = @_;
    return map { $_->{gfx_target} eq 'gfx1151' ? { %$_, matrix => 'instinct' }
               : $_->{gfx_target} eq 'gfx1100' ? do { my %r = %$_; delete $r{matrix}; \%r }
               : $_ } $class->SUPER::targets;
  }
  package Local::AMD::Own1151;
  our @ISA = ('Rex::GPU::AMD');
  sub hardware_class { 'Local::HW::Own1151' }
}

subtest 'a subclass with its own hardware_class decides what is checked (k91)' => sub {
  ok(Local::HW::Own1151->target('gfx1151')->{matrix} eq 'instinct', 'the own class says gfx1151 is an Instinct-table target');
  for my $gfx (qw( gfx1151 gfx1100 )) {
    my ( $rec, $how ) = rocm(host_for('debian-13', undef, $gfx), class => 'Local::AMD::Own1151', release => '10.1', targets => [ $gfx ]);
    installed_ok($rec, $how, "Debian 13 $gfx under the own hardware_class", $gfx);
    is(uname_reads($rec), 0, '... uname -r was never run');
  }
};

subtest 'the stock class on the same host refuses what the subclass lets through (k91)' => sub {
  my ( $rec, $how ) = rocm(host_for('debian-13', undef, 'gfx1151'), class => 'Rex::GPU::AMD', release => '10.1', targets => [ 'gfx1151' ]);
  refused_ok($rec, $how, 'the stock class, same host', 'gfx1151');
};

subtest 'a Radeon and a Ryzen APU target together: the Radeon ones are named first, as install_driver does (k91)' => sub {
  # Debian 13: both off; only the Radeon table is named, in the order given
  my ( $rec, $how ) = rocm(host_for('debian-13', undef, 'gfx1151', 'gfx1101', 'gfx1100'), release => '10.1', targets => [ 'gfx1151', 'gfx1101', 'gfx1100' ]);
  refused_ok($rec, $how, 'debian-13 gfx1151 gfx1101 gfx1100', 'gfx1101', 'gfx1100');
  unlike($rec->{error}, qr/gfx1151/, '... the APU is not named while a Radeon target is');

  # Ubuntu 22.04 HWE 6.8: the Radeon target passes, the APU is what is refused
  ( $rec, $how ) = rocm(host_for('ubuntu-22.04', '6.8.0-85-generic', 'gfx1100', 'gfx1151'), release => '10.1', targets => [ 'gfx1100', 'gfx1151' ]);
  refused_ok($rec, $how, 'ubuntu-22.04 HWE gfx1100 gfx1151', 'gfx1151');
  unlike($rec->{error}, qr/gfx1100/, '... the Radeon target that is listed is not named');
};

subtest 'the targets come from gpus => [...] and from the KFD nodes: the matrix applies to both (k91)' => sub {
  my ( $rec, $how ) = rocm(amd_host('debian-13'), release => '10.1', gpus => [ gpu_synapse() ]);
  refused_ok($rec, $how, 'gpus => [gfx1151 GPU]', 'gfx1151');
  ( $rec, $how ) = rocm(amd_host('debian-13'), release => '10.1', gpus => [ gpu_mi300x(), gpu_navi31() ]);
  refused_ok($rec, $how, 'gpus => [MI300X, Navi 31]', 'gfx1100');

  my $kfd = sub { amd_state(gpus => [ { slot => '0000:95:00.0', class => '0380', device_id => '1586', kfd => $_[0] } ]) };
  ( $rec, $how ) = rocm(amd_host('debian-13', state => $kfd->(110501)), release => '10.1');
  refused_ok($rec, $how, 'KFD node 110501', 'gfx1151');
  ok(( grep { $_ eq 'run: '.$STATE_CMD } @{ $rec->{lines} } ), '... via the state read');
  ( $rec, $how ) = rocm(amd_host('debian-13', state => $kfd->(110000)), release => '10.1');
  refused_ok($rec, $how, 'KFD node 110000', 'gfx1100');
  # and the same nodes on a host the matrix lists them for
  ( $rec, $how ) = rocm(rocm_host('ubuntu-24.04', state => $kfd->(110501)), release => '10.1');
  installed_ok($rec, $how, 'KFD node 110501 on 24.04 HWE 7.0', 'gfx1151');
};

#### dies after a change

subtest 'a signing key that is not the pinned one: dies, nothing installed' => sub {
  my ( $rec ) = rocm(rocm_host('ubuntu-24.04', host => { key => 'DEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF' }),
    release => '10.1', targets => [ 'gfx1151' ]);
  like($rec->{error}, qr/The key from https:\/\/stable\.repo\.amd\.com\/rocm\/gpg\/packages\.gpg is not the AMD signing key expected \(fingerprint \Q$ROCM_KEY\E; got DEADBEEF/, 'dies');
  ok(!( grep { /apt-get .* install |> \/etc\/apt\/sources\.list\.d\/amdrocm-stable/ } @{ $rec->{lines} } ), 'no install, no repository file');
};

subtest 'a package installed at another version than the release: dies after the install' => sub {
  my ( $rec ) = rocm(rocm_host('ubuntu-24.04', version => '7.9.0-1'), release => '10.1', targets => [ 'gfx1151' ]);
  like($rec->{error}, qr/\Ainstall_rocm: amdrocm10\.1-gfx1151 is installed at 7\.9\.0-1, not ROCm 10\.1\n?\z/, 'dies naming both');

  ( $rec ) = rocm(rocm_host('ubuntu-24.04', responses => [ [ qr{^dpkg -l amdrocm10\.1-gfx1151 2>/dev/null \| grep -q '\^\[hi\]i'$} => '', 1 ] ]),
    release => '10.1', targets => [ 'gfx1151' ]);
  like($rec->{error}, qr/\Aamdrocm10\.1-gfx1151 not installed after apt-get install/, 'a package dpkg does not show as installed: dies');
  ok(no_pkg($rec), '... verified by dpkg, not Rex::Pkg');
};

done_testing;
