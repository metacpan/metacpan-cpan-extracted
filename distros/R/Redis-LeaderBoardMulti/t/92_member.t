# test compatibility with Redis::LeaderBoard
# steel from https://github.com/Songmu/p5-Redis-LeaderBoard

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
    subtest 'get_rank_with_score' => sub {
        my $redis_ranking = Redis::LeaderBoardMulti->new(
            key   => 'test_asc',
            redis => $redis,
            %$opt,
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
        isa_ok $member, 'Redis::LeaderBoardMulti::Member';
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
}

subtest 'no opotion' => sub { test({}) };
subtest 'do not use script, use normal key' => sub { test({use_script => 0, use_hash => 0}) };
subtest 'do not use script, use hash key'   => sub { test({use_script => 0, use_hash => 1}) };
subtest 'use script,        use normal key' => sub { test({use_script => 1, use_hash => 0}) };
subtest 'use script,        use hash key'   => sub { test({use_script => 1, use_hash => 1}) };

done_testing;
