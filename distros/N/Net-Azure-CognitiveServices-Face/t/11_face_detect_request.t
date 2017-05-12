use strict;
use warnings;
use Test::More;
use Net::Azure::CognitiveServices::Face;

Net::Azure::CognitiveServices::Face->access_key('MYSECRET');
my $face = Net::Azure::CognitiveServices::Face->Face;
isa_ok $face, 'Net::Azure::CognitiveServices::Face::Face';
can_ok $face, qw/_detect_request/;

my $img = 'http://example.com/hoge.jpg';
my $req = $face->_detect_request($img, returnFaceAttributes => ['age', 'gender']);
isa_ok $req, 'HTTP::Request';
like $req->uri, qr|^https://api.projectoxford.ai/face/v1.0/detect|;
like $req->uri, qr|returnFaceId=true|;
like $req->uri, qr|returnFaceLandmarks=false|;
like $req->uri, qr|returnFaceAttributes=age%2Cgender|;
is $req->method, 'POST';
is $req->header('Content-Type'), 'application/json';
is $req->header('Ocp-Apim-Subscription-Key'), 'MYSECRET';
is $req->content, '{"url":"http://example.com/hoge.jpg"}';

done_testing;