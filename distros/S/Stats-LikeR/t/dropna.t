#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use feature 'say';
use File::Temp;
use Scalar::Util 'looks_like_number';
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

# ---------------------------------------------------------------------------
# dropna() is pure Perl and is inlined below so this test is self-contained.
# Once it lands in LikeR.pm and is exported, delete this sub and instead add
# `use Stats::LikeR;` to the header above.
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# dropna($df, cols => \@cols, how => 'any'|'all')	# NA mode
# dropna($df, rows => \@rows)						 # literal deletion
#
# $df may be:
#	AoH	 [ { A=>.., B=>.. }, ... ]			rows are 0-based indices
#	HoA	 { A=>[..], B=>[..] }				rows are 0-based indices
#	HoH	 { r1=>{ A=>.. }, r2=>{ .. } }		rows are the outer keys
#
# cols mode (NA): inspect the named columns and drop the rows that are undef
#	in them. how => 'any' (default) drops a row when any named column is undef;
#	how => 'all' drops it only when every named column is undef. Columns that
#	are not named are untouched but stay aligned (their cell at a dropped index
#	goes too). A missing key counts as undef.
#
# rows mode: delete exactly the listed rows (indices for AoH/HoA, keys for HoH);
#	no NA check. Indices/keys that aren't present are ignored.
#
# Returns a NEW top-level data frame; the original is never modified. For HoA
# the column arrays are rebuilt (cell values copied); for AoH/HoH the surviving
# row references are reused, not deep-copied (dropna never mutates a row).
# ---------------------------------------------------------------------------
sub dropna {
	my $df = shift;
	die "dropna: first argument must be a data frame (HoA/HoH hashref or AoH arrayref)\n"
		unless ref $df;
	die "dropna: arguments after the data frame must be name => value pairs\n"
		if @_ % 2;
	my %arg = @_;

	my %known = ( cols => 1, rows => 1, how => 1 );
	my @bad = sort grep { !$known{$_} } keys %arg;
	die "dropna: unknown argument(s): @bad\n" if @bad;

	my $have_cols = exists $arg{cols};
	my $have_rows = exists $arg{rows};
	die "dropna: pass exactly one of 'cols' or 'rows'\n"
		unless $have_cols xor $have_rows;

	my $sel = $have_cols ? $arg{cols} : $arg{rows};
	die "dropna: '" . ($have_cols ? 'cols' : 'rows') . "' must be an arrayref\n"
		unless ref $sel eq 'ARRAY';

	my $how = defined $arg{how} ? lc $arg{how} : 'any';
	die "dropna: 'how' must be 'any' or 'all'\n"
		unless $how eq 'any' or $how eq 'all';

	my $r = ref $df;

	#----- AoH -----
	if ($r eq 'ARRAY') {
		if ($have_rows) {						# literal index deletion
			my %drop = map { $_ => 1 } @$sel;
			return [ map { $df->[$_] } grep { !$drop{$_} } 0 .. $#$df ];
		}
		my @cols = @$sel;
		return [ @$df ] unless @cols;			# nothing to check -> keep all
		return [] unless @$df;				# empty frame -> empty result
		my %seen;
		for my $row (@$df) {
			next unless ref $row eq 'HASH';
			$seen{$_} = 1 for keys %$row;
		}
		for my $c (@cols) {
			die "dropna: column '$c' not found\n" unless $seen{$c};
		}
		my @keep;
		for my $i (0 .. $#$df) {
			my $row = $df->[$i];
			my $nundef = (ref $row eq 'HASH')
				? (grep { !defined $row->{$_} } @cols)
				: @cols;						# malformed row counts as all-NA
			my $drop = $how eq 'any' ? $nundef > 0 : $nundef == @cols;
			push @keep, $i unless $drop;
		}
		return [ map { $df->[$_] } @keep ];
	}

	#----- HoA vs HoH -----
	if ($r eq 'HASH') {
		my ($saw_arr, $saw_hash) = (0, 0);
		for my $v (values %$df) {
			next unless ref $v;
			$saw_arr++	if ref $v eq 'ARRAY';
			$saw_hash++ if ref $v eq 'HASH';
		}
		die "dropna: hashref mixes array and hash values (ambiguous HoA/HoH)\n"
			if $saw_arr and $saw_hash;

		#----- HoH -----
		if ($saw_hash) {
			if ($have_rows) {					# delete row keys
				my %drop = map { $_ => 1 } @$sel;
				return { map { $_ => $df->{$_} } grep { !$drop{$_} } keys %$df };
			}
			my @cols = @$sel;
			return { %$df } unless @cols;
			my %out;
			for my $rk (keys %$df) {
				my $row = $df->{$rk};
				my $nundef = (ref $row eq 'HASH')
					? (grep { !defined $row->{$_} } @cols)
					: @cols;
				my $drop = $how eq 'any' ? $nundef > 0 : $nundef == @cols;
				$out{$rk} = $row unless $drop;
			}
			return \%out;
		}

		#----- HoA (also the empty-hash fallthrough) -----
		my $n = 0;
		for my $v (values %$df) {
			$n = @$v if ref $v eq 'ARRAY' and @$v > $n;
		}
		if ($have_rows) {						# delete indices
			my %drop = map { $_ => 1 } @$sel;
			my @keep = grep { !$drop{$_} } 0 .. $n - 1;
			return { map { $_ => [ @{ $df->{$_} }[@keep] ] } keys %$df };
		}
		my @cols = @$sel;
		return { map { $_ => [ @{ $df->{$_} } ] } keys %$df } unless @cols;
		for my $c (@cols) {
			die "dropna: column '$c' not found\n" unless exists $df->{$c};
		}
		my @keep;
		for my $i (0 .. $n - 1) {
			my $nundef = grep { !defined $df->{$_}[$i] } @cols;
			my $drop = $how eq 'any' ? $nundef > 0 : $nundef == @cols;
			push @keep, $i unless $drop;
		}
		return { map { $_ => [ @{ $df->{$_} }[@keep] ] } keys %$df };
	}

	die "dropna: data frame must be an arrayref (AoH) or hashref (HoA/HoH)\n";
}

#--------
# HoA cols (the motivating example, how => 'any' default)
#--------
{
	my $df = { A => [1, 2, undef], B => [1, 2, 3], C => [undef, 2, 4] };
	my $out = dropna($df, cols => ['A', 'B']);
	is_deeply($out, { A => [1, 2], B => [1, 2], C => [undef, 2] },
		'HoA cols: drop index 2 (A undef); C not checked but realigned');
	is_deeply($df, { A => [1, 2, undef], B => [1, 2, 3], C => [undef, 2, 4] },
		'HoA cols: original data frame untouched');
}

#--------
# HoA how => 'any' vs 'all'
#--------
{
	my $df = { A => [1, undef, undef], B => [9, 2, undef] };
	is_deeply(dropna($df, cols => ['A', 'B'], how => 'any'),
		{ A => [1], B => [9] }, 'HoA how=any drops rows 1 and 2');
	is_deeply(dropna($df, cols => ['A', 'B'], how => 'all'),
		{ A => [1, undef], B => [9, 2] }, 'HoA how=all drops only the all-undef row');
}

#--------
# HoA rows (literal index deletion, no NA logic)
#--------
{
	my $df = { A => [10, 20, 30, 40], B => ['a', 'b', 'c', 'd'] };
	is_deeply(dropna($df, rows => [1, 3]),
		{ A => [10, 30], B => ['a', 'c'] }, 'HoA rows: delete indices 1 and 3');
	is_deeply(dropna($df, rows => [99]),
		{ A => [10, 20, 30, 40], B => ['a', 'b', 'c', 'd'] },
		'HoA rows: an out-of-range index is ignored');
}

#--------
# AoH cols and rows
#--------
{
	my $df = [ { A => 1, B => 1 }, { A => undef, B => 2 }, { A => 3, B => undef } ];
	is_deeply(dropna($df, cols => ['A']),
		[ { A => 1, B => 1 }, { A => 3, B => undef } ],
		'AoH cols: drop the A-undef row');
	is_deeply(dropna($df, cols => ['A', 'B'], how => 'any'),
		[ { A => 1, B => 1 } ], 'AoH cols any over A and B');
	is_deeply(dropna($df, rows => [0, 2]),
		[ { A => undef, B => 2 } ], 'AoH rows: delete indices 0 and 2');
}

#--------
# HoH cols and rows
#--------
{
	my $df = { r1 => { A => 1, B => 2 }, r2 => { A => undef, B => 5 }, r3 => { A => 7, B => 8 } };
	is_deeply(dropna($df, cols => ['A']),
		{ r1 => { A => 1, B => 2 }, r3 => { A => 7, B => 8 } },
		'HoH cols: drop r2 (A undef)');
	is_deeply(dropna($df, rows => ['r1', 'r3']),
		{ r2 => { A => undef, B => 5 } }, 'HoH rows: delete keys r1 and r3');
}

#--------
# values survive intact (numeric cells)
#--------
{
	my $df = { mpg => [21, 22.8, undef], gear => [4, 3, 5] };
	my $out = dropna($df, cols => ['mpg']);
	is_approx($out->{mpg}[1], 22.8, 'surviving fractional value intact');
	ok(looks_like_number($out->{mpg}[0]), 'surviving cell is still numeric');
	is_deeply($out->{gear}, [4, 3], 'unchecked column realigned to survivors');
}

#--------
# empty / edge
#--------
is_deeply(dropna([], cols => ['A']), [], 'empty AoH -> empty');
is_deeply(dropna({}, rows => [0]), {}, 'empty HoA -> empty');
is_deeply(dropna({ A => [1, 2] }, cols => []), { A => [1, 2] }, 'empty cols subset keeps all');

#--------
# errors
#--------
throws_ok { dropna('scalar', cols => ['A']) } qr/data frame/,
	'scalar data frame dies';
throws_ok { dropna({ A => [1] }, cols => ['A'], rows => [0]) } qr/exactly one/,
	'both cols and rows dies';
throws_ok { dropna({ A => [1] }) } qr/exactly one/,
	'neither cols nor rows dies';
throws_ok { dropna({ A => [1] }, cols => 'A') } qr/must be an arrayref/,
	'non-arrayref selector dies';
throws_ok { dropna({ A => [1] }, cols => ['Z']) } qr/column 'Z' not found/,
	'a missing column dies';
throws_ok { dropna({ A => [1] }, cols => ['A'], how => 'maybe') } qr/'how' must be/,
	'an invalid how dies';
throws_ok { dropna({ A => [1] }, foo => 1) } qr/unknown argument/,
	'an unknown argument dies';
throws_ok { dropna({ A => [1], r => { x => 1 } }, cols => ['A']) } qr/ambiguous/,
	'a hashref mixing arrays and hashes dies';
lives_ok { dropna({ A => [1, undef] }, cols => ['A']) }
	'a well-formed call lives';

#--------
# memory
#--------
no_leaks_ok {
	my $x = dropna({ A => [1, 2, undef], B => [1, 2, 3] }, cols => ['A']);
} 'dropna: no memory leaks (HoA cols)' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	my $x = dropna([ { A => 1 }, { A => undef } ], cols => ['A']);
} 'dropna: no memory leaks (AoH cols)' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { dropna({ A => [1] }, cols => ['Z']) };
} 'dropna: no memory leaks (die path)' unless $INC{'Devel/Cover.pm'};

done_testing;
