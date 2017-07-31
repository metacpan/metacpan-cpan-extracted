use strict;
use warnings;
use Test::Fatal;
use Test::More;

use Paws::DynamoDB::QueryOutput;
use PawsX::DynamoDB::DocumentClient::Util qw(make_attr_map make_key);

my $class;
BEGIN {
    $class = 'PawsX::DynamoDB::DocumentClient::Query';
    use_ok($class);
}

is_deeply(
    {
        $class->transform_arguments(
            ConsistentRead => 1,
            ExclusiveStartKey => {
                classname => 'english',
                Percentile => .60,
            },
            ExpressionAttributeNames => {
                '#P' => 'Percentile',
            },
            ExpressionAttributeValues => {
                ':classname' => 'english',
                ':min_percentile' => .5,
                ':max_percentile' => .75,
                ':year' => 2017,
            },
            FilterExpression => 'year = :year',
            KeyConditionExpression => 'classname = :classname AND #p BETWEEN :min_percentile AND :max_percentile',
            Limit => 10,
            ProjectionExpression => 'student_id, percentile',
            ReturnConsumedCapacity => 'NONE',
            ScanIndexForward => 1,
            Select => 'SPECIFIC_ATTRIBUTES',
            TableName => 'roster',
        )
    },
    {
        ConsistentRead => 1,
        ExclusiveStartKey => {
            classname => { S => 'english' },
            Percentile => { N => .60 },
        },
        ExpressionAttributeNames => {
            '#P' => 'Percentile',
        },
        ExpressionAttributeValues => {
            ':classname' => { S => 'english' },
            ':min_percentile' => { N => .5 },
            ':max_percentile' => { N => .75 },
            ':year' => { N => 2017 },
        },
        FilterExpression => 'year = :year',
        KeyConditionExpression => 'classname = :classname AND #p BETWEEN :min_percentile AND :max_percentile',
        Limit => 10,
        ProjectionExpression => 'student_id, percentile',
        ReturnConsumedCapacity => 'NONE',
        ScanIndexForward => 1,
        Select => 'SPECIFIC_ATTRIBUTES',
        TableName => 'roster',
    },
    'transform_arguments() marshalls correct args',
);

is_deeply(
    {
        $class->transform_arguments(
            ExpressionAttributeValues => {
                ':username' => '1234',
            },
            ExclusiveStartKey => {
                username => '1000',
            },
            TableName => 'users',
            force_type => {
                ':username' => 'S',
                username => 'S',
            },
        )
    },
    {
        ExpressionAttributeValues => {
            ':username' => { S => '1234' },
        },
        ExclusiveStartKey => {
            username => { S => '1000' },
        },
        TableName => 'users',
    },
    'transform_arguments() handles force_type',
);

my $test_output1 = Paws::DynamoDB::QueryOutput->new(
    Count => 2,
    Items => [
        make_attr_map({
            user_id => { N => 100 },
            username => { S => 'foobar' },
        }),
        make_attr_map({
            user_id => { N => 101 },
            username => { S => 'bazbaz' },
        }),
    ],
    LastEvaluatedKey => make_key({}),
);

is_deeply(
    $class->transform_output($test_output1),
    {
        count => 2,
        items => [
            {
                user_id => 100,
                username => 'foobar',
            },
            {
                user_id => 101,
                username => 'bazbaz',
            },
        ],
    },
    'items built correctly from output',
);

my $test_output2 = Paws::DynamoDB::QueryOutput->new(
    Count => 2,
    Items => [
        make_attr_map({
            user_id => { N => 100 },
            username => { S => 'foobar' },
        }),
        make_attr_map({
            user_id => { N => 101 },
            username => { S => 'bazbaz' },
        }),
    ],
    LastEvaluatedKey => make_key({
        user_id => { N => 101 },
    }),
);

is_deeply(
    $class->transform_output($test_output2),
    {
        count => 2,
        items => [
            {
                user_id => 100,
                username => 'foobar',
            },
            {
                user_id => 101,
                username => 'bazbaz',
            },
        ],
        last_evaluated_key => {
            user_id => 101,
        },
    },
    'last_evaluated_key correctly built from output',
);

my $test_output3 = Paws::DynamoDB::QueryOutput->new(
    Count => 4,
);

is_deeply(
    $class->transform_output($test_output3),
    {
        count => 4,
        items => [],
    },
    'count-only output handled correctly',
);

like(
    exception {
        $class->transform_arguments(
            ExpressionAttributeValues => 'asdf',
        );
    },
    qr/\Qquery(): ExpressionAttributeValues must be a hashref\E/,
    'error thrown on bad ExpressionAttributeValues',
);

like(
    exception {
        $class->transform_arguments(
            ExclusiveStartKey => 'asdf',
        );
    },
    qr/\Qquery(): ExclusiveStartKey must be a hashref\E/,
    'error thrown on bad ExclusiveStartKey',
);

done_testing;
