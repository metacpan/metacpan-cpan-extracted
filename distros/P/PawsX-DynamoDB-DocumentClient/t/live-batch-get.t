use Test::DescribeMe qw(author);
use Test::Deep;
use Test::Fatal;
use Test::More;
use strict;
use warnings;

use PawsX::DynamoDB::DocumentClient;
use UUID::Tiny ':std';

# Expected table:
#   Partition key: user_id (String)

my $table_name = $ENV{TEST_DYNAMODB_TABLE}
    || die "please set TEST_DYNAMODB_TABLE";

my $dynamodb = PawsX::DynamoDB::DocumentClient->new();

my $user_id1 = create_uuid_as_string();
my $user_id2 = create_uuid_as_string();
my $user_id3 = create_uuid_as_string();

my $item1 = {
    user_id => $user_id1,
    email => 'jdoe@example.com',
};
my $item2 = {
    user_id => $user_id2,
    email => '@example.com',
};
my $item3 = {
    user_id => $user_id3,
    email => 'hjohnson@example.com',
};

$dynamodb->put(
    TableName => $table_name,
    Item => $item1,
);
$dynamodb->put(
    TableName => $table_name,
    Item => $item2,
);
$dynamodb->put(
    TableName => $table_name,
    Item => $item3,
);

my %args = (
    RequestItems => {
        $table_name => {
            ConsistentRead => 1,
            Keys => [
                { user_id => $user_id1 },
                { user_id => $user_id3 },
            ],
        },
    },
);

my $output;
is(
    exception {
        $output = $dynamodb->batch_get(%args);
    },
    undef,
    'batch_get() lives',
);

cmp_deeply(
    $output,
    {
        responses => {
            $table_name => set($item1, $item3),
        },
        unprocessed_keys => undef,
    },
    'items correctly fetched'
);

my %args2 = (
    RequestItems => {
        $table_name => {
            ConsistentRead => 1,
            Keys => [
                { user_id => create_uuid_as_string() },
            ],
        },
    },
);

is(
    exception {
        $output = $dynamodb->batch_get(%args2);
    },
    undef,
    'batch_get() lives on miss',
);

cmp_deeply(
    $output,
    {
        responses => {
            $table_name => [],
        },
        unprocessed_keys => undef,
    },
    'response looks OK on miss'
);

done_testing;
