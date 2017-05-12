use Test::More tests => 18;

use OAuth::Lite::ServerUtil;
use OAuth::Lite::Util;
use OAuth::Lite::SignatureMethod::HMAC_SHA1;

my $util = OAuth::Lite::ServerUtil->new;
my $non_strict_util = OAuth::Lite::ServerUtil->new( strict => 0 );

eval {$util->support_signature_method('HMAC-SHA1');};
ok(!$@, 'load HMAC-SHA1 signature method class');

eval {$util->support_signature_methods(qw/RSA-SHA1 PLAINTEXT/);};
ok(!$@, 'load RSA-SHA1 and PLAINTEXT signature method classes');

eval {$util->support_signature_method('FOO-BAR');};
like($@, qr{Couldn't require class, OAuth::Lite::SignatureMethod::FOO_BAR},
	'fails to load FOO-BAR signature method class');

eval {$util->support_signature_methods(qw/FOO BAR/);};
like($@, qr{Couldn't require class, OAuth::Lite::SignatureMethod::FOO},
	'fails to load FOO and BAR signature method classes');

ok($util->validate_signature_method('HMAC-SHA1'), 'HMAC-SHA1 is valid');
ok($util->validate_signature_method('PLAINTEXT'), 'PLAINTEXT is valid');
ok($util->validate_signature_method('RSA-SHA1'), 'RSA-SHA1 is valid');
ok(!$util->validate_signature_method('FOO-BAR'), 'FOO-BAR is invalid');
ok(!$util->validate_signature_method('FOO'), 'FOO is invalid');
ok(!$util->validate_signature_method('BAR'), 'BAR is invalid');

$util->allow_extra_params(qw/file size/);

$util->allow_extra_param('another');

my $http_method = "GET";
my $request_url = "http://example.com/resource";
my $consumer_key = 'dpf43f3p214k3103';
my $consumer_secret = 'abcddpf43f3p214k';
my $sign_method = OAuth::Lite::SignatureMethod::HMAC_SHA1->new(
	consumer_secret => $consumer_secret,
);
my $params = {
	oauth_consumer_key     => $consumer_key,
	oauth_signature_method => 'HMAC-SHA1',
	oauth_timestamp        => '1191242096',
	oauth_nonce            => 'kllo9940pd9333jh',
	oauth_version          => '1.0',
	file                   => 'vacation.jpg',
	size                   => 'original',
	another                => 'hoge',
};

my $base_string = OAuth::Lite::Util::create_signature_base_string($http_method, $request_url, $params);
my $signature = $sign_method->sign($base_string);
$params->{oauth_signature} = $signature;
ok($util->validate_params($params), $util->errstr);
ok(!$util->validate_params($params, 1), 'validate_params should fail');

my $params_with_token = {
	oauth_token => 'nnch734d00s12jdk',
	%$params,
};


my $base_string2 = OAuth::Lite::Util::create_signature_base_string($http_method, $request_url, $params_with_token);
my $signature2 = $sign_method->sign($base_string2);
$params_with_token->{oauth_signature} = $signature2;
ok($util->validate_params($params_with_token, 1), $util->errstr);
ok(!$util->validate_params($params_with_token), 'validate_params should fail');

my $ext_params = {
	ext => 'foo',
	%$params_with_token,
};

my $base_string3 = OAuth::Lite::Util::create_signature_base_string($http_method, $request_url, $ext_params);
my $signature3 = $sign_method->sign($base_string3);
$ext_params->{oauth_signature} = $signature3;
ok(!$util->validate_params($ext_params, 1), $util->errstr);
ok($non_strict_util->validate_params($ext_params, 1), 'validate_params should be success on non-strict mode.');

my $signature_is_ok = $util->verify_signature(
	method          => $http_method,
	url             => $request_url,
	params          => $params,
	consumer_secret => $consumer_secret,
);

ok($signature_is_ok, $util->errstr);

my $signature_is_not_ok = $util->verify_signature(
	method          => 'POST',
	url             => $request_url,
	params          => $params,
	consumer_secret => $consumer_secret,
);

ok(!$signature_is_not_ok, 'verify should fail');
