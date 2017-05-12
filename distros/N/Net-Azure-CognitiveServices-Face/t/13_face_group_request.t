use strict;
use warnings;
use Test::More;
use Net::Azure::CognitiveServices::Face;

Net::Azure::CognitiveServices::Face->access_key('MYSECRET');
my $face = Net::Azure::CognitiveServices::Face->Face;
isa_ok $face, 'Net::Azure::CognitiveServices::Face::Face';
can_ok $face, qw/_group_request/;

my $req = $face->_group_request(
    faceIds => [qw[
        foobar
        hogefuga
        piyopoo
    ]],
);

isa_ok $req, 'HTTP::Request';
is $req->uri, 'https://api.projectoxford.ai/face/v1.0/group';
is $req->method, 'POST';
is $req->header('Content-Type'), 'application/json';
is $req->header('Ocp-Apim-Subscription-Key'), 'MYSECRET';
like $req->content, qr|"faceIds":\["foobar","hogefuga","piyopoo"\]|;

done_testing;