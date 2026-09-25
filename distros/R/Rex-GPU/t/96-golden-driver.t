use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# CHARACTERIZATION ("golden") tests for install_driver (karr #29, T0 of epic
# #25).
#
# CLAIM: for each GPU x OS below, install_driver(gpu => ...) hands Rex exactly
# the host interactions recorded in t/golden/driver/<os>--<gpu>.txt, in that
# order -- every run/pkg/file/can_run call with its full command string. The
# goldens record what the code does TODAY (HEAD 3cba655), not what it should
# do: the T2-T4 refactors of epic #25 must reproduce them byte for byte. A
# diff is a behaviour change -- read it before regenerating (see
# t/lib/Test/RexGPU/Golden.pm for the switch).
#
# Kepler (K80) is asserted inline on every OS, handed to install_driver
# directly (detection skips it since karr #55): it must die with the "Nothing
# was changed" message after the nvidia-smi probe and before any other host
# interaction.
#
# Several GPUs (karr #33): install_driver(gpus => [...]) must emit exactly
# what the most constrained GPU gets alone, and a V100 next to a B200 or a K80
# anywhere must die after the probe only. Every "no driver source fits" case
# must die with only read-only probes before it. Ubuntu's package search
# runs after apt-get update (karr #35); when it finds nothing, the die comes
# after the update and before any install command.
#
# NOT covered -- none of this runs without a real GPU host, and a green prove
# is NOT evidence that a driver installs:
#   * what the remote shell does with a command string (pipes, sed, awk,
#     `|| true`, `$(...)` are recorded verbatim, never evaluated);
#   * whether a recorded package exists / installs / DKMS-builds on the real
#     release, or the module binds after the nouveau reboot;
#   * install_driver(reboot => 1) here (t/41-reboot.t covers the emitted
#     shutdown and the reconnect loop with a scripted connection);
#   * the host outputs are hand-written stand-ins (uname -r, apt-cache search,
#     rpm -q ...), not captures from real hosts.
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw(
  record_host golden_is host_names host_profile gpu_fixture mutating_lines working_driver
);
use Rex::GPU::NVIDIA;

my @GPUS = qw( ada blackwell volta none );

sub driver_on {
  my ( $host, $gpu ) = @_;
  return record_host(
    host => $host,
    code => sub { Rex::GPU::NVIDIA::install_driver(gpu => $gpu) }
  );
}

subtest 'fixtures come from the real lspci parser' => sub {
  for my $name (qw( ada blackwell volta b200 b300 pascal maxwell )) {
    my $gpu = gpu_fixture($name);
    is($gpu->{compute}, 1, "$name is compute");
    like($gpu->{device_id}, qr/^[0-9a-f]{4}$/, "$name has a device id");
  }
  # karr #55: the class-0302 K80 is skipped by its Kepler row, so gpu_setup
  # never passes it; the Kepler cases below hand it to install_driver directly.
  my $kepler = gpu_fixture('kepler');
  is($kepler->{compute}, 0, 'kepler (K80, class 0302) is not compute');
  is($kepler->{device_id}, '102d', 'kepler has its device id');
  is(gpu_fixture('none'), undef, 'none => undef (install_driver without gpu =>)');
};

#### The matrix

for my $os (host_names()) {
  for my $g (@GPUS) {
    my $rec = driver_on(host_profile($os), gpu_fixture($g));
    golden_is($rec, "driver/$os--$g");
  }
}

#### Entry-level Pascal / Maxwell (karr #54)
#
# A GeForce GT 1030 (Pascal, 10de:1d01) and GTX 980 (Maxwell, 10de:13c0) at
# class 0300 are compute by generation now. The driver choice reads only the
# device ID's requirement (proprietary, branch <= 580), so on every OS they
# must get exactly what the V100 gets -- same transcript, or the same die.
# Two goldens pin it on Ubuntu 24.04 and Rocky 9.

for my $os (host_names()) {
  my $volta = driver_on(host_profile($os), gpu_fixture('volta'));
  for my $g (qw( pascal maxwell )) {
    my $rec = driver_on(host_profile($os), gpu_fixture($g));
    is($rec->{error}, $volta->{error}, "$os + $g: dies/lives like volta");
    is_deeply($rec->{lines}, $volta->{lines}, "$os + $g: same commands as volta");
  }
}
golden_is(driver_on(host_profile('ubuntu-24.04'), gpu_fixture('pascal')), 'driver/ubuntu-24.04--pascal');
golden_is(driver_on(host_profile('rocky-9'), gpu_fixture('pascal')), 'driver/rocky-9--pascal');

