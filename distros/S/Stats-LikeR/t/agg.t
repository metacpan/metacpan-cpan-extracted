#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use feature 'say';
use Scalar::Util 'looks_like_number';
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

dies_ok {
	agg(undef, 'x');
} 'agg: dies when given undefined data';
# shared fixture, expressed in every shape --------------------------------
#   sex  wt   age
#   M    70   30
#   F    60   25
#   M    80   40
#   F    55   undef
my $AoH = [
	{ sex => 'M', wt => 70, age => 30    },
	{ sex => 'F', wt => 60, age => 25    },
	{ sex => 'M', wt => 80, age => 40    },
	{ sex => 'F', wt => 55, age => undef },
];
my $HoA = {
	sex => [ 'M', 'F', 'M', 'F'     ],
	wt  => [ 70,  60,  80,  55      ],
	age => [ 30,  25,  40,  undef   ],
};
my $HoH = {
	p1 => { sex => 'M', wt => 70, age => 30    },
	p2 => { sex => 'F', wt => 60, age => 25    },
	p3 => { sex => 'M', wt => 80, age => 40    },
	p4 => { sex => 'F', wt => 55, age => undef },
};
# AoA: col 0 = sex, col 1 = wt, col 2 = age
my $AoA = [
	[ 'M', 70, 30    ],
	[ 'F', 60, 25    ],
	[ 'M', 80, 40    ],
	[ 'F', 55, undef ],
];

#--------
# grouped AoH, single aggregator keeps the column name
#--------
{
	my $g = agg($AoH, by => 'sex', agg => { wt => 'mean' });
	is(scalar @$g, 2, 'AoH/mean: two groups');
	my %by = map { $_->{sex} => $_ } @$g;
	is($g->[0]{sex}, 'F', 'AoH/mean: groups sorted (F first)');
	is_approx($by{F}{wt}, 57.5, 'AoH/mean: F mean wt');
	is_approx($by{M}{wt}, 75,   'AoH/mean: M mean wt');
	ok(!exists $by{F}{wt_mean}, 'AoH/mean: single func keeps bare column name');
}

#--------
# grouped AoH, multiple aggregators -> <col>_<func>, plus a count on a label col
#--------
{
	my $g  = agg($AoH, by => 'sex', agg => { wt => [ 'mean', 'sd' ], age => [ 'mean', 'count' ] });
	my %by = map { $_->{sex} => $_ } @$g;
	is_approx($by{F}{wt_mean}, 57.5,          'AoH/multi: F wt_mean');
	is_approx($by{F}{wt_sd},   sqrt(12.5),    'AoH/multi: F wt_sd');
	is_approx($by{M}{wt_sd},   sqrt(50),      'AoH/multi: M wt_sd');
	is_approx($by{F}{age_mean}, 25,           'AoH/multi: F age mean skips undef');
	is($by{F}{age_count}, 1, 'AoH/multi: F age count excludes the undef');
}

#--------
# ungrouped: whole frame collapses to one row (pandas df.agg)
#--------
{
	my $u = agg($AoH, agg => { wt => 'mean', age => 'count' });
	is(scalar @$u, 1, 'ungrouped: single row');
	is_approx($u->[0]{wt}, 66.25, 'ungrouped: mean wt');
	is($u->[0]{age}, 3, 'ungrouped: count ignores the undef age');
}

#--------
# every shape yields the same grouped means (normalised to aoh output)
#--------
{
	for my $case ([ 'HoA', $HoA, 'sex', 'wt' ], [ 'HoH', $HoH, 'sex', 'wt' ], [ 'AoA', $AoA, 0, 1 ]) {
		my ($name, $df, $bycol, $wtcol) = @$case;
		my $g = agg($df, by => $bycol, agg => { $wtcol => 'mean' }, 'output.type' => 'aoh');
		my %by = map { $_->{$bycol} => $_->{$wtcol} } @$g;
		is_approx($by{F}, 57.5, "$name: F mean wt");
		is_approx($by{M}, 75,   "$name: M mean wt");
	}
	# default output type mirrors the input family
	is(ref agg($HoA, by => 'sex', agg => { wt => 'mean' }), 'HASH',
		'default output: HoA in -> hashref out');
	is(ref agg($AoA, by => 0, agg => { 1 => 'mean' }), 'ARRAY',
		'default output: AoA in -> arrayref out');
}

