#!perl

use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
    use_ok( 'Net::OAuth::Request' );
	use_ok( 'Net::OAuth::ProtectedResourceRequest' );
}

my $request = Net::OAuth::ProtectedResourceRequest->new(
        consumer_key => 'dpf43f3p2l4k3l03',
        consumer_secret => 'kd94hf93k423kf44',
        request_url => 'http://photos.example.net/photos',
        request_method => 'GET',
        signature_method => 'HMAC-SHA1',
        timestamp => '1191242096',
        nonce => 'kllo9940pd9333jh',
        token => 'nnch734d00sl2jdk',
        token_secret => 'pfkkdhi9sl3r4s00',
        extra_params => {
            file => 'vacation.jpg',
            size => 'original',
        }
);

$request->sign;

ok($request->verify);

my $header = $request->to_authorization_header('My Realm', ",\n    ");

is("$header\n",<<EOT);
OAuth realm="My Realm",
    oauth_consumer_key="dpf43f3p2l4k3l03",
    oauth_nonce="kllo9940pd9333jh",
    oauth_signature="tR3%2BTy81lMeYAr%2FFid0kMTYa%2FWM%3D",
    oauth_signature_method="HMAC-SHA1",
    oauth_timestamp="1191242096",
    oauth_token="nnch734d00sl2jdk",
    oauth_version="1.0"
EOT

my $parsed_req = $request->from_authorization_header(
    $header, 
    request_method => 'GET', 
    request_url => 'http://photos.example.net/photos',
    consumer_secret => 'kd94hf93k423kf44',
    token_secret => 'pfkkdhi9sl3r4s00',
    extra_params => {
        file => 'vacation.jpg',
        size => 'original',
    },
);

ok($parsed_req->verify);