#!/usr/bin/env perl
#
# lm_read_rows() -- the reader behind lm(), glm(), anova(), aov(), vif() and
# the mf_rows() family -- must give the same answer whatever order perl hands
# back a hash's keys.
#
# Provenance: no R or SciPy test covers this, because R's data.frame() has no
# hash order to depend on. The cases are this module's own, for a data-handling
# rule with no reference analogue: the frame is {x => 1..5, y => (2,1,5,3,7),
# z => (1,3,2,5,4)}, and the expected values are worked by hand from it:
#   y ~ x:        intercept 0, slope 1.2 (Sxy = 12, Sxx = 10, means 3 and 3.6),
#                 RSS 8.8 (Syy = 20.8 less 12 * 1.2)
#   y ~ x + z:    RSS 0.0888888888888889 (R's lm on the same five rows)
#   vif(x, z):    1 / (1 - r^2) with r = 0.8, so 2.77777777777778 each
# They were also confirmed against the same call on a frame with none of the
# extra keys.
#
# Up to 0.3413 the row count came from whichever entry hv_iternext() returned
# first: a row-name column that came first and was shorter or longer than the
# data made every data column fail the length check, and a scalar entry that
# came first croaked "Hash values must be ArrayRefs". Order is varied two
# ways: many distinct key names for the row-name column and the scalar entry
# (each lands in a different bucket), and child perls run under fixed
# PERL_HASH_SEED values, spawned with the list form of system() so that no
# shell is involved.
#
# Tolerance 1e-9: the arithmetic is a few dozen flops on small integers, so the
# worst disagreement seen was ~1e-15 on a double perl, and long double and
# quadmath builds are closer still.
require 5.010; use strict; use warnings FATAL => 'all';
use Test::More;
use File::Temp qw(tempdir);
use Stats::LikeR;

my $tol = 1e-9;
my @ROWNAME_KEYS = qw(row_names _row rownames .rownames);

sub frame {
	my %extra = @_;
	return { x => [1 .. 5], y => [2, 1, 5, 3, 7], z => [1, 3, 2, 5, 4], %extra };
}

# every call under test, with the value it must return on the frame above
my %CALL = (
	lm_slope  => [sub { lm(formula => 'y ~ x', data => $_[0])->{coefficients}{x} }, 1.2],
	lm_icept  => [sub { lm(formula => 'y ~ x', data => $_[0])->{coefficients}{Intercept} }, 0],
	glm_slope => [sub { glm(formula => 'y ~ x', data => $_[0])->{coefficients}{x} }, 1.2],
	anova_rss => [sub { anova($_[0], 'y ~ x', 'y ~ x + z')->[1]{RSS} }, 0.0888888888888889],
	aov_ss    => [sub { aov($_[0], 'y ~ x')->{x}{'Sum Sq'} }, 14.4],
	vif_x     => [sub { vif($_[0], 'y ~ x + z')->{x} }, 2.77777777777778],
);

# name keys, short, long and exact length, and a scalar entry under many names
my @NAME_COLS = (['a', 'b'], ['a' .. 'i'], ['a' .. 'e']);
my $nvariants = 0;
for my $call (sort keys %CALL) {
	my ($code, $want) = @{ $CALL{$call} };
	my $bad = 0;
	for my $rk (@ROWNAME_KEYS) {
		for my $names (@NAME_COLS) {
			for my $i (1 .. 12) {
				my $d = frame($rk => [@$names], "k$i" => [1 .. 5]);
				$d->{"note$i"} = 'meta';
				my $got = $code->($d);
				$nvariants++;
				$bad++ unless abs($got - $want) < $tol;
			}
		}
	}
	is($bad, 0, "$call: a row-name column of any length, and a scalar entry, never change the fit");
}

# the row names a short column leaves unfilled are 1..n, as the comment says
for my $i (1 .. 12) {
	my $d = frame(row_names => ['a', 'b'], "n$i" => 'meta');
	my $fv = lm(formula => 'y ~ x', data => $d)->{fitted_values};
	is_deeply([sort keys %$fv], [qw(3 4 5 a b)], "short row_names filled with 1..n (variant $i)");
}

# a scalar entry is ignored wherever it falls, never a croak
for my $i (1 .. 30) {
	my $d = frame("meta$i" => 'text');
	my $s = eval { lm(formula => 'y ~ x', data => $d)->{coefficients}{x} };
	ok(defined $s && abs($s - 1.2) < $tol, "scalar entry meta$i is ignored") or diag $@;
}

# no ArrayRef and no HashRef anywhere: still the old croak
like(eval { lm(formula => 'y ~ x', data => { x => 'a', y => 'b' }); 1 } ? '' : $@,
     qr/Hash values must be ArrayRefs \(HoA\) or HashRefs \(HoH\)/, 'scalars only croak');

# a ragged frame croaks whatever the order; the message names one of the two columns
for my $i (1 .. 12) {
	my $d = frame("r$i" => [1, 2, 3]);
	like(eval { lm(formula => 'y ~ x', data => $d); 1 } ? '' : $@,
	     qr/HoA columns have unequal lengths/, "ragged column r$i croaks");
}

# a HoH is still a HoH, and a non-hash row in it still croaks
{
	my %h = map { ("r$_" => { x => $_, y => (2, 1, 5, 3, 7)[$_ - 1] }) } 1 .. 5;
	my $s = lm(formula => 'y ~ x', data => \%h)->{coefficients}{x};
	ok(abs($s - 1.2) < $tol, 'HoH slope');
	$h{bad} = 'meta';
	like(eval { lm(formula => 'y ~ x', data => \%h); 1 } ? '' : $@,
	     qr/Hash values must all be HashRefs \(HoH\)/, 'HoH with a scalar row croaks');
}

# child perls under fixed hash seeds: the confirmed failing frame, 24 seeds
my $dir = tempdir(CLEANUP => 1);
my $script = "$dir/child.pl";
open my $fh, '>', $script or die "$script: $!";
print $fh <<'CHILD';
use strict; use warnings;
use Stats::LikeR;
my $d = { row_names => ['a', 'b'], x => [1 .. 5], y => [2, 1, 5, 3, 7], k1 => [1 .. 5], note => 'meta' };
my $c = lm(formula => 'y ~ x', data => $d)->{coefficients}{x};
print abs($c - 1.2) < 1e-9 ? "ok\n" : "bad $c\n";
CHILD
close $fh;
my @inc = map { "-I$_" } @INC;
my $badseed = 0;
for my $seed (0 .. 23) {
	local $ENV{PERL_HASH_SEED} = $seed;
	local $ENV{PERL_PERTURB_KEYS} = 0;
	my $out = "$dir/out.$seed";
	open my $save, '>&', \*STDOUT or die $!;
	open STDOUT, '>', $out or die $!;
	my $rc = system($^X, @inc, $script);
	open STDOUT, '>&', $save or die $!;
	open my $in, '<', $out or die $!;
	my $line = <$in> // '';
	$badseed++ unless $rc == 0 && $line eq "ok\n";
}
is($badseed, 0, 'PERL_HASH_SEED 0..23: the frame fits under every seed');

done_testing();
