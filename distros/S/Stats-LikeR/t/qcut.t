#!/usr/bin/env perl

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::LeakTrace;
use Stats::LikeR;

sub is_approx {
	my ($got, $exp, $msg, $tol) = @_;
	$tol = 1e-9 unless defined $tol;
	ok(abs($got - $exp) < $tol, $msg)
		or diag("got $got, expected $exp (tolerance $tol)");
}

# --- default return is the edge list (numpy/pandas linear interpolation) ----
{
	my @edges = qcut([1 .. 10], 4);
	my @want  = (1, 3.25, 5.5, 7.75, 10);
	is(scalar @edges, scalar @want, 'four bins -> five edges (list, not ref)');
	for my $i (0 .. $#want) {
		is_approx($edges[$i], $want[$i], "edge $i matches pandas");
	}
}

# --- codes are opt-in -------------------------------------------------------
{
	my $codes = qcut([1 .. 10], 4, codes => 1);
	is(ref $codes, 'ARRAY', 'codes => 1 returns an arrayref');
	is_deeply($codes, [0, 0, 0, 1, 1, 2, 2, 3, 3, 3], 'quartile codes match pandas');
}

# --- both edges and codes in one pass ---------------------------------------
{
	my ($codes, $edges) = qcut([1 .. 10], 4, codes => 1, edges => 1);
	is(ref $codes, 'ARRAY', 'both: first return is codes ref');
	is(ref $edges, 'ARRAY', 'both: second return is edges ref');
	is_approx($edges->[-1], 10, 'both: edges intact');
}

# --- equal-frequency counts -------------------------------------------------
{
	my $codes = qcut([1 .. 100], 4, codes => 1);
	my %n;
	$n{$_}++ for @$codes;
	is($n{$_}, 25, "bin $_ holds 25 of 100") for 0 .. 3;
}

# --- explicit probability vector (top-5% tranche) ---------------------------
{
	my @edges = qcut([1 .. 100], [0, 0.5, 0.95, 1]);
	is(scalar @edges, 4, 'three bands -> four edges');

	my $codes = qcut([1 .. 100], [0, 0.5, 0.95, 1], codes => 1);
	my %n;
	$n{$_}++ for @$codes;
	is($n{0}, 50, 'lower-half tranche');
	is($n{1}, 45, 'mid tranche');
	is($n{2},  5, 'top-5% tranche');
}

# --- named and interval labels (imply codes) --------------------------------
{
	my $lab = qcut([1 .. 10], 4, labels => [qw/Q1 Q2 Q3 Q4/]);
	is_deeply($lab, [qw/Q1 Q1 Q1 Q2 Q2 Q3 Q3 Q4 Q4 Q4/], 'named labels applied');

	my $iv = qcut([1 .. 10], 4, labels => 'interval');
	is($iv->[0],  '[1, 3.25]',  'first interval is closed-closed');
	is($iv->[-1], '(7.75, 10]', 'last interval is open-closed');
}

# --- NA (undef) passes through codes ----------------------------------------
{
	my $codes = qcut([1, 2, undef, 4, 5, 6, 7, 8, 9, 10], 4, codes => 1);
	ok(!defined $codes->[2], 'undef stays undef');
	is($codes->[0], 0, 'value before NA binned correctly');
	is($codes->[9], 3, 'value after NA binned correctly');
}

# --- duplicate edges: raise by default, drop on request ---------------------
{
	my @tied = ((0) x 8, 1, 2, 3, 4);
	my $err = !eval { my @e = qcut(\@tied, 4); 1 };
	ok($err && $@ =~ /not unique/, 'tied data raises on duplicate edges');

	my @edges = qcut(\@tied, 4, duplicates => 'drop');
	ok(scalar @edges < 5, 'dropping merges duplicate edges');
}

# --- help: qcut('h') / qcut('H') dies with a help string --------------------
{
	for my $arg (qw/h H/) {
		my $err = !eval { qcut($arg); 1 };
		ok($err, "qcut('$arg') dies");
		like($@, qr/equal-frequency binning/, "qcut('$arg') emits help text");
	}
}

# --- leak checks (assignments hoisted out for Devel::Cover) ------------------
{
	my @data  = map { $_ / 7 } 1 .. 500;
	my @tied  = ((0) x 50, 1, 2, 3, 4, 5);
	my @probs = (0, 0.25, 0.5, 0.75, 1);

	no_leaks_ok { eval { my @x = qcut(\@data, 10) } } 'qcut: no leaks (edges only, default)';
	no_leaks_ok { eval { my $x = qcut(\@data, 10, codes => 1) } } 'qcut: no leaks (codes)';
	no_leaks_ok { eval { my ($c, $e) = qcut(\@data, 10, codes => 1, edges => 1) } } 'qcut: no leaks (both)';
	no_leaks_ok { eval { my @x = qcut(\@data, \@probs) } } 'qcut: no leaks (probability vector)';
	no_leaks_ok { eval { my $x = qcut(\@data, 4, labels => [qw/a b c d/]) } } 'qcut: no leaks (labels)';
	no_leaks_ok { eval { my @x = qcut(\@tied, 4, duplicates => 'drop') } } 'qcut: no leaks (drop dups)';
	no_leaks_ok { eval { my @x = qcut(\@tied, 4) } } 'qcut: no leaks (croak path)';
	no_leaks_ok { eval { qcut('h') } } 'qcut: no leaks (help/die path)';
}

done_testing();
