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
			oauth_request_token_url => 'http://term.ie/oauth/example/request_token.php',
			oauth_authorize_url => 'null',
			oauth_access_token_url => 'http://term.ie/oauth/example/access_token.php',
			oauth_verifier_timeout => 2
		);
};

test {
	$ua->get_request_token();
};

failwith {
	$ua->get_access_token();
} 'Timeout error while waiting for a callback connection';


