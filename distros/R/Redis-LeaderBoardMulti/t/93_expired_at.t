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
    subtest 'get incr set' => sub {
        my $redis_ranking = Redis::LeaderBoardMulti->new(
            key        => 'test1',
            redis      => $redis,
            expire_at => time() + 2,
            %$opt,
        );

        $redis_ranking->set_score(one => 10);
        is $redis_ranking->get_score('one'), 10;
        sleep 2;

        ok !$redis_ranking->get_score('one');
    };
}

subtest 'no opotion' => sub { test({}) };
subtest 'do not use script, use normal key' => sub { test({use_script => 0, use_hash => 0}) };
subtest 'do not use script, use hash key'   => sub { test({use_script => 0, use_hash => 1}) };
subtest 'use script,        use normal key' => sub { test({use_script => 1, use_hash => 0}) };
subtest 'use script,        use hash key'   => sub { test({use_script => 1, use_hash => 1}) };

done_testing;
