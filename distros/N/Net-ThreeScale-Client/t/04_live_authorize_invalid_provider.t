use strict;
use warnings;
use blib;
use Carp qw(cluck);
use lib "../lib";
use Data::Dumper;

use Test::More tests=>3;
use Net::ThreeScale::Client;

local $SIG{__WARN__} = sub { cluck @_; };

my $DEBUG = 0;

$DEBUG = 1 if $ENV{MKS_DEBUG_TESTS};

SKIP: {
	skip("not configured for a live test", 3) if (not (
		$ENV{PROVIDER_KEY} and
		$ENV{APP_ID}
	));

	my $client = new Net::ThreeScale::Client( url=>'http://su1.3scale.net',
		provider_key => "provider-abc123", DEBUG=>$DEBUG);

	my $response = $client->authorize(app_id=>$ENV{APP_ID}, app_key=>$ENV{APP_KEY});

	ok(defined($response));
	ok(! $response->is_success());

	my $rep = $response->usage_reports();

	ok(not defined($rep));
}

# vim:set ts=4 sw=4 ai noet:
