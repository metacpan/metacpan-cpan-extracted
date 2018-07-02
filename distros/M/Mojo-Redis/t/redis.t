use Mojo::Base -strict;
use Test::More;
use Mojo::Redis;

my $redis = Mojo::Redis->new;
like $redis->protocol_class, qr{Protocol::Redis},      'connection_class';
is $redis->max_connections,  5,                        'max_connections';
is $redis->url,              'redis://localhost:6379', 'default url';

$redis = Mojo::Redis->new('redis://redis.localhost', max_connections => 1);
is $redis->url, 'redis://redis.localhost', 'custom url';
is $redis->max_connections, 1, 'custom max_connections';

$redis = Mojo::Redis->new(Mojo::URL->new('redis://redis.example.com'));
is $redis->url, 'redis://redis.example.com', 'custom url object';

$redis = Mojo::Redis->new({max_connections => 3});
is $redis->max_connections, 3, 'constructor with hash ref';

$redis = Mojo::Redis->new(max_connections => 2);
is $redis->max_connections, 2, 'constructor with list';

$ENV{MOJO_REDIS_URL} = 'redis://redis.env.localhost';
$redis = Mojo::Redis->new;
is $redis->url, 'redis://redis.env.localhost', 'custom default url';

done_testing;
