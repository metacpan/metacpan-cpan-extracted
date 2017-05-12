use strict;
use warnings;

use Test::More;
use RocksDB;
use File::Temp;

my $name = File::Temp::tmpnam;
my $filter_called;
{
    package TestCompactionFilter;
    sub new { bless {}, shift }
    sub filter {
        my ($self, $level, $key, $value, $new_value_ref) = @_;
        $filter_called++;
        $$new_value_ref = 'foo';
        return 0;
    }
}
my $filter = RocksDB::CompactionFilter->new(TestCompactionFilter->new);
isa_ok $filter , 'RocksDB::CompactionFilter';

my $db = RocksDB->new($name, {
    create_if_missing => 1,
    compaction_filter => $filter,
});
$db->put(foo => 'bar');
$db->flush;
$db->put(bar => 'baz');
$db->delete('foo');
$db->flush;
$db->compact_range;
ok $filter_called;
is $db->get('bar'), 'foo';

done_testing;

END {
    RocksDB->destroy_db($name);
}
