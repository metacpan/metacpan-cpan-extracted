use Mojo::Base -strict;
use Test2::V0;
use Mojo::File qw(curfile);
use Mojo::IOLoop::Server;
use Mojo::Promise;
use Mojo::Server::DaemonControl;
use Mojo::UserAgent;

plan skip_all => 'TEST_LIVE=1' unless $ENV{TEST_LIVE};

# It is very unlikely that this test will succeed. It is only meant as a check
# to see if the load is distributed at all.
# On Macos 12.2.1 (ARM64) only one of the workers gets all the requests, while
# on Linux 5.13.0 (x86_64) it gets distributed more evenly.

my $n_req     = $ENV{TEST_LOAD_REQUESTS} || 100;
my $n_workers = $ENV{TEST_LOAD_WORKERS}  || 4;
my $app       = curfile->dirname->child('myapp.pl');
my $listen    = Mojo::URL->new(sprintf 'http://127.0.0.1:%s', Mojo::IOLoop::Server->generate_port);

subtest 'run and spawn if reaped' => sub {
  my $dctl = Mojo::Server::DaemonControl->new(listen => [$listen], workers => $n_workers);
  my %workers;

  $dctl->on(
    heartbeat => sub {
      my ($dctl, $w) = @_;
      $workers{$w->{pid}} ||= 0;
      return if keys(%workers) < $n_workers;

      state $ua = Mojo::UserAgent->new->max_connections(0);
      my $url = $listen->clone->path('/pid')->to_string;
      my $p   = Mojo::Promise->map({concurrency => 5}, sub { $ua->get_p($url) }, 1 .. $n_req);
      return $p->then(sub {
        $_->[0]->res->body =~ m!pid=(\d+)! && $workers{$1}++ for @_;
        $dctl->stop;
      })->catch(sub {
        ok 0, $_[0];
        $dctl->stop;
      })->wait;
    }
  );

  $dctl->run($app);
  is int(keys %workers), $n_workers, 'workers';

  my $todo = todo 'This test is unlikely to pass';
  is [values %workers], [($n_req / $n_workers) x $n_workers], 'load';

  warn Mojo::Util::tablify(
    [['#', '', ''], ['#', 'pid', 'req'], map { ['#', $_, $workers{$_}] } sort keys %workers])
    if $ENV{TEST_NOTES};
};

done_testing;
