use strict;
use warnings;
use Test::More;
use Net::Azure::CognitiveServices::Face;

Net::Azure::CognitiveServices::Face->access_key('MYSECRET');
my $facelist = Net::Azure::CognitiveServices::Face->FaceList;
isa_ok $facelist, 'Net::Azure::CognitiveServices::Face::FaceList';
can_ok $facelist, qw/_update_request/;

my $req = $facelist->_update_request('my_facelist', name => "My Face List");
isa_ok $req, 'ARRAY';
is $req->[1], 'https://westus.api.cognitive.microsoft.com/face/v1.0/facelists/my_facelist';
is $req->[0], 'PATCH';
is $req->[2]{headers}{'Content-Type'}, 'application/json';
is $req->[2]{headers}{'Ocp-Apim-Subscription-Key'}, 'MYSECRET';
like $req->[2]{content}, qr|"name":"My Face List"|;

done_testing;