use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Unit test for the server config.yaml builder (Rex::Rancher::Server).
#
# With cilium (the default) Cilium must be the only CNI on both distributions:
# - rke2: cni:none + disable-kube-proxy.
# - k3s: flannel-backend:none + disable-network-policy + disable-kube-proxy,
#   and cluster-cidr spelled out: Cilium's cluster-pool IPAM is handed the
#   same range (Rex::Rancher::Cilium), as in kubernetes-ocp k178.
# Cilium replaces kube-proxy on both. Without cilium neither distribution's
# CNI or kube-proxy is touched.
#
# _build_server_config is pure (no file/YAML I/O), so it is unit-testable
# offline; the actual write stays in _write_config. Nothing here says the
# resulting cluster comes up -- k3s has not been run live through Rex::Rancher.
# -----------------------------------------------------------------------------

use JSON::MaybeXS ();
use Rex::Rancher::Server;
use Rex::Rancher::Cilium;

sub cfg { Rex::Rancher::Server::_build_server_config(@_) }
#          ($distribution, $token, $server, $tls_san, $node_labels, $cilium)

subtest 'rke2 + cilium: kube-proxy replacement config present' => sub {
  my $c = cfg('rke2', 'tok', undef, undef, undef, 1);
  is($c->{token}, 'tok',   'token set');
  is($c->{cni},   'none',  'cni:none — Cilium owns the CNI');
  ok($c->{'disable-kube-proxy'}, 'disable-kube-proxy true (Cilium replaces it on rke2)');
  ok(!exists $c->{'flannel-backend'}, 'no k3s flannel key on rke2');
  is_deeply($c->{disable}, [qw( rke2-ingress-nginx rke2-traefik rke2-traefik-crd )],
    'rke2 bundled ingress controllers disabled');
};

subtest 'k3s + cilium: Flannel, network policy and kube-proxy off' => sub {
  my $c = cfg('k3s', 'tok', undef, undef, undef, 1);
  is($c->{token}, 'tok', 'token set');
  is($c->{'flannel-backend'}, 'none', 'flannel-backend:none — Cilium is the only CNI');
  ok(JSON::MaybeXS::is_bool($c->{'disable-network-policy'}) && $c->{'disable-network-policy'},
    'disable-network-policy is a real true boolean');
  ok(JSON::MaybeXS::is_bool($c->{'disable-kube-proxy'}) && $c->{'disable-kube-proxy'},
    'disable-kube-proxy is a real true boolean — Cilium replaces it');
  is($c->{'cluster-cidr'}, '10.42.0.0/16', 'cluster-cidr spelled out');
  is($c->{'cluster-cidr'},
    Rex::Rancher::Cilium::_paths_for('k3s')->{cluster_cidr},
    'cluster-cidr is the range Cilium\'s pool gets');
  ok(!exists $c->{cni},     'no rke2 cni key on k3s');
  is_deeply($c->{disable}, ['traefik', 'servicelb'],
    'k3s default disable list (traefik, servicelb), no rke2 names');
};

subtest 'k3s without cilium: Flannel and network policy left alone' => sub {
  my $c = cfg('k3s', 'tok', undef, undef, undef, 0);
  ok(!exists $c->{'flannel-backend'},        'no flannel-backend without cilium');
  ok(!exists $c->{'disable-network-policy'}, 'no disable-network-policy without cilium');
  ok(!exists $c->{'disable-kube-proxy'},     'no disable-kube-proxy');
  ok(!exists $c->{'cluster-cidr'},           'no cluster-cidr');
  ok(!exists $c->{cni},                      'no cni key');
};

subtest 'k3s server join + cilium: same CNI keys as the first server' => sub {
  my $c = cfg('k3s', 'tok', 'https://cp1:6443', undef, undef, 1);
  is($c->{server}, 'https://cp1:6443', 'server set');
  is($c->{'flannel-backend'}, 'none', 'joining server also has flannel-backend:none');
  ok($c->{'disable-network-policy'}, 'joining server also disables network policy');
  ok($c->{'disable-kube-proxy'}, 'joining server also disables kube-proxy');
  is($c->{'cluster-cidr'}, '10.42.0.0/16', 'joining server: same cluster-cidr');
};

subtest 'rke2 without cilium: no kube-proxy override, ingress still disabled' => sub {
  my $c = cfg('rke2', 'tok', undef, undef, undef, 0);
  ok(!exists $c->{'flannel-backend'},    'no k3s flannel key on rke2');
  ok(!exists $c->{'disable-kube-proxy'}, 'no disable-kube-proxy without cilium');
  ok(!exists $c->{cni},                  'no cni:none without cilium');
  is_deeply($c->{disable}, [qw( rke2-ingress-nginx rke2-traefik rke2-traefik-crd )],
    'rke2 bundled ingress controllers still disabled');
};

subtest 'server / tls_san / node_labels passthrough' => sub {
  my $c = cfg('rke2', 'tok', 'https://api:6443', ['lb.example.com'], ['role=cp'], 1);
  is($c->{server}, 'https://api:6443', 'server set');
  is_deeply($c->{'tls-san'},    ['lb.example.com'], 'tls-san array');
  is_deeply($c->{'node-label'}, ['role=cp'],        'node-label array');
};

done_testing;
