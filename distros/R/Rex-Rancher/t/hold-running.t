use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# k77 (kubernetes-ocp k193, option b): hold_running => 1 keeps a host on the
# version it runs. Maintainer decision 2026-09-27, rke2 and k3s, server and
# agent alike:
#
#   service running         -> its running version (/proc/PID/exe) is the
#                              pinned version for this run
#   running, unreadable     -> the installed binary, with a warning; no
#                              binary either: version, with a warning
#   not running             -> the installed binary; none: version; no
#                              version: unpinned, as without hold_running
#   version given too       -> the held version wins while a service runs
#                              or a binary is installed; one line names both
#   agent                   -> its own version; the control plane skew check
#                              stays
#   restart                 -> only for a changed configuration: rke2 through
#                              restart_reasons (same binary), k3s the same
#                              instead of on every run, plus its install
#                              script's own check (unit and env file content)
#
# Resolved before check_version_skew and before anything is written; the
# held version is then `version` for the skew check, the installer,
# verify_installed_version and start_verb.
#
# run and the Kubernetes API are faked: this proves the decisions, the
# commands and the messages, not that a real host answers like this.
# -----------------------------------------------------------------------------

use IO::K8s;
use Rex::Rancher;
use Rex::Rancher::Server;
use Rex::Rancher::Agent;
use Rex::Rancher::K8s;
use Rex::Rancher::Distribution;

my $D = 'Rex::Rancher::Distribution';

my @perl_warnings;
$SIG{__WARN__} = sub { push @perl_warnings, @_ };

