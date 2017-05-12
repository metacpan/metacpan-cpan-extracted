use strict;
use Test::More 0.98;
use Time::Piece;
use Net::Amazon::DynamoDB::Lite;
use URI;

my $dynamo = Net::Amazon::DynamoDB::Lite->new(
    region     => 'ap-northeast-1',
    access_key => 'XXXXXXXXXXXXXXXXX',
    secret_key => 'YYYYYYYYYYYYYYYYY',
    uri => URI->new('http://localhost:8000'),
);

my $t = localtime;
my $table = 'test_' . $t->epoch;
SKIP: {
    eval {
        $dynamo->list_tables;
        };
    skip $@, 1 if $@;

    $dynamo->create_table({
        "AttributeDefinitions" => [
            {
                "AttributeName" => "id",
                "AttributeType" => "S",
            }
        ],
        "KeySchema" => [
            {
                "AttributeName" => "id",
                "KeyType" => "HASH"
            }
        ],
        "ProvisionedThroughput" => {
            "ReadCapacityUnits" => 5,
            "WriteCapacityUnits" => 5,
        },
        "TableName" => $table,
    });
    $dynamo->put_item({
        "Item" => {
            "id" => {
                "S" => "12345678",
            },
            "last_update" => {
                "S" => "2015-03-30 10:24:00",
            }
        },
        "TableName" => $table
    });
    $dynamo->put_item({
        "Item" => {
            "id" => {
                "S" => "99999999",
            },
            "last_update" => {
                "S" => "2015-03-31 10:24:00",
            }
        },
        "TableName" => $table
    });
    my $res = $dynamo->get_item({
        "Key" => {
            id => {
                "S" => "99999999",
            }
        },
        "TableName" => $table
    });
    is_deeply $res, {
        'last_update' => '2015-03-31 10:24:00',
        'id' => '99999999',
    };
    $dynamo->put_item({
        "Item" => {
            'id' => { S => "11111111" },
            'a'  => { N => "1"        },
            'b'  => { S => "pants"    },
            'c'  => { N => "23.5"     },
            'e'  => {
                'M' => {
                    'a' => { 'N' => "23.5"  },
                    'b' => { 'S' => "pants" },
                },
            },
            'f'  => {
                'L' => [
                    { 'S' => "pants" },
                    { 'N' => "23.5"  },
                ],
            },
            'g'  => { 'S' => "23" },
        },
        "TableName" => $table
    });
    my $res = $dynamo->get_item({
        "Key" => {
            id => {
                "S" => "11111111",
            }
        },
        "TableName" => $table
    });
    is_deeply $res, {
        'id' => '11111111',
        'a'  => 1,
        'b'  => "pants",
        'c'  => 23.5,
        'e'  => { a => 23.5, b => "pants" },
        'f'  => [ "pants", 23.5 ],
        'g'  => "23",
    };
    $dynamo->delete_table({TableName => $table});
}


done_testing;
