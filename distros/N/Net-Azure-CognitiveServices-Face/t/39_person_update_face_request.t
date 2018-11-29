use strict;
use warnings;
use Test::More;
use Net::Azure::CognitiveServices::Face;

Net::Azure::CognitiveServices::Face->access_key('MYSECRET');
my $person = Net::Azure::CognitiveServices::Face->Person;
isa_ok $person, 'Net::Azure::CognitiveServices::Face::Person';
can_ok $person, qw/_update_face_request/;

my $req = $person->_update_face_request("machida_pm", "ytnobody", "ossan", userData => "PAUSE=YTURTLE");

isa_ok $req, 'ARRAY';
is $req->[1], "https://westus.api.cognitive.microsoft.com/face/v1.0/persongroups/machida_pm/persons/ytnobody/persistedFaces/ossan";
is $req->[0], 'PATCH';
is $req->[2]{headers}{'Content-Type'}, 'application/json';
is $req->[2]{headers}{'Ocp-Apim-Subscription-Key'}, 'MYSECRET';
is $req->[2]{content}, '{"userData":"PAUSE=YTURTLE"}';

done_testing;