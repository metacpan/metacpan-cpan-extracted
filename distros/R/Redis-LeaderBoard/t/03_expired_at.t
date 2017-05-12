use strict;
use warnings;
use utf8;

use Test::More;
use Test::RedisServer;
use Redis;
use Redis::LeaderBoard;

my $redis_server = eval { Test::RedisServer->new }
    or plan skip_all => 'redis-server is required in PATH to run this test';
my $redis = Redis->new($redis_server->connect_info);

subtest 'get incr set' => sub {
    my $redis_ranking = Redis::LeaderBoard->new(
        key        => 'test1',
        redis      => $redis,
        expire_at => time() + 2,
    );

    $redis_ranking->set_score(one => 10);
    is $redis_ranking->get_score('one'), 10;
    sleep 2;

    ok !$redis_ranking->get_score('one');
};

done_testing;
