use strict;
use warnings;

use Test::More;
use Net::HTTP::Spore;
use JSON;

my $api = {
    "name"    => "Test API",
    "methods" => {
        "get_test_required_params" => {
            "required_params" => ["user"],
            "path"            => "/test",
            "method"          => "GET"
        },
        "get_test_token_params" => {
            "path"   => "/another_test/:otherparam",
            "method" => "GET"
        }
    },
    base_url => 'http://localhost:12345'
};


my $mock_server = {
    '/test' => sub {
        my $req = shift;
        like $req->env->{'QUERY_STRING'}, qr'user=toto',
          'and our parameters are correctly set';
        $req->new_response( 200, [ 'Content-Type' => 'text/plain' ], 'ok' );
    },
    '/another_test/titi' => sub {
        my $req = shift;
        ok $req, 'and we managed to reach the parametrized URL';
        $req->new_response( 200, [ 'Content-Type' => 'text/plain' ], 'ok' );
    },
    '/another_test/tata' => sub {
        my $req = shift;
        ok $req, 'and we managed to reach a non default parametrized URL';
        $req->new_response( 200, [ 'Content-Type' => 'text/plain' ], 'ok' );
    },
};

ok my $client = Net::HTTP::Spore->new_from_string( JSON::encode_json($api) ),
  'client created';
$client->enable(
    'DefaultParams',
    default_params => { user => 'toto', otherparam => 'titi' }
);
$client->enable( 'Mock', tests => $mock_server );
my $res = $client->get_test_required_params();
is $res->body, 'ok', 'and we get a response when passing default URL paramters';
$res = $client->get_test_token_params();
is $res->body, 'ok', 'and we get a response from the mock server';
$res = $client->get_test_token_params(otherparam => 'tata');
is $res->body, 'ok', 'and we get a response from the mock server';
done_testing();

