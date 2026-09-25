use strict;
use warnings;
use Test::More;

use Rex::Rancher;

# rancher_deploy_agent: option validation, then the connection check, then the
# host. Offline: every remote step is replaced by a fake that records the order.

# install_agent keeps its own check (public API), message without line number.
# Before the fakes below: Rex::Exporter shares the glob with Rex::Rancher::Agent.
my %join = ( server => 'https://cp:9345', token => 't' );
for my $missing (qw( server token )) {
  my %opts = %join;
  delete $opts{$missing};
  ok(!eval { Rex::Rancher::Agent::install_agent(%opts); 1 }, 'install_agent, no '.$missing.': dies');
  is($@, $missing." is required for install_agent\n", 'install_agent, no '.$missing.': message');
}

my @ran;
our %agent_opts;
no warnings 'redefine';
local *Rex::Rancher::_check_connection       = sub { push @ran, 'check_connection' };
local *Rex::Rancher::prepare_node            = sub { push @ran, 'prepare_node' };
local *Rex::Rancher::_gpu_setup_if_requested = sub { push @ran, 'gpu_setup' };
local *Rex::Rancher::install_agent           = sub { push @ran, 'install_agent'; %agent_opts = @_ };
use warnings 'redefine';

for my $dist (qw( rke2 k3s )) {
  @ran = ();
  Rex::Rancher::rancher_deploy_agent(%join, distribution => $dist, gpu => 1);
  is_deeply(\@ran, [qw( check_connection prepare_node gpu_setup install_agent )],
    $dist.': connection checked before the host is touched');
}

Rex::Rancher::rancher_deploy_agent(%join, node_labels => ['role=gpu']);
is_deeply($agent_opts{node_labels}, ['role=gpu'], 'node_labels passed to install_agent');

for my $missing (qw( server token )) {
  @ran = ();
  my %opts = %join;
  delete $opts{$missing};
  ok(!eval { Rex::Rancher::rancher_deploy_agent(%opts, gpu => 1); 1 },
    'no '.$missing.': dies');
  like($@, qr/^\Q$missing\E is required for rancher_deploy_agent\n\z/,
    'no '.$missing.': names it, no line number');
  is_deeply(\@ran, [], 'no '.$missing.': before the connection check and any host step');
}

# A failing connection check stops the pipeline before prepare_node.
{
  @ran = ();
  no warnings 'redefine';
  local *Rex::Rancher::_check_connection = sub { push @ran, 'check_connection'; die "no sftp\n" };
  use warnings 'redefine';
  ok(!eval { Rex::Rancher::rancher_deploy_agent(%join); 1 }, 'connection check fails: dies');
  is_deeply(\@ran, ['check_connection'], 'connection check fails: host untouched');
}

done_testing;
