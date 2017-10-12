use Mojo::Base -strict;
use Mojo::Redis2;
use Test::More;

plan skip_all => 'Cannot test on Win32' if $^O eq 'MSWin32';
plan skip_all => $@ unless eval { Mojo::Redis2::Server->start };

my $redis = Mojo::Redis2->new;
my ($ping_err, $c, $ping, $get_err, $get);

$redis->on(connection => sub { (my $redis, $c) = @_; });

is $redis->set('mojo:redis2:test_scalar' => 42), 'OK', 'SET mojo:redis2:test_scalar 42';
is $redis->get('mojo:redis2:test_scalar'), 42, 'GET mojo:redis2:test_scalar';

ok $c->{id}, 'connection id';
is $c->{nb}, 0, 'connection blocking';
is $c->{group}, 'blocking', 'connection blocking';

Mojo::IOLoop->delay(
  sub {
    my ($delay) = @_;
    $redis->ping($delay->begin)->get("mojo:redis2:test_scalar", $delay->begin);
  },
  sub {
    (my $delay, $ping_err, $ping, $get_err, $get) = @_;
    Mojo::IOLoop->stop;
  },
);
Mojo::IOLoop->start;

is $ping_err, '', 'no ping error';
is $ping, 'PONG', 'got PONG';
is $get_err, '', 'no get error';
is $get, 42, 'got 42';

is_deeply $redis->del('mojo:redis2:test_scalar'), '1', 'DEL mojo:redis2:test_scalar';

done_testing;
