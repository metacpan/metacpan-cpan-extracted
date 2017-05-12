use Test::Most;

use Paws::Kinesis::MemoryCaller;

is(
    ref(Paws::Kinesis::MemoryCaller->new_kinesis()),
    "Paws::Kinesis",
    "created new Paws::Kinesis",
);

done_testing;
