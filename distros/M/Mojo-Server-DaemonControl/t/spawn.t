use Mojo::Base -strict;
use Test2::V0;
use Mojo::File qw(curfile);
use Mojo::IOLoop::Server;
use Mojo::Server::DaemonControl;

plan skip_all => 'TEST_LIVE=1' unless $ENV{TEST_LIVE};

my $app    = curfile->dirname->child('myapp.pl');
my $listen = Mojo::URL->new(sprintf 'http://127.0.0.1:%s', Mojo::IOLoop::Server->generate_port);

subtest 'spawn if reaped' => sub {
  my $dctl = Mojo::Server::DaemonControl->new(listen => [$listen], workers => 2);
  my %workers;

  $dctl->on(
    heartbeat => sub {
      my ($dctl, $w) = @_;
      my $kill_pid = keys(%workers) > 2 ? $$ : $w->{pid};
      ok kill(TERM => $kill_pid), "kill TERM $kill_pid";
    }
  );

  $dctl->on(spawn => sub { $workers{$_[1]->{pid}} = 1 });
  $dctl->on(reap  => sub { $workers{$_[1]->{pid}} += 100 });
  $dctl->run($app);

  my @res = values %workers;    # Could be three or four
  ok @res >= 3, 'reaped at least three workers';
  is \@res, [(101) x int @res], 'reaped';
};

done_testing;
