use strict;
use warnings;
use Test::More;
use Net::Azure::CognitiveServices::Face;

Net::Azure::CognitiveServices::Face->access_key('MYSECRET');
my $person = Net::Azure::CognitiveServices::Face->Person;
isa_ok $person, 'Net::Azure::CognitiveServices::Face::Person';
can_ok $person, qw/_update_face_request/;

my $req = $person->_update_face_request("machida_pm", "ytnobody", "ossan", userData => "PAUSE=YTURTLE");

isa_ok $req, 'HTTP::Request';
is $req->uri, "https://api.projectoxford.ai/face/v1.0/persongroups/machida_pm/persons/ytnobody/persistedFaces/ossan";
is $req->method, 'PATCH';
is $req->header('Content-Type'), 'application/json';
is $req->header('Ocp-Apim-Subscription-Key'), 'MYSECRET';
is $req->content, '{"userData":"PAUSE=YTURTLE"}';

done_testing;