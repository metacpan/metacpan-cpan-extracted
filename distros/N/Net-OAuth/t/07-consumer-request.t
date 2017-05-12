#!perl

use strict;
use warnings;
use Test::More tests => 6;

BEGIN {
        use_ok( 'Net::OAuth' );
	use_ok( 'Net::OAuth::ConsumerRequest' );
}

my $request = Net::OAuth->request('consumer')->new(
        consumer_key => 'dpf43f3p2l4k3l03',
        consumer_secret => 'kd94hf93k423kf44',
        request_url => 'http://provider.example.net/profile',
        request_method => 'GET',
        signature_method => 'HMAC-SHA1',
        timestamp => '1191242096',
        nonce => 'kllo9940pd9333jh',
);

$request->sign;

ok($request->verify);

is($request->signature_base_string, 'GET&http%3A%2F%2Fprovider.example.net%2Fprofile&oauth_consumer_key%3Ddpf43f3p2l4k3l03%26oauth_nonce%3Dkllo9940pd9333jh%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1191242096%26oauth_version%3D1.0');

is($request->signature, 'SGtGiOrgTGF5Dd4RUMguopweOSU=');

is($request->to_authorization_header('http://provider.example.net/', ",\n")."\n", <<EOT);
OAuth realm="http://provider.example.net/",
oauth_consumer_key="dpf43f3p2l4k3l03",
oauth_nonce="kllo9940pd9333jh",
oauth_signature="SGtGiOrgTGF5Dd4RUMguopweOSU%3D",
oauth_signature_method="HMAC-SHA1",
oauth_timestamp="1191242096",
oauth_version="1.0"
EOT
