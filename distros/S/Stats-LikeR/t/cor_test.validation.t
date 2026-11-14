#!/usr/bin/env perl
# cor_test() refuses a bad alternative and a bad conf_level.
#
# PROVENANCE
#
# R 4.6.1 src/library/stats/R/cor.test.R, cor.test.default(): alternative goes
# through match.arg(alternative) (an unlisted value is an error), and
#   if(!((length(conf.level) == 1L) && is.finite(conf.level) &&
#        (conf.level > 0) && (conf.level < 1)))
#       stop("'conf.level' must be a single number between 0 and 1")
# The module takes the same extra spellings of "two.sided" that t_test() does
# ("two-sided", "two_sided"). The inputs are invented (R has no test of the
# error paths); the rules are R's. Leak checks follow t/croak.leaks.t and need
# the optional Test::LeakTrace, skipping without it.
require 5.010; use strict; use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR ();
my $HAVE_LEAKTRACE;
BEGIN {
	if (eval { require Test::LeakTrace; 1 }) { Test::LeakTrace->import("no_leaks_ok"); $HAVE_LEAKTRACE = 1 }
	else { *no_leaks_ok = sub (&;$) { SKIP: { skip "Test::LeakTrace not installed", 1 } }; $HAVE_LEAKTRACE = 0 }
}

my ($x, $y) = ([1, 2, 3, 4, 5, 6, 7, 8], [2, 1, 4, 3, 7, 5, 8, 6]);
for my $m (qw(pearson kendall spearman)) {
	for my $alt ('bogus', 'TWO.SIDED', '', 'two') {
		eval { Stats::LikeR::cor_test($x, $y, method => $m, alternative => $alt) };
		like($@, qr/cor_test: .*'alternative' must be 'two.sided', 'less' or 'greater', not '\Q$alt\E'/, "$m alternative '$alt' refused");
	}
	for my $cl (5, -1, 0, 1, 'nan', 'inf') {
		eval { Stats::LikeR::cor_test($x, $y, method => $m, conf_level => $cl) };
		like($@, qr/cor_test: .*'conf_level' must be between 0 and 1/, "$m conf_level $cl refused");
	}
	for my $alt (qw(two.sided less greater two-sided two_sided)) {
		my $r = eval { Stats::LikeR::cor_test($x, $y, method => $m, alternative => $alt, exact => 0) };
		ok($r, "$m alternative $alt accepted") or diag $@;
		is($r->{alternative}, $alt =~ /^two/ ? 'two.sided' : $alt, "$m alternative $alt echoed in R's spelling") if $r;
	}
}
# the all-named call form is validated too
eval { Stats::LikeR::cor_test(x => $x, y => $y, alternative => 'bogus') };
like($@, qr/'alternative' must be/, 'named form: alternative');
eval { Stats::LikeR::cor_test(x => $x, y => $y, conf_level => 5) };
like($@, qr/'conf_level' must be between 0 and 1/, 'named form: conf_level');
# a legal conf_level still works
my $r = Stats::LikeR::cor_test($x, $y, conf_level => 0.9);
ok($r->{conf_int}[0] < $r->{estimate} && $r->{estimate} < $r->{conf_int}[1], 'conf_level 0.9 gives an interval about the estimate');

# no leaks on the refusals (the alternative text must not outlive the call)
no_leaks_ok { eval { Stats::LikeR::cor_test($x, $y, alternative => 'bogus') } } 'alternative croak does not leak';
no_leaks_ok { eval { Stats::LikeR::cor_test($x, $y, conf_level => 5) } } 'conf_level croak does not leak';
done_testing;
