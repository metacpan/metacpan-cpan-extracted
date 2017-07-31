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

my $table_name = $ENV{TEST_DYNAMODB_TABLE}
    || die "please set TEST_DYNAMODB_TABLE";

my $dynamodb = PawsX::DynamoDB::DocumentClient->new();

my $team_id_str = create_uuid_as_string();
my $team_id_num = int(rand(100000));

my $user_id1 = create_uuid_as_string();
my $create_time1 = 1499982965;
my $item1 = {
    user_id => $user_id1,
    email => 'jdoe@example.com',
    team_id => $team_id_str,
    create_time => $create_time1,
};

my $user_id2 = create_uuid_as_string();
my $create_time2 = $create_time1 + 1;
my $item2 = {
    user_id => $user_id2,
    email => 'bsmith@example.com',
    team_id => $team_id_num,
    create_time => $create_time2,
};

like(
    exception {
        $dynamodb->batch_write(
            RequestItems => {
                $table_name => [
                    { PutRequest => { Item => $item1 } },
                    { PutRequest => { Item => $item2 } },
                ],
            },
        );
    },
    qr/Type mismatch for Index Key team_id/,
    'type mismatch error thrown on batch_write() if force_type not specified',
);

is(
    exception {
        $dynamodb->batch_write(
            RequestItems => {
                $table_name => [
                    { PutRequest => { Item => $item1 } },
                    { PutRequest => { Item => $item2 } },
                ],
            },
            force_type => {
                $table_name => {
                    team_id => 'S',
                },
            },
        );
    },
    undef,
    'batch_write() lives when force_type specified',
);

my $query_args = sub {
    my ($team_id) = @_;
    return {
        TableName => $table_name,
        IndexName => 'team_id-create_time-index',
        KeyConditionExpression => 'team_id = :team_id',
        ExpressionAttributeValues => {
            ':team_id' => $team_id,
        },
    };
};

my $result1;
is(
    exception {
        $result1 = $dynamodb->query(
            %{ $query_args->($team_id_str) }
        );
    },
    undef,
    'query() lives with no force_type if id is a string',
);

cmp_deeply(
    $result1,
    {
        count => 1,
        items => [$item1],
    },
    'first result looks good'
);

my $result2;
like(
    exception {
        $result2 = $dynamodb->query(
            %{ $query_args->($team_id_num) }
        );
    },
    qr/Condition parameter type does not match schema type/,
    'query() throws error with no force_type if id is a num',
);

is(
    exception {
        $result2 = $dynamodb->query(
            %{ $query_args->($team_id_num) },
            force_type => {
                ':team_id' => 'S',
            },
        );
    },
    undef,
    'query() lives if id is a num, and force_type specified',
);

cmp_deeply(
    $result2,
    {
        count => 1,
        items => [$item2],
    },
    'second result looks good'
);

done_testing;
