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
    skip $@, 3 if $@;

    my $create_res = $dynamo->create_table({
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
    ok $create_res;
    $dynamo->put_item({
        "Item" => {
            "id" => {
                "S" => "11111",
            },
            "last_update" => {
                "S" => "2015-04-01 10:24:00",
            }
        },
        "TableName" => $table
    });
    $dynamo->put_item({
        "Item" => {
            "id" => {
                "S" => "22222",
            },
            "last_update" => {
                "S" => "2015-04-02 10:24:00",
            }
        },
        "TableName" => $table
    });
    $dynamo->put_item({
        "Item" => {
            "id" => {
                "S" => "33333",
            },
            "last_update" => {
                "S" => "2015-03-30 10:24:00",
            }
        },
        "TableName" => $table
    });
    my $res = $dynamo->query({
        "KeyConditions" => {
            "id" => {
                "AttributeValueList" => [
                    {
                        "S" => "22222",
                    }
                ],
                "ComparisonOperator" => "EQ"
            }
        },
        "TableName" => $table
    });
    is $res->[0]->{id}, '22222';
    $dynamo->delete_table({TableName => $table});
}

done_testing;
