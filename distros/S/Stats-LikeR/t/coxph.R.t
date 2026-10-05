#!/usr/bin/env perl
# coxph() cross-validated against R's survival::coxph.
#
# PROVENANCE
#
# Expected values are frozen literals produced by R 4.6.1 with the survival
# package 3.8.9 -- the reference implementation of the Cox model, and the one
# `?coxph` documents. They were printed at options(digits = 17) by the
# generator committed alongside this file as t/coxph.R.R; re-run it with
#
#     Rscript t/coxph.R.R
#
# and paste the numbers back into the table below. The test itself never calls
# R, python, or any external program, so it runs unchanged on a smoker with
# neither installed.
#
# Two corpora:
#
#  * `ovarian`, the dataset survival ships and `?coxph` uses. It has no tied
#    event times, so Efron and Breslow agree on it to the last bit -- which is
#    itself worth pinning, because a tie-handling bug that fired on untied data
#    would show up here.
#
#  * a hand-built 16-observation set with deliberate ties at t = 5 and t = 8,
#    where Efron and Breslow genuinely differ (coefficient 0.02044757 against
#    0.01822431 on one covariate). Every value in it is a small integer, so it
#    is exactly representable at every NV width -- the project's rule for
#    cross-validation corpora, since a tie structure that depends on rounding
#    is a different test on a quadmath build than on a double one. `ovarian`'s
#    ages carry four decimals, which is why the tied corpus is separate rather
#    than being made by perturbing that one.
#
# TOLERANCE
#
# 1e-9 relative on coefficients, standard errors and log-likelihoods. The test
# prints the worst disagreement it actually saw as a diagnostic, so the bound
# can be re-justified on any build rather than taken on faith. Observed worst
# across all 22 quantities and both tie methods, on every perl in the local
# support matrix:
#
#     perl-5.44.0        double            8.88e-16
#     perl-5.44.0+x87    double, x87       8.88e-16
#     perl-5.42.3        double, threads   8.88e-16
#     perl-5.10.1        double            8.88e-16
#     perl-5.12.5        long double       3.64e-16
#     5.44.0-quadmath    __float128        3.64e-16
#     5.44.0-i686        double, ivsize 4  1.11e-15
#
# So between 2 and 5 ulp of a double: the fit agrees with survival's to very
# nearly the last bit, and 1e-9 leaves about seven decimal digits of headroom.
# The bound is deliberately far looser than the observation, because a Newton
# iteration's stopping point is the kind of thing that shifts by an iteration
# on a different libm; it is not there to paper over anything. Do not widen it
# to make a failure pass -- a real divergence here means the risk sets or the
# tie correction moved.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR ();

# ---------------------------------------------------------------- corpora
my %ovarian = (
    time => [ 59, 115, 156, 421, 431, 448, 464, 475, 477, 563, 638, 744, 769,
              770, 803, 855, 1040, 1106, 1129, 1206, 1227, 268, 329, 353, 365,
              377 ],
    status => [ 1,1,1,0,1,0,1,1,0,1,1,0,0,0,0,0,0,0,0,0,0,1,1,1,1,0 ],
    age => [ 72.3315, 74.4932, 66.4658, 53.3644, 50.3397, 56.4301, 56.937,
             59.8548, 64.1753, 55.1781, 56.7562, 50.1096, 59.6301, 57.0521,
             39.2712, 43.1233, 38.8932, 44.6, 53.9068, 44.2055, 59.589,
             74.5041, 43.137, 63.2192, 64.4247, 58.3096 ],
    rx => [ 1,1,1,2,1,1,2,2,1,2,1,2,2,2,1,1,1,1,2,2,2,1,1,2,2,2 ],
);

my %tied = (
    time   => [ 2,3,5,5,5,6,8,8,9,11,12,14,15,15,17,20 ],
    status => [ 1,1,1,1,0,1,1,1,0,1,1,0,1,1,1,0 ],
    x1     => [ 1,4,2,6,3,8,5,7,2,9,4,6,8,1,3,5 ],
    x2     => [ 0,1,0,1,1,0,1,0,1,1,0,0,1,0,1,1 ],
);

