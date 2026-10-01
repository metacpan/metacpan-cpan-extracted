use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# k56: without version, curl | sh installs whatever the stable channel is at,
# and restart_reasons restarted a running control plane onto it: a silent
# upgrade by a mere re-run. Maintainer decision, for rke2 and k3s alike:
#
#   same minor (patch)      -> restart, pinned or not
#   next minor              -> restart only with version pinned; unpinned:
#                              installed, not restarted, loud warning
#   more than one minor,    -> die BEFORE anything is installed
#   or a downgrade
#   agent newer minor than  -> die before anything is installed (needs the
#   the control plane          control plane's version: kubeconfig)
#
# The version an unpinned install gets comes from the channel URL the install
# script resolves (curl on the host). start_verb checks the installed binary
# against the running one again before any restart. k3s keeps its restart on
# every run otherwise.
#
# run and the Kubernetes API are faked: this proves the decisions, the
# commands and the messages. That the channel redirect, /proc/PID/exe and the
# node list answer like this on a real host is only shown by a live run.
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

# %host: pid (0 = not running), running / installed (version strings),
# channel (the URL the channel redirects to; undef = curl fails).
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
    return "1790000000\n" if $cmd =~ /ps -o etimes=/;
    # Through /proc/PID/exe the binary answers as "exe", rke2 and k3s alike (k68).
    if ( $cmd =~ m{^/proc/\d+/exe --version} ) {
      return defined $host{running} ? "exe version $host{running} (abc)\ngo version go1.22.5\n" : "exec failed\n";
    }
    if ( $cmd =~ /^(rke2|k3s) --version/ ) {
      return defined $host{installed} ? "$1 version $host{installed} (def)\n" : '';
    }
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
sub installed_anything { grep { /get\.(?:rke2|k3s)\.io|^file / } @log }
sub restarted          { grep { /^systemctl (?:start|restart) / } @log }

my $CH_RKE2 = 'https://github.com/rancher/rke2/releases/tag/';
my $CH_K3S  = 'https://github.com/k3s-io/k3s/releases/tag/';

