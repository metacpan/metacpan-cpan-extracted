#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Numeric::Vector qw(sum product mean min max dot norm normalize argmin argmax);
use Benchmark qw(cmpthese);

my $N     = 1_000;
my $ITERS = -3;

my @pa = map { rand() + 0.1 } 1 .. $N;
my @pb = map { rand() + 0.1 } 1 .. $N;

my $va = Numeric::Vector::new(\@pa);
my $vb = Numeric::Vector::new(\@pb);

print "=== Reductions (n=$N) ===\n";

print "\n-- sum --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->sum() },
    'NV func' => sub { nvec_sum($va) },
    'Perl'    => sub { my $s = 0; $s += $_ for @pa; $s },
});

print "\n-- product --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->product() },
    'NV func' => sub { nvec_product($va) },
    'Perl'    => sub { my $p = 1.0; $p *= $_ for @pa; $p },
});

print "\n-- mean --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->mean() },
    'NV func' => sub { nvec_mean($va) },
    'Perl'    => sub { my $s = 0; $s += $_ for @pa; $s / @pa },
});

print "\n-- min --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->min() },
    'NV func' => sub { nvec_min($va) },
    'Perl'    => sub { my $m = $pa[0]; for (@pa) { $m = $_ if $_ < $m } $m },
});

print "\n-- max --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->max() },
    'NV func' => sub { nvec_max($va) },
    'Perl'    => sub { my $m = $pa[0]; for (@pa) { $m = $_ if $_ > $m } $m },
});

print "\n-- dot --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->dot($vb) },
    'NV func' => sub { nvec_dot($va, $vb) },
    'Perl'    => sub { my $s = 0; $s += $pa[$_] * $pb[$_] for 0 .. $#pa; $s },
});

print "\n-- norm --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->norm() },
    'NV func' => sub { nvec_norm($va) },
    'Perl'    => sub { my $s = 0; $s += $_ * $_ for @pa; sqrt($s) },
});

print "\n-- normalize --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->normalize() },
    'NV func' => sub { nvec_normalize($va) },
    'Perl'    => sub {
        my $s = 0; $s += $_ * $_ for @pa;
        my $inv = $s > 0 ? 1.0 / sqrt($s) : 0.0;
        [ map { $_ * $inv } @pa ];
    },
});

print "\n-- argmin --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->argmin() },
    'NV func' => sub { nvec_argmin($va) },
    'Perl'    => sub {
        my ($idx, $m) = (0, $pa[0]);
        for my $i (1 .. $#pa) { if ($pa[$i] < $m) { $m = $pa[$i]; $idx = $i } }
        $idx;
    },
});

print "\n-- argmax --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->argmax() },
    'NV func' => sub { nvec_argmax($va) },
    'Perl'    => sub {
        my ($idx, $m) = (0, $pa[0]);
        for my $i (1 .. $#pa) { if ($pa[$i] > $m) { $m = $pa[$i]; $idx = $i } }
        $idx;
    },
});
