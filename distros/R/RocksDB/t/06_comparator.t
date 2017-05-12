use strict;
use warnings;

use Test::More;
use RocksDB;
use File::Temp;

my $name = File::Temp::tmpnam;
my $compare_called;
{
    package TestComparator;
    sub new { bless {}, shift }
    sub compare {
        my ($self, $a, $b) = @_;
        $compare_called++;
        $b cmp $a;
    }
}
my $comparator = RocksDB::Comparator->new(TestComparator->new);
isa_ok $comparator, 'RocksDB::Comparator';

my $db = RocksDB->new($name, {
    create_if_missing => 1,
    comparator        => $comparator,
});
$db->put(foo => 'bar');
$db->put(bar => 'baz');
my $iter = $db->new_iterator;
$iter->seek_to_first;
is $iter->key, 'foo';
$iter->next;
is $iter->key, 'bar';
ok $compare_called;

done_testing;

END {
    RocksDB->destroy_db($name);
}
