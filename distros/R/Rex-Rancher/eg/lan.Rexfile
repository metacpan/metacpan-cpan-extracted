# LAN test node -> single-node RKE2 or K3s cluster, GPU optional,
# optionally a second host joining it as agent.
#
# Meant as a live rig for a machine on the local network: every run goes
# through the public API of Rex::Rancher only, and the `check` task prints
# the control points after each step. Nothing here is Hetzner-specific.
#
# Usage (192.0.2.10 / .11 are placeholders -- use your LAN addresses):
#
#   rex -f eg/lan.Rexfile -T                                   # list tasks
#   rex -f eg/lan.Rexfile -H 192.0.2.10 deploy                 # rke2, no GPU
#   LAN_DIST=k3s rex -f eg/lan.Rexfile -H 192.0.2.10 deploy    # k3s
#   LAN_GPU=1    rex -f eg/lan.Rexfile -H 192.0.2.10 deploy    # + GPU (reboots once)
#   rex -f eg/lan.Rexfile -H 192.0.2.10 rerun                  # idempotency run
#   rex -f eg/lan.Rexfile -H 192.0.2.10 check                  # control points
#   LAN_CILIUM_UPGRADE_TO=1.20.2 \
#     rex -f eg/lan.Rexfile -H 192.0.2.10 cilium_upgrade       # upgrade w/ kubeconfig
#   LAN_SERVER=192.0.2.10 rex -f eg/lan.Rexfile -H 192.0.2.11 join_agent  # agent join
#
# Every run of one test series needs the SAME environment (LAN_DIST, LAN_GPU,
# ...): `rerun` and `check` read them to know what they are looking at.
#
# Environment (all optional unless noted):
#
#   LAN_DIST              rke2 (default) or k3s
#   LAN_GPU               1 = gpu => 1 on the server (Rex::GPU needed), default 0
#   LAN_REBOOT            reboot after a driver install; default: LAN_GPU
#   LAN_SERVER            the server's LAN address; default: the -H host.
#                         Used as tls_san (so as kubeconfig server address and,
#                         on K3s, Cilium's k8s_service_host). REQUIRED for `join_agent`.
#   LAN_KUBECONFIG        local kubeconfig; default ~/.kube/lan-<dist>.yaml
#   LAN_TOKEN             cluster token; default: none, the server generates
#                         one and reuses it on every re-run, `join_agent` reads it
#                         from the server
#   LAN_VERSION           pinned rke2/k3s version (e.g. v1.33.4+rke2r1)
#   LAN_CILIUM_VERSION    Cilium version for deploy/rerun (library default 1.20.0)
#   LAN_CILIUM_CLI_VERSION Cilium CLI version (for a newer Cilium)
#   LAN_CILIUM_UPGRADE_TO Cilium version for `cilium_upgrade` (REQUIRED there)
#   LAN_CLUSTER_CIDR      cluster_cidr (pod network), e.g. 10.44.0.0/16
#   LAN_HOSTNAME / LAN_DOMAIN / LAN_TIMEZONE   passed to prepare_node when set
#   LAN_AGENT_GPU         1 = gpu => 1 on the joining agent, default 0
#   LAN_AGENT_HOSTNAME    hostname for the agent (when set)
#   LAN_JOIN_URL          override the agent's join URL, e.g. a wrong address
#                         to see the join hint of install_agent (karr k44)
#   LAN_USER / LAN_KEY    SSH user (root) and private key (~/.ssh/id_ed25519)
#
# Prerequisites on the machine(s): fresh Debian/Ubuntu/Rocky, root SSH login
# with your key. The LibSSH backend needs no SFTP subsystem -- to rehearse an
# SFTP-less host, comment out `Subsystem sftp` in /etc/ssh/sshd_config and
# restart sshd; `check` shows what sshd has configured.
#
# For development (both repos checked out):
#   PERL5LIB=lib:../rex-gpu/lib:$PERL5LIB rex -f eg/lan.Rexfile -H <IP> deploy

use Rex -feature => ['1.4'];
use Rex::LibSSH;
use Rex::Rancher;
use Rex::Rancher::Server;    # get_token
use Rex::Rancher::Cilium;    # upgrade_cilium
use Kubernetes::REST::Kubeconfig;

# --- Configuration ---

