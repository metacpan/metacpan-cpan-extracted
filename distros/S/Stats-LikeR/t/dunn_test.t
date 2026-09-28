#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

sub is_approx {
	my ($got, $expected, $name, $eps) = @_;
	$eps = 1e-6 if not defined $eps;
	if (abs($got - $expected) <= $eps) { pass("$name: within $eps"); return 1; }
	fail($name); diag("  got: $got\n  expected: $expected");
	return 0;
}
sub by_comp { my ($r,$c)=@_; for (@$r) { return $_ if $_->{comparison} eq $c } undef }

# Reference values from the canonical Dunn (1964) formula in base R
# (rank + Kruskal-Wallis tie correction + p.adjust), two-sided.
my @x = (2.1,3.4,1.9,5.6,4.2, 6.1,7.3,5.9,8.2,6.6, 3.3,4.4,2.2,3.3,5.5);
my @g = ((('A') x 5), (('B') x 5), (('C') x 5));

# Z statistics and raw p-values (method-independent)
{
	my $r  = dunn_test(\@x, \@g, method => 'holm');
	is(scalar(@$r), 3, 'three pairwise comparisons for k=3');
	my $ab = by_comp($r, 'A - B');
	my $ac = by_comp($r, 'A - C');
	my $bc = by_comp($r, 'B - C');
	is_approx($ab->{Z}, -2.760182, 'A-B Z');
	is_approx($ac->{Z}, -0.212322, 'A-C Z');
	is_approx($bc->{Z},  2.547860, 'B-C Z');
	is_approx($ab->{'p.value'}, 0.005777, 'A-B raw p');
	is_approx($bc->{'p.value'}, 0.010839, 'B-C raw p');
	# Holm-adjusted
	is_approx($ab->{'p.adjust'}, 0.017331, 'A-B holm');
	is_approx($ac->{'p.adjust'}, 0.831856, 'A-C holm');
	is_approx($bc->{'p.adjust'}, 0.021677, 'B-C holm');
}

# Benjamini-Hochberg
{
	my $r  = dunn_test(\@x, \@g, method => 'bh');
	is_approx(by_comp($r,'A - B')->{'p.adjust'}, 0.016258, 'A-B BH');
	is_approx(by_comp($r,'B - C')->{'p.adjust'}, 0.016258, 'B-C BH');
}

# Bonferroni
{
	my $r  = dunn_test(\@x, \@g, method => 'bonferroni');
	is_approx(by_comp($r,'A - B')->{'p.adjust'}, 0.017331, 'A-B bonferroni');
	is_approx(by_comp($r,'A - C')->{'p.adjust'}, 1.0,      'A-C bonferroni capped at 1');
	is_approx(by_comp($r,'B - C')->{'p.adjust'}, 0.032516, 'B-C bonferroni');
}

# 'none' leaves raw p-values unchanged
{
	my $r = dunn_test(\@x, \@g, method => 'none');
	my $ab = by_comp($r, 'A - B');
	is_approx($ab->{'p.adjust'}, $ab->{'p.value'}, "method 'none' equals raw p");
}

# error handling
throws_ok { dunn_test(\@x, [ ('A') x 14 ]) } qr/same length/, 'length mismatch rejected';
throws_ok { dunn_test(\@x, \@g, method => 'bogus') } qr/unknown method/, 'bad method rejected';
# Method names fold case by ASCII rules, whatever LC_CTYPE says (up to 0.319
# this was tolower(), which under a Turkish locale folds I outside ASCII).
is_deeply(dunn_test(\@x, \@g, method => "BONFERRONI"),
	dunn_test(\@x, \@g, method => "bonferroni"), "method is case-insensitive");
throws_ok { dunn_test(\@x, \@g, method => "b\xc9") } qr/unknown method/,
	"a method name with a byte >= 0x80 is rejected, not folded";

# Devel::Cover's own per-line counters are allocated inside whatever block is
# running and are reported as leaks, so the check is skipped under it.
no_leaks_ok {
	dunn_test(\@x, \@g, method => 'holm');
	dunn_test(\@x, \@g, method => 'bh');
} 'dunn_test does not leak' unless $INC{'Devel/Cover.pm'};

done_testing();
