package Test::RexGPU::Golden;

use strict;
use warnings;

# -----------------------------------------------------------------------------
# Characterization ("golden") harness for Rex::GPU::NVIDIA (karr #29, T0 of
# epic #25).
#
# record_host() runs a piece of Rex::GPU code against a SCRIPTED host: every
# Rex function the module reaches for (run, pkg, file, can_run, the OS facts,
# Rex::Logger::info) is swapped for a recorder for the duration of one call and
# restored afterwards, even when the call dies. The recorder returns canned
# output keyed by the exact command string (or a regex), sets $? the way Rex
# does, and appends one line per host interaction to an ordered transcript.
# golden_is() compares that transcript with t/golden/<name>.txt.
#
# What the transcript is: the exact command strings handed to Rex, in order.
# What it is NOT: what the remote shell makes of them. Pipes, `|| true`,
# `$(...)`, `2>/dev/null` and sed expressions inside a command string are
# recorded verbatim and never evaluated -- a wrong sed or awk in a command is
# invisible here. Canned outputs are hand-written stand-ins, not captures from
# a real host.
#
# Scope of a swap: Rex::Exporter exports by aliasing the whole glob, so
# Rex::GPU::NVIDIA::run IS Rex::Commands::Run::run (and Rex::GPU::Detect::run).
# While a recording runs, every run/pkg/file/can_run/is_installed call in the
# process is recorded, whoever makes it (is_installed since karr #46, for
# Detect's pciutils bootstrap). Rex functions the harness does not mock --
# i_run, cat, get_operating_system, Rex::get_current_connection
# -- are replaced by traps that die, so a code path the harness does not know
# about fails the test instead of reaching a host. A refactor that starts
# using one of them must extend this harness first.
#
# Regenerate intentionally (never to make a red test green without reading
# the diff):
#
#   REX_GPU_GOLDEN_UPDATE=1 prove -l t/96-golden-driver.t t/97-golden-toolkit.t
#   git diff t/golden/
# -----------------------------------------------------------------------------

use Carp qw( croak );
use Exporter qw( import );
use Path::Tiny qw( path );
use Test::More;

use Rex::Commands::File ();
use Rex::Commands::Gather ();
use Rex::Commands::Pkg ();
use Rex::Commands::Run ();
use Rex::Logger ();
use Rex::GPU::Detect ();
use Rex::GPU::NVIDIA ();

our @EXPORT_OK = qw(
  record_host
  golden_is
  host_names
  host_profile
  gpu_fixture
  mutating_lines
  transcript
  working_driver
);

my $GOLDEN_DIR = path(__FILE__)->absolute->parent(4)->child('golden');

#### Host profiles ############################################################
#
# One fresh host per OS: no NVIDIA driver loaded, the pieces install_driver
# probes answer the way a stock Hetzner image of that release would. OS names
# and release strings are what Rex 1.16 returns there (Rocky/Alma without
# lsb_release => "Redhat", openSUSE => "SuSE"; release keeps its dots).

my @COMMON = (
  [ 'nvidia-smi -L 2>&1'                   => 'bash: line 1: nvidia-smi: command not found', 127 ],
  [ q{lsmod | grep '^nvidia '}             => '', 1 ],
  # no CUDA library in the linker cache (karr #42); a test with a working
  # driver scripts it present
  [ qr{^/sbin/ldconfig -p }                => '', 1 ],
  [ qr{^dpkg -l \S+ 2>/dev/null \| grep -q '\^ii'$} => '', 0 ],
  [ q{rpm -q --qf '%{VERSION}' nvidia-driver 2>&1} => '580.95.05', 0 ],
  [ qr{^rpm -q (?:--whatprovides )?(\S+) 2>&1$} => 'installed', 0 ],
  [ 'uname -m'                             => 'x86_64', 0 ],
  [ 'dpkg --print-architecture'            => 'amd64', 0 ]
);

my %UBUNTU_POLICY = (
  '22.04' => "nvidia-driver-580-server:\n  Installed: (none)\n"
    . "  Candidate: 580.95.05-0ubuntu0.22.04.1\n",
  '24.04' => "nvidia-driver-580-server:\n  Installed: (none)\n"
    . "  Candidate: 580.95.05-0ubuntu0.24.04.2\n"
);

