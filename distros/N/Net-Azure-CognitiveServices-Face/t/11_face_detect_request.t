use strict;
use warnings;
use Test::More;
use Net::Azure::CognitiveServices::Face;

Net::Azure::CognitiveServices::Face->access_key('MYSECRET');
Net::Azure::CognitiveServices::Face->endpoint('https://eastus.api.cognitive.microsoft.com/face/v1.0');
my $face = Net::Azure::CognitiveServices::Face->Face;
isa_ok $face, 'Net::Azure::CognitiveServices::Face::Face';
can_ok $face, qw/_detect_request/;

my $img = 'http://example.com/hoge.jpg';
my $req = $face->_detect_request($img, returnFaceAttributes => ['age', 'gender']);
isa_ok $req, 'ARRAY';
like $req->[1], qr|^https://eastus.api.cognitive.microsoft.com/face/v1.0/detect|;
like $req->[1], qr|returnFaceId=true|;
like $req->[1], qr|returnFaceLandmarks=false|;
like $req->[1], qr|returnFaceAttributes=age%2Cgender|;
is $req->[0], 'POST';
is $req->[2]{headers}{'Content-Type'}, 'application/json';
is $req->[2]{headers}{'Ocp-Apim-Subscription-Key'}, 'MYSECRET';
is $req->[2]{content}, '{"url":"http://example.com/hoge.jpg"}';

done_testing;