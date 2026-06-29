use strict;
use warnings;
use Test::More;
use Stats::LikeR 'csort';

# Import no_leaks_ok at compile time so its (&;$) prototype is in scope for the
# block-style calls below. Absent module -> the leak tests are skipped at runtime.
my $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	};
}

#
# AoH, sort by column name (numeric column -> numeric order)
#
{
	my $aoh = [
		{ name => 'Carol', age => 30 },
		{ name => 'Alice', age => 9  },
		{ name => 'Bob',   age => 100 },
	];
	my $s = csort($aoh, 'age');
	is_deeply [ map { $_->{name} } @$s ], [qw(Alice Carol Bob)],
		'AoH numeric column sorts numerically (9 < 30 < 100)';
	# non-destructive
	is_deeply [ map { $_->{name} } @$aoh ], [qw(Carol Alice Bob)],
		'AoH input left untouched';
	# returned rows are the SAME hashrefs (sorting reorders, not clones)
	is $s->[0], $aoh->[1], 'AoH result shares the original row hashrefs';
}

#
# AoH, string column -> lexical order
#
{
	my $aoh = [ { c => 'banana' }, { c => 'apple' }, { c => 'cherry' } ];
	my $s = csort($aoh, 'c');
	is_deeply [ map { $_->{c} } @$s ], [qw(apple banana cherry)],
		'AoH string column sorts lexically';
}

#
# AoH, custom comparator with $a / $b (descending numeric)
#
{
	my $aoh = [ { v => 3 }, { v => 1 }, { v => 2 } ];
	my $s = csort($aoh, sub { $b->{v} <=> $a->{v} });
	is_deeply [ map { $_->{v} } @$s ], [ 3, 2, 1 ],
		'AoH comparator: $a/$b are row hashrefs, descending works';
}

#
# HoA, sort by column name (all columns permuted in parallel)
#
{
	my $hoa = {
		id    => [ 1,   2,   3   ],
		score => [ 50,  10,  30  ],
	};
	my $s = csort($hoa, 'score');
	is_deeply $s->{score}, [ 10, 30, 50 ], 'HoA sort column ordered';
	is_deeply $s->{id},    [ 2,  3,  1  ], 'HoA other column permuted in lockstep';
	# non-destructive
	is_deeply $hoa->{id}, [ 1, 2, 3 ], 'HoA input left untouched';
}

#
# HoA, custom comparator: $a / $b are per-row hash views
#
{
	my $hoa = {
		id  => [ 1,  2,  3  ],
		val => [ 30, 10, 20 ],
	};
	my $s = csort($hoa, sub { $a->{val} <=> $b->{val} });
	is_deeply $s->{val}, [ 10, 20, 30 ], 'HoA comparator sorts by val';
	is_deeply $s->{id},  [ 2,  3,  1  ], 'HoA comparator permutes id in lockstep';
}

#
# Stability: equal keys keep their original relative order
#
{
	my $aoh = [
		{ k => 1, tag => 'a' },
		{ k => 1, tag => 'b' },
		{ k => 0, tag => 'c' },
		{ k => 1, tag => 'd' },
	];
	my $s = csort($aoh, 'k');
	is_deeply [ map { $_->{tag} } @$s ], [qw(c a b d)],
		'stable sort preserves input order among equal keys';
}

#
# Undef / missing cells sort last
#
{
	my $aoh = [
		{ id => 1, v => 5 },
		{ id => 2 },           # missing v
		{ id => 3, v => undef }, # explicit undef
		{ id => 4, v => 1 },
	];
	my $s = csort($aoh, 'v');
	is_deeply [ map { $_->{id} } @$s ], [ 4, 1, 2, 3 ],
		'defined values first (asc), undef/missing last (stable among themselves)';
}

#
# $a / $b resolve in a non-main package, just like real sort
#
{
	package My::Sorter;
	use Stats::LikeR 'csort';
	our ($a, $b);
	my $aoh = [ { v => 2 }, { v => 3 }, { v => 1 } ];
	my $s = csort($aoh, sub { $a->{v} <=> $b->{v} });
	::is_deeply [ map { $_->{v} } @$s ], [ 1, 2, 3 ],
		'comparator $a/$b work from a package other than main';
}

