use strict;
use warnings;
use Test::Fatal;
use Test::More;

use Paws::DynamoDB::UpdateItemOutput;
use PawsX::DynamoDB::DocumentClient::Util qw(make_attr_map);

my $class;
BEGIN {
    $class = 'PawsX::DynamoDB::DocumentClient::Update';
    use_ok($class);
}

is_deeply(
    {
        $class->transform_arguments(
            TabelName => 'users',
            ExpressionAttributeValues => {
                ':update_time' => 1499872950,
            },
            Key => {
                user_id => 100,
            },
            UpdateExpression => 'SET update_time = :update_time',
        )
    },
    {
        TabelName => 'users',
        ExpressionAttributeValues => {
            ':update_time' => { N => 1499872950 },
        },
        Key => {
            user_id => { N => 100 },
        },
        UpdateExpression => 'SET update_time = :update_time',
    },
    'transform_arguments() marshalls correct args',
);

my $test_output = Paws::DynamoDB::UpdateItemOutput->new();
is(
    $class->transform_output($test_output),
    undef,
    'nothing returned by default',
);

$test_output = Paws::DynamoDB::UpdateItemOutput->new(
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
    qr/\Qupdate(): ExpressionAttributeValues must be a hashref\E/,
    'error thrown on bad ExpressionAttributeValues',
);

like(
    exception {
        $class->transform_arguments(
            Key => 'asdf',
        );
    },
    qr/\Qupdate(): Key must be a hashref\E/,
    'error thrown on bad Key',
);


done_testing;
