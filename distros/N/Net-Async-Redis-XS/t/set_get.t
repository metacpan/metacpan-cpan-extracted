use strict;
use warnings;

use Test::More;
use Future::AsyncAwait;
use IO::Async::Loop;
use Net::Async::Redis::XS;

my $key = 'some-key';
my $value = 'some-value';

my $host = $ENV{NET_ASYNC_REDIS_HOST}
    or plan skip_all => 'Set NET_ASYNC_REDIS_HOST to run this test';

my $loop = IO::Async::Loop->new;
$loop->add(
    my $redis = Net::Async::Redis::XS->new(
        host => $host
    )
);
await $redis->connect;
await $redis->set($key, $value);
my $result = await $redis->get($key);
is($result, $value, 'value was set correctly');
await $redis->del('random-array'); # don't care if it was there or not
is((await $redis->lpush('random-array', qw(x y z))), 3, 'push to a random array gives 3 back');

done_testing;
