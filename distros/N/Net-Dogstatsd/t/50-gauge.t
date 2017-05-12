#!perl -T

use strict;
use warnings;

use Test::Most 'bail', tests => 22;

use Net::Dogstatsd;


# Create an object to communicate with Dogstatsd, using default server/port settings.
my $dogstatsd = Net::Dogstatsd->new();

ok(
	defined( $dogstatsd ),
	'Net::Dogstatsd instance defined',
);

throws_ok(
	sub {
		$dogstatsd->gauge();
	},
	qr/required argument/,
	'Gauge: dies on missing required argument-metric name',
);


throws_ok(
	sub {
		$dogstatsd->gauge( name => 'testmetric.inventory.onhand_minus_onhold' );
	},
	qr/required argument/,
	'Gauge: dies on missing required argument - metric value',
);


throws_ok(
	sub {
		$dogstatsd->gauge(
			name  => 'testmetric.inventory.onhand_minus_onhold',
			value => 'abc',
		);
	},
	qr/not a number/,
	'Gauge: non-numeric value',
);


throws_ok(
	sub {
		$dogstatsd->gauge(
			name  => 'testmetric.inventory.onhand_minus_onhold',
			value => '',
		);
	},
	qr/required argument/,
	'Gauge: Dies on empty value',
);

throws_ok(
	sub {
		$dogstatsd->gauge(
			name => '1testmetric.request_count',
			value => 250,
		);
	},
	qr/Invalid metric name/,
	'Gauge: dies with invalid metric name  - starting with number',
);


warnings_exist(
	sub {
		$dogstatsd->gauge(
			name => 'testmetric.request_count:',
			value => 250,
		);
	},
	qr/converted metric/,
	'Gauge: warns on translated metric name - colon',
) || diag ($dogstatsd );


warnings_exist(
	sub {
		$dogstatsd->gauge(
			name => 'testmetric.request_count|',
			value => 250,
		);
	},
	qr/converted metric/,
	'Gauge: warns on translated metric name - pipe',
) || diag ($dogstatsd );


warning_like(
	sub {
		$dogstatsd->gauge(
			name => 'testmetric.request_count@',
			value => 250,
		);
	},
	qr/converted metric/,
	'Gauge: warns on translated metric name - at sign',
) || diag ($dogstatsd );




lives_ok(
	sub {
		$dogstatsd->gauge(
			name => 'testmetric.inventory.onhand_minus_onhold',
			value => 250,
		);
	},
	'Gauge: specified valid metric name and value',
) || diag ($dogstatsd );


# Additional tag-specific tests

throws_ok(
	sub {
		$dogstatsd->gauge(
			name => 'testmetric.request_count',
			value => 250,
			tags => {},
		);
	},
	qr/Not an ARRAY reference/,
	'Gauge: dies unless tag list is an arrayref',
);


throws_ok(
	sub {
		$dogstatsd->gauge(
			name => 'testmetric.request_count',
			value => 250,
			tags => [ '1tag:something:value' ],
		);
	},
	qr/Invalid tag/,
	'Gauge: dies when tag list contains invalid item - tag starting with number',
);


throws_ok(
	sub {
		$dogstatsd->gauge(
			name => 'testmetric.request_count',
			value => 250,
			tags => [ 'tagabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz:value' ],
		);
	},
	qr/Invalid tag/,
	'Gauge: dies when tag list contains invalid item - tag > 200 characters',
);


# This is a non-standard check, DataDog will allow it, but it will result in
# confusion and unusual behavior in UI/graphing
throws_ok(
	sub {
		$dogstatsd->gauge(
			name => 'testmetric.request_count',
			value => 250,
			tags => [ 'tag:something:value' ],
		);
	},
	qr/Invalid tag/,
	'Gauge: dies when tag list contains invalid item - two colons',
);


lives_ok(
	sub {
		$dogstatsd->gauge(
			name => 'testmetric.request_count',
			value => 250,
			tags => [],
		);
	},
	'Gauge: empty tag list',
) || diag ($dogstatsd );


warnings_exist(
	sub {
		$dogstatsd->gauge(
			name => 'testmetric.request_count',
			value => 250,
			tags => [ 'tag+name&here:value' ],
		);
	},
	qr/converted tag/,
	'Gauge: tag list with invalid item - WARN on disallowed characters',
) || diag ($dogstatsd );


lives_ok(
	sub {
		$dogstatsd->gauge(
			name => 'testmetric.request_count',
			value => 250,
			tags => [ 'testingtag', 'testtag:testvalue' ]
		);
	},
	'Gauge: valid tag list',
) || diag ($dogstatsd );


# Additional sample rate-specific tests

throws_ok(
	sub {
		$dogstatsd->gauge(
			name        => 'testmetric.request_count',
			value => 250,
			sample_rate => '',
		);
	},
	qr/Invalid sample rate/,
	'Gauge: dies with empty sample_rate',
);


throws_ok(
	sub {
		$dogstatsd->gauge(
			name        => 'testmetric.request_count',
			value => 250,
			sample_rate => 2,
		);
	},
	qr/Invalid sample rate/,
	'Gauge: dies with sample rate > 1',
);


throws_ok(
	sub {
		$dogstatsd->gauge(
			name => 'testmetric.request_count',
			value => 250,
			sample_rate => -1,
		);
	},
	qr/Invalid sample rate/,
	'Gauge: dies with negative sample rate',
);


throws_ok(
	sub {
		$dogstatsd->gauge(
			name => 'testmetric.request_count',
			value => 250,
			sample_rate => 0,
		);
	},
	qr/Invalid sample rate/,
	'Gauge: dies with sample rate of zero',
);


lives_ok(
	sub {
		$dogstatsd->gauge(
			name        => 'testmetric.request_count',
			value => 250,
			sample_rate => 0.5,
		);
	},
	'Gauge: valid sample rate',
) || diag ($dogstatsd );