my $DIST = $ENV{LAN_DIST} || 'rke2';
die "LAN_DIST must be rke2 or k3s, not '$DIST'\n"
  unless $DIST eq 'rke2' || $DIST eq 'k3s';

my $GPU        = $ENV{LAN_GPU} ? 1 : 0;
my $REBOOT     = defined $ENV{LAN_REBOOT} ? ( $ENV{LAN_REBOOT} ? 1 : 0 ) : $GPU;
my $KUBECONFIG = $ENV{LAN_KUBECONFIG} || $ENV{HOME}.'/.kube/lan-'.$DIST.'.yaml';

# What differs between the two distributions, as far as this Rexfile has to
# look at the host itself. The library keeps its own table; this one is only
# for the `check` and `rerun` output.
my %HOST = (
  rke2 => {
    server_service => 'rke2-server',
    agent_service  => 'rke2-agent',
    binary         => 'rke2',
    data_dir       => '/var/lib/rancher/rke2',
    config_dir     => '/etc/rancher/rke2',
    join_port      => 9345
  },
  k3s => {
    server_service => 'k3s',
    agent_service  => 'k3s-agent',
    binary         => 'k3s',
    data_dir       => '/var/lib/rancher/k3s',
    config_dir     => '/etc/rancher/k3s',
    join_port      => 6443
  }
);
my $D = $HOST{$DIST};

# --- Connection ---

set connection  => 'LibSSH';
set user        => ( $ENV{LAN_USER} || 'root' );
set private_key => ( $ENV{LAN_KEY}  || $ENV{HOME}.'/.ssh/id_ed25519' );
set public_key  => ( $ENV{LAN_KEY}  ? $ENV{LAN_KEY}.'.pub' : $ENV{HOME}.'/.ssh/id_ed25519.pub' );
set auth        => 'key';

# ============================================================
#  Option builders
# ============================================================

sub server_address { $ENV{LAN_SERVER} || connection->server }

sub node_opts {
  my ( $prefix ) = @_;
  return (
    $ENV{$prefix.'HOSTNAME'} ? ( hostname => $ENV{$prefix.'HOSTNAME'} ) : (),
    $ENV{LAN_DOMAIN}         ? ( domain   => $ENV{LAN_DOMAIN} )         : (),
    $ENV{LAN_TIMEZONE}       ? ( timezone => $ENV{LAN_TIMEZONE} )       : ()
  );
}

sub server_opts {
  return (
    distribution    => $DIST,
    gpu             => $GPU,
    reboot          => $REBOOT,
    tls_san         => server_address(),
    kubeconfig_file => $KUBECONFIG,
    node_opts('LAN_'),
    $ENV{LAN_TOKEN}              ? ( token              => $ENV{LAN_TOKEN} )              : (),
    $ENV{LAN_VERSION}            ? ( version            => $ENV{LAN_VERSION} )            : (),
    $ENV{LAN_CLUSTER_CIDR}       ? ( cluster_cidr       => $ENV{LAN_CLUSTER_CIDR} )       : (),
    $ENV{LAN_CILIUM_VERSION}     ? ( cilium_version     => $ENV{LAN_CILIUM_VERSION} )     : (),
    $ENV{LAN_CILIUM_CLI_VERSION} ? ( cilium_cli_version => $ENV{LAN_CILIUM_CLI_VERSION} ) : ()
  );
}

sub deploy_server {
  rancher_deploy_server( server_opts() );
  untaint_node( kubeconfig => $KUBECONFIG );
}

# ============================================================
#  Test plan (karr k53)
# ============================================================

desc 'Full server deployment: prepare -> [GPU] -> '.$DIST.' -> kubeconfig -> Cilium -> [device plugin] -> untaint';
task 'deploy', sub {
  deploy_server();
  say '';
  say 'Done. export KUBECONFIG='.$KUBECONFIG;
  say 'Next: rex -f eg/lan.Rexfile -H '.connection->server.' check';
};

