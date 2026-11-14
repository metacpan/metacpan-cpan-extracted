#!/usr/bin/env perl
#
# A formula term whose name is a UTF-8 string must find its column.  Up to
# 0.3418 the lookup used the formula's bytes as a byte key, so with `use utf8`
# data keys the column was never found and lm() died with "0 degrees of
# freedom".
#
# Provenance: R 4.6.1, options(digits=17), lm(y ~ e) with
# y = c(1,2,3.5,4,5.5,7) and e = 1:6 (Intercept -0.26666666666666661, slope
# 1.17142857142857149), and e = c(2,1,4,3,6,5) (0.33333333333333348, 1).
# R's column names do not matter to the fit; only the data do.
#
# Output names: the coefficient names are the formula's own bytes, unflagged,
# so for a flagged formula they are the UTF-8 encoding of the name (what
# Encode::encode_utf8() of the name gives), not the characters; the names are
# looked up again by predict() through the same two-way lookup.
require 5.010; use strict; use warnings FATAL => 'all';
use utf8;
use Test::More;
use Encode ();
use Stats::LikeR;

my @y = (1,2,3.5,4,5.5,7);
my %want = ("é" => [-0.26666666666666661, 1.17142857142857149],
            "Ω" => [0.33333333333333348, 1]);
my %col  = ("é" => [1..6], "Ω" => [2,1,4,3,6,5]);
sub near { my ($g, $w, $n) = @_; cmp_ok(abs($g - $w), '<=', 1e-10, $n) or diag("got $g want $w") }

for my $nm (sort keys %want) {
	my $lab = sprintf 'U+%04X', ord $nm;	# ASCII label: a wide character in a test name warns
	my $bytes = Encode::encode_utf8($nm);
	my $hoa = { y => \@y, $nm => $col{$nm} };
	my $aoh = [ map { { y => $y[$_], $nm => $col{$nm}[$_] } } 0 .. 5 ];
	for my $shape (['HoA', $hoa], ['AoH', $aoh]) {
		for my $glmfn (['lm',  sub { lm(formula => $_[0], data => $_[1]) }],
		               ['glm', sub { glm(formula => $_[0], data => $_[1], family => 'gaussian') }]) {
			my $r = eval { $glmfn->[1]->("y ~ $nm", $shape->[1]) };
			ok($r, "$glmfn->[0] $shape->[0] $lab: fits") or diag($@);
			next unless $r;
			near($r->{coefficients}{Intercept}, $want{$nm}[0], "$glmfn->[0] $shape->[0] $lab: intercept");
			near($r->{coefficients}{$bytes}, $want{$nm}[1], "$glmfn->[0] $shape->[0] $lab: slope under the formula's bytes");
		}
	}
	# a byte-string formula and byte-string keys keep working as before
	my $r = lm(formula => "y ~ $bytes", data => { y => \@y, $bytes => $col{$nm} });
	near($r->{coefficients}{$bytes}, $want{$nm}[1], "$lab: byte formula, byte key");
	# predict() on the fitted model
	my $m = lm(formula => "y ~ $nm", data => $hoa);
	my ($p) = values %{ predict($m, { $nm => [10] }) };
	near($p, $want{$nm}[0] + 10 * $want{$nm}[1], "$lab: predict() finds the column and the coefficient");
}
# a Latin-1 byte formula against a flagged key
{
	my %e = (y => \@y, "\xe9" => [1..6]);
	my $r = lm(formula => "y ~ \xe9", data => \%e);
	near($r->{coefficients}{"\xe9"}, 1.17142857142857149, 'latin-1 formula, latin-1 key');
}
done_testing;
