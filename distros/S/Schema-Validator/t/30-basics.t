#!/usr/bin/env perl

# ---------------------------------------------------------------------------
# 30-basics.t -- functional tests for Schema::Validator
# Tests is_valid_datetime edge cases and load_dynamic_vocabulary.
# Network tests are skipped when NO_NETWORK_TESTING is set (CI default).
# ---------------------------------------------------------------------------

use strict;
use warnings;

use Test::Most;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Schema::Validator qw(is_valid_datetime load_dynamic_vocabulary);

# ---------------------------------------------------------------------------
# is_valid_datetime -- comprehensive edge-case coverage
# ---------------------------------------------------------------------------

# Accepted formats: date only
ok(is_valid_datetime('2025-06-28'),           'YYYY-MM-DD is valid');

# Accepted formats: datetime with T separator
ok(is_valid_datetime('2025-06-28T15:00'),     'YYYY-MM-DDTHH:MM is valid');
ok(is_valid_datetime('2025-06-28T15:00:45'),  'YYYY-MM-DDTHH:MM:SS is valid');

# Accepted formats: datetime with space separator
ok(is_valid_datetime('2025-06-28 15:00'),     'YYYY-MM-DD HH:MM (space sep) is valid');
ok(is_valid_datetime('2025-06-28 15:00:45'),  'YYYY-MM-DD HH:MM:SS (space sep) is valid');

# Rejected: non-ISO date orderings
ok(!is_valid_datetime('28/06/2025'),          'DD/MM/YYYY format is rejected');
ok(!is_valid_datetime('06-28-2025'),          'MM-DD-YYYY format is rejected');

# Accepted: timezone designators (DateTime::Format::ISO8601 handles these)
ok(is_valid_datetime('2025-06-28T15:00:00Z'),      'UTC Z suffix is accepted');
ok(is_valid_datetime('2025-06-28T15:00:00+01:00'), 'timezone offset is accepted');

# Rejected: semantically invalid values (regex previously accepted these)
ok(!is_valid_datetime('2025-99-01'),               'invalid month is rejected');
ok(!is_valid_datetime('2025-06-99'),               'invalid day is rejected');

# Rejected: undef and empty string must return 0, not throw
ok(!is_valid_datetime(undef), 'undef returns false without throwing');
ok(!is_valid_datetime(''),    'empty string returns false without throwing');

# ---------------------------------------------------------------------------
# load_dynamic_vocabulary -- skipped in CI / no-network environments
# ---------------------------------------------------------------------------

SKIP: {
	skip 'NO_NETWORK_TESTING is set', 4
		if $ENV{NO_NETWORK_TESTING};

	my $vocab = load_dynamic_vocabulary();

	# The return value must be a hashref, not a plain hash or list.
	isa_ok($vocab, 'HASH', 'load_dynamic_vocabulary returns a hashref');

	# A useful vocabulary contains at least a few hundred classes.
	ok(scalar(keys %{$vocab}) > 100,
		'vocabulary contains more than 100 classes');

	# Spot-check a handful of Schema.org classes that should always be present.
	for my $class (qw(Person Organization Event MusicEvent)) {
		ok(exists $vocab->{$class}, "class '$class' is present in vocabulary");
	}

	# Package globals must also be populated as a documented side-effect.
	ok(%Schema::Validator::dynamic_schema,
		'%dynamic_schema package global is populated');
	ok(%Schema::Validator::dynamic_properties,
		'%dynamic_properties package global is populated');

	# A known property should appear in the properties table.
	ok(exists $Schema::Validator::dynamic_properties{name},
		"property 'name' is present in %dynamic_properties");
}

done_testing();
