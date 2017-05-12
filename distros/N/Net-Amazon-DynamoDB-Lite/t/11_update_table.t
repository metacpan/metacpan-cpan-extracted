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
    my $put_res = $dynamo->put_item({
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
    ok $put_res;
    my $update_res = $dynamo->update_table(    {
        "ProvisionedThroughput" => {
            "ReadCapacityUnits" => 10,
            "WriteCapacityUnits" => 10,
        },
        "AttributeDefinitions" => [
            {
                "AttributeName" => "name",
                "AttributeType" => "S"
            }
        ],
        "TableName" => $table
    });
    ok $update_res;
    my $describe_res = $dynamo->describe_table({TableName => $table});
    delete $describe_res->{CreationDateTime};
    is_deeply $describe_res, {
        'AttributeDefinitions' => [
            {
                'AttributeType' => 'S',
                'AttributeName' => 'id'
            }
        ],
        'ItemCount' => 1,
        'TableStatus' => 'ACTIVE',
        'TableSizeBytes' => 40,
        'ProvisionedThroughput' => {
            'LastDecreaseDateTime' => '0',
            'ReadCapacityUnits' => 10,
            'NumberOfDecreasesToday' => 0,
            'LastIncreaseDateTime' => '0',
            'WriteCapacityUnits' => 10
        },
        'KeySchema' => [
            {
                'AttributeName' => 'id',
                'KeyType' => 'HASH'
            }
        ],
        'TableName' => $table,
    };
    $dynamo->delete_table({TableName => $table});
}


done_testing;
