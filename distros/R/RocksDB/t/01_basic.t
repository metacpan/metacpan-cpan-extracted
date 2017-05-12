use strict;
use warnings;

use Test::More;
use RocksDB;
use File::Temp;
use File::Path 'remove_tree';

my $name = File::Temp::tmpnam;

my $db = RocksDB->new($name, { create_if_missing => 1 });
isa_ok $db, 'RocksDB';

$db->put(foo => 'bar');
is $db->get('foo'), 'bar';
ok $db->exists("foo");

my $value;
ok $db->key_may_exist('foo', \$value);
is $value, 'bar';

$db->put("nu\0ll", "bar\0baz");
is $db->get("nu\0ll"), "bar\0baz", 'contains null';
ok $db->exists("nu\0ll");
is_deeply $db->get_multi('foo', "nu\0ll"), { foo => 'bar', "nu\0ll" => "bar\0baz" };

$db->delete('foo');
$db->delete("nu\0ll");
is $db->get('foo'), undef;
ok !$db->exists('foo');
is $db->get("nu\0ll"), undef;
ok !$db->exists("nu\0ll");
is_deeply $db->get_multi('foo', "nu\0ll"), { foo => undef, "nu\0ll" => undef };

$db->put_multi({
    foo => 'baz',
    "nu\0ll" => "foo\0bar",
});
is_deeply $db->get_multi('foo', "nu\0ll"), { foo => 'baz', "nu\0ll" => "foo\0bar" };

$db->flush;
undef $db;
RocksDB->destroy_db($name);

$db = RocksDB->new($name, { create_if_missing => 1 });
$db->put(foo => 'bar');
$db->put(bar => 'baz');

ok defined $db->get_approximate_size('a', 'z');

ok !defined $db->compact_range;
ok !defined $db->compact_range('a');
ok !defined $db->compact_range(undef, 'a');
ok !defined $db->compact_range('a', 'z');

ok defined $db->get_property('rocksdb.stats');
ok defined $db->get_property('rocksdb.num-files-at-level0');
ok defined $db->get_property('rocksdb.sstables');
ok !defined $db->get_property('hogehoge');

ok defined $db->number_levels;
ok defined $db->max_mem_compaction_level;
ok defined $db->level0_stop_write_trigger;
is $db->get_name, $name;
ok !defined $db->disable_file_deletions;
ok !defined $db->enable_file_deletions;
ok defined $db->get_latest_sequence_number;
ok $db->get_db_identity;

undef $db;

ok defined RocksDB->major_version;
ok defined RocksDB->minor_version;

RocksDB->repair_db($name);
RocksDB->destroy_db($name);
remove_tree $name;

done_testing;
