use Mojo::Base -strict;
use Mojo::Redis2;
use Test::More;

plan skip_all => 'Cannot test on Win32' if $^O eq 'MSWin32';
plan skip_all => $@ unless eval { Mojo::Redis2::Server->start };

my $redis = Mojo::Redis2->new;
my $bulk = $redis->bulk;
my ($err, $res);

$res = eval { $bulk->ping->set(foo => 123)->get("foo")->execute };
is_deeply $res, [ 'PONG', 'OK', '123', ], 'got sync res';

Mojo::IOLoop->delay(
  sub {
    my ($delay) = @_;
    $bulk->ping->set(foo => 123)->get("foo")->execute($delay->begin);
  },
  sub {
    (my $delay, $err, $res) = @_;
    Mojo::IOLoop->stop;
  },
);
Mojo::IOLoop->start;

is $err->compact->join('. '), '', 'no errors';
is_deeply $res, [ 'PONG', 'OK', '123', ], 'got async res';

{
  # mostly just for code coverage
  for my $method ($redis->_basic_operations) {
    $bulk->$method;
  }

  eval { $bulk->execute };
  like $@, qr{wrong number of arguments}, 'wrong number of arguments';
}

done_testing;
