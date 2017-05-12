use strict;
use warnings;

use Test::More;
use RocksDB;
use File::Temp;

my $name = File::Temp::tmpnam;

{
    package TestMergeOperator;
    sub new { bless {}, shift }
    sub merge {
        my ($self, $key, $existing_value, $value) = @_;
        ($existing_value || 0) + $value;
    }
}

my $merge_operator = RocksDB::AssociativeMergeOperator->new(TestMergeOperator->new);
my $db = RocksDB->new($name, {
    create_if_missing => 1,
    merge_operator    => $merge_operator,
    WAL_ttl_seconds   => 600,
});
$db->update(sub {
    my $batch = shift;
    $batch->put_log_data('hoge');
    $batch->put(foo => 'bar');
    $batch->put(bar => 1);
    $batch->merge(bar => 2);
    $batch->delete('foo');
});

my $iter = $db->get_updates_since(0);
isa_ok $iter, 'RocksDB::TransactionLogIterator';
ok $iter->valid;
my $result = $iter->get_batch;
isa_ok $result, 'RocksDB::BatchResult';
ok $result->sequence;
my $batch = $result->write_batch;
isa_ok $batch, 'RocksDB::WriteBatch';
is $batch->count, 4;
ok $batch->data;

{
    package TestWriteBatchHandler;
    use Test::More;
    sub new { bless {}, shift }
    sub put {
        my ($self, $key, $value) = @_;
        is $value, $key eq 'foo' ? 'bar' : 1;
    }
    sub merge {
        my ($self, $key, $value) = @_;
        is $key, 'bar';
        is $value, 2;
    }
    sub delete {
        my ($self, $key) = @_;
        is $key, 'foo';
    }

    sub log_data {
        my ($self, $blob) = @_;
        is $blob, 'hoge';
    }
    sub continue { 1 }
}
$batch->iterate(RocksDB::WriteBatchHandler->new(TestWriteBatchHandler->new));

$db->flush;
my @files = $db->get_sorted_wal_files;
ok scalar(@files);
my $file = $files[0];
is ref($file), 'HASH';
ok exists $file->{$_} for qw(log_number path_name size_file_bytes start_sequence type);

my @meta_data = $db->get_live_files_meta_data;
ok scalar(@meta_data);
my $data = $meta_data[0];
is ref($data), 'HASH';
ok exists $data->{$_} for qw(largest_seqno largestkey level name size smallest_seqno smallestkey);

my $repl_name = File::Temp::tmpnam;
my $repl = RocksDB->new($repl_name, {
    create_if_missing => 1,
    merge_operator    => $merge_operator,
});
$repl->write($batch);
is $repl->get('bar'), 3;

done_testing;

END {
    RocksDB->destroy_db($name);
    RocksDB->destroy_db($repl_name);
}
