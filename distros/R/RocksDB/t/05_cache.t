use strict;
use warnings;

use Test::More;
use RocksDB;
use File::Temp;

my $name = File::Temp::tmpnam;

my $cache = RocksDB::LRUCache->new(1024);
isa_ok $cache, 'RocksDB::LRUCache';
isa_ok $cache, 'RocksDB::Cache';

my $db = RocksDB->new($name, {
    create_if_missing => 1,
    block_cache       => $cache,
});
$db->put(foo => 'bar');
is $db->get('foo'), 'bar';

done_testing;

END {
    RocksDB->destroy_db($name);
}
