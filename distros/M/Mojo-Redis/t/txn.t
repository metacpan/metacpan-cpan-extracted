use Mojo::Base -strict;
use Test::More;
use Mojo::Redis;

plan skip_all => 'TEST_ONLINE=redis://localhost' unless $ENV{TEST_ONLINE};

my $redis = Mojo::Redis->new($ENV{TEST_ONLINE});
my $db    = $redis->txn;
my $key   = "txn:$0";
my $res;

$db->set($key => 123)->get($key)->incr($key)->incrby($key => -10)->exec_p->then(sub { $res = shift })->wait;
is_deeply($res, ['OK', 123, 124, 114], 'exec_p');

$res = $db->set($key => 123)->get($key)->incr($key)->incrby($key => -10)->exec;
is_deeply($res, ['OK', 123, 124, 114], 'exec');

done_testing;
