use strict;
use warnings;

use Test::More;
use RocksDB;
use File::Temp;

my $name = File::Temp::tmpnam;
my $db = RocksDB->new($name, {
    create_if_missing => 1,
    cuckoo_table_options => {
        hash_table_ratio       => 0.9,
        max_search_depth       => 100,
        cuckoo_block_size      => 5,
        identity_as_first_hash => 0,
        use_module_hash        => 1,
    },
});
isa_ok $db, 'RocksDB';

$db->put('foo', 'bar');
is $db->get('foo'), 'bar';
done_testing;

END {
    RocksDB->destroy_db($name);
}
