use strict;
use warnings;
use Test::More;
use Net::Azure::CognitiveServices::Face;

Net::Azure::CognitiveServices::Face->access_key('MYSECRET');
my $person = Net::Azure::CognitiveServices::Face->Person;
isa_ok $person, 'Net::Azure::CognitiveServices::Face::Person';
can_ok $person, qw/_create_request/;

my $req = $person->_create_request("machida_pm", 
    name     => 'ytnobody',
    userData => 'japan-perl',
);
isa_ok $req, 'HTTP::Request';
is $req->uri, "https://api.projectoxford.ai/face/v1.0/persongroups/machida_pm/persons";
is $req->method, 'POST';
is $req->header('Content-Type'), 'application/json';
is $req->header('Ocp-Apim-Subscription-Key'), 'MYSECRET';
like $req->content, qr|"userData":"japan-perl"|;
like $req->content, qr|"name":"ytnobody"|;

done_testing;