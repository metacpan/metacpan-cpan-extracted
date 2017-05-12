use strict;
use warnings;
use Test::Subs debug => 1;
use OAuth::Consumer;
use WWW::Mechanize;

skip 'You need a Perl with thread' unless eval 'use threads; 1' && eval 'use Thread::Queue; 1';

my ($ua, $oua, $r, $api, $verifier_url);
my ($token, $secret);

$ua = LWP::UserAgent->new(timeout => 15);
$r = $ua->get('http://oauth-sandbox.sevengoslings.net/');
skip 'oauth-sandbox.sevengoslings.net is not reachable' unless $r->is_success;

test {
	$oua = OAuth::Consumer->new(
		oauth_consumer_key => '0c200087d6b0d2e1',
		oauth_consumer_secret => '3d10d9c543adebd723a656be4a49',
		oauth_request_token_url => 'http://oauth-sandbox.sevengoslings.net/request_token',
		oauth_access_token_url => 'http://oauth-sandbox.sevengoslings.net/access_token',
		oauth_authorize_url => 'http://oauth-sandbox.sevengoslings.net/authorize',
		oauth_verifier_type => 'thread'
	);
};

test {
	$r = $oua->get('http://oauth-sandbox.sevengoslings.net/three_legged');
	$r->code == 500;
};

test {
	$r = $oua->get('http://oauth-sandbox.sevengoslings.net/two_legged');
	$r->is_success;
};

test {
	$verifier_url = $oua->get_request_token();
};

#comment { $verifier_url };

test {
	my $mech = WWW::Mechanize->new();
	$mech->get($verifier_url);
	$mech->submit_form(
			with_fields      => {
					username => 'mathias',
					kitten => 'able',
				}
		);
	# bug dans WWW::Mechanize qui ne poste pas les valeurs du champs submit...
	$mech->submit_form(with_fields => { allow => 'Allow Access' });
	$mech->form_with_fields('allow');
	$mech->click_button(value => 'Allow Access');
};


test {
	($token, $secret) = $oua->get_access_token();
};

#comment { "token: $token\nsecret: $secret" };

test {
	$r = $oua->get('http://oauth-sandbox.sevengoslings.net/three_legged');
	$r->is_success;
};

test {
	$oua = OAuth::Consumer->new(
		oauth_consumer_key => '0c200087d6b0d2e1',
		oauth_consumer_secret => '3d10d9c543adebd723a656be4a49',
		oauth_token => $token,
		oauth_token_secret => $secret
	);
};

test {
	$r = $oua->get('http://oauth-sandbox.sevengoslings.net/three_legged');
	$r->is_success;
};

test {
	$r = $oua->get('http://oauth-sandbox.sevengoslings.net/two_legged');
	$r->is_success;
};

test {
	my $mech = WWW::Mechanize->new();
	$mech->get('http://oauth-sandbox.sevengoslings.net/');
	$mech->submit_form(
			with_fields      => {
					username => 'mathias',
					kitten => 'able',
				}
		);
	while(my $lnk = $mech->find_link(url_regex => qr/delete-token/)) {
		$mech->get($lnk->url());
	}
	1;
};


