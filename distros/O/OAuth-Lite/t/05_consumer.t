use Test::More tests => 53;

use URI::Escape;
use OAuth::Lite::Consumer;
use OAuth::Lite::Token;
use OAuth::Lite::Util;
use OAuth::Lite::AuthMethod qw(:all);

my $consumer_key    = "key";
my $consumer_secret = "secret";

my $c1 = OAuth::Lite::Consumer->new(
	consumer_key    => $consumer_key,
	consumer_secret => $consumer_secret,
);


is($c1->consumer_key, $consumer_key, "consumer_key passed collectly");
is($c1->consumer_secret, $consumer_secret, "consumer_secret passed collectly");
is($c1->{auth_method}, AUTH_HEADER, "default auth_method is set collectly.");
is($c1->{http_method}, 'POST', "default http_method is set collectly.");

my $c2 = OAuth::Lite::Consumer->new(
	consumer_key    => $consumer_key,
	consumer_secret => $consumer_secret,
	auth_method     => POST_BODY,
	http_method     => 'GET',
);

is($c2->{auth_method}, POST_BODY, "customized auth_method is set collectly.");
is($c2->{http_method}, 'GET', "customized http_method is set collectly.");


my $c3 = OAuth::Lite::Consumer->new(
	consumer_key       => $consumer_key,
	consumer_secret    => $consumer_secret,
	request_token_path => 'http://example.org/path/to/requesttoken',
	access_token_path  => 'http://example.org/path/to/accesstoken',
	authorize_path     => 'http://example.org/path/to/authorize',
);

