#!/usr/bin/env perl
# Example: full GPU cluster deploy on Hetzner dedicated server
#
# Usage:
#   rex -f eg/hetzner-gpu.pl -H <host> deploy

use Rex -feature => ['1.4'];
use Rex::LibSSH;
use Rex::GPU;
use Rex::Rancher;

my $key  = $ENV{REX_KEY}  || "$ENV{HOME}/.ssh/id_ed25519";
my $user = $ENV{REX_USER} || 'root';

set connection  => 'LibSSH';
set user        => $user;
set private_key => $key;
set public_key  => "$key.pub";
set auth        => 'key';

group 'avatar' => 'avatar.conflict.industries';

desc 'Full deploy: node prep + GPU drivers (reboot) + RKE2 + Cilium + device plugin';
task 'deploy', group => 'avatar', sub {
  rancher_deploy_server(
    distribution    => 'rke2',
    gpu             => 1,
    reboot          => 1,
    hostname        => 'avatar',
    domain          => 'conflict.industries',
    token           => 'avatarcluster',
    tls_san         => 'avatar.conflict.industries',
    kubeconfig_file => "$ENV{HOME}/.kube/rexdemo.yaml",
  );
};
