use Test::Most;

use MIME::Base64 qw(decode_base64 encode_base64);
use Paws::Kinesis::MemoryCaller;

my $kinesis = Paws::Kinesis::MemoryCaller->new_kinesis();

$kinesis->CreateStream(
    ShardCount => 1,
    StreamName => "my_stream",
);

$kinesis->PutRecords(
    StreamName => "my_stream",
    Records => [
        map {
            +{
                PartitionKey => "abc",
                Data => encode_base64("Message $_", ""),
            };
        }
        1..6
    ],
);

my $shard_iterator = $kinesis->GetShardIterator(
    ShardId => "shardId-000000000000",
    ShardIteratorType => "TRIM_HORIZON",
    StreamName => "my_stream",
)->ShardIterator;

my $get_records_output = $kinesis->GetRecords(
    Limit => 2,
    ShardIterator => $shard_iterator,
);

eq_or_diff(
    [ map { decode_base64($_->Data) } @{$get_records_output->Records} ],
    [ "Message 1", "Message 2" ],
    "correct records with ShardIterator + Limit = 2",
);

$shard_iterator = $get_records_output->NextShardIterator;

$get_records_output = $kinesis->GetRecords(
    Limit => 3,
    ShardIterator => $shard_iterator,
);

eq_or_diff(
    [ map { decode_base64($_->Data) } @{$get_records_output->Records} ],
    [ "Message 3", "Message 4", "Message 5" ],
    "correct records with NextShardIterator + Limit = 3",
);

$shard_iterator = $get_records_output->NextShardIterator;

$get_records_output = $kinesis->GetRecords(
    ShardIterator => $shard_iterator,
);

eq_or_diff(
    [ map { decode_base64($_->Data) } @{$get_records_output->Records} ],
    [ "Message 6" ],
    "correct records with NextShardIterator + no Limit",
);

$shard_iterator = $get_records_output->NextShardIterator;

$get_records_output = $kinesis->GetRecords(
    ShardIterator => $shard_iterator,
    Limit => 5,
);

eq_or_diff(
    $get_records_output->Records, [],
    "no records returned despite the limit",
);

$kinesis->PutRecords(
    StreamName => "my_stream",
    Records => [
        {
            PartitionKey => "abc",
            Data => encode_base64("Message 7", ""),
        },
    ],
);

$shard_iterator = $get_records_output->NextShardIterator;

$get_records_output = $kinesis->GetRecords(
    ShardIterator => $shard_iterator,
);

eq_or_diff(
    [ map { decode_base64($_->Data) } @{$get_records_output->Records} ],
    [ "Message 7" ],
    "correct records with NextShardIterator + no Limit",
);

done_testing;
