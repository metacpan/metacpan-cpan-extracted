use strict;
use warnings;
use Test::More;

use JSON;
use HTTP::Response;

use Net::Riak::Bucket;
use Net::Riak;
use Net::Riak::Object;

my $client = Net::Riak->new()->client;
my $bucket = Net::Riak::Bucket->new(name => 'foo', client => $client);

ok my $object =
  Net::Riak::Object->new(key => 'bar', bucket => $bucket, client => $client),
  'object bar created';

my $response = HTTP::Response->new(400);
$client->http_response($response);

ok !$object->exists, 'object don\'t exists';

eval {
    $client->populate_object($object,  $response, [200]);
};

like $@, qr/Expected status 200, received: 400/, "can't populate with a 400";

my $value = {value => 1};

$response = HTTP::Response->new(200);
$client->http_response($response);
$response->content(JSON::encode_json($value));

$client->populate_object($object, $response, [200]);

ok $object->exists, 'object exists';

is_deeply $value, $object->data, 'got same data';

is $object->client->status, 200, 'last http code is 200';

done_testing;
