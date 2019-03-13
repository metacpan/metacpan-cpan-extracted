use strict;
use warnings;
use Test::More;
use Protocol::Redis::Test;

protocol_redis_ok 'Protocol::Redis::Faster', 1;

done_testing;
