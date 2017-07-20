use strict;
use warnings;
use Test::Fatal;
use Test::More;

use Paws::DynamoDB::ScanOutput;
use PawsX::DynamoDB::DocumentClient::Util qw(make_attr_map make_key);

my $class;
BEGIN {
    $class = 'PawsX::DynamoDB::DocumentClient::Scan';
    use_ok($class);
}

is_deeply(
    {
        $class->transform_arguments(
            ExclusiveStartKey => {
                user_id => 1000,
            },
            ExpressionAttributeValues => {
                ':year' => 2017,
            },
            FilterExpression => 'year = :year',
            TableName => 'signups',
        )
    },
    {
        ExclusiveStartKey => {
            user_id => { N => 1000 },
        },
        ExpressionAttributeValues => {
            ':year' => { N => 2017 },
        },
        FilterExpression => 'year = :year',
        TableName => 'signups',
    },
    'transform_arguments() marshalls correct args',
);

my $test_output = Paws::DynamoDB::ScanOutput->new(
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
    $class->transform_output($test_output),
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
    'output transformed correctly',
);

like(
    exception {
        $class->transform_arguments(
            ExpressionAttributeValues => 'asdf',
        );
    },
    qr/\Qscan(): ExpressionAttributeValues must be a hashref\E/,
    'error thrown on bad ExpressionAttributeValues',
);

like(
    exception {
        $class->transform_arguments(
            ExclusiveStartKey => 'asdf',
        );
    },
    qr/\Qscan(): ExclusiveStartKey must be a hashref\E/,
    'error thrown on bad ExclusiveStartKey',
);

done_testing;
