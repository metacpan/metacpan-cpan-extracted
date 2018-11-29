use strict;
use warnings;
use Test::More;
use Net::Azure::CognitiveServices::Face;

Net::Azure::CognitiveServices::Face->access_key('MYSECRET');
my $pg = Net::Azure::CognitiveServices::Face->PersonGroup;
isa_ok $pg, 'Net::Azure::CognitiveServices::Face::PersonGroup';
can_ok $pg, qw/_create_request/;

my $req = $pg->_create_request("machida_pm", name => 'machida_pm', userData => "machiP");

isa_ok $req, 'ARRAY';
is $req->[1], "https://westus.api.cognitive.microsoft.com/face/v1.0/persongroups/machida_pm";
is $req->[0], 'PUT';
is $req->[2]{headers}{'Content-Type'}, 'application/json';
is $req->[2]{headers}{'Ocp-Apim-Subscription-Key'}, 'MYSECRET';
like $req->[2]{content}, qr|"name":"machida_pm"|;
like $req->[2]{content}, qr|"userData":"machiP"|;

done_testing;