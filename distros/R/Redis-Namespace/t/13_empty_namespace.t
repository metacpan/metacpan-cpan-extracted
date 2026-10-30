use strict;
use warnings;
use Test::More;
use Redis;
use Test::RedisServer;

use Redis::Namespace;

eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

subtest 'add_namespace and rem_namespace' => sub {
    my $ns = Redis::Namespace->new(redis => bless({},'FakeRedis'), namespace => '0');
    is_deeply [$ns->add_namespace('foo')], ['0:foo'], 'namespace "0" is a namespace';
    is_deeply [$ns->rem_namespace('0:foo')], ['foo'], 'namespace "0" is removed';

    for my $namespace (undef, '') {
        my $ns = Redis::Namespace->new(redis => bless({},'FakeRedis'), namespace => $namespace);
        is_deeply [$ns->add_namespace('foo')], ['foo'], 'no namespace is added';
        is_deeply [$ns->rem_namespace('foo')], ['foo'], 'no namespace is removed';
    }
};

my $redis_server = Test::RedisServer->new;
my $redis = Redis->new( $redis_server->connect_info );

subtest 'namespace "0"' => sub {
    my $ns = Redis::Namespace->new(redis => $redis, namespace => '0');
    $redis->set('foo', 'global');
    ok($ns->set('foo', 'bar'), 'set foo');
    is($redis->get('0:foo'), 'bar', 'foo in namespace');
    is($redis->get('foo'), 'global', 'global foo is not changed');
    is_deeply([$ns->keys('*')], ['foo'], 'keys');
    my ($iter, $keys) = $ns->scan(0, count => 100);
    is_deeply($keys, ['foo'], 'scan');
    $redis->flushall;
};

for my $namespace (undef, '') {
    my $name = defined $namespace ? 'empty namespace' : 'no namespace';
    subtest $name => sub {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };

        my $ns = Redis::Namespace->new(redis => $redis, namespace => $namespace);
        ok($ns->set('foo', 'bar'), 'set foo');
        is($redis->get('foo'), 'bar', 'foo is not prefixed');
        is_deeply([sort $ns->keys('f*')], ['foo'], 'keys');
        my ($iter, $keys) = $ns->scan(0, match => 'f*', count => 100);
        is_deeply($keys, ['foo'], 'scan with match');
        ($iter, $keys) = $ns->scan(0, count => 100);
        is_deeply($keys, ['foo'], 'scan without match');
        is_deeply(\@warnings, [], 'no warnings');
        $redis->flushall;
    };
}

done_testing;
