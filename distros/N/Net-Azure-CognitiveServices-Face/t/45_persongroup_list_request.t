use strict;
use warnings;
use Test::More;
use Net::Azure::CognitiveServices::Face;

Net::Azure::CognitiveServices::Face->access_key('MYSECRET');
my $pg = Net::Azure::CognitiveServices::Face->PersonGroup;
isa_ok $pg, 'Net::Azure::CognitiveServices::Face::PersonGroup';
can_ok $pg, qw/_list_request/;

my $req = $pg->_list_request(start => 10, top => 5);

isa_ok $req, 'HTTP::Request';
like $req->uri, qr|^https://api.projectoxford.ai/face/v1.0/persongroups|;
like $req->uri, qr|start=10|;
like $req->uri, qr|top=5|;
is $req->method, 'GET';
is $req->header('Content-Type'), 'application/json';
is $req->header('Ocp-Apim-Subscription-Key'), 'MYSECRET';

done_testing;