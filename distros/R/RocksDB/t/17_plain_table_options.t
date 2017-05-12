use strict;
use warnings;

use Test::More;
use RocksDB;
use File::Temp;

my $name = File::Temp::tmpnam;
my $db = RocksDB->new($name, {
    create_if_missing => 1,
    allow_mmap_reads => 1,
    plain_table_options => {
        user_key_len       => 0,
        bloom_bits_per_key => 10,
        hash_table_ratio   => 0.75,
        index_sparseness   => 16,
        huge_page_tlb_size => 0,
        encoding_type      => 'plain',
        full_scan_mode     => 0,
        tore_index_in_file => 0,
    },
});
isa_ok $db, 'RocksDB';

$db->put('foo', 'bar');
is $db->get('foo'), 'bar';
done_testing;

END {
    RocksDB->destroy_db($name);
}
