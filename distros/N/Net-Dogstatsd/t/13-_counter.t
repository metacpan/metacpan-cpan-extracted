#!perl -T

use strict;
use warnings;

use Test::Most 'bail', tests => 3;

use Net::Dogstatsd;


# Create an object to communicate with Dogstatsd - no parameters.
my $dogstatsd = Net::Dogstatsd->new();

ok(
	defined( $dogstatsd ),
	'Net::Dogstatsd instance defined',
);

throws_ok(
	sub {
		$dogstatsd->_counter( action => 'foo' );
	},
	qr/invalid action/,
	'_counter: Dies on invalid action'
);



throws_ok(
	sub {
		$dogstatsd->_counter(
			name   => 'test_counter',
			action => 'increment',
			value  => '',
		);
	},
	qr/positive integer/,
	'_counter: Dies on empty value'
);


#**|throws_ok(
#**|	sub {
#**|		$dogstatsd->_counter(
#**|			name   => 'test_counter',
#**|			action => 'increment',
#**|			value  => 1,
#**|			tags   => [],
#**|		);
#**|	},
#**|	qr/positive integer/,
#**|	'_counter: Dies on empty tag list'
#**|);
#**|
#**|
