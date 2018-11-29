use strict;
use warnings;
use Test::More;
use Net::Azure::CognitiveServices::Face;

Net::Azure::CognitiveServices::Face->access_key('MYSECRET');
my $pg = Net::Azure::CognitiveServices::Face->PersonGroup;
isa_ok $pg, 'Net::Azure::CognitiveServices::Face::PersonGroup';
can_ok $pg, qw/_update_request/;

my $req = $pg->_update_request('machida_pm', name => "ooimachiPM");

isa_ok $req, 'ARRAY';
is $req->[1], "https://westus.api.cognitive.microsoft.com/face/v1.0/persongroups/machida_pm";
is $req->[0], 'PATCH';
is $req->[2]{headers}{'Content-Type'}, 'application/json';
is $req->[2]{headers}{'Ocp-Apim-Subscription-Key'}, 'MYSECRET';
is $req->[2]{content}, '{"name":"ooimachiPM"}';

done_testing;