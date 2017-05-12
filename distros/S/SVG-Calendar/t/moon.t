#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 31 * 3;
use SVG::Calendar;

my @packages = qw/Astro::Coord::ECI::Moon Astro::MoonPhase /;
my %found;

for my $package (@packages) {
    my $file = $package;
    $file =~ s{::}{/}gxms;
    $file .= '.pm';

    eval{ require $file };
    next if $@;

    $found{$package} = 1;
}

my $cal = SVG::Calendar->new();

my %phases = (
    # date       => phase
    '2008-10-01' => 0.50704,
    '2008-10-02' => 0.70373,
    '2008-10-03' => 0.89713,
    '2008-10-04' => 1.08806,
    '2008-10-05' => 1.27761,
    '2008-10-06' => 1.46708,
    '2008-10-07' => 1.65794,
    '2008-10-08' => 1.85173,
    '2008-10-09' => 2.04996,
    '2008-10-10' => 2.25399,
    '2008-10-11' => 2.46489,
    '2008-10-12' => 2.68323,
    '2008-10-13' => 2.90892,
    '2008-10-14' => 3.14111,
    '2008-10-15' => 3.37819,
    '2008-10-16' => 3.61801,
    '2008-10-17' => 3.85821,
    '2008-10-18' => 4.09662,
    '2008-10-19' => 4.33158,
    '2008-10-20' => 4.56210,
    '2008-10-21' => 4.78780,
    '2008-10-22' => 5.00879,
    '2008-10-23' => 5.22545,
    '2008-10-24' => 5.43821,
    '2008-10-25' => 5.64747,
    '2008-10-26' => 5.85350,
    '2008-10-27' => 6.05645,
    '2008-10-28' => 6.25639,
    '2008-10-29' => 0.17019,
    '2008-10-30' => 0.36438,
    '2008-10-31' => 0.55607,
);

for my $package (@packages) {
    SKIP:
    {
        skip "Missing optional package $package", scalar keys %phases if !$found{$package};
        diag "Missing optional package $package ", scalar keys %phases if !$found{$package};

        $cal->{moon_phase} = $package;

        for my $date (sort keys %phases) {
            my $phase = $cal->get_moon_phase($date);
            ok( abs( $phases{$date} - $phase ) < 0.005, "For $date the phase $phase is approximatly $phases{$date} with $package" );
        }
    }
}

SKIP:
{
    skip "Missing optional all packages", scalar keys %phases if !%found;

    # let SVG::Calendar choose the best phase checking package
    delete $cal->{moon_phase};

    for my $date (keys %phases) {
        my $phase = $cal->get_moon_phase($date);
        ok( $cal->moon( phase => $phase, id => $date, x => 1, y => 1, r => 1), "SVG can be generated for this date ($date)" );
    }
}
