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
is($result, $value);

done_testing;
