use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# How install_agent starts the agent, rke2 and k3s alike: the installer never
# starts it, then systemctl --no-block and the bounded _wait_for_service.
# k3s' install script would otherwise `systemctl restart` the Type=notify
# k3s-agent itself and block until the join, forever for an agent that cannot
# reach its server (kubernetes-ocp k185). k3s is restarted, as the script did,
# so a re-run still picks up a new binary and config.yaml.
#
# run and file are faked; this proves the command order, not that a real
# agent joins.
# -----------------------------------------------------------------------------

use Rex::Rancher::Server;
use Rex::Rancher::Agent;

$Rex::Logger::silent = 1;

my @log;
my $run = sub {
  my ( $cmd ) = @_;
  push @log, $cmd;
  if ( $cmd =~ m{^systemctl is-active} ) { $? = 0; return "active\n" }
  $? = 0;
  return '';
};
{
  no warnings 'redefine';
  *Rex::Rancher::Server::run  = $run;
  *Rex::Rancher::Agent::run   = $run;
  *Rex::Rancher::Server::file = sub { push @log, 'file '.$_[0] };
}

my %expect = (
  rke2 => [ 'curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=agent sh -',
            'systemctl enable rke2-agent.service',
            'systemctl start --no-block rke2-agent.service',
            'systemctl is-active rke2-agent.service' ],
  k3s  => [ 'curl -sfL https://get.k3s.io | K3S_URL=https://cp1:6443 INSTALL_K3S_SKIP_START=true sh -s - agent',
            'systemctl enable k3s-agent.service',
            'systemctl restart --no-block k3s-agent.service',
            'systemctl is-active k3s-agent.service' ],
);

for my $dist (qw( rke2 k3s )) {
  @log = ();
  install_agent( distribution => $dist, server => 'https://cp1:6443', token => 't' );
  my @steps = grep { /get\.(rke2|k3s)\.io|^systemctl/ } @log;
  is_deeply( \@steps, $expect{$dist},
    $dist.': installer does not start, then a non-blocking (re)start and the bounded wait' );
}

done_testing;
