use strict;
use warnings;

use Test::More;
use RocksDB;
use File::Temp;

my $name = File::Temp::tmpnam;

my $db = RocksDB->new($name, {
    create_if_missing => 1,
    enable_statistics => 1,
});
$db->get('foo');
$db->put('bar', 'baz');
my $stats = $db->get_statistics;
isa_ok $stats, 'RocksDB::Statistics';
ok defined $stats->get_ticker_count('rocksdb.block.cache.miss');
ok !defined $stats->get_ticker_count('hogehoge');
ok defined $stats->histogram_data('rocksdb.write.raw.block.micros');
ok !defined $stats->histogram_data('foobar');
ok $stats->to_string;
my $hashref = $stats->to_hashref;
ok $hashref;
is ref($hashref), 'HASH';

done_testing;

END {
    RocksDB->destroy_db($name);
}
