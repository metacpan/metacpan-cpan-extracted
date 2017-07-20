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
#   GSI "team_id-create_time-index":
#     Partition key: team_id (String)
#     Sort key: create_time (Number)

my $table_name = $ENV{TEST_DYNAMODB_TABLE}
    || die "please set TEST_DYNAMODB_TABLE";

my $dynamodb = PawsX::DynamoDB::DocumentClient->new();

my $team_id = create_uuid_as_string();

my $user_id1 = create_uuid_as_string();
my $create_time1 = 1499982965;
my $item1 = {
    user_id => $user_id1,
    email => 'jdoe@example.com',
    team_id => $team_id,
    create_time => $create_time1,
};

my $user_id2 = create_uuid_as_string();
my $create_time2 = $create_time1 + 1;
my $item2 = {
    user_id => $user_id2,
    email => 'bsmith@example.com',
    team_id => $team_id,
    create_time => $create_time2,
};

my $user_id3 = create_uuid_as_string();
my $create_time3 = $create_time2 + 1;
my $item3 = {
    user_id => $user_id3,
    email => 'hjohnson@example.com',
    team_id => $team_id,
    create_time => $create_time3,
};

$dynamodb->batch_write(
    RequestItems => {
        $table_name => [
            { PutRequest => { Item => $item1 } },
            { PutRequest => { Item => $item2 } },
            { PutRequest => { Item => $item3 } },
        ],
    },
);

my %base_query_args = (
    TableName => $table_name,
    IndexName => 'team_id-create_time-index',
    ExpressionAttributeValues => {
        ':team_id' => $team_id,
    },
    KeyConditionExpression => 'team_id = :team_id',
    ScanIndexForward => 1,
);

my $result1;
is(
    exception {
        $result1 = $dynamodb->query(
            %base_query_args,
            Limit => 2,
        );
    },
    undef,
    'query() lives',
);

cmp_deeply(
    $result1,
    {
        count => 2,
        items => [$item1, $item2],
        last_evaluated_key => {
            user_id => $user_id2,
            team_id => $team_id,
            create_time => $create_time2,
        }
    },
    'first result looks good'
);

my $result2;
is(
    exception {
        $result2 = $dynamodb->query(
            %base_query_args,
            ExclusiveStartKey => $result1->{last_evaluated_key},
        );
    },
    undef,
    'query() lives',
);

cmp_deeply(
    $result2,
    {
        count => 1,
        items => [$item3],
    },
    'second result looks good'
);

my $result3;
is(
    exception {
        $result3 = $dynamodb->query(
            %base_query_args,
            Select => 'COUNT',
        );
    },
    undef,
    'query() lives',
);

cmp_deeply(
    $result3,
    {
        count => 3,
        items => [],
    },
    'count result looks good'
);

done_testing;