#### Kepler: dies before touching the host, on every OS

for my $os (host_names()) {
  my $rec = driver_on(host_profile($os), gpu_fixture('kepler'));
  like($rec->{error}, qr/Kepler or older.*No driver package was installed and no package source was added/,
    "$os + K80 dies with the Kepler message");
  is_deeply($rec->{lines}, [ 'run: nvidia-smi -L 2>&1' ],
    "$os + K80: only the nvidia-smi probe ran");
}

#### Already-installed short-circuit
#
# Installed = nvidia-smi lists a GPU AND libcuda.so.1 is in the linker cache
# (karr #42). The libcuda probe runs only after nvidia-smi passed, so a fresh
# host (every golden above) still runs the single nvidia-smi probe.

my $LIBCUDA_PROBE = q{run: /sbin/ldconfig -p 2>/dev/null | grep -q '^[[:space:]]*libcuda\.so\.1 '};

for my $os (host_names()) {
  my $rec = driver_on(host_profile($os, responses => [ working_driver() ]), gpu_fixture('kepler'));
  is($rec->{error}, undef, "$os + working driver: no die, even for a K80");
  is_deeply($rec->{lines}, [ 'run: nvidia-smi -L 2>&1', $LIBCUDA_PROBE ],
    "$os + working driver: nothing but the two probes");
}

# nvidia-smi lists a GPU but libcuda.so.1 is missing: not installed. The
# install runs exactly as on a fresh host, with the libcuda probe after the
# nvidia-smi one; a K80 is refused after both probes.
for my $os (host_names()) {
  my $smi_only = [ [ 'nvidia-smi -L 2>&1' => 'GPU 0: NVIDIA RTX 4000 SFF Ada Generation (UUID: GPU-0)', 0 ] ];
  my $fresh = driver_on(host_profile($os), gpu_fixture('ada'));
  my $rec   = driver_on(host_profile($os, responses => $smi_only), gpu_fixture('ada'));
  is($rec->{error}, $fresh->{error}, "$os + nvidia-smi without libcuda: dies/lives like a fresh host");
  my @lines = @{ $rec->{lines} };
  is($lines[1], $LIBCUDA_PROBE, "$os + nvidia-smi without libcuda: libcuda probed after nvidia-smi");
  splice @lines, 1, 1;
  is_deeply(\@lines, $fresh->{lines}, "$os + nvidia-smi without libcuda: then the fresh-host install");
  ok((grep { $_->[0] eq 'warn' && $_->[1] =~ /libcuda\.so\.1 is not in the linker cache/ } @{ $rec->{logs} }),
    "$os + nvidia-smi without libcuda: warns before installing");

  $rec = driver_on(host_profile($os, responses => $smi_only), gpu_fixture('kepler'));
  like($rec->{error}, qr/Kepler or older.*libcuda\.so\.1 is in the linker cache, install_driver skips/,
    "$os + K80, nvidia-smi without libcuda: Kepler message names both conditions");
  is_deeply($rec->{lines}, [ 'run: nvidia-smi -L 2>&1', $LIBCUDA_PROBE ], '... after the two probes only');
}
golden_is(
  driver_on(host_profile('debian-12', responses => [
    [ 'nvidia-smi -L 2>&1' => 'GPU 0: NVIDIA RTX 4000 SFF Ada Generation (UUID: GPU-0)', 0 ]
  ]), gpu_fixture('ada')),
  'driver/debian-12--ada--libcuda-missing'
);

#### Failure variants on the install-verify seam and the selection guards

# Driver package not ii after apt-get install (e.g. DKMS build failed in
# postinst): dies after the install, before nouveau is touched.
golden_is(
  driver_on(host_profile('debian-12', responses => [
    [ q{dpkg -l nvidia-driver 2>/dev/null | grep -q '^ii'} => '', 1 ]
  ]), gpu_fixture('ada')),
  'driver/debian-12--ada--not-installed'
);

golden_is(
  driver_on(host_profile('rocky-9', responses => [
    [ 'rpm -q nvidia-driver 2>&1' => 'package nvidia-driver is not installed', 1 ]
  ]), gpu_fixture('ada')),
  'driver/rocky-9--ada--not-installed'
);