is($c3->request_token_url, q{http://example.org/path/to/requesttoken}, qq/request_token_url is called collectly/);
is($c3->access_token_url, q{http://example.org/path/to/accesstoken}, qq/access_token_url is called collectly/);
is($c3->authorization_url, q{http://example.org/path/to/authorize}, qq/authorization_url is called collectly/);

my $c4 = OAuth::Lite::Consumer->new(
	consumer_key       => $consumer_key,
	consumer_secret    => $consumer_secret,
	site               => 'http://example.org',
	request_token_path => '/path/to/requesttoken',
	access_token_path  => '/path/to/accesstoken',
	authorize_path     => '/path/to/authorize',
);

is($c4->request_token_url, q{http://example.org/path/to/requesttoken}, qq/request_token_url is called collectly/);
is($c4->access_token_url, q{http://example.org/path/to/accesstoken}, qq/access_token_url is called collectly/);
is($c4->authorization_url, q{http://example.org/path/to/authorize}, qq/authorization_url is called collectly/);

my $c5 = OAuth::Lite::Consumer->new(
	consumer_key       => $consumer_key,
	consumer_secret    => $consumer_secret,
	site               => 'http://example.org',
	request_token_path => '/path/to/requesttoken',
	access_token_path  => '/path/to/accesstoken',
	authorize_path     => 'http://example2.org/path/to/authorize',
);

is($c5->request_token_url, q{http://example.org/path/to/requesttoken}, qq/request_token_url is called collectly/);
is($c5->access_token_url, q{http://example.org/path/to/accesstoken}, qq/access_token_url is called collectly/);
is($c5->authorization_url, q{http://example2.org/path/to/authorize}, qq/authorization_url is called collectly/);

my $atoken1 = OAuth::Lite::Token->new;
$atoken1->token('foo');

my $auth_url1 = $c5->url_to_authorize;
is ($auth_url1, q{http://example2.org/path/to/authorize}, 'url_to_authorize works as expected.');

my $auth_url2 = $c5->url_to_authorize( token => $atoken1 );
is ($auth_url2, q{http://example2.org/path/to/authorize?oauth_token=foo}, 'url_to_authorize works as expected.');

my $callback_url = q{http://myservice/callback};
my $enc_callback_url = URI::Escape::uri_escape($callback_url);
my $auth_url3 = $c5->url_to_authorize( callback_url => $callback_url );
#is( $auth_url3, qq{http://example2.org/path/to/authorize?oauth_callback=$enc_callback_url} );

my $auth_url4 = $c5->url_to_authorize( token => '' );
is ($auth_url4, q{http://example2.org/path/to/authorize?oauth_token=}, 'url_to_authorize works as expected.');

my $c6 = OAuth::Lite::Consumer->new(
	consumer_key       => $consumer_key,
	consumer_secret    => $consumer_secret,
	site               => 'http://example.org',
	request_token_path => '/path/to/requesttoken',
	access_token_path  => '/path/to/accesstoken',
	authorize_path     => 'http://example2.org/path/to/authorize',
	callback_url       => $callback_url,
);

my $auth_url5 = $c6->url_to_authorize( token => $atoken1 );
is( $auth_url5, qq{http://example2.org/path/to/authorize?oauth_token=foo} );

my $oauth_params1 = $c6->gen_auth_params('GET', 'http://example.org/');
ok(!exists $oauth_params1->{oauth_token}, "oauth_token shouldn't be included");
ok(exists $oauth_params1->{oauth_signature}, 'signature is set');
is($oauth_params1->{oauth_consumer_key}, $consumer_key, 'collect consumer_key');
is($oauth_params1->{oauth_signature_method}, 'HMAC-SHA1', 'collect signature method');
#is($oauth_params1->{oauth_signature}, '8vqsDTcMwKNGblxtgmRVrHtn29I=', 'collect signature');
is($oauth_params1->{oauth_version}, '1.0', 'collect version');
like($oauth_params1->{oauth_timestamp}, qr/^\d+$/, 'collect timestamp');
like($oauth_params1->{oauth_nonce}, qr/^[a-fA-F0-9]+$/, 'collect timestamp');
my $oauth_params2 = $c6->gen_auth_params('POST', 'http://example.org/', $atoken1);
ok(exists $oauth_params2->{oauth_token}, "oauth_token should be included");
ok(exists $oauth_params2->{oauth_signature}, 'signature is set');
is($oauth_params2->{oauth_consumer_key}, $consumer_key, 'collect consumer_key');
is($oauth_params2->{oauth_signature_method}, 'HMAC-SHA1', 'collect signature method');
#is($oauth_params2->{oauth_signature}, 'HMAC-SHA1', 'collect signature');
is($oauth_params2->{oauth_token}, 'foo', 'collect token');
is($oauth_params2->{oauth_version}, '1.0', 'collect version');
like($oauth_params2->{oauth_timestamp}, qr/^\d+$/, 'collect timestamp');
like($oauth_params2->{oauth_nonce}, qr/^[a-fA-F0-9]+$/, 'collect timestamp');

my $oauth_params3 = $c6->gen_auth_params('POST', 'http://example.org/', '');
ok(exists $oauth_params3->{oauth_token}, "oauth_token should be included");
ok(exists $oauth_params3->{oauth_signature}, 'signature is set');
is($oauth_params3->{oauth_consumer_key}, $consumer_key, 'collect consumer_key');
is($oauth_params3->{oauth_signature_method}, 'HMAC-SHA1', 'collect signature method');
#is($oauth_params2->{oauth_signature}, 'HMAC-SHA1', 'collect signature');
is($oauth_params3->{oauth_token}, '', 'collect token');
is($oauth_params3->{oauth_version}, '1.0', 'collect version');
like($oauth_params3->{oauth_timestamp}, qr/^\d+$/, 'collect timestamp');
like($oauth_params3->{oauth_nonce}, qr/^[a-fA-F0-9]+$/, 'collect timestamp');

my $oauth_params4 = $c6->gen_auth_params('POST', 'http://example.org/');
ok(!exists $oauth_params4->{oauth_token}, "oauth_token shouldn't be included");
ok(exists $oauth_params4->{oauth_signature}, 'signature is set');
is($oauth_params4->{oauth_consumer_key}, $consumer_key, 'collect consumer_key');
is($oauth_params4->{oauth_signature_method}, 'HMAC-SHA1', 'collect signature method');
#is($oauth_params2->{oauth_signature}, 'HMAC-SHA1', 'collect signature');
is($oauth_params4->{oauth_version}, '1.0', 'collect version');
like($oauth_params4->{oauth_timestamp}, qr/^\d+$/, 'collect timestamp');
like($oauth_params4->{oauth_nonce}, qr/^[a-fA-F0-9]+$/, 'collect timestamp');

my $token2 = OAuth::Lite::Token->new;
$token2->token('foo');
my $auth_query1 = $c6->gen_auth_query('GET', q{http://example.org/});
like($auth_query1, qr{oauth_consumer_key=key&oauth_nonce=[a-fA-F0-9]+&oauth_signature=[^\&]+&oauth_signature_method=HMAC-SHA1&oauth_timestamp=\d+&oauth_version=1.0}, 'gen_auth_query works as expected');
my $auth_query2 = $c6->gen_auth_query('GET', q{http://example.org/}, $token2);
like($auth_query2, qr{oauth_consumer_key=key&oauth_nonce=[a-fA-F0-9]+&oauth_signature=[^\&]+&oauth_signature_method=HMAC-SHA1&oauth_timestamp=\d+&oauth_token=foo&oauth_version=1.0}, 'gen_auth_query works as expected');
my $auth_query3 = $c6->gen_auth_query('GET', q{http://example.org/}, undef, { extra => 'foo' });
like($auth_query3, qr{extra=foo&oauth_consumer_key=key&oauth_nonce=[a-fA-F0-9]+&oauth_signature=[^\&]+&oauth_signature_method=HMAC-SHA1&oauth_timestamp=\d+&oauth_version=1.0}, 'gen_auth_query works as expected');
my $auth_query4 = $c6->gen_auth_query('GET', q{http://example.org/}, $token2, { extra => 'foo' });
like($auth_query4, qr{extra=foo&oauth_consumer_key=key&oauth_nonce=[a-fA-F0-9]+&oauth_signature=[^\&]+&oauth_signature_method=HMAC-SHA1&oauth_timestamp=\d+&oauth_token=foo&oauth_version=1.0}, 'gen_auth_query works as expected');

=pod

my $c7 = OAuth::Lite::Consumer->new(
    consumer_key    => q{consumer},
    consumer_secret => q{dummy},
    _nonce          => q{10369470270925},
    _timestamp      => q{1236874236},
);
my $req7 = $c7->gen_oauth_request(
method  => 'PUT',
url     => q{http://www.example.com},
content => q{Hello World!},
headers => [ 'Content-Type' => q{text/plain} ],
);

=cut
