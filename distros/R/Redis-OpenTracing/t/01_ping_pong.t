use Test::Most;

use strict;
use warnings;

use lib 't/lib';

use Test::RedisServer::Client;

my $redis = Test::RedisServer::Client->connect( )
    or plan skip_all => 'Can not run test with true Redis';

is $redis->ping, 'PONG', 'ping pong ok';

done_testing;
