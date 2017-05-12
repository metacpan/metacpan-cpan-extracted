#!perl -T

use strict;
use warnings;

use Test::Most 'bail', tests => 21;

use Net::Dogstatsd;

# Create an object to communicate with Dogstatsd, using default server/port settings.
my $dogstatsd = Net::Dogstatsd->new();

ok(
	defined( $dogstatsd ),
	'Net::Dogstatsd instance defined',
);

throws_ok(
	sub {
		$dogstatsd->sets();
	},
	qr/required argument/,
	'Sets: dies on missing required argument-metric name',
);

throws_ok(
	sub {
		$dogstatsd->sets( name => 'testmetric.inventory.onhand_minus_onhold' );
	},
	qr/required argument/,
	'Sets: dies on missing required argument-metric value',
);

throws_ok(
	sub {
		$dogstatsd->sets(
			name => '1testmetric.request_count',
			value => 250,
		);
	},
	qr/Invalid metric name/,
	'Sets: dies with invalid metric name  - starting with number',
);


warning_like(
	sub {
		$dogstatsd->sets(
			name => 'testmetric.request_count:',
			value => 250,
		);
	},
	qr/converted metric/,
	'Sets: warns on translated metric name - colon',
) || diag ($dogstatsd );


warnings_exist(
	sub {
		$dogstatsd->sets(
			name => 'testmetric.request_count|',
			value => 250,
		);
	},
	qr/converted metric/,
	'Sets: warns on translated metric name - pipe',
) || diag ($dogstatsd );


warning_like(
	sub {
		$dogstatsd->sets(
			name => 'testmetric.request_count@',
			value => 250,
		);
	},
	qr/converted metric/,
	'Sets: warns on translated metric name - at sign',
) || diag ($dogstatsd );


lives_ok(
	sub {
		$dogstatsd->sets(
			name => 'testmetric.site.unique_visitors',
			value => 'abc124def678',
		);
	},
	'Sets: specified metric name and value',
) || diag ( $dogstatsd );


# Additional tag-specific tests

throws_ok(
	sub {
		$dogstatsd->sets(
			name => 'testmetric.request_count',
			value => 250,
			tags => {},
		);
	},
	qr/Not an ARRAY reference/,
	'Sets: dies unless tag list is an arrayref',
);


throws_ok(
	sub {
		$dogstatsd->sets(
			name => 'testmetric.request_count',
			value => 250,
			tags => [ '1tag:something:value' ],
		);
	},
	qr/Invalid tag/,
	'Sets: dies when tag list contains invalid item - tag starting with number',
);


throws_ok(
	sub {
		$dogstatsd->sets(
			name => 'testmetric.request_count',
			value => 250,
			tags => [ 'tagabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz:value' ],
		);
	},
	qr/Invalid tag/,
	'Sets: dies when tag list contains invalid item - tag > 200 characters',
);


# This is a non-standard check, DataDog will allow it, but it will result in
# confusion and unusual behavior in UI/graphing
throws_ok(
	sub {
		$dogstatsd->sets(
			name => 'testmetric.request_count',
			value => 250,
			tags => [ 'tag:something:value' ],
		);
	},
	qr/Invalid tag/,
	'Sets: dies when tag list contains invalid item - two colons',
);


throws_ok(
	sub {
		$dogstatsd->sets(
			name => 'testmetric.request_count',
			value => '',
		);
	},
	qr/required argument/,
	'Sets: dies with empty value',
);


lives_ok(
	sub {
		$dogstatsd->sets(
			name => 'testmetric.request_count',
			value => 250,
			tags => [],
		);
	},
	'Sets: specified name, value and empty tag list',
) || diag ($dogstatsd );


warnings_exist(
	sub {
		$dogstatsd->sets(
			name => 'testmetric.request_count',
			value => 250,
			tags => [ 'tag+name&here:value' ],
		);
	},
	qr/converted tag/,
	'Sets: tag list with invalid item - WARN on disallowed characters',
) || diag ($dogstatsd );


lives_ok(
	sub {
		$dogstatsd->sets(
			name => 'testmetric.request_count',
			value => 250,
			tags => [ 'testingtag', 'testtag:testvalue' ]
		);
	},
	'Sets: specified valid name, value and tag list',
) || diag ($dogstatsd );


# Additional sample rate-specific tests

throws_ok(
	sub {
		$dogstatsd->sets(
			name        => 'testmetric.request_count',
			value => 250,
			sample_rate => '',
		);
	},
	qr/Invalid sample rate/,
	'Sets: dies with empty sample_rate',
);


throws_ok(
	sub {
		$dogstatsd->sets(
			name        => 'testmetric.request_count',
			value => 250,
			sample_rate => 2,
		);
	},
	qr/Invalid sample rate/,
	'Sets: dies with sample rate > 1',
);


throws_ok(
	sub {
		$dogstatsd->sets(
			name => 'testmetric.request_count',
			value => 250,
			sample_rate => -1,
		);
	},
	qr/Invalid sample rate/,
	'Sets: dies with negative sample rate',
);


throws_ok(
	sub {
		$dogstatsd->sets(
			name => 'testmetric.request_count',
			value => 250,
			sample_rate => 0,
		);
	},
	qr/Invalid sample rate/,
	'Sets: dies with sample rate of zero',
);


lives_ok(
	sub {
		$dogstatsd->sets(
			name        => 'testmetric.request_count',
			value => 250,
			sample_rate => 0.5,
		);
	},
	'Sets: valid sample rate',
) || diag ($dogstatsd );
