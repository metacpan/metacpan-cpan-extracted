#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';   # the exact environment that used to die
use Stats::LikeR;
use Test::Exception; # throws_ok / dies_ok
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

# stringify a column with possible undef, so assertions never trip
# 'uninitialized' warnings themselves under FATAL warnings
sub shown { join ',', map { defined $_ ? $_ : 'undef' } @_ }

no warnings 'once';   # $a / $b package globals used by comparators below

#--------
# the reported case: HoH, comparator, undef column -> undef last, no die
#--------
{
	my $hoh = {
		Ehd1  => { 'tau p' => 0.33 },
		CFTR  => { 'tau p' => 1    },
		Bcop  => { 'tau p' => undef },
		I12   => { 'tau p' => undef },
		CDK2  => { 'tau p' => 0.95 },
	};
	my $s;
	lives_ok { $s = csort($hoh, sub { $a->{'tau p'} <=> $b->{'tau p'} }, 'hoa') }
		'comparator on a column with undef no longer dies under FATAL warnings';
	is( shown(@{ $s->{'tau p'} }), '0.33,0.95,1,undef,undef',
		'HoH comparator ascending: defined asc, undef last' );
}

#--------
# descending comparator: defined descending, undef still last
#--------
{
	my $hoh = {
		Ehd1  => { 'tau p' => 0.33 },
		CFTR  => { 'tau p' => 1    },
		Bcop  => { 'tau p' => undef },
		CDK2  => { 'tau p' => 0.95 },
	};
	my $s = csort($hoh, sub { $b->{'tau p'} <=> $a->{'tau p'} }, 'hoa');
	is( shown(@{ $s->{'tau p'} }), '1,0.95,0.33,undef',
		'HoH comparator descending: defined desc, undef last' );
}

#--------
# AoH numeric comparator with undef / missing cells
#--------
{
	my $aoh = [
		{ id => 1, v => 5 },
		{ id => 2, v => undef },
		{ id => 3, v => 1 },
		{ id => 4 },              # missing v
		{ id => 5, v => 9 },
	];
	my $s = csort($aoh, sub { $a->{v} <=> $b->{v} });
	is( shown(map { $_->{id} } @$s), '3,1,5,2,4',
		'AoH comparator: defined asc first, undef/missing last (stable)' );
}

#--------
# AoA comparator: undef / short rows sort last
#--------
{
	my $aoa = [ [ 1, 5 ], [ 2, undef ], [ 3, 1 ], [ 4 ], [ 5, 9 ] ];
	my $s = csort($aoa, sub { $a->[1] <=> $b->[1] });
	is( shown(map { $_->[0] } @$s), '3,1,5,2,4',
		'AoA comparator: undef/missing index sorts last' );
}

#--------
# string comparator (cmp) with undef -> undef last
#--------
{
	my $aoh = [ { k => 'b' }, { k => undef }, { k => 'a' }, {} ];
	my $s = csort($aoh, sub { $a->{k} cmp $b->{k} });
	is( shown(map { $_->{k} } @$s), 'a,b,undef,undef',
		'string comparator: defined lexically first, undef last' );
}

#--------
# a comparator that handles undef itself is left completely alone
#--------
{
	my $aoh = [ { v => 3 }, { v => undef }, { v => 1 } ];
	my $s = csort($aoh, sub { ($a->{v} // 0) <=> ($b->{v} // 0) });
	is( shown(map { $_->{v} } @$s), 'undef,1,3',
		'self-guarded comparator: csort does not interfere (undef stays as 0)' );
}

#--------
# multi-key: undef reached only at the tie-break still sends the row last
#--------
{
	my $aoh = [
		{ a => 1, b => 2 },
		{ a => 1, b => undef },
		{ a => 0, b => 9 },
	];
	my $s = csort($aoh, sub { $a->{a} <=> $b->{a} or $a->{b} <=> $b->{b} });
	is( shown(map { "$_->{a}" . (defined $_->{b} ? $_->{b} : 'u') } @$s),
		'09,12,1u',
		'multi-key comparator: row with undef in an evaluated key sorts last' );
}

#--------
# all-defined data is sorted exactly as before (no reordering artifacts)
#--------
{
	my $aoh = [ map { { v => $_ } } (3, 1, 4, 1, 5, 9, 2, 6) ];
	my $s = csort($aoh, sub { $a->{v} <=> $b->{v} });
	is( shown(map { $_->{v} } @$s), '1,1,2,3,4,5,6,9',
		'all-defined comparator sort is unaffected' );
}

#--------
# a genuine comparator error must propagate, not be silently reclassified
#--------
throws_ok { csort([ { v => 1 }, { v => 2 } ], sub { die "boom\n" }) }
	qr/boom/, 'genuine comparator die propagates verbatim';

#--------
# leak checks (calls repeated outside any captured assignment; skipped under
# Devel::Cover whose instrumentation registers false leaks)
#--------
no_leaks_ok {
	csort([ { v => 5 }, { v => undef }, { v => 1 }, {} ],
	      sub { $a->{v} <=> $b->{v} })
} 'no leaks: AoH comparator with undef/missing cells'
	unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	csort({ x => { v => 1 }, y => { v => undef }, z => { v => 2 } },
	      sub { $a->{v} <=> $b->{v} }, 'hoa')
} 'no leaks: HoH comparator with undef, HoA output'
	unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	csort([ [ 1, 5 ], [ 2, undef ], [ 3, 1 ] ], sub { $a->[1] <=> $b->[1] })
} 'no leaks: AoA comparator with undef'
	unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { csort([ { v => 1 }, { v => 2 } ], sub { die "boom\n" }) }
} 'no leaks: genuine comparator-die path'
	unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	csort([ { v => 3 }, { v => undef }, { v => 1 } ],
	      sub { ($a->{v} // 0) <=> ($b->{v} // 0) })
} 'no leaks: self-guarded comparator'
	unless $INC{'Devel/Cover.pm'};

done_testing();
