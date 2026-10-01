use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# How install_agent starts the agent, rke2 and k3s alike: the installer never
# starts it, then systemctl --no-block and the bounded wait_for_service.
# k3s' install script would otherwise `systemctl restart` the Type=notify
# k3s-agent itself and block until the join, forever for an agent that cannot
# reach its server (kubernetes-ocp k185). k3s is restarted, as the script did,
# so a re-run still picks up a new binary and config.yaml. Both ask for a
# running agent before the installer (version skew, t/version-skew.t) and
# before the start; rke2 then whether it needs a restart
# (t/restart-reasons.t); not here.
#
# run and file are faked; this proves the command order, not that a real
# agent joins.
# -----------------------------------------------------------------------------

use Rex::Rancher::Server;
use Rex::Rancher::Agent;

$Rex::Logger::silent = 1;

my @log;
our $state = "active\n";
my $run = sub {
  my ( $cmd ) = @_;
  push @log, $cmd;
  if ( $cmd =~ m{^systemctl is-active} ) { $? = 0; return $state }
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
  rke2 => [ 'systemctl show -p MainPID rke2-agent.service 2>/dev/null',
            'curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=agent sh -',
            'systemctl show -p MainPID rke2-agent.service 2>/dev/null',
            'systemctl enable rke2-agent.service',
            'systemctl start --no-block rke2-agent.service',
            'systemctl is-active rke2-agent.service' ],
  k3s  => [ 'systemctl show -p MainPID k3s-agent.service 2>/dev/null',
            'curl -sfL https://get.k3s.io | K3S_URL=https://cp1:6443 INSTALL_K3S_SKIP_START=true sh -s - agent',
            'systemctl show -p MainPID k3s-agent.service 2>/dev/null',
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

# k44: an agent that never gets active names the address it joins through,
# the usual culprit, next to its journal.
my %join = ( rke2 => 'https://10.0.0.1:9345', k3s => 'https://10.0.0.1:6443' );
for my $dist (qw( rke2 k3s )) {
  local $state = "failed\n";
  ok( !eval { install_agent( distribution => $dist, server => $join{$dist}, token => 't' ); 1 },
    $dist.': failed agent dies' );
  like( $@, qr/is failed\nIt joins the cluster via \Q$join{$dist}\E -- check that this node can reach that address\n--- journalctl/,
    $dist.': message names the join address' );
}

done_testing;
