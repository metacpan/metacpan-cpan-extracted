use strict;
use warnings;
use Test::Fatal;
use Test::More;

use aliased 'Paws::DynamoDB::BatchWriteItemOutput';
use aliased 'Paws::DynamoDB::BatchWriteItemRequestMap';
use aliased 'Paws::DynamoDB::PutItemInputAttributeMap';
use aliased 'Paws::DynamoDB::WriteRequest';
use aliased 'Paws::DynamoDB::PutRequest';
use aliased 'Paws::DynamoDB::DeleteRequest';
use PawsX::DynamoDB::DocumentClient::Util qw(make_attr_map make_key);

my $class;
BEGIN {
    $class = 'PawsX::DynamoDB::DocumentClient::BatchWrite';
    use_ok($class);
}

sub make_put_request {
    my ($attrs) = @_;
    my $attr_map = make_attr_map($attrs);
    my $put_attr_map = PutItemInputAttributeMap->new(Map => $attr_map->Map);
    return WriteRequest->new(
        PutRequest => PutRequest->new(
            Item => $put_attr_map,
        ),
    );
}

sub make_delete_request {
    my ($key) = @_;
    return WriteRequest->new(
        DeleteRequest => DeleteRequest->new(
            Key => make_key($key),
        ),
    );
}

is_deeply(
    {
        $class->transform_arguments(
            RequestItems => {
                'friends' => [
                    {
                        PutRequest => {
                            Item => { user_id => 100, friend_id => 101 },
                        },
                    },
                    {
                        PutRequest => {
                            Item => { user_id => 100, friend_id => 102 },
                        },
                    },
                    {
                        DeleteRequest => {
                            Key => { user_id => 100, friend_id => 200 },
                        },
                    },
                ],
                'user' => [
                    {
                        PutRequest => {
                            Item => { user_id => 101, name => 'Johnny' },
                        },
                    },
                ],
            },
            ReturnConsumedCapacity => 'NONE',
        ),
    },
    {
        RequestItems => {
            'friends' => [
                {
                    PutRequest => {
                        Item => {
                            user_id => { N => 100 },
                            friend_id => { N => 101 },
                        },
                    },
                },
                {
                    PutRequest => {
                        Item => {
                            user_id => { N => 100 },
                            friend_id => { N => 102 },
                        },
                    },
                },
                {
                    DeleteRequest => {
                        Key => {
                            user_id => { N => 100 },
                            friend_id => { N => 200 },
                        },
                    },
                },
            ],
            'user' => [
                {
                    PutRequest => {
                        Item => {
                            user_id => { N => 101 },
                            name => { S => 'Johnny' },
                        },
                    },
                },
            ],
        },
        ReturnConsumedCapacity => 'NONE',
    },
    'transform_arguments() marshalls correct args',
);

my $test_output = BatchWriteItemOutput->new(
    UnprocessedItems => BatchWriteItemRequestMap->new(
        Map => {
            'friends' => [
                make_put_request({
                    user_id => { N => 100 },
                    friend_id => { N => 102 },
                }),
                make_put_request({
                    user_id => { N => 100 },
                    friend_id => { N => 103 },
                }),
            ],
            'user' => [
                make_delete_request({
                    user_id => { N => 100 },
                }),
            ],
        },
    ),
);

is_deeply(
    $class->transform_output($test_output),
    {
        'friends' => [
            {
                PutRequest => {
                    Item => { user_id => 100, friend_id => 102 },
                },
            }, {
                PutRequest => {
                    Item => { user_id => 100, friend_id => 103 },
                },
            },
        ],
        'user' => [
            {
                DeleteRequest => {
                    Key => { user_id => 100 },
                },
            },
        ],
    },
    'unprocessed items returned',
);

like(
    exception {
        $class->transform_arguments(
            RequestItems => 'asdf',
        );
    },
    qr/\Qbatch_write(): RequestItems must be a hashref\E/,
    'error thrown on bad RequestItems',
);

like(
    exception {
        $class->transform_arguments(
            RequestItems => {
                foo => 'asdf',
            },
        );
    },
    qr/\Qbatch_write(): RequestItems value must be an arrayref\E/,
    'error thrown on bad RequestItems value',
);

like(
    exception {
        $class->transform_arguments(
            RequestItems => {
                foo => [
                    'asdfasdf',
                ],
            },
        );
    },
    qr/\Qbatch_write(): write request must be a hashref\E/,
    'error thrown on bad write request',
);

like(
    exception {
        $class->transform_arguments(
            RequestItems => {
                foo => [
                    {
                        bar => 'asdf',
                    },
                ],
            },
        );
    },
    qr/\Qbatch_write(): write request missing PutRequest or DeleteRequest\E/,
    'error thrown on bad write request',
);

like(
    exception {
        $class->transform_arguments(
            RequestItems => {
                foo => [
                    {
                        PutRequest => 'asdf'
                    },
                ],
            },
        );
    },
    qr/\Qbatch_write(): PutRequest must be a hashref\E/,
    'error thrown on bad PutRequest',
);

like(
    exception {
        $class->transform_arguments(
            RequestItems => {
                foo => [
                    {
                        PutRequest => { foo => 'bar '},
                    },
                ],
            },
        );
    },
    qr/\Qbatch_write(): PutRequest must contain Item\E/,
    'error thrown on bad PutRequest',
);

like(
    exception {
        $class->transform_arguments(
            RequestItems => {
                foo => [
                    {
                        PutRequest => {
                            Item => 'bar',
                        },
                    },
                ],
            },
        );
    },
    qr/\Qbatch_write(): PutRequest's Item must be a hashref\E/,
    'error thrown on bad PutRequest Item',
);

like(
    exception {
        $class->transform_arguments(
            RequestItems => {
                foo => [
                    {
                        DeleteRequest => 'asdf'
                    },
                ],
            },
        );
    },
    qr/\Qbatch_write(): DeleteRequest must be a hashref\E/,
    'error thrown on bad DeleteRequest',
);

like(
    exception {
        $class->transform_arguments(
            RequestItems => {
                foo => [
                    {
                        DeleteRequest => { foo => 'bar '},
                    },
                ],
            },
        );
    },
    qr/\Qbatch_write(): DeleteRequest must contain Key\E/,
    'error thrown on bad DeleteRequest',
);

like(
    exception {
        $class->transform_arguments(
            RequestItems => {
                foo => [
                    {
                        DeleteRequest => {
                            Key => 'bar',
                        },
                    },
                ],
            },
        );
    },
    qr/\Qbatch_write(): DeleteRequest's Key must be a hashref\E/,
    'error thrown on bad DeleteRequest Key',
);

done_testing;
