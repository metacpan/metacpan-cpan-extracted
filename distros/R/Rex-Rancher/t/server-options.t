use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Offline tests for the install_server options version, node_name and disable,
# rke2 and k3s alike.
#
# - version lands on the installer line as INSTALL_RKE2_VERSION /
#   INSTALL_K3S_VERSION; without it the line is exactly what it was before.
# - node_name becomes `node-name:` in config.yaml.
# - disable replaces the per-distribution default list in config.yaml; the
#   default (undef) is rke2-ingress-nginx + rke2-traefik(-crd) on rke2 and
#   traefik + servicelb on k3s -- the latter moved from --disable flags on the
#   k3s installer line into config.yaml, so the installer line must no longer
#   carry them.
# - the cilium keys (cni on rke2, flannel-backend/disable-kube-proxy on k3s)
#   are untouched by disable.
#
# This proves the config hash and the command strings, not a deploy.
# -----------------------------------------------------------------------------

use YAML::PP;
use Rex::Rancher::Server;

sub cfg { Rex::Rancher::Server::_build_server_config(@_) }
#  ($distribution, $token, $server, $tls_san, $node_labels, $cilium, $node_name, $disable)

sub paths { Rex::Rancher::Server::_paths(@_) }

my %DEFAULT = (
  rke2 => ['rke2-ingress-nginx', 'rke2-traefik', 'rke2-traefik-crd'],
  k3s  => ['traefik', 'servicelb'],
);

for my $dist (qw( rke2 k3s )) {
  subtest "$dist: defaults unchanged" => sub {
    my $c = cfg($dist, 'tok', undef, undef, undef, 1);
    is_deeply($c->{disable}, $DEFAULT{$dist}, 'default disable list');
    ok(!exists $c->{'node-name'}, 'no node-name without node_name');
  };

  subtest "$dist: node_name" => sub {
    my $c = cfg($dist, 'tok', undef, undef, undef, 1, 'cp-01');
    is($c->{'node-name'}, 'cp-01', 'node-name written');
  };

  subtest "$dist: disable replaces the default" => sub {
    my $c = cfg($dist, 'tok', undef, undef, undef, 1, undef, ['a', 'b']);
    is_deeply($c->{disable}, ['a', 'b'], 'arrayref taken verbatim');

    $c = cfg($dist, 'tok', undef, undef, undef, 1, undef, 'a,b');
    is_deeply($c->{disable}, ['a', 'b'], 'comma-separated string split');

    $c = cfg($dist, 'tok', undef, undef, undef, 1, undef, []);
    ok(!exists $c->{disable}, 'empty list: no disable key, nothing disabled');
  };

  subtest "$dist: default list is not shared state" => sub {
    my $c = cfg($dist, 'tok', undef, undef, undef, 1);
    push @{ $c->{disable} }, 'mutated';
    is_deeply(cfg($dist, 'tok', undef, undef, undef, 1)->{disable}, $DEFAULT{$dist},
      'mutating one config does not change the next default');
  };
}

subtest 'rke2: OCP disable list, cilium gate intact' => sub {
  my @ocp = qw( rke2-ingress-nginx rke2-traefik rke2-traefik-crd );
  my $c = cfg('rke2', 'tok', undef, undef, undef, 1, 'cp-01', \@ocp);
  is_deeply($c->{disable}, \@ocp, 'all three disabled');
  is($c->{cni}, 'none', 'cni:none still set');
  ok($c->{'disable-kube-proxy'}, 'disable-kube-proxy still set');

  my $yaml = YAML::PP->new(boolean => 'JSON::PP')->dump_string($c);
  like($yaml, qr/^node-name: cp-01$/m, 'yaml: node-name');
  like($yaml, qr/^disable:\n- rke2-ingress-nginx\n- rke2-traefik\n- rke2-traefik-crd$/m,
    'yaml: disable list');
  like($yaml, qr/^disable-kube-proxy: true$/m, 'yaml: real boolean');
};

subtest 'k3s: disable does not touch the cilium keys' => sub {
  my $c = cfg('k3s', 'tok', undef, undef, undef, 1, undef, ['traefik']);
  ok(!exists $c->{cni},                'no rke2 cni key on k3s');
  ok($c->{'disable-kube-proxy'},       'disable-kube-proxy kept');
  is($c->{'flannel-backend'}, 'none',  'flannel-backend kept');
  is_deeply($c->{disable}, ['traefik'], 'caller list used');
};

subtest 'rke2 installer command' => sub {
  my $p = paths('rke2');
  is(Rex::Rancher::Server::_rke2_server_install_cmd($p, undef),
    'curl -sfL https://get.rke2.io | sh -', 'unpinned: unchanged command');
  is(Rex::Rancher::Server::_rke2_server_install_cmd($p, 'v1.30.4+rke2r1'),
    'curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=v1.30.4+rke2r1 sh -',
    'pinned: INSTALL_RKE2_VERSION');
};

subtest 'k3s installer command' => sub {
  my $p = paths('k3s');
  is(Rex::Rancher::Server::_k3s_server_install_cmd($p, undef, undef),
    'curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_START=true sh -s - server --write-kubeconfig-mode=644',
    'unpinned, first server');
  is(Rex::Rancher::Server::_k3s_server_install_cmd($p, undef, 'v1.30.4+k3s1'),
    'curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.30.4+k3s1 INSTALL_K3S_SKIP_START=true sh -s - server'
      . ' --write-kubeconfig-mode=644',
    'pinned: INSTALL_K3S_VERSION');
  my $ha = Rex::Rancher::Server::_k3s_server_install_cmd($p, 'https://cp1:6443', 'v1.30.4+k3s1');
  like($ha, qr/\| K3S_URL=https:\/\/cp1:6443 INSTALL_K3S_VERSION=v1\.30\.4\+k3s1 INSTALL_K3S_SKIP_START=true sh -s - server/,
    'HA join: URL and version');
  unlike($ha, qr/--disable/, 'disable lives in config.yaml, not on the command line');
};

done_testing;
