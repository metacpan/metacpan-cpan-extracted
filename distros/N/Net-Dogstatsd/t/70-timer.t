#!perl -T

use strict;
use warnings;

use Test::Most 'bail', tests => 26;

use Net::Dogstatsd;


# Create an object to communicate with Dogstatsd, using default server/port settings.
my $dogstatsd = Net::Dogstatsd->new();

ok(
	defined( $dogstatsd ),
	'Net::Dogstatsd instance defined',
);

throws_ok(
	sub {
		$dogstatsd->timer();
	},
	qr/required argument/,
	'Timer: dies on missing required argument-metric name',
);

throws_ok(
	sub {
		$dogstatsd->timer( name => 'testmetric.timing.sample_sql' );
	},
	qr/required argument/,
	'Timer: dies on missing required argument-metric value',
);

throws_ok(
	sub {
		$dogstatsd->timer(
			name  => 'testmetric.timing.sample_sql',
			value => 400
		);
	},
	qr/required argument/,
	'Timer: dies on missing required argument-unit of time',
);


throws_ok(
	sub {
		$dogstatsd->timer(
			name  => 'testmetric.timing.sample_sql',
			value => 250,
			unit  => 'parsecs',
		);
	},
	qr/invalid value/,
	'Timer: dies on invalid unit',
);

throws_ok(
	sub {
		$dogstatsd->timer(
			name  => 'testmetric.timing.sample_sql',
			value => 'abc',
			unit  => 'sec',
		);
	},
	qr/not a positive number/,
	'Timer: dies on non-numeric value',
);


throws_ok(
	sub {
		$dogstatsd->timer(
			name  => 'testmetric.timing.sample_sql',
			value => '',
			unit  => 'sec',
		);
	},
	qr/required argument/,
	'Timer: dies on empty value',
);


throws_ok(
	sub {
		$dogstatsd->timer(
			name => '1testmetric.request_count',
			value => 250,
			unit  => 'sec',
		);
	},
	qr/Invalid metric name/,
	'Timer: dies with invalid metric name  - starting with number',
);


warnings_exist(
	sub {
		$dogstatsd->timer(
			name => 'testmetric.request_count:',
			value => 250,
			unit  => 'sec',
		);
	},
	qr/converted metric/,
	'Timer: warns on translated metric name - colon',
) || diag ($dogstatsd );


warnings_exist(
	sub {
		$dogstatsd->timer(
			name => 'testmetric.request_count|',
			value => 250,
			unit  => 'sec',
		);
	},
	qr/converted metric/,
	'Timer: warns on translated metric name - pipe',
) || diag ($dogstatsd );


warning_like(
	sub {
		$dogstatsd->timer(
			name => 'testmetric.request_count@',
			value => 250,
			unit  => 'sec',
		);
	},
	qr/converted metric/,
	'Timer: warns on translated metric name - at sign',
) || diag ($dogstatsd );


lives_ok(
	sub {
		$dogstatsd->timer(
			name  => 'testmetric.timing.sample_sql',
			value => 250,
			unit  => 'sec',
		);
	},
	'Timer: specified metric, value, unit (sec)',
);

lives_ok(
	sub {
		$dogstatsd->timer(
			name  => 'testmetric.timing.sample_sql',
			value => 250,
			unit  => 's',
		);
	},
	'Timer: specified metric, value, unit(s)',
);

lives_ok(
	sub {
		$dogstatsd->timer(
			name  => 'testmetric.timing.sample_sql',
			value => 250,
			unit  => 'ms',
		);
	},
	'Timer: specified metric, value, unit(ms)',
);


# Additional tag-specific tests

throws_ok(
	sub {
		$dogstatsd->timer(
			name => 'testmetric.timing.sample_sql',
			value => 250,
			unit  => 'sec',
			tags => {},
		);
	},
	qr/Not an ARRAY reference/,
	'Timer: dies unless tag list is an arrayref',
);


throws_ok(
	sub {
		$dogstatsd->timer(
			name => 'testmetric.timing.sample_sql',
			value => 250,
			unit  => 'sec',
			tags => [ '1tag:value' ],
		);
	},
	qr/Invalid tag/,
	'Timer: dies when tag list contains invalid item - tag starting with number',
);


throws_ok(
	sub {
		$dogstatsd->timer(
			name => 'testmetric.timing.sample_sql',
			value => 250,
			unit  => 'sec',
			tags => [ 'tagabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz:value' ],
		);
	},
	qr/Invalid tag/,
	'Timer: dies when tag list contains invalid item - tag > 200 characters',
);


# This is a non-standard check, DataDog will allow it, but it will result in
# confusion and unusual behavior in UI/graphing
throws_ok(
	sub {
		$dogstatsd->timer(
			name => 'testmetric.timing.sample_sql',
			value => 250,
			unit  => 'sec',
			tags => [ 'tag:something:value' ],
		);
	},
	qr/Invalid tag/,
	'Timer: dies when tag list contains invalid item - two colons',
);


lives_ok(
	sub {
		$dogstatsd->timer(
			name => 'testmetric.timing.sample_sql',
			value => 250,
			unit  => 'sec',
			tags => [],
		);
	},
	'Timer: empty tag list',
) || diag ($dogstatsd );


warnings_exist(
	sub {
		$dogstatsd->timer(
			name => 'testmetric.timing.sample_sql',
			value => 250,
			unit  => 'sec',
			tags => [ 'tag+name&here:value' ],
		);
	},
	qr/converted tag/,
	'Timer: tag list with invalid item - WARN on disallowed characters',
) || diag ($dogstatsd );


lives_ok(
	sub {
		$dogstatsd->timer(
			name => 'testmetric.timing.sample_sql',
			value => 250,
			unit  => 'sec',
			tags => [ 'testingtag', 'testtag:testvalue' ]
		);
	},
	'Timer: specified metric, value, unit(sec), valid tag list',
) || diag ($dogstatsd );


# Additional sample rate-specific tests

throws_ok(
	sub {
		$dogstatsd->timer(
			name        => 'testmetric.request_count',
			value => 250,
			unit  => 'sec',
			sample_rate => '',
		);
	},
	qr/Invalid sample rate/,
	'Timer: dies with empty sample_rate',
);


throws_ok(
	sub {
		$dogstatsd->timer(
			name        => 'testmetric.request_count',
			value => 250,
			unit  => 'sec',
			sample_rate => 2,
		);
	},
	qr/Invalid sample rate/,
	'Timer: dies with sample rate > 1',
);


throws_ok(
	sub {
		$dogstatsd->timer(
			name => 'testmetric.request_count',
			value => 250,
			unit  => 'sec',
			sample_rate => -1,
		);
	},
	qr/Invalid sample rate/,
	'Timer: dies with negative sample rate',
);


throws_ok(
	sub {
		$dogstatsd->timer(
			name => 'testmetric.request_count',
			value => 250,
			unit  => 'sec',
			sample_rate => 0,
		);
	},
	qr/Invalid sample rate/,
	'Timer: dies with sample rate of zero',
);


lives_ok(
	sub {
		$dogstatsd->timer(
			name        => 'testmetric.request_count',
			value => 250,
			unit  => 'sec',
			sample_rate => 0.5,
		);
	},
	'Timer: valid sample rate',
) || diag ($dogstatsd );
