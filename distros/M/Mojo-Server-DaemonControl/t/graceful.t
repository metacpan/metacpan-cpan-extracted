use Mojo::Base -strict;
use Test2::V0;
use Mojo::File qw(curfile);
use Mojo::IOLoop::Server;
use Mojo::Promise;
use Mojo::Server::DaemonControl;
use Mojo::UserAgent;
use Time::HiRes qw(time);

plan skip_all => 'TEST_LIVE=1' unless $ENV{TEST_LIVE};

my $app    = curfile->dirname->child('myapp.pl');
my $listen = Mojo::URL->new(sprintf 'http://127.0.0.1:%s', Mojo::IOLoop::Server->generate_port);
my $t0;

subtest 'stop workers gracefully' => sub {
  my $dctl = Mojo::Server::DaemonControl->new(heartbeat_interval => 0.5, listen => [$listen],
    workers => 2);
  my %pids;

  $dctl->on(
    heartbeat => sub {
      my ($dctl, $w) = @_;
      ok $pids{$$} = kill(QUIT => $$), 'signal manager' if keys(%pids) >= 2 and !$pids{$$};
      run_slow_request_in_fork() unless %pids;
      $pids{$w->{pid}} ||= 0;
    }
  );

  $dctl->on(reap => sub { $pids{$_[1]->{pid}} = time });
  $dctl->run($app);

  delete $pids{$$};
  my @t = sort map { sprintf '%.3f', $_ - $t0 } values %pids;
  is $t[0], within(0.5, 0.3), "one worker had nothing to do ($t[0])";
  is $t[1], within(2.2, 0.5), "one worker had to finish the request ($t[1])";
};

done_testing;

sub run_slow_request_in_fork {
  $t0 = time;
  return if fork;
  Mojo::UserAgent->new->get($listen->clone->path('/slow'));
  exit 0;
}