#--------
# output.type overrides
#--------
{
	my $hoh = agg($HoA, by => 'sex', agg => { wt => 'mean' }, 'output.type' => 'hoh');
	is_approx($hoh->{F}{wt}, 57.5, 'output hoh: keyed by group value');
	is($hoh->{M}{sex}, 'M', 'output hoh: retains grouping column');

	my $hoa = agg($AoH, by => 'sex', agg => { wt => 'mean' }, 'output.type' => 'hoa');
	is(ref $hoa, 'HASH', 'output hoa: is a hashref');
	is_approx($hoa->{wt}[0], 57.5, 'output hoa: column-major values');

	my $aoa = agg($AoH, by => 'sex', agg => { wt => [ 'mean', 'max' ] }, 'output.type' => 'aoa');
	is_approx($aoa->[1][1], 75, 'output aoa: positional mean for M');
	is_approx($aoa->[1][2], 80, 'output aoa: positional max for M');

	throws_ok { agg($AoH, agg => { wt => 'mean' }, 'output.type' => 'bogus') }
		qr/output\.type 'bogus' isn't allowed/, 'output.type validated';
}

#--------
# named aggregators, exercised on one column
#--------
{
	my $df = [ map { { g => 'x', v => $_ } } (2, 4, 4, 4, 5, 5, 7, 9) ];
	push @$df, { g => 'x', v => undef };            # one NA
	my %want = (
		mean    => 5,
		median  => 4.5,
		sum     => 40,
		sd      => sd(2, 4, 4, 4, 5, 5, 7, 9),
		var     => var(2, 4, 4, 4, 5, 5, 7, 9),
		min     => 2,
		max     => 9,
		count   => 8,                                # defined only
		n       => 9,                                # includes the undef
		nunique => 5,                                # 2,4,5,7,9
		first   => 2,
		last    => 9,
		mode    => 4,
	);
	for my $f (sort keys %want) {
		my $r = agg($df, agg => { v => $f });
		is_approx($r->[0]{v}, $want{$f}, "aggregator $f");
	}
}

#--------
# mode tie-breaking is deterministic
#--------
{
	my $num = agg([ map { { v => $_ } } (3, 1, 3, 1) ], agg => { v => 'mode' });
	is($num->[0]{v}, 1, 'mode: numeric tie -> smallest');
	my $str = agg([ map { { v => $_ } } qw(b a b a) ], agg => { v => 'mode' });
	is($str->[0]{v}, 'a', 'mode: string tie -> lowest');
}

#--------
# skipna
#--------
{
	my $keep = agg($AoH, by => 'sex', agg => { age => 'mean' }, skipna => 1);
	my %k = map { $_->{sex} => $_->{age} } @$keep;
	is_approx($k{F}, 25, 'skipna=1: undef dropped, mean over the rest');

	my $strict = agg($AoH, by => 'sex', agg => { age => 'mean' }, skipna => 0);
	my %s = map { $_->{sex} => $_ } @$strict;
	ok(!defined $s{F}{age}, 'skipna=0: any undef poisons a numeric reducer');
	is_approx($s{M}{age}, 35, 'skipna=0: clean group still aggregates');
}

