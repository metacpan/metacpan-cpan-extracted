use strict;
use warnings;
use Test::Fatal;
use Test::More;

use Paws::DynamoDB::GetItemOutput;
use PawsX::DynamoDB::DocumentClient::Util qw(make_attr_map);

my $class;
BEGIN {
    $class = 'PawsX::DynamoDB::DocumentClient::Get';
    use_ok($class);
}

is_deeply(
    {
        $class->transform_arguments(
            Key => {
                user_id => '002da0b1-5607-44bd-9658-250e46d23db4',
                epoch => 1499884956,
            },
            TableName => 'users',
        )
    },
    {
        Key => {
            user_id => { S => '002da0b1-5607-44bd-9658-250e46d23db4' },
            epoch => { N => 1499884956 },
        },
        TableName => 'users',
    },
    'transform_arguments() marshalls correct args',
);

my $test_output = Paws::DynamoDB::GetItemOutput->new(
    Item => make_attr_map({
        user_id => { S => '002da0b1-5607-44bd-9658-250e46d23db4' },
        epoch => { N => '1499884956' },
        tags => {
            L => [
                {
                    S => 'admin',
                },
                {
                    S => 'user',
                },
            ],
        },
        relationships => {
            M => {
                father => { N => 30 },
                mother => { N => 31 },
            }
        }
    }),
);

is_deeply(
    $class->transform_output($test_output),
    {
        user_id => '002da0b1-5607-44bd-9658-250e46d23db4',
        epoch => 1499884956,
        tags => [ 'admin', 'user' ],
        relationships => {
            father => 30,
            mother => 31,
        },
    },
    'unmarshalled item returned by default',
);

like(
    exception {
        $class->transform_arguments(
            Key => 'foobar',
        );
    },
    qr/\Qget(): Key must be a hashref\E/,
    'error thrown on bad Key',
);

done_testing;
