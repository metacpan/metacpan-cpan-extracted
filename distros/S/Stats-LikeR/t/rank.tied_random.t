#!/usr/bin/env perl
#
# Regression tests for three rank() bugs found by the 2026-11-02 read of
# LikeR.xs, all fixed in the same edit:
#
# - ties_method => 'random' called Drand01() without AUTO_SEED_PRNG(), so a
#   process that had never called srand() drew from an unseeded generator and
#   every run broke ties in the same order (1 2 3 6 7 4 5 8 for eight ties, on
#   every run).  runif(), sample() and the rest already seeded first.
# - Elements were read with a raw av_fetch() and tested with SvOK() before
#   their get magic ran, so every element of a tied array read as undef:
#   rank(\@tied) of (3, 1, 2) returned 1 2 3, the ranks of three NAs.
# - The four work buffers were freed by hand at the end, so a croak part-way
#   through leaked them.  Test::LeakTrace counts SVs, not Newx() buffers, so
#   that part is checked only as "the croak propagates and the next call
#   works"; the fix is SAVEFREEPV() on each buffer.
#
# Nothing here comes from R or SciPy: R has no tied vectors, and the random
# case asserts only that an unseeded process is not deterministic and that a
# seed is, not which permutation a seed gives (that is libc's business on some
# builds and perl's on others; see t/srand.stream.t).

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use File::Temp qw(tempfile);
use lib 'blib/lib', 'blib/arch';
use Stats::LikeR qw(rank);

{
	package TieCount;	# a tied scalar that counts its FETCHes
	sub TIESCALAR { my ($c, $v) = @_; bless { v => $v, n => 0 }, $c }
	sub FETCH     { my $s = shift; $s->{n}++; $s->{v} }
	sub STORE     { $_[0]{v} = $_[1] }
}
{
	package TieGrow;	# each FETCH pushes onto the array that holds it
	sub TIESCALAR { my ($c, $v, $av) = @_; bless { v => $v, av => $av }, $c }
	sub FETCH     { my $s = shift; push @{ $s->{av} }, (1) x 1000; $s->{v} }
	sub STORE     { $_[0]{v} = $_[1] }
}
{
	package TieDie;
	sub TIESCALAR { bless {}, shift }
	sub FETCH     { die "FETCH died\n" }
	sub STORE     {}
}
require Tie::Array;

# --- tied arrays and tied elements 
{
	tie my @x, 'Tie::StdArray';
	@x = (3, 1, 2);
	is_deeply([rank(\@x)], [3, 1, 2], 'tied array is ranked by its values');

	@x = (3, undef, 2, 3);
	is_deeply([rank(\@x)], [2.5, 4, 1, 2.5], 'tied array: undef is NA, ties averaged');
	is_deeply([rank(\@x, na_last => 'keep')], [2.5, undef, 1, 2.5], 'tied array, na_last => keep');
}
{
	my @x = (5, 0, 9);
	my $t = tie $x[1], 'TieCount', 7;
	is_deeply([rank(\@x)], [1, 2, 3], 'tied element in a plain array');
	is($t->{n}, 1, 'tied element is FETCHed exactly once');
}
{
	my $v;
	my $t = tie $v, 'TieCount', 2;
	is_deeply([rank(3, $v, 1)], [3, 2, 1], 'tied scalar argument');
	is($t->{n}, 1, 'tied scalar argument is FETCHed exactly once');
}
{
	# The array grows by 1000 on every FETCH; only the three elements counted
	# before the gather are ranked, and nothing is written past the buffers.
	my @x = (2, 0, 1);
	tie $x[1], 'TieGrow', 3, \@x;
	is_deeply([rank(\@x)], [2, 3, 1], 'array grown by a FETCH: counted elements only');
	my @z = (2, 0, 1);
	tie $z[1], 'TieGrow', 3, \@z;
	my @y = (10, 20);
	is_deeply([rank(\@z, \@y)], [2, 3, 1, 4, 5],
		'array grown by a FETCH does not take a later argument\'s positions');
}
{
	my @x = (1, 2, 3);
	tie $x[1], 'TieDie';
	throws_ok { rank(\@x) } qr/^FETCH died/, 'a dying FETCH propagates';
	is_deeply([rank([2, 1])], [2, 1], 'rank works after a croak mid-gather');
}

# --- ties_method => 'random' 
{
	my @ties = (1) x 20;
	srand(42); my @a = rank(\@ties, ties_method => 'random');
	srand(42); my @b = rank(\@ties, ties_method => 'random');
	is_deeply(\@a, \@b, 'srand() makes random tie-breaking reproducible');
	is_deeply([sort { $a <=> $b } @a], [1 .. 20], 'random ranks are a permutation');
}
{
	# A fresh process that never calls srand(), run twice.  Twenty ties have
	# 20! orderings, so two seeded runs agree with probability about 4e-19.
	# The program goes in a file and is run with the list form of system(),
	# so no shell (and no cmd.exe quoting) is involved.
	my ($fh, $prog) = tempfile('rank_random_XXXX', SUFFIX => '.pl', TMPDIR => 1, UNLINK => 1);
	print {$fh} 'use Stats::LikeR qw(rank); print join(",", rank([(1) x 20], ties_method => "random"));';
	close $fh;
	my ($ofh1, $out1) = tempfile('rank_out_XXXX', TMPDIR => 1, UNLINK => 1);
	my ($ofh2, $out2) = tempfile('rank_out_XXXX', TMPDIR => 1, UNLINK => 1);
	close $ofh1; close $ofh2;
	my @run = ($^X, (map { "-I$_" } grep { !ref } @INC), $prog);
	my @got;
	for my $out ($out1, $out2) {
		open my $save, '>&', \*STDOUT or die "dup STDOUT: $!";
		open STDOUT, '>', $out or die "redirect STDOUT: $!";
		my $rc = system { $run[0] } @run;
		open STDOUT, '>&', $save or die "restore STDOUT: $!";
		is($rc, 0, 'unseeded child process ran');
		open my $in, '<', $out or die "read $out: $!";
		local $/;
		push @got, scalar <$in>;
	}
	like($got[0], qr/^\d+(,\d+){19}$/, 'unseeded child printed 20 ranks');
	isnt($got[0], $got[1], 'unseeded processes break ties differently');
}

done_testing();
