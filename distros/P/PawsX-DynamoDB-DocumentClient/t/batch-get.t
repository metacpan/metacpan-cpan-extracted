use strict;
use warnings;
use Test::Fatal;
use Test::More;

use Paws::DynamoDB::BatchGetItemOutput;
use Paws::DynamoDB::BatchGetRequestMap;
use Paws::DynamoDB::BatchGetResponseMap;
use Paws::DynamoDB::KeysAndAttributes;
use PawsX::DynamoDB::DocumentClient::Util qw(make_attr_map make_key make_attr_name_map);

my $class;
BEGIN {
    $class = 'PawsX::DynamoDB::DocumentClient::BatchGet';
    use_ok($class);
}

is_deeply(
    {
        $class->transform_arguments(
            RequestItems => {
                'foo' => {
                    ConsistentRead => 1,
                    ProjectionExpression => 'foo_id, foo_name',
                    Keys => [
                        { foo_id => 'abcde' },
                        { foo_id => 'fghijk' },
                    ],
                },
                'bar' => {
                    Keys => [
                        { bar_id => 12345 },
                    ],
                },
            },
        )
    },
    {
        RequestItems => {
            'foo' => {
                ConsistentRead => 1,
                ProjectionExpression => 'foo_id, foo_name',
                Keys => [
                    { foo_id => { S => 'abcde' } },
                    { foo_id => { S => 'fghijk' } },
                ],
            },
            'bar' => {
                Keys => [
                    { bar_id => { N => 12345 } },
                ],
            },
        },
    },
    'transform_arguments() marshalls correct args',
);

my $test_output = Paws::DynamoDB::BatchGetItemOutput->new(
    Responses => Paws::DynamoDB::BatchGetResponseMap->new(
        Map => {
            'foo' => [
                make_attr_map({
                    foo_id => { S => 'abcde' },
                    foo_name => { S => 'Billy Joe' },
                }),
                make_attr_map({
                    foo_id => { S => 'fghij' },
                    foo_name => { S => 'Bobby Sue' },
                }),
            ],
            'bar' => [
                make_attr_map({
                    bar_id => { N => 10000 },
                    bar_closes => { S => 'Never' },
                }),
            ],
        },
    ),
    UnprocessedKeys => Paws::DynamoDB::BatchGetRequestMap->new(
        Map => {
            'bar' => Paws::DynamoDB::KeysAndAttributes->new(
                ConsistentRead => 1,
                ExpressionAttributeNames => make_attr_name_map({
                    '#P' => 'Percentile',
                }),
                ProjectionExpression => '#P, bar_id',
                Keys => [
                    make_key({ bar_id => { N => 12345 }}),
                    make_key({ bar_id => { N => 67890 }}),
                ],
            ),
            'baz' => Paws::DynamoDB::KeysAndAttributes->new(
                Keys => [
                    make_key({ baz_id => { N => 0 }}),
                ],
            ),
        },
    ),
);

is_deeply(
    $class->transform_output($test_output),
    {
        responses => {
            foo => [
                {
                    foo_id => 'abcde',
                    foo_name => 'Billy Joe',
                },
                {
                    foo_id => 'fghij',
                    foo_name => 'Bobby Sue',
                },
            ],
            bar => [
                {
                    bar_id => 10000,
                    bar_closes => 'Never',
                },
            ],
        },
        unprocessed_keys => {
            bar => {
                ConsistentRead => 1,
                Keys => [
                    { bar_id => 12345 },
                    { bar_id => 67890 },
                ],
                ExpressionAttributeNames => {
                    '#P' => 'Percentile',
                },
                ProjectionExpression => '#P, bar_id',
            },
            baz => {
                Keys => [
                    { baz_id => 0 },
                ],
            },
        }
    },
    'output transformed correctly',
);

like(
    exception {
        $class->transform_arguments(
            RequestItems => 'asds',
        );
    },
    qr/\Qbatch_get(): RequestItems must be a hashref\E/,
    'error thrown on bad RequestItems',
);

like(
    exception {
        $class->transform_arguments(
            RequestItems => {
                'foo' => {
                },
            },
        );
    },
    qr/\Qbatch_get(): RequestItems entry must have Keys\E/,
    'error thrown on missing Keys',
);

like(
    exception {
        $class->transform_arguments(
            RequestItems => {
                'foo' => {
                    Keys => 'asdf',
                },
            },
        );
    },
    qr/\Qbatch_get(): Keys must be an arrayref\E/,
    'error thrown on bad Keys',
);

like(
    exception {
        $class->transform_arguments(
            RequestItems => {
                'foo' => {
                    Keys => [
                        'asdf',
                    ],
                },
            },
        );
    },
    qr/\Qbatch_get(): Keys entry must be a hashref\E/,
    'error thrown on bad Keys entry',
);

done_testing;