desc 'Same deploy again; compares the service and the Cilium release before and after';
task 'rerun', sub {
  my $before = snapshot();
  deploy_server();
  my $after = snapshot();

  say '';
  say '=== Re-run result ===';
  printf "  %-24s %s -> %s\n", $_, $before->{$_}, $after->{$_} for sort keys %$before;

  my $restarted = $before->{service} ne $after->{service};
  if ( $DIST eq 'k3s' ) {
    say '  '.$D->{server_service}.' '.( $restarted ? 'restarted' : 'NOT restarted' )
      .' -- K3s is restarted on every run by design (install script rewrites the unit)';
  }
  else {
    say $restarted
      ? '  FAIL: '.$D->{server_service}.' was restarted -- a re-run with the same options must stay at start'
      : '  OK: '.$D->{server_service}.' kept running (systemctl start, no restart)';
  }
  say $before->{cilium_release} eq $after->{cilium_release}
    ? '  OK: Cilium release untouched (noop)'
    : '  NOTE: Cilium release changed -- expected only if version/values differ from the last run';
};

desc 'Upgrade Cilium through the saved kubeconfig to LAN_CILIUM_UPGRADE_TO, waiting until ready';
task 'cilium_upgrade', sub {
  my $to = $ENV{LAN_CILIUM_UPGRADE_TO}
    or die "Set LAN_CILIUM_UPGRADE_TO to the Cilium version to upgrade to\n";
  -f $KUBECONFIG or die 'No kubeconfig at '.$KUBECONFIG." -- run deploy first\n";

  upgrade_cilium(
    distribution => $DIST,
    kubeconfig   => $KUBECONFIG,
    version      => $to,
    wait         => 1,
    $DIST eq 'k3s'               ? ( k8s_service_host => server_address() )            : (),
    $ENV{LAN_CILIUM_CLI_VERSION} ? ( cli_version      => $ENV{LAN_CILIUM_CLI_VERSION} ) : ()
  );
  say 'Cilium release now: '.cilium_release();
};

desc 'Join this host as agent to LAN_SERVER (token read from the server unless LAN_TOKEN)';
task 'join_agent', sub {
  my $server = $ENV{LAN_SERVER}
    or die "Set LAN_SERVER to the server's LAN address\n";
  my $url = $ENV{LAN_JOIN_URL} || 'https://'.$server.':'.$D->{join_port};

  # Read before the agent is touched; the token is never printed.
  my $token = $ENV{LAN_TOKEN} || run_task( 'join_token', on => $server );
  die 'No join token from '.$server." -- is the server deployed?\n" unless $token;

  rancher_deploy_agent(
    distribution => $DIST,
    server       => $url,
    token        => $token,
    gpu          => ( $ENV{LAN_AGENT_GPU} ? 1 : 0 ),
    reboot       => ( $ENV{LAN_AGENT_GPU} ? 1 : 0 ),
    node_opts('LAN_AGENT_'),
    -f $KUBECONFIG      ? ( kubeconfig_file => $KUBECONFIG )       : (),
    $ENV{LAN_VERSION}   ? ( version         => $ENV{LAN_VERSION} ) : ()
  );
  say 'Joined '.connection->server.' via '.$url;
};

desc 'Internal: returns the server join token to `join_agent` (prints nothing)';
task 'join_token', sub {
  return get_token($DIST);
};

# ============================================================
#  Control points
# ============================================================

