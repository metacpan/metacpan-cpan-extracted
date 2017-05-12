use strict;
use warnings;
use Test::More;
use ShardedKV;
use ShardedKV::Continuum::CHash;

use lib qw(t/lib);
use ShardedKV::Test::CHash;

subtest "memory storage" => sub {
  extension_test_by_one_server_chash(sub {ShardedKV::Storage::Memory->new()}, 'memory');
  extension_test_by_multiple_servers_chash(sub {ShardedKV::Storage::Memory->new()}, 'memory');
};

done_testing();

