use strict;
use warnings;
use Test::More;
use Net::Azure::CognitiveServices::Face;

Net::Azure::CognitiveServices::Face->access_key('MYSECRET');
my $person = Net::Azure::CognitiveServices::Face->Person;
isa_ok $person, 'Net::Azure::CognitiveServices::Face::Person';
can_ok $person, qw/_add_face_request/;

my $img = 'http://example.com/hoge.jpg';
my $req = $person->_add_face_request("machida_pm", "ytnobody", $img, 
    userData   => 'japan-perl',
    targetFace => '10,20,100,100', 
);
isa_ok $req, 'ARRAY';
like $req->[1], qr|^https://westus.api.cognitive.microsoft.com/face/v1.0/persongroups/machida_pm/persons/ytnobody/persistedFaces|;
like $req->[1], qr|userData=japan-perl|;
like $req->[1], qr|targetFace=10%2C20%2C100%2C100|;
is $req->[0], 'POST';
is $req->[2]{headers}{'Content-Type'}, 'application/json';
is $req->[2]{headers}{'Ocp-Apim-Subscription-Key'}, 'MYSECRET';
is $req->[2]{content}, '{"url":"http://example.com/hoge.jpg"}';

done_testing;