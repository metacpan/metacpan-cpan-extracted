use strict;
use warnings;
use Test::More;
use Net::Azure::CognitiveServices::Face;

Net::Azure::CognitiveServices::Face->access_key('MYSECRET');
my $person = Net::Azure::CognitiveServices::Face->Person;
isa_ok $person, 'Net::Azure::CognitiveServices::Face::Person';
can_ok $person, qw/_list_request/;

my $req = $person->_list_request("machida_pm");

isa_ok $req, 'HTTP::Request';
is $req->uri, "https://westus.api.cognitive.microsoft.com/face/v1.0/persongroups/machida_pm/persons";
is $req->method, 'GET';
is $req->header('Content-Type'), 'application/json';
is $req->header('Ocp-Apim-Subscription-Key'), 'MYSECRET';

done_testing;