#!/usr/bin/env perl
#
# cov() and cor_test() must free their number buffers when a cell's FETCH
# dies.  Up to 0.3418 both leaked them (cor() was fixed in 0.3413): about
# 8 bytes a cell per call, 242 MB of RSS over 20000 calls at n = 1000.
# No R/SciPy reference applies: this is a resource test, the numeric results
# are pinned by t/cor.t.
#
# Test::LeakTrace counts SVs and so cannot see a C buffer; the RSS check below
# is what catches this leak.  The threshold is a measured one: 3000 calls at
# n = 1000 grew RSS by 35 MB in cov() before the fix and by 8 KB after; 10 MB
# is between them.  Linux only (/proc).  cor_test() could not leak this way
# before the fix because it never ran the FETCH that dies (it tested the cell's
# definedness before its get magic), so for it the first loop is the regression
# and its RSS check only guards against a future leak.
require 5.010; use strict; use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR;

{ package Dying; sub TIEARRAY { bless { n => 1000 }, shift }
  sub FETCH { die "boom\n" if $_[1] == 500; $_[1] } sub FETCHSIZE { $_[0]{n} } }
tie my @t, 'Dying';
my @y = (1 .. 1000);

for my $call (['cov', sub { cov(\@t, \@y) }],
              ['cov spearman', sub { cov(\@t, \@y, 'spearman') }],
              ['cor_test', sub { cor_test(\@t, \@y) }]) {
	eval { $call->[1]->() };
	is($@, "boom\n", "$call->[0]: the FETCH's die comes through");
}

sub rss_kb {
	open my $fh, '<', '/proc/self/status' or return;
	while (<$fh>) { return $1 if /^VmRSS:\s+(\d+)/ }
	return;
}
SKIP: {
	skip 'no /proc/self/status', 3 unless defined rss_kb();	# platform, not a reference implementation
	for my $call (['cov', sub { cov(\@t, \@y) }],
	              ['cov spearman', sub { cov(\@t, \@y, 'spearman') }],
	              ['cor_test', sub { cor_test(\@t, \@y) }]) {
		eval { $call->[1]->() } for 1 .. 200;	# warm up
		my $before = rss_kb();
		eval { $call->[1]->() } for 1 .. 3000;
		cmp_ok(rss_kb() - $before, '<', 10_000, "$call->[0]: no growth over 3000 dying calls");
	}
}
done_testing;
