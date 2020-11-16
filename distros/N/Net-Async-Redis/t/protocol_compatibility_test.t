use strict;
use warnings;

use Test::More;

use Future::AsyncAwait;
use Syntax::Keyword::Try;

use IO::Async::Loop;
use Net::Async::Redis;

plan skip_all => 'set NET_ASYNC_REDIS5_URI and NET_ASYNC_REDIS6_URI env var to test' unless exists $ENV{NET_ASYNC_REDIS5_URI} and exists $ENV{NET_ASYNC_REDIS6_URI};

my $loop = IO::Async::Loop->new();

$loop->add(my $redis5 = Net::Async::Redis->new(uri => $ENV{NET_ASYNC_REDIS5_URI}));
$loop->add(my $redis6 = Net::Async::Redis->new(uri => $ENV{NET_ASYNC_REDIS6_URI}, protocol => 'resp3', hashrefs => 0));

sub test_responses {
    my @responses = @_;
    my $i = 0;

    my $len = @responses;
    die 'We should collect responses form both versions' unless $len % 2 == 0;

    while ($i < $len / 2) {
        ok($responses[$i], 'redis 5 response is not empty');
        ok($responses[$i + ($len / 2)], 'redis 6 response is not empty');
        is_deeply($responses[$i], $responses[$i + ($len / 2)], 'response format should the same');
        $i += 2;
    }
}

# Since we are dealing with hashes trasnformed into arrays order is not gurnteed
# We just need to make sure that first_stream is the first item in the list
sub dummy_sort {
    my $arr = shift;
    my $first = $arr->[0];
    my $second = $arr->[1];

    if ($second->[0] eq 'first_stream') {
        $arr = [$second, $first];
    }

    return $arr;
}

subtest 'xread family' => sub {
    (async sub {
        my @responses;
        for my $redis ($redis5, $redis6) {
            try {
                await $redis->xadd('first_stream', '1', key => 'value');
                await $redis->xadd('second_stream', '1', key => 'value');

                await $redis->xgroup('create', 'first_stream', 'group1', 0);
                await $redis->xgroup('create', 'second_stream', 'group1', 0);

                my $response = await $redis->xread('streams', 'first_stream', 'second_stream', 0, 0);
                push @responses, dummy_sort($response);

                $response = await $redis->xreadgroup(group => 'group1', 'innocent_consumer', 'streams', 'first_stream', 'second_stream', '>', '>');
                push @responses, dummy_sort($response);
            } catch($e) {
                is($e, undef, 'should not have an error');
            }

            await $redis->xgroup('destroy', 'first_stream', 'group1');
            await $redis->xgroup('destroy', 'second_stream', 'group1');
            await $redis->del('first_stream');
            await $redis->del('second_stream');

        }

        test_responses(@responses);

    })->()->get();
};


subtest 'zrange family' => sub {
    (async sub {
        my @responses;
        for my $redis ($redis5, $redis6) {
            try {
                for my $score (1..5) {
                    await $redis->zadd('sorted-set', $score, 'val_'.$score);
                }

                my $response = await $redis->zrange('sorted-set', 0, -1, 'WITHSCORES');
                push @responses, $response;

                $response = await $redis->zrangebyscore('sorted-set', 0, -1, 'WITHSCORES');
                push @responses, $response;

                $response = await $redis->zrevrange('sorted-set', -1, 0, 'WITHSCORES');
                push @responses, $response;

                $response = await $redis->zrevrangebyscore('sorted-set', -1, 0, 'WITHSCORES');
            } catch($e) {
                is($e, undef, 'should not have an error');
            }
            await $redis->del('sorted-set');

        }

        test_responses(@responses);

    })->()->get();

};

done_testing();
