#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
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
# AoH input: default preserves shape, rows are shared, input untouched
#--------
{
	my $aoh = [ { id => 1, grp => 'a' }, { id => 2, grp => 'b' }, { id => 3, grp => 'a' } ];
	my $r = filter($aoh, sub { $_->{grp} eq 'a' });
	is(ref $r, 'ARRAY', 'AoH in -> AoH out by default');
	is(scalar @$r, 2, 'AoH: two rows kept');
	is_deeply([ map { $_->{id} } @$r ], [1, 3], 'AoH: correct rows, order preserved');
	is($r->[0], $aoh->[0], 'AoH: kept row is the SAME hashref (shared, not copied)');
	is(scalar @$aoh, 3, 'AoH: the input frame is not modified');
}

#--------
# HoA input: columns filtered in parallel and stay aligned
#--------
{
	my $hoa = { id => [1, 2, 3], grp => [qw(a b a)] };
	my $r = filter($hoa, sub { $_->{id} >= 2 });
	is(ref $r, 'HASH', 'HoA in -> HoA out by default');
	is_deeply($r->{id},	 [2, 3],	 'HoA: id column filtered');
	is_deeply($r->{grp}, ['b', 'a'], 'HoA: grp column filtered in parallel');
	is(scalar @{ $r->{id} }, scalar @{ $r->{grp} }, 'HoA: columns stay aligned');
	is_deeply($hoa->{id}, [1, 2, 3], 'HoA: the input frame is not modified');
}

#--------
# HoH input (new): default preserves keys, inner rows shared
#--------
{
	my $hoh = { r1 => { id => 1 }, r2 => { id => 2 }, r3 => { id => 3 } };
	my $r = filter($hoh, sub { $_->{id} != 2 });
	is(ref $r, 'HASH', 'HoH in -> HoH out by default');
	is_deeply([ sort keys %$r ], ['r1', 'r3'], 'HoH: matching keys preserved');
	is($r->{r1}{id}, 1, 'HoH: row data intact');
	is($r->{r1}, $hoh->{r1}, 'HoH: kept inner hash is shared');
	is(scalar keys %$hoh, 3, 'HoH: the input frame is not modified');
}

#--------
# output.type converts between shapes (rows/keys order may differ for HoH)
#--------
{
	my $aoh = [ { id => 1, grp => 'a' }, { id => 2, grp => 'b' } ];
	my $hoa = { id => [1, 2], grp => ['a', 'b'] };
	my $hoh = { r1 => { id => 1, grp => 'a' }, r2 => { id => 2, grp => 'b' } };
	my $all = sub { 1 };

	my $a2h = filter($aoh, $all, 'output.type' => 'hoa');
	is(ref $a2h, 'HASH', 'AoH -> hoa: hash out');
	is_deeply($a2h->{id},  [1, 2],	   'AoH -> hoa: id column, row order preserved');
	is_deeply($a2h->{grp}, ['a', 'b'], 'AoH -> hoa: grp column');

	my $h2a = filter($hoa, $all, 'output.type' => 'aoh');
	is(ref $h2a, 'ARRAY', 'HoA -> aoh: array out');
	is_deeply([ map { $_->{id} } @$h2a ], [1, 2], 'HoA -> aoh: rows, order preserved');

	my $hh2a = filter($hoh, $all, 'output.type' => 'aoh');
	is(ref $hh2a, 'ARRAY', 'HoH -> aoh: array out');
	is_deeply([ sort map { $_->{id} } @$hh2a ], [1, 2], 'HoH -> aoh: inner rows kept');

	my $hh2h = filter($hoh, $all, 'output.type' => 'hoa');
	is(ref $hh2h, 'HASH', 'HoH -> hoa: hash out');
	is_deeply([ sort { $a <=> $b } @{ $hh2h->{id} } ], [1, 2], 'HoH -> hoa: id column');
}

#--------
# output type may be given bare or via the 'out' alias
#--------
{
	my $aoh = [ { x => 1 }, { x => 2 } ];
	is(ref filter($aoh, sub { 1 }, 'hoa'),		  'HASH', 'bare positional output type');
	is(ref filter($aoh, sub { 1 }, out => 'hoa'), 'HASH', "'out' alias for output.type");
}

#--------
# the predicate sees the row as both $_ and $_[0]
#--------
{
	my $aoh = [ { x => 1, y => undef }, { x => 2, y => 5 } ];
	is_deeply([ map { $_->{x} } @{ filter($aoh, sub { defined $_->{y} }) } ], [2],
		'predicate via $_ (undef cell handled in the sub)');
	is_deeply([ map { $_->{x} } @{ filter($aoh, sub { $_[0]{x} == 1 }) } ], [1],
		'predicate via $_[0]');
}

#--------
# keep-all / keep-none for every shape
#--------
{
	my $aoh = [ { x => 1 }, { x => 2 } ];
	my $hoa = { x => [1, 2] };
	my $hoh = { a => { x => 1 }, b => { x => 2 } };
	is(scalar @{ filter($aoh, sub { 1 }) }, 2, 'keep-all AoH returns all rows');
	is_deeply(filter($aoh, sub { 0 }), [], 'keep-none AoH -> []');
	is_deeply(filter($hoa, sub { 0 }), { x => [] }, 'keep-none HoA -> columns with empty arrays');
	is_deeply(filter($hoh, sub { 0 }), {}, 'keep-none HoH -> {}');
}

