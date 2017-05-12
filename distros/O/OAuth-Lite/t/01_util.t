use Test::More tests => 24;

use OAuth::Lite;
use OAuth::Lite::Util;

my $random1 = OAuth::Lite::Util::gen_random_key();
is(length($random1), 20);
like($random1, qr/^[0-9a-zA-Z]{20}$/);

my $random2 = OAuth::Lite::Util::gen_random_key(10);
is(length($random2), 20);
like($random2, qr/^[0-9a-zA-Z]{20}$/);

my $random3 = OAuth::Lite::Util::gen_random_key(8);
is(length($random3), 16);
like($random3, qr/^[0-9a-zA-Z]{16}$/);

my $param = q{123 @#$%&hoge hoge+._-~};
my $encoded = OAuth::Lite::Util::encode_param($param);
is($encoded, q{123%20%40%23%24%25%26hoge%20hoge%2B._-~});
my $decoded = OAuth::Lite::Util::decode_param($encoded);
is($decoded, $param);


my $http_method = "GET";
my $request_url = "http://photos.example.net/photos";
my $params = {
	oauth_consumer_key     => 'dpf43f3p214k3103',
	oauth_token            => 'nnch734d00s12jdk',
	oauth_signature_method => 'HMAC-SHA1',
	oauth_timestamp        => '1191242096',
	oauth_nonce            => 'kllo9940pd9333jh',
	oauth_version          => '1.0',
	file                   => 'vacation.jpg',
	size                   => 'original',
};

my $base = OAuth::Lite::Util::create_signature_base_string($http_method, $request_url, $params);
is($base, q{GET&http%3A%2F%2Fphotos.example.net%2Fphotos&file%3Dvacation.jpg%26oauth_consumer_key%3Ddpf43f3p214k3103%26oauth_nonce%3Dkllo9940pd9333jh%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1191242096%26oauth_token%3Dnnch734d00s12jdk%26oauth_version%3D1.0%26size%3Doriginal});

delete $params->{file};
delete $params->{size};

my $head = sprintf(q{OAuth realm="http://example.com/realm"});
my $header = join(", ", $head, (map sprintf(q{%s="%s"}, $_, OAuth::Lite::Util::encode_param($params->{$_})), keys %$params));
my ($realm, $parsed) = OAuth::Lite::Util::parse_auth_header($header);
is($realm, 'http://example.com/realm');
is($parsed->{oauth_consumer_key},     'dpf43f3p214k3103');
is($parsed->{oauth_token},            'nnch734d00s12jdk');
is($parsed->{oauth_signature_method}, 'HMAC-SHA1');
is($parsed->{oauth_timestamp},        '1191242096');
is($parsed->{oauth_nonce},            'kllo9940pd9333jh');
is($parsed->{oauth_version},          '1.0');

my $params_include_array = {
	oauth_consumer_key     => 'dpf43f3p214k3103',
	oauth_token            => 'nnch734d00s12jdk',
	oauth_signature_method => 'HMAC-SHA1',
	oauth_timestamp        => '1191242096',
	oauth_nonce            => 'kllo9940pd9333jh',
	oauth_version          => '1.0',
	file                   => 'vacation.jpg',
	size                   => 'original',
  selected               => [ 1, 2, 3 ],
};

my $base2 = OAuth::Lite::Util::create_signature_base_string($http_method, $request_url, $params_include_array);
is($base2, q{GET&http%3A%2F%2Fphotos.example.net%2Fphotos&file%3Dvacation.jpg%26oauth_consumer_key%3Ddpf43f3p214k3103%26oauth_nonce%3Dkllo9940pd9333jh%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1191242096%26oauth_token%3Dnnch734d00s12jdk%26oauth_version%3D1.0%26selected%3D1%26selected%3D2%26selected%3D3%26size%3Doriginal});

my $params_include_invalidtype = {
	oauth_consumer_key     => 'dpf43f3p214k3103',
	oauth_token            => 'nnch734d00s12jdk',
	oauth_signature_method => 'HMAC-SHA1',
	oauth_timestamp        => '1191242096',
	oauth_nonce            => 'kllo9940pd9333jh',
	oauth_version          => '1.0',
	file                   => 'vacation.jpg',
	size                   => 'original',
    selected               => { unknown => 'type' },
};

my $base3 = OAuth::Lite::Util::create_signature_base_string($http_method, $request_url, $params_include_invalidtype);
# throughed unknown type
is($base3, q{GET&http%3A%2F%2Fphotos.example.net%2Fphotos&file%3Dvacation.jpg%26oauth_consumer_key%3Ddpf43f3p214k3103%26oauth_nonce%3Dkllo9940pd9333jh%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1191242096%26oauth_token%3Dnnch734d00s12jdk%26oauth_version%3D1.0%26size%3Doriginal});

is(OAuth::Lite::Util::normalize_params({ b => 1, a => 2 }), 'a=2&b=1');

# From http://oauth.net/core/1.0#anchor14
my %hash = (
    a => 1,
    a1 => 1,
    c => 'hi there',
    f => [25, 50, 'a'],
    z => ['p', 't'],
);
is(OAuth::Lite::Util::normalize_params(\%hash), 'a=1&a1=1&c=hi%20there&f=25&f=50&f=a&z=p&z=t');

# http://tools.ietf.org/html/rfc5849#section-3.4.1.3.2
%hash = (
    'b5'                     => '=%3D',
    'a3'                     => 'a',
    'c@'                     => '',
    'a2'                     => 'r b',
    'oauth_consumer_key'     => '9djdj82h48djs9d2',
    'oauth_token'            => 'kkk9d7dh3k39sjv7',
    'oauth_signature_method' => 'HMAC-SHA1',
    'oauth_timestamp'        => 137131201,
    'oauth_nonce'            => '7d8f3e4a',
    'c2'                     => '',
    'a3'                     => '2 q',
);
$OAuth::Lite::USE_DEPRECATED_NORMALIZER = 1;
isnt(OAuth::Lite::Util::normalize_params(\%hash), 'a2=r%20b&a3=2%20q&b5=%3D%253D&c%40=&c2=&oauth_consumer_key=9djdj82h48djs9d2&oauth_nonce=7d8f3e4a&oauth_signature_method=HMAC-SHA1&oauth_timestamp=137131201&oauth_token=kkk9d7dh3k39sjv7');
$OAuth::Lite::USE_DEPRECATED_NORMALIZER = 0;
is(OAuth::Lite::Util::normalize_params(\%hash), 'a2=r%20b&a3=2%20q&b5=%3D%253D&c%40=&c2=&oauth_consumer_key=9djdj82h48djs9d2&oauth_nonce=7d8f3e4a&oauth_signature_method=HMAC-SHA1&oauth_timestamp=137131201&oauth_token=kkk9d7dh3k39sjv7');

my $base4 = OAuth::Lite::Util::normalize_request_url('HTTP://EXAMPLE.com:80/resource?id=123');
is($base4, 'http://example.com/resource');
my $base5 = OAuth::Lite::Util::normalize_request_url('HTTP://EXAMPLE.com:80/Path?id=123');
is($base5, 'http://example.com/Path');

