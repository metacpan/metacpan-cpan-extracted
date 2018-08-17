use Mojo::Base -strict;
use Test::More;
use Mojo::Redis;

my $url   = Mojo::URL->new->host('/tmp/redis.sock');
my $redis = Mojo::Redis->new($url);
my $args;

Mojo::Util::monkey_patch('Mojo::IOLoop::Client', 'connect' => sub { $args = $_[1] });
is $redis->db->connection->url->host, '/tmp/redis.sock', 'host';
is $redis->db->connection->url->port, undef,             'port';

$redis->db->connection->_connect;
is_deeply $args, {path => '/tmp/redis.sock', timeout => 10}, 'connect args';

done_testing;
