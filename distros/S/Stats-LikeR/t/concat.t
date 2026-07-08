#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # die_ok / throws_ok
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
		diag("         got: $got\n    expected: $expected; diff = $diff");
		return 0;
	}
}

#--------
# AoA: outer arrays joined in order; ragged rows kept; refs reused
#--------
{
	my $a = [ [ 1, 2 ], [ 3, 4 ]  ];
	my $b = [ [ 5, 6 ], [ 7 ]     ];      # ragged last row
	my $c = concat($a, $b);
	is(scalar @$c, 4, 'AoA: row count is the sum');
	is_deeply($c->[0], [ 1, 2 ], 'AoA: first row intact');
	is_deeply($c->[3], [ 7 ],    'AoA: ragged row preserved');
	is($c->[2], $b->[0], 'AoA: row references are reused (not copied)');
	is(scalar @$a, 2, 'AoA: source frame untouched');
}

#--------
# AoH: rows joined in order; union of columns; refs reused; sources intact
#--------
{
	my $a = [ { id => 1, x => 10 } ];
	my $b = [ { id => 2, x => 20, y => 99 } ];      # extra column y
	my $c = concat($a, $b);
	is(scalar @$c, 2, 'AoH: two rows');
	is($c->[1]{y}, 99, 'AoH: union column present on its own row');
	ok(!exists $c->[0]{y}, 'AoH: absent key stays absent (reads as undef)');
	is($c->[0], $a->[0], 'AoH: row references reused');
}

#--------
# HoA: column union (sorted); absent columns and ragged columns padded
#--------
{
	my $a = { g => [ 'a', 'a' ], v => [ 1, 2 ] };
	my $b = { g => [ 'b' ], w => [ 9 ] };            # v absent here, w new
	my $c = concat($a, $b);
	is_deeply([ sort keys %$c ], [ qw(g v w) ], 'HoA: column union');
	is(scalar @{ $c->{g} }, 3, 'HoA: g has all rows');
	is_deeply($c->{v}, [ 1, 2, undef ], 'HoA: v padded for frame lacking it');
	is_deeply($c->{w}, [ undef, undef, 9 ], 'HoA: w padded for earlier frame');
	is(scalar @{ $c->{w} }, 3, 'HoA: every column same length');
}

#--------
# HoA: ragged columns within a single frame are padded to that frame's row count
#--------
{
	my $ragged = { a => [ 1, 2, 3 ], b => [ 9 ] };
	my $c = concat($ragged);
	is(scalar @{ $c->{b} }, 3, 'HoA: short column padded to frame length');
	ok(!defined $c->{b}[2], 'HoA: padding value is undef');
}

#--------
# HoH: outer hashes merged; duplicate row names made unique + warning; refs reused
#--------
{
	my $a = { p1 => { v => 1 }, p2 => { v => 2 } };
	my $b = { p3 => { v => 3 } };
	my $c = concat($a, $b);
	is_deeply([ sort keys %$c ], [ qw(p1 p2 p3) ], 'HoH: keys merged');
	is($c->{p1}, $a->{p1}, 'HoH: inner row refs reused');

	my @warn;
	local $SIG{__WARN__} = sub { push @warn, $_[0] };
	my $dup = concat({ r => { v => 1 } }, { r => { v => 2 } });
	is_deeply([ sort keys %$dup ], [ qw(r r.1) ], 'HoH: duplicate name suffixed');
	is($dup->{r}{v},   1, 'HoH: first duplicate keeps the name');
	is($dup->{'r.1'}{v}, 2, 'HoH: second duplicate gets .1');
	ok(scalar(@warn) >= 1, 'HoH: a warning is emitted on collision');
}

#--------
# three or more frames
#--------
{
	my $c = concat([ { n => 1 } ], [ { n => 2 } ], [ { n => 3 } ]);
	is(scalar @$c, 3, 'three AoH frames concatenated');
}

#--------
# undef and empty frames are skipped; shape taken from first non-empty
#--------
{
	my $c = concat(undef, [], [ { n => 1 } ], undef, [ { n => 2 } ]);
	is(scalar @$c, 2, 'undef/empty frames skipped');

	my $empty_arr = concat([], []);
	is_deeply($empty_arr, [], 'all-empty arrays -> empty arrayref');
	my $empty_hash = concat({}, {});
	is_deeply($empty_hash, {}, 'all-empty hashes -> empty hashref');
}

#--------
# a single frame round-trips
#--------
{
	my $one = concat({ a => [ 1, 2 ], b => [ 3, 4 ] });
	is_deeply($one, { a => [ 1, 2 ], b => [ 3, 4 ] }, 'single HoA frame preserved');
}

#--------
# rbind is a true synonym of concat
#--------
{
	is(\&Stats::LikeR::rbind, \&Stats::LikeR::concat, 'rbind and concat are the same sub');
	my $c = rbind([ [ 1 ] ], [ [ 2 ] ]);
	is_deeply($c, [ [ 1 ], [ 2 ] ], 'rbind works like concat');
}

#--------
# error handling
#--------
throws_ok { concat() }
	qr/needs at least one data frame/, 'no frames dies';
throws_ok { concat([ { a => 1 } ], { a => [ 1 ] }) }
	qr/cannot mix .* frame/, 'mixing AoH and HoA dies with a hint';
throws_ok { concat('scalar') }
	qr/every frame must be an ARRAY or HASH ref/, 'scalar frame dies';
throws_ok { concat([ { a => 1 } ], [ [ 1 ] ]) }
	qr/cannot mix/, 'mixing AoH and AoA dies';

#--------
# no memory leaks across shapes
#--------
no_leaks_ok {
	concat([ [ 1, 2 ] ], [ [ 3, 4 ], [ 5 ] ]);
} 'concat(): AoA no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	concat([ { a => 1 } ], [ { a => 2, b => 3 } ]);
} 'concat(): AoH no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	concat({ g => [ 'a' ], v => [ 1 ] }, { w => [ 9 ] });
} 'concat(): HoA no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	my @w; local $SIG{__WARN__} = sub { push @w, @_ };
	concat({ r => { v => 1 } }, { r => { v => 2 } });
} 'concat(): HoH (with dup) no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	rbind([ { n => 1 } ], [ { n => 2 } ]);
} 'rbind(): no leaks' unless $INC{'Devel/Cover.pm'};

done_testing();
