#!/usr/bin/env perl
# A trailing option name with no value is refused, not dropped.
#
# PROVENANCE
#
# No R or SciPy counterpart: this is a Perl call-syntax rule, taken from what
# survfit(), logrank_test(), coxph(), prop_test() and bedroc() already do
# ("options must be key => value pairs", pinned by their own tests). Up to
# 0.3419 epi_2x2(), cmh_test(), bw_nrd0() and bw_nrd() looped while
# i + 1 < items and so never saw a last key: cmh_test($strata, 'correct')
# silently ran with the default. Cases are invented around that rule.
require 5.010; use strict; use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR ();
my $HAVE_LEAKTRACE;
BEGIN {
	if (eval { require Test::LeakTrace; 1 }) { Test::LeakTrace->import("no_leaks_ok"); $HAVE_LEAKTRACE = 1 }
	else { *no_leaks_ok = sub (&;$) { SKIP: { skip "Test::LeakTrace not installed", 1 } }; $HAVE_LEAKTRACE = 0 }
}

my $strata = [[[2, 3], [3, 4]], [[3, 2], [2, 3]]];
my $x = [1, 2, 4, 8, 3, 9, 5, 6, 7, 2.5];
my @bad = (
	['cmh_test', sub { Stats::LikeR::cmh_test($strata, 'correct') }, qr/cmh_test: .*key => value pairs/],
	['cmh_test after a pair', sub { Stats::LikeR::cmh_test($strata, conf_level => 0.9, 'correct') }, qr/cmh_test: .*key => value pairs/],
	['epi_2x2 four cells', sub { Stats::LikeR::epi_2x2(10, 5, 3, 8, 'conf_level') }, qr/epi_2x2: .*key => value pairs/],
	['epi_2x2 array ref', sub { Stats::LikeR::epi_2x2([[10, 5], [3, 8]], 'correct') }, qr/epi_2x2: .*key => value pairs/],
	['bw_nrd0', sub { Stats::LikeR::bw_nrd0($x, 'x') }, qr/bw_nrd0: .*key => value pairs/],
	['bw_nrd', sub { Stats::LikeR::bw_nrd($x, 'x') }, qr/bw_nrd: .*key => value pairs/],
);
for my $c (@bad) {
	my ($name, $code, $re) = @$c;
	eval { $code->() };
	like($@, $re, "$name: dangling key refused");
	no_leaks_ok { eval { $code->() } } "$name: refusal does not leak";
}
# the well-formed calls still work, with and without options
ok(eval { Stats::LikeR::cmh_test($strata, correct => 0) }, 'cmh_test correct => 0') or diag $@;
ok(eval { Stats::LikeR::cmh_test($strata) }, 'cmh_test no options') or diag $@;
ok(eval { Stats::LikeR::epi_2x2(10, 5, 3, 8, conf_level => 0.9) }, 'epi_2x2 four cells with an option') or diag $@;
ok(eval { Stats::LikeR::epi_2x2([[10, 5], [3, 8]]) }, 'epi_2x2 array ref alone') or diag $@;
ok(eval { Stats::LikeR::bw_nrd0(x => $x) }, 'bw_nrd0 named x') or diag $@;
ok(eval { Stats::LikeR::bw_nrd($x) }, 'bw_nrd positional x') or diag $@;
done_testing;
