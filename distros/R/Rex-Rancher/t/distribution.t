use strict;
use warnings;
use Test::More;

use Rex::Rancher;

# An unknown distribution dies before the host is touched: before
# rancher_deploy_* runs prepare_node and Rex::GPU's driver install
# (containerd_config => distribution), and before install_server/install_agent
# write a file or run a command. Offline: every remote step is a fake that
# records what ran. This proves the order of the checks, not a deploy.

my @ran;
my %join = ( server => 'https://cp:9345', token => 't' );

no warnings 'redefine';
local *Rex::Rancher::Server::run  = sub { push @ran, 'server run'; '' };
local *Rex::Rancher::Server::file = sub { push @ran, 'server file' };
local *Rex::Rancher::Agent::run   = sub { push @ran, 'agent run'; '' };
local *Rex::Rancher::Agent::file  = sub { push @ran, 'agent file' };
# The shared steps in Rex::Rancher::Distribution call Rex::Commands::* directly.
local *Rex::Commands::Run::run    = sub { push @ran, 'rex run'; '' };
local *Rex::Commands::File::file  = sub { push @ran, 'rex file' };
use warnings 'redefine';

# The public install functions keep their own check. Before the pipeline fakes
# below: Rex::Exporter shares the install_* globs with Rex::Rancher.
{
  @ran = ();
  ok(!eval { Rex::Rancher::Server::install_server(distribution => 'containerd'); 1 },
    'install_server, containerd: dies');
  is($@, "Unknown distribution: containerd (expected 'rke2' or 'k3s')\n",
    'install_server, containerd: message');
  is_deeply(\@ran, [], 'install_server, containerd: host untouched');

  @ran = ();
  ok(!eval { Rex::Rancher::Agent::install_agent(%join, distribution => 'containerd'); 1 },
    'install_agent, containerd: dies');
  is($@, "Unknown distribution: containerd (expected 'rke2' or 'k3s')\n",
    'install_agent, containerd: message, no line number');
  is_deeply(\@ran, [], 'install_agent, containerd: host untouched');
}

no warnings 'redefine';
local *Rex::Rancher::_check_connection       = sub { push @ran, 'check_connection' };
local *Rex::Rancher::prepare_node            = sub { push @ran, 'prepare_node' };
local *Rex::Rancher::_gpu_setup_if_requested = sub { push @ran, 'gpu_setup' };
# Rex::GPU is not needed here: its check has t/gpu-module-version.t.
local *Rex::Rancher::_check_gpu_module       = sub { };
local *Rex::Rancher::install_server          = sub { push @ran, 'install_server' };
local *Rex::Rancher::install_agent           = sub { push @ran, 'install_agent' };
use warnings 'redefine';

my %deploy = (
  rancher_deploy_server => sub { Rex::Rancher::rancher_deploy_server(@_, cilium => 0) },
  rancher_deploy_agent  => sub { Rex::Rancher::rancher_deploy_agent(%join, @_) },
);

for my $name (sort keys %deploy) {
  for my $dist ('containerd', 'RKE2', 'k3s ', '') {
    @ran = ();
    ok(!eval { $deploy{$name}->(distribution => $dist, gpu => 1); 1 },
      $name.", distribution '".$dist."': dies");
    is($@, "Unknown distribution: $dist (expected 'rke2' or 'k3s'); nothing was done on the host\n",
      $name.", distribution '".$dist."': names it and the valid values");
    is_deeply(\@ran, [], $name.", distribution '".$dist."': before the connection check and any host step");
  }
  for my $dist (qw( rke2 k3s )) {
    @ran = ();
    $deploy{$name}->(distribution => $dist, gpu => 1);
    # Between them only the preflight's reads of the host (k78), all run.
    my @steps = grep { !/ run$/ } @ran;
    is($steps[1], 'prepare_node', $name.', '.$dist.': passes the check');
  }
}

done_testing;
