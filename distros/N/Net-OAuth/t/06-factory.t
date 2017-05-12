use strict;
use warnings;
use Test::More tests => 12;

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

my $response = Net::OAuth->response('UserAuth')->new(
    token => 'abcdef',
    extra_params => {
            foo => 'bar',
    },
);

is($response->to_post_body, 'foo=bar&oauth_token=abcdef');

$response = Net::OAuth->response('user_auth')->new(
    token => 'abcdef',
    extra_params => {
            foo => 'bar',
    },
);

is($response->to_post_body, 'foo=bar&oauth_token=abcdef');

$response = Net::OAuth->message('user authentication response')->new(
    token => 'abcdef',
    extra_params => {
            foo => 'bar',
    },
);

is($response->to_post_body, 'foo=bar&oauth_token=abcdef');

$request = Net::OAuth->request('Request Token')->from_hash(
        {
			oauth_consumer_key => 'dpf43f3p2l4k3l03',
        	oauth_signature_method => 'PLAINTEXT',
        	oauth_timestamp => '1191242090',
        	oauth_nonce => 'hsu94j3884jdopsl',
        	oauth_version => '1.0',
		},
    	consumer_secret => 'kd94hf93k423kf44',
    	request_url => 'https://photos.example.net/request_token',
    	request_method => 'POST',
);

$request->sign;

ok($request->verify);

is($request->to_post_body, 'oauth_consumer_key=dpf43f3p2l4k3l03&oauth_nonce=hsu94j3884jdopsl&oauth_signature=kd94hf93k423kf44%26&oauth_signature_method=PLAINTEXT&oauth_timestamp=1191242090&oauth_version=1.0');

$request = Net::OAuth->request('Protected Resource')->from_hash(
	{
        oauth_consumer_key => 'dpf43f3p2l4k3l03',
        oauth_signature_method => 'HMAC-SHA1',
        oauth_timestamp => '1191242096',
        oauth_nonce => 'kllo9940pd9333jh',
        oauth_token => 'nnch734d00sl2jdk',
		oauth_signature => 'tR3+Ty81lMeYAr/Fid0kMTYa/WM=',
    	oauth_version => '1.0',
        file => 'vacation.jpg',
        size => 'original',
	},
    request_url => 'http://photos.example.net/photos',
    request_method => 'GET',
    token_secret => 'pfkkdhi9sl3r4s00',
    consumer_secret => 'kd94hf93k423kf44',
);

ok($request->verify);

is($request->signature_base_string, 'GET&http%3A%2F%2Fphotos.example.net%2Fphotos&file%3Dvacation.jpg%26oauth_consumer_key%3Ddpf43f3p2l4k3l03%26oauth_nonce%3Dkllo9940pd9333jh%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1191242096%26oauth_token%3Dnnch734d00sl2jdk%26oauth_version%3D1.0%26size%3Doriginal');

is($request->consumer_key, 'dpf43f3p2l4k3l03');

$request->consumer_key('foo');

is($request->consumer_key, 'foo');

is($request->signature_base_string, 'GET&http%3A%2F%2Fphotos.example.net%2Fphotos&file%3Dvacation.jpg%26oauth_consumer_key%3Dfoo%26oauth_nonce%3Dkllo9940pd9333jh%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1191242096%26oauth_token%3Dnnch734d00sl2jdk%26oauth_version%3D1.0%26size%3Doriginal');

eval {
    Net::OAuth->request('Foo Bar'); 
};

ok($@, 'should die');