# ------------------------------------------------- frozen R 4.6.1 / survival
# survival 3.8.9, options(digits = 17). See t/coxph.R.R.
my @expect = (
    {   name => 'ovarian ~ age, efron', data => \%ovarian, ties => 'efron',
        cov  => ['age'],
        coef => [0.16161985740631596], se => [0.049740124502642168],
        loglik => -27.838147291082471, loglik0 => -34.984940371162558,
    },
    {   name => 'ovarian ~ age, breslow', data => \%ovarian, ties => 'breslow',
        cov  => ['age'],
        coef => [0.16161985740631596], se => [0.049740124502642168],
        loglik => -27.838147291082471, loglik0 => -34.984940371162558,
    },
    {   name => 'ovarian ~ age + rx, efron', data => \%ovarian, ties => 'efron',
        cov  => [ 'age', 'rx' ],
        coef => [ 0.147326595469114, -0.80397301266511445 ],
        se   => [ 0.046147047740802638, 0.63204937187945009 ],
        loglik => -27.041898863008388,
    },
    {   name => 'ovarian ~ age + rx, breslow', data => \%ovarian, ties => 'breslow',
        cov  => [ 'age', 'rx' ],
        coef => [ 0.147326595469114, -0.80397301266511445 ],
        se   => [ 0.046147047740802638, 0.63204937187945009 ],
        loglik => -27.041898863008388,
    },
    {   name => 'tied ~ x1, efron', data => \%tied, ties => 'efron',
        cov  => ['x1'],
        coef => [0.020447571340250856], se => [0.12261958284589614],
        loglik => -24.484178170719364, loglik0 => -24.49807400217874,
    },
    {   name => 'tied ~ x1, breslow', data => \%tied, ties => 'breslow',
        cov  => ['x1'],
        coef => [0.018224309699935503], se => [0.12140032188856019],
        loglik => -24.953961951545029, loglik0 => -24.965224562442067,
    },
    {   name => 'tied ~ x1 + x2, efron', data => \%tied, ties => 'efron',
        cov  => [ 'x1', 'x2' ],
        coef => [ 0.060344110434177013, -0.74901653829834902 ],
        se   => [ 0.1271563692129864, 0.65159080758658017 ],
        loglik => -23.812888487726326,
    },
    {   name => 'tied ~ x1 + x2, breslow', data => \%tied, ties => 'breslow',
        cov  => [ 'x1', 'x2' ],
        coef => [ 0.057216465855524937, -0.69889434100456838 ],
        se   => [ 0.12618446419390986, 0.64745482922368325 ],
        loglik => -24.363410299882101,
    },
);

# Relative agreement; see the TOLERANCE note in the header for the 1e-9.
my $TOL = 1e-9;

# The worst disagreement this run actually saw, reported at the end the way
# t/var_sd_cov.R.t reports its own. That number is what justifies $TOL, so it
# is printed rather than left to be re-derived by hand on the next build width.
my ( $worst, $worst_what ) = ( 0, '(none)' );

sub close_to {
    my ( $got, $want, $label ) = @_;
    if ( !defined $got ) { fail("$label (got undef)"); return }
    my $scale = abs($want) > 1 ? abs($want) : 1;
    my $rel   = abs( $got - $want ) / $scale;
    if ( $rel > $worst ) { $worst = $rel; $worst_what = $label }
    ok( $rel <= $TOL, sprintf( '%s: within %g (rel %.3g)', $label, $TOL, $rel ) )
        or diag("  got  $got\n  want $want");
}

