#!/usr/bin/env perl
#
# Tied-scalar cells are fetched exactly once, and the value tested is the
# value used.  Up to 0.3418 cov(), cor() and cor_test() ran a cell's FETCH
# twice (once for the numeric test, once to read it), and the formula data
# readers (lm() and friends) read an element's definedness before running its
# FETCH, so a tied scalar in a hash-of-arrays column read as missing.
#
# Provenance: R 4.6.1, options(digits=17): cov(c(1,5,2,8,3), 1:5) = 1.75,
# cor(...) = 0.3988620176087328, cor.test(...)$estimate = the same; and
# lm(y ~ x) for x = 1:8, y = c(2.1,3.9,6.2,7.8,10.1,12.2,13.8,16.1) gives
# Intercept 0.035714285714285587, slope 1.9976190476190476.
require 5.010; use strict; use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR;

{ package Cnt;
  our $n = 0;
  sub TIESCALAR { my ($c, $v) = @_; bless { v => $v }, $c }
  sub FETCH { $n++; $_[0]{v} }
  sub STORE {} }

sub tied_array { my @a; $#a = $#_; for my $i (0 .. $#_) { tie $a[$i], 'Cnt', $_[$i] } return \@a }
sub near { my ($g, $w, $n) = @_; cmp_ok(abs($g - $w), '<=', 1e-12, $n) or diag("got $g want $w") }

my @x = (1,5,2,8,3);
$Cnt::n = 0; near(cov(tied_array(@x), [1..5]), 1.75, 'cov value');
is($Cnt::n, 5, 'cov: one FETCH per cell');
$Cnt::n = 0; near(cor(tied_array(@x), [1..5]), 0.3988620176087328, 'cor value');
is($Cnt::n, 5, 'cor: one FETCH per cell');
$Cnt::n = 0;
my $ct = cor_test(tied_array(@x), [1..5]);
near($ct->{estimate}, 0.3988620176087328, 'cor_test estimate');
is($Cnt::n, 5, 'cor_test: one FETCH per cell');

# a value that changes on each FETCH must not be tested as one thing and used as another
{ package Flip; sub TIESCALAR { bless { n => 0 }, shift } sub FETCH { $_[0]{n}++ ? 'abc' : 7 } sub STORE {} }
my @f; $#f = 2; tie $f[0], 'Flip'; $f[1] = 2; $f[2] = 3;
my $c = cov(\@f, [1,2,3]);
ok(!defined $c || $c == $c, 'cov: a flipping cell is read once (no mixed test and use)');

# the formula data path: tied scalars in HoA columns
my @xs = (1..8); my @ys = (2.1,3.9,6.2,7.8,10.1,12.2,13.8,16.1);
$Cnt::n = 0;
my $r = lm(formula => 'y ~ x', data => { x => tied_array(@xs), y => tied_array(@ys) });
near($r->{coefficients}{Intercept}, 0.035714285714285587, 'lm over tied cells: intercept');
near($r->{coefficients}{x}, 1.9976190476190476, 'lm over tied cells: slope');
done_testing;
