#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # dies_ok / lives_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';
# Gemini helped to write some of the tests
# Custom helper for floating-point comparisons
sub is_approx {
	my ($got, $expected, $test_name, $epsilon) = @_;
	$epsilon = 1e-7 if not defined $epsilon;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	my $i = 0;
	foreach my $arg ($got, $expected, $test_name) {
		next if defined $arg;
		die "\$arg[$i] (see subroutine signature for name) isn't defined in $current_sub";
		$i++;
	}
	my $diff = abs($got - $expected);
	if ($diff <= $epsilon) {
		pass("$test_name: within $epsilon");
		return 1;
	} else {
		fail($test_name);
		diag("         got: $got\n    expected: $expected; diff = $diff");
		return 0;
	}
}

dies_ok {
	value_counts(\1);
} 'unsupported top-level reference (SCALAR ref) dies';

#
# CASE 1: flattened scalar list
#
is_deeply(
	value_counts(qw/a a b/),
	{ a => 2, b => 1 },
	'CASE 1: flattened scalar list'
);
is_deeply(
	value_counts('solo'),
	{ solo => 1 },
	'CASE 1: single scalar'
);

# ---------------------------------------------------------------------------
# CASE 2a: flat array ref, no key
# ---------------------------------------------------------------------------
is_deeply(
	value_counts([qw/a b a c b a/]),
	{ a => 3, b => 2, c => 1 },
	'CASE 2a: flat array ref'
);

# ---------------------------------------------------------------------------
# CASE 2b: Array of Hashes (NEW) -- count a column by its key
# ---------------------------------------------------------------------------
my @aoh = (
	{ name => 'Alice', dept => 'Sales' },
	{ name => 'Bob',   dept => 'Eng'   },
	{ name => 'Carol', dept => 'Sales' },
	{ name => 'Dan'                    },   # row missing 'dept' -> skipped
);
is_deeply(
	value_counts(\@aoh, 'dept'),
	{ Sales => 2, Eng => 1 },
	'CASE 2b: Array of Hashes by key, missing key skipped'
);
is_deeply(
	value_counts(\@aoh, 'name'),
	{ Alice => 1, Bob => 1, Carol => 1, Dan => 1 },
	'CASE 2b: Array of Hashes, all-unique key'
);

# numeric-looking VALUES are still counted (the key is a string, not an index)
my @aoh_num = ( { v => 1 }, { v => 1 }, { v => 2 } );
is_deeply(
	value_counts(\@aoh_num, 'v'),
	{ 1 => 2, 2 => 1 },
	'CASE 2b: Array of Hashes with numeric values'
);

# empty AoH -> empty result
is_deeply(
	value_counts([], 'dept'),
	{},
	'CASE 2b: empty array ref with key'
);

#
# CASE 2b: Array of Arrays (NEW) -- count a column by its numeric index
#
my @aoa = ([1, 'x'], [2, 'y'], [3, 'x']);
is_deeply(
	value_counts(\@aoa, 1),
	{ 'x' => 2, 'y' => 1 },
	'CASE 2b: Array of Arrays by numeric index'
);

# ---------------------------------------------------------------------------
# CASE 2b: croak paths for keyed-array mode (NEW)
# ---------------------------------------------------------------------------
dies_ok {
	value_counts([1, 2, 3], 'k');
} 'CASE 2b: keyed flat (scalar element) array dies';

dies_ok {
	value_counts([[1, 2]], 'notnum');
} 'CASE 2b: Array of Arrays with non-numeric index dies';

dies_ok {
	value_counts([sub { 1 }], 'k');
} 'CASE 2b: array of CODE refs with key dies';

# ---------------------------------------------------------------------------
# CASE 3: hash ref, no key
# ---------------------------------------------------------------------------
is_deeply(
	value_counts({ x => 'a', y => 'b', z => 'a' }),
	{ a => 2, b => 1 },
	'CASE 3: hash ref of scalars'
);
is_deeply(
	value_counts({ g1 => [qw/a a/], g2 => [qw/a b/] }),
	{ a => 3, b => 1 },
	'CASE 3: hash of arrays counts all elements'
);
is_deeply(
	value_counts({ r1 => { a => 'x', b => 'y' }, r2 => { a => 'x' } }),
	{ x => 2, y => 1 },
	'CASE 3: hash of hashes counts all inner values'
);
dies_ok {
	value_counts({ bad => \1 });
} 'CASE 3: unsupported nested reference type dies';

# ---------------------------------------------------------------------------
# CASES 4 & 5: nested hash with a key argument
# ---------------------------------------------------------------------------
# Column-oriented (DataFrame style): key maps directly to an array ref
is_deeply(
	value_counts({ dept => [qw/Sales Eng Sales/], name => [qw/A B C/] }, 'dept'),
	{ Sales => 2, Eng => 1 },
	'Column-oriented hash by key'
);
# CASE 5: Hash of Hashes, row-oriented, by key
is_deeply(
	value_counts(
		{ r1 => { dept => 'Sales' }, r2 => { dept => 'Eng' }, r3 => { dept => 'Sales' } },
		'dept'
	),
	{ Sales => 2, Eng => 1 },
	'CASE 5: Hash of Hashes by key'
);
# CASE 4: Hash of Arrays, row-oriented, by numeric index
is_deeply(
	value_counts(
		{ r1 => [99, 'x'], r2 => [99, 'y'], r3 => [99, 'x'] },
		1
	),
	{ x => 2, y => 1 },
	'CASE 4: Hash of Arrays by numeric index'
);

# ---------------------------------------------------------------------------
# Return shape
# ---------------------------------------------------------------------------
is(ref value_counts([qw/a b/]), 'HASH', 'returns a HASH ref');

# ---------------------------------------------------------------------------
# Leak checks: representative success AND croak paths
# ---------------------------------------------------------------------------
no_leaks_ok { value_counts(\@aoh, 'dept') }             'no leak: Array of Hashes';
no_leaks_ok { value_counts(\@aoa, 1) }                  'no leak: Array of Arrays';
no_leaks_ok { value_counts([qw/a b a c/]) }             'no leak: flat array ref';
no_leaks_ok { value_counts({ a => 1, b => 1 }) }        'no leak: hash ref no key';
no_leaks_ok { eval { value_counts([1, 2], 'k') } }      'no leak: croak on keyed scalar array';
no_leaks_ok { eval { value_counts([[1]], 'x') } }       'no leak: croak on AoA non-numeric index';
no_leaks_ok { eval { value_counts([sub { 1 }], 'k') } } 'no leak: croak on bad nested array ref';
no_leaks_ok { eval { value_counts(\1) } }               'no leak: croak on unsupported top-level ref';

done_testing;