# RHEL (karr #47): dnf config-manager --add-repo fails (HTTP error on the
# CUDA .repo URL, nothing written) -- dies naming the URL and dnf's output,
# before dnf clean / module enable / any install.
{
  my $url = 'https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo';
  my $rec = driver_on(host_profile('rocky-9', responses => [
    [ qr{^dnf config-manager --add-repo } =>
        "Adding repo from: $url\nCurl error (22): HTTP response code said error for $url [The requested URL returned error: 404]\nError: Configuration of repo failed", 1 ]
  ]), gpu_fixture('ada'));
  like($rec->{error}, qr{^dnf config-manager --add-repo \Q$url\E failed \(exit 1\): .*error: 404.*no driver was installed}s,
    'rocky-9 + Ada, add-repo fails: dies with URL and dnf output');
  is_deeply([ grep { / install |module enable|clean expire-cache/ } @{ $rec->{lines} } ], [],
    '... nothing after the add-repo is emitted');
  golden_is($rec, 'driver/rocky-9--ada--add-repo-failed');
}

# openSUSE (karr #27): zypper install fails (no provider, exit 104) -- the
# open meta package is not there, dies after the addlock, before nouveau.
golden_is(
  driver_on(host_profile('leap-15.6', responses => [
    [ 'ZYPP_LOCK_TIMEOUT=120 zypper install -y nvidia-open-driver-G06-signed-kmp-meta' =>
        "No provider of 'nvidia-open-driver-G06-signed-kmp-meta' found.", 104 ],
    [ 'rpm -q --whatprovides nvidia-open-driver-G06-signed-kmp-meta 2>&1' =>
        'no package provides nvidia-open-driver-G06-signed-kmp-meta', 1 ]
  ]), gpu_fixture('ada')),
  'driver/leap-15.6--ada--install-failed'
);

# openSUSE (karr #52): the GFX repo URL answers 404. zypper addrepo of a base
# URL does not contact the server (exit 0, checked in opensuse/leap:15.6 and
# 16.0 containers), the refresh fails (exit 4) -- the entry is removed again
# and it dies naming alias, URL and zypper's output, before any install.
{
  my $url = 'https://download.nvidia.com/opensuse/leap/15.6/';
  my $rec = driver_on(host_profile('leap-15.6', responses => [
    [ 'ZYPP_LOCK_TIMEOUT=120 zypper --gpg-auto-import-keys refresh nvidia-gfx 2>&1' =>
        "Retrieving repository 'nvidia-gfx' metadata [.error]\nRepository 'nvidia-gfx' is invalid.\n[nvidia-gfx|$url] Failed to retrieve new repository metadata.\nHistory:\n - [nvidia-gfx|$url] Repository type can't be determined.\nPlease check if the URIs defined for this repository are pointing to a valid repository.\nSkipping repository 'nvidia-gfx' because of the above error.\nCould not refresh the repositories because of errors.", 4 ]
  ]), gpu_fixture('ada'));
  like($rec->{error}, qr{^zypper refresh of repository nvidia-gfx \(\Q$url\E\) failed \(exit 4\): .*is invalid.*removed again; nothing was installed from it}s,
    'leap-15.6 + Ada, GFX refresh fails: dies with alias, URL and zypper output');
  my @lines = @{ $rec->{lines} };
  is_deeply([ grep { / install |addlock|dracut/ } @lines ], [], '... no install after the failed refresh');
  like($lines[-1], qr{^run: ZYPP_LOCK_TIMEOUT=120 zypper rr nvidia-gfx }, '... and the broken entry is removed again');
  golden_is($rec, 'driver/leap-15.6--ada--refresh-failed');
}

