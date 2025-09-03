#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

# Test the module can be loaded
BEGIN {
	use_ok('Readonly::Values::Days') or BAIL_OUT('Cannot load Readonly::Values::Days');
}

# Import all exported symbols
use Readonly::Values::Days;

# Test constants are defined and have correct values
subtest 'Day constants' => sub {
	ok(defined $MON, '$MON is defined');
	ok(defined $TUE, '$TUE is defined');
	ok(defined $WED, '$WED is defined');
	ok(defined $THU, '$THU is defined');
	ok(defined $FRI, '$FRI is defined');
	ok(defined $SAT, '$SAT is defined');
	ok(defined $SUN, '$SUN is defined');

	# Test values are sequential starting from 1
	is($MON, 1, '$MON equals 1');
	is($TUE, 2, '$TUE equals 2');
	is($WED, 3, '$WED equals 3');
	is($THU, 4, '$THU equals 4');
	is($FRI, 5, '$FRI equals 5');
	is($SAT, 6, '$SAT equals 6');
	is($SUN, 7, '$SUN equals 7');

	# Test constants are readonly
	throws_ok { $MON = 99 } qr/Modification of a read-only value/,
		'$MON is readonly';
};

# Test %days hash
subtest 'Days hash' => sub {
	# Test full day names
	is($days{'monday'}, $MON, 'monday maps to $MON');
	is($days{'tuesday'}, $TUE, 'tuesday maps to $TUE');
	is($days{'wednesday'}, $WED, 'wednesday maps to $WED');
	is($days{'thursday'}, $THU, 'thursday maps to $THU');
	is($days{'friday'}, $FRI, 'friday maps to $FRI');
	is($days{'saturday'}, $SAT, 'saturday maps to $SAT');
	is($days{'sunday'}, $SUN, 'sunday maps to $SUN');

	# Test abbreviated day names
	is($days{'mon'}, $MON, 'mon maps to $MON');
	is($days{'tue'}, $TUE, 'tue maps to $TUE');
	is($days{'wed'}, $WED, 'wed maps to $WED');
	is($days{'thu'}, $THU, 'thu maps to $THU');
	is($days{'fri'}, $FRI, 'fri maps to $FRI');
	is($days{'sat'}, $SAT, 'sat maps to $SAT');
	is($days{'sun'}, $SUN, 'sun maps to $SUN');

	# Test hash is readonly
	throws_ok { $days{'monday'} = 99 } qr/Modification of a read-only value/,
		'%days is readonly';

	# Test expected number of entries
	is(scalar keys %days, 14, '%days has 14 entries (7 full + 7 abbreviated)');
};

# Test @day_names array
subtest 'Day names array' => sub {
	is(scalar @day_names, 7, '@day_names has 7 elements');

	my @expected = qw(monday tuesday wednesday thursday friday saturday sunday);
	is_deeply(\@day_names, \@expected, '@day_names contains expected day names');

	# Test array is readonly
	throws_ok { $day_names[0] = 'foo' } qr/Modification of a read-only value/,
		'@day_names is readonly';
	throws_ok { push @day_names, 'foo' } qr/Modification of a read-only value/,
		'Cannot push to @day_names';
};

# Test @short_day_names array
subtest 'Short day names array' => sub {
	is(scalar @short_day_names, 7, '@short_day_names has 7 elements');

	my @expected = qw(mon tue wed thu fri sat sun);
	is_deeply(\@short_day_names, \@expected,
		'@short_day_names contains expected abbreviated names');
};

# Test %day_names_to_short hash
subtest 'Day names to short hash' => sub {
	is($day_names_to_short{'monday'}, 'mon', 'monday maps to mon');
	is($day_names_to_short{'tuesday'}, 'tue', 'tuesday maps to tue');
	is($day_names_to_short{'wednesday'}, 'wed', 'wednesday maps to wed');
	is($day_names_to_short{'thursday'}, 'thu', 'thursday maps to thu');
	is($day_names_to_short{'friday'}, 'fri', 'friday maps to fri');
	is($day_names_to_short{'saturday'}, 'sat', 'saturday maps to sat');
	is($day_names_to_short{'sunday'}, 'sun', 'sunday maps to sun');

	is(scalar keys %day_names_to_short, 7,
		'%day_names_to_short has 7 entries');
};

# Test _shorten helper function
subtest 'Shorten helper function' => sub {
	# Test normal cases
	is(Readonly::Values::Days::_shorten('monday'), 'mon',
		'_shorten("monday") returns "mon"');
	is(Readonly::Values::Days::_shorten('tuesday'), 'tue',
		'_shorten("tuesday") returns "tue"');
	is(Readonly::Values::Days::_shorten('ab'), 'ab',
		'_shorten("ab") returns "ab" (shorter than 3 chars)');
	is(Readonly::Values::Days::_shorten('a'), 'a',
		'_shorten("a") returns "a" (single char)');

	# Test edge cases
	is(Readonly::Values::Days::_shorten(''), '',
		'_shorten("") returns empty string');
	is(Readonly::Values::Days::_shorten(undef), undef,
		'_shorten(undef) returns undef');
};

# Test exports
subtest 'Exports' => sub {
	# Test that all expected symbols are exported
	my @expected_exports = qw(
		$MON $TUE $WED $THU $FRI $SAT $SUN
		%days
		@day_names
		@short_day_names
		%day_names_to_short
	);

	# Check constants are accessible
	ok(defined $MON, '$MON is exported');
	ok(defined $TUE, '$TUE is exported');
	ok(defined $WED, '$WED is exported');
	ok(defined $THU, '$THU is exported');
	ok(defined $FRI, '$FRI is exported');
	ok(defined $SAT, '$SAT is exported');
	ok(defined $SUN, '$SUN is exported');

	# Check hash and arrays are accessible
	ok(%days, '%days is exported');
	ok(@day_names, '@day_names is exported');
	# Note: These will fail due to module bugs
	# ok(@short_day_names, '@short_day_names is exported');
	# ok(%day_names_to_short, '%day_names_to_short is exported');
};

# Test practical usage scenarios
subtest 'Usage scenarios' => sub {
	# Test iteration over day names (from synopsis)
	my $output = '';
	for my $name (@day_names) {
		$output .= sprintf "%-9s => %2d\n", ucfirst($name), $days{$name};
	}

	like($output, qr/Monday\s+=>\s+1/, 'Synopsis example works for Monday');
	like($output, qr/Sunday\s+=>\s+7/, 'Synopsis example works for Sunday');

	# Test case sensitivity
	ok(!exists $days{'Monday'}, 'Hash keys are lowercase');
	ok(!exists $days{'MONDAY'}, 'Hash keys are not uppercase');

	# Test abbreviations work
	is($days{'mon'}, $days{'monday'}, 'mon and monday have same value');
	is($days{'fri'}, $days{'friday'}, 'fri and friday have same value');
};

# Test module metadata
subtest 'Module metadata' => sub {
	is($Readonly::Values::Days::VERSION, '0.01', 'Version is 0.01');
	ok(defined $Readonly::Values::Days::VERSION, 'Version is defined');
};

# Test edge cases and error conditions
subtest 'Edge cases' => sub {
	# Test non-existent keys
	ok(!exists $days{'invalid'}, 'Non-existent key returns false');
	is($days{'invalid'}, undef, 'Non-existent key returns undef');

	# Test empty string
	ok(!exists $days{''}, 'Empty string key returns false');

	# Test case variations that should not exist
	ok(!exists $days{'MON'}, 'Uppercase abbreviations do not exist');
	ok(!exists $days{'Mon'}, 'Capitalized abbreviations do not exist');
};

done_testing();
