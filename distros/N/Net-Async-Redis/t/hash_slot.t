use strict;
use warnings;

use Test::More;

use Net::Async::Redis::Cluster;
subtest 'hash slot' => sub {
    is(Net::Async::Redis::Cluster->hash_slot_for_key('full_key'), 10135, 'full key hashes to CRC16(full_key)');
    is(Net::Async::Redis::Cluster->hash_slot_for_key('partial.{user}'), 5474, 'hash slot with prefix hashes to CRC16(user)');
    is(Net::Async::Redis::Cluster->hash_slot_for_key('partial.{}{user}'), 12062, 'hash slot with prefix hashes to full key');
    done_testing;
};

done_testing;


