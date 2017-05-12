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

subtest 'limit with desc' => sub {
    my $redis_ranking = Redis::LeaderBoard->new(
        key        => 'testlimit1',
        redis      => $redis,
        limit      => 3,
    );

    $redis_ranking->set_score(
        zero  => 0,
        one   => 1,
    );
    is $redis_ranking->member_count, 2;

    $redis_ranking->set_score(
        zero  => 0,
        one   => 1,
        two   => 2,
        three => 3,
        four  => 4,
    );
    is $redis_ranking->member_count, 3;

    is_deeply $redis_ranking->rankings, [{
        member => 'four',
        score  => 4,
        rank   => 1,
    }, {
        member => 'three',
        score  => 3,
        rank   => 2,
    }, {
        member => 'two',
        score  => 2,
        rank   => 3,
    }];


    $redis_ranking->set_score(
        'three-dash' => 3,
        'zero2'      => 0,
    );

    is $redis_ranking->member_count, 3;
    is_deeply $redis_ranking->rankings, [{
        member => 'four',
        score  => 4,
        rank   => 1,
    }, {
        member => 'three-dash',
        score  => 3,
        rank   => 2,
    }, {
        member => 'three',
        score  => 3,
        rank   => 2,
    }];
};

subtest 'limit with desc' => sub {
    my $redis_ranking = Redis::LeaderBoard->new(
        key   => 'testlimit2',
        redis => $redis,
        limit => 3,
        order => 'asc',
    );

    $redis_ranking->set_score(
        zero  => 0,
        one   => 1,
    );
    is $redis_ranking->member_count, 2;

    $redis_ranking->set_score(
        zero  => 0,
        one   => 1,
        two   => 2,
        three => 3,
        four  => 4,
    );
    is $redis_ranking->member_count, 3;

    is_deeply $redis_ranking->rankings, [{
        member => 'zero',
        score  => 0,
        rank   => 1,
    }, {
        member => 'one',
        score  => 1,
        rank   => 2,
    }, {
        member => 'two',
        score  => 2,
        rank   => 3,
    }];


    $redis_ranking->set_score(
        'three-dash' => 3,
        'zero2'      => 0,
    );

    is $redis_ranking->member_count, 3;
    is_deeply $redis_ranking->rankings, [{
        member => 'zero',
        score  => 0,
        rank   => 1,
    }, {
        member => 'zero2',
        score  => 0,
        rank   => 1,
    }, {
        member => 'one',
        score  => 1,
        rank   => 3,
    }];
};

done_testing;