subtest 'parse_release / compare_versions' => sub {
  is_deeply( [ $D->parse_release('v1.30.4+rke2r1') ], [ 1, 30, 4, 1 ], 'rke2' );
  is_deeply( [ $D->parse_release('v1.36.4+k3s2') ], [ 1, 36, 4, 2 ], 'k3s' );
  is_deeply( [ $D->parse_release('1.30.4') ], [ 1, 30, 4, 0 ], 'bare, no v, no revision' );
  is_deeply( [ $D->parse_release('v1.31.0-rc1+rke2r1') ], [ 1, 31, 0, 1 ], 'pre-release tag' );
  is_deeply( [ $D->parse_release($_) ], [], "'".( $_ // 'undef' )."' does not parse" )
    for ( undef, '', 'stable', 'v1.30', 'v1.30.4+rke2r1 (abc)' );
  is( $D->compare_versions('v1.30.4+rke2r1', 'v1.30.4+rke2r2'), -1, 'revision counts' );
  is( $D->compare_versions('v1.30.10+rke2r1', 'v1.30.9+rke2r1'), 1, 'numeric, not string' );
  is( $D->compare_versions('v1.30.4+rke2r1', 'v1.30.4+rke2r1'), 0, 'equal' );
  is( $D->compare_versions('v1.30.4+rke2r1', 'stable'), undef, 'unparseable' );
};

subtest 'version_skew' => sub {
  my @case = (
    [ 'v1.30.4+rke2r1', 'v1.30.4+rke2r1',  'same' ],
    [ 'v1.30.4+rke2r1', '1.30.4+rke2r1',   'same' ],
    [ 'v1.30.4+rke2r1', 'v1.30.5+rke2r1',  'patch' ],
    [ 'v1.30.4+rke2r1', 'v1.30.4+rke2r2',  'patch' ],
    [ 'v1.30.4+rke2r1', 'v1.31.0+rke2r1',  'minor' ],
    [ 'v1.30.9+rke2r3', 'v1.31.0+rke2r1',  'minor' ],
    [ 'v1.30.4+rke2r1', 'v1.32.1+rke2r1',  'jump' ],
    [ 'v1.30.4+k3s1',   'v2.0.0+k3s1',     'jump' ],
    [ 'v1.30.4+rke2r1', 'v1.29.9+rke2r1',  'downgrade' ],
    [ 'v1.30.4+rke2r2', 'v1.30.4+rke2r1',  'downgrade' ],
    [ 'v1.30.5+k3s1',   'v1.30.4+k3s1',    'downgrade' ],
    [ 'v1.30.4+rke2r1', 'nonsense',        undef ],
  );
  is( $D->version_skew( $_->[0], $_->[1] ), $_->[2],
    $_->[0].' -> '.$_->[1].': '.( $_->[2] // 'undef' ) ) for @case;
};

subtest 'the stable channel, resolved on the host' => sub {
  is( $D->new_for('rke2')->channel_url, 'https://update.rke2.io/v1-release/channels/stable', 'rke2 channel' );
  is( $D->new_for('k3s')->channel_url,  'https://update.k3s.io/v1-release/channels/stable',  'k3s channel' );
  is( $D->parse_channel_redirect($CH_RKE2.'v1.36.4+rke2r1'), 'v1.36.4+rke2r1', 'tag' );
  is( $D->parse_channel_redirect($CH_RKE2."v1.36.4%2Brke2r1\n"), 'v1.36.4+rke2r1', '%2B decoded' );
  is( scalar $D->parse_channel_redirect('https://update.rke2.io/v1-release/channels/stable'), undef,
    'no redirect: nothing' );
  is( scalar $D->parse_channel_redirect(undef), undef, 'undef' );

  reset_host( channel => $CH_K3S.'v1.36.4+k3s1' );
  is( $D->new_for('k3s')->channel_version, 'v1.36.4+k3s1', 'k3s version' );
  is_deeply( \@log, [ "curl -fsSL -o /dev/null -w '%{url_effective}' "
    . "'https://update.k3s.io/v1-release/channels/stable' 2>/dev/null" ], 'the command' );
  reset_host();
  is( scalar $D->new_for('rke2')->channel_version, undef, 'curl fails: nothing' );
};

my $rke2 = $D->new_for('rke2');
my $k3s  = $D->new_for('k3s');

subtest 'check_version_skew: before the install' => sub {
  reset_host( pid => 0 );
  is( scalar $rke2->check_version_skew, undef, 'not running, no binary: fresh, nothing to check' );
  is_deeply( \@log, [ 'systemctl show -p MainPID rke2-server 2>/dev/null', 'rke2 --version 2>&1' ],
    'only MainPID and the binary asked, no channel' );

  for my $c (
    [ 'v1.30.5+rke2r1', 'patch' ], [ 'v1.31.2+rke2r1', 'next minor' ], [ 'v1.30.4+rke2r1', 'same' ],
  ) {
    reset_host( pid => 42, running => 'v1.30.4+rke2r1' );
    is( $rke2->check_version_skew( version => $c->[0] ), $c->[0], 'pinned, '.$c->[1].': allowed' );
    ok( !( grep { /^curl/ } @log ), 'pinned: channel not asked' );
  }

  reset_host( pid => 42, running => 'v1.30.4+rke2r1' );
  ok( !eval { $rke2->check_version_skew( version => 'v1.32.1+rke2r1' ); 1 }, 'pinned jump: dies' );
  is( $@, "Refusing to install rke2 v1.32.1+rke2r1: rke2-server runs v1.30.4+rke2r1, and that "
    . "skips a minor version: Kubernetes' version skew policy moves a node one minor version at a "
    . "time. Upgrade to a v1.31 release first (pin version). Nothing was installed; rke2-server "
    . "keeps running v1.30.4+rke2r1.\n", 'message: both versions, the rule, the way out' );

  reset_host( pid => 42, running => 'v1.30.4+rke2r1' );
  ok( !eval { $rke2->check_version_skew( version => 'v1.29.9+rke2r1' ); 1 }, 'pinned downgrade: dies' );
  like( $@, qr/^Refusing to install rke2 v1\.29\.9\+rke2r1: rke2-server runs v1\.30\.4\+rke2r1, and that is a downgrade.*Pin version to v1\.30\.4\+rke2r1 or newer\. Nothing was installed/,
    'message' );

  reset_host( pid => 42, running => 'v1.30.4+rke2r1', channel => $CH_RKE2.'v1.36.4+rke2r1' );
  ok( !eval { $rke2->check_version_skew; 1 }, 'unpinned, channel six minors ahead: dies' );
  like( $@, qr/^Refusing to install rke2 v1\.36\.4\+rke2r1 \(the stable channel's version; version is not pinned\): rke2-server runs v1\.30\.4\+rke2r1/,
    'message says it is the channel' );

  reset_host( pid => 42, running => 'v1.35.2+rke2r1', channel => $CH_RKE2.'v1.36.4+rke2r1' );
  is( $rke2->check_version_skew, 'v1.36.4+rke2r1', 'unpinned, channel one minor ahead: allowed here' );
  like( $info[-1], qr/version not pinned: the stable channel installs v1\.36\.4\+rke2r1/, 'says what it installs' );

  reset_host( pid => 42, running => 'v1.30.4+rke2r1' );
  is( scalar $rke2->check_version_skew, undef, 'channel does not resolve: no die' );
  like( $warn[0], qr/^Could not resolve the version https:\/\/update\.rke2\.io\/v1-release\/channels\/stable would install: .*checked only after the install/,
    'but a warning' );

  reset_host( pid => 42, running => undef );
  is( scalar $rke2->check_version_skew( version => 'v1.32.1+rke2r1' ), undef, 'running version unreadable: no die' );
  like( $warn[0], qr/^Could not ask the running rke2-server/, 'but a warning' );

  reset_host( pid => 7, running => 'v1.30.4+k3s1' );
  ok( !eval { $k3s->check_version_skew( version => 'v1.32.0+k3s1' ); 1 }, 'k3s: the same rule' );
  like( $@, qr/^Refusing to install k3s v1\.32\.0\+k3s1: k3s runs v1\.30\.4\+k3s1/, 'k3s message' );
};

# k63: a stopped service (crashed node, re-run) is checked against the
# binary on disk: after the install nothing is left to compare with.
subtest 'check_version_skew: a stopped service, against the installed binary' => sub {
  for my $c ( [ $rke2, 'rke2-server', 'rke2', '+rke2r1' ], [ $k3s, 'k3s', 'k3s', '+k3s1' ] ) {
    my ( $d, $svc, $bin, $r ) = @$c;

    reset_host( pid => 0, installed => "v1.30.4$r" );
    ok( !eval { $d->check_version_skew( version => "v1.32.1$r" ); 1 }, "$bin: pinned jump: dies" );
    is( $@, "Refusing to install $bin v1.32.1$r: $svc is not running, and the installed $bin is "
      . "v1.30.4$r; that skips a minor version: Kubernetes' version skew policy moves a node one "
      . "minor version at a time. Upgrade to a v1.31 release first (pin version). Nothing was "
      . "installed; $bin v1.30.4$r stays in place.\n", "$bin: message" );
    ok( !( grep { /^\/proc\// } @log ), "$bin: no process asked" );

    reset_host( pid => 0, installed => "v1.30.4$r" );
    ok( !eval { $d->check_version_skew( version => "v1.29.9$r" ); 1 }, "$bin: pinned downgrade: dies" );
    like( $@, qr/^Refusing to install \Q$bin\E v1\.29\.9.*that is a downgrade/, "$bin: downgrade message" );

    reset_host( pid => 0, installed => "v1.30.4$r", channel => ( $bin eq 'k3s' ? $CH_K3S : $CH_RKE2 )."v1.36.4$r" );
    ok( !eval { $d->check_version_skew; 1 }, "$bin: unpinned, channel six minors ahead: dies" );
    like( $@, qr/^Refusing to install \Q$bin\E v1\.36\.4\S+ \(the stable channel's version; version is not pinned\): \Q$svc\E is not running/,
      "$bin: says it is the channel" );

    reset_host( pid => 0, installed => "v1.35.2$r", channel => ( $bin eq 'k3s' ? $CH_K3S : $CH_RKE2 )."v1.36.4$r" );
    is( $d->check_version_skew, "v1.36.4$r", "$bin: unpinned next minor: allowed" );
    is( scalar @warn, 1, "$bin: with one warning" );
    like( $warn[0], qr/^\Q$svc\E is not running, and the installed \Q$bin\E is v1\.35\.2\S+: the stable channel's v1\.36\.4\S+, a new minor version, is installed since version is not pinned, and \Q$svc\E starts on it\. Pin version => 'v1\.35\.2\S+' to stay on it$/,
      "$bin: the warning" );

    for my $v ( "v1.31.0$r", "v1.30.9$r", "v1.30.4$r" ) {
      reset_host( pid => 0, installed => "v1.30.4$r" );
      is( $d->check_version_skew( version => $v ), $v, "$bin: pinned $v: allowed" );
      is_deeply( \@warn, [], "$bin: pinned $v: no warning" );
    }

    reset_host( pid => 0, installed => "v1.30.4$r" );
    is( scalar $d->check_version_skew, undef, "$bin: channel unresolved: no die" );
    like( $warn[0], qr/the version skew against the installed \Q$bin\E v1\.30\.4\S+ is not checked, and \Q$svc\E, which is not running, starts on whatever the install brings$/,
      "$bin: a warning that says it is not checked at all" );
  }

  reset_host( pid => 0, installed => 'v1.30.4+rke2r1' );
  ok( !eval { install_server( token => 't', version => 'v1.32.1+rke2r1' ); 1 }, 'install_server: dies' );
  is_deeply( [ installed_anything() ], [], 'nothing written or installed' );

  reset_host( pid => 0, installed => 'v1.30.4+k3s1' );
  ok( !eval { install_agent( distribution => 'k3s', server => 'https://cp:6443', token => 't',
    version => 'v1.28.1+k3s1' ); 1 }, 'install_agent: dies' );
  like( $@, qr/^Refusing to install k3s v1\.28\.1\+k3s1: k3s-agent\.service is not running/, 'the agent unit' );
  is_deeply( [ installed_anything() ], [], 'nothing written or installed' );
};

subtest 'install_server refuses before it writes or installs anything' => sub {
  for my $c ( [ 'rke2', 'v1.30.4+rke2r1', 'v1.32.1+rke2r1' ], [ 'k3s', 'v1.30.4+k3s1', 'v1.32.1+k3s1' ] ) {
    my ( $dist, $running, $v ) = @$c;
    reset_host( pid => 42, running => $running );
    ok( !eval { install_server( distribution => $dist, token => 't', version => $v ); 1 },
      $dist.': jump dies' );
    like( $@, qr/^Refusing to install \Q$dist $v\E/, $dist.': the skew message' );
    is_deeply( [ installed_anything() ], [], $dist.': no config written, no installer run' );
    is_deeply( [ restarted() ], [], $dist.': nothing restarted' );
  }
};

subtest 'start_verb: the installed binary against the running one' => sub {
  my @case = (
    # dist, running, installed, pinned, verb, warns
    [ 'rke2', 'v1.30.4+rke2r1', 'v1.30.5+rke2r1', 0, 'restart', 0 ],
    [ 'rke2', 'v1.30.4+rke2r1', 'v1.30.5+rke2r1', 1, 'restart', 0 ],
    [ 'rke2', 'v1.30.4+rke2r1', 'v1.31.1+rke2r1', 1, 'restart', 0 ],
    [ 'rke2', 'v1.30.4+rke2r1', 'v1.31.1+rke2r1', 0, 'start',   1 ],
    [ 'rke2', 'v1.30.4+rke2r1', 'v1.30.4+rke2r1', 0, 'start',   0 ],
    [ 'k3s',  'v1.30.4+k3s1',   'v1.30.5+k3s1',   0, 'restart', 0 ],
    [ 'k3s',  'v1.30.4+k3s1',   'v1.31.1+k3s1',   1, 'restart', 0 ],
    [ 'k3s',  'v1.30.4+k3s1',   'v1.31.1+k3s1',   0, 'start',   1 ],
    [ 'k3s',  'v1.30.4+k3s1',   'v1.30.4+k3s1',   0, 'restart', 0 ],
  );
  for my $c (@case) {
    my ( $dist, $running, $installed, $pinned, $verb, $warns ) = @$c;
    my $name = "$dist $running -> $installed, ".( $pinned ? 'pinned' : 'unpinned' );
    reset_host( pid => 42, running => $running, installed => $installed );
    my $d = $D->new_for($dist);
    is( $d->start_verb( pinned => $pinned ), $verb, $name.': '.$verb );
    if ($warns) {
      is( scalar @warn, 1, $name.': one warning' );
      like( $warn[0], qr/^\Q${\ $d->service }\E was NOT restarted: it runs \Q$running\E, and \Q$installed\E is now installed.*Pin version => '\Q$installed\E' to have it restarted, or run: systemctl restart \Q${\ $d->service }\E$/,
        $name.': says it was not restarted, and both ways out' );
      ok( !( grep { /-newermt|config\.toml/ } @log ), $name.': nothing else asked' );
    }
    else {
      is_deeply( \@warn, [], $name.': no warning' );
    }
  }

  for my $c ( [ 'v1.32.1+rke2r1', qr/skips a minor version/ ], [ 'v1.29.1+rke2r1', qr/is a downgrade/ ] ) {
    reset_host( pid => 42, running => 'v1.30.4+rke2r1', installed => $c->[0] );
    ok( !eval { $rke2->start_verb( pinned => 1 ); 1 }, 'installed '.$c->[0].': dies' );
    like( $@, qr/^rke2 \Q$c->[0]\E is installed, but rke2-server runs v1\.30\.4\+rke2r1, and that $c->[1].* rke2-server was not restarted and keeps running v1\.30\.4\+rke2r1; its next start \(a reboot\) runs \Q$c->[0]\E\./,
      'installed '.$c->[0].': says what runs, what is on disk, and the reboot' );
  }

  reset_host( pid => 0, installed => 'v1.36.4+rke2r1' );
  is( $rke2->start_verb, 'start', 'rke2 not running: start, nothing to hold' );
  reset_host( pid => 0, installed => 'v1.36.4+k3s1' );
  is( $k3s->start_verb, 'restart', 'k3s not running: restart as ever' );
  ok( !( grep { /--version/ } @log ), 'not running: no version asked' );
};

subtest 'wired into the server start' => sub {
  reset_host( pid => 42, running => 'v1.30.4+rke2r1', installed => 'v1.31.1+rke2r1' );
  Rex::Rancher::Server::_install( $rke2, undef, undef, 'script' );
  is_deeply( [ restarted() ], [ 'systemctl start --no-block rke2-server' ], 'unpinned minor: start, it keeps running' );
  is( scalar @warn, 1, 'and the warning' );

  reset_host( pid => 42, running => 'v1.30.4+rke2r1', installed => 'v1.31.1+rke2r1' );
  Rex::Rancher::Server::_install( $rke2, undef, 'v1.31.1+rke2r1', 'script' );
  is_deeply( [ restarted() ], [ 'systemctl restart --no-block rke2-server' ], 'pinned minor: restart' );

  reset_host( pid => 42, running => 'v1.30.4+k3s1', installed => 'v1.31.1+k3s1' );
  Rex::Rancher::Server::_install( $k3s, undef, undef, 'script' );
  is_deeply( [ restarted() ], [ 'systemctl start --no-block k3s' ], 'k3s unpinned minor: start' );

  reset_host( pid => 42, running => 'v1.30.4+k3s1', installed => 'v1.32.1+k3s1' );
  ok( !eval { Rex::Rancher::Server::_install( $k3s, undef, undef, 'script' ); 1 }, 'k3s jump after install: dies' );
  is_deeply( [ restarted() ], [], 'k3s jump: not restarted' );
};

# ---------------------------------------------------------------------------
# Agents: never a newer minor than the control plane.
# ---------------------------------------------------------------------------

my %INFO = map { $_ => 'x' } qw( architecture bootID containerRuntimeVersion kernelVersion
  kubeProxyVersion machineID operatingSystem osImage systemUUID );
sub node {
  my ( $name, $version, %labels ) = @_;
  return IO::K8s->new->new_object( 'Node',
    metadata => { name => $name, labels => \%labels },
    status   => { nodeInfo => { %INFO, kubeletVersion => $version } } );
}
our ( @nodes, $cluster_version, $api_error, $api_calls );
{
  package FakeAPI;
  sub new  { bless {}, shift }
  sub list { $main::api_calls++; die $main::api_error if $main::api_error; FakeList->new(@main::nodes) }
  sub cluster_version { $main::cluster_version // 'unknown' }
  package FakeList;
  sub new   { my ( $c, @i ) = @_; bless { items => \@i }, $c }
  sub items { $_[0]{items} }
}
{
  no warnings 'redefine';
  *Rex::Rancher::K8s::_api = sub { FakeAPI->new };
}
my %CP = ( 'node-role.kubernetes.io/control-plane' => 'true' );

subtest 'control_plane_version' => sub {
  local @nodes = (
    node( 'cp1', 'v1.31.2+rke2r1', %CP ),
    node( 'cp2', 'v1.30.9+rke2r1', %CP ),
    node( 'w1',  'v1.29.1+rke2r1' ),
  );
  is( control_plane_version( kubeconfig => 'kc' ), 'v1.30.9+rke2r1',
    'the lowest control-plane kubelet (mid rolling upgrade), workers ignored' );
  local @nodes = ( node( 'm1', 'v1.30.4+k3s1', 'node-role.kubernetes.io/master' => 'true' ) );
  is( control_plane_version( kubeconfig => 'kc' ), 'v1.30.4+k3s1', 'the older master label counts' );
  local @nodes = ( node( 'w1', 'v1.29.1+rke2r1' ) );
  local $cluster_version = 'v1.30.4+rke2r1';
  is( control_plane_version( kubeconfig => 'kc' ), 'v1.30.4+rke2r1', 'no labelled server: /version' );
  local $cluster_version = undef;
  is( scalar control_plane_version( kubeconfig => 'kc' ), undef, "/version 'unknown': nothing" );
  local $api_error = "401 Unauthorized\n";
  ok( !eval { control_plane_version( kubeconfig => 'kc' ); 1 }, 'API error dies' );
};

subtest 'check_agent_version' => sub {
  my $agent = $D->new_for( 'rke2', role => 'agent' );
  ok( $agent->check_agent_version( 'v1.30.9+rke2r1', 'v1.30.4+rke2r1' ), 'newer patch: fine' );
  ok( $agent->check_agent_version( 'v1.29.9+rke2r1', 'v1.30.4+rke2r1' ), 'older minor: fine' );
  ok( !eval { $agent->check_agent_version( 'v1.31.0+rke2r1', 'v1.30.4+rke2r1' ); 1 }, 'newer minor: dies' );
  is( $@, "Refusing the rke2 agent v1.31.0+rke2r1: the control plane runs v1.30.4+rke2r1, and a "
    . "kubelet must never be of a newer minor version than the API server (Kubernetes' version skew "
    . "policy: servers first, then agents). Nothing was installed. Upgrade the servers first, or pin "
    . "version to a v1.30 release.\n", 'message' );
  ok( !eval { $agent->check_agent_version( 'v1.31.0+rke2r1', 'v1.30.4+rke2r1', 1 ); 1 }, 'installed: dies' );
  like( $@, qr/rke2 v1\.31\.0\+rke2r1 is installed, but rke2-agent\.service was not \(re\)started\./, 'installed message' );
};

subtest 'install_agent with kubeconfig' => sub {
  my %join = ( server => 'https://cp:9345', token => 't', kubeconfig => 'kc' );
  local @nodes = ( node( 'cp1', 'v1.30.4+rke2r1', %CP ) );

  reset_host( pid => 0 );
  local $api_calls = 0;
  ok( !eval { install_agent( %join, version => 'v1.31.0+rke2r1' ); 1 }, 'pinned newer minor than the servers: dies' );
  like( $@, qr/^Refusing the rke2 agent v1\.31\.0\+rke2r1: the control plane runs v1\.30\.4\+rke2r1/, 'message' );
  is_deeply( [ installed_anything() ], [], 'nothing written or installed' );
  is( $api_calls, 1, 'the API was asked' );

  reset_host( pid => 0, channel => $CH_RKE2.'v1.36.4+rke2r1' );
  ok( !eval { install_agent(%join); 1 }, 'unpinned, fresh node, channel ahead of the servers: dies' );
  is_deeply( [ installed_anything() ], [], 'nothing installed' );

  reset_host( pid => 0, channel => $CH_RKE2.'v1.30.9+rke2r1', installed => 'v1.30.9+rke2r1' );
  ok( eval { install_agent(%join); 1 }, 'unpinned, channel at a newer patch: joins' ) or diag $@;
  is_deeply( [ restarted() ], [ 'systemctl start --no-block rke2-agent.service' ], 'and is started' );

  reset_host( pid => 0, installed => 'v1.31.0+rke2r1' );
  ok( !eval { install_agent(%join); 1 }, 'channel unresolved, installed a newer minor: dies' );
  like( $@, qr/is installed, but rke2-agent\.service was not \(re\)started/, 'after the install' );
  is_deeply( [ grep { /^systemctl (?:enable|start|restart)/ } @log ], [], 'not enabled, not started' );

  reset_host( pid => 0 );
  local $api_error = "connection refused\n";
  ok( !eval { install_agent( %join, version => 'v1.30.4+rke2r1' ); 1 }, 'API unreachable: dies' );
  like( $@, qr/^Could not read the control plane's version through kc \(connection refused\); nothing was installed\n\z/, 'message' );
  is_deeply( [ @log ], [], 'before the host is touched' );
  local $api_error;

  local $api_calls = 0;
  reset_host( pid => 0, installed => 'v1.31.0+rke2r1' );
  ok( eval { install_agent( server => 'https://cp:9345', token => 't' ); 1 }, 'no kubeconfig: not checked' ) or diag $@;
  is( $api_calls, 0, 'API not asked' );
};

subtest 'rancher_deploy_agent hands kubeconfig_file to install_agent' => sub {
  my ( %got, %pre );
  no warnings 'redefine';
  local *Rex::Rancher::_check_connection       = sub { };
  local *Rex::Rancher::prepare_node            = sub { };
  local *Rex::Rancher::_gpu_setup_if_requested = sub { };
  local *Rex::Rancher::Agent::preflight_agent  = sub { %pre = @_; {} };
  local *Rex::Rancher::install_agent           = sub { %got = @_ };
  Rex::Rancher::rancher_deploy_agent( server => 'https://cp:9345', token => 't', kubeconfig_file => 'kc' );
  is( $got{kubeconfig}, 'kc', 'as kubeconfig' );
  is( $pre{kubeconfig}, 'kc', 'and to the preflight before the node is prepared (k78)' );
  Rex::Rancher::rancher_deploy_agent( server => 'https://cp:9345', token => 't' );
  ok( !exists $got{kubeconfig}, 'without it: none' );
  ok( !exists $pre{kubeconfig}, 'nor to the preflight' );
};

is_deeply( \@perl_warnings, [], 'no Perl warnings' );

done_testing;