#--------
# too few defined values -> undef (sd/var need >= 2, mean etc. need >= 1)
#--------
{
	my $one = agg([ { g => 'a', v => 5 } ], by => 'g', agg => { v => [ 'mean', 'sd', 'var' ] });
	is_approx($one->[0]{v_mean}, 5, 'single value: mean defined');
	ok(!defined $one->[0]{v_sd},  'single value: sd undef');
	ok(!defined $one->[0]{v_var}, 'single value: var undef');

	my $none = agg([ { g => 'a', v => undef } ], by => 'g', agg => { v => [ 'mean', 'count' ] });
	ok(!defined $none->[0]{v_mean}, 'all-NA group: mean undef');
	is($none->[0]{v_count}, 0, 'all-NA group: count 0');
}

#--------
# coderef aggregator receives every cell (undef included)
#--------
{
	my $r = agg($AoH, by => 'sex', agg => { age => sub {
		my $cells = shift;
		my $na = grep { !defined } @$cells;
		"$na NA of " . scalar(@$cells);
	} });
	my %by = map { $_->{sex} => $_->{age} } @$r;
	is($by{F}, '1 NA of 2', 'coderef: sees raw cells incl. undef');
	is($by{M}, '0 NA of 2', 'coderef: clean group');
}

#--------
# sort => 0 preserves first-seen group order
#--------
{
	my $seen = agg($AoH, by => 'sex', agg => { wt => 'mean' }, sort => 0);
	is($seen->[0]{sex}, 'M', 'sort=0: first-seen order (M appears first)');
}

#--------
# multiple grouping columns; hoh labels join with '.'
#--------
{
	my $df = [
		{ a => 1, b => 'x', v => 10 },
		{ a => 1, b => 'x', v => 20 },
		{ a => 1, b => 'y', v => 30 },
		{ a => 2, b => 'y', v => 40 },
	];
	my $aoh = agg($df, by => [ 'a', 'b' ], agg => { v => 'sum' });
	is(scalar @$aoh, 3, 'multi-key: three groups');
	my %by = map {; ( "$_->{a}.$_->{b}" => $_->{v} ) } @$aoh;
	is($by{'1.x'}, 30, 'multi-key: 1/x summed');
	my $hoh = agg($df, by => [ 'a', 'b' ], agg => { v => 'sum' }, 'output.type' => 'hoh');
	is_approx($hoh->{'1.x'}{v}, 30, 'multi-key hoh: label joined with dot');
	ok(exists $hoh->{'2.y'}, 'multi-key hoh: all labels present');
}

#--------
# error handling
#--------
throws_ok { agg('scalar', agg => { v => 'mean' }) }
	qr/data frame must be an ARRAY/, 'non-ref df dies';
throws_ok { agg($AoH) }
	qr/'agg' spec .* is required/, 'missing agg spec dies';
throws_ok { agg($AoH, agg => { wt => 'mean' }, bogus => 1) }
	qr/unknown argument/, 'unknown option dies';
throws_ok { agg($AoH, agg => { wt => 'bogus' }) }
	qr/unknown aggregator 'bogus'/, 'bad aggregator name dies';
throws_ok { agg($AoH, agg => { wt => [] }) }
	qr/empty aggregator list/, 'empty aggregator list dies';
throws_ok { agg($AoH, agg => { wt => 'mean' }, 'extra') }
	qr/name => value pairs/, 'odd trailing args die';

#--------
# no memory leaks across shapes
#--------
no_leaks_ok {
	agg($AoH, by => 'sex', agg => { wt => [ 'mean', 'sd' ], age => 'count' });
} 'agg(): AoH grouped no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	agg($HoA, by => 'sex', agg => { wt => 'mean' }, 'output.type' => 'hoh');
} 'agg(): HoA -> hoh no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	agg($HoH, by => 'sex', agg => { wt => 'sum' });
} 'agg(): HoH no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	agg($AoA, by => 0, agg => { 1 => [ 'mean', 'max' ] });
} 'agg(): AoA no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	agg($AoH, agg => { age => sub { scalar @{ $_[0] } } });
} 'agg(): coderef no leaks' unless $INC{'Devel/Cover.pm'};

done_testing();
