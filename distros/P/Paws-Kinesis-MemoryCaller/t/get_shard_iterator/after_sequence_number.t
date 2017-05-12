use Test::Most;

use Paws;
use Paws::Credential::Environment;
use Paws::Kinesis::MemoryCaller;

use MIME::Base64 qw(decode_base64 encode_base64);

my $kinesis = Paws->service('Kinesis',
    region      => 'N/A',
    credentials => Paws::Credential::Environment->new(),
    caller      => Paws::Kinesis::MemoryCaller->new(),
);

$kinesis->CreateStream(StreamName => "my_stream", ShardCount => 1);

my $describe_stream_output = $kinesis->DescribeStream(
    StreamName => "my_stream",
);

my $shard_id = $describe_stream_output->StreamDescription->Shards->[0]->ShardId;

my $record_request_entries = [
    map {
        +{
            Data => encode_base64("Message #$_", ""),
            PartitionKey => "olympics",
        };
    }
    1..6
];

$kinesis->PutRecords(
    Records => $record_request_entries,
    StreamName => "my_stream",
);

my $shard_iterator = $kinesis->GetShardIterator(
    ShardId                 => $shard_id,
    ShardIteratorType       => "AFTER_SEQUENCE_NUMBER",
    StreamName              => "my_stream",
    StartingSequenceNumber  => "4",
)->ShardIterator;
ok ($shard_iterator, "got a new shard_iterator ($shard_iterator)");

my $get_records_output = $kinesis->GetRecords(ShardIterator => $shard_iterator);
my $next_shard_iterator = $get_records_output->NextShardIterator;
my $records = $get_records_output->Records;

ok($next_shard_iterator, "got a new shard_iterator ($next_shard_iterator)");

is scalar @$records, 2, 'got two records';

$record_request_entries = [
    map {
        +{
            Data => encode_base64("Message #$_", ""),
            PartitionKey => "olympics",
        };
    }
    7..8
];

$kinesis->PutRecords(
    Records => $record_request_entries,
    StreamName => "my_stream",
);

$get_records_output = $kinesis->GetRecords(ShardIterator => $shard_iterator);
$next_shard_iterator = $get_records_output->NextShardIterator;
$records = $get_records_output->Records;

ok($next_shard_iterator, "got a new shard_iterator ($next_shard_iterator)");
is scalar @$records, 4, 'got four records';
is decode_base64($records->[0]->Data), "Message #5", "got correct data";
is decode_base64($records->[1]->Data), "Message #6", "got correct data";

done_testing;
