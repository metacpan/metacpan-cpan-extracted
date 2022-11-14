use Mojo::Base -strict;
use Test2::V0;
use Mojo::File qw(curfile);
use Mojo::IOLoop::Server;
use Mojo::Promise;
use Mojo::Server::DaemonControl;
use Mojo::UserAgent;
use Time::HiRes qw(time);

plan skip_all => 'TEST_LIVE=1' unless $ENV{TEST_LIVE};

$ENV{MOJO_LOG_LEVEL} ||= 'fatal' unless $ENV{HARNESS_IS_VERBOSE};

my $app    = curfile->dirname->child('myapp.pl');
my $listen = sprintf 'http://127.0.0.1:%s', Mojo::IOLoop::Server->generate_port;
my $t0;

subtest 'force stop blocked workers' => sub {
  my $dctl = Mojo::Server::DaemonControl->new(
    graceful_timeout   => 0.5,
    heartbeat_interval => 0.5,
    heartbeat_timeout  => 1,
    listen             => [$listen],
    workers            => 2,
  );

  my %workers;
  $dctl->on(
    heartbeat => sub {
      my ($dctl, $w) = @_;
      $workers{$w->{pid}} = $w;

      # Only do this once
      state $ua_pid = run_slow_request_in_fork();

      # Do not stop the server before the forced worker is actually stopped
      $dctl->stop if grep { $_->{KILL} and !kill 0, $_->{pid} } values %workers;
    }
  );

  $dctl->run($app);

  my %got;
  for my $w (values %workers) {
    $got{graceful}++ if $w->{graceful};
    $got{forced}++   if $w->{KILL} and $w->{QUIT};
    $got{stopped}++  if $w->{TERM};
  }

  is \%got, {forced => 1, graceful => 1, stopped => 2}, 'workers killed';
};

done_testing;

sub run_slow_request_in_fork {
  $t0 = time;
  return if fork;
  Mojo::UserAgent->new->get("$listen/block");
  exit 0;
}
