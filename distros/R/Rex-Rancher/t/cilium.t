use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Offline tests for Rex::Rancher::Cilium.
#
# 1. Helm values: the per-distribution defaults are unchanged, caller values
#    deep-merge over them, gateway_api adds gatewayAPI.enabled, and k3s gets
#    kube-proxy replacement at the control plane address (never loopback)
#    with its pool on k3s' cluster-cidr, as kubernetes-ocp k178.
# 2. Release handling: Helm's release Secrets decode to status, chart version
#    and values, and _release_action turns that into install / noop / upgrade
#    / reinstall (or dies where acting could take down a working network).
# 3. The re-run case the old "cannot re-use a name" swallow covered: an
#    existing release at the requested version is a no-op, not a failure --
#    both with a kubeconfig (decided from the release) and without one (the
#    swallow is kept there).
#
# `run`, `file` and the Kubernetes::REST client are faked, so no host or
# cluster is involved. This proves decision logic and command strings, not a
# deploy.
# -----------------------------------------------------------------------------

use IO::Compress::Gzip qw( gzip );
use IO::K8s;
use JSON::MaybeXS;
use MIME::Base64 qw( encode_base64 );
use Rex::Rancher::Cilium;

$Rex::Logger::silent = 1;

my $C = 'Rex::Rancher::Cilium';
my $T = JSON()->true;
my $F = JSON()->false;

# -----------------------------------------------------------------------------
# Fakes: remote shell and local API
# -----------------------------------------------------------------------------

my ( @cmds, %files );
our $run_hook;
{
  no warnings 'redefine';
  *Rex::Rancher::Cilium::run = sub {
    my ( $cmd ) = @_;
    push @cmds, $cmd;
    if ( $cmd =~ /^cilium version --client/ ) { $? = 0; return 'cilium-cli: v0.19.7' }
    if ( $run_hook ) { my @r = $run_hook->( $cmd ); return $r[0] if @r }
    $? = 0;
    return '';
  };
  *Rex::Rancher::Cilium::file = sub { my ( $path, %o ) = @_; $files{$path} = $o{content} };
}

my $k8s = IO::K8s->new;

# Helm stores: base64(gzip(json)); the Secret's data is base64 of that again.
sub helm_secret {
  my ( %a ) = @_;
  my $json = encode_json( {
    name   => 'cilium',
    chart  => { metadata => { name => 'cilium', version => $a{chart_version} } },
    config => $a{config} // {},
  } );
  gzip( \$json => \my $gz );
  my $helm = encode_base64( $gz, '' );
  return {
    name    => 'sh.helm.release.v1.cilium.v'.$a{revision},
    labels  => { owner => 'helm', name => 'cilium', status => $a{status}, version => $a{revision} },
    release => encode_base64( $helm, '' ),
  };
}

