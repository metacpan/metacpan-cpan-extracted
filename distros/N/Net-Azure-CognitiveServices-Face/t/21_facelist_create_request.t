use strict;
use warnings;
use Test::More;
use Net::Azure::CognitiveServices::Face;

Net::Azure::CognitiveServices::Face->access_key('MYSECRET');
my $facelist = Net::Azure::CognitiveServices::Face->FaceList;
isa_ok $facelist, 'Net::Azure::CognitiveServices::Face::FaceList';
can_ok $facelist, qw/_create_request/;

my $req = $facelist->_create_request('my_facelist', name => "My Face List");
isa_ok $req, 'HTTP::Request';
is $req->uri, 'https://westus.api.cognitive.microsoft.com/face/v1.0/facelists/my_facelist';
is $req->method, 'PUT';
is $req->header('Content-Type'), 'application/json';
is $req->header('Ocp-Apim-Subscription-Key'), 'MYSECRET';
like $req->content, qr|"name":"My Face List"|;
like $req->content, qr|"userData":"my_facelist"|;

done_testing;