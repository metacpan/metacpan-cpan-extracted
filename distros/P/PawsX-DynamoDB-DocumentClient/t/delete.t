use strict;
use warnings;
use Test::Fatal;
use Test::More;

use Paws::DynamoDB::DeleteItemOutput;
use PawsX::DynamoDB::DocumentClient::Util qw(make_attr_map);

my $class;
BEGIN {
    $class = 'PawsX::DynamoDB::DocumentClient::Delete';
    use_ok($class);
}

is_deeply(
    {
        $class->transform_arguments(
            ConditionExpression => 'create_time < :min_create_time',
            ExpressionAttributeValues => {
                ':min_create_time' => 1499872950,
            },
            Key => {
                user_id => 25,
            },
            TableName => 'users',
        )
    },
    {
        ConditionExpression => 'create_time < :min_create_time',
        ExpressionAttributeValues => {
            ':min_create_time' => { N => 1499872950 },
        },
        Key => {
            user_id => { N => 25 },
        },
        TableName => 'users',
    },
    'transform_arguments() marshalls correct args',
);

my $test_output = Paws::DynamoDB::DeleteItemOutput->new();
is(
    $class->transform_output($test_output),
    undef,
    'nothing returned by default',
);

$test_output = Paws::DynamoDB::DeleteItemOutput->new(
    Attributes => make_attr_map({
        user_id => { S => '002da0b1-5607-44bd-9658-250e46d23db4' },
        epoch => { N => '1499884956' },
    }),
);

is_deeply(
    $class->transform_output($test_output),
    {
        user_id => '002da0b1-5607-44bd-9658-250e46d23db4',
        epoch => 1499884956,
    },
    'unmarshalled attributes returned if found in output',
);

like(
    exception {
        $class->transform_arguments(
            ExpressionAttributeValues => 'foobar',
        );
    },
    qr/\Qdelete(): ExpressionAttributeValues must be a hashref\E/,
    'error thrown on bad ExpressionAttributeValues',
);

like(
    exception {
        $class->transform_arguments(
            Key => 'foobar',
        );
    },
    qr/\Qdelete(): Key must be a hashref\E/,
    'error thrown on bad Key',
);

done_testing;