desc 'Print the control points: local via kubeconfig, remote via run';
task 'check', sub {
  my $svc = run( 'systemctl is-active '.$D->{agent_service}.' 2>/dev/null', auto_die => 0 ) eq 'active'
    ? $D->{agent_service} : $D->{server_service};
  my $cd  = $D->{data_dir}.'/agent/etc/containerd';

  section( 'Host '.connection->server.' ('.$DIST.', '.$svc.')' );
  remote( 'binary',        'PATH=$PATH:/usr/local/bin '.$D->{binary}.' --version 2>&1 | head -1' );
  remote( 'is-active',     'systemctl is-active '.$svc );
  remote( 'service',       'systemctl show -p MainPID -p ActiveEnterTimestamp -p NRestarts '.$svc );
  remote( 'config.yaml',   'sed -e "s/^\(token:\).*/\1 <redacted>/" '.$D->{config_dir}.'/config.yaml' );
  remote( 'swap',          'swapon --show --noheadings | grep . || echo off' );
  remote( 'modules',       'lsmod | grep -E "^(br_netfilter|overlay) " | cut -d" " -f1' );
  remote( 'sshd subsystem', 'sshd -T 2>/dev/null | grep -i "^subsystem" || echo "none (SFTP off)"' );

  section('GPU');
  remote( 'nvidia-smi',    'nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>&1' );
  remote( 'libcuda',       'ldconfig -p | grep -m1 libcuda.so.1 || echo missing' );
  remote( 'drop-in',       'ls -1 '.$cd.'/config-v3.toml.d/ 2>/dev/null; cat '.$cd.'/config-v3.toml.d/99-nvidia.toml 2>/dev/null || echo "(no 99-nvidia.toml)"' );
  remote( 'templates',     'ls -1 '.$cd.'/config*.tmpl 2>/dev/null || echo "(none)"' );
  remote( 'nvidia runtime', 'grep -n "nvidia" '.$cd.'/config.toml 2>/dev/null | head -5' );

  return unless $svc eq $D->{server_service};

  section( 'Cluster via '.$KUBECONFIG );
  unless ( -f $KUBECONFIG ) {
    say '  no kubeconfig -- run deploy first';
    return;
  }
  my $api = eval { Kubernetes::REST::Kubeconfig->new( kubeconfig_path => $KUBECONFIG )->api };
  my $nodes = $api && eval { $api->list('Node') };
  unless ($nodes) {
    say '  API not reachable: '.( $@ || 'unknown error' );
    return;
  }
  for my $node ( @{ $nodes->items } ) {
    my $st      = $node->status;
    my ($ready) = grep { $_->type eq 'Ready' } @{ $st->conditions // [] };
    my $taints  = join ',', map { $_->key.':'.$_->effect } @{ $node->spec->taints // [] };
    printf "  %-20s %-9s %-22s nvidia.com/gpu=%s taints=%s\n",
      $node->metadata->name,
      ( $ready && $ready->status eq 'True' ? 'Ready' : 'NotReady' ),
      $st->nodeInfo->kubeletVersion,
      ( ( $st->capacity // {} )->{'nvidia.com/gpu'} // 0 ),
      ( $taints || '-' );
  }
  for my $ds (qw( cilium nvidia-device-plugin-daemonset )) {
    my $obj = eval { $api->get( 'DaemonSet', $ds, namespace => 'kube-system' ) };
    my $s   = $obj && $obj->status;
    say '  DaemonSet '.$ds.': '
      .( $s ? ( $s->numberReady // 0 ).'/'.( $s->desiredNumberScheduled // 0 ).' ready' : 'absent' );
  }
  say '  Cilium Helm release: '.cilium_release($api);
};

# ============================================================
#  Helpers for check / rerun
# ============================================================

sub section { say ''; say '=== '.$_[0].' ===' }

sub remote {
  my ( $label, $cmd ) = @_;
  my $out = run( $cmd, auto_die => 0 );
  $out = '(no output)' unless length $out;
  my @lines = split /\n/, $out;
  printf "  %-15s %s\n", $label, shift @lines;
  printf "  %-15s %s\n", '', $_ for @lines;
}

# Newest revision of Cilium's Helm release as "vN status chart", or 'none'.
sub cilium_release {
  my ( $api ) = @_;
  return 'no kubeconfig' unless -f $KUBECONFIG;
  $api //= eval { Kubernetes::REST::Kubeconfig->new( kubeconfig_path => $KUBECONFIG )->api };
  my $list = $api && eval {
    $api->list( 'Secret', namespace => 'kube-system', labelSelector => 'owner=helm,name=cilium' );
  };
  return 'unreadable ('.( $@ || 'no API' ).')' unless $list;
  my ($newest) = sort { $b->{version} <=> $a->{version} }
    map { $_->metadata->labels // {} } @{ $list->items // [] };
  return 'none' unless $newest;
  return 'v'.$newest->{version}.' '.( $newest->{status} // '?' );
}

sub snapshot {
  my $svc = $D->{server_service};
  my $out = run( 'systemctl show -p MainPID -p ActiveEnterTimestamp '.$svc, auto_die => 0 );
  $out =~ s/\n/ /g;
  return { service => $out, cilium_release => cilium_release() };
}

# ============================================================
#  Pre-connect host-key scan (Rex::LibSSH >= 0.004)
# ============================================================
#
# A freshly installed LAN machine has no known_hosts entry; scan it in before
# the verified connect instead of switching verification off. Must come after
# the task definitions: 'before' attaches to tasks that already exist. After
# a reinstall the old key is stale -- remove it first (ssh-keygen -R <IP>).
before 'ALL' => sub {
  my ( $server ) = @_;
  rancher_scan_known_hosts($server);
};

1;
