#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use Cwd qw(abs_path);
use Numeric::Vector qw(new ones add sub mul div scale neg add_inplace scale_inplace);
use Benchmark qw(cmpthese);

my $N     = 1_000;
my $ITERS = -3;
my $s     = 2.5;

my @pa = map { rand() + 0.1 } 1 .. $N;
my @pb = map { rand() + 0.1 } 1 .. $N;

my $va = nvec_new(\@pa);
my $vb = nvec_new(\@pb);

nvec_ones(5);

print "=== Arithmetic (n=$N) ===\n";

print "\n-- add --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->add($vb) },
    'NV func' => sub { nvec_add($va, $vb) },
    'Perl'    => sub { my @c; $c[$_] = $pa[$_] + $pb[$_] for 0 .. $#pa; \@c },
});

print "\n-- sub --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->sub($vb) },
    'NV func' => sub { nvec_sub($va, $vb) },
    'Perl'    => sub { my @c; $c[$_] = $pa[$_] - $pb[$_] for 0 .. $#pa; \@c },
});

print "\n-- mul --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->mul($vb) },
    'NV func' => sub { nvec_mul($va, $vb) },
    'Perl'    => sub { my @c; $c[$_] = $pa[$_] * $pb[$_] for 0 .. $#pa; \@c },
});

print "\n-- div --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->div($vb) },
    'NV func' => sub { nvec_div($va, $vb) },
    'Perl'    => sub { my @c; $c[$_] = $pa[$_] / $pb[$_] for 0 .. $#pa; \@c },
});

print "\n-- scale --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->scale($s) },
    'NV func' => sub { nvec_scale($va, $s) },
    'Perl'    => sub { my @c; $c[$_] = $pa[$_] * $s for 0 .. $#pa; \@c },
});

print "\n-- neg --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->neg() },
    'NV func' => sub { nvec_neg($va) },
    'Perl'    => sub { [ map { -$_ } @pa ] },
});

print "\n-- add_inplace --\n";
my $vai_oo   = Numeric::Vector::new(\@pa);
my $vai_func = Numeric::Vector::new(\@pa);
my @pai      = @pa;
cmpthese($ITERS, {
    'NV OO'   => sub { $vai_oo->add_inplace($vb) },
    'NV func' => sub { nvec_add_inplace($vai_func, $vb) },
    'Perl'    => sub { $pai[$_] += $pb[$_] for 0 .. $#pai },
});

print "\n-- scale_inplace --\n";
my $vsi_oo   = Numeric::Vector::new(\@pa);
my $vsi_func = Numeric::Vector::new(\@pa);
my @psi      = @pa;
cmpthese($ITERS, {
    'NV OO'   => sub { $vsi_oo->scale_inplace($s) },
    'NV func' => sub { nvec_scale_inplace($vsi_func, $s) },
    'Perl'    => sub { $psi[$_] *= $s for 0 .. $#psi },
});
