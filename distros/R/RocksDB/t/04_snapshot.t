use strict;
use warnings;

use Test::More tests => 3;
use RocksDB;
use File::Temp;

my $name = File::Temp::tmpnam;

my $db = RocksDB->new($name, { create_if_missing => 1 });
$db->put(foo => 'bar');
my $snapshot = $db->get_snapshot;
isa_ok $snapshot, 'RocksDB::Snapshot';
$db->put(foo => 'baz');
is $db->get('foo', { snapshot => $snapshot }), 'bar';

my $iter = $db->new_iterator({ snapshot => $snapshot });
$iter->seek_to_first;
is $iter->key, 'foo';

done_testing;

END {
    RocksDB->destroy_db($name);
}
