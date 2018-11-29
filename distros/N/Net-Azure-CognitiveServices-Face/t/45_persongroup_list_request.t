use strict;
use warnings;
use Test::More;
use Net::Azure::CognitiveServices::Face;

Net::Azure::CognitiveServices::Face->access_key('MYSECRET');
my $pg = Net::Azure::CognitiveServices::Face->PersonGroup;
isa_ok $pg, 'Net::Azure::CognitiveServices::Face::PersonGroup';
can_ok $pg, qw/_list_request/;

my $req = $pg->_list_request(start => 10, top => 5);

isa_ok $req, 'ARRAY';
like $req->[1], qr|^https://westus.api.cognitive.microsoft.com/face/v1.0/persongroups|;
like $req->[1], qr|start=10|;
like $req->[1], qr|top=5|;
is $req->[0], 'GET';
is $req->[2]{headers}{'Content-Type'}, 'application/json';
is $req->[2]{headers}{'Ocp-Apim-Subscription-Key'}, 'MYSECRET';

done_testing;