# ... addrepo itself fails (the zypp lock held by another process, exit 7):
# dies there, no refresh, no install.
{
  my $rec = driver_on(host_profile('leap-16.0', responses => [
    [ qr{^ZYPP_LOCK_TIMEOUT=120 zypper addrepo --refresh } =>
        "System management is locked by the application with pid 4242 (zypper).\nClose this application before trying again.", 7 ]
  ]), gpu_fixture('ada'));
  like($rec->{error}, qr{^zypper addrepo of repository nvidia-gfx \(https://download\.nvidia\.com/opensuse/leap/16\.0/\) failed \(exit 7\): System management is locked.*; nothing was installed from it}s,
    'leap-16.0 + Ada, addrepo fails: dies with alias, URL and zypper output');
  is_deeply([ grep { / install | refresh / } @{ $rec->{lines} } ], [], '... no refresh, no install');
  golden_is($rec, 'driver/leap-16.0--ada--addrepo-failed');
}

# ... a re-run: the existing alias is removed before addrepo, which would
# otherwise exit 4 ("Repository named 'nvidia-gfx' already exists").
for my $os (qw( leap-15.6 leap-16.0 )) {
  my @lines = @{ driver_on(host_profile($os), gpu_fixture('ada'))->{lines} };
  my ($rr)  = grep { $lines[$_] =~ /^run: ZYPP_LOCK_TIMEOUT=120 zypper rr nvidia-gfx / } 0..$#lines;
  my ($add) = grep { $lines[$_] =~ /^run: ZYPP_LOCK_TIMEOUT=120 zypper addrepo / } 0..$#lines;
  ok(defined $rr && defined $add && $rr < $add, $os.': zypper rr nvidia-gfx precedes addrepo');
}

# ... the meta package is there but no package provides the kmp it requires.
golden_is(
  driver_on(host_profile('leap-16.0', responses => [
    [ 'rpm -q --whatprovides nvidia-open-driver-G07-signed-kmp 2>&1' =>
        'no package provides nvidia-open-driver-G07-signed-kmp', 1 ]
  ]), gpu_fixture('ada')),
  'driver/leap-16.0--ada--kmp-missing'
);

# Pre-Turing on RHEL 10 gets a newer branch than 580: dies after install.
golden_is(
  driver_on(host_profile('rocky-10', responses => [
    [ q{rpm -q --qf '%{VERSION}' nvidia-driver 2>&1} => '590.44.01', 0 ]
  ]), gpu_fixture('volta')),
  'driver/rocky-10--volta--wrong-branch'
);

# Ubuntu, V100, no candidate for nvidia-driver-580-server: dies after
# apt-get update and before any install.
{
  my $rec = driver_on(host_profile('ubuntu-24.04', responses => [
    [ qr{^LC_ALL=C apt-cache policy } => "nvidia-driver-580-server:\n  Installed: (none)\n  Candidate: (none)\n", 0 ]
  ]), gpu_fixture('volta'));
  golden_is($rec, 'driver/ubuntu-24.04--volta--no-candidate');
  is_deeply([ grep { / install / } @{ $rec->{lines} } ], [],
    'ubuntu-24.04 + V100 without candidate: no install command emitted');
}

# Ubuntu, apt-cache search finds nothing even after apt-get update (karr
# #35): dies naming the search, before any install. The hard-coded 570
# fallback this golden recorded before is gone -- the search matches 570 too,
# so an empty answer means apt-get could not install it either.
{
  my $rec = driver_on(host_profile('ubuntu-24.04', responses => [
    [ qr{^apt-cache search } => '', 0 ]
  ]), gpu_fixture('ada'));
  like($rec->{error}, qr/ubuntu-server chosen for .*finds no package after apt-get update.*No driver package was installed/,
    'ubuntu-24.04 + Ada, empty search: dies, no fallback package');
  is_deeply([ grep { / install / } @{ $rec->{lines} } ], [],
    '... no install command emitted');
  golden_is($rec, 'driver/ubuntu-24.04--ada--empty-search');
}

# deb822 (karr #36): debian.sources already carries every component -- read,
# not rewritten (no file: line).
golden_is(
  driver_on(host_profile('debian-13', responses => [
    [ 'cat /etc/apt/sources.list.d/debian.sources 2>/dev/null' =>
        "Types: deb\nURIs: http://deb.debian.org/debian/\nSuites: trixie trixie-updates\n"
      . "Components: main contrib non-free non-free-firmware\n"
      . "Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp", 0 ]
  ]), gpu_fixture('ada')),
  'driver/debian-13--ada--nonfree-enabled'
);

# Both formats on one host: sources.list is rewritten first, then the deb822
# file (Hetzner mirror); a third-party .sources file is read but
# not written, and a name apt ignores is not even read.
golden_is(
  driver_on(host_profile('debian-12', responses => [
    [ 'ls -1 /etc/apt/sources.list.d/ 2>/dev/null' =>
        "debian.sources\nhashicorp.sources\nnvidia-container-toolkit.list\nold.sources.bak", 0 ],
    [ 'cat /etc/apt/sources.list.d/debian.sources 2>/dev/null' =>
        "Types: deb\nURIs: http://mirror.hetzner.com/debian/packages\nSuites: bookworm bookworm-updates\n"
      . "Components: main\n", 0 ],
    [ 'cat /etc/apt/sources.list.d/hashicorp.sources 2>/dev/null' =>
        "Types: deb\nURIs: https://apt.releases.hashicorp.com\nSuites: bookworm\nComponents: main\n"
      . "Signed-By: /usr/share/keyrings/hashicorp-archive-keyring.gpg", 0 ]
  ]), gpu_fixture('ada')),
  'driver/debian-12--ada--both-formats'
);

# Classic sources.list as the bookworm installer writes it (karr #40): "main
# non-free-firmware" must not pass for non-free -- contrib non-free are
# appended to the deb lines; deb-src, the commented cdrom line and a
# third-party line are written back unchanged.
golden_is(
  driver_on(host_profile('debian-12', responses => [
    [ 'cat /etc/apt/sources.list 2>/dev/null' =>
        "#deb cdrom:[Debian GNU/Linux 12.11.0 _Bookworm_]/ bookworm contrib main non-free-firmware\n"
      . "deb http://deb.debian.org/debian/ bookworm main non-free-firmware\n"
      . "deb-src http://deb.debian.org/debian/ bookworm main non-free-firmware\n"
      . "deb http://security.debian.org/debian-security bookworm-security main non-free-firmware\n"
      . "deb http://deb.debian.org/debian/ bookworm-updates main non-free-firmware\n"
      . "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com bookworm main", 0 ]
  ]), gpu_fixture('ada')),
  'driver/debian-12--ada--installer-sources'
);

# Classic sources.list already complete: read, not rewritten (no file: line).
golden_is(
  driver_on(host_profile('debian-12', responses => [
    [ 'cat /etc/apt/sources.list 2>/dev/null' =>
        "deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware", 0 ]
  ]), gpu_fixture('ada')),
  'driver/debian-12--ada--nonfree-enabled'
);

# Blackwell on a Debian release NVIDIA has no CUDA repo for: dies before any
# host change. Since karr #33 the message is the no-source-fits one, listing
# each candidate; the CUDA-repo reason still names the supported releases.
{
  my $rec = driver_on(host_profile('debian-12', release => '11.11'), gpu_fixture('blackwell'));
  like($rec->{error}, qr/NVIDIA's CUDA repo only covers Debian 12 and 13/,
    'debian-11 + RTX 5090 dies naming the supported releases');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [],
    'debian-11 + RTX 5090: only read-only probes before the die');
  golden_is($rec, 'driver/debian-11--blackwell');
}

#### Several GPUs on one host (karr #33)
#
# install_driver(gpus => [...]) chooses for the intersection of all GPUs'
# requirements. A mixed host gets exactly what its most constrained GPU gets
# alone -- same transcript, command for command -- and GPUs that cannot share
# a driver die after the nvidia-smi probe, before anything else.

sub driver_for {
  my ( $host, @names ) = @_;
  return record_host(
    host => $host,
    code => sub { Rex::GPU::NVIDIA::install_driver(gpus => [ map { gpu_fixture($_) } @names ]) }
  );
}

for my $os (host_names()) {
  my %single = map { $_ => driver_on(host_profile($os), gpu_fixture($_)) } qw( ada blackwell volta );
  for my $case ([ [qw( ada ada )], 'ada' ], [ [qw( ada blackwell )], 'blackwell' ],
                [ [qw( blackwell ada )], 'blackwell' ], [ [qw( ada volta )], 'volta' ]) {
    my ( $pair, $as ) = @$case;
    my $rec = driver_for(host_profile($os), @$pair);
    is($rec->{error}, $single{$as}{error}, "$os + ".join('+', @$pair).": dies/lives like $as alone");
    is_deeply($rec->{lines}, $single{$as}{lines}, "$os + ".join('+', @$pair).": same commands as $as alone");
  }

  my $rec = driver_for(host_profile($os), qw( volta b200 ));
  like($rec->{error}, qr/^No single NVIDIA driver supports all GPUs on this host: GB100 \[B200\] \(Blackwell, 10de:2901\) needs the open kernel module, but GV100GL \[Tesla V100 PCIe 16GB\] \(Maxwell\/Pascal\/Volta, 10de:1db4\) needs the proprietary one\. No driver package was installed and no package source was added/,
    "$os + V100+B200 dies naming both GPUs");
  is_deeply($rec->{lines}, [ 'run: nvidia-smi -L 2>&1' ], "$os + V100+B200: only the nvidia-smi probe ran");

  $rec = driver_for(host_profile($os), qw( ada kepler ));
  like($rec->{error}, qr/GK210GL \[Tesla K80\].*Kepler or older.*No driver package was installed and no package source was added/,
    "$os + Ada+K80: a Kepler anywhere in the list is rejected");
  is_deeply($rec->{lines}, [ 'run: nvidia-smi -L 2>&1' ], "$os + Ada+K80: only the nvidia-smi probe ran");
}

golden_is(driver_for(host_profile('ubuntu-24.04'), qw( ada blackwell )),
  'driver/ubuntu-24.04--ada+blackwell');
golden_is(driver_for(host_profile('ubuntu-24.04'), qw( ada volta )),
  'driver/ubuntu-24.04--ada+volta');
golden_is(driver_for(host_profile('ubuntu-24.04'), qw( volta b200 )),
  'driver/ubuntu-24.04--volta+b200');

# gpu => stays an alias of a one-element gpus =>; both at once die untouched
is_deeply(driver_for(host_profile('debian-12'), 'ada')->{lines},
  driver_on(host_profile('debian-12'), gpu_fixture('ada'))->{lines}, 'gpus => [ada] is gpu => ada');
is_deeply(driver_for(host_profile('debian-12'))->{lines},
  driver_on(host_profile('debian-12'), undef)->{lines}, 'gpus => [] is no GPU');
{
  my $rec = record_host(host => host_profile('debian-12'), code => sub {
    Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('ada'), gpus => [ gpu_fixture('ada') ]) });
  like($rec->{error}, qr/^install_driver: pass gpu or gpus, not both$/, 'gpu and gpus together die');
  is_deeply($rec->{lines}, [], '... before any host interaction');
}

