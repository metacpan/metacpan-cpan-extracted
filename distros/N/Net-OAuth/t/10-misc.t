use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
    use Net::OAuth;
    $Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0;
}

my $request = Net::OAuth->request('user auth')->new(
    token => 'abcdef',
    callback => 'http://example.com/callback',
    extra_params => {
            foo => 'bar',
    },
);

is($request->to_post_body, 'foo=bar&oauth_callback=http%3A%2F%2Fexample.com%2Fcallback&oauth_token=abcdef');

use URI;
my $url = URI->new('http://example.com?bar=baz');
is($request->to_url($url), 'http://example.com?foo=bar&oauth_callback=http%3A%2F%2Fexample.com%2Fcallback&oauth_token=abcdef');
is($url, 'http://example.com?bar=baz');

$request = Net::OAuth->request('Request Token')->new(
		consumer_key => 'dpf43f3p2l4k3l03',
        signature_method => 'PLAINTEXT',
        timestamp => '1191242090',
        nonce => 'hsu94j3884jdopsl',
    	consumer_secret => 'kd94hf93k423kf44',
    	request_url => 'https://photos.example.net/request_token',
    	request_method => 'GET',
    	extra_params => {
    	    foo => 'this value contains spaces'
    	},
);

$request->sign;

is($request->to_url(), 'https://photos.example.net/request_token?foo=this%20value%20contains%20spaces&oauth_consumer_key=dpf43f3p2l4k3l03&oauth_nonce=hsu94j3884jdopsl&oauth_signature=kd94hf93k423kf44%26&oauth_signature_method=PLAINTEXT&oauth_timestamp=1191242090&oauth_version=1.0');


# https://rt.cpan.org/Ticket/Display.html?id=47369
# Make sure signature works without oauth_version
$request = Net::OAuth->request('request_token')->from_hash(
  {
      "oauth_signature" => "lcdJGdH4NRntuelnX+pAoxtIcLY=",
      "oauth_timestamp" => "1246037243",
      "oauth_nonce" => "288f21",
      "oauth_consumer_key" => "myKey",
      "oauth_signature_method" => "HMAC-SHA1"  
  },
  consumer_secret => 'mySecret',
  request_method => 'POST',
  request_url => 'http://localhost/provider/request-token.cgi',
);

ok($request->verify);