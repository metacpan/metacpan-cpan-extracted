#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Numeric::Vector qw(
    exp log log10 log2 sqrt abs floor ceil round sign
    sin cos tan asin acos atan sinh cosh tanh
);
use Benchmark qw(cmpthese);
use POSIX qw(floor ceil);

my $N     = 1_000;
my $ITERS = -3;
my $LN2   = log(2);
my $LN10  = log(10);

my @pa    = map { rand() * 0.9 + 0.1 } 1 .. $N;   # (0.1, 1.0) — safe for log/asin/acos
my @unit  = map { rand() * 1.8 - 0.9 } 1 .. $N;   # (-0.9, 0.9) — safe for asin/acos
my @mixed = map { rand() * 200 - 100 } 1 .. $N;

my $va    = Numeric::Vector::new(\@pa);
my $vunit = Numeric::Vector::new(\@unit);
my $vmix  = Numeric::Vector::new(\@mixed);

print "=== Math functions (n=$N) ===\n";

print "\n-- exp --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->exp() },
    'NV func' => sub { nvec_exp($va) },
    'Perl'    => sub { [ map { exp($_) } @pa ] },
});

print "\n-- log --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->log() },
    'NV func' => sub { nvec_log($va) },
    'Perl'    => sub { [ map { log($_) } @pa ] },
});

print "\n-- log10 --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->log10() },
    'NV func' => sub { nvec_log10($va) },
    'Perl'    => sub { [ map { log($_) / $LN10 } @pa ] },
});

print "\n-- log2 --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->log2() },
    'NV func' => sub { nvec_log2($va) },
    'Perl'    => sub { [ map { log($_) / $LN2 } @pa ] },
});

print "\n-- sqrt --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->sqrt() },
    'NV func' => sub { nvec_sqrt($va) },
    'Perl'    => sub { [ map { sqrt($_) } @pa ] },
});

print "\n-- abs --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $vmix->abs() },
    'NV func' => sub { nvec_abs($vmix) },
    'Perl'    => sub { [ map { abs($_) } @mixed ] },
});

print "\n-- floor --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $vmix->floor() },
    'NV func' => sub { nvec_floor($vmix) },
    'Perl'    => sub { [ map { floor($_) } @mixed ] },
});

print "\n-- ceil --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $vmix->ceil() },
    'NV func' => sub { nvec_ceil($vmix) },
    'Perl'    => sub { [ map { ceil($_) } @mixed ] },
});

print "\n-- round --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $vmix->round() },
    'NV func' => sub { nvec_round($vmix) },
    'Perl'    => sub { [ map { floor($_ + 0.5) } @mixed ] },
});

print "\n-- sign --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $vmix->sign() },
    'NV func' => sub { nvec_sign($vmix) },
    'Perl'    => sub { [ map { $_ > 0 ? 1.0 : $_ < 0 ? -1.0 : 0.0 } @mixed ] },
});

print "\n-- sin --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->sin() },
    'NV func' => sub { nvec_sin($va) },
    'Perl'    => sub { [ map { sin($_) } @pa ] },
});

print "\n-- cos --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->cos() },
    'NV func' => sub { nvec_cos($va) },
    'Perl'    => sub { [ map { cos($_) } @pa ] },
});

print "\n-- tan --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->tan() },
    'NV func' => sub { nvec_tan($va) },
    'Perl'    => sub { [ map { sin($_) / cos($_) } @pa ] },
});

print "\n-- asin --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $vunit->asin() },
    'NV func' => sub { nvec_asin($vunit) },
    'Perl'    => sub { [ map { atan2($_, sqrt(1 - $_ * $_)) } @unit ] },
});

print "\n-- acos --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $vunit->acos() },
    'NV func' => sub { nvec_acos($vunit) },
    'Perl'    => sub { [ map { atan2(sqrt(1 - $_ * $_), $_) } @unit ] },
});

print "\n-- atan --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->atan() },
    'NV func' => sub { nvec_atan($va) },
    'Perl'    => sub { [ map { atan2($_, 1) } @pa ] },
});

print "\n-- sinh --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->sinh() },
    'NV func' => sub { nvec_sinh($va) },
    'Perl'    => sub { [ map { (exp($_) - exp(-$_)) / 2 } @pa ] },
});

print "\n-- cosh --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->cosh() },
    'NV func' => sub { nvec_cosh($va) },
    'Perl'    => sub { [ map { (exp($_) + exp(-$_)) / 2 } @pa ] },
});

print "\n-- tanh --\n";
cmpthese($ITERS, {
    'NV OO'   => sub { $va->tanh() },
    'NV func' => sub { nvec_tanh($va) },
    'Perl'    => sub {
        [ map { my ($ep, $em) = (exp($_), exp(-$_)); ($ep - $em) / ($ep + $em) } @pa ]
    },
});
