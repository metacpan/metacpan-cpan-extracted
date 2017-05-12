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

$kinesis->CreateStream(StreamName => "my_stream", ShardCount => 2);

eq_or_diff($kinesis->caller->store, {
    my_stream => {
        'shardId-000000000000' => [],
        'shardId-000000000001' => [],
    },
}, "One stream exists, with two empty shards");

eq_or_diff(
    $kinesis->caller->shard_iterator__address, {},
    "no shard_iterators exist yet",
);

assert_put_record(data => "1st Message", expected_sequence_number => 1);

my $get_shard_iterator_output = $kinesis->GetShardIterator(
    ShardId => "shardId-000000000000",
    StreamName => "my_stream",
    ShardIteratorType => "LATEST",
);
is(
    ref($get_shard_iterator_output), "Paws::Kinesis::GetShardIteratorOutput",
    "got a Paws::Kinesis::GetShardIteratorOutput",
);

my $shard_iterator = $get_shard_iterator_output->ShardIterator;

eq_or_diff(
    $kinesis->caller->shard_iterator__address, {
        $shard_iterator => {
            shard_id => "shardId-000000000000",
            index => 1,
            stream_name => "my_stream",
        },
    },
    "a shard_iterator has been created ($shard_iterator)",
);

my $get_records_output = $kinesis->GetRecords(ShardIterator => $shard_iterator);
eq_or_diff(
    $get_records_output->Records,
    [],
    "no records found on shard_iterator",
);
ok $get_records_output->NextShardIterator, "got NextShardIterator";

assert_put_record(data => "2nd Message", expected_sequence_number => 2);
assert_put_record(data => "3rd Message", expected_sequence_number => 3);

$get_records_output = $kinesis->GetRecords(
    ShardIterator => $get_records_output->NextShardIterator,
);
is(scalar @{$get_records_output->Records}, 2, "got two records");
eq_or_diff(
    [ map { decode_base64($_->Data) } @{$get_records_output->Records} ],
    [ "2nd Message", "3rd Message" ],
    "found the new messages on the shard_iterator",
);

$get_shard_iterator_output = $kinesis->GetShardIterator(
    ShardIteratorType => "TRIM_HORIZON",
    ShardId => "shardId-000000000000",
    StreamName => "my_stream",
);

ok(
    $get_shard_iterator_output->ShardIterator,
    "got a shard_iterator using TRIM_HORIZON",
);

$get_records_output = $kinesis->GetRecords(
    ShardIterator => $get_shard_iterator_output->ShardIterator,
);

is scalar @{$get_records_output->Records}, 3, "got 3 records using TRIM_HORIZON";

$get_shard_iterator_output = $kinesis->GetShardIterator(
    ShardIteratorType => "AT_SEQUENCE_NUMBER",
    StartingSequenceNumber => 3,
    ShardId => "shardId-000000000000",
    StreamName => "my_stream",
);

ok(
    $get_shard_iterator_output->ShardIterator,
    "got a shard_iterator using AT_SEQUENCE_NUMBER",
);

$get_records_output = $kinesis->GetRecords(
    ShardIterator => $get_shard_iterator_output->ShardIterator,
);

is(
    scalar @{$get_records_output->Records}, 1,
    "got 1 records using AT_SEQUENCE_NUMBER",
);

is(
    $get_records_output->Records->[0]->SequenceNumber, 3,
    "record has SequenceNumber 3",
);

is(
    decode_base64($get_records_output->Records->[0]->Data), "3rd Message",
    "record has correct data",
);

done_testing;

sub assert_put_record {
    my %args = @_;

    my $data = $args{data};
    my $expected_sequence_number = $args{expected_sequence_number};

    my $base64_data = encode_base64($data, "");

    my $put_record_output = $kinesis->PutRecord(
        Data => $base64_data,
        StreamName => "my_stream",
        PartitionKey => "my_partition_key",
    );

    is(
        ref($put_record_output), "Paws::Kinesis::PutRecordOutput",
        "got a Paws::Kinesis::PutRecordOutput",
    );

    is(
        $put_record_output->SequenceNumber, $expected_sequence_number,
        "Returned the expected SequenceNumber",
    );
}
