#!/usr/bin/env perl
# Example: full GPU cluster deploy on Hetzner dedicated server
#
# Usage:
#   rex -f eg/hetzner-gpu.pl -H <host> deploy

# Rex::LibSSH >= 0.004 verifies the host key against known_hosts by default
# (CWE-322 fix). A fresh Hetzner host has no entry, so the 'before ALL' hook at
# the bottom ssh-keyscans it into known_hosts before the first connect — this
# KEEPS verification on. To override and skip verification instead, add
# 'disable_strict_host_key_checking' to the feature list below.
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

# Pre-connect host-key scan (Rex::LibSSH >= 0.004) — see the note at the top.
# ssh-keyscans the target into known_hosts on the local machine before the
# first connect, keeping verification on. Must come after the task definition.
before 'ALL' => sub {
  my ($server) = @_;
  rancher_scan_known_hosts($server);
};

1;
