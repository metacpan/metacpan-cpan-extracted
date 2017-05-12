use strict;
use warnings;

use Test::More;
use RocksDB;
use File::Temp;

my $name = File::Temp::tmpnam;

my $filter = RocksDB::BloomFilterPolicy->new(10);
isa_ok $filter, 'RocksDB::BloomFilterPolicy';
isa_ok $filter, 'RocksDB::FilterPolicy';

my $db = RocksDB->new($name, {
    create_if_missing => 1,
    filter_policy     => $filter,
});
$db->put(foo => 'bar');
is $db->get('foo'), 'bar';

done_testing;

END {
    RocksDB->destroy_db($name);
}
