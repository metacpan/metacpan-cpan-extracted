use strict;
use warnings;
use Test::More;
use Net::Azure::CognitiveServices::Face;

Net::Azure::CognitiveServices::Face->access_key('MYSECRET');
my $face = Net::Azure::CognitiveServices::Face->Face;
isa_ok $face, 'Net::Azure::CognitiveServices::Face::Face';
can_ok $face, qw/_find_similar_request/;

my $req = $face->_find_similar_request(
    faceId     => 'foobar',
    faceListId => 'my_facelist',
    mode       => 'matchPerson',
);

isa_ok $req, 'ARRAY';
is $req->[1], 'https://westus.api.cognitive.microsoft.com/face/v1.0/findsimilars';
is $req->[0], 'POST';
is $req->[2]{headers}{'Content-Type'}, 'application/json';
is $req->[2]{headers}{'Ocp-Apim-Subscription-Key'}, 'MYSECRET';
like $req->[2]{content}, qr|"faceId":"foobar"|;
like $req->[2]{content}, qr|"faceListId":"my_facelist"|;
like $req->[2]{content}, qr|"mode":"matchPerson"|;

done_testing;