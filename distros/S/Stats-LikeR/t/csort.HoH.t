#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use feature 'say';
use Test::Exception; # dies_ok
use Test::More;
use Stats::LikeR;
use Test::LeakTrace 'no_leaks_ok';

# Provided your module exports csort
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
# Setup basic test HoH
# --------
my $hoh_data = {
 row_c => { id => 3, val => 30, tag => 'C' },
 row_a => { id => 1, val => 10, tag => 'A' },
 row_b => { id => 2, val => 20, tag => 'B' }
};

# --------
# 1. Default output for HoH (AoH) sorted by column name
# --------
my $res_aoh = csort($hoh_data, 'val');
no_leaks_ok {
	csort($hoh_data, 'val');
} 'csort(HoH) by column name: no memory leaks' unless $INC{'Devel/Cover.pm'};
is(ref $res_aoh, 'ARRAY', 'csort(HoH) safely defaults to Array-of-Hashes (AoH) output');
is(scalar @$res_aoh, 3, 'All rows returned');
is($res_aoh->[0]{id}, 1, 'First returned row has ID 1');
is($res_aoh->[1]{id}, 2, 'Second returned row has ID 2');
is($res_aoh->[2]{id}, 3, 'Third returned row has ID 3');
# --------
# 2. Output as HoA sorted using coderef comparator
# --------
no warnings 'once';
my $res_hoa = csort($hoh_data, sub { $b->{id} <=> $a->{id} }, 'hoa');
no_leaks_ok {
	csort($hoh_data, sub { $b->{id} <=> $a->{id} }, 'hoa');
} 'csort(HoH, hoa) descending via coderef: no memory leaks' unless $INC{'Devel/Cover.pm'};
is(ref $res_hoa, 'HASH', 'csort(HoH, hoa) returns Hash-of-Arrays (HoA) output successfully');
is_deeply($res_hoa->{id},  [3, 2, 1],         'Column ID correctly mapped and sorted descending');
is_deeply($res_hoa->{val}, [30, 20, 10],      'Values vector aligns cleanly with sorted ID row index');
is_deeply($res_hoa->{tag}, ['C', 'B', 'A'],   'String tags follow identical positional sort logic');
# --------
# 3. Handling Edge Cases
# --------
my $empty_hoh = csort({}, 'missing_col');
is(ref $empty_hoh, 'HASH', 'Sorting an empty hash gracefully returns an empty AoH');
is(scalar keys %{ $empty_hoh }, 0, 'Empty AoH length confirmed');

# --------
# 4. Input Exceptions
# --------
dies_ok { csort({ a => 'string' }, 'val') } 
    'csort properly croaks on invalid top-level Hash containing scalars instead of Hash/Arrays';

dies_ok { csort({ a => { v => 1}, b => [1] }, 'v') }
    'csort catches malformed structures with mixed HoH/HoA types internally';

done_testing();
