use strict;
use warnings;
use Test::More;
use Test::RedisServer;
use Redis::Transaction qw/watch_multi_exec/;
use Time::HiRes qw/time sleep/;

my $redis_backend = $ENV{REDIS_BACKEND} || 'Redis';
eval "use $redis_backend";

my $redis_server = eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';
my $redis = $redis_backend->new( $redis_server->connect_info );
my $redis2 = $redis_backend->new( $redis_server->connect_info );

subtest 'retry succeed' => sub {
    $redis->flushall;

    my ($res) = watch_multi_exec $redis, ['foo'], 10, sub {
        my $r = shift;
        note 'GET foo';
        my $foo = $r->get('foo') || 0;
    }, sub {
        my ($r, $foo) = @_;

        unless ($foo) {
            note "SET foo, 1 by another client";
            is $redis2->set('foo', 1), 'OK', 'another client changes `foo`';
        }

        note "SET foo, $foo + 10";
        is $r->set('foo', $foo + 10), 'QUEUED', 'SET command is queued.';
    };
    is $res, 'OK';

    is $redis->get('foo'), 11, 'my change is executed.';
};

subtest 'retry failed' => sub {
    $redis->flushall;

    my $try_count = 0;
    eval {
        watch_multi_exec $redis, ['foo'], 5, sub {
            my $r = shift;
            $try_count++;
            note 'GET foo';
            my $foo = $r->get('foo') || 0;
        }, sub {
            my ($r, $foo) = @_;

            note "SET foo, 1 by another client";
            is $redis2->set('foo', 1), 'OK', 'another client changes `foo`';

            note "SET foo, $foo + 10";
            is $r->set('foo', $foo + 10), 'QUEUED', 'SET command is queued.';
        };
    };
    like $@, qr/failed to retry/;
    is $try_count, 5, 'tried 10 times';
};

done_testing;
