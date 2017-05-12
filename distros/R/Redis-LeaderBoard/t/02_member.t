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

subtest 'get_rank_with_score' => sub {
    my $redis_ranking = Redis::LeaderBoard->new(
        key   => 'test_asc',
        redis => $redis,
    );
    my @scores = (
        [1, one   => 100],
        [2, two   => 50],
        [2, two2  => 50],
        [4, four  => 30],
        [5, five  => 10],
        [6, six   => 8],
        [6, six2  => 8],
        [6, six3  => 8],
        [9, nine  => 1],
    );
    for my $score (@scores) {
        my ($rank, $member, $score) = @$score;
        $redis_ranking->set_score($member => $score);
    }

    my $member = $redis_ranking->find_member('six');
    isa_ok $member, 'Redis::LeaderBoard::Member';
    is $member->rank, 6;
    is $member->score, 8;

    $member->decr;
    is $member->rank, 8;
    is $member->score, 7;

    $member->incr(3);
    is $member->rank, 5;
    is $member->score, 10;
    is $redis_ranking->get_rank($member->member), 5;

    $member->score(110);
    is $member->rank, 1;
};

done_testing;