# %host: pid (0 = not running), running / installed (version strings; the
# installer sets installed to the version on its line), channel (redirect
# target; undef = curl fails), since (ps etimes answer), changed (find
# -newermt output), units / units_after (sha256sum of the unit files before
# and after the installer ran).
my ( @log, @info, @warn, %host );
{
  no warnings 'redefine';
  my $run = sub {
    my ( $cmd ) = @_;
    push @log, $cmd;
    $? = 0;
    return "MainPID=" . ( $host{pid} // 0 ) . "\n" if $cmd =~ /^systemctl show -p MainPID /;
    if ( $cmd =~ /^curl -fsSL -o \/dev\/null -w / ) {
      return $host{channel} if defined $host{channel};
      $? = 6 << 8;
      return '';
    }
    return ( $host{since} // 1790000000 ) . "\n" if $cmd =~ /ps -o etimes=/;
    return $host{changed} // '' if $cmd =~ /-newermt /;
    # Through /proc/PID/exe the binary answers as "exe" (k68).
    if ( $cmd =~ m{^/proc/\d+/exe --version} ) {
      return defined $host{running} ? "exe version $host{running} (abc)\ngo version go1.22.5\n" : "exec failed\n";
    }
    if ( $cmd =~ /^(rke2|k3s) --version/ ) {
      return defined $host{installed} ? "$1 version $host{installed} (def)\n" : '';
    }
    if ( $cmd =~ /get\.(?:rke2|k3s)\.io/ ) {
      $host{installed} = $1 if $cmd =~ /INSTALL_(?:RKE2|K3S)_VERSION=(\S+)/;
      $host{units} = $host{units_after} if exists $host{units_after};
      return '';
    }
    return $host{units} // "abc  /etc/systemd/system/unit\n" if $cmd =~ /^sha256sum /;
    return "active\n"              if $cmd =~ /^systemctl is-active /;
    return "yes\n"                 if $cmd =~ /^test -f/;
    return "/usr/local/bin/rke2\n" if $cmd =~ /^command -v rke2/;
    return '';
  };
  *Rex::Commands::Run::run    = $run;
  *Rex::Rancher::Server::run  = $run;
  *Rex::Rancher::Agent::run   = $run;
  *Rex::Commands::File::file  = sub { push @log, 'file '.$_[0] };
  *Rex::Rancher::Server::file = sub { push @log, 'file '.$_[0] };
  *Rex::Commands::File::get_tmp_file_name = sub { '/tmp/.rex.tmp' };
  *Rex::Logger::info = sub { push @{ ( $_[1] // '' ) eq 'warn' ? \@warn : \@info }, $_[0] };
}

sub reset_host { %host = @_; ( @log, @info, @warn ) = () }

# The version on the installer line: undef when it did not run, '' unpinned.
sub installer_version {
  my ( $line ) = grep { /get\.(?:rke2|k3s)\.io/ } @log;
  return unless defined $line;
  return $line =~ /INSTALL_(?:RKE2|K3S)_VERSION=(\S+)/ ? $1 : '';
}
sub started   { grep { /^systemctl (?:start|restart) / } @log }
sub installed_anything { grep { /get\.(?:rke2|k3s)\.io|^file / } @log }

my %REV   = ( rke2 => '+rke2r1', k3s => '+k3s1' );
my %JOIN  = ( rke2 => 'https://cp:9345', k3s => 'https://cp:6443' );
my %CH    = ( rke2 => 'https://github.com/rancher/rke2/releases/tag/',
              k3s  => 'https://github.com/k3s-io/k3s/releases/tag/' );

# install_server or install_agent, as the role says.
sub deploy {
  my ( $dist, $role, %opts ) = @_;
  return $role eq 'server'
    ? install_server( distribution => $dist, token => 't', %opts )
    : install_agent( distribution => $dist, server => $JOIN{$dist}, token => 't', %opts );
}

my @ROLES = map { my $d = $_; map { [ $d, $_ ] } qw( server agent ) } qw( rke2 k3s );

for my $c (@ROLES) {
  my ( $dist, $role ) = @$c;
  my $r    = $REV{$dist};
  my $obj  = $D->new_for( $dist, role => $role );
  my $svc  = $obj->service;
  my $bin  = $obj->binary;
  my $name = "$dist $role";

  subtest "$name: running -> its version is pinned" => sub {
    reset_host( pid => 42, running => "v1.30.4$r", installed => "v1.30.4$r" );
    ok( eval { deploy( $dist, $role, hold_running => 1 ); 1 }, 'installs' ) or diag $@;
    is( installer_version(), "v1.30.4$r", 'the installer gets the running version' );
    ok( !( grep { /^curl -fsSL -o \/dev\/null/ } @log ), 'the stable channel is not asked' );
    ok( ( grep { $_ eq "$bin --version 2>&1" } @log ), 'the installed version is verified' );
    is_deeply( \@warn, [], 'no warning' );
    ok( ( grep { /^hold_running: \Q$svc\E runs v1\.30\.4\Q$r\E/ } @info ), 'says what it holds' );
  };

  subtest "$name: running, version given too -> hold wins, one line names both" => sub {
    reset_host( pid => 42, running => "v1.30.4$r", installed => "v1.30.4$r" );
    ok( eval { deploy( $dist, $role, hold_running => 1, version => "v1.31.1$r" ); 1 }, 'installs' ) or diag $@;
    is( installer_version(), "v1.30.4$r", 'the running version, not version' );
    my @both = grep { /v1\.30\.4\Q$r\E/ && /v1\.31\.1\Q$r\E/ } @warn;
    is( scalar @both, 1, 'one warning names both' );
    like( $both[0] // '', qr/^hold_running: \Q$svc\E runs v1\.30\.4\Q$r\E; that is the version for this run, not version => 'v1\.31\.1\Q$r\E'$/,
      'the line' );
  };

  subtest "$name: running, a jump away from version -> no skew die, held" => sub {
    reset_host( pid => 42, running => "v1.30.4$r", installed => "v1.30.4$r" );
    ok( eval { deploy( $dist, $role, hold_running => 1, version => "v1.33.0$r" ); 1 },
      'hold resolved before the skew check' ) or diag $@;
    is( installer_version(), "v1.30.4$r", 'held' );
  };

  subtest "$name: stopped with a binary -> the binary's version" => sub {
    reset_host( pid => 0, installed => "v1.29.8$r" );
    ok( eval { deploy( $dist, $role, hold_running => 1, version => "v1.30.4$r" ); 1 }, 'installs' ) or diag $@;
    is( installer_version(), "v1.29.8$r", 'the installed binary' );
    ok( !( grep { m{^/proc/} } @log ), 'no process asked' );
    like( join( "\n", @warn ), qr/^hold_running: \Q$svc\E is not running, the installed \Q$bin\E is v1\.29\.8\Q$r\E; that is the version for this run, not version => 'v1\.30\.4\Q$r\E'$/m,
      'both named' );
  };

  subtest "$name: no binary -> version" => sub {
    reset_host( pid => 0 );
    ok( eval { deploy( $dist, $role, hold_running => 1, version => "v1.30.4$r" ); 1 }, 'installs' ) or diag $@;
    is( installer_version(), "v1.30.4$r", 'the pin' );
    ok( ( grep { /^hold_running: \Q$svc\E is not running and no installed \Q$bin\E reports a version: version v1\.30\.4\Q$r\E applies$/ } @info ),
      'says so' );
  };

  subtest "$name: no binary, no version -> unpinned, as without hold_running" => sub {
    reset_host( pid => 0 );
    ok( eval { deploy( $dist, $role, hold_running => 1 ); 1 }, 'installs' ) or diag $@;
    is( installer_version(), '', 'unpinned installer line' );
    reset_host( pid => 0 );
    deploy( $dist, $role );
    is( installer_version(), '', 'the same without hold_running' );
  };

  subtest "$name: running, version unreadable -> the binary, with a warning" => sub {
    reset_host( pid => 42, running => undef, installed => "v1.30.4$r" );
    ok( eval { deploy( $dist, $role, hold_running => 1, version => "v1.30.9$r" ); 1 }, 'installs' ) or diag $@;
    is( installer_version(), "v1.30.4$r", 'the installed binary' );
    like( $warn[0] // '', qr/^Could not ask the running \Q$svc\E \(\/proc\/42\/exe --version\) for its version: hold_running holds the installed \Q$bin\E v1\.30\.4\Q$r\E instead$/,
      'warned' );
  };

  subtest "$name: running, unreadable, no binary -> version, with a warning" => sub {
    reset_host( pid => 42, running => undef );
    ok( eval { deploy( $dist, $role, hold_running => 1, version => "v1.30.9$r" ); 1 }, 'installs' ) or diag $@;
    is( installer_version(), "v1.30.9$r", 'the pin' );
    like( $warn[0] // '', qr/^Could not ask the running \Q$svc\E \(\/proc\/42\/exe --version\) for its version, and no installed \Q$bin\E reports a version: hold_running holds nothing, version v1\.30\.9\Q$r\E applies$/,
      'warned' );
  };
}

# ---------------------------------------------------------------------------
# held_version on its own: the one place install_* (and the pre-checks of
# rancher_deploy_*) resolve it.
# ---------------------------------------------------------------------------

subtest 'held_version' => sub {
  my $rke2 = $D->new_for('rke2');
  reset_host( pid => 42, running => 'v1.30.4+rke2r1' );
  is( $rke2->held_version, 'v1.30.4+rke2r1', 'running' );
  is_deeply( [ @log ], [ 'systemctl show -p MainPID rke2-server 2>/dev/null', '/proc/42/exe --version 2>&1' ],
    'asks MainPID and the process, nothing else' );
  reset_host( pid => 42, running => 'v1.30.4+rke2r1' );
  is( $rke2->held_version( version => 'v1.30.4+rke2r1' ), 'v1.30.4+rke2r1', 'same as version' );
  is_deeply( \@warn, [], 'no warning when they agree' );
  reset_host( pid => 42, running => 'v1.30.4+rke2r1' );
  is( $rke2->held_version( version => '1.30.4+rke2r1' ), 'v1.30.4+rke2r1', 'without the v: the same' );
  is_deeply( \@warn, [], 'no warning' );
  reset_host( pid => 0 );
  is( scalar $rke2->held_version, undef, 'nothing on the host, no version: undef (unpinned)' );
  reset_host( pid => 42, running => 'garbage;rm' );
  $host{installed} = 'v1.30.4+rke2r1';
  is( $rke2->held_version, 'v1.30.4+rke2r1', 'a running version that is no release counts as unreadable' );
  like( $warn[0], qr/^Could not ask the running rke2-server/, 'warned' );
};

# ---------------------------------------------------------------------------
# Agent: its own version, the control plane skew still checked.
# ---------------------------------------------------------------------------

my %INFO = map { $_ => 'x' } qw( architecture bootID containerRuntimeVersion kernelVersion
  kubeProxyVersion machineID operatingSystem osImage systemUUID );
sub node {
  my ( $name, $version, %labels ) = @_;
  return IO::K8s->new->new_object( 'Node',
    metadata => { name => $name, labels => \%labels },
    status   => { nodeInfo => { %INFO, kubeletVersion => $version } } );
}
our @nodes;
{
  package FakeAPI;
  sub new  { bless {}, shift }
  sub list { FakeList->new(@main::nodes) }
  sub cluster_version { 'unknown' }
  package FakeList;
  sub new   { my ( $c, @i ) = @_; bless { items => \@i }, $c }
  sub items { $_[0]{items} }
}
{
  no warnings 'redefine';
  *Rex::Rancher::K8s::_api = sub { FakeAPI->new };
}
my %CP = ( 'node-role.kubernetes.io/control-plane' => 'true' );

for my $dist (qw( rke2 k3s )) {
  my $r = $REV{$dist};
  subtest "$dist agent: its own version against the control plane" => sub {
    local @nodes = ( node( 'cp1', "v1.31.2$r", %CP ) );
    reset_host( pid => 42, running => "v1.30.4$r", installed => "v1.30.4$r" );
    ok( eval { deploy( $dist, 'agent', hold_running => 1, kubeconfig => 'kc', version => "v1.31.2$r" ); 1 },
      'older than the control plane: joins' ) or diag $@;
    is( installer_version(), "v1.30.4$r", 'on its own running version, not the pin' );

    local @nodes = ( node( 'cp1', "v1.30.4$r", %CP ) );
    reset_host( pid => 42, running => "v1.31.0$r", installed => "v1.31.0$r" );
    ok( !eval { deploy( $dist, 'agent', hold_running => 1, kubeconfig => 'kc', version => "v1.30.4$r" ); 1 },
      'held a newer minor than the control plane: dies' );
    like( $@, qr/^Refusing the \Q$dist\E agent v1\.31\.0\Q$r\E: the control plane runs v1\.30\.4\Q$r\E/,
      'the skew message' );
    is_deeply( [ installed_anything() ], [], 'nothing written or installed' );
  };
}

# ---------------------------------------------------------------------------
# Restart only for a changed configuration.
# ---------------------------------------------------------------------------

for my $c (@ROLES) {
  my ( $dist, $role ) = @$c;
  my $r    = $REV{$dist};
  my $obj  = $D->new_for( $dist, role => $role );
  my $svc  = $obj->service;
  my $name = "$dist $role";
  my %RUN  = ( pid => 42, running => "v1.30.4$r", installed => "v1.30.4$r" );

  subtest "$name: held, nothing changed -> not restarted" => sub {
    reset_host(%RUN);
    deploy( $dist, $role, hold_running => 1 );
    is_deeply( [ started() ], [ "systemctl start --no-block $svc" ], 'start: a no-op for the running service' );
    ok( ( grep { /-newermt/ } @log ), 'the configuration was asked' );
    ok( !( grep { /^Restarting/ } @info ), 'no restart logged' );
  };

  subtest "$name: held, config.yaml changed -> restarted" => sub {
    reset_host( %RUN, changed => $obj->config_file."\n" );
    deploy( $dist, $role, hold_running => 1 );
    is_deeply( [ started() ], [ "systemctl restart --no-block $svc" ], 'restart' );
    ok( ( grep { /^Restarting \Q$svc\E, which reads these only when it starts: changed since it started: \Q${\ $obj->config_file }\E$/ } @info ),
      'the log says why' );
  };
}

# An earlier unpinned run left a new minor on disk that the service was not
# restarted onto (k56): held, the running version is installed back.
for my $dist (qw( rke2 k3s )) {
  my $r   = $REV{$dist};
  my $svc = $D->new_for($dist)->service;
  subtest "$dist server: held while a newer minor waits on disk" => sub {
    reset_host( pid => 42, running => "v1.30.4$r", installed => "v1.31.1$r" );
    ok( eval { deploy( $dist, 'server', hold_running => 1 ); 1 }, 'installs' ) or diag $@;
    is( installer_version(), "v1.30.4$r", 'the running version, not the one on disk' );
    is_deeply( [ started() ], [ "systemctl start --no-block $svc" ], 'not restarted' );
  };
}

subtest 'k3s held: the unit the install script rewrote' => sub {
  for my $role (qw( server agent )) {
    my $obj  = $D->new_for( 'k3s', role => $role );
    my $svc  = $obj->service;
    my @unit = $obj->installer_unit_files;
    my $unit = $role eq 'server' ? 'k3s' : 'k3s-agent';
    is_deeply( \@unit, [ "/etc/systemd/system/$unit.service", "/etc/systemd/system/$unit.service.env" ],
      "$role: the unit and env file get.k3s.io writes" );

    reset_host( pid => 42, running => 'v1.30.4+k3s1', installed => 'v1.30.4+k3s1',
      units => "aaa  unit\n", units_after => "bbb  unit\n" );
    deploy( 'k3s', $role, hold_running => 1 );
    is_deeply( [ started() ], [ "systemctl restart --no-block $svc" ], "$role: other content: restart" );
    ok( ( grep { /^Restarting \Q$svc\E, .*rewritten by the installer with other content: \Q$unit[0], $unit[1]\E$/ } @info ),
      "$role: the log names the files" );
    my @sums = grep { /^sha256sum / } @log;
    is( scalar @sums, 2, "$role: asked before and after the installer" );
    is( $sums[0], "sha256sum '$unit[0]' '$unit[1]' 2>&1", "$role: the command" );

    reset_host( pid => 42, running => 'v1.30.4+k3s1', installed => 'v1.30.4+k3s1',
      units => "aaa  unit\n", units_after => "aaa  unit\n" );
    deploy( 'k3s', $role, hold_running => 1 );
    is_deeply( [ started() ], [ "systemctl start --no-block $svc" ], "$role: same content: start" );
  }

  is_deeply( [ $D->new_for('rke2')->installer_unit_files ], [], 'rke2: none, its unit comes with the version' );
  reset_host( pid => 42, running => 'v1.30.4+rke2r1', installed => 'v1.30.4+rke2r1' );
  deploy( 'rke2', 'server', hold_running => 1 );
  ok( !( grep { /^sha256sum / } @log ), 'rke2: not asked' );
};

subtest 'without hold_running: k3s restarts on every run, as before' => sub {
  for my $role (qw( server agent )) {
    my $svc = $D->new_for( 'k3s', role => $role )->service;
    reset_host( pid => 42, running => 'v1.30.4+k3s1', installed => 'v1.30.4+k3s1' );
    deploy( 'k3s', $role, version => 'v1.30.4+k3s1' );
    is_deeply( [ started() ], [ "systemctl restart --no-block $svc" ], "$role: restart" );
    ok( !( grep { /^sha256sum / } @log ), "$role: no unit check" );
  }
};

subtest 'rancher_deploy_* hand hold_running on' => sub {
  my ( %server, %agent );
  no warnings 'redefine';
  local *Rex::Rancher::_check_connection       = sub { };
  local *Rex::Rancher::prepare_node            = sub { };
  local *Rex::Rancher::_gpu_setup_if_requested = sub { };
  local *Rex::Rancher::install_server          = sub { %server = @_ };
  local *Rex::Rancher::install_agent           = sub { %agent = @_ };
  Rex::Rancher::rancher_deploy_server( token => 't', cilium => 0, hold_running => 1 );
  is( $server{hold_running}, 1, 'server' );
  Rex::Rancher::rancher_deploy_agent( server => 'https://cp:9345', token => 't', hold_running => 1 );
  is( $agent{hold_running}, 1, 'agent' );
};

is_deeply( \@perl_warnings, [], 'no Perl warnings' );

done_testing;