#### No source fits: dies before any host change, listing every candidate

{
  # Debian without a CUDA repo, Blackwell and V100 (non-free branch unknown)
  my $rec = driver_on(host_profile('debian-13', release => '14.0'), gpu_fixture('blackwell'));
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], 'debian-14 + RTX 5090: only read-only probes');
  golden_is($rec, 'driver/debian-14--blackwell');

  $rec = driver_on(host_profile('debian-13', release => '14.0'), gpu_fixture('volta'));
  like($rec->{error}, qr/debian-nonfree: driver branch not known, 580 or older is needed/,
    'debian-14 + V100: non-free has no known branch there');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... only read-only probes');
  golden_is($rec, 'driver/debian-14--volta');

  # Ubuntu, B300 (580 or newer), apt-cache search empty after apt-get update
  # (karr #35): -server-open is chosen in plan and the empty search makes it
  # die before any install. Deliberately REPLACED claim: this used to die in
  # plan with only read-only probes, because the search ran against the
  # un-refreshed index; now the apt timers are stopped and apt-get update
  # runs first -- still no package is installed.
  $rec = driver_on(host_profile('ubuntu-24.04', responses => [
    [ qr{^apt-cache search } => '', 0 ]
  ]), gpu_fixture('b300'));
  like($rec->{error}, qr/ubuntu-server-open chosen for .*finds no package after apt-get update/,
    'ubuntu-24.04 + B300, empty search: dies naming the search');
  is_deeply([ grep { / install / } @{ $rec->{lines} } ], [], '... no install command emitted');
  golden_is($rec, 'driver/ubuntu-24.04--b300--empty-search');
}

#### The harness itself

subtest 'mocks are restored after every recording' => sub {
  my $orig_run = \&Rex::GPU::NVIDIA::run;
  my $orig_log = \&Rex::Logger::info;
  driver_on(host_profile('debian-12'), gpu_fixture('ada'));
  driver_on(host_profile('debian-12'), gpu_fixture('kepler'));   # dies inside
  is(\&Rex::GPU::NVIDIA::run, $orig_run, 'Rex::GPU::NVIDIA::run is the real one again');
  is(\&Rex::Logger::info,     $orig_log, 'Rex::Logger::info is the real one again');
};

subtest 'an unmocked Rex call is trapped, not executed' => sub {
  my $rec = record_host(
    host => host_profile('debian-12'),
    code => sub { Rex::Commands::Run::i_run('true') }
  );
  ok($rec->{trapped}, 'trap fired');
  like($rec->{error}, qr/unmocked Rex::Commands::Run::i_run/, 'and names the function');
};

done_testing;
