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

    subtest 'get incr set' => sub {
        my $redis_ranking = Redis::LeaderBoardMulti->new(
            key   => 'test1',
            redis => $redis,
            %$opt,
        );

        $redis_ranking->set_score(one => 10);
        is $redis_ranking->incr_score(one => 10), 20;
        is $redis_ranking->get_score('one'), 20;

        is $redis_ranking->decr_score(one => 3), 17;
        is $redis_ranking->get_score('one'), 17;

        $redis_ranking->set_score(one => 5);
        is $redis_ranking->get_score('one'), 5;
    };

    subtest 'empty' => sub {
        my $redis_ranking = Redis::LeaderBoardMulti->new(
            key   => 'empty',
            redis => $redis,
            %$opt,
        );
        my ($rank, $score) = $redis_ranking->get_rank_with_score('one');
        ok !$rank;
        ok !$score;
        ok !$redis_ranking->get_score('one');
        ok !$redis_ranking->get_rank('one');
    };

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
        for my $score (@scores) {
            my ($rank, $member, $score) = @$score;
            is_deeply [$redis_ranking->get_rank_with_score($member)],  [$rank, $score];
            is $redis_ranking->get_rank($member), $rank;
        }

    };

    subtest 'get_rank_with_score_desc' => sub {
        my $redis_ranking = Redis::LeaderBoardMulti->new(
            key   => 'test_desc',
            redis => $redis,
            order => 'asc',
            %$opt,
        );
        my @scores = (
            [1, one   => -11],
            [2, two   => 11],
            [2, two2  => 11],
            [4, four  => 20],
            [5, five  => 30],
            [6, six   => 44],
            [6, six2  => 44],
            [6, six3  => 44],
            [9, nine  => 80],
        );

        my @flat_scores = map { ($_->[1], $_->[2]) } @scores;
        $redis_ranking->set_score(@flat_scores);
        for my $score (@scores) {
            my ($rank, $member, $score) = @$score;
            is_deeply [$redis_ranking->get_rank_with_score($member)],  [$rank, $score];
            is $redis_ranking->get_rank($member), $rank;
        }

        is_deeply $redis_ranking->rankings(limit => 2, offset => 3), [{
            member => 'four',
            rank   => 4,
            score  => 20,
            scores => [20], # added
        }, {
            member => 'five',
            rank   => 5,
            score  => 30,
            scores => [30], # added
        }];
    };

    subtest 'get_rank_with_score_same' => sub {
        my $redis_ranking = Redis::LeaderBoardMulti->new(
            key   => 'test_same1',
            redis => $redis,
            %$opt,
        );
        my @scores = (
            [1, one   => 100],
            [1, one2  => 100],
            [3, three => 50],
            [4, four  => 30],
        );
        for my $score (@scores) {
            my ($rank, $member, $score) = @$score;
            $redis_ranking->set_score($member => $score);
        }

        is_deeply [$redis_ranking->get_rank_with_score('one')],  [1, 100];
        is_deeply [$redis_ranking->get_rank_with_score('one2')], [1, 100];
        is_deeply [$redis_ranking->get_rank_with_score('three')], [3, 50];

        $redis_ranking->incr_score(one => 1);
        is_deeply [$redis_ranking->get_rank_with_score('one')],  [1, 101];
        is_deeply [$redis_ranking->get_rank_with_score('one2')], [2, 100];

        is $redis_ranking->member_count, 4;

        subtest rankings => sub {
            is_deeply( $redis_ranking->rankings, [{
                member => 'one',
                rank   => 1,
                score  => 101,
                scores => [101], # added
            }, {
                member => 'one2',
                rank   => 2,
                score  => 100,
                scores => [100], # added
            }, {
                member => 'three',
                rank   => 3,
                score  => 50,
                scores => [50], # added
            }, {
                member => 'four',
                rank   => 4,
                score  => 30,
                scores => [30], # added
            },]);

            is_deeply( $redis_ranking->rankings(limit => 2), [{
                member => 'one',
                rank   => 1,
                score  => 101,
                scores => [101], # added
            }, {
                member => 'one2',
                rank   => 2,
                score  => 100,
                scores => [100], # added
            },]);

            is_deeply( $redis_ranking->rankings(limit => 1, offset => 2), [{
                member => 'three',
                rank   => 3,
                score  => 50,
                scores => [50], # added
            },]);

            is_deeply( $redis_ranking->rankings(limit => 10, offset => 2), [{
                member => 'three',
                rank   => 3,
                score  => 50,
                scores => [50], # added
            }, {
                member => 'four',
                rank   => 4,
                score  => 30,
                scores => [30], # added
            },]);

            is_deeply( $redis_ranking->rankings(offset => 4), []);
        };

        $redis_ranking->remove('one2');
        is_deeply [$redis_ranking->get_rank_with_score('three')], [2, 50];
    };
}

subtest 'no opotion' => sub { test({}) };
subtest 'do not use script, use normal key' => sub { test({use_script => 0, use_hash => 0}) };
subtest 'do not use script, use hash key'   => sub { test({use_script => 0, use_hash => 1}) };
subtest 'use script,        use normal key' => sub { test({use_script => 1, use_hash => 0}) };
subtest 'use script,        use hash key'   => sub { test({use_script => 1, use_hash => 1}) };

done_testing;
