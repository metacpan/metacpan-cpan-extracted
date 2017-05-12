use strict;
use warnings;

use Test::More;
use RocksDB;
use File::Temp;

my $name = File::Temp::tmpnam;

my $prefix = 'rocksdb:';
my $transform = RocksDB::FixedPrefixTransform->new(length($prefix));
isa_ok $transform, 'RocksDB::FixedPrefixTransform';
my $db = RocksDB->new($name, {
    create_if_missing => 1,
    prefix_extractor => $transform,
});
$db->put('foo', 'bar');
$db->put('rocksdb:foo', 'bar');
$db->put('rocksdb:bar', 'baz');
$db->put('bar','baz');
my $iter = $db->new_iterator;
$iter->seek($prefix);
ok $iter->valid;
is $iter->key, 'rocksdb:bar';
is $iter->value, 'baz';
$iter->next;
ok $iter->valid;
is $iter->key, 'rocksdb:foo';
is $iter->value, 'bar';
$iter->next;
ok !$iter->valid;

done_testing;

END {
    RocksDB->destroy_db($name);
}