#
# A named comparator sub (resolved via its own package's $a/$b)
#
{
	package Cmp::Pkg;
	our ($a, $b);
	sub by_v_desc { $b->{v} <=> $a->{v} }
	package main;
	my $aoh = [ { v => 1 }, { v => 3 }, { v => 2 } ];
	my $s = csort($aoh, \&Cmp::Pkg::by_v_desc);
	is_deeply [ map { $_->{v} } @$s ], [ 3, 2, 1 ],
		'named comparator sub uses $a/$b from its defining package';
}

#
# Edge cases: empty and single-element
#
{
	is_deeply csort([], 'x'), [], 'empty AoH returns empty arrayref';
	is_deeply csort([ { x => 7 } ], 'x'), [ { x => 7 } ], 'single-row AoH';
	is_deeply csort({}, 'x'), {}, 'empty HoA returns empty hashref';
	my $one = csort({ a => [5], b => [9] }, 'a');
	is_deeply $one, { a => [5], b => [9] }, 'single-row HoA';
}

#
# A string comparator result (the sub returns "-1"/"0"/"1") still works
#
{
	my $aoh = [ { v => 'pear' }, { v => 'apple' }, { v => 'fig' } ];
	my $s = csort($aoh, sub { $a->{v} cmp $b->{v} });
	is_deeply [ map { $_->{v} } @$s ], [qw(apple fig pear)],
		'comparator using cmp (string result) works';
}

#
# Error handling
#
{
	eval { csort('notaref', 'x') };
	like $@, qr/array-ref \(AoH\) or hash-ref \(HoA, HoH\)/, 'rejects non-ref data';

	eval { csort([ { x => 1 } ], undef) };
	like $@, qr/column name or a comparator/, 'rejects undef $by';

	eval { csort([ { x => 1 } ], [1,2,3]) };
	like $@, qr/column name or a comparator/, 'rejects non-code ref $by';

	eval { csort({ a => [1,2], b => [1] }, 'a') };
	like $@, qr/unequal lengths/, 'HoA unequal column lengths croaks';

	eval { csort({ a => [1,2] }, 'missing') };
	like $@, qr/not found/, 'HoA missing sort column croaks';

	eval { csort({ a => 'notarray' }, 'a') };
	like $@, qr/not an array-ref/, 'HoA non-array column croaks';
}

#
# Output-type option: AoH -> HoA (sort + transpose)
#
{
	my $aoh = [
		{ name => 'Carol', age => 30 },
		{ name => 'Alice', age => 9  },
		{ name => 'Bob',   age => 100 },
	];
	my $h = csort($aoh, 'age', 'hoa');
	is ref($h), 'HASH', 'AoH + output=hoa returns a hashref';
	is_deeply $h->{age},  [ 9, 30, 100 ],          'AoH->HoA: age column sorted';
	is_deeply $h->{name}, [qw(Alice Carol Bob)],   'AoH->HoA: name column in lockstep';
	# original untouched
	is_deeply [ map { $_->{name} } @$aoh ], [qw(Carol Alice Bob)],
		'AoH->HoA: input untouched';
}

# AoH with heterogeneous keys -> HoA fills missing cells with undef
{
	my $aoh = [
		{ a => 2, b => 'x' },
		{ a => 1 },            # no 'b'
		{ a => 3, b => 'z', c => 9 },
	];
	my $h = csort($aoh, 'a', 'hoa');
	is_deeply $h->{a}, [ 1, 2, 3 ], 'AoH->HoA union: column a sorted';
	is_deeply $h->{b}, [ undef, 'x', 'z' ], 'AoH->HoA union: missing b -> undef';
	is_deeply $h->{c}, [ undef, undef, 9 ], 'AoH->HoA union: sparse c filled';
}

#
# Output-type option: HoA -> AoH (sort + transpose)
#
{
	my $hoa = {
		id    => [ 1,  2,  3  ],
		score => [ 50, 10, 30 ],
	};
	my $a = csort($hoa, 'score', 'aoh');
	is ref($a), 'ARRAY', 'HoA + output=aoh returns an arrayref';
	is_deeply [ map { $_->{score} } @$a ], [ 10, 30, 50 ], 'HoA->AoH: sorted by score';
	is_deeply [ map { $_->{id}    } @$a ], [ 2,  3,  1  ], 'HoA->AoH: id carried along';
	is_deeply [ sort keys %{ $a->[0] } ], [qw(id score)], 'HoA->AoH: each row has all columns';
}

