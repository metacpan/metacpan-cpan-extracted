#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Test::Exception; # dies_ok
use Test::More;
use Stats::LikeR;
use Test::LeakTrace 'no_leaks_ok';

# Assume Stats::LikeR handles the `vals` export natively in your build.
# use Stats::LikeR;

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

# --------
# Setup Test Data Shapes
# --------
my $aoh = [
 { id => 1, val => 10, tag => 'A' },
 { id => 2, val => 20, tag => 'B' },
 { id => 3 } # intentional missing 'val'
];


my $hoa = {
 id  => [1, 2, 3],
 val => [10, 20, undef],
 tag => ['A', 'B', 'C']
};

my $hoh = {
 row_c => { id => 3, val => 30, tag => 'C' },
 row_a => { id => 1, val => 10, tag => 'A' },
 row_b => { id => 2, val => 20, tag => 'B' },
 row_d => { id => 4 } # intentional missing 'val'
};

# --------
# Array of Hashes (AoH) Tests
# --------
my $res_aoh = vals($aoh, 'val');
no_leaks_ok {
	vals($aoh, 'val');
} 'vals(AoH): no memory leaks' unless $INC{'Devel/Cover.pm'};

is(ref $res_aoh, 'ARRAY', 'vals(AoH) successfully returns an array reference');
is(scalar @$res_aoh, 3, 'vals(AoH) returns the correct column length');
is($res_aoh->[0], 10, 'vals(AoH) element 0 extracted correctly');
is($res_aoh->[1], 20, 'vals(AoH) element 1 extracted correctly');
is($res_aoh->[2], undef, 'vals(AoH) missing cell safely yields undef');

# --------
# Hash of Arrays (HoA) Tests
# --------
my $res_hoa = vals($hoa, 'val');
no_leaks_ok {
    vals($hoa, 'val');
} 'vals(HoA): no memory leaks' unless $INC{'Devel/Cover.pm'};

is(ref $res_hoa, 'ARRAY', 'vals(HoA) successfully returns an array reference');
is(scalar @$res_hoa, 3, 'vals(HoA) returns the correct column length');
is($res_hoa->[0], 10, 'vals(HoA) element 0 extracted correctly');
is($res_hoa->[1], 20, 'vals(HoA) element 1 extracted correctly');
is($res_hoa->[2], undef, 'vals(HoA) explicit undef element extracted safely');

dies_ok { vals($hoa, 'missing_col') } 'vals(HoA) gracefully dies when asked for a non-existent column';

# --------
# Hash of Hashes (HoH) Tests
# --------
my $res_hoh = vals($hoh, 'val');
no_leaks_ok {
	vals($hoh, 'val');
} 'vals(HoH): no memory leaks' unless $INC{'Devel/Cover.pm'};

is(ref $res_hoh, 'ARRAY', 'vals(HoH) successfully returns an array reference');
is(scalar @$res_hoh, 4, 'vals(HoH) returns the correct column length');
# Expect alphabetical alignment: row_a, row_b, row_c, row_d
is($res_hoh->[0], 10, 'vals(HoH) row_a extracted in proper alphabetical order');
is($res_hoh->[1], 20, 'vals(HoH) row_b extracted in proper alphabetical order');
is($res_hoh->[2], 30, 'vals(HoH) row_c extracted in proper alphabetical order');
is($res_hoh->[3], undef, 'vals(HoH) row_d (missing) safely yields undef');

# --------
# General Exceptions and Edge Cases
# --------
dies_ok { vals('not_a_ref', 'val') } 'vals properly croaks on string instead of reference';
dies_ok { vals($aoh) } 'vals properly croaks when missing column argument';

my $empty_aoh = vals([], 'col');
is_deeply($empty_aoh, [], 'vals on an empty AoH yields a clean empty arrayref');

my $empty_hash = vals({}, 'col');
is_deeply($empty_hash, [], 'vals on an empty HoA/HoH yields a clean empty arrayref');

done_testing();
