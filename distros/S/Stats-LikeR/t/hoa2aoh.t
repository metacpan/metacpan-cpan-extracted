#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Scalar::Util 'looks_like_number';
use Stats::LikeR;
use Test::Exception; # die_ok
use Test::More;
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
# hoa2aoh: basic reshape
#--------
my $hoa = { id => [1, 2, 3], name => ['a', 'b', 'c'] };
my $aoh = hoa2aoh($hoa);
is_deeply($aoh,
	[ { id => 1, name => 'a' }, { id => 2, name => 'b' }, { id => 3, name => 'c' } ],
	'hoa2aoh: basic HoA -> AoH');
is(scalar @$aoh, 3, 'hoa2aoh: row count matches the column length');
is_deeply([ sort keys %{ $aoh->[0] } ], [ 'id', 'name' ],
	'hoa2aoh: every row carries all column keys');

#--------
# hoa2aoh: cells are copied, not aliased
#--------
$aoh->[0]{id} = 99;
is($hoa->{id}[0], 1, 'hoa2aoh: mutating the AoH does not touch the HoA');

#--------
# hoa2aoh: values (floats, numeric-ness, single column)
#--------
my $vals = hoa2aoh({ mpg => [21, 22.8, 18.1] });
is_approx($vals->[1]{mpg}, 22.8, 'hoa2aoh: fractional value preserved');
ok(looks_like_number($vals->[2]{mpg}), 'hoa2aoh: numeric cell stays numeric');
is(scalar @$vals, 3, 'hoa2aoh: single column yields one row per element');

#--------
# hoa2aoh: undef cells preserved
#--------
is_deeply(hoa2aoh({ x => [undef, 5] }), [ { x => undef }, { x => 5 } ],
	'hoa2aoh: undef cells preserved');

#--------
# hoa2aoh: ragged columns pad short ones with undef
#--------
is_deeply(hoa2aoh({ a => [1, 2, 3], b => [10] }),
	[ { a => 1, b => 10 }, { a => 2, b => undef }, { a => 3, b => undef } ],
	'hoa2aoh: short column padded with undef to the longest length');

#--------
# hoa2aoh: empty inputs
#--------
is_deeply(hoa2aoh({}), [], 'hoa2aoh: empty hash -> empty array');
is_deeply(hoa2aoh({ a => [], b => [] }), [], 'hoa2aoh: all-empty columns -> empty array');

#--------
# hoa2aoh: error handling
#--------
throws_ok { hoa2aoh([1, 2, 3]) } qr/hash-of-arrays/,
	'hoa2aoh: arrayref argument dies';
throws_ok { hoa2aoh('scalar') } qr/hash-of-arrays/,
	'hoa2aoh: scalar argument dies';
throws_ok { hoa2aoh({ a => [1], b => 5 }) } qr/column 'b' is not an arrayref/,
	'hoa2aoh: a non-arrayref column dies (naming the column)';
lives_ok { hoa2aoh({ a => [1, 2], b => [3, 4] }) }
	'hoa2aoh: a well-formed hash-of-arrays lives';

#--------
# hoa2aoh: memory
#--------
no_leaks_ok {
	eval { hoa2aoh({ id => [1, 2, 3], name => ['x', 'y', 'z'] }) }
} 'hoa2aoh: no memory leaks on a normal reshape' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { hoa2aoh({ a => [1, 2, 3], b => [9] }) }
} 'hoa2aoh: no memory leaks on ragged columns' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { hoa2aoh({ a => [1], b => 5 }) }
} 'hoa2aoh: no memory leaks on a die path' unless $INC{'Devel/Cover.pm'};

done_testing;
