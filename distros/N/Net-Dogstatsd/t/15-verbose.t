#!perl -T

use strict;
use warnings;

use Test::Most 'bail', tests => 3;

use Net::Dogstatsd;


# Create an object to communicate with Dogstatsd, using default server/port settings.
my $dogstatsd = Net::Dogstatsd->new();

ok(
	defined( $dogstatsd ),
	'Net::Dogstatsd instance defined',
);


# Set verbosity with invalid value
lives_ok(
	sub
	{
		$dogstatsd->verbose(3);
	},
	'Does not set verbosity to anything but 0/1',
);

# Set verbosity with valid value
$dogstatsd->verbose(1);

# Get verbosity
my $verbosity = $dogstatsd->verbose();

is(
	$verbosity,
	1,
	"Verbosity set to true."
);