# HoA -> AoH driven by a custom comparator
{
	my $hoa = { id => [1,2,3], v => [30,10,20] };
	my $a = csort($hoa, sub { $a->{v} <=> $b->{v} }, 'aoh');
	is_deeply [ map { $_->{id} } @$a ], [ 2, 3, 1 ],
		'HoA->AoH with comparator';
}

#
# Explicit same-shape output, and case-insensitive spelling
#
{
	my $aoh = [ { v => 3 }, { v => 1 }, { v => 2 } ];
	my $same = csort($aoh, 'v', 'AoH');
	is_deeply [ map { $_->{v} } @$same ], [ 1, 2, 3 ], 'explicit aoh->aoh (mixed case accepted)';

	my $hoa = { v => [3,1,2] };
	my $sameh = csort($hoa, 'v', 'HoA');
	is_deeply $sameh->{v}, [ 1, 2, 3 ], 'explicit hoa->hoa (mixed case accepted)';
}

# Default (omitted) output matches the input shape
{
	my $aoh = [ { v => 2 }, { v => 1 } ];
	is ref(csort($aoh, 'v')), 'ARRAY', 'omitted output: AoH stays AoH';
	my $hoa = { v => [2,1] };
	is ref(csort($hoa, 'v')), 'HASH', 'omitted output: HoA stays HoA';
	# undef is treated the same as omitted
	is ref(csort($aoh, 'v', undef)), 'ARRAY', 'undef output behaves like omitted';
}

# Transpose round-trips on empty / single-row inputs
{
	is_deeply csort([], 'x', 'hoa'), {}, 'empty AoH -> empty HoA';
	is_deeply csort({}, 'x', 'aoh'), [], 'empty HoA -> empty AoH';
	is_deeply csort([ { a => 1, b => 2 } ], 'a', 'hoa'),
		{ a => [1], b => [2] }, 'single-row AoH -> HoA';
	is_deeply csort({ a => [1], b => [2] }, 'a', 'aoh'),
		[ { a => 1, b => 2 } ], 'single-row HoA -> AoH';
}

# Bad output type is rejected
{
	eval { csort([ { x => 1 } ], 'x', 'frame') };
	like $@, qr/output type must be 'aoh' or 'hoa'/, 'rejects bogus output type';
}

#
# Leak checks (Test::LeakTrace). Skipped if the module isn't installed, and
# skipped under Devel::Cover, whose instrumentation registers false leaks.
#
SKIP: {
	skip 'Test::LeakTrace not installed', 7 unless $HAVE_LEAKTRACE;
	skip 'Devel::Cover skews leak detection', 7 if $INC{'Devel/Cover.pm'};

	my @aoh = map { { id => $_, v => int(rand(100)), w => "s$_" } } 1 .. 40;
	my %hoa = ( id => [ 1 .. 40 ],
				v  => [ map { int(rand(100)) } 1 .. 40 ],
				w  => [ map { "s$_" }          1 .. 40 ] );
	my $cmp = sub { $a->{v} <=> $b->{v} };

	# --- clean (successful) paths --------------------------------------
	no_leaks_ok { my $s = csort([@aoh], 'v') }
		'no leaks: AoH column sort' unless $INC{'Devel/Cover.pm'};
	no_leaks_ok { my $s = csort({%hoa}, 'v') }
		'no leaks: HoA column sort' unless $INC{'Devel/Cover.pm'};
	no_leaks_ok { my $s = csort([@aoh], $cmp, 'hoa') }
		'no leaks: AoH->HoA comparator sort (synthesizes nothing, builds columns)';
	no_leaks_ok { my $s = csort({%hoa}, $cmp, 'aoh') }
		'no leaks: HoA->AoH comparator sort (synthesizes per-row views)';

	# --- croak paths: allocations must unwind cleanly ------------------
	no_leaks_ok {
		eval { csort({%hoa}, sub { die "boom\n" }) };
	} 'no leaks (synthesized rows) when the comparator dies mid-sort';

	no_leaks_ok {
		eval { csort({ a => [ 1, 2 ], b => [1] }, 'a') };
	} 'no leaks when HoA columns are unequal length (croak after ENTER)';

	no_leaks_ok {
		eval { csort([@aoh], 'v', 'frame') };
	} 'no leaks when the output type is invalid (croak)';
}

done_testing();
