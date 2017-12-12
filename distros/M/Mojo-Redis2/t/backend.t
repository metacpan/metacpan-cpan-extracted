use Mojo::Base -strict;
use Mojo::Redis2;
use Test::More;
use Time::HiRes 'sleep';

plan skip_all => 'Cannot test on Win32' if $^O eq 'MSWin32';
plan skip_all => $@ unless eval { Mojo::Redis2::Server->start };

my $redis   = Mojo::Redis2->new;
my $backend = $redis->backend;
my ($err, @res);

{
  my $info = $backend->info('clients');
  is $info->{connected_clients}, 1, 'connected_clients';
  is $info->{blocked_clients},   0, 'blocked_clients';

  $info = {};
  Mojo::IOLoop->delay(
    sub {
      my ($delay) = @_;
      is $backend->info(clients => $delay->begin), $backend, 'info return backend';
    },
    sub {
      $info = pop;
      Mojo::IOLoop->stop;
    },
  );
  Mojo::IOLoop->start;

  is $info->{connected_clients}, 2, 'async connected_clients';
  is $info->{blocked_clients},   0, 'async blocked_clients';
}

{
  $redis->set(foo => 123);
  is $backend->dbsize,     1,         'dbsize';
  like $backend->lastsave, qr{^\d+$}, 'lastsave';
  like $backend->time->[0], qr{^\d+$}, 'time.0';
  like $backend->time->[1], qr{^\d+$}, 'time.1';
}

SKIP: {
  skip 'REWRITE is not available', 1 unless eval { @res = $backend->rewrite; };
  is $res[0], 'OK', 'rewrite';
}

for my $method (qw( flushall flushdb resetstat save )) {
  @res = $backend->$method;
  is $res[0], 'OK', $method;
  sleep 0.1 while $backend->info('persistence')->{aof_rewrite_in_progress};
}

{
  @res = $backend->bgsave;
  like $res[0], qr{start}i, 'bgsave started';

  # Give the rewrite chance to complete
  sleep 0.1 while $backend->info('persistence')->{rdb_bgsave_in_progress};

  @res = $backend->bgrewriteaof;
  like $res[0], qr{scheduled|started}i, 'bgrewriteaof scheduled/started';

  # Give the rewrite chance to complete
  sleep 0.1 while $backend->info('persistence')->{aof_rewrite_in_progress};

  # needed to make sure dump.rdb exists
  Mojo::Redis2::Server->stop;
}

done_testing;

END {
  unlink glob '*.aof';
  unlink 'dump.rdb';
}
