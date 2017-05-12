use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/../";
use Test::More;
use Test::RedisServer;
use Redis::Script qw/redis_eval/;
use t::RedisRecorder;

my $redis_backend = $ENV{REDIS_BACKEND} || 'Redis';
eval "use $redis_backend";

my $redis_server = eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

my $redis = $redis_backend->new( $redis_server->connect_info );

my $script = "return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}";
my $script_sha1 = "a42059b356c875f0717db19a51f6aaca9ae659ea";

subtest 'sha1' => sub {
    is lc Redis::Script->new(
        script      => $script,
    )->sha1, lc $script_sha1;
};

subtest 'evalsha' => sub {
    $redis->script_flush;
    my $s = Redis::Script->new(
        script      => $script,
        use_evalsha => 1,
    );
    my $r = t::RedisRecorder->new($redis);

    ok !$s->exists($r), 'the script is not cached before EVAL';

    $r->reset_record;
    is_deeply [$s->eval($r, ['key1', 'key2'], ['arg1', 'arg2'])], ['key1', 'key2', 'arg1', 'arg2'];
    is_deeply $r->record, [
        ['evalsha', $script_sha1, qw/2 key1 key2 arg1 arg2/],
        ['eval', $script, qw/2 key1 key2 arg1 arg2/],
    ], "fallback to EVAL";

    ok $s->exists($r), 'the script is cached after EVAL';
    $r->reset_record;
    is_deeply [$s->eval($r, ['key1', 'key2'], ['arg1', 'arg2'])], ['key1', 'key2', 'arg1', 'arg2'];
    is_deeply $r->record, [
        ['evalsha', $script_sha1, qw/2 key1 key2 arg1 arg2/],
    ], "not trigger fallback";
};

subtest 'eval' => sub {
    $redis->script_flush;
    my $s = Redis::Script->new(
        script      => $script,
        use_evalsha => 0,
    );
    my $r = t::RedisRecorder->new($redis);

    ok !$s->exists($r), 'the script is not cached before EVAL';

    $r->reset_record;
    is_deeply [$s->eval($r, ['key1', 'key2'], ['arg1', 'arg2'])], ['key1', 'key2', 'arg1', 'arg2'];
    is_deeply $r->record, [
        ['eval', $script, qw/2 key1 key2 arg1 arg2/],
    ], "execute EVAL directory";

    ok $s->exists($r), 'the script is cached after EVAL';

    $r->reset_record;
    is_deeply [$s->eval($r, ['key1', 'key2'], ['arg1', 'arg2'])], ['key1', 'key2', 'arg1', 'arg2'];
    is_deeply $r->record, [
        ['eval', $script, qw/2 key1 key2 arg1 arg2/],
    ], "execute EVAL directory";
};

subtest 'load' => sub {
    $redis->script_flush;
    my $s = Redis::Script->new(
        script => $script,
    );

    ok !$s->exists($redis), 'the script is not cached before EVAL';
    is lc $s->load($redis), lc $script_sha1, "loading script success";
    ok $s->exists($redis), 'the script is cached after EVAL';
};

subtest 'eval' => sub {
    $redis->script_flush;
    is_deeply [redis_eval($redis, $script, ['key1', 'key2'], ['arg1', 'arg2'])], ['key1', 'key2', 'arg1', 'arg2'];
};

done_testing;
