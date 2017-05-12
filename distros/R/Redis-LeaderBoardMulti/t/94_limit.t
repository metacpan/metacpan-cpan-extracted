use strict;
use warnings;
use utf8;

use Test::More;
use Test::RedisServer;
use Redis::LeaderBoardMulti;

my $redis_backend = $ENV{REDIS_BACKEND} || 'Redis';
eval "use $redis_backend";

my $redis_server = eval { Test::RedisServer->new }
    or plan skip_all => 'redis-server is required in PATH to run this test';
my $redis = $redis_backend->new($redis_server->connect_info);

sub test {
    my $opt = shift;
    $redis->flushall;
    subtest 'limit with desc' => sub {
        my $redis_ranking = Redis::LeaderBoardMulti->new(
            key        => 'testlimit1',
            redis      => $redis,
            limit      => 3,
            %$opt,
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
            scores => [4], # added
        }, {
            member => 'three',
            score  => 3,
            rank   => 2,
            scores => [3], # added
        }, {
            member => 'two',
            score  => 2,
            rank   => 3,
            scores => [2], # added
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
            scores => [4], # added
        }, {
            # XXX: Redis::LeaderBoard will retrun three-dash, but Redis::LeaderBoardMulti will not
            member => 'three',
            score  => 3,
            rank   => 2,
            scores => [3], # added
        }, {
            # XXX: Redis::LeaderBoard will retrun three, but Redis::LeaderBoardMulti will not
            member => 'three-dash', # three
            score  => 3,
            rank   => 2,
            scores => [3], # added
        }];
    };

    subtest 'limit with desc' => sub {
        my $redis_ranking = Redis::LeaderBoardMulti->new(
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
            scores => [0], # added
        }, {
            member => 'one',
            score  => 1,
            rank   => 2,
            scores => [1], # added
        }, {
            member => 'two',
            score  => 2,
            rank   => 3,
            scores => [2], # added
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
            scores => [0], # added
        }, {
            member => 'zero2',
            score  => 0,
            rank   => 1,
            scores => [0], # added
        }, {
            member => 'one',
            score  => 1,
            rank   => 3,
            scores => [1], # added
        }];
    };
}

subtest 'no opotion' => sub { test({}) };
subtest 'do not use script, use normal key' => sub { test({use_script => 0, use_hash => 0}) };
subtest 'do not use script, use hash key'   => sub { test({use_script => 0, use_hash => 1}) };
subtest 'use script,        use normal key' => sub { test({use_script => 1, use_hash => 0}) };
subtest 'use script,        use hash key'   => sub { test({use_script => 1, use_hash => 1}) };

done_testing;
