use strict;
use warnings;
use Test::More;
use Test::RedisServer;
use Redis::LeaderBoardMulti;

my $redis_backend = $ENV{REDIS_BACKEND} || 'Redis';
eval "use $redis_backend";

my $redis_server = eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

my $redis = $redis_backend->new( $redis_server->connect_info );

subtest 'do not use script, use normal key' => sub {
    my $l = Redis::LeaderBoardMulti->new(
        redis => $redis,
        key   => 'sortable-member',
        use_script => 0,
        use_hash   => 0,
        order      => ['asc', 'asc'],
    );
    $redis->flushall;
    test_leader_board($l);
};

subtest 'do not use script, use hash key' => sub {
    my $l = Redis::LeaderBoardMulti->new(
        redis => $redis,
        key   => 'sortable-member',
        use_script => 0,
        use_hash   => 1,
        order      => ['asc', 'asc'],
    );
    $redis->flushall;
    test_leader_board($l);
};

subtest 'use script, use normal key' => sub {
    my $l = Redis::LeaderBoardMulti->new(
        redis => $redis,
        key   => 'sortable-member',
        use_script => 1,
        use_hash   => 0,
        order      => ['asc', 'asc'],
    );
    $redis->flushall;
    test_leader_board($l);
};

subtest 'use script, use hash key' => sub {
    my $l = Redis::LeaderBoardMulti->new(
        redis => $redis,
        key   => 'sortable-member',
        use_script => 1,
        use_hash   => 1,
        order      => ['asc', 'asc'],
    );
    $redis->flushall;
    test_leader_board($l);
};

sub test_leader_board {
    my $l = shift;

    note 'set_score';
    $l->set_score('z', [1, 1]);
    $l->set_score('y', [2, 1]);
    $l->set_score('x', [2, 1]);
    $l->set_score('w', [2, 2]);

    note 'get_rank';
    is $l->get_rank('z'), 1;
    is $l->get_rank('y'), 2;
    is $l->get_rank('x'), 2;
    is $l->get_rank('w'), 4;

    note 'get_sorted_order';
    is $l->get_sorted_order('z'), 0;
    is $l->get_sorted_order('y'), 2;
    is $l->get_sorted_order('x'), 1;
    is $l->get_sorted_order('w'), 3;

    note 'get_rank_with_score';
    is_deeply [$l->get_rank_with_score('z')], [1, 1, 1];
    is_deeply [$l->get_rank_with_score('y')], [2, 2, 1];
    is_deeply [$l->get_rank_with_score('x')], [2, 2, 1];
    is_deeply [$l->get_rank_with_score('w')], [4, 2, 2];

    note 'get_rank_by_score';
    is $l->get_rank_by_score([1, 1]), 1;
    is $l->get_rank_by_score([2, 1]), 2;
    is $l->get_rank_by_score([2, 2]), 4;

    note 'modify the score of existing key by set_score';
    $l->set_score('z', [3, 1]);
    is $l->get_rank('w'), 3;
    is $l->get_rank('z'), 4;

    note 'remove';
    $l->remove('w');
    is $l->get_rank('z'), 3;
}

done_testing;
