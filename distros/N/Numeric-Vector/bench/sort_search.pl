#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Numeric::Vector qw(sort argsort argmin argmax any all count where concat slice copy);
use Benchmark qw(cmpthese);

my $N     = 1_000;
my $ITERS = -3;

my @pa     = map { rand() * 200 - 100 } 1 .. $N;
my @pb     = map { rand() * 200 - 100 } 1 .. $N;
my @mask   = map { rand() < 0.5 ? 1.0 : 0.0 } 1 .. $N;
my @sparse = (0) x $N; $sparse[-1] = 1.0;
my @full   = (1.0) x $N; $full[-1]  = 0.0;

my $va      = Numeric::Vector::new(\@pa);
my $vb      = Numeric::Vector::new(\@pb);
my $vmask   = Numeric::Vector::new(\@mask);
my $vsparse = Numeric::Vector::new(\@sparse);
my $vfull   = Numeric::Vector::new(\@full);

print "=== Sort & Search (n=$N) ===\n";

print "\n-- sort --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->sort() },
    'NV func' => sub { nvec_sort($va) },
    'Perl'    => sub { [ sort { $a <=> $b } @pa ] },
});

print "\n-- argsort --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->argsort() },
    'NV func' => sub { nvec_argsort($va) },
    'Perl'    => sub { [ sort { $pa[$a] <=> $pa[$b] } 0 .. $#pa ] },
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

print "\n-- any (match only at end) --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $vsparse->any() },
    'NV func' => sub { nvec_any($vsparse) },
    'Perl'    => sub { my $f = 0; for (@sparse) { if ($_ != 0) { $f = 1; last } } $f },
});

print "\n-- all (fail only at end) --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $vfull->all() },
    'NV func' => sub { nvec_all($vfull) },
    'Perl'    => sub { my $ok = 1; for (@full) { if ($_ == 0) { $ok = 0; last } } $ok },
});

print "\n-- count --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $vmask->count() },
    'NV func' => sub { nvec_count($vmask) },
    'Perl'    => sub { my $c = 0; $c++ for grep { $_ != 0 } @mask; $c },
});

print "\n-- where --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->where($vmask) },
    'NV func' => sub { nvec_where($va, $vmask) },
    'Perl'    => sub { [ map { $mask[$_] ? $pa[$_] : () } 0 .. $#pa ] },
});

print "\n-- concat --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->concat($vb) },
    'NV func' => sub { nvec_concat($va, $vb) },
    'Perl'    => sub { [ @pa, @pb ] },
});

print "\n-- slice [250, 750] --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->slice(250, 750) },
    'NV func' => sub { nvec_slice($va, 250, 750) },
    'Perl'    => sub { [ @pa[250 .. 750] ] },
});

print "\n-- copy --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->copy() },
    'NV func' => sub { nvec_copy($va) },
    'Perl'    => sub { [@pa] },
});