for my $c (@expect) {
    my $d = $c->{data};
    my @cols = map { $d->{$_} } @{ $c->{cov} };
    my $x = @cols == 1 ? $cols[0] : \@cols;
    my $fit = Stats::LikeR::coxph( $d->{time}, $d->{status}, $x,
        ties => $c->{ties} );

    ok( ref $fit eq 'HASH', "$c->{name}: returns a hashref" ) or next;
    is( scalar @{ $fit->{coef} }, scalar @{ $c->{coef} },
        "$c->{name}: one coefficient per covariate" );
    for my $j ( 0 .. $#{ $c->{coef} } ) {
        close_to( $fit->{coef}[$j], $c->{coef}[$j], "$c->{name}: coef[$j]" );
        close_to( $fit->{se}[$j],   $c->{se}[$j],   "$c->{name}: se[$j]" );
    }
    close_to( $fit->{loglik}, $c->{loglik}, "$c->{name}: loglik" );
    close_to( $fit->{'loglik_null'}, $c->{loglik0}, "$c->{name}: loglik null" )
        if defined $c->{loglik0};
    is( $fit->{n}, scalar @{ $d->{time} }, "$c->{name}: n" );
    ok( $fit->{converged}, "$c->{name}: converged" );
}

# Efron and Breslow must actually differ on the tied corpus -- otherwise the
# `ties` argument is being ignored and every check above would still pass.
{
    my $e = Stats::LikeR::coxph( $tied{time}, $tied{status}, $tied{x1}, ties => 'efron' );
    my $b = Stats::LikeR::coxph( $tied{time}, $tied{status}, $tied{x1}, ties => 'breslow' );
    ok( abs( $e->{coef}[0] - $b->{coef}[0] ) > 1e-6,
        'ties => efron and breslow differ on tied event times' );
}

# ------------------------------------------------- argument validation
# A sparse vector -- a hole left by delete, or by assigning past the end --
# used to reach SvNV(*av_fetch(...)) and take the interpreter out with SIGSEGV,
# uncatchably. Every one of these must be an ordinary croak.
{
    my @good_t = @{ $tied{time} };
    my @good_s = @{ $tied{status} };
    my @good_x = @{ $tied{x1} };

    my @cases = (
        [ 'hole in time', sub { my @t = @good_t; delete $t[3];
                Stats::LikeR::coxph( \@t, \@good_s, \@good_x ) }, qr/coxph: time at index 3/ ],
        [ 'hole in status', sub { my @s = @good_s; delete $s[4];
                Stats::LikeR::coxph( \@good_t, \@s, \@good_x ) }, qr/coxph: status at index 4/ ],
        [ 'hole in covariate', sub { my @x = @good_x; delete $x[5];
                Stats::LikeR::coxph( \@good_t, \@good_s, \@x ) }, qr/coxph: covariate value at index 5/ ],
        [ 'hole in one of several covariates', sub { my @x = @good_x; delete $x[6];
                Stats::LikeR::coxph( \@good_t, \@good_s, [ \@x, $tied{x2} ] ) },
            qr/coxph: covariate value at index 6/ ],
        [ 'undef in time', sub { my @t = @good_t; $t[2] = undef;
                Stats::LikeR::coxph( \@t, \@good_s, \@good_x ) }, qr/coxph: time at index 2 is undef/ ],
        [ 'non-numeric time', sub { my @t = @good_t; $t[1] = 'abc';
                Stats::LikeR::coxph( \@t, \@good_s, \@good_x ) },
            qr/coxph: time at index 1 is not a number/ ],
        [ 'non-numeric covariate', sub { my @x = @good_x; $x[0] = 'zz';
                Stats::LikeR::coxph( \@good_t, \@good_s, \@x ) },
            qr/coxph: covariate value at index 0 is not a number/ ],
        [ 'covariate slot is not an array ref', sub {
                Stats::LikeR::coxph( \@good_t, \@good_s, [ 'nope', $tied{x2} ] ) },
            qr/coxph: covariate/ ],
    );
    for my $c (@cases) {
        my ( $label, $cb, $re ) = @$c;
        my $lived = eval { $cb->(); 1 };
        ok( !$lived, "$label: croaks rather than dying by signal" );
        like( $@, $re, "$label: message names the offending index" ) if !$lived;
    }
}

diag( sprintf 'worst relative disagreement with R: %.3g on %s (limit %g)',
    $worst, $worst_what, $TOL );

done_testing;
