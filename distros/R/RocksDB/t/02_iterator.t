use strict;
use warnings;

use Test::More;
use RocksDB;
use File::Temp;

my $name = File::Temp::tmpnam;

my $db = RocksDB->new($name, { create_if_missing => 1 });
$db->put(foo => 'bar');
$db->put(bar => 'baz');
$db->put(baz => 'foo');

my $iter = $db->new_iterator;
isa_ok $iter, 'RocksDB::Iterator';
$iter->seek_to_first;
ok $iter->valid;
is $iter->key, 'bar';
is $iter->value, 'baz';
$iter->next;
ok $iter->valid;
is $iter->key, 'baz';
is $iter->value, 'foo';
$iter->next;
ok $iter->valid;
is $iter->key, 'foo';
is $iter->value, 'bar';
$iter->next;
ok !$iter->valid;

$iter->seek_to_first;
$iter->seek_to_last;
ok $iter->valid;
is $iter->key, 'foo';
is $iter->value, 'bar';

$iter->seek('baz');
ok $iter->valid;
is $iter->key, 'baz';
is $iter->value, 'foo';

$iter->seek_to_first;
my $i = 0;
while (my ($key, $value) = $iter->each) {
    if ($i == 0) {
        is $key, 'bar';
        is $value, 'baz';
    } elsif ($i == 1) {
        is $key, 'baz';
        is $value, 'foo';
    } elsif ($i == 2) {
        is $key, 'foo';
        is $value, 'bar';
    } else {
        die "BUG: key: $key, value: $value";
    }
    $i++;
}

$iter->seek_to_last;
$i = 0;
while (my ($key, $value) = $iter->reverse_each) {
    if ($i == 0) {
        is $key, 'foo';
        is $value, 'bar';
    } elsif ($i == 1) {
        is $key, 'baz';
        is $value, 'foo';
    } elsif ($i == 2) {
        is $key, 'bar';
        is $value, 'baz';
    } else {
        die "BUG: key: $key, value: $value";
    }
    $i++;
}

done_testing;

END {
    RocksDB->destroy_db($name);
}
