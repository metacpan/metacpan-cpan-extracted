use strict;
use version 0.77;
use Test::More;
use Redis;
use Test::RedisServer;

use Redis::Namespace;

eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

my $redis_server = Test::RedisServer->new;
my $redis = Redis->new( $redis_server->connect_info );

my $ns = Redis::Namespace->new(
    redis => $redis,
    namespace => 'prefix',
);

$redis->mset( plain => 1, 'prefix:foo' => 2, 'prefix:bar' => 3 );

subtest 'no parameters' => sub {
    my %trace;
    $ns->scan_callback( sub { $trace{ $_[0] }++ } );
    is_deeply( \%trace, { foo => 1, bar => 1 }, "every key accessed once" );
};

subtest 'with parameters' => sub {
    my %trace;
    $ns->scan_callback( match => 'f*', sub { $trace{ $_[0] }++ } );
    is_deeply( \%trace, { foo => 1 }, "every matching key accessed once" );
};

done_testing;
