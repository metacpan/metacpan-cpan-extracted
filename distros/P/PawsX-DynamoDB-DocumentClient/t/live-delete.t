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

$dynamodb->put(
    TableName => $table_name,
    Item => $item1,
);

$dynamodb->put(
    TableName => $table_name,
    Item => $item2,
);

my $fetch_item1 = sub {
    return $dynamodb->get(
        TableName => $table_name,
        Key => { user_id => $user_id1 },
        ConsistentRead => 1,
    );
};

ok($fetch_item1->(), 'item exists beforehand');

my $output;
is(
    exception {
        $output = $dynamodb->delete(
            TableName => $table_name,
            Key => { user_id => $user_id1 },
        );
    },
    undef,
    'delete() lives',
);
is($output, undef, 'no output by default');

ok(!$fetch_item1->(), 'item is deleted');

is(
    exception {
        $output = $dynamodb->delete(
            TableName => $table_name,
            Key => { user_id => $user_id2 },
            ReturnValues => 'ALL_OLD',
        );
    },
    undef,
    'delete() lives',
);

is_deeply($output, $item2, 'item returned when called with ALL_OLD');

is(
    exception {
        $output = $dynamodb->delete(
            TableName => $table_name,
            Key => { user_id => $user_id2 },
            ReturnValues => 'ALL_OLD',
        );
    },
    undef,
    'delete() lives when called for deleted item',
);

is($output, undef, 'no item returned when called with ALL_OLD, but item does not exist');

done_testing;
