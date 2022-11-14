use Mojo::Base -strict;
use Test2::V0;
use Mojo::File qw(curfile);
use Mojo::Server::DaemonControl;

plan skip_all => 'TEST_LIVE=1' unless $ENV{TEST_LIVE};

my $listen = sprintf 'http://127.0.0.1:%s', Mojo::IOLoop::Server->generate_port;
my $app    = curfile->sibling('myapp.pl')->to_abs->to_string;

subtest 'Stop manager with signal' => sub {
  my $dctl = dctl(workers => 1);
  my @stop;
  for my $sig (qw(INT QUIT TERM)) {
    $dctl->once(stop      => sub { push @stop, $_[1] });
    $dctl->once(heartbeat => sub { kill $sig => $$ });
    $dctl->run($app);
  }

  is \@stop, [qw(INT QUIT TERM)], 'INT QUIT TERM';
};

subtest 'Increase workers' => sub {
  my $dctl = dctl(workers => 3);

  my $n_spawned = 0;
  $dctl->on(spawn => sub { shift->stop if ++$n_spawned >= 5 });
  $dctl->once(start => sub { kill TTIN => $$ for 1 .. 2 });

  $dctl->run($app);
  is $n_spawned,     5, 'spawned workers';
  is $dctl->workers, 5, 'inc workers';
};

subtest 'Decrease workers' => sub {
  my $dctl = dctl(workers => 3);

  my $n_reaped = 0;
  $dctl->on(reap      => sub { shift->stop if ++$n_reaped >= 3 });
  $dctl->on(heartbeat => sub { kill TTOU => $$ });
  $dctl->run($app);
  is $n_reaped,      3, 'reaped workers';
  is $dctl->workers, 0, 'dec workers';
};

done_testing;

sub dctl {
  my $dctl = Mojo::Server::DaemonControl->new(@_, heartbeat_interval => 0.1, listen => [$listen]);
  my $n    = 0;
  $dctl->on(heartbeat => sub { delete shift->{running} if ++$n > 10 });
  return $dctl;
}
