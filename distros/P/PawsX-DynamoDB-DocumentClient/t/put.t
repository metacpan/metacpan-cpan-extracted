use strict;
use warnings;
use Test::Fatal;
use Test::More;

use Paws::DynamoDB::PutItemOutput;
use PawsX::DynamoDB::DocumentClient::Util qw(make_attr_map);

my $class;
BEGIN {
    $class = 'PawsX::DynamoDB::DocumentClient::Put';
    use_ok($class);
}

is_deeply(
    {
        $class->transform_arguments(
            ConditionExpression => 'create_time < :min_create_time',
            ExpressionAttributeValues => {
                ':min_create_time' => 1499872950,
            },
            Item => {
                user_id => 25,
                create_time => 1499872950,
                email => 'jdoe@example.com',
            },
            TableName => 'users',
        )
    },
    {
        ConditionExpression => 'create_time < :min_create_time',
        ExpressionAttributeValues => {
            ':min_create_time' => { N => 1499872950 },
        },
        Item => {
            user_id => { N => 25 },
            create_time => { N => 1499872950 },
            email => { S => 'jdoe@example.com' },
        },
        TableName => 'users',
    },
    'transform_arguments() marshalls correct args',
);

my $test_output = Paws::DynamoDB::PutItemOutput->new();
is(
    $class->transform_output($test_output),
    undef,
    'nothing returned by default',
);

$test_output = Paws::DynamoDB::PutItemOutput->new(
    Attributes => make_attr_map({
        user_id => { N => 100 },
        username => { S => 'foobar' },
    }),
);
is_deeply(
    $class->transform_output($test_output),
    {
        user_id => 100,
        username => 'foobar',
    },
    'Attributes unmarshalled and returned if present',
);

like(
    exception {
        $class->transform_arguments(
            ExpressionAttributeValues => 'asdf',
        );
    },
    qr/\Qput(): ExpressionAttributeValues must be a hashref\E/,
    'error thrown on bad ExpressionAttributeValues',
);

like(
    exception {
        $class->transform_arguments(
            Item => 'asdf',
        );
    },
    qr/\Qput(): Item must be a hashref\E/,
    'error thrown on bad Item',
);

done_testing;
