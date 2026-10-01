use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# k78 (kubernetes-ocp k196), maintainer decision 2026-09-27: rancher_deploy_*
# run the checks install_server/install_agent make before they write -- Cilium
# datapath residue (k71), the version skew with hold_running (k56, k77), the
# established cluster-cidr (k67, server only) -- right after _check_connection
# and before prepare_node and the GPU setup. A refused host is then left as it
# was, not half prepared (packages, swap, kernel modules, a GPU driver, maybe
# a reboot). One helper per side (preflight_server, preflight_agent) is what
# both the pipelines and install_* call, so the checks and their order cannot
# drift apart. install_* keep calling it for direct callers.
#
# run and the Kubernetes API are faked, prepare_node, the GPU step and the
# installs are markers: this proves the order and that nothing past the checks
# runs when one dies, not what a real host answers.
# -----------------------------------------------------------------------------

use IO::K8s;
use Rex::Rancher;
use Rex::Rancher::Server;
use Rex::Rancher::Agent;
use Rex::Rancher::K8s;
use Rex::Rancher::Uninstall;
use Rex::Rancher::Distribution;

my $D = 'Rex::Rancher::Distribution';

my @perl_warnings;
$SIG{__WARN__} = sub { push @perl_warnings, @_ };

# %host: pid (0 = not running), running / installed (version strings),
# residue (what the Cilium probe prints), config (config.yaml content; set:
# a server is established on the host).
my ( @log, @order, @warn, %host );
{
  no warnings 'redefine';
  my $run = sub {
    my ( $cmd ) = @_;
    push @log, $cmd;
    $? = 0;
    return $host{residue} // '' if $cmd =~ /^if command -v /;
    return "MainPID=" . ( $host{pid} // 0 ) . "\n" if $cmd =~ /^systemctl show -p MainPID /;
    if ( $cmd =~ /^curl -fsSL -o \/dev\/null -w / ) { $? = 6 << 8; return '' }
    if ( $cmd =~ m{^/proc/\d+/exe --version} ) {
      return defined $host{running} ? "exe version $host{running} (abc)\n" : "exec failed\n";
    }
    if ( $cmd =~ /^(rke2|k3s) --version/ ) {
      return defined $host{installed} ? "$1 version $host{installed} (def)\n" : '';
    }
    if ( $cmd =~ /^systemctl is-active --quiet / || $cmd =~ /^test -[ed] / ) {
      my $there = defined $host{config} && $cmd !~ /^test -d /;
      $? = $there ? 0 : 1 << 8;
      return '';
    }
    return $host{config} // '' if $cmd =~ /^cat '.*config\.yaml'$/;
    return '';
  };
  *Rex::Commands::Run::run    = $run;
  *Rex::Rancher::Server::run  = $run;
  *Rex::Rancher::Agent::run   = $run;
  *Rex::Logger::info = sub { push @warn, $_[0] if ( $_[1] // '' ) eq 'warn' };

  # The checks, recorded in the order they run.
  for my $m (qw( held_version check_version_skew check_established_cluster_cidr )) {
    no strict 'refs';
    my $orig = \&{"Rex::Rancher::Distribution::$m"};
    *{"Rex::Rancher::Distribution::$m"} = sub { push @order, $m; goto &$orig };
  }
  my $residue = \&Rex::Rancher::Uninstall::check_cilium_residue;
  *Rex::Rancher::Uninstall::check_cilium_residue = sub { push @order, 'check_cilium_residue'; goto &$residue };
  my $cp = \&Rex::Rancher::Agent::_control_plane_version;
  *Rex::Rancher::Agent::_control_plane_version = sub { push @order, 'control_plane_version'; goto &$cp };

  # What writes to the host: markers only.
  *Rex::Rancher::_check_connection       = sub { push @order, 'check_connection' };
  *Rex::Rancher::prepare_node            = sub { push @order, 'prepare_node' };
  *Rex::Rancher::_gpu_setup_if_requested = sub { push @order, 'gpu_setup' };
  *Rex::Rancher::install_server          = sub { push @order, 'install_server' };
  *Rex::Rancher::install_agent           = sub { push @order, 'install_agent' };
}

# The Kubernetes API behind kubeconfig_file.
my %INFO = map { $_ => 'x' } qw( architecture bootID containerRuntimeVersion kernelVersion
  kubeProxyVersion machineID operatingSystem osImage systemUUID );
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
sub cp_node {
  my ( $version ) = @_;
  return IO::K8s->new->new_object( 'Node',
    metadata => { name => 'cp1', labels => { 'node-role.kubernetes.io/control-plane' => 'true' } },
    status   => { nodeInfo => { %INFO, kubeletVersion => $version } } );
}

sub reset_host { %host = @_; ( @log, @order, @warn ) = () }
sub touched { grep { /^(?:prepare_node|gpu_setup|install_)/ } @order }

my %REV  = ( rke2 => '+rke2r1', k3s => '+k3s1' );
my %JOIN = ( rke2 => 'https://cp:9345', k3s => 'https://cp:6443' );

sub deploy {
  my ( $dist, $role, %opts ) = @_;
  return $role eq 'server'
    ? Rex::Rancher::rancher_deploy_server( distribution => $dist, token => 't', cilium => 0,
        ( $dist eq 'k3s' ? ( tls_san => 'cp' ) : () ), %opts )
    : Rex::Rancher::rancher_deploy_agent( distribution => $dist, server => $JOIN{$dist}, token => 't', %opts );
}

my %CHECKS = (
  server => [qw( check_cilium_residue check_version_skew check_established_cluster_cidr )],
  agent  => [qw( control_plane_version check_cilium_residue check_version_skew )],
);

for my $dist (qw( rke2 k3s )) {
  my $r = $REV{$dist};
  for my $role (qw( server agent )) {
    my $name = "$dist $role";
    my @checks = @{ $CHECKS{$role} };

    subtest "$name: the checks run after the connection check, before the host is prepared" => sub {
      reset_host( pid => 0 );
      ok( eval { deploy( $dist, $role ); 1 }, 'deploys' ) or diag $@;
      is_deeply( [ @order[ 0 .. $#checks + 3 ] ],
        [ 'check_connection', @checks, 'prepare_node', 'gpu_setup' ],
        'check_connection, the checks in install_*\'s order, then prepare_node and the GPU step' );
    };

    subtest "$name: hold_running is resolved in the preflight, before the skew check" => sub {
      reset_host( pid => 42, running => "v1.30.4$r", installed => "v1.30.4$r" );
      ok( eval { deploy( $dist, $role, hold_running => 1, version => "v1.33.0$r" ); 1 },
        'a version a jump away is not what is installed: no die' ) or diag $@;
      my @pre = @order[ 0 .. ( grep { $order[$_] eq 'prepare_node' } 0 .. $#order )[0] ];
      my ( $held ) = grep { $pre[$_] eq 'held_version' } 0 .. $#pre;
      my ( $skew ) = grep { $pre[$_] eq 'check_version_skew' } 0 .. $#pre;
      ok( defined $held && defined $skew && $held < $skew, 'held_version, then the skew check, before prepare_node' );

      reset_host( pid => 42, running => "v1.30.4$r", installed => "v1.30.4$r" );
      ok( !eval { deploy( $dist, $role, version => "v1.33.0$r" ); 1 }, 'without hold_running: dies' );
      like( $@, qr/^Refusing to install \Q$dist\E v1\.33\.0/, 'the skew message' );
      is_deeply( [ touched() ], [], 'before prepare_node' );
    };

    subtest "$name: Cilium residue dies before the host is prepared" => sub {
      reset_host( pid => 0, residue => "/sys/fs/bpf/cilium\n" );
      ok( !eval { deploy( $dist, $role ); 1 }, 'dies' );
      like( $@, qr/still carries Cilium datapath state from an earlier cluster \(\/sys\/fs\/bpf\/cilium\)/, 'the residue message' );
      is_deeply( [ touched() ], [], 'no prepare_node, no GPU step, no install' );
      ok( !( grep { /--version|^systemctl show/ } @log ), 'nothing asked after it' );
    };

    subtest "$name: a version skew dies before the host is prepared" => sub {
      reset_host( pid => 42, running => "v1.30.4$r", installed => "v1.30.4$r" );
      ok( !eval { deploy( $dist, $role, version => "v1.29.1$r" ); 1 }, 'a downgrade dies' );
      like( $@, qr/^Refusing to install \Q$dist\E v1\.29\.1\Q$r\E: .* that is a downgrade/, 'the skew message' );
      is_deeply( [ touched() ], [], 'no prepare_node, no GPU step, no install' );
    };
  }

  subtest "$dist server: another cluster-cidr dies before the host is prepared" => sub {
    reset_host( pid => 0, config => "token: x\ncluster-cidr: 10.43.0.0/16\n" );
    ok( !eval { deploy( $dist, 'server', cluster_cidr => '10.44.0.0/16' ); 1 }, 'dies' );
    like( $@, qr/^Refusing to install \Q$dist\E with cluster-cidr 10\.44\.0\.0\/16 \(cluster_cidr\): the \Q$dist\E server on this host was set up with 10\.43\.0\.0\/16/,
      'the cluster-cidr message' );
    is_deeply( [ touched() ], [], 'no prepare_node, no GPU step, no install' );
  };

  subtest "$dist agent: the control plane's version is asked before the host is prepared" => sub {
    local @nodes = ( cp_node("v1.30.4$r") );
    reset_host( pid => 0 );
    ok( !eval { deploy( $dist, 'agent', kubeconfig_file => 'kc', version => "v1.31.0$r" ); 1 },
      'a newer minor than the control plane dies' );
    like( $@, qr/^Refusing the \Q$dist\E agent v1\.31\.0\Q$r\E: the control plane runs v1\.30\.4\Q$r\E/, 'the message' );
    is_deeply( [ touched() ], [], 'no prepare_node, no GPU step, no install' );

    reset_host( pid => 42, running => "v1.31.0$r", installed => "v1.31.0$r" );
    ok( !eval { deploy( $dist, 'agent', kubeconfig_file => 'kc', hold_running => 1, version => "v1.30.4$r" ); 1 },
      'hold_running: the held version is what is checked against it' );
    like( $@, qr/^Refusing the \Q$dist\E agent v1\.31\.0\Q$r\E/, 'the held one, not version' );
    is_deeply( [ touched() ], [], 'before prepare_node' );
  };
}

# ---------------------------------------------------------------------------
# The helpers themselves, for install_* and for callers that prepare the node
# on their own (kubernetes-ocp).
# ---------------------------------------------------------------------------

subtest 'preflight_server / preflight_agent' => sub {
  reset_host( pid => 42, running => 'v1.30.4+rke2r1', installed => 'v1.30.4+rke2r1' );
  is_deeply( Rex::Rancher::Server::preflight_server( hold_running => 1, version => 'v1.31.0+rke2r1',
      cluster_cidr => '10.42.0.0/16' ),
    { version => 'v1.30.4+rke2r1', install_method => 'script', cluster_cidr => '10.42.0.0/16' },
    'server: the version, install method and cluster-cidr this run uses' );

  local @nodes = ( cp_node('v1.31.2+k3s1') );
  reset_host( pid => 0, installed => 'v1.30.4+k3s1' );
  is_deeply( Rex::Rancher::Agent::preflight_agent( distribution => 'k3s', hold_running => 1,
      kubeconfig => 'kc' ),
    { version => 'v1.30.4+k3s1', install_method => 'script', server_version => 'v1.31.2+k3s1' },
    'agent: the version, install method and the control plane\'s version' );

  reset_host( pid => 0 );
  ok( !eval { Rex::Rancher::Server::preflight_server( install_method => 'artifact' ); 1 },
    'the pure option checks come first' );
  is_deeply( [ @log ], [], 'before the host is read' );
};

is_deeply( \@perl_warnings, [], 'no Perl warnings' );

done_testing;
