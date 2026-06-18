use strict;
use warnings;
use Test::More;
use Stats::LikeR 'aoh2hoa';

# Optional leak testing: import at compile time so the no_leaks_ok prototype
# is in scope, and skip cleanly when the module is not installed.
my $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	} ? 1 : 0;
}
# basic transpose
{
	my $hoa = aoh2hoa([ { a => 1, b => 2 }, { a => 3, b => 4 } ]);
	is_deeply $hoa, { a => [1, 3], b => [2, 4] }, 'basic AoH -> HoA';
}

# ragged rows: union of keys, missing cells become undef, columns stay parallel
{
	my $aoh = [ { a => 1, b => 2 }, { a => 3 }, { b => 4, c => 5 } ];
	my $hoa = aoh2hoa($aoh);
	is_deeply $hoa,
		{ a => [1, 3, undef], b => [2, undef, 4], c => [undef, undef, 5] },
		'ragged keys: union + undef fill';

	is scalar(@{ $hoa->{$_} }), 3, "column '$_' has one entry per row"
		for sort keys %$hoa;
}

# ---------------------------------------------------------------------------
# a key that first appears in a later row is back-filled with undef
# ---------------------------------------------------------------------------
{
	my $hoa = aoh2hoa([ {}, {}, { z => 9 } ]);
	is_deeply $hoa, { z => [undef, undef, 9] }, 'late key back-filled';
}

# result is an independent copy (mutating output never touches input)
{
	my $aoh = [ { a => 1 }, { a => 2 } ];
	my $hoa = aoh2hoa($aoh);
	$hoa->{a}[0] = 99;
	is $aoh->[0]{a}, 1, 'mutating the HoA does not alter the source AoH';
}

# reference values are copied shallowly (the referent is shared, like Perl =)
{
	my $shared = [10, 20];
	my $hoa = aoh2hoa([ { r => $shared } ]);
	is $hoa->{r}[0], $shared, 'reference value is the same referent (shallow copy)';
}

# edge cases
is_deeply aoh2hoa([]),        {},          'empty AoH -> empty HoA';
is_deeply aoh2hoa([ {} ]),    {},          'single empty row -> empty HoA';
is_deeply aoh2hoa([ { a => 1 } ]), { a => [1] }, 'single row';

# a non-hashref row is skipped (contributes undef at its index)
{
	my $hoa = aoh2hoa([ { a => 1 }, 'oops', { a => 3 } ]);
	is_deeply $hoa, { a => [1, undef, 3] }, 'non-hashref row -> undef slot';
}

# unicode / wide keys round-trip correctly
{
	my $k = "\x{263a}";			# WHITE SMILING FACE
	my $hoa = aoh2hoa([ { $k => 1 }, { $k => 2 } ]);
	is_deeply $hoa, { $k => [1, 2] }, 'utf8 key preserved';
}

# bad input croaks
{
	eval { aoh2hoa({ a => 1 }) };
	like $@, qr/arrayref/, 'hashref argument croaks';
	eval { aoh2hoa(42) };
	like $@, qr/arrayref/, 'non-ref argument croaks';
}

# no memory leaks
SKIP: {
	skip 'Test::LeakTrace not installed', 3 unless $HAVE_LEAKTRACE;
	skip 'running under Devel::Cover', 3 if $INC{'Devel/Cover.pm'};

	no_leaks_ok { aoh2hoa([ { a => 1, b => 2 }, { a => 3, b => 4 } ]) }
		'no leaks: rectangular transpose';
	no_leaks_ok { aoh2hoa([ { a => 1, b => 2 }, { a => 3 }, { c => 5 } ]) }
		'no leaks: ragged transpose (undef fill)';
	no_leaks_ok { eval { aoh2hoa(42) } }
		'no leaks: croak path';
}

done_testing;
