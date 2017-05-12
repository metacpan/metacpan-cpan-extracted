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
    skip $@, 2 if $@;

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
    my $delete_res = $dynamo->delete_item({
        "Key" => {
            "id" => {
                "S" => "99999999",
            }
        },
        "TableName" => $table
    });

    ok $delete_res;
    my $get_res = $dynamo->get_item({
        "Key" => {
            id => {
                "S" => "99999999",
            }
        },
        "TableName" => $table
    });
    is $get_res, undef;
    $dynamo->delete_table({TableName => $table});
}


done_testing;
