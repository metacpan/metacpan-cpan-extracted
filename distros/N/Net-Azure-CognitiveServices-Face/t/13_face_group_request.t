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

isa_ok $req, 'ARRAY';
is $req->[1], 'https://westus.api.cognitive.microsoft.com/face/v1.0/group';
is $req->[0], 'POST';
is $req->[2]{headers}{'Content-Type'}, 'application/json';
is $req->[2]{headers}{'Ocp-Apim-Subscription-Key'}, 'MYSECRET';
like $req->[2]{content}, qr|"faceIds":\["foobar","hogefuga","piyopoo"\]|;

done_testing;