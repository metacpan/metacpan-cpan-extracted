#!perl -T

use strict;
use warnings;

use Test::Most 'bail', tests => 2;
use Test::FailWarnings -allow_deps => 1;

use Net::Dogstatsd;


# Create an object to communicate with Dogstatsd - no parameters.
my $dogstatsd = Net::Dogstatsd->new();

isa_ok(
	$dogstatsd, 'Net::Dogstatsd',
	'Return value of Net::Dogstatsd->new()',
) || diag( explain( $dogstatsd ) );

# Create an object to communicate with Dogstatsd.
undef $dogstatsd;
$dogstatsd = Net::Dogstatsd->new(
	port    => 2128,
	host    => 127.0.0.1,
	verbose => 1,
);

isa_ok(
	$dogstatsd, 'Net::Dogstatsd',
	'Return value of Net::Dogstatsd->new()',
) || diag( explain( $dogstatsd ) );
