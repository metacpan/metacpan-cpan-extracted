use strict;
use warnings;
use Test::More;
use ShardedKV;
use ShardedKV::Continuum::CHash;

use lib qw(t/lib);
use ShardedKV::Test::CHash;

subtest "memory storage" => sub {
  simple_test_one_server_chash();
  simple_test_multiple_servers_chash();
};

done_testing();
