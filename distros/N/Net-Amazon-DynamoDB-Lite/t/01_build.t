use strict;
use Test::More 0.98;
use Net::Amazon::DynamoDB::Lite;
use POSIX qw(strftime);

my $dynamo = Net::Amazon::DynamoDB::Lite->new(
    region     => 'ap-northeast-1',
    access_key => 'XXXXXXXXXXXXXXXXX',
    secret_key => 'YYYYYYYYYYYYYYYYY',
);

my $time = strftime('%Y%m%d', gmtime);
is $dynamo->scope, "$time/ap-northeast-1/dynamodb/aws4_request";
is ref $dynamo->signature, 'WebService::Amazon::Signature::v4';
is $dynamo->uri, "https://dynamodb.ap-northeast-1.amazonaws.com/";

done_testing;
