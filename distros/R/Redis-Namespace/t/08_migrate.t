use strict;
use version 0.77;
use Test::More;
use Redis;
use Test::RedisServer;
use Test::TCP;

use Redis::Namespace;

eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

my $redis_server1 = Test::RedisServer->new;
my $server = Test::TCP->new(
    code => sub {
        my ($port) = @_;
        my $redis = Test::RedisServer->new(
            auto_start => 0,
            conf       => { port => $port },
        );
        $redis->exec;
    },
);
my $redis_server2 = Test::RedisServer->new;
my $redis1 = Redis->new( $redis_server1->connect_info );
my $redis2 = Redis->new( server => 'localhost:' . $server->port);
my $ns1 = Redis::Namespace->new(redis => $redis1, namespace => 'ns');
my $ns2 = Redis::Namespace->new(redis => $redis2, namespace => 'ns');

subtest 'basic MIGRATE test' => sub {
    my $redis_version = version->parse($redis1->info->{redis_version});
    plan skip_all => 'your redis does not support MIGRATE command'
        unless $redis_version >= '2.6.0';

    $redis1->flushall;
    $redis2->flushall;
    $ns1->set('hogehoge', 'foobar');
    is $ns1->migrate('localhost', $server->port, 'hogehoge', 0, 60), 'OK';
    is $ns1->get('hogehoge'), undef;
    is $ns2->get('hogehoge'), 'foobar';
};

subtest 'COPY' => sub {
    my $redis_version = version->parse($redis1->info->{redis_version});
    plan skip_all => 'your redis does not support COPY clause of MIGRATE command'
        unless $redis_version >= '3.0.0';

    $redis1->flushall;
    $redis2->flushall;
    $ns1->set('hogehoge', 'foobar');
    is $ns1->migrate('localhost', $server->port, 'hogehoge', 0, 60, 'COPY'), 'OK';
    is $ns1->get('hogehoge'), 'foobar';
    is $ns2->get('hogehoge'), 'foobar';
};

subtest 'REPLACE' => sub {
    my $redis_version = version->parse($redis1->info->{redis_version});
    plan skip_all => 'your redis does not support REPLACE clause of MIGRATE command'
        unless $redis_version >= '3.0.0';

    $redis1->flushall;
    $redis2->flushall;
    $ns1->set('hogehoge', 'foobar');
    $ns2->set('hogehoge', 'xxxxxx');
    is $ns1->migrate('localhost', $server->port, 'hogehoge', 0, 60, 'REPLACE'), 'OK';
    is $ns1->get('hogehoge'), undef;
    is $ns2->get('hogehoge'), 'foobar';
};

subtest 'multi keys' => sub {
    my $redis_version = version->parse($redis1->info->{redis_version});
    plan skip_all => 'your redis does not support KEYS clause of MIGRATE command'
        unless $redis_version >= '3.1.0';

    $redis1->flushall;
    $redis2->flushall;

    is $ns1->get("hogehoge$_"), undef, "hogehoge$_ is empty first" for 1..10;

    $ns1->set("hogehoge$_", "foobar$_") for 1..10;
    is $ns1->migrate(
        'localhost', $server->port, '', 0, 60,
        'KEYS' => map { "hogehoge$_" } 1..10,
    ), 'OK';

    is $ns2->get("hogehoge$_"), "foobar$_", "hogehoge$_ is set" for 1..10;
};

done_testing;
