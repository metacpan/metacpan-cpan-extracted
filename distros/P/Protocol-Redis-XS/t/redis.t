use strict;
use warnings;
use Test::More tests => 2;
use Protocol::Redis::Test;

use_ok 'Protocol::Redis::XS';

# Test Protocol::Redis API
protocol_redis_ok 'Protocol::Redis::XS', 1;
