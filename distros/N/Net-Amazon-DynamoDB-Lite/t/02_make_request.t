use strict;
use Test::More 0.98;
use Net::Amazon::DynamoDB::Lite;
use WebService::Amazon::Signature::v4;

my $dynamo = Net::Amazon::DynamoDB::Lite->new(
    region     => 'ap-northeast-1',
    access_key => 'XXXXXXXXXXXXXXXXX',
    secret_key => 'YYYYYYYYYYYYYYYYY',
);

my $req = $dynamo->make_request('ListTables', {Limit => 10});
is ref $req, 'HTTP::Request';
ok $req->header("Date");
ok $req->header("x-amz-date");
is $req->header("x-amz-target"), "DynamoDB_20120810.ListTables";
is $req->header("content-type"), "application/x-amz-json-1.0";
is $req->header("Content-Length"), length '{"Limit":10}';
like $req->header("Authorization"), qr#^AWS4-HMAC-SHA256 Credential=XXXXXXXXXXXXXXXXX/\d{8}/ap-northeast-1/dynamodb/aws4_request, SignedHeaders=content-length;content-type;date;host;x-amz-date;x-amz-target, Signature=.+$#;
is $req->content, '{"Limit":10}';

done_testing;


