#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Test::Exception; # dies_ok
use Test::More;
use Stats::LikeR;
use Test::LeakTrace 'no_leaks_ok';
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
		diag("		   got: $got\n	  expected: $expected; diff = $diff");
		return 0;
	}
}

#--------
# test data shapes
#--------
my $aoh = [
	{ id => 1, val => 10, tag => 'A' },
	{ id => 2, val => 20, tag => 'B' },
	{ id => 3 },							# intentionally missing 'val'
];
my $hoa = {
	id	=> [1, 2, 3],
	val => [10, 20, undef],
	tag => ['A', 'B', 'C'],
};
my $hoh = {
	row_c => { id => 3, val => 30, tag => 'C' },
	row_a => { id => 1, val => 10, tag => 'A' },
	row_b => { id => 2, val => 20, tag => 'B' },
	row_d => { id => 4 },					# intentionally missing 'val'
};

#--------
# AoH
#--------
my $res_aoh = vals($aoh, 'val');
no_leaks_ok { vals($aoh, 'val') } 'vals(AoH): no memory leaks' unless $INC{'Devel/Cover.pm'};
is(ref $res_aoh, 'ARRAY', 'vals(AoH) returns an array reference');
is(scalar @$res_aoh, 3, 'vals(AoH) returns the column length');
is_deeply($res_aoh, [10, 20, undef], 'vals(AoH) extracts the column, missing cell -> undef');

#--------
# HoA
#--------
my $res_hoa = vals($hoa, 'val');
no_leaks_ok { vals($hoa, 'val') } 'vals(HoA): no memory leaks' unless $INC{'Devel/Cover.pm'};
is(ref $res_hoa, 'ARRAY', 'vals(HoA) returns an array reference');
is_deeply($res_hoa, [10, 20, undef], 'vals(HoA) extracts the column, explicit undef preserved');
dies_ok { vals($hoa, 'missing_col') } 'vals(HoA) dies on a non-existent column';
no_leaks_ok { eval { vals($hoa, 'missing_col') } } 'vals(HoA) croak path: no leak' unless $INC{'Devel/Cover.pm'};

#--------
# HoH (values returned in sorted-key order)
#--------
my $res_hoh = vals($hoh, 'val');
no_leaks_ok { vals($hoh, 'val') } 'vals(HoH): no memory leaks' unless $INC{'Devel/Cover.pm'};
is(ref $res_hoh, 'ARRAY', 'vals(HoH) returns an array reference');
is(scalar @$res_hoh, 4, 'vals(HoH) returns the row count');
is_deeply($res_hoh, [10, 20, 30, undef], 'vals(HoH) in alphabetical key order (row_a..row_d), missing -> undef');
# sort must be a real string sort, not just first-char
my $sorted = vals({ a => { v => 1 }, ab => { v => 2 }, b => { v => 3 } }, 'v');
is_deeply($sorted, [1, 2, 3], 'vals(HoH) sorts keys as strings (a < ab < b)');

#--------
# the result is an independent copy: mutating it must NOT touch the source
#--------
{
	my $src_aoh = [ { val => 10 }, { val => 20 } ];
	my $v = vals($src_aoh, 'val'); $v->[0] = 999;
	is($src_aoh->[0]{val}, 10, 'vals(AoH) result is independent of the source');

	my $src_hoa = { val => [10, 20] };
	my $w = vals($src_hoa, 'val'); $w->[0] = 999;
	is($src_hoa->{val}[0], 10, 'vals(HoA) result is independent of the source');

	my $src_hoh = { a => { val => 10 }, b => { val => 20 } };
	my $x = vals($src_hoh, 'val'); $x->[0] = 999;
	is($src_hoh->{a}{val}, 10, 'vals(HoH) result is independent of the source');
}

#--------
# undef cells are writable (not the shared read-only PL_sv_undef)
#--------
{
	my $r = vals([ { val => 1 }, { id => 2 } ], 'val');	  # slot 1 is a missing cell
	lives_ok { $r->[1] = 5 } 'vals: a missing/undef slot is a writable scalar';
}

#--------
# leniency vs strictness for an entirely-absent column
#--------
is_deeply(vals([ { id => 1 }, { id => 2 } ], 'val'), [undef, undef],
	'vals(AoH) absent column -> all undef (per-row, lenient)');
is_deeply(vals({ a => { id => 1 }, b => { id => 2 } }, 'val'), [undef, undef],
	'vals(HoH) absent column -> all undef (per-row, lenient)');
dies_ok { vals({ id => [1, 2], tag => ['A', 'B'] }, 'val') }
	'vals(HoA) absent column -> dies (column is structural)';

#--------
# malformed AoH element (not a hashref) yields undef, not a crash
#--------
is_deeply(vals([ { val => 1 }, 5, { val => 3 } ], 'val'), [1, undef, 3],
	'vals(AoH) non-hash element -> undef');

#--------
# argument validation
#--------
dies_ok { vals('not_a_ref', 'val') } 'vals dies on a non-reference data frame';
dies_ok { vals($aoh) }				 'vals dies when the column argument is missing';
dies_ok { vals($aoh, undef) }		 'vals dies when the column name is undef';

#--------
# empty frames
#--------
is_deeply(vals([], 'col'), [], 'vals on an empty AoH yields []');
is_deeply(vals({}, 'col'), [], 'vals on an empty hash yields []');

done_testing();
