use strict;
use warnings;
use blib;
use Carp qw(cluck);
use lib "../lib";
use Data::Dumper;

use Test::More tests => 10;
use Net::ThreeScale::Client;

local $SIG{__WARN__} = sub { cluck @_; };

my $DEBUG = 0;

$DEBUG = 1 if $ENV{MKS_DEBUG_TESTS};

SKIP: {
	skip("not configured for a live test", 5) if (not (
		$ENV{PROVIDER_KEY} and
		$ENV{APP_ID}
	));

	my $client = new Net::ThreeScale::Client( url=>'http://su1.3scale.net',
		provider_key => $ENV{PROVIDER_KEY}, DEBUG=>$DEBUG);

	my $response = $client->authorize(app_id=>$ENV{APP_ID}, app_key=>$ENV{APP_KEY});

	ok(defined($response));
	ok($response->is_success());

	my $rep = $response->usage_reports();

	is(ref($rep), 'ARRAY');

	my @reports = @{$rep};

	ok(defined($reports[0]->{period_start}));
	ok(defined($reports[0]->{period_end}));
}

SKIP: {
	skip("not configured for a live test", 5) if (not (
		$ENV{PROVIDER_KEY} and
		$ENV{USER_KEY}
	));

	my $client = new Net::ThreeScale::Client( url=>'http://su1.3scale.net',
		provider_key => $ENV{PROVIDER_KEY}, DEBUG=>$DEBUG);

	my $response = $client->authrep(user_key=>$ENV{USER_KEY});

	ok(defined($response));
	ok($response->is_success());

	my $rep = $response->usage_reports();

	is(ref($rep), 'ARRAY');

	my @reports = @{$rep};

	ok(defined($reports[0]->{period_start}));
	ok(defined($reports[0]->{period_end}));
}

# vim:set ts=4 sw=4 ai noet:
