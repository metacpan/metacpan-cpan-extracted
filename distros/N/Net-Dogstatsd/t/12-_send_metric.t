#!perl -T

use strict;
use warnings;

use Test::Most 'bail', tests => 11;

use Net::Dogstatsd;


# Create an object to communicate with Dogstatsd, using default server/port settings.
my $dogstatsd = Net::Dogstatsd->new();

ok(
	defined( $dogstatsd ),
	'Net::Dogstatsd instance defined',
);

throws_ok(
	sub {
		$dogstatsd->_send_metric();
	},
	qr/required argument/,
	'_send_metric: dies on missing required arguments',
);


throws_ok(
	sub {
		$dogstatsd->_send_metric( name => 'testmetric.current_visitors');
	},
	qr/required argument/,
	'_send_metric: dies on missing required arguments',
);

throws_ok(
	sub {
		$dogstatsd->_send_metric(
			type => 'gauge',
			name => 'testmetric.current_visitors'
		);
	},
	qr/required argument/,
	'_send_metric: dies on missing required arguments',
);


throws_ok(
	sub {
		$dogstatsd->_send_metric(
			type  => 'gauge',
			name  => 'testmetric.current_visitors',
			value => '',
		);
	},
	qr/required argument/,
	'_send_metric: dies on missing/empty required arguments',
);

throws_ok(
	sub {
		$dogstatsd->_send_metric(
			type  => 'gauge',
			value => 4,
		);
	},
	qr/required argument/,
	'_send_metric: dies on missing required arguments',
);

throws_ok(
	sub {
		$dogstatsd->_send_metric(
			type  => 'gauge',
			name  => 'testmetric.inventory.onhand_minus_onhold',
			value => 250,
			tags  => {},
		);
	},
	qr/Not an ARRAY reference/,
	'_send_metric: dies on invalid tag list ',
);


lives_ok(
	sub {
		$dogstatsd->_send_metric(
			type  => 'gauge',
			name  => 'testmetric.inventory.onhand_minus_onhold',
			value => 250,
		);
	},
	'_send_metric: specified valid metric name, type and value',
) || diag ($dogstatsd );


lives_ok(
	sub {
		$dogstatsd->_send_metric(
			type  => 'gauge',
			name  => 'testmetric.current_visitors',
			value => 32,
			tags => [ 'env:dev' ],
		);
	},
	'_send_metric: specified valid metric name, type, value and tags',
);

lives_ok(
	sub {
		$dogstatsd->_send_metric(
			type  => 'gauge',
			name  => 'testmetric.current_visitors',
			value => 32,
			tags => [],
		);
	},
	'_send_metric: specified valid metric name, type, value and empty tag list',
);


lives_ok(
	sub {
		$dogstatsd->_send_metric(
			type        => 'gauge',
			name        => 'testmetric.current_visitors',
			value       => 32,
			tags        => [ 'env:dev' ],
			sample_rate => 0.5
		);
	},
	'_send_metric: specified valid metric name, type, value, tags and sample_rate',
);

