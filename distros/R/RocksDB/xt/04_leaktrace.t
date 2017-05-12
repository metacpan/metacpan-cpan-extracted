use strict;
use Test::More;
use RocksDB;
use File::Temp;

eval 'use Test::LeakTrace 0.08';
plan skip_all => "Test::LeakTrace 0.08 required for testing leak trace" if $@;

plan tests => 1;

my $name = File::Temp::tmpnam;

{
    package MyComparator;
    sub new { bless {}, shift }
    sub compare {
        my ($self, $a, $b) = @_;
        $a cmp $b;
    }
}

{
    package MyCompactionFilter;
    sub new { bless {}, shift }
    sub filter {
        my ($self, $level, $key, $value, $new_value_ref) = @_;
        $$new_value_ref = "hogehoge";
    }
}

no_leaks_ok(sub {
    my @values;
    my $cache = RocksDB::LRUCache->new(1024);
    my $cmp = RocksDB::Comparator->new(MyComparator->new);
    my $filter = RocksDB::CompactionFilter->new(MyCompactionFilter->new);
    my $db = RocksDB->new($name, {
        create_if_missing => 1,
        block_cache       => $cache,
        comparator        => $cmp,
        compaction_filter => $filter,
        enable_statistics => 1,
    });
    $db->put(foo => 'bar');
    push @values, $db->get('foo');
    push @values, $db->get_multi('foo', 'bar');
    push @values, $db->exists('foo');
    my $value;
    push @values, $db->key_may_exist('foo', \$value);
    my $snapshot = $db->get_snapshot;
    push @values, $db->get('foo', { snapshot => $snapshot });
    my $batch;
    $db->update(sub { $batch = shift });
    my $iter = $db->new_iterator;
    $iter->seek_to_first;
    push @values, $iter->key;
    push @values, $iter->value;
    $db->flush;
    $db->compact_range;
    push @values, $db->get_sorted_wal_files;
    push @values, $db->get_live_files_meta_data;
    push @values, $db->get_statistics;
    push @values, $db->get_db_identity;
    push @values, RocksDB->major_version;
    push @values, RocksDB->minor_version;

    push @values, $db->get_name;
});

RocksDB->destroy_db($name);
