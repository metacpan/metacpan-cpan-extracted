use Test::DescribeMe qw(author);
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
my $item1 = {
    user_id => $user_id1,
    email => 'jdoe@example.com',
};

my $user_id2 = create_uuid_as_string();
my $item2 = {
    user_id => $user_id2,
    email => 'bsmith@example.com',
};

my $user_id3 = create_uuid_as_string();
my $item3 = {
    user_id => $user_id3,
    email => 'hjohnson@example.com',
};

$dynamodb->put(
    TableName => $table_name,
    Item => $item1,
);

my $fetch_user = sub {
    my ($user_id) = @_;
    $dynamodb->get(
        TableName => $table_name,
        Key => { user_id => $user_id },
        ConsistentRead => 1,
    ),
};

ok(
    $fetch_user->($user_id1),
    'user1 exists before batch_write',
);

ok(
    !$fetch_user->($user_id2),
    'user2 does not exist before batch_write',
);

ok(
    !$fetch_user->($user_id3),
    'user3 does not exist before batch_write',
);

my $output;
is(
    exception {
        $output = $dynamodb->batch_write(
            RequestItems => {
                $table_name => [
                    { PutRequest => { Item => $item2 } },
                    { PutRequest => { Item => $item3 } },
                    { DeleteRequest => { Key => { user_id => $user_id1 } } },
                ],
            },
        );
    },
    undef,
    'batch_write() lives',
);

is($output, undef, 'no output by default (no unprocessed items)');

ok(
    !$fetch_user->($user_id1),
    'user1 deleted by batch_write',
);

ok(
    $fetch_user->($user_id2),
    'user2 created by batch_write',
);

ok(
    $fetch_user->($user_id3),
    'user3 created by batch_write',
);

done_testing;
