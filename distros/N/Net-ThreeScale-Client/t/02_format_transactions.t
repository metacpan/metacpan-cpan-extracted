use strict;
use warnings;
use blib;
use Carp qw(cluck);
use lib "../lib";
use Data::Dumper;

use Test::More tests=>2;
use Net::ThreeScale::Client;

local $SIG{__WARN__} = sub { cluck @_; };

my $DEBUG = 0;

$DEBUG = 1 if $ENV{MKS_DEBUG_TESTS};

my $client = new Net::ThreeScale::Client( url=>'http://su1.3scale.net',
	provider_key => "provider-abc123", DEBUG=>$DEBUG);

# transaction example copied from here:
#
# http://www.3scale.net/support/api-service-management-v2-0/

my @transactions = (
	{
		app_id => "bce4c8f4",
		usage => {
			hits => 1,
			transfer => 4500,
		},
		timestamp => "2009-01-01 14:23:08",
	},
	{
		app_id => "bad7e480",
		usage => {
			hits => 1,
			transfer => 2840,
		},
		timestamp => "2009-01-01 18:11:59",
	},
);

my $expected = "transactions[0][app_id]=bce4c8f4&"
	. "transactions[0][usage][hits]=1&"
	. "transactions[0][usage][transfer]=4500&"
	. "transactions[0][timestamp]=2009-01-01%2014%3A23%3A08&"
	. "transactions[1][app_id]=bad7e480&"
	. "transactions[1][usage][hits]=1&"
	. "transactions[1][usage][transfer]=2840&"
	. "transactions[1][timestamp]=2009-01-01%2018%3A11%3A59";

my $result = $client->_format_transactions(@transactions);
ok(defined($result));

is($result, $expected);

# vim:set ts=4 sw=4 ai noet:
