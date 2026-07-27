#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

sub is_approx {
	my ($got, $expected, $test_name, $epsilon) = @_;
	$epsilon = 1e-9 if not defined $epsilon;
	my $diff = abs($got - $expected);
	if ($diff <= $epsilon) { pass("$test_name: within $epsilon"); return 1; }
	fail($test_name);
	diag("         got: $got\n    expected: $expected; diff = $diff");
	return 0;
}

# Reference values from an independent R reimplementation of Truchon & Bayly
# (2007) BEDROC eq. 36:  BEDROC = RIE * factor1 + factor2, with midranks for
# ties and rank 1 = top of the (descending-score) ranking.  This dataset is
# the one used by t/roc.t and contains a tie at 0.55 (an active and an
# inactive), so the midrank tie handling is genuinely exercised.
my @s = (0.1,0.4,0.35,0.8,0.7,0.6,0.2,0.9,0.55,0.55,0.3,0.75,0.45,0.85,0.5);
my @l = (0,  0,  1,   1,  1,  0,  0,  1,  0,   1,   0,  1,   1,   1,  0);

my $r = bedroc(\@s, \@l, alpha => 20);
is_approx($r->{bedroc},  0.998882221734, 'BEDROC alpha=20');
is_approx($r->{rie},     1.872860699222, 'RIE alpha=20');
is_approx($r->{rie_min}, 0.000165796739, 'RIE min alpha=20');
is_approx($r->{rie_max}, 1.874956299300, 'RIE max alpha=20');
is_approx($r->{ra},      8/15,           'R_a = n_active / n');
is($r->{n},          15, 'n total');
is($r->{n_active},    8, 'n_active');
is($r->{n_inactive},  7, 'n_inactive');
is($r->{alpha},      20, 'alpha echoed');
is($r->{direction}, '>', 'direction defaults to >');

# alpha controls how sharply early hits are weighted
is_approx(bedroc(\@s, \@l, alpha => 8  )->{bedroc}, 0.960538867053, 'BEDROC alpha=8');
is_approx(bedroc(\@s, \@l, alpha => 0.5)->{bedroc}, 0.853254831944, 'BEDROC alpha=0.5');

# bounds: actives all on top -> 1, actives all on the bottom -> 0
is_approx(bedroc([10,9,8,7,3,2,1,0], [1,1,1,1,0,0,0,0], alpha => 20)->{bedroc},
          1.0, 'perfect early ranking => BEDROC 1');
is_approx(bedroc([10,9,8,7,3,2,1,0], [0,0,0,0,1,1,1,1], alpha => 20)->{bedroc},
          0.0, 'worst ranking => BEDROC 0');

# direction => '<' : lower score ranks first, flips the worst case back to 1
is_approx(bedroc([0,1,2,3,7,8,9,10], [1,1,1,1,0,0,0,0], alpha => 20, direction => '<')->{bedroc},
          1.0, "direction '<' ranks low scores first");

# string labels via positive =>
is_approx(bedroc([0.9,0.1,0.8,0.2], ['case','ctrl','case','ctrl'],
                 alpha => 20, positive => 'case')->{bedroc},
          1.0, 'string labels with positive =>');

# cutoff => : actives are the @target entries with value >= cutoff
my @sc = (10,9,8,7,6,5,4,3,2,1);
my @v  = ( 9,8,7,2,1,6,3,10,5,6.5);   # values >= 6.5 are active (5 of them)
my $c = bedroc(\@sc, \@v, alpha => 20, cutoff => 6.5, top => 0.3);
is_approx($c->{bedroc}, 0.997567159019, 'BEDROC with cutoff-defined actives');
is($c->{n_active},   5, 'cutoff => selects 5 actives');
is($c->{n_inactive}, 5, 'cutoff => leaves 5 inactives');

# top => : enrichment in the top fraction of the ranking
my $e = $c->{enrichment};
is($e->{n_top},         3,   'top 0.3 of 10 => 3 compounds (ceil)');
is($e->{active_count},  3,   'all 3 top-ranked are active');
is_approx($e->{expected},          1.5, 'expected hits = ra * n_top');
is_approx($e->{enrichment_factor}, 2.0, 'enrichment factor = (hits/n_top)/ra');
is_approx($e->{fraction},          0.3, 'top fraction echoed');

# active_frac => : binarize the second array by taking a fraction as active.
# On @sc/@v the 5 highest values are exactly the >= 6.5 set (the 6th-highest is
# 6), so active_frac => 0.5 high must reproduce the cutoff => 6.5 BEDROC above.
my $fh = bedroc(\@sc, \@v, alpha => 20, active_frac => 0.5, active_side => 'high');
is_approx($fh->{bedroc}, 0.997567159019, 'active_frac high == cutoff on this data');
is($fh->{n_active},   5, 'active_frac 0.5 of 10 => 5 actives (ceil)');
is($fh->{n_inactive}, 5, 'active_frac 0.5 => 5 inactives');

# active_side defaults to 'high'; 'low' takes the small tail (the complement here)
my $fl = bedroc(\@sc, \@v, alpha => 20, active_frac => 0.5, active_side => 'low');
is($fl->{n_active}, 5, "active_side 'low' selects the low tail");

# perfect / worst with fraction-defined actives (self-contained, exact bounds)
is_approx(bedroc([1,2,3,4,5,6,7,8], [1,2,3,4,10,11,12,13],
                 alpha => 20, active_frac => 0.5, active_side => 'low',
                 direction => '<')->{bedroc},
          1.0, 'active_frac low + direction < : low-value actives on top => 1');
is_approx(bedroc([1,2,3,4,5,6,7,8], [1,2,3,4,10,11,12,13],
                 alpha => 20, active_frac => 0.5, active_side => 'high',
                 direction => '<')->{bedroc},
          0.0, 'active_frac high + direction < : high-value actives on bottom => 0');

# n_a is clamped to [1, N-1] so both classes always exist
is(bedroc(\@sc, \@v, active_frac => 0.001)->{n_active}, 1, 'tiny active_frac => 1 active');
is(bedroc(\@sc, \@v, active_frac => 0.99 )->{n_inactive}, 1, 'huge active_frac => 1 inactive');

# the whole point: a raw numeric column that would otherwise leave one class
# empty no longer dies -- active_frac guarantees a usable split
lives_ok { bedroc(\@sc, \@v, active_frac => 0.1) }
	'active_frac binarizes a raw column instead of dying';

# guard rails
dies_ok { bedroc(\@sc, \@v, active_frac => 0.5, cutoff => 6.5) }
	'active_frac + cutoff together dies';
dies_ok { bedroc(\@sc, \@v, active_frac => 0)   } 'active_frac = 0 dies';
dies_ok { bedroc(\@sc, \@v, active_frac => 1)   } 'active_frac = 1 dies';
dies_ok { bedroc(\@sc, \@v, active_frac => 1.5) } 'active_frac > 1 dies';

# help: bedroc('h' | 'H' | '?') prints usage (like ?fn in R) and returns nothing
for my $flag ('h', 'H', '?') {
	my $out = '';
	{
		local *STDOUT;
		open STDOUT, '>', \$out or die "cannot redirect STDOUT: $!";
		my @got = bedroc($flag);
		is(scalar(@got), 0, "bedroc('$flag') returns empty list");
	}
	like($out, qr/bedroc/i,  "bedroc('$flag') prints help mentioning bedroc");
	like($out, qr/USAGE/,    "bedroc('$flag') prints a USAGE section");
	like($out, qr/alpha/,    "bedroc('$flag') documents alpha");
}

# error paths
dies_ok { bedroc(\@s) }                         'missing labels dies';
dies_ok { bedroc(\@s, [1,0,1]) }                'length mismatch dies';
dies_ok { bedroc([1,2,3],[1,1,1]) }             'single-class dies';
dies_ok { bedroc(\@s, \@l, bogus => 1) }        'unknown option dies';
dies_ok { bedroc(\@s, \@l, alpha => 0) }        'alpha = 0 dies';
dies_ok { bedroc(\@s, \@l, alpha => -5) }       'negative alpha dies';
dies_ok { bedroc(\@s, \@l, top => 0) }          'top = 0 dies';
dies_ok { bedroc(\@s, \@l, top => 1.5) }        'top > 1 dies';
dies_ok { bedroc(\@sc, \@v, cutoff => 999) }    'cutoff selecting no actives dies';

unless ($INC{'Devel/Cover.pm'}) {
	no_leaks_ok { eval { bedroc(\@s, \@l, alpha => 20) } }            'bedroc: no leaks';
	no_leaks_ok { eval { bedroc(\@sc, \@v, cutoff => 6.5, top => 0.3) } } 'bedroc cutoff/top: no leaks';
	no_leaks_ok { eval { bedroc(\@sc, \@v, active_frac => 0.3, active_side => 'low', top => 0.2) } } 'bedroc active_frac: no leaks';
}

done_testing();