#--------
# empty inputs
#--------
{
	is_deeply(filter([], sub { 1 }), [], 'empty AoH stays []');
	is_deeply(filter({}, sub { 1 }), {}, 'empty hash stays {}');
	is_deeply(filter({}, sub { 1 }, 'output.type' => 'aoh'), [], 'empty hash -> aoh gives []');
}

#--------
# col() predicate: operators, operand order, combinators, undef rule
#--------
{
	my $df = [
		{ id => 1, age => 20, grp => "a" },
		{ id => 2, age => 17, grp => "b" },
		{ id => 3, age => 25, grp => "a" },
	];
	is_deeply([ map { $_->{id} } @{ filter($df, col("age") >= 18) } ], [1, 3], "col: numeric >=");
	is_deeply([ map { $_->{id} } @{ filter($df, 18 <= col("age")) } ], [1, 3], "col: operand order (literal on the left)");
	is_deeply([ map { $_->{id} } @{ filter($df, col("grp") eq "a") } ], [1, 3], "col: string eq");
	is_deeply([ map { $_->{id} } @{ filter($df, (col("grp") eq "a") & (col("age") > 18)) } ], [1, 3], "col: & (and)");
	is_deeply([ sort { $a <=> $b } map { $_->{id} } @{ filter($df, (col("age") < 18) | (col("id") == 3)) } ], [2, 3], "col: | (or)");
	is_deeply([ map { $_->{id} } @{ filter($df, !(col("age") > 18)) } ], [2], "col: ! (not)");
	my $h = filter($df, col("age") >= 18, "output.type" => "hoa");
	is_deeply([ sort { $a <=> $b } @{ $h->{age} } ], [20, 25], "col honours output.type => hoa");
	my $hoh = { r1 => { age => 20 }, r2 => { age => 10 } };
	is_deeply([ keys %{ filter($hoh, col("age") > 15) } ], ["r1"], "col on HoH input");
	my $u = [ { x => 5 }, { x => undef }, { x => 1 } ];
	is_deeply([ map { $_->{x} } @{ filter($u, col("x") > 0) } ], [5, 1], "col: undef/non-numeric cell never matches (numeric)");
	is_deeply([ map { $_->{x} } @{ filter($u, col("x") ne "5") } ], [1], "col: undef cell never matches (string ne)");
}

#--------
# errors
#--------
throws_ok { filter('x', sub { 1 }) }					   qr/data frame/,			  'non-ref data frame dies';
throws_ok { filter([], "x") } qr/CODE reference or a col/, "non-predicate (neither CODE nor col) dies";
throws_ok { filter([ { x => 1 } ], col("x")) } qr/incomplete col/, "a bare col() predicate dies";
throws_ok { filter([], sub { 1 }, 'output.type' => 'hoh') } qr/output\.type must be/, 'output.type hoh is rejected';
throws_ok { filter([ {}, 'x' ], sub { 1 }) }			   qr/element 1 is not a HASH/, 'AoH non-hash element dies';
throws_ok { filter({ c => 'x' }, sub { 1 }) }			   qr/hash of arrays.*hash of hashes/, 'scalar-valued hash dies';
# NB: shape is auto-detected by peeking the first value, and hash order is
# randomized, so a malformed mixed hash is rejected EITHER by the per-element
# check OR by shape detection -- accept both, since both are descriptive.
throws_ok { filter({ a => [1], b => 'x' }, sub { 1 }) }
	qr/not an ARRAY|hash of arrays.*hash of hashes/, 'HoA non-array column dies';
throws_ok { filter({ a => { x => 1 }, b => 'x' }, sub { 1 }) }
	qr/not a HASH|hash of arrays.*hash of hashes/, 'HoH non-hash row dies';
throws_ok { filter([ { x => 1 } ], sub { die "boom\n" }) } qr/boom/,				  'a dying predicate propagates';

#--------
# memory
#--------
my $LA	= [ { x => 1 }, { x => 2 } ];
my $LHA = { x => [1, 2], y => ['p', 'q'] };
my $LH	= { a => { x => 1 }, b => { x => 2 } };
no_leaks_ok { filter($LA,  sub { $_->{x} > 1 }) }						 'no leak: AoH -> AoH'	unless $INC{'Devel/Cover.pm'};
no_leaks_ok { filter($LA,  sub { $_->{x} > 1 }, 'output.type' => 'hoa') } 'no leak: AoH -> hoa'	 unless $INC{'Devel/Cover.pm'};
no_leaks_ok { filter($LHA, sub { $_->{x} > 1 }) }						 'no leak: HoA -> HoA'	unless $INC{'Devel/Cover.pm'};
no_leaks_ok { filter($LHA, sub { $_->{x} > 1 }, 'output.type' => 'aoh') } 'no leak: HoA -> aoh'	 unless $INC{'Devel/Cover.pm'};
no_leaks_ok { filter($LH,  sub { $_->{x} > 0 }) }						 'no leak: HoH -> HoH'	unless $INC{'Devel/Cover.pm'};
no_leaks_ok { filter($LH,  sub { $_->{x} > 0 }, 'output.type' => 'hoa') } 'no leak: HoH -> hoa'	 unless $INC{'Devel/Cover.pm'};
no_leaks_ok { filter($LA, col('x') > 1) } 'no leak: col predicate' unless $INC{'Devel/Cover.pm'};
no_leaks_ok { eval { filter($LA, sub { die "x\n" }) } }					 'no leak: dying predicate' unless $INC{'Devel/Cover.pm'};

done_testing;