my %HOST = (
  'debian-12' => {
    os => 'Debian', release => '12.11',
    responses => [
      [ 'uname -r' => '6.1.0-37-amd64', 0 ],
      # classic one-line sources.list, main only: rewritten with every
      # component added (the same text the pre-#40 sed produced)
      [ 'cat /etc/apt/sources.list 2>/dev/null' =>
          "deb http://deb.debian.org/debian bookworm main\n"
        . "deb http://deb.debian.org/debian bookworm-updates main\n"
        . "deb http://security.debian.org/debian-security bookworm-security main\n", 0 ],
      # ... and no deb822 .sources files next to it
      [ 'ls -1 /etc/apt/sources.list.d/ 2>/dev/null' => '', 0 ]
    ]
  },
  'debian-13' => {
    os => 'Debian', release => '13.1',
    responses => [
      [ 'uname -r' => '6.12.48+deb13-amd64', 0 ],
      # deb822 only (/etc/apt/sources.list.d/debian.sources): no sources.list
      [ 'cat /etc/apt/sources.list 2>/dev/null' => '', 1 ],
      [ 'ls -1 /etc/apt/sources.list.d/ 2>/dev/null' => 'debian.sources', 0 ],
      # what the trixie installer writes (cat output: last newline chomped)
      [ 'cat /etc/apt/sources.list.d/debian.sources 2>/dev/null' =>
          "Types: deb\n"
        . "URIs: http://deb.debian.org/debian/\n"
        . "Suites: trixie trixie-updates\n"
        . "Components: main non-free-firmware\n"
        . "Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp\n"
        . "\n"
        . "Types: deb\n"
        . "URIs: http://security.debian.org/debian-security/\n"
        . "Suites: trixie-security\n"
        . "Components: main non-free-firmware\n"
        . "Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp", 0 ]
    ]
  },
  'ubuntu-22.04' => {
    os => 'Ubuntu', release => '22.04',
    responses => [
      [ 'uname -r' => '5.15.0-151-generic', 0 ],
      [ qr{^apt-cache search .*-server-open\$'} => 'nvidia-driver-580-server-open', 0 ],
      [ qr{^apt-cache search .*-server\$'}      => 'nvidia-driver-580-server', 0 ],
      [ qr{^LC_ALL=C apt-cache policy }         => $UBUNTU_POLICY{'22.04'}, 0 ]
    ]
  },
  'ubuntu-24.04' => {
    os => 'Ubuntu', release => '24.04',
    responses => [
      [ 'uname -r' => '6.8.0-85-generic', 0 ],
      [ qr{^apt-cache search .*-server-open\$'} => 'nvidia-driver-590-server-open', 0 ],
      [ qr{^apt-cache search .*-server\$'}      => 'nvidia-driver-590-server', 0 ],
      [ qr{^LC_ALL=C apt-cache policy }         => $UBUNTU_POLICY{'24.04'}, 0 ]
    ]
  },
  'rocky-9' => {
    os => 'Redhat', release => '9.6',
    responses => [
      [ 'uname -r' => '5.14.0-570.17.1.el9_6.x86_64', 0 ],
      [ 'cat /etc/os-release 2>/dev/null' => _os_release('Rocky Linux', 'rocky', 'rhel centos fedora', '9.6'), 0 ]
    ]
  },
  'rocky-10' => {
    os => 'Redhat', release => '10.0',
    responses => [
      [ 'uname -r' => '6.12.0-55.12.1.el10_0.x86_64', 0 ],
      [ 'cat /etc/os-release 2>/dev/null' => _os_release('Rocky Linux', 'rocky', 'rhel centos fedora', '10.0'), 0 ]
    ]
  },
  # karr #39: the same kind of hosts with lsb_release installed. Rex then
  # takes the name from `lsb_release -s -i`: redhat-lsb-core 4.1 prints
  # "Rocky" for Rocky Linux, EPEL 9's lsb_release "RockyLinux"; both print
  # "AlmaLinux" for AlmaLinux. Rex 1.16's is_redhat knows none of them.
  'rocky-9-lsb' => {
    os => 'Rocky', release => '9.6',
    responses => [
      [ 'uname -r' => '5.14.0-570.17.1.el9_6.x86_64', 0 ],
      [ 'cat /etc/os-release 2>/dev/null' => _os_release('Rocky Linux', 'rocky', 'rhel centos fedora', '9.6'), 0 ]
    ]
  },
  'alma-9-lsb' => {
    os => 'AlmaLinux', release => '9.6',
    responses => [
      [ 'uname -r' => '5.14.0-570.17.1.el9_6.x86_64', 0 ],
      [ 'cat /etc/os-release 2>/dev/null' => _os_release('AlmaLinux', 'almalinux', 'rhel centos fedora', '9.6'), 0 ]
    ]
  },
  # RHEL itself, no lsb_release (RHEL 9 ships none): Rex reads
  # /etc/redhat-release and reports "Redhat", as for Rocky/Alma. Only
  # /etc/os-release (ID=rhel) tells them apart.
  'rhel-9' => {
    os => 'Redhat', release => '9.6',
    responses => [
      [ 'uname -r' => '5.14.0-570.12.1.el9_6.x86_64', 0 ],
      [ 'cat /etc/os-release 2>/dev/null' => _os_release('Red Hat Enterprise Linux', 'rhel', 'fedora', '9.6'), 0 ]
    ]
  },
  'leap-15.6' => {
    os => 'SuSE', release => '15.6',
    responses => [ [ 'uname -r' => '6.4.0-150600.23.73-default', 0 ] ]
  },
  'leap-16.0' => {
    os => 'SuSE', release => '16.0',
    responses => [ [ 'uname -r' => '6.12.0-160000.26-default', 0 ] ]
  }
);

# The os-release(5) lines Setup::RHEL reads (cat output: last newline chomped).
sub _os_release {
  my ( $name, $id, $id_like, $version_id ) = @_;
  return join("\n",
    'NAME="'.$name.'"',
    'VERSION="'.$version_id.'"',
    'ID="'.$id.'"',
    'ID_LIKE="'.$id_like.'"',
    'VERSION_ID="'.$version_id.'"');
}

sub host_names { sort keys %HOST }

# Responses of a host whose driver works: nvidia-smi lists a GPU and
# libcuda.so.1 is in the linker cache -- what already_installed needs (karr
# #42). Put them into host_profile(..., responses => [ working_driver() ]).
sub working_driver {
  return (
    [ 'nvidia-smi -L 2>&1' => 'GPU 0: NVIDIA RTX 4000 SFF Ada Generation (UUID: GPU-0)', 0 ],
    [ qr{^/sbin/ldconfig -p } => '', 0 ]
  );
}

# host_profile($name, %override) -- a fresh copy; `responses` given here are
# consulted BEFORE the profile's own, `release`/`os` replace the profile's.
# A response's output may be a CODE ref returning (output, exit) per call.
# `installed => { pciutils => 1 }` answers Rex::GPU::Detect's is_installed.
sub host_profile {
  my ( $name, %override ) = @_;
  my $base = $HOST{$name} or croak __PACKAGE__.': unknown host profile '.$name;
  return {
    name      => $name,
    os        => $override{os}      // $base->{os},
    release   => $override{release} // $base->{release},
    can_run   => { %{ $override{can_run} // {} } },
    installed => { %{ $override{installed} // {} } },
    responses => [ @{ $override{responses} // [] }, @{ $base->{responses} }, @COMMON ]
  };
}

#### GPU fixtures #############################################################
#
# Built through the real lspci parser, so device_id/compute are what
# gpu_setup would pass in gpus => [...].

my %GPU_LINE = (
  ada       => '01:00.0 VGA compatible controller [0300]: NVIDIA Corporation AD104GL [RTX 4000 SFF Ada Generation] [10de:27b0] (rev a1)',
  blackwell => '01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GB202 [GeForce RTX 5090] [10de:2b85] (rev a1)',
  volta     => '3b:00.0 3D controller [0302]: NVIDIA Corporation GV100GL [Tesla V100 PCIe 16GB] [10de:1db4] (rev a1)',
  # multi-GPU fixtures (karr #33); names hand-written like the others
  b200      => '18:00.0 3D controller [0302]: NVIDIA Corporation GB100 [B200] [10de:2901] (rev a1)',
  b300      => '19:00.0 3D controller [0302]: NVIDIA Corporation GB110 [B300 SXM6 AC] [10de:3182] (rev a1)',
  # NVL72 compute tray GPU (karr #49), name hand-written
  gb200     => '0009:01:00.0 3D controller [0302]: NVIDIA Corporation GB100 [GB200] [10de:2941] (rev a1)',
  # compute 0 since karr #55 (skipped by detection); install_driver is
  # still handed it directly to prove it refuses a Kepler on its own
  kepler    => '04:00.0 3D controller [0302]: NVIDIA Corporation GK210GL [Tesla K80] [10de:102d] (rev a1)',
  # entry-level Pascal / Maxwell desktop cards, compute by generation (karr
  # #54); names as pci.ids 2026-09-24 resolves them
  pascal    => '01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GP108 [GeForce GT 1030] [10de:1d01] (rev a1)',
  maxwell   => '01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GM204 [GeForce GTX 980] [10de:13c0] (rev a1)',
  # HGX H100 GPU (karr #23), name as pci.ids 2025 resolves 10de:2330
  h100      => '18:00.0 3D controller [0302]: NVIDIA Corporation GH100 [H100 SXM5 80GB] [10de:2330] (rev a1)'
);

sub gpu_fixture {
  my ( $name ) = @_;
  return undef if $name eq 'none';
  my $line = $GPU_LINE{$name} or croak __PACKAGE__.': unknown GPU fixture '.$name;
  my $gpu;
  _with_subs({ 'Rex::Logger::info' => sub { } }, [],
    sub { $gpu = Rex::GPU::Detect::_parse_nvidia_line($line) });
  return $gpu;
}

#### Recorder #################################################################

# record_host(host => host_profile(...), code => sub { ... })
# => { lines => [...], logs => [[level, msg], ...], error => $@|undef, trapped => 0|1 }
# `subs => { 'Pkg::name' => sub {...} }` adds mocks for the call; a mock beats
# the trap on the same glob (karr #63: Rex::get_current_connection for
# _reboot_and_wait). What they do is not in the transcript -- the test that
# passes them records it itself.
sub record_host {
  my ( %arg ) = @_;
  my $host = $arg{host} or croak __PACKAGE__.'::record_host needs host';
  my $code = $arg{code} or croak __PACKAGE__.'::record_host needs code';

  my ( @lines, @logs );
  my $trapped = 0;

  my $trap = sub {
    my ( $sym ) = @_;
    return sub {
      $trapped = 1;
      croak __PACKAGE__.': unmocked '.$sym.' reached -- extend the harness; '
        .'a real call would touch a host';
    };
  };

  my $run = sub {
    my ( $cmd, @rest ) = @_;
    croak __PACKAGE__.': array-form run() is not recorded yet' if ref $rest[0];
    my %opt = @rest;
    push @lines, 'run'._opt_tag(\%opt).': '.$cmd;
    my ( $out, $exit ) = _respond($host->{responses}, $cmd);
    $? = $exit << 8;
    return wantarray ? split( /\n/, $out ) : $out;
  };

  my $pkg = sub {
    my ( $pkgs, %opt ) = @_;
    push @lines, 'pkg: '.join(' ', ref $pkgs ? @$pkgs : $pkgs)
      .join('', map { ' '.$_.'='.$opt{$_} } sort keys %opt);
    return 1;
  };

  my $file = sub {
    my ( $path, %opt ) = @_;
    my $content = delete $opt{content};
    push @lines, 'file: '.$path.join('', map { ' '.$_.'='.$opt{$_} } sort keys %opt);
    if (defined $content) {
      my @c = split /\n/, $content, -1;
      if (@c && $c[-1] eq '') { pop @c }
      else { push @c, '\\ no newline at end of content' }
      push @lines, map { '  | '.$_ } @c;
    }
    return 1;
  };

  # karr #46: Rex::GPU::Detect's pciutils bootstrap asks is_installed before
  # pkg; the answer comes from the profile's `installed` (default: no).
  my $is_installed = sub {
    my ( $name ) = @_;
    push @lines, 'is_installed: '.$name;
    return $host->{installed}{$name} ? 1 : 0;
  };

  my $can_run = sub {
    my ( @cmds ) = @_;
    push @lines, 'can_run: '.join(' ', @cmds);
    for my $c (@cmds) {
      return '/usr/bin/'.$c if $host->{can_run}{$c};
    }
    return undef;
  };

  my $os      = $host->{os};
  my $release = $host->{release};
  my $is_deb  = \&Rex::Commands::Gather::is_debian;
  my $is_rh   = \&Rex::Commands::Gather::is_redhat;
  my $is_suse = \&Rex::Commands::Gather::is_suse;

  my %subs = (
    'Rex::GPU::NVIDIA::run'                      => $run,
    'Rex::GPU::NVIDIA::pkg'                      => $pkg,
    'Rex::GPU::NVIDIA::file'                     => $file,
    'Rex::GPU::NVIDIA::can_run'                  => $can_run,
    'Rex::GPU::Detect::is_installed'             => $is_installed,
    'Rex::GPU::NVIDIA::operating_system'         => sub { $os },
    'Rex::GPU::NVIDIA::operating_system_release' => sub { $release },
    # the real classifiers, fed the scripted OS name
    'Rex::GPU::NVIDIA::is_debian'                => sub { $is_deb->($os) },
    'Rex::GPU::NVIDIA::is_redhat'                => sub { $is_rh->($os) },
    'Rex::GPU::NVIDIA::is_suse'                  => sub { $is_suse->($os) },
    # called fully qualified by NVIDIA.pm; the real operating_system_version
    # resolves through this too, so it strips the dots exactly like Rex does
    'Rex::Commands::Gather::operating_system_release' => sub { $release },
    'Rex::Logger::info' => sub { push @logs, [ $_[1] // 'info', $_[0] ] },
    %{ $arg{subs} // {} }
  );
  my @traps = map { my $s = $_; [ $s => $trap->($s) ] } qw(
    Rex::GPU::NVIDIA::is_installed
    Rex::GPU::NVIDIA::cat
    Rex::GPU::Detect::run
    Rex::GPU::Detect::can_run
    Rex::GPU::Detect::pkg
    Rex::GPU::Detect::is_installed
    Rex::Commands::Run::run
    Rex::Commands::Run::i_run
    Rex::Commands::Run::can_run
    Rex::Commands::Pkg::pkg
    Rex::Commands::File::file
    Rex::Commands::Gather::get_operating_system
    Rex::get_current_connection
  );

  my $error;
  _with_subs(\%subs, \@traps, sub {
    $error = $@ unless eval { $code->(); 1 };
  });
  $? = 0;
  chomp $error if defined $error;

  return { lines => \@lines, logs => \@logs, error => $error, trapped => $trapped };
}

# Swap subs for the duration of $code and restore them no matter how $code
# exits. Rex::Exporter exports by aliasing the WHOLE glob
# (*Rex::GPU::NVIDIA::run = *Rex::Commands::Run::run), so an imported name and
# its source are one glob: they are resolved to the canonical glob first and
# each glob is swapped and restored exactly once. A mock always beats a trap
# on the same glob; the first mock for a glob wins (aliases get equivalent
# mocks). Only existing subs may be swapped -- a typo must not silently create
# an unused one.
sub _with_subs {
  my ( $mocks, $traps, $code ) = @_;
  my ( %orig, %plan );
  no strict 'refs';
  for my $pair (( map { [ $_ => $mocks->{$_} ] } sort keys %$mocks ), @$traps) {
    my ( $sym, $sub ) = @$pair;
    croak __PACKAGE__.': cannot mock '.$sym.' -- no such sub' unless defined &{$sym};
    my $canon = substr(''.*{$sym}, 1);
    $plan{$canon} //= $sub;
  }
  {
    no warnings qw( redefine prototype );
    for my $canon (sort keys %plan) {
      $orig{$canon} = \&{$canon};
      *{$canon} = $plan{$canon};
    }
  }
  my $ok = eval { $code->(); 1 };
  my $err = $@;
  {
    no warnings qw( redefine prototype );
    *{$_} = $orig{$_} for keys %orig;
  }
  die $err unless $ok;
  return;
}

sub _respond {
  my ( $responses, $cmd ) = @_;
  for my $r (@$responses) {
    my ( $match, $out, $exit ) = @$r;
    my $hit = ref $match eq 'Regexp' ? $cmd =~ $match : $cmd eq $match;
    next unless $hit;
    # a CODE response answers per call (a host that changes, e.g. lspci
    # missing before the pciutils install and present after it)
    ( $out, $exit ) = $out->($cmd) if ref $out eq 'CODE';
    return ( $out, $exit // 0 );
  }
  return ( '', 0 );   # unscripted: empty output, success
}

sub _opt_tag {
  my ( $opt ) = @_;
  my %o = %$opt;
  my $explicit_zero = exists $o{auto_die} && defined $o{auto_die} && !$o{auto_die};
  delete $o{auto_die} if $explicit_zero;
  $o{auto_die} = 'default' unless $explicit_zero || exists $o{auto_die};
  return '' unless %o;
  return '('.join(',', map { $_.'='.( $o{$_} // 'undef' ) } sort keys %o).')';
}

#### Classification ###########################################################

# Transcript lines that change the host. Everything else is a read-only probe.
my $RUN = qr{^run(?:\([^)]*\))?: };
my @READ_ONLY = (
  qr{${RUN}nvidia-smi -L },
  qr{${RUN}uname -[rm]$},
  qr{${RUN}dpkg --print-architecture$},
  qr{${RUN}cat \S+ 2>/dev/null$},
  qr{${RUN}ls -1 \S+ 2>/dev/null$},
  qr{${RUN}(?:LC_ALL=C )?apt-cache (?:search|policy) },
  qr{${RUN}dpkg -l \S+ 2>/dev/null \| grep -q '\^(?:ii|\[hi\]i)'$},
  qr{${RUN}nvidia-ctk --version 2>&1$},
  qr{${RUN}test -s \S+$},
  qr{${RUN}rpm -q },
  qr{${RUN}lsmod },
  qr{${RUN}/sbin/ldconfig -p },
  qr{${RUN}dpkg-query -W },
  qr{${RUN}apt-cache madison },
  qr{${RUN}systemctl is-active },
  # karr #50: the Fabric Manager retrofit's probes
  qr{${RUN}nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>&1$},
  qr{${RUN}rpm -qa },
  qr{${RUN}LC_ALL=C apt-get -o DPkg::Lock::Timeout=\d+ -s install },
  qr{${RUN}dnf -q list --showduplicates --available },
  # karr #56: the HGX B200/B300 Fabric State read
  qr{${RUN}nvidia-smi -q 2>&1$},
  qr{^can_run: }
);

sub mutating_lines {
  my ( @lines ) = @_;
  return grep { my $l = $_; !grep { $l =~ $_ } @READ_ONLY } @lines;
}

#### Golden comparison ########################################################

sub transcript {
  my ( $rec ) = @_;
  my @t = @{ $rec->{lines} };
  push @t, 'DIE: '.$rec->{error} if defined $rec->{error};
  return join('', map { $_."\n" } @t);
}

# golden_is($rec, 'driver/debian-12--ada')
sub golden_is {
  my ( $rec, $name, $label ) = @_;
  $label //= 'golden '.$name;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my $file = $GOLDEN_DIR->child($name.'.txt');
  my $got  = transcript($rec);

  if ($rec->{trapped}) {
    fail($label);
    diag('the call reached an unmocked Rex function -- see the DIE line:');
    diag($got);
    return 0;
  }

  # Raw bytes both ways: NVIDIA.pm has no `use utf8`, so its em dashes reach
  # the transcript (via die messages) as UTF-8 byte strings already.
  if ($ENV{REX_GPU_GOLDEN_UPDATE}) {
    $file->parent->mkpath;
    $file->spew_raw(
      '# golden: '.$name."\n"
      .'# Host interactions Rex::GPU emits, in order. Regenerate with'."\n"
      .'# REX_GPU_GOLDEN_UPDATE=1 prove -l t/ -- and read the diff.'."\n"
      .$got
    );
    pass($label.' (written)');
    return 1;
  }

  unless ($file->exists) {
    fail($label);
    diag('missing '.$file.' -- run with REX_GPU_GOLDEN_UPDATE=1 to create it');
    return 0;
  }

  my @want = grep { !/^#/ } $file->lines_raw({ chomp => 1 });
  my @got  = split /\n/, $got;
  return is_deeply(\@got, \@want, $label)
    || diag("got:\n".$got);
}

1;
