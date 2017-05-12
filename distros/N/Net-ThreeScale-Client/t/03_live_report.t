use strict;
use warnings;
use blib;
use Carp qw(cluck);
use lib "../lib";
use Data::Dumper;

use Test::More tests=>5;
use Net::ThreeScale::Client;

use POSIX qw(strftime);

local $SIG{__WARN__} = sub { cluck @_; };

my $DEBUG = 0;

$DEBUG = 1 if $ENV{MKS_DEBUG_TESTS};

SKIP: {
	skip("not configured for a live test", 5) if (not (
		$ENV{PROVIDER_KEY} and
		$ENV{APP_ID}
	));

	my $client = new Net::ThreeScale::Client(provider_key => $ENV{PROVIDER_KEY}, DEBUG=>$DEBUG);

	my $response = $client->authorize(app_id=>$ENV{APP_ID}, app_key=>$ENV{APP_KEY});

	ok(defined($response));
	ok($response->is_success());

	my $ts1 = strftime("%Y-%m-%d %H:%M:%S", localtime());
	sleep(1);
	my $ts2 = strftime("%Y-%m-%d %H:%M:%S", localtime());

	my @transactions = (
		{
			app_id => $ENV{APP_ID},
			usage => {
				hits => 10,
			},
			timestamp => $ts1,
		},
		{
			app_id => $ENV{APP_ID},
			usage => {
				hits => 10,
			},
			timestamp => $ts2,
		},
	);

	is(scalar(@transactions), 2);

	my $report_response = $client->report(transactions=>\@transactions);

	ok(defined($report_response));
	ok($response->is_success());
}

# vim:set ts=4 sw=4 ai noet:
