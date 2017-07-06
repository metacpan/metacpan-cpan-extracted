use strict;
use warnings;
use Test::More;
use Net::Azure::CognitiveServices::Face;

Net::Azure::CognitiveServices::Face->access_key('MYSECRET');
my $facelist = Net::Azure::CognitiveServices::Face->FaceList;
isa_ok $facelist, 'Net::Azure::CognitiveServices::Face::FaceList';
can_ok $facelist, qw/_delete_request/;

my $req = $facelist->_delete_request('my_facelist', 'foobar');
isa_ok $req, 'HTTP::Request';
is $req->uri, 'https://westus.api.cognitive.microsoft.com/face/v1.0/facelists/my_facelist/persistedFaces/foobar';
is $req->method, 'DELETE';
is $req->header('Content-Type'), 'application/json';
is $req->header('Ocp-Apim-Subscription-Key'), 'MYSECRET';

done_testing;