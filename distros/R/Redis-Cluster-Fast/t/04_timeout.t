use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t/lib';
use Test::Docker::RedisCluster qw/get_startup_nodes/;

use Redis::Cluster::Fast;

my $redis = Redis::Cluster::Fast->new(
    startup_nodes => get_startup_nodes,
    connect_timeout => 0.05,
    command_timeout => 0.05,
    max_retry_count => 3,
);

my $lua = <<EOF;
local tmp = KEYS[1]

redis.call("SET", tmp, "1")
redis.call("EXPIRE", tmp, ARGV[1])

for i = 0, ARGV[1] do
    local is_exist = redis.call("EXISTS", tmp)
    if is_exist == 0 then
        break;
    end
end

return {KEYS[1],ARGV[1],ARGV[2]}
EOF

eval {
    # sleep 1 sec
    $redis->eval($lua, 1, '{key}10', 1000000, 1);
};
like $@, qr/^\[eval\] Timeout/;

done_testing;
