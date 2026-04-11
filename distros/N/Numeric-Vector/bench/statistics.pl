#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Numeric::Vector qw(
    variance std median cumsum cumprod diff reverse clip isnan isinf isfinite
);
use Benchmark qw(cmpthese);
use POSIX qw(floor);

my $N     = 1_000;
my $ITERS = -3;

my @pa = map { rand() * 100 - 50 } 1 .. $N;
my $va = Numeric::Vector::new(\@pa);

my @special = @pa;
$special[0] = 9**9**9;
$special[1] = -9**9**9;
$special[2] = 9**9**9 - 9**9**9;
my $vspec = Numeric::Vector::new(\@special);

print "=== Statistics (n=$N) ===\n";

print "\n-- variance --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->variance() },
    'NV func' => sub { nvec_variance($va) },
    'Perl'    => sub {
        my $m = 0; $m += $_ for @pa; $m /= @pa;
        my $s = 0; $s += ($_ - $m) ** 2 for @pa;
        $s / @pa;
    },
});

print "\n-- std --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->std() },
    'NV func' => sub { nvec_std($va) },
    'Perl'    => sub {
        my $m = 0; $m += $_ for @pa; $m /= @pa;
        my $s = 0; $s += ($_ - $m) ** 2 for @pa;
        sqrt($s / @pa);
    },
});

print "\n-- median --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->median() },
    'NV func' => sub { nvec_median($va) },
    'Perl'    => sub {
        my @s = sort { $a <=> $b } @pa;
        my $mid = int(@s / 2);
        @s % 2 ? $s[$mid] : ($s[$mid - 1] + $s[$mid]) / 2;
    },
});

print "\n-- cumsum --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->cumsum() },
    'NV func' => sub { nvec_cumsum($va) },
    'Perl'    => sub { my ($acc, @out) = (0); push @out, $acc += $_ for @pa; \@out },
});

print "\n-- cumprod --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->cumprod() },
    'NV func' => sub { nvec_cumprod($va) },
    'Perl'    => sub { my ($acc, @out) = (1.0); push @out, $acc *= $_ for @pa; \@out },
});

print "\n-- diff --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->diff() },
    'NV func' => sub { nvec_diff($va) },
    'Perl'    => sub { [ map { $pa[$_ + 1] - $pa[$_] } 0 .. $#pa - 1 ] },
});

print "\n-- reverse --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->reverse() },
    'NV func' => sub { nvec_reverse($va) },
    'Perl'    => sub { [ reverse @pa ] },
});

print "\n-- clip [-10, 10] --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->clip(-10.0, 10.0) },
    'NV func' => sub { nvec_clip($va, -10.0, 10.0) },
    'Perl'    => sub { [ map { $_ < -10 ? -10 : $_ > 10 ? 10 : $_ } @pa ] },
});

print "\n-- isnan --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $vspec->isnan() },
    'NV func' => sub { nvec_isnan($vspec) },
    'Perl'    => sub { [ map { $_ != $_ ? 1.0 : 0.0 } @special ] },
});

print "\n-- isinf --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $vspec->isinf() },
    'NV func' => sub { nvec_isinf($vspec) },
    'Perl'    => sub { [ map { my $x = $_; ($x == $x && $x - $x != 0) ? 1.0 : 0.0 } @special ] },
});

print "\n-- isfinite --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $vspec->isfinite() },
    'NV func' => sub { nvec_isfinite($vspec) },
    'Perl'    => sub { [ map { my $x = $_; ($x == $x && $x - $x == 0) ? 1.0 : 0.0 } @special ] },
});
