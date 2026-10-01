use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# How the server installers start the service. rke2: get.rke2.io never starts
# rke2-server, the service is started with --no-block and polled; whether a
# running one needs a restart instead is asked first (t/restart-reasons.t).
# k3s: the install script runs with INSTALL_K3S_SKIP_START, since its own
# `systemctl restart` of the Type=notify k3s unit blocks until k3s is up,
# forever for an HA join that cannot reach its first server; k3s.service is
# then (after the version skew check of a running k3s, t/version-skew.t)
# restarted with --no-block (a re-run picks up a new binary and
# config.yaml) and polled by the bounded wait_for_service, like the agents
# (t/agent-start.t).
#
# run is faked; this proves the command order, not that a real server starts.
# -----------------------------------------------------------------------------

use Rex::Rancher::Server;
use Rex::Rancher::Distribution;

$Rex::Logger::silent = 1;

my @log;
{
  no warnings 'redefine';
  my $run = sub {
    my ( $cmd ) = @_;
    push @log, $cmd;
    $? = 0;
    return "active\n"   if $cmd =~ /^systemctl is-active/;
    return "yes\n"      if $cmd =~ /^test -f/;
    return "/usr/local/bin/rke2\n" if $cmd =~ /^command -v rke2/;
    return '';
  };
  # Server's own steps and the shared ones in Rex::Rancher::Distribution.
  *Rex::Rancher::Server::run = $run;
  *Rex::Commands::Run::run   = $run;
}

my %expect = (
  rke2 => [ 'curl -sfL https://get.rke2.io | sh -',
            'systemctl enable rke2-server',
            'systemctl show -p MainPID rke2-server 2>/dev/null',
            'systemctl start --no-block rke2-server',
            'systemctl is-active rke2-server' ],
  k3s  => [ 'curl -sfL https://get.k3s.io | K3S_URL=https://cp1:6443 INSTALL_K3S_SKIP_START=true sh -s - server --write-kubeconfig-mode=644',
            'systemctl enable k3s',
            'systemctl show -p MainPID k3s 2>/dev/null',
            'systemctl restart --no-block k3s',
            'systemctl is-active k3s' ],
);

Rex::Rancher::Server::_install( Rex::Rancher::Distribution->new_for('rke2'), undef, undef, 'script' );
my @rke2 = grep { /get\.rke2\.io|^systemctl/ } @log;
is_deeply( \@rke2, $expect{rke2}, 'rke2: installer does not start, then start --no-block and the bounded wait' );

@log = ();
Rex::Rancher::Server::_install( Rex::Rancher::Distribution->new_for('k3s'), 'https://cp1:6443', undef, 'script' );
my @k3s = grep { /get\.k3s\.io|^systemctl/ } @log;
is_deeply( \@k3s, $expect{k3s}, 'k3s: installer does not start, then restart --no-block and the bounded wait' );
ok( ( grep { /^test -f \/etc\/rancher\/k3s\/k3s\.yaml/ } @log ), 'k3s: kubeconfig wait follows' );

done_testing;
