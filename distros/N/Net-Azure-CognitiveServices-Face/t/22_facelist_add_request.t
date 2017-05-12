use strict;
use warnings;
use Test::More;
use Net::Azure::CognitiveServices::Face;

Net::Azure::CognitiveServices::Face->access_key('MYSECRET');
my $facelist = Net::Azure::CognitiveServices::Face->FaceList;
isa_ok $facelist, 'Net::Azure::CognitiveServices::Face::FaceList';
can_ok $facelist, qw/_add_request/;

my $req = $facelist->_add_request('my_facelist', 'http://example.com/hoge.jpg', userData => 'Oreore');
isa_ok $req, 'HTTP::Request';
is $req->uri, 'https://api.projectoxford.ai/face/v1.0/facelists/my_facelist/persistedFaces?userData=Oreore';
is $req->method, 'POST';
is $req->header('Content-Type'), 'application/json';
is $req->header('Ocp-Apim-Subscription-Key'), 'MYSECRET';
is $req->content, '{"url":"http://example.com/hoge.jpg"}';

done_testing;