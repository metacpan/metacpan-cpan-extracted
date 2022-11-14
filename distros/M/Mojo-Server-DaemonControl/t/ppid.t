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
my $listen = sprintf 'http://127.0.0.1:%s', Mojo::IOLoop::Server->generate_port;

subtest 'force quit worker' => sub {
  my $dctl = Mojo::Server::DaemonControl->new(heartbeat_interval => 0.5, listen => [$listen],
    workers => 1);

  my $w;
  $dctl->on(heartbeat => sub { run_slow_request_in_fork() unless $w; $w ||= $_[1] });
  $dctl->on(reap      => sub { $w = $_[1];                           shift->stop });
  $dctl->run($app);
  ok $w->{killed}, 'forced killed' or diag Mojo::Util::dumper($w);
};

done_testing;

sub run_slow_request_in_fork {
  return if fork;
  Mojo::UserAgent->new->get(sprintf "$listen/ppid/%s", $$ - 1);
  exit 0;
}