{
  package FakeAPI;
  sub new { my ( $class, %a ) = @_; bless { %a, deleted => [], patched => [] }, $class }
  sub list {
    my ( $self ) = @_;
    my @items = map {
      $k8s->struct_to_object( {
        apiVersion => 'v1', kind => 'Secret',
        metadata   => { name => $_->{name}, namespace => 'kube-system', labels => $_->{labels} },
        data       => { release => $_->{release} },
      } )
    } @{ $self->{secrets} // [] };
    return bless { items => \@items }, 'FakeList';
  }
  # What Kubernetes::REST croaks with on a 404 response.
  sub not_found { "Kubernetes API error (get $_[0]): 404 {\"kind\":\"Status\",\"reason\":\"NotFound\"}\n" }
  sub get {
    my ( $self, $kind, $name ) = @_;
    my $obj = $self->{objects}{"$kind/$name"};
    return $obj->() if ref $obj eq 'CODE';
    return $obj if $obj;
    return $self->{daemonset} ? bless( {}, 'FakeObj' ) : die not_found($kind)
      if $kind eq 'DaemonSet';
    die not_found($kind);
  }
  sub delete {
    my ( $self, $kind, $name ) = @_;
    my $err = $self->{delete_errors}{"$kind/$name"};
    die $err if $err;
    push @{ $self->{deleted} }, "$kind/$name";
    1;
  }
  sub patch  { my ( $self, $kind, $name ) = @_; push @{ $self->{patched} }, "$kind/$name"; 1 }
  package FakeList;
  sub items { $_[0]{items} }
}

my $api;
{
  no warnings 'redefine';
  *Rex::Rancher::Cilium::_api = sub { $api };
}

sub values_for { $C->can('_resolve_opts')->( @_ )->{values} }

# -----------------------------------------------------------------------------
# 1. Helm values
# -----------------------------------------------------------------------------

subtest 'rke2 defaults unchanged' => sub {
  my $v = values_for( distribution => 'rke2' );
  is_deeply( $v, {
    cni => { binPath => '/opt/cni/bin', confPath => '/etc/cni/net.d', exclusive => $F },
    ipam                 => { mode => 'kubernetes' },
    operator             => { replicas => 1 },
    kubeProxyReplacement => $T,
    k8sServiceHost       => '127.0.0.1',
    k8sServicePort       => '6443',
  }, 'same values the old heredoc wrote' );
  my $yaml = Rex::Rancher::Cilium::_helm_values_yaml($v);
  like( $yaml, qr/^k8sServicePort: '6443'$/m, 'port stays a YAML string' );
  like( $yaml, qr/^  exclusive: false$/m,     'exclusive is a YAML boolean' );
  like( $yaml, qr/^kubeProxyReplacement: true$/m, 'kubeProxyReplacement boolean' );
  ok( !exists $v->{gatewayAPI}, 'gateway API off by default' );
};

subtest 'k3s: kube-proxy replacement at the control plane, pool = cluster-cidr' => sub {
  my $v = values_for( distribution => 'k3s', k8s_service_host => '203.0.113.7' );
  is_deeply( $v, {
    cni => { binPath => '/opt/cni/bin', confPath => '/etc/cni/net.d', exclusive => $T },
    ipam => {
      mode     => 'cluster-pool',
      operator => { clusterPoolIPv4PodCIDRList => ['10.42.0.0/16'] },
    },
    operator             => { replicas => 1 },
    kubeProxyReplacement => $T,
    k8sServiceHost       => '203.0.113.7',
    k8sServicePort       => '6443',
  }, 'the kubernetes-ocp k178 values, plus the CNI paths and one operator' );
  my $yaml = Rex::Rancher::Cilium::_helm_values_yaml($v);
  like( $yaml, qr/^k8sServicePort: '6443'$/m, 'port stays a YAML string' );
  like( $yaml, qr/^kubeProxyReplacement: true$/m, 'kubeProxyReplacement boolean' );
  like( $yaml, qr/^    clusterPoolIPv4PodCIDRList:\n    - 10\.42\.0\.0\/16$/m, 'pool as a YAML list' );
};

subtest 'k3s: the API address is required and never loopback' => sub {
  my $r = $C->can('_resolve_opts');
  eval { $r->( distribution => 'k3s' ) };
  like( $@, qr/k3s needs k8s_service_host.*127\.0\.0\.1:6444/, 'missing: dies, says why' );
  for my $lo (qw( 127.0.0.1 localhost LOCALHOST ::1 )) {
    eval { $r->( distribution => 'k3s', k8s_service_host => $lo ) };
    like( $@, qr/needs k8s_service_host.*got '\Q$lo\E'/, "$lo: dies" );
  }
  eval { $r->( distribution => 'k3s', helm_values => { k8sServiceHost => 'localhost' } ) };
  like( $@, qr/got 'localhost'/, 'loopback through helm_values: dies' );
  is( values_for( distribution => 'k3s', helm_values => { k8sServiceHost => 'cp' } )->{k8sServiceHost},
    'cp', 'helm_values k8sServiceHost takes the place of k8s_service_host' );
  is( values_for( distribution => 'k3s', k8s_service_host => 'a', helm_values => { k8sServiceHost => 'b' } )
    ->{k8sServiceHost}, 'b', 'helm_values wins, as everywhere' );
  eval { $r->( distribution => 'rke2', k8s_service_host => '203.0.113.7' ) };
  like( $@, qr/k8s_service_host is k3s-only/, 'rke2: refused, not silently ignored' );
};

subtest 'caller values deep-merge over the defaults' => sub {
  my $extra = { operator => { replicas => 2 }, hubble => { relay => { enabled => $T } },
                cni => { exclusive => $T }, ipam => 'cluster-pool' };
  my $v = values_for( distribution => 'rke2', helm_values => $extra );
  is( $v->{operator}{replicas}, 2, 'nested override' );
  is( $v->{cni}{binPath}, '/opt/cni/bin', 'sibling default kept' );
  ok( $v->{cni}{exclusive}, 'nested boolean override' );
  ok( $v->{hubble}{relay}{enabled}, 'new key added' );
  is( $v->{ipam}, 'cluster-pool', 'non-hash replaces a hash' );
  is_deeply( $extra->{operator}, { replicas => 2 }, 'caller hash not modified' );
  is( values_for( distribution => 'rke2' )->{operator}{replicas}, 1, 'defaults not modified' );
};

subtest 'gateway_api sets gatewayAPI.enabled' => sub {
  my $v = values_for( distribution => 'rke2', kubeconfig => '/kc',
    gateway_api => 1, gateway_api_version => 'v1.2.0' );
  ok( $v->{gatewayAPI}{enabled}, 'gatewayAPI.enabled true' );
};

subtest 'gateway_api_channel defaults to experimental' => sub {
  my $r = $C->can('_resolve_opts');
  my %gw = ( gateway_api => 1, gateway_api_version => 'v1.2.0', kubeconfig => '/kc' );
  is( $r->( distribution => 'rke2', %gw )->{gateway_api_channel}, 'experimental',
    'no channel: experimental (keeps TLSRoute for Cilium <= 1.19)' );
  is( $r->( distribution => 'rke2', %gw, gateway_api_channel => 'standard' )->{gateway_api_channel},
    'standard', 'explicit standard kept' );
};

subtest 'option validation dies before touching the host' => sub {
  my $r = $C->can('_resolve_opts');
  my %gw = ( gateway_api => 1, gateway_api_version => 'v1.2.0', kubeconfig => '/kc' );
  my $k3s_gw = $r->( distribution => 'k3s', k8s_service_host => 'cp', %gw );
  ok( $k3s_gw->{gateway_api} && $k3s_gw->{values}{gatewayAPI}{enabled}, 'gateway_api allowed on k3s' );
  ok( eval { $r->( distribution => 'k3s', k8s_service_host => 'cp',
    helm_values => { kubeProxyReplacement => $T, k8sServicePort => '6443' } ); 1 },
    'k3s may set kube-proxy replacement keys' );
  eval { $r->( distribution => 'rke2', %gw, kubeconfig => undef ) };
  like( $@, qr/needs kubeconfig/, 'gateway_api needs kubeconfig' );
  eval { $r->( distribution => 'rke2', %gw, gateway_api_version => undef ) };
  like( $@, qr/needs gateway_api_version/, 'gateway_api needs a version' );
  eval { $r->( distribution => 'rke2', %gw, gateway_api_channel => 'beta' ) };
  like( $@, qr/gateway_api_channel/, 'unknown channel refused' );
  eval { $r->( helm_values => [] ) };
  like( $@, qr/helm_values must be a hashref/, 'helm_values must be a hash' );
  eval { $r->( distribution => 'microk8s' ) };
  like( $@, qr/Unknown distribution/, 'unknown distribution' );
  ok( eval { $r->( distribution => 'rke2', helm_values => { kubeProxyReplacement => $T } ); 1 },
    'rke2 may set kube-proxy replacement keys' );
};

subtest 'cilium command lines' => sub {
  my $cmd = $C->can('_cilium_command');
  my $rke2 = $cmd->( 'install', $C->can('_resolve_opts')->( distribution => 'rke2' ), '/tmp/v.yaml' );
  is( $rke2, 'KUBECONFIG=/etc/rancher/rke2/rke2.yaml cilium install --version 1.20.0 '
    .'--helm-values /tmp/v.yaml --set kubeProxyReplacement=true', 'rke2 install' );
  my $k3s = $cmd->( 'upgrade', $C->can('_resolve_opts')->( distribution => 'k3s',
    k8s_service_host => 'cp', version => '1.18.1' ), '/tmp/v.yaml' );
  is( $k3s, 'KUBECONFIG=/etc/rancher/k3s/k3s.yaml cilium upgrade --version 1.18.1 '
    .'--helm-values /tmp/v.yaml --set kubeProxyReplacement=true', 'k3s upgrade, kube-proxy replacement' );
};

subtest 'gateway API bundle' => sub {
  is( Rex::Rancher::Cilium::_gateway_api_url( 'v1.2.0', 'experimental' ),
    'https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/experimental-install.yaml',
    'bundle URL' );
  my $n = $C->can('_gateway_api_needs_apply');
  my %cur = ( 'gateway.networking.k8s.io/bundle-version' => 'v1.2.0',
              'gateway.networking.k8s.io/channel'        => 'experimental' );
  ok( $n->( undef, 'v1.2.0', 'experimental' ), 'no CRDs yet: apply' );
  ok( !$n->( \%cur, 'v1.2.0', 'experimental' ), 'same bundle: skip' );
  ok( $n->( \%cur, 'v1.3.0', 'experimental' ), 'other version: apply' );
  ok( $n->( \%cur, 'v1.2.0', 'standard' ), 'other channel: apply' );
};

# -----------------------------------------------------------------------------
# 2. Release state and the decision
# -----------------------------------------------------------------------------

my $want = values_for( distribution => 'rke2' );
# The CLI stores more than we set: our values plus its own detected ones.
my $deployed_cfg = { %$want, cluster => { name => 'default' },
  cni => { %{ $want->{cni} } }, k8sServicePort => 6443 };

subtest 'release secrets decode' => sub {
  my $rel = Rex::Rancher::Cilium::_release_from_secrets( [
    helm_secret( revision => 9,  status => 'superseded', chart_version => '1.16.5' ),
    helm_secret( revision => 10, status => 'deployed',   chart_version => '1.17.0', config => $deployed_cfg ),
  ] );
  is( $rel->{revision}, 10, 'newest revision by number, not string' );
  is( $rel->{status}, 'deployed', 'status from labels' );
  is( $rel->{chart_version}, '1.17.0', 'chart version from payload' );
  is( $rel->{config}{cluster}{name}, 'default', 'values from payload' );
  ok( $rel->{has_deployed}, 'has a deployed revision' );
  is_deeply( $rel->{secrets}, [ 'sh.helm.release.v1.cilium.v10', 'sh.helm.release.v1.cilium.v9' ], 'secret names' );
  is( Rex::Rancher::Cilium::_release_from_secrets( [] ), undef, 'no secrets: no release' );
  is( Rex::Rancher::Cilium::_decode_release('not base64 gzip json'), undef, 'garbage decodes to undef' );
};

subtest 'release action' => sub {
  my $act = sub { $C->can('_release_action')->( $_[0], $_[1] // '1.17.0', $_[2] // $want ) };
  my $rel = sub { +{ status => 'deployed', chart_version => '1.17.0', config => $deployed_cfg,
                     has_deployed => 1, revision => 3, @_ } };

  is( $act->(undef), 'install', 'no release: install' );
  is( $act->( $rel->() ), 'noop', 'same version, values in effect: noop (the re-run case)' );
  is( $act->( $rel->( chart_version => 'v1.17.0' ) ), 'noop', 'leading v ignored' );
  is( $act->( $rel->(), 'v1.17.0' ), 'noop', 'leading v ignored on the request too' );
  is( $act->( $rel->(), '1.18.0' ), 'upgrade', 'other version: upgrade' );
  is( $act->( $rel->(), undef, { %$want, operator => { replicas => 2 } } ), 'upgrade',
    'changed value: upgrade' );
  is( $act->( $rel->(), undef, { %$want, gatewayAPI => { enabled => $T } } ), 'upgrade',
    'value not yet set: upgrade' );
  is( $act->( $rel->( chart_version => undef ) ), 'upgrade', 'unreadable payload: upgrade, never noop' );
  is( $act->( $rel->( status => 'failed' ) ), 'upgrade', 'failed upgrade: upgrade again' );
  is( $act->( $rel->( status => 'failed', has_deployed => 0 ) ), 'reinstall', 'failed first install: reinstall' );
  is( eval { $act->( $rel->( status => 'pending-install', has_deployed => 0 ) ) } // $@, 'reinstall',
    'pending first install: reinstall' );
  is( $act->( $rel->( status => $_ ) ), 'reinstall', "$_: reinstall" )
    for qw( uninstalling uninstalled );
  for my $st (qw( pending-upgrade pending-rollback )) {
    eval { $act->( $rel->( status => $st ) ) };
    like( $@, qr/stuck in $st.*sh\.helm\.release\.v1\.cilium\.v3/s, "$st: dies naming the secret" );
  }
  eval { $act->( $rel->( status => 'pending-install' ) ) };
  like( $@, qr/stuck in pending-install.*sh\.helm\.release\.v1\.cilium\.v3/s,
    'pending-install over a deployed revision: dies naming the secret, never reinstall (k82)' );
  my $pool = { %$want, ipam => { mode => 'cluster-pool' } };
  eval { $act->( $rel->(), undef, $pool ) };
  like( $@, qr/runs ipam\.mode kubernetes, the requested values ipam\.mode cluster-pool.*Redeploy.*mode => 'kubernetes'/s,
    'deployed: changing ipam.mode dies naming both modes' );
  eval { $act->( $rel->( status => 'failed' ), undef, $pool ) };
  like( $@, qr/runs ipam\.mode kubernetes/, 'failed upgrade: same refusal' );
  is( $act->( $rel->( config => { %$deployed_cfg, ipam => {} } ), undef, $pool ), 'upgrade',
    'no ipam.mode in the release: not refused' );
  is( $act->( $rel->(), '1.18.0' ), 'upgrade', 'same ipam.mode: upgrade as before' );
  eval { $act->( $rel->( status => 'superseded' ) ) };
  like( $@, qr/unexpected state 'superseded'/, 'unknown state dies' );
};

subtest 'boolean values compare against decoded JSON' => sub {
  my $s = $C->can('_values_subset');
  ok( $s->( { a => $T }, { a => JSON::MaybeXS->new->decode('{"a":true}')->{a} } ), 'true eq true' );
  ok( !$s->( { a => $T }, { a => JSON::MaybeXS->new->decode('{"a":false}')->{a} } ), 'true ne false' );
  ok( $s->( { p => '6443' }, { p => 6443 } ), 'string and number alike' );
  ok( !$s->( { a => { b => 1 } }, { a => 1 } ), 'hash vs scalar' );
  ok( $s->( { l => [ 1, 2 ] }, { l => [ 1, 2 ] } ), 'equal arrays' );
  ok( !$s->( { l => [ 1 ] }, { l => [ 1, 2 ] } ), 'arrays compare whole' );
};

# -----------------------------------------------------------------------------
# 3. install_cilium end to end against the fakes
# -----------------------------------------------------------------------------

sub cilium_cmds { grep { /cilium (install|upgrade|uninstall)/ } @cmds }

subtest 'with kubeconfig: existing release at the version is a noop' => sub {
  @cmds = ();
  $api = FakeAPI->new( secrets => [
    helm_secret( revision => 1, status => 'deployed', chart_version => '1.17.0', config => $deployed_cfg ) ] );
  install_cilium( distribution => 'rke2', kubeconfig => '/kc' );
  is( scalar cilium_cmds(), 0, 'no install, no upgrade' );
  ok( $files{'/tmp/cilium-values-rke2.yaml'}, 'values file still written' );
};

subtest 'with kubeconfig: other version upgrades' => sub {
  @cmds = ();
  $api = FakeAPI->new( secrets => [
    helm_secret( revision => 1, status => 'deployed', chart_version => '1.19.8', config => $deployed_cfg ) ] );
  install_cilium( distribution => 'rke2', kubeconfig => '/kc', version => '1.20.0' );
  is_deeply( [ map { /cilium (\w+)/ } cilium_cmds() ], ['upgrade'], 'exactly one upgrade' );
};

subtest 'with kubeconfig: k3s release on ipam kubernetes dies before upgrade' => sub {
  @cmds = ();
  $api = FakeAPI->new( secrets => [
    helm_secret( revision => 1, status => 'deployed', chart_version => '1.17.0', config => $deployed_cfg ) ] );
  eval { install_cilium( distribution => 'k3s', k8s_service_host => 'cp', kubeconfig => '/kc' ) };
  like( $@, qr/runs ipam\.mode kubernetes, the requested values ipam\.mode cluster-pool/, 'dies naming both modes' );
  is( scalar cilium_cmds(), 0, 'no cilium upgrade' );

  @cmds = ();
  install_cilium( distribution => 'k3s', k8s_service_host => 'cp', kubeconfig => '/kc',
    helm_values => { ipam => { mode => 'kubernetes' } } );
  is_deeply( [ map { /cilium (\w+)/ } cilium_cmds() ], ['upgrade'], 'matching helm_values: upgrade' );
};

subtest 'with kubeconfig: fresh cluster installs and checks the DaemonSet' => sub {
  @cmds = ();
  $api = FakeAPI->new( secrets => [], daemonset => 1 );
  install_cilium( distribution => 'k3s', k8s_service_host => 'cp', kubeconfig => '/kc' );
  is_deeply( [ map { /cilium (\w+)/ } cilium_cmds() ], ['install'], 'one install' );

  $api = FakeAPI->new( secrets => [], daemonset => 0 );
  eval { install_cilium( distribution => 'rke2', kubeconfig => '/kc' ) };
  like( $@, qr/DaemonSet kube-system\/cilium does not exist/, 'exit 0 without a DaemonSet dies' );
};

subtest 'with kubeconfig: stale first install is purged, then installed' => sub {
  @cmds = ();
  $api = FakeAPI->new( daemonset => 1, secrets => [
    helm_secret( revision => 1, status => 'failed', chart_version => '1.17.0' ) ] );
  install_cilium( distribution => 'rke2', kubeconfig => '/kc' );
  is_deeply( [ map { /cilium (\w+)/ } cilium_cmds() ], [ 'uninstall', 'install' ], 'uninstall, then install' );
  is_deeply( $api->{deleted}, ['Secret/sh.helm.release.v1.cilium.v1'], 'release secret removed' );
};

subtest 'with kubeconfig: a failing install is not swallowed' => sub {
  @cmds = ();
  $api = FakeAPI->new( secrets => [] );
  $run_hook = sub { return unless $_[0] =~ /cilium install/; $? = 1 << 8; 'Error: cannot re-use a name that is still in use' };
  eval { install_cilium( distribution => 'rke2', kubeconfig => '/kc' ) };
  like( $@, qr/cilium install failed: .*cannot re-use a name/, 'dies with the CLI output' );
  $run_hook = undef;
};

subtest 'without kubeconfig: the re-run swallow is kept' => sub {
  @cmds = ();
  $run_hook = sub { return unless $_[0] =~ /cilium install/; $? = 1 << 8; 'Error: cannot re-use a name that is still in use' };
  ok( eval { install_cilium( distribution => 'rke2' ); 1 }, 'existing release counts as success' ) or diag $@;
  is_deeply( [ map { /cilium (install|upgrade)/ } cilium_cmds() ], ['install'],
    'only cilium install ran: an existing release is never upgraded without kubeconfig' );

  $run_hook = sub { return unless $_[0] =~ /cilium install/; $? = 1 << 8; 'Error: boom' };
  eval { install_cilium( distribution => 'rke2' ) };
  like( $@, qr/cilium install failed: Error: boom/, 'any other failure dies' );
  $run_hook = undef;
};

# -----------------------------------------------------------------------------
# 4. A running Cilium keeps what it runs (k43): IPAM mode and pool from its
#    ConfigMap, k8sServiceHost from its DaemonSet, operator.replicas from the
#    release -- unless the caller asked for them, where a change the running
#    cluster cannot take dies before the host is touched.
# -----------------------------------------------------------------------------

sub configmap {
  my ( %data ) = @_;
  $k8s->struct_to_object( { apiVersion => 'v1', kind => 'ConfigMap',
    metadata => { name => 'cilium-config', namespace => 'kube-system' }, data => \%data } );
}

sub daemonset {
  my ( %a ) = @_;
  $k8s->struct_to_object( { apiVersion => 'apps/v1', kind => 'DaemonSet',
    metadata => { name => 'cilium', namespace => 'kube-system', generation => $a{generation} // 1 },
    spec => { selector => {}, template => { spec => { containers => [
      { name => 'cilium-agent', image => 'cilium',
        env => [ map { { name => $_, value => $a{env}{$_} } } sort keys %{ $a{env} // {} } ] },
    ] } } },
    status => { currentNumberScheduled => $a{desired} // 1, desiredNumberScheduled => $a{desired} // 1,
      numberMisscheduled => 0, numberReady => $a{ready} // 1,
      updatedNumberScheduled => $a{updated} // $a{desired} // 1,
      observedGeneration => $a{observed} // $a{generation} // 1 },
  } );
}

sub operator_deployment {
  my ( %a ) = @_;
  $k8s->struct_to_object( { apiVersion => 'apps/v1', kind => 'Deployment',
    metadata => { name => 'cilium-operator', namespace => 'kube-system', generation => 1 },
    spec => { replicas => $a{replicas} // 1, selector => {}, template => {} },
    status => { readyReplicas => $a{ready} // 1, updatedReplicas => $a{ready} // 1, observedGeneration => 1 },
  } );
}

sub adopt {
  my ( $running, %opts ) = @_;
  my $o = $C->can('_resolve_opts')->( kubeconfig => '/kc', %opts );
  return $C->can('_adopt_running')->( $o, $running )->{values};
}

subtest 'which values the caller set' => sub {
  my $e = $C->can('_explicit_values');
  is_deeply( $e->( {} ), { ipam_mode => 0, pool => 0, k8s_service_host => 0, operator_replicas => 0 },
    'nothing given: all defaults' );
  is_deeply( $e->( { ipam => { mode => 'kubernetes' } } ),
    { ipam_mode => 1, pool => 0, k8s_service_host => 0, operator_replicas => 0 }, 'mode only' );
  is( $e->( { ipam => { operator => { clusterPoolIPv4PodCIDRList => ['10.1.0.0/16'] } } } )->{pool}, 1, 'pool' );
  is( $e->( { ipam => { operator => { clusterPoolIPv4MaskSize => 24 } } } )->{pool}, 0,
    'another operator key is not the pool' );
  is_deeply( [ @{ $e->( { ipam => 'cluster-pool' } ) }{qw( ipam_mode pool )} ], [ 1, 1 ],
    'a non-hash ipam sets both' );
  is( $e->( {}, 'cp' )->{k8s_service_host}, 1, 'k8s_service_host option' );
  is( $e->( { k8sServiceHost => 'cp' } )->{k8s_service_host}, 1, 'k8sServiceHost value' );
  is( $e->( { operator => { replicas => 2 } } )->{operator_replicas}, 1, 'operator.replicas' );
};

subtest 'adopt: IPAM mode and pool follow the running Cilium' => sub {
  my $pool = { ipam_mode => 'cluster-pool', pool => ['10.0.0.0/8'] };
  is_deeply( adopt( $pool, distribution => 'rke2' )->{ipam},
    { mode => 'cluster-pool', operator => { clusterPoolIPv4PodCIDRList => ['10.0.0.0/8'] } },
    'rke2 on a cluster-pool cluster: never switched to kubernetes (the k43 danger)' );
  is_deeply( adopt( { ipam_mode => 'kubernetes' }, distribution => 'rke2' )->{ipam},
    { mode => 'kubernetes' }, 'rke2 on kubernetes: unchanged' );
  is_deeply( adopt( { ipam_mode => 'kubernetes' }, distribution => 'k3s', k8s_service_host => 'cp' )->{ipam},
    { mode => 'kubernetes' }, 'k3s on kubernetes: mode kept, default pool dropped' );
  is_deeply( adopt( { ipam_mode => 'cluster-pool', pool => ['10.100.0.0/16'] },
      distribution => 'k3s', k8s_service_host => 'cp' )->{ipam},
    { mode => 'cluster-pool', operator => { clusterPoolIPv4PodCIDRList => ['10.100.0.0/16'] } },
    'k3s: the running pool replaces the default one' );
  is_deeply( adopt( { ipam_mode => 'cluster-pool' }, distribution => 'k3s', k8s_service_host => 'cp' )->{ipam},
    { mode => 'cluster-pool' }, 'no readable pool: the default gives way to the chart\'s' );
  is_deeply( adopt( {}, distribution => 'rke2' )->{ipam}, { mode => 'kubernetes' },
    'no ConfigMap: defaults stand' );
  my $keep = adopt( $pool, distribution => 'rke2',
    helm_values => { ipam => { operator => { clusterPoolIPv4MaskSize => 26 } } } );
  is( $keep->{ipam}{operator}{clusterPoolIPv4MaskSize}, 26, 'caller\'s other ipam keys kept' );
  is_deeply( $keep->{ipam}{operator}{clusterPoolIPv4PodCIDRList}, ['10.0.0.0/8'], 'next to the running pool' );

  eval { adopt( $pool, distribution => 'rke2', helm_values => { ipam => { mode => 'kubernetes' } } ) };
  like( $@, qr{runs ipam\.mode cluster-pool \(ConfigMap kube-system/cilium-config\), the requested values ipam\.mode kubernetes},
    'explicit other mode: dies naming both' );
  is( adopt( $pool, distribution => 'rke2', helm_values => { ipam => { mode => 'cluster-pool' } } )
    ->{ipam}{operator}{clusterPoolIPv4PodCIDRList}[0], '10.0.0.0/8', 'explicit same mode: pool still adopted' );

  my $two = { ipam_mode => 'cluster-pool', pool => [ '10.0.0.0/16', '10.1.0.0/16' ] };
  eval { adopt( $two, distribution => 'rke2',
    helm_values => { ipam => { operator => { clusterPoolIPv4PodCIDRList => ['10.9.0.0/16'] } } } ) };
  like( $@, qr{cluster-pool is 10\.0\.0\.0/16 10\.1\.0\.0/16 .*requested clusterPoolIPv4PodCIDRList 10\.9\.0\.0/16}s,
    'explicit other pool: dies naming both' );
  ok( eval { adopt( $two, distribution => 'rke2',
    helm_values => { ipam => { operator => { clusterPoolIPv4PodCIDRList => [ '10.1.0.0/16', '10.0.0.0/16' ] } } } ); 1 },
    'explicit same pool in another order: fine' ) or diag $@;
  ok( eval { adopt( { ipam_mode => 'kubernetes' }, distribution => 'rke2',
    helm_values => { ipam => { operator => { clusterPoolIPv4PodCIDRList => ['10.9.0.0/16'] } } } ); 1 },
    'a pool on a kubernetes-mode cluster is not compared' );
};

subtest 'adopt: k8sServiceHost (k3s) and operator.replicas' => sub {
  my $v = adopt( { k8s_service_host => '10.0.0.1', operator_replicas => 2 }, distribution => 'k3s' );
  is( $v->{k8sServiceHost}, '10.0.0.1', 'k3s: running host used when none given' );
  is( $v->{operator}{replicas}, 2, 'operator.replicas from the release, not forced to 1' );
  is( adopt( { k8s_service_host => '10.0.0.1' }, distribution => 'k3s', k8s_service_host => 'cp' )
    ->{k8sServiceHost}, 'cp', 'given host wins' );
  is( adopt( { k8s_service_host => '10.0.0.1' }, distribution => 'rke2' )->{k8sServiceHost},
    '127.0.0.1', 'rke2 keeps 127.0.0.1' );
  is( adopt( { operator_replicas => 2 }, distribution => 'rke2',
    helm_values => { operator => { replicas => 3 } } )->{operator}{replicas}, 3, 'given replicas win' );
  is( adopt( {}, distribution => 'rke2' )->{operator}{replicas}, 1, 'nothing running: default 1' );
};

subtest 'read the running Cilium' => sub {
  $api = FakeAPI->new( objects => {
    'ConfigMap/cilium-config' => configmap( ipam => 'cluster-pool', 'cluster-pool-ipv4-cidr' => '10.0.0.0/16 10.1.0.0/16' ),
    'DaemonSet/cilium'        => daemonset( env => { KUBERNETES_SERVICE_HOST => '203.0.113.7' } ),
  } );
  is_deeply( $C->can('_read_running')->( $api, { status => 'deployed', config => { operator => { replicas => 2 } } } ), {
    ipam_mode => 'cluster-pool', pool => [ '10.0.0.0/16', '10.1.0.0/16' ],
    k8s_service_host => '203.0.113.7', operator_replicas => 2,
  }, 'mode, pool list, host, replicas' );

  $api = FakeAPI->new( objects => { 'ConfigMap/cilium-config' => configmap() } );
  is( $C->can('_read_running')->( $api, undef )->{ipam_mode}, 'cluster-pool',
    'ConfigMap without ipam: the agent default cluster-pool' );

  $api = FakeAPI->new( objects => { 'ConfigMap/cilium-config' => sub { die "Kubernetes API error: 403 forbidden\n" } } );
  eval { $C->can('_read_running')->( $api, undef ) };
  like( $@, qr{Cannot read ConfigMap kube-system/cilium-config: .*403}, 'an API error dies, never guesses' );

  # k54.2: only a 404 status is "missing"; "not found" or "404" elsewhere in
  # another error is an error.
  for my $err (
    [ 'webhook body', "Kubernetes API error (get ConfigMap): 500 {\"message\":\"webhook service not found\"}\n" ],
    [ 'proxy body',   "Kubernetes API error (get ConfigMap): 502 upstream answered 404\n" ],
    [ 'no API',       "599 Could not connect to 'cp.example.com:6443': host not found\n" ],
  ) {
    my ( $name, $msg ) = @$err;
    $api = FakeAPI->new( objects => { 'ConfigMap/cilium-config' => sub { die $msg } } );
    eval { $C->can('_read_running')->( $api, undef ) };
    like( $@, qr{^Cannot read ConfigMap kube-system/cilium-config: }, "$name: dies instead of reading as missing" );
  }
  $api = FakeAPI->new;
  is_deeply( $C->can('_read_running')->( $api, undef ), { operator_replicas => undef },
    'a real 404 everywhere: nothing running' );

  # k54.3: operator.replicas from the Deployment, which runs the chart's
  # default when the release never set one.
  $api = FakeAPI->new( objects => { 'Deployment/cilium-operator' => operator_deployment( replicas => 2 ) } );
  is( $C->can('_read_running')->( $api, { status => 'deployed', config => {} } )->{operator_replicas}, 2,
    'replicas from the Deployment, release without operator.replicas' );
  is( $C->can('_read_running')->( $api, { status => 'deployed', config => { operator => { replicas => 3 } } } )->{operator_replicas}, 2,
    'the Deployment wins over the release values' );
  $api = FakeAPI->new;
  is( $C->can('_read_running')->( $api, { status => 'deployed', config => { operator => { replicas => 3 } } } )->{operator_replicas}, 3,
    'no Deployment: the release values' );
};

# k69: without a release, reading operator.replicas from it must not
# autovivify one -- a status-less hash then warned "uninitialized" on every
# install_cilium with kubeconfig against a fresh cluster.
subtest 'a fresh cluster reads without warnings (k69)' => sub {
  my @warned;
  local $SIG{__WARN__} = sub { push @warned, @_ };

  $api = FakeAPI->new( secrets => [] );
  is_deeply( $C->can('_read_running')->( $api, undef ), { operator_replicas => undef },
    '_read_running: nothing running' );
  is_deeply( \@warned, [], '_read_running: no warning' );

  @warned = (); @cmds = ();
  no warnings 'redefine';
  local *Rex::Rancher::Cilium::_verify_daemonset = sub { };
  use warnings 'redefine';
  ok( eval { install_cilium( distribution => 'rke2', kubeconfig => '/kc' ); 1 }, 'install_cilium: installs' )
    or diag $@;
  is_deeply( [ map { /cilium (\w+)/ } cilium_cmds() ], ['install'], 'install_cilium: one install' );
  is_deeply( \@warned, [], 'install_cilium: no warning' );
};

subtest 'install_cilium: operator.replicas of a running operator is kept (k54.3)' => sub {
  @cmds = ();
  $api = FakeAPI->new(
    secrets => [ helm_secret( revision => 1, status => 'deployed', chart_version => '1.16.5',
      config => { cluster => { name => 'default' } } ) ],
    objects => {
      'ConfigMap/cilium-config'    => configmap( ipam => 'kubernetes' ),
      'Deployment/cilium-operator' => operator_deployment( replicas => 2 ),
    },
  );
  install_cilium( distribution => 'rke2', kubeconfig => '/kc' );
  like( $files{'/tmp/cilium-values-rke2.yaml'}, qr/^operator:\n  replicas: 2$/m, 'not forced down to 1' );
};

subtest 'install_cilium: a running cluster-pool rke2 cluster is upgraded on cluster-pool' => sub {
  @cmds = ();
  $api = FakeAPI->new(
    secrets => [ helm_secret( revision => 1, status => 'deployed', chart_version => '1.16.5',
      config => { cluster => { name => 'default' } } ) ],
    objects => { 'ConfigMap/cilium-config' => configmap( ipam => 'cluster-pool', 'cluster-pool-ipv4-cidr' => '10.0.0.0/8' ) },
  );
  install_cilium( distribution => 'rke2', kubeconfig => '/kc' );
  is_deeply( [ map { /cilium (\w+)/ } cilium_cmds() ], ['upgrade'], 'upgraded' );
  like( $files{'/tmp/cilium-values-rke2.yaml'}, qr/^  mode: cluster-pool$/m, 'values keep cluster-pool' );
  like( $files{'/tmp/cilium-values-rke2.yaml'}, qr{^    - 10\.0\.0\.0/8$}m, 'and the running pool' );

  @cmds = ();
  eval { install_cilium( distribution => 'rke2', kubeconfig => '/kc', helm_values => { ipam => { mode => 'kubernetes' } } ) };
  like( $@, qr/runs ipam\.mode cluster-pool/, 'explicit kubernetes: dies' );
  is_deeply( \@cmds, [], 'before anything ran on the host' );
};

subtest 'install_cilium: a stale release is reinstalled on what cilium-config says (k54.4)' => sub {
  for my $status (qw( failed pending-install )) {
    @cmds = (); %files = ();
    $api = FakeAPI->new( daemonset => 1,
      secrets => [ helm_secret( revision => 1, status => $status, chart_version => '1.17.0' ) ],
      objects => { 'ConfigMap/cilium-config' => configmap( ipam => 'cluster-pool', 'cluster-pool-ipv4-cidr' => '10.0.0.0/8' ) } );
    install_cilium( distribution => 'rke2', kubeconfig => '/kc' );
    is_deeply( [ map { /cilium (\w+)/ } cilium_cmds() ], [ 'uninstall', 'install' ], "$status: purged, installed" );
    like( $files{'/tmp/cilium-values-rke2.yaml'}, qr/^  mode: cluster-pool$/m,
      "$status: the pods' cluster-pool, not the rke2 default kubernetes" );
    like( $files{'/tmp/cilium-values-rke2.yaml'}, qr{^    - 10\.0\.0\.0/8$}m, "$status: and their pool" );
  }

  @cmds = ();
  $api = FakeAPI->new( daemonset => 1, secrets => [],
    objects => { 'ConfigMap/cilium-config' => configmap( ipam => 'cluster-pool', 'cluster-pool-ipv4-cidr' => '10.0.0.0/8' ) } );
  install_cilium( distribution => 'rke2', kubeconfig => '/kc' );
  like( $files{'/tmp/cilium-values-rke2.yaml'}, qr/^  mode: cluster-pool$/m, 'no release at all: the ConfigMap still counts' );

  @cmds = ();
  $api = FakeAPI->new( daemonset => 1,
    secrets => [ helm_secret( revision => 1, status => 'failed', chart_version => '1.17.0' ) ],
    objects => { 'ConfigMap/cilium-config' => configmap( ipam => 'cluster-pool', 'cluster-pool-ipv4-cidr' => '10.0.0.0/8' ) } );
  eval { install_cilium( distribution => 'rke2', kubeconfig => '/kc', helm_values => { ipam => { mode => 'kubernetes' } } ) };
  like( $@, qr/runs ipam\.mode cluster-pool/, 'explicit other mode on it: dies' );
  is_deeply( \@cmds, [], 'before anything ran on the host' );

  @cmds = ();
  $api = FakeAPI->new( daemonset => 1,
    secrets => [ helm_secret( revision => 1, status => 'failed', chart_version => '1.17.0' ) ] );
  install_cilium( distribution => 'rke2', kubeconfig => '/kc' );
  like( $files{'/tmp/cilium-values-rke2.yaml'}, qr/^  mode: kubernetes$/m, 'no ConfigMap: defaults' );
};

subtest 'upgrade_cilium: k3s keeps the running k8sServiceHost' => sub {
  @cmds = ();
  $api = FakeAPI->new( secrets => [ helm_secret( revision => 1, status => 'deployed', chart_version => '1.20.0' ) ], objects => {
    'ConfigMap/cilium-config' => configmap( ipam => 'cluster-pool', 'cluster-pool-ipv4-cidr' => '10.42.0.0/16' ),
    'DaemonSet/cilium'        => daemonset( env => { KUBERNETES_SERVICE_HOST => '203.0.113.7' } ),
  } );
  upgrade_cilium( distribution => 'k3s', kubeconfig => '/kc' );
  like( $files{'/tmp/cilium-values-k3s.yaml'}, qr/^k8sServiceHost: 203\.0\.113\.7$/m, 'host from the DaemonSet' );
  is_deeply( [ map { /cilium (\w+)/ } cilium_cmds() ], ['upgrade'], 'upgraded' );

  # No DaemonSet to read a host from (no release at all: k66/k70 below).
  @cmds = ();
  $api = FakeAPI->new( secrets => [ helm_secret( revision => 1, status => 'deployed', chart_version => '1.20.0' ) ] );
  eval { upgrade_cilium( distribution => 'k3s', kubeconfig => '/kc' ) };
  like( $@, qr/k3s needs k8s_service_host/, 'no running host and none given: dies' );
  is_deeply( \@cmds, [], 'before anything ran on the host' );
};

subtest 'upgrade_cilium without kubeconfig dies before the host (k51)' => sub {
  for my $case (
    [ 'rke2 defaults',         distribution => 'rke2' ],
    [ 'rke2 with ipam.mode',   distribution => 'rke2', helm_values => { ipam => { mode => 'cluster-pool' } } ],
    [ 'k3s with a host',       distribution => 'k3s', k8s_service_host => '10.0.0.1' ],
    [ 'k3s without a host',    distribution => 'k3s' ],
  ) {
    my ( $name, %o ) = @$case;
    @cmds = (); %files = ();
    $api = FakeAPI->new( secrets => [ helm_secret( revision => 1, status => 'deployed', chart_version => '1.16.5' ) ] );
    eval { upgrade_cilium( %o ) };
    like( $@, qr/upgrade_cilium needs kubeconfig .*IPAM mode and pool cannot be checked.*Pass the kubeconfig/s,
      $name.': dies naming why and what to pass' );
    is_deeply( \@cmds, [], $name.': nothing ran on the host' );
    is_deeply( \%files, {}, $name.': no values file written' );
  }
};

# -----------------------------------------------------------------------------
# k66, k70: upgrade_cilium upgrades the deployed revision of Helm release
# cilium -- `cilium upgrade` is a Helm upgrade without --install. Without a
# deployed revision it points to install_cilium, even with cilium-config or
# the cilium DaemonSet on the cluster; with a pending upgrade or rollback it
# dies as install_cilium does. Both before the CLI, the Gateway API CRDs or
# the values file reach host or cluster, and before the running Cilium is
# read. A failed upgrade over a deployed revision still upgrades.
# -----------------------------------------------------------------------------

subtest 'upgrade_cilium without a deployed release dies before the host (k66, k70)' => sub {
  my @crds;
  no warnings 'redefine';
  local *Rex::Rancher::Cilium::_ensure_gateway_api_crds = sub { push @crds, $_[1]; 1 };
  use warnings 'redefine';

  my %o = ( distribution => 'rke2', kubeconfig => '/kc', gateway_api => 1, gateway_api_version => 'v1.6.1' );
  my $undeployed = qr{^upgrade_cilium found no deployed revision of Helm release cilium in kube-system .*: cilium upgrade .*cannot install one.*install_cilium}s;
  my $cleared    = qr{install_cilium, which removes the release left behind and installs Cilium again};
  my $rev = sub { helm_secret( revision => $_[0], status => $_[1], chart_version => '1.20.0' ) };
  my $cm  = configmap( ipam => 'kubernetes' );
  my $ds  = daemonset();

  my $nothing_ran = sub {
    my ( $name ) = @_;
    is_deeply( \@cmds, [], $name.': nothing ran on the host (no CLI install, no cilium upgrade)' );
    is_deeply( \@crds, [], $name.': no Gateway API CRDs applied' );
    is_deeply( \%files, {}, $name.': no values file written' );
  };

  # (a) no deployed revision: install_cilium, whatever else of Cilium runs.
  for my $case (
    [ 'nothing at all',          [], {}, qr/\(no release\)/ ],
    [ 'only cilium-config',      [], { 'ConfigMap/cilium-config' => $cm }, qr/\(no release\)/ ],
    [ 'only the DaemonSet',      [], { 'DaemonSet/cilium' => $ds }, qr/\(no release\)/ ],
    [ 'a failed first install',  [ $rev->( 1, 'failed' ) ], {}, qr/\(latest revision 1 is failed\)/ ],
    [ 'a pending first install', [ $rev->( 1, 'pending-install' ) ], {}, qr/\(latest revision 1 is pending-install\)/ ],
    [ 'an uninstalling release', [ $rev->( 1, 'uninstalling' ) ], {}, qr/\(latest revision 1 is uninstalling\)/ ],
    [ 'an uninstalled release',  [ $rev->( 1, 'uninstalled' ) ], {}, qr/\(latest revision 1 is uninstalled\)/ ],
    [ 'cilium-config and DaemonSet over a pending first install', [ $rev->( 1, 'pending-install' ) ],
      { 'ConfigMap/cilium-config' => $cm, 'DaemonSet/cilium' => $ds }, qr/\(latest revision 1 is pending-install\)/ ],
  ) {
    my ( $name, $secrets, $objects, $state ) = @$case;
    @cmds = (); %files = (); @crds = ();
    $api = FakeAPI->new( secrets => $secrets, objects => $objects );
    eval { upgrade_cilium( %o ) };
    like( $@, $undeployed, $name.': dies pointing to install_cilium' );
    like( $@, $state, $name.': names the release state' );
    @$secrets ? like( $@, $cleared, $name.': install_cilium clears what is left' )
              : unlike( $@, $cleared, $name.': nothing left to clear' );
    $nothing_ran->( $name );
  }

  # (b) a pending upgrade or rollback: the same message as install_cilium,
  # checked before a deployed revision is looked for.
  for my $case (
    [ 'a pending upgrade over a deployed revision',  [ $rev->( 1, 'deployed' ), $rev->( 2, 'pending-upgrade' ) ], 'pending-upgrade', 2 ],
    [ 'a pending rollback over a deployed revision', [ $rev->( 1, 'deployed' ), $rev->( 2, 'pending-rollback' ) ], 'pending-rollback', 2 ],
    [ 'a pending upgrade without a deployed revision', [ $rev->( 1, 'failed' ), $rev->( 2, 'pending-upgrade' ) ], 'pending-upgrade', 2 ],
    [ 'a pending install over a deployed revision',  [ $rev->( 1, 'deployed' ), $rev->( 2, 'pending-install' ) ], 'pending-install', 2 ],
  ) {
    my ( $name, $secrets, $status, $n ) = @$case;
    @cmds = (); %files = (); @crds = ();
    $api = FakeAPI->new( secrets => $secrets, objects => { 'ConfigMap/cilium-config' => $cm, 'DaemonSet/cilium' => $ds } );
    eval { upgrade_cilium( %o ) };
    like( $@, qr{^Helm release cilium is stuck in \Q$status\E \(revision $n\): .*delete Secret sh\.helm\.release\.v1\.cilium\.v$n in kube-system and re-run}s,
      $name.': dies saying a Helm operation hangs, naming the Secret' );
    $nothing_ran->( $name );
  }

  # install_cilium says the same for the same state (one helper for both).
  for my $status (qw( pending-upgrade pending-rollback )) {
    my $secrets = [ $rev->( 1, 'deployed' ), $rev->( 2, $status ) ];
    $api = FakeAPI->new( secrets => $secrets );
    eval { upgrade_cilium( %o ) };
    my $upgrade = $@;
    like( $upgrade, qr/^Helm release cilium is stuck in \Q$status\E /, $status.': upgrade_cilium dies stuck' );
    $api = FakeAPI->new( secrets => $secrets );
    eval { install_cilium( %o ) };
    is( $@, $upgrade, $status.': install_cilium and upgrade_cilium die with the same message' );
  }

  # Checked before the running Cilium is read: an API error on the
  # DaemonSet does not hide a missing release.
  @cmds = ();
  $api = FakeAPI->new( objects => { 'DaemonSet/cilium' =>
    sub { die "Kubernetes API error (get DaemonSet): 403 {\"reason\":\"Forbidden\"}\n" } } );
  eval { upgrade_cilium( %o ) };
  like( $@, $undeployed, 'no release and a 403 on the DaemonSet: the missing release wins' );

  # k3s without k8s_service_host: the missing release is the message, not
  # the missing host that follows from it.
  @cmds = ();
  $api = FakeAPI->new( objects => { 'ConfigMap/cilium-config' => $cm, 'DaemonSet/cilium' => $ds } );
  eval { upgrade_cilium( distribution => 'k3s', kubeconfig => '/kc' ) };
  like( $@, $undeployed, 'k3s without a host: the missing release wins' );
  is_deeply( \@cmds, [], 'k3s without a host: nothing ran on the host' );

  # With a deployed release, any API error but a 404 still dies as itself.
  @cmds = ();
  $api = FakeAPI->new( secrets => [ $rev->( 1, 'deployed' ) ], objects => { 'DaemonSet/cilium' =>
    sub { die "Kubernetes API error (get DaemonSet): 403 {\"reason\":\"Forbidden\"}\n" } } );
  eval { upgrade_cilium( %o ) };
  like( $@, qr{^Cannot read DaemonSet kube-system/cilium: .*403}, 'a 403 dies naming the read' );
  is_deeply( \@cmds, [], 'a 403: nothing ran on the host' );

  for my $case (
    [ 'only a deployed release', secrets => [ $rev->( 1, 'deployed' ) ] ],
    [ 'a deployed release with cilium-config and DaemonSet', secrets => [ $rev->( 1, 'deployed' ) ],
      objects => { 'ConfigMap/cilium-config' => $cm, 'DaemonSet/cilium' => $ds } ],
    [ 'a failed upgrade over a deployed revision', secrets => [ $rev->( 1, 'deployed' ),
      helm_secret( revision => 2, status => 'failed', chart_version => '1.20.1' ) ] ],
  ) {
    my ( $name, @fake ) = @$case;
    @cmds = (); %files = (); @crds = ();
    $api = FakeAPI->new( @fake );
    ok( eval { upgrade_cilium( %o ); 1 }, $name.': upgrades' ) or diag $@;
    is_deeply( [ map { /cilium (\w+)/ } cilium_cmds() ], ['upgrade'], $name.': cilium upgrade ran' );
    is_deeply( \@crds, ['v1.6.1'], $name.': Gateway API CRDs applied' );
    ok( $files{'/tmp/cilium-values-rke2.yaml'}, $name.': values file written' );
  }
};

# -----------------------------------------------------------------------------
# k82: install_cilium over a release with a Helm operation pending dies as
# upgrade_cilium does, before the CLI, the Gateway API CRDs or the values
# file reach host or cluster -- a pending install over a deployed revision
# included, which a reinstall would purge together with the deployed
# revision and the pod network it carries. A pending install without a
# deployed revision (an interrupted first install) is removed and installed
# again, as before.
# -----------------------------------------------------------------------------

subtest 'install_cilium over a stuck release dies before the host (k82)' => sub {
  my @crds;
  no warnings 'redefine';
  local *Rex::Rancher::Cilium::_ensure_gateway_api_crds = sub { push @crds, $_[1]; 1 };
  use warnings 'redefine';

  my %o   = ( distribution => 'rke2', kubeconfig => '/kc', gateway_api => 1, gateway_api_version => 'v1.6.1' );
  my $rev = sub { helm_secret( revision => $_[0], status => $_[1], chart_version => '1.20.0' ) };
  my %running = ( 'ConfigMap/cilium-config' => configmap( ipam => 'cluster-pool', 'cluster-pool-ipv4-cidr' => '10.0.0.0/8' ),
                  'DaemonSet/cilium'        => daemonset() );

  for my $case (
    [ 'a pending install over a deployed revision', \%o, [ $rev->( 1, 'deployed' ), $rev->( 2, 'pending-install' ) ], 'pending-install', 2 ],
    [ 'a pending install over deployed and superseded', \%o,
      [ $rev->( 1, 'superseded' ), $rev->( 2, 'deployed' ), $rev->( 3, 'pending-install' ) ], 'pending-install', 3 ],
    [ 'a pending upgrade over a deployed revision',  \%o, [ $rev->( 1, 'deployed' ), $rev->( 2, 'pending-upgrade' ) ], 'pending-upgrade', 2 ],
    [ 'a pending rollback over a deployed revision', \%o, [ $rev->( 1, 'deployed' ), $rev->( 2, 'pending-rollback' ) ], 'pending-rollback', 2 ],
    # k3s without k8s_service_host: the hanging operation is the message,
    # not the missing host that follows from it.
    [ 'k3s without a host, a pending install over a deployed revision', { distribution => 'k3s', kubeconfig => '/kc' },
      [ $rev->( 1, 'deployed' ), $rev->( 2, 'pending-install' ) ], 'pending-install', 2 ],
  ) {
    my ( $name, $opts, $secrets, $status, $n ) = @$case;

    $api = FakeAPI->new( secrets => $secrets, objects => \%running );
    eval { upgrade_cilium( %$opts ) };
    my $upgrade = $@;

    @cmds = (); %files = (); @crds = ();
    $api = FakeAPI->new( secrets => $secrets, objects => \%running );
    eval { install_cilium( %$opts ) };
    like( $@, qr{^Helm release cilium is stuck in \Q$status\E \(revision $n\): .*delete Secret sh\.helm\.release\.v1\.cilium\.v$n in kube-system and re-run}s,
      $name.': dies saying a Helm operation hangs, naming the Secret' );
    is( $@, $upgrade, $name.': with the message of upgrade_cilium' );
    is_deeply( \@cmds, [], $name.': nothing ran on the host (no CLI, no cilium uninstall, install or upgrade)' );
    is_deeply( \@crds, [], $name.': no Gateway API CRDs applied' );
    is_deeply( \%files, {}, $name.': no values file written' );
    is_deeply( $api->{deleted}, [], $name.': no release Secret deleted' );
  }

  # No deployed revision: nothing works that a purge could take down.
  for my $case (
    [ 'a pending first install',             [ $rev->( 1, 'pending-install' ) ] ],
    [ 'a pending install over a failed one', [ $rev->( 1, 'failed' ), $rev->( 2, 'pending-install' ) ] ],
  ) {
    my ( $name, $secrets ) = @$case;
    @cmds = (); %files = (); @crds = ();
    $api = FakeAPI->new( secrets => $secrets, objects => \%running );
    ok( eval { install_cilium( %o ); 1 }, $name.': installs' ) or diag $@;
    is_deeply( [ map { /cilium (\w+)/ } cilium_cmds() ], [ 'uninstall', 'install' ], $name.': uninstall, then install' );
    is_deeply( [ sort @{ $api->{deleted} } ], [ sort map { 'Secret/'.$_->{name} } @$secrets ],
      $name.': every release Secret removed' );
    like( $files{'/tmp/cilium-values-rke2.yaml'}, qr/^  mode: cluster-pool$/m, $name.': on the running cluster-pool' );
  }
};

subtest 'wait for readiness' => sub {
  my $r = $C->can('_readiness');
  ok( $r->( daemonset(), operator_deployment() )->{ready}, 'all ready' );
  my $st = $r->( daemonset( desired => 3, ready => 2 ), operator_deployment() );
  ok( !$st->{ready}, 'a node not ready' );
  like( $st->{detail}, qr{cilium 2/3 ready, 3/3 updated; cilium-operator 1/1 ready}, 'detail says so' );
  ok( !$r->( daemonset( desired => 2, updated => 1 ), operator_deployment() )->{ready}, 'rollout incomplete' );
  like( $r->( daemonset( generation => 3, observed => 2 ), operator_deployment() )->{detail},
    qr/rollout not observed yet/, 'new generation not observed' );
  ok( !$r->( daemonset(), operator_deployment( ready => 0 ) )->{ready}, 'operator not ready' );
  like( $r->( undef, undef )->{detail}, qr{DaemonSet kube-system/cilium not found; Deployment kube-system/cilium-operator not found},
    'nothing there' );

  my $resolve = $C->can('_resolve_opts');
  eval { $resolve->( wait => 1 ) };
  like( $@, qr/wait needs kubeconfig/, 'wait needs kubeconfig' );
  eval { $resolve->( wait => 1, kubeconfig => '/kc', wait_duration => '10m' ) };
  like( $@, qr/wait_duration must be a whole number of seconds/, 'duration in seconds' );
  is( $resolve->( wait => 1, kubeconfig => '/kc' )->{wait_duration}, 600, 'default 600s' );

  my $slept = 0;
  no warnings 'redefine';
  local *Rex::Rancher::Cilium::_sleep = sub { $slept++ };
  use warnings 'redefine';

  $api = FakeAPI->new( secrets => [], objects => {
    'DaemonSet/cilium' => daemonset(), 'Deployment/cilium-operator' => operator_deployment() } );
  ok( eval { install_cilium( distribution => 'rke2', kubeconfig => '/kc', wait => 1 ); 1 }, 'ready: returns' ) or diag $@;
  is( $slept, 0, 'without sleeping' );

  $api = FakeAPI->new( secrets => [ helm_secret( revision => 1, status => 'deployed', chart_version => '1.16.5',
    config => $deployed_cfg ) ], objects => {
    'DaemonSet/cilium' => daemonset( desired => 2, ready => 1 ), 'Deployment/cilium-operator' => operator_deployment() } );
  eval { upgrade_cilium( distribution => 'rke2', kubeconfig => '/kc', wait => 1, wait_duration => 12 ) };
  like( $@, qr{Cilium was not ready within 12s: cilium 1/2 ready}, 'timeout dies with the state' );
  is( $slept, 2, 'three polls, 5s apart' );

  # k54.1: a 403 is not "not found" to wait out for wait_duration.
  $slept = 0;
  $api = FakeAPI->new( secrets => [], objects => {
    'DaemonSet/cilium'           => daemonset(),
    'Deployment/cilium-operator' => sub { die "Kubernetes API error (get Deployment): 403 {\"reason\":\"Forbidden\"}\n" } } );
  eval { install_cilium( distribution => 'rke2', kubeconfig => '/kc', wait => 1, wait_duration => 600 ) };
  like( $@, qr{^Cannot read Deployment kube-system/cilium-operator: .*403}, 'an API error dies, naming it' );
  is( $slept, 0, 'at once, not after 600s' );

  $api = FakeAPI->new( secrets => [], objects => { 'Deployment/cilium-operator' => operator_deployment() } );
  local *Rex::Rancher::Cilium::_verify_daemonset = sub { };
  eval { install_cilium( distribution => 'rke2', kubeconfig => '/kc', wait => 1, wait_duration => 10 ) };
  like( $@, qr{not ready within 10s: DaemonSet kube-system/cilium not found}, 'a real 404 is waited out' );
  is( $slept, 1, 'polled' );
};

subtest 'ensure_gateway_api_crds' => sub {
  @cmds = ();
  eval { ensure_gateway_api_crds( version => 'v1.2.0' ) };
  like( $@, qr/needs kubeconfig/, 'kubeconfig required' );
  eval { ensure_gateway_api_crds( kubeconfig => '/kc' ) };
  like( $@, qr/needs version/, 'version required' );
  eval { ensure_gateway_api_crds( kubeconfig => '/kc', version => 'v1.2.0', channel => 'beta' ) };
  like( $@, qr/gateway_api_channel must be/, 'channel checked' );

  my @called;
  no warnings 'redefine';
  local *Rex::Rancher::Cilium::_ensure_gateway_api_crds = sub { push @called, [ @_[ 1, 2 ] ]; $main::applied };
  use warnings 'redefine';

  our $applied = 0;
  $api = FakeAPI->new( objects => { 'Deployment/cilium-operator' => operator_deployment() } );
  is( ensure_gateway_api_crds( kubeconfig => '/kc', version => 'v1.2.0' ), 0, 'current: 0' );
  is_deeply( $called[-1], [ 'v1.2.0', 'experimental' ], 'default channel experimental' );
  is_deeply( $api->{patched}, [], 'operator left alone' );

  $applied = 1;
  is( ensure_gateway_api_crds( kubeconfig => '/kc', version => 'v1.6.1', channel => 'standard' ), 1, 'applied: 1' );
  is_deeply( $api->{patched}, ['Deployment/cilium-operator'], 'operator restarted' );
  is_deeply( \@cmds, [], 'nothing on the remote host' );
};

subtest 'cluster_cidr (k41): the server\'s pod network is Cilium\'s pool' => sub {
  is_deeply( values_for( distribution => 'k3s', k8s_service_host => 'cp', cluster_cidr => '10.244.0.0/16' )->{ipam},
    { mode => 'cluster-pool', operator => { clusterPoolIPv4PodCIDRList => ['10.244.0.0/16'] } },
    'k3s: replaces 10.42.0.0/16' );
  is_deeply( values_for( distribution => 'rke2', cluster_cidr => '10.244.0.0/16' )->{ipam},
    { mode => 'kubernetes', operator => { clusterPoolIPv4PodCIDRList => ['10.244.0.0/16'] } },
    'rke2: pool set, mode stays kubernetes' );
  is_deeply( values_for( distribution => 'rke2', cluster_cidr => '10.244.0.0/16',
      helm_values => { ipam => { mode => 'cluster-pool' } } )->{ipam},
    { mode => 'cluster-pool', operator => { clusterPoolIPv4PodCIDRList => ['10.244.0.0/16'] } },
    'rke2 with cluster-pool from helm_values: the OCP shape' );
  is_deeply( values_for( distribution => 'k3s', k8s_service_host => 'cp', cluster_cidr => '10.244.0.0/16',
      helm_values => { ipam => { operator => { clusterPoolIPv4PodCIDRList => ['10.9.0.0/16'] } } } )
    ->{ipam}{operator}{clusterPoolIPv4PodCIDRList}, ['10.9.0.0/16'], 'helm_values wins' );
  is( $C->can('_resolve_opts')->( distribution => 'rke2', cluster_cidr => '10.244.0.0/16' )->{explicit}{pool},
    0, 'not a requested pool: the pool of a fresh install (k54.5)' );
  eval { values_for( distribution => 'rke2', cluster_cidr => '10.244.0.0' ) };
  like( $@, qr/cluster_cidr must be one IPv4 CIDR/, 'invalid: dies' );

  my @warn;
  no warnings 'redefine';
  local *Rex::Logger::info = sub { push @warn, $_[0] if ( $_[1] // '' ) eq 'warn' };
  use warnings 'redefine';

  # k54.5: a running pool wins over cluster_cidr, loudly; only helm_values dies.
  my $running = { ipam_mode => 'cluster-pool', pool => ['10.42.0.0/16'] };
  my $old     = { ipam_mode => 'cluster-pool', pool => ['10.0.0.0/8'] };
  for my $case (
    [ 'k3s',  $running, [ distribution => 'k3s', k8s_service_host => 'cp' ], '10.244.0.0/16' ],
    [ 'rke2', $old,     [ distribution => 'rke2', helm_values => { ipam => { mode => 'cluster-pool' } } ], '10.42.0.0/16' ],
  ) {
    my ( $dist, $run, $opts, $cidr ) = @$case;
    @warn = ();
    my $v = eval { adopt( $run, @$opts, cluster_cidr => $cidr ) };
    ok( $v, "$dist: another cluster_cidr than the running pool does not die" ) or diag $@;
    is_deeply( $v->{ipam}{operator}{clusterPoolIPv4PodCIDRList}, $run->{pool}, "$dist: the running pool is kept" );
    is( scalar @warn, 1, "$dist: one warning" );
    like( $warn[0] // '', qr{^cluster_cidr \Q$cidr\E is not applied: Cilium already runs cluster-pool \Q@{ $run->{pool} }\E \(ConfigMap kube-system/cilium-config\).*Keeping the running pool}s,
      "$dist: names both pools" );
  }

  @warn = ();
  is_deeply( adopt( { ipam_mode => 'cluster-pool' }, distribution => 'k3s', k8s_service_host => 'cp', cluster_cidr => '10.244.0.0/16' )
    ->{ipam}, { mode => 'cluster-pool' }, 'no readable pool: cluster_cidr not applied either' );
  like( $warn[0] // '', qr/cluster_cidr 10\.244\.0\.0\/16 is not applied/, 'and said so' );

  @warn = ();
  is_deeply( adopt( $running, distribution => 'k3s', k8s_service_host => 'cp', cluster_cidr => '10.42.0.0/16' )
    ->{ipam}{operator}{clusterPoolIPv4PodCIDRList}, ['10.42.0.0/16'], 'the running pool: fine' );
  is_deeply( adopt( $running, distribution => 'k3s', k8s_service_host => 'cp' )
    ->{ipam}{operator}{clusterPoolIPv4PodCIDRList}, ['10.42.0.0/16'], 'not given: the running pool wins' );
  is_deeply( adopt( { ipam_mode => 'kubernetes' }, distribution => 'rke2', cluster_cidr => '10.244.0.0/16' )->{ipam},
    { mode => 'kubernetes' }, 'rke2 on kubernetes IPAM: the inactive pool value is dropped' );
  is_deeply( \@warn, [], 'no warning for any of these' );

  eval { adopt( $running, distribution => 'k3s', k8s_service_host => 'cp', cluster_cidr => '10.42.0.0/16',
    helm_values => { ipam => { operator => { clusterPoolIPv4PodCIDRList => ['10.244.0.0/16'] } } } ) };
  like( $@, qr{cluster-pool is 10\.42\.0\.0/16 .*requested clusterPoolIPv4PodCIDRList 10\.244\.0\.0/16.*out of helm_values}s,
    'another pool in helm_values still dies' );

  @cmds = (); @warn = ();
  $api = FakeAPI->new(
    secrets => [ helm_secret( revision => 1, status => 'deployed', chart_version => '1.16.5' ) ],
    objects => { 'ConfigMap/cilium-config' => configmap( ipam => 'cluster-pool', 'cluster-pool-ipv4-cidr' => '10.0.0.0/8' ) },
  );
  install_cilium( distribution => 'rke2', kubeconfig => '/kc', cluster_cidr => '10.42.0.0/16',
    helm_values => { ipam => { mode => 'cluster-pool' } } );
  is_deeply( [ map { /cilium (\w+)/ } cilium_cmds() ], ['upgrade'], 'the OCP shape on an old 10.0.0.0/8 cluster: upgraded' );
  like( $files{'/tmp/cilium-values-rke2.yaml'}, qr{^    - 10\.0\.0\.0/8$}m, 'on the running pool' );
};

# -----------------------------------------------------------------------------
# k64: ipam_mode is the mode of a fresh install, fed through the
# distribution's cilium_helm_defaults; a running Cilium's mode wins over it,
# loudly. helm_values ipam.mode keeps its own rule (a different one dies).
# -----------------------------------------------------------------------------

subtest 'ipam_mode (k64): the mode of a fresh install' => sub {
  is_deeply( values_for( distribution => 'rke2', ipam_mode => 'cluster-pool', cluster_cidr => '10.244.0.0/16' )->{ipam},
    { mode => 'cluster-pool', operator => { clusterPoolIPv4PodCIDRList => ['10.244.0.0/16'] } },
    'rke2 + cluster-pool + cluster_cidr: the pool is in use' );
  is_deeply( values_for( distribution => 'rke2', ipam_mode => 'cluster-pool' )->{ipam},
    { mode => 'cluster-pool' }, 'rke2 + cluster-pool alone: the chart default pool' );
  is( values_for( distribution => 'k3s', k8s_service_host => 'cp', ipam_mode => 'kubernetes' )->{ipam}{mode},
    'kubernetes', 'k3s + kubernetes' );
  is( values_for( distribution => 'rke2', ipam_mode => 'kubernetes' )->{ipam}{mode}, 'kubernetes',
    'rke2 + its own default' );
  is( $C->can('_resolve_opts')->( distribution => 'rke2', ipam_mode => 'cluster-pool' )->{explicit}{ipam_mode},
    0, 'not a requested mode' );
  is( values_for( distribution => 'rke2', ipam_mode => 'cluster-pool',
      helm_values => { ipam => { mode => 'cluster-pool' } } )->{ipam}{mode}, 'cluster-pool',
    'the same mode in helm_values: fine' );

  for my $bad ( 'multi-pool', 'eni', 'Kubernetes', '' ) {
    @cmds = (); %files = ();
    eval { install_cilium( distribution => 'rke2', ipam_mode => $bad ) };
    like( $@, qr/ipam_mode must be 'kubernetes' or 'cluster-pool', got '\Q$bad\E'/, "'$bad': dies" );
    is_deeply( \@cmds, [], "'$bad': before anything ran on the host" );
  }
  eval { values_for( distribution => 'rke2', ipam_mode => 'cluster-pool',
    helm_values => { ipam => { mode => 'kubernetes' } } ) };
  like( $@, qr/ipam_mode cluster-pool and helm_values ipam\.mode kubernetes contradict/, 'contradiction dies' );

  my @warn;
  no warnings 'redefine';
  local *Rex::Logger::info = sub { push @warn, $_[0] if ( $_[1] // '' ) eq 'warn' };
  use warnings 'redefine';

  @warn = ();
  my $v = eval { adopt( { ipam_mode => 'kubernetes' }, distribution => 'rke2', ipam_mode => 'cluster-pool',
    cluster_cidr => '10.244.0.0/16' ) };
  ok( $v, 'running kubernetes, ipam_mode cluster-pool: does not die' ) or diag $@;
  is_deeply( $v->{ipam}, { mode => 'kubernetes' }, 'the running mode stays, the unused pool goes' );
  is( scalar @warn, 1, 'one warning' );
  like( $warn[0] // '', qr{^ipam_mode cluster-pool is not applied: Cilium already runs ipam\.mode kubernetes \(ConfigMap kube-system/cilium-config\).*Keeping kubernetes}s,
    'naming both modes' );

  @warn = ();
  is( adopt( { ipam_mode => 'cluster-pool', pool => ['10.0.0.0/8'] }, distribution => 'k3s',
      k8s_service_host => 'cp', ipam_mode => 'kubernetes' )->{ipam}{mode}, 'cluster-pool', 'k3s: the same' );
  like( $warn[0] // '', qr/ipam_mode kubernetes is not applied: Cilium already runs ipam\.mode cluster-pool/,
    'k3s: warned' );

  @warn = ();
  is_deeply( adopt( { ipam_mode => 'cluster-pool', pool => ['10.0.0.0/8'] }, distribution => 'rke2',
      ipam_mode => 'cluster-pool' )->{ipam}, { mode => 'cluster-pool', operator => { clusterPoolIPv4PodCIDRList => ['10.0.0.0/8'] } },
    'the running mode asked for: kept with its pool' );
  is_deeply( adopt( {}, distribution => 'rke2', ipam_mode => 'cluster-pool' )->{ipam}, { mode => 'cluster-pool' },
    'nothing running: ipam_mode applies' );
  is_deeply( \@warn, [], 'no warning for these' );

  eval { adopt( { ipam_mode => 'kubernetes' }, distribution => 'rke2',
    helm_values => { ipam => { mode => 'cluster-pool' } } ) };
  like( $@, qr/runs ipam\.mode kubernetes .*requested values ipam\.mode cluster-pool/s,
    'helm_values ipam.mode on another running mode still dies' );

  # End to end: the OCP shape with ipam_mode on a hand-changed kubernetes
  # cluster upgrades on kubernetes, where helm_values would have died.
  for my $fn ( \&install_cilium, \&upgrade_cilium ) {
    @cmds = (); %files = (); @warn = ();
    $api = FakeAPI->new(
      secrets => [ helm_secret( revision => 1, status => 'deployed', chart_version => '1.16.5' ) ],
      objects => { 'ConfigMap/cilium-config' => configmap( ipam => 'kubernetes' ) },
    );
    ok( eval { $fn->( distribution => 'rke2', kubeconfig => '/kc', ipam_mode => 'cluster-pool',
      cluster_cidr => '10.42.0.0/16' ); 1 }, 'running kubernetes: no die' ) or diag $@;
    is_deeply( [ map { /cilium (\w+)/ } cilium_cmds() ], ['upgrade'], 'upgraded' );
    like( $files{'/tmp/cilium-values-rke2.yaml'}, qr/^  mode: kubernetes$/m, 'on the running mode' );
    unlike( $files{'/tmp/cilium-values-rke2.yaml'}, qr/clusterPoolIPv4PodCIDRList/, 'without the unused pool' );
    ok( grep( { /ipam_mode cluster-pool is not applied/ } @warn ), 'with the warning' );
  }

  @cmds = (); %files = ();
  $api = FakeAPI->new( secrets => [], daemonset => 1 );
  install_cilium( distribution => 'rke2', kubeconfig => '/kc', ipam_mode => 'cluster-pool',
    cluster_cidr => '10.42.0.0/16' );
  is_deeply( [ map { /cilium (\w+)/ } cilium_cmds() ], ['install'], 'fresh rke2: installed' );
  like( $files{'/tmp/cilium-values-rke2.yaml'}, qr/^  mode: cluster-pool$/m, 'on cluster-pool' );
  like( $files{'/tmp/cilium-values-rke2.yaml'}, qr{^    - 10\.42\.0\.0/16$}m, 'with cluster_cidr as its pool' );
};

# -----------------------------------------------------------------------------
# k65: the default Cilium is 1.20.0 (CLI v0.19.7); Cilium moves one minor at
# a time, so the default never jumps or pulls back a running Cilium, and a
# pinned version more than one minor away dies before the host is touched.
# -----------------------------------------------------------------------------

subtest 'version skew against a running Cilium (k65)' => sub {
  my $o = $C->can('_resolve_opts')->( distribution => 'rke2' );
  is( $o->{version}, '1.20.0', 'default Cilium 1.20.0' );
  is( $o->{cli_version}, 'v0.19.7', 'default CLI v0.19.7' );

  my @warn;
  no warnings 'redefine';
  local *Rex::Logger::info = sub { push @warn, $_[0] if ( $_[1] // '' ) eq 'warn' };
  use warnings 'redefine';

  my $settle = sub {
    my ( $running, $version, $pinned ) = @_;
    my $x = { version => $version, version_pinned => $pinned };
    $C->can('_settle_version')->( $x, $running );
    return $x->{version};
  };
  for my $case (
    # running,  version,  pinned, result,    warns
    [ undef,    '1.20.0', 0, '1.20.0', 0, 'nothing running: the default' ],
    [ 'latest', '1.20.0', 0, '1.20.0', 0, 'unreadable running version: no check' ],
    [ '1.20.0', '1.20.0', 0, '1.20.0', 0, 'the same' ],
    [ '1.20.0', '1.20.3', 0, '1.20.3', 0, 'default a newer patch: taken' ],
    [ '1.19.8', '1.20.0', 0, '1.19.8', 1, 'default one minor newer: running kept, warned' ],
    [ '1.17.0', '1.20.0', 0, '1.17.0', 1, 'default three minors newer: running kept, warned' ],
    [ '1.20.2', '1.20.0', 0, '1.20.2', 0, 'running a newer patch: kept' ],
    [ '1.21.0', '1.20.0', 0, '1.21.0', 0, 'running a newer minor: kept' ],
    [ 'v1.17.0', '1.20.0', 0, '1.17.0', 1, 'leading v on the running version' ],
    [ '1.17.0', '1.18.0', 1, '1.18.0', 0, 'pinned next minor: taken' ],
    [ '1.20.0', '1.19.8', 1, '1.19.8', 0, 'pinned previous minor (rollback): taken' ],
    [ '1.20.0', '1.20.0', 1, '1.20.0', 0, 'pinned the same' ],
  ) {
    my ( $run, $ver, $pin, $res, $warns, $name ) = @$case;
    @warn = ();
    is( $settle->( $run, $ver, $pin ), $res, $name );
    is( scalar @warn, $warns, $name.': '.$warns.' warning(s)' );
  }
  like( do { @warn = (); $settle->( '1.17.0', '1.20.0', 0 ); $warn[0] },
    qr/^Cilium runs 1\.17\.0; the default 1\.20\.0 is a newer minor version .*Keeping 1\.17\.0; pass version \(cilium_version\)/s,
    'the warning names both and the way out' );

  eval { $settle->( '1.17.0', '1.20.0', 1 ) };
  like( $@, qr/Cilium runs 1\.17\.0, version 1\.20\.0 is more than one minor version away.*latest 1\.18\.x first/s,
    'pinned three minors up: dies naming the next step' );
  eval { $settle->( '1.18.3', '1.16.0', 1 ) };
  like( $@, qr/latest 1\.17\.x first/, 'pinned two minors down: dies naming the step' );
  eval { $settle->( '1.20.0', '2.0.0', 1 ) };
  like( $@, qr/more than one minor version away/, 'another major: dies' );

  my $dsv = $C->can('_daemonset_version');
  my $ds_image = sub {
    $k8s->struct_to_object( { apiVersion => 'apps/v1', kind => 'DaemonSet',
      metadata => { name => 'cilium', namespace => 'kube-system' },
      spec => { selector => {}, template => { spec => { containers => [
        { name => 'cilium-agent', image => $_[0] } ] } } } } );
  };
  is( $dsv->( $ds_image->('quay.io/cilium/cilium:v1.17.0@sha256:abc') ), '1.17.0', 'tag with digest' );
  is( $dsv->( $ds_image->('mirror.lan:5000/cilium/cilium:v1.18.2') ), '1.18.2', 'mirror with a port' );
  is( $dsv->( $ds_image->('quay.io/cilium/cilium@sha256:abc') ), undef, 'digest only: unknown' );
  is( $dsv->( $ds_image->('quay.io/cilium/cilium:latest') ), undef, 'latest: unknown' );

  my $rel = sub { $C->can('_release_from_secrets')->( [ helm_secret( revision => 1, chart_version => '1.17.0', @_ ) ] ) };
  $api = FakeAPI->new( objects => { 'DaemonSet/cilium' => $ds_image->('quay.io/cilium/cilium:v1.18.1') } );
  is( $C->can('_read_running')->( $api, $rel->( status => 'deployed' ) )->{version}, '1.18.1',
    'the agents\' image wins over the release' );
  $api = FakeAPI->new;
  is( $C->can('_read_running')->( $api, $rel->( status => 'deployed' ) )->{version}, '1.17.0',
    'no DaemonSet: the deployed chart' );
  is( $C->can('_read_running')->( $api, $rel->( status => 'failed' ) )->{version}, undef,
    'a failed release names no running version' );

  # End to end on a cluster deployed with the old default.
  my $old = sub { FakeAPI->new( secrets => [
    helm_secret( revision => 1, status => 'deployed', chart_version => '1.17.0', config => $deployed_cfg ) ] ) };

  @cmds = (); @warn = ();
  $api = $old->();
  install_cilium( distribution => 'rke2', kubeconfig => '/kc' );
  is( scalar cilium_cmds(), 0, 'install_cilium re-run without version on 1.17: left alone' );
  ok( grep( { /Keeping 1\.17\.0/ } @warn ), 'with the warning' );

  @cmds = ();
  $api = $old->();
  upgrade_cilium( distribution => 'rke2', kubeconfig => '/kc' );
  is_deeply( [ map { /cilium upgrade --version (\S+)/ } @cmds ], ['1.17.0'],
    'upgrade_cilium without version: stays on 1.17.0' );

  @cmds = ();
  $api = $old->();
  install_cilium( distribution => 'rke2', kubeconfig => '/kc', version => '1.18.0' );
  ok( grep( { /cilium upgrade --version 1\.18\.0 / } @cmds ), 'pinned next minor: upgraded' );

  for my $fn ( \&install_cilium, \&upgrade_cilium ) {
    @cmds = (); %files = ();
    $api = $old->();
    eval { $fn->( distribution => 'rke2', kubeconfig => '/kc', version => '1.20.0' ) };
    like( $@, qr/runs 1\.17\.0, version 1\.20\.0 is more than one minor/, 'pinned 1.17 -> 1.20: dies' );
    is_deeply( \@cmds, [], 'before anything ran on the host' );
    is_deeply( \%files, {}, 'no values file written' );
  }
};

subtest 'Gateway API bundle for Cilium 1.20 (k65)' => sub {
  my %gw = ( distribution => 'rke2', kubeconfig => '/kc', gateway_api => 1 );
  eval { $C->can('_resolve_opts')->( %gw, version => '1.20.0', gateway_api_version => 'v1.2.0' ) };
  like( $@, qr/Cilium 1\.20\.0 needs Gateway API v1\.6\.1 or newer.*gateway_api_version is v1\.2\.0/s,
    'pinned 1.20 + v1.2.0: dies in option resolution' );
  ok( eval { $C->can('_resolve_opts')->( %gw, version => '1.20.0', gateway_api_version => 'v1.6.1' ); 1 },
    '1.20 + v1.6.1: fine' ) or diag $@;
  ok( eval { $C->can('_resolve_opts')->( %gw, version => '1.17.0', gateway_api_version => 'v1.2.0' ); 1 },
    '1.17 + v1.2.0: fine' ) or diag $@;
  ok( eval { $C->can('_resolve_opts')->( %gw, gateway_api_version => 'v1.2.0' ); 1 },
    'default version: not yet, a running Cilium may keep an older one' ) or diag $@;

  @cmds = ();
  $api = FakeAPI->new;
  eval { install_cilium( %gw, gateway_api_version => 'v1.2.0' ) };
  like( $@, qr/Cilium 1\.20\.0 needs Gateway API v1\.6\.1/, 'fresh cluster, default 1.20 + v1.2.0: dies' );
  is_deeply( \@cmds, [], 'before anything ran on the host' );

  my $check = $C->can('_check_gateway_api_version');
  ok( eval { $check->( { gateway_api => 1, version => '1.17.0', gateway_api_version => 'v1.2.0' } ); 1 },
    'the default kept at a running 1.17: v1.2.0 fine' );
  ok( eval { $check->( { gateway_api => 0, version => '1.20.0', gateway_api_version => undef } ); 1 },
    'without gateway_api: no check' );
  ok( eval { $check->( { gateway_api => 1, version => '1.21.0', gateway_api_version => 'v1.7.0' } ); 1 },
    'newer both: fine' );
};

# -----------------------------------------------------------------------------
# k59: every API read or delete outside _read_running tells a 404 status from
# any other error the same way -- missing is its own case, a 403 or a proxy
# body that mentions "not found" dies instead of reading as missing.
# -----------------------------------------------------------------------------

subtest 'API errors are not read as missing (k59)' => sub {
  my $forbidden = sub { my ( $what ) = @_; sub { die "Kubernetes API error (get $what): 403 {\"reason\":\"Forbidden\"}\n" } };
  my $crd_name  = 'gateways.gateway.networking.k8s.io';
  my $secret    = 'sh.helm.release.v1.cilium.v1';
  my $stale     = [ helm_secret( revision => 1, status => 'failed', chart_version => '1.17.0' ) ];

  # _purge_release: a 404 on delete is "already gone"; a body saying
  # "not found" under another status is not.
  @cmds = ();
  $api = FakeAPI->new( daemonset => 1, secrets => $stale,
    delete_errors => { "Secret/$secret" => FakeAPI::not_found('Secret') } );
  eval { install_cilium( distribution => 'rke2', kubeconfig => '/kc' ) };
  is( $@, '', 'purge: a real 404 on delete is already gone' );
  is_deeply( [ map { /cilium (\w+)/ } cilium_cmds() ], [ 'uninstall', 'install' ], 'and the install runs' );

  @cmds = ();
  $api = FakeAPI->new( daemonset => 1, secrets => $stale,
    delete_errors => { "Secret/$secret" => "Kubernetes API error (delete Secret): 500 webhook: namespace not found\n" } );
  eval { install_cilium( distribution => 'rke2', kubeconfig => '/kc' ) };
  like( $@, qr{^Cannot delete Secret kube-system/\Q$secret\E: .*500}, 'purge: another error mentioning "not found" dies' );
  is_deeply( [ map { /cilium (\w+)/ } cilium_cmds() ], ['uninstall'], 'before the install' );

  # _verify_daemonset: an unreadable DaemonSet is named as such.
  $api = FakeAPI->new( secrets => [], objects => { 'DaemonSet/cilium' => $forbidden->('DaemonSet') } );
  eval { $C->can('_verify_daemonset')->( $api ) };
  like( $@, qr{^Cannot read DaemonSet kube-system/cilium: .*403}, 'verify: a 403 is not "does not exist"' );

  # _restart_operator: no operator is nothing to restart, a 403 dies.
  $api = FakeAPI->new;
  is( $C->can('_restart_operator')->( $api ), undef, 'restart: no operator, nothing to do' );
  is_deeply( $api->{patched}, [], 'nothing patched' );
  $api = FakeAPI->new( objects => { 'Deployment/cilium-operator' => $forbidden->('Deployment') } );
  eval { $C->can('_restart_operator')->( $api ) };
  like( $@, qr{^Cannot read Deployment kube-system/cilium-operator: .*403}, 'restart: a 403 dies instead of skipping' );

  # The Gateway API probe: missing means apply, a 403 dies before any fetch.
  my @fetched;
  no warnings 'redefine';
  local *HTTP::Tiny::get = sub { push @fetched, $_[1]; +{ success => 0, status => 599, reason => 'offline test' } };
  local *Rex::Rancher::Cilium::_sleep = sub { };
  use warnings 'redefine';

  $api = FakeAPI->new( secrets => [] );
  eval { $C->can('_ensure_gateway_api_crds')->( $api, 'v1.2.0', 'standard' ) };
  like( $@, qr/Cannot fetch Gateway API bundle/, 'probe 404: goes on to apply' );
  is( scalar @fetched, 1, 'and fetched the bundle' );

  @fetched = ();
  $api = FakeAPI->new( secrets => [], objects => { "CustomResourceDefinition/$crd_name" => $forbidden->('CustomResourceDefinition') } );
  eval { $C->can('_ensure_gateway_api_crds')->( $api, 'v1.2.0', 'standard' ) };
  like( $@, qr{^Cannot read CustomResourceDefinition \Q$crd_name\E: .*403}, 'probe 403: dies, cluster-scoped name' );
  is( scalar @fetched, 0, 'nothing fetched or applied' );

  # _wait_crd_established: not visible yet is waited out, a 403 dies at once.
  my $calls = 0;
  my $established = $k8s->struct_to_object( { apiVersion => 'apiextensions.k8s.io/v1',
    kind => 'CustomResourceDefinition', metadata => { name => $crd_name },
    spec => { group => 'gateway.networking.k8s.io', scope => 'Namespaced',
      names => { plural => 'gateways', kind => 'Gateway' }, versions => [] },
    status => { conditions => [ { type => 'Established', status => 'True' } ] } } );
  $api = FakeAPI->new( objects => { "CustomResourceDefinition/$crd_name" =>
    sub { $calls++ ? $established : die FakeAPI::not_found('CustomResourceDefinition') } } );
  is( $C->can('_wait_crd_established')->( $api, $crd_name ), 1, 'wait: a 404 is waited out' );
  is( $calls, 2, 'polled again' );

  $calls = 0;
  $api = FakeAPI->new( objects => { "CustomResourceDefinition/$crd_name" =>
    sub { $calls++; $forbidden->('CustomResourceDefinition')->() } } );
  eval { $C->can('_wait_crd_established')->( $api, $crd_name ) };
  like( $@, qr{^Cannot read CustomResourceDefinition \Q$crd_name\E: .*403}, 'wait: a 403 dies' );
  is( $calls, 1, 'at once, not after 30s' );
};

done_testing;
