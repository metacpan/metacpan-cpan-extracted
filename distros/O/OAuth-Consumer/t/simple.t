use strict;
use warnings;
use Test::Subs;
use OAuth::Consumer;

# we use this server for the test: http://term.ie/oauth/example/
my ($ua, $r);

$ua = LWP::UserAgent->new(timeout => 15);
$r = $ua->get('http://term.ie/oauth/example/');
skip 'term.ie/oauth/example/ is not reachable' unless $r->is_success;

test {
	$ua = OAuth::Consumer->new(
			oauth_consumer_key => 'key',
			oauth_consumer_secret => 'secret',
			oauth_verifier_type => 'manual',
			oauth_request_token_url => 'http://term.ie/oauth/example/request_token.php',
			oauth_authorize_url => 'null',
			oauth_access_token_url => 'http://term.ie/oauth/example/access_token.php',
			oauth_callback => 'null'
		);
};

test {
	$r = $ua->get('http://term.ie/oauth/example/echo_api.php?test=foo');
};

match { $r->content } qr/Invalid access token/;

test {
	$ua->get_request_token();
};

my ($token, $secret);
test {
	($token, $secret) = $ua->get_access_token(oauth_verifier => '');
};

test {
	$token eq 'accesskey' and $secret eq 'accesssecret'
};

test {
	$r = $ua->get('http://term.ie/oauth/example/echo_api.php?test=foo');
};

test {
	$r->content eq 'test=foo'
};
