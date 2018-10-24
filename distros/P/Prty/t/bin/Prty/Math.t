#!/usr/bin/env perl

package Prty::Math::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

use Prty::Time;;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Math');
}

# -----------------------------------------------------------------------------

sub test_pi : Test(2) {
    my $self = shift;

    my $pi = Prty::Math->pi;
    $self->ok($pi > 3.1415926);
    $self->ok($pi < 3.1415927);
}

# -----------------------------------------------------------------------------

sub test_roundTo : Test(4) {
    my $self = shift;

    my $y = Prty::Math->roundTo(5.735,2);
    $self->is($y,'5.74');

    $y = Prty::Math->roundTo(5.7,2);
    $self->is($y,'5.70');

    $y = Prty::Math->roundTo(599,2);
    $self->is($y,'599.00');

    $y = Prty::Math->roundTo(599,2,1);
    $self->is($y,'599');
}

# -----------------------------------------------------------------------------

sub test_roundToInt : Test(7) {
    my $self = shift;

    my @arg = (0.4999, 0.5, 1.5, 2.5, 3.5, -0.5, -1.5);
    my @val = (0,      1,   2,   3,   4,   -1,   -2);

    for (my $i = 0; $i < @arg; $i++) {
        my $val = Prty::Math->roundToInt($arg[$i]);
        $self->is($val,$val[$i]);
    }
}

# -----------------------------------------------------------------------------

sub test_roundMinMax : Test(6) {
    my $self = shift;

    my ($min,$max) = Prty::Math->roundMinMax(8.53,8.73);
    $self->is($min,8.5);
    $self->is($max,8.8);

    ($min,$max) = Prty::Math->roundMinMax(8.53,8.53);
    $self->is($min,7);
    $self->is($max,10);

    ($min,$max) = Prty::Math->roundMinMax(-9.65,-4);
    $self->is($min,-10);
    $self->is($max,-4);
}

# -----------------------------------------------------------------------------

sub test_gcd : Test(2) {
    my $self = shift;

    my $n = Prty::Math->gcd(2,5);
    $self->is($n,1);

    $n = Prty::Math->gcd(2,4);
    $self->is($n,2);
}

# -----------------------------------------------------------------------------

sub test_degreeToRad : Test(6) {
    my $self = shift;

    my $pi = Prty::Math->pi;

    # 1° ~ 0.017453293 rad

    my $y = sprintf '%.9f',Prty::Math->degreeToRad(1);
    $self->is($y,0.017453293);

    $y = Prty::Math->degreeToRad(0);
    $self->is($y,0);

    $y = Prty::Math->degreeToRad(90);
    $self->is($y,$pi/2);

    $y = Prty::Math->degreeToRad(180);
    $self->is($y,$pi);

    $y = Prty::Math->degreeToRad(270);
    $self->is($y,1.5*$pi);

    $y = Prty::Math->degreeToRad(360);
    $self->is($y,2*$pi);
}

# -----------------------------------------------------------------------------

sub test_radToDegree : Test(1) {
    my $self = shift;

    # 1 rad ~ 57.29577951°

    my $grad = sprintf '%.8f',Prty::Math->radToDegree(1);
    $self->is($grad,57.29577951);
}

# -----------------------------------------------------------------------------

sub test_geoMidpoint_with_weight : Test(2) {
    my $self = shift;

    my ($latitude,$longitude) = Prty::Math->geoMidpoint([
        [40.7143528,-74.0059731,1095.75],
        [41.8781136,-87.6297982,730.5],
        [33.7489954,-84.3879824,365.25],
    ]);

    # Fix: CPAN Testers
    $self->floatIs($latitude,40.1156886102644);
    $self->floatIs($longitude,-80.2996028062865);
}

# -----------------------------------------------------------------------------

sub test_geoMidpoint_without_weight : Test(2) {
    my $self = shift;

    my ($latitude,$longitude) = Prty::Math->geoMidpoint([
        [40.7143528,-74.0059731],
        [41.8781136,-87.6297982],
        [33.7489954,-84.3879824],
    ]);

    # Fix: CPAN Testers
    $self->floatIs($latitude,38.9224184710314);
    $self->floatIs($longitude,-82.0561504698106);
}

# -----------------------------------------------------------------------------

sub test_geoToDegree : Test(7) {
    my $self = shift;

    my $val = Prty::Math->geoToDegree(50,6,44);
    $self->floatIs($val,50.11222);

    $val = Prty::Math->geoToDegree(50,6,44);
    $self->floatIs($val,50.11222);

    $val = Prty::Math->geoToDegree(50,6,44,'N');
    $self->floatIs($val,50.11222);

    $val = Prty::Math->geoToDegree(50,6,44,'S');
    $self->floatIs($val,-50.11222);

    $val = Prty::Math->geoToDegree(50,6,44,'E');
    $self->floatIs($val,50.11222);

    $val = Prty::Math->geoToDegree(50,6,44,'W');
    $self->floatIs($val,-50.11222);

    eval { Prty::Math->geoToDegree(50,6,44,'X') };
    $self->like($@,qr/MATH-00001/);
}

# -----------------------------------------------------------------------------

sub test_geoDistance : Test(6) {
    my $self = shift;

    # Abstand zw. zwei Längengraden (9. und 10.) am Äquator

    my $km = sprintf '%.2f',Prty::Math->geoDistance(0,359,0,360);
    $self->is($km,111.12); # 40.003,2/360 = 60*1.852 (1.852 km = 1 Seemeile)

    # Abstand zw. zwei Längengraden am Pol

    $km = Prty::Math->geoDistance(90,9,90,10);
    $self->is($km,0);

    # Halber Erdumfang am Äquator

    $km = Prty::Math->geoDistance(0,0,0,180);
    $self->is($km,20_001.6);

    # Abstand Äquator / Pol

    $km = Prty::Math->geoDistance(0,0,90,0);
    $self->is($km,10_000.8);

    # Abstand zw. zwei Längengraden 48° n.B.

    $km = sprintf '%.2f',Prty::Math->geoDistance(48,9,48,10);
    $self->is($km,74.35);

    # Abstand zw. zwei Längengraden 49° n.B.

    $km = sprintf '%.2f',Prty::Math->geoDistance(49,9,49,10);
    $self->is($km,'72.90');
}

# -----------------------------------------------------------------------------

sub test_latitudeDistance : Test(4) {
    my $self = shift;

    # Abstand zw. zwei Längengraden am Äquator

    my $km = sprintf '%.2f',Prty::Math->latitudeDistance(0);
    $self->is($km,111.12); # ~ 40.000/360

    # Abstand zw. zwei Längengraden am Pol

    $km = Prty::Math->latitudeDistance(90);
    $self->is($km,0);

    # Abstand zw. zwei Längengraden 48° n.B.

    $km = sprintf '%.2f',Prty::Math->latitudeDistance(48);
    $self->is($km,74.35);

    # Abstand zw. zwei Längengraden 49° n.B.

    $km = sprintf '%.2f',Prty::Math->latitudeDistance(49);
    $self->is($km,'72.90');
}

# -----------------------------------------------------------------------------

sub test_valueToPixelFactor : Test(2) {
    my $self = shift;

    my $fac = Prty::Math->valueToPixelFactor(100,0,10);
    $self->is($fac,9.9);

    $fac = Prty::Math->valueToPixelFactor(100,10,35);
    $self->is($fac,3.96);
}

# -----------------------------------------------------------------------------

sub test_interpolate : Test(3) {
    my $self = shift;

    my $y = Prty::Math->interpolate(0,0,2,2,1);
    $self->is($y,1);

    $y = Prty::Math->interpolate(2,2,1,1,1.5);
    $self->is($y,1.5);

    $y = Prty::Math->interpolate(1000,1,2000,2,1500);
    $self->is($y,1.5);
}

# -----------------------------------------------------------------------------

sub test_isNumber : Test(10) {
    my $self = shift;

    my $bool = Prty::Math->isNumber(undef);
    $self->is($bool,0);

    $bool = Prty::Math->isNumber('');
    $self->is($bool,0);

    $bool = Prty::Math->isNumber('x');
    $self->is($bool,0);

    $bool = Prty::Math->isNumber('x1');
    $self->is($bool,0);

    $bool = Prty::Math->isNumber('1x');
    $self->is($bool,0);

    $bool = Prty::Math->isNumber(1);
    $self->is($bool,1);

    $bool = Prty::Math->isNumber(-1);
    $self->is($bool,1);

    $bool = Prty::Math->isNumber(+1);
    $self->is($bool,1);

    $bool = Prty::Math->isNumber(1.23);
    $self->is($bool,1);

    $bool = Prty::Math->isNumber(-1.23);
    $self->is($bool,1);
}

# -----------------------------------------------------------------------------

sub test_spikeValue : Test(39) {
    my $self = shift;

    my $csvFile = Prty::Test::Class->testPath(
       't/data/csv/spike-test.csv');

    my @arr;
    my $fh = Prty::FileHandle->new('<',$csvFile);
    while (<$fh>) {
        chomp;
        my $row = [split /;/];
        my ($m,$d,$y,$h,$mi,$s) = split /\D+/,$row->[0];
        $row->[0] = Prty::Time->new($y,$m,$d,$h,$mi,$s)->epoch;
        push @arr,$row;
    }
    $fh->close;

    for (my $i = 1; $i < @arr-1; $i++) {
        my $v1 = $arr[$i-1]->[1]; # Messwert vor dem gesteten Messwert
        my $v2 = $arr[$i]->[1];   # getesteter Messwert
        my $v3 = $arr[$i+1]->[1]; # Messwert nach dem gesteten Messwert

        my $t1 = $arr[$i-1]->[0]; # Zeitpunkt Messwert 1 in Sekunden
        my $t3 = $arr[$i+1]->[0]; # Zeitpunkt Messwert 3 in Sekunden

        my $v = Prty::Math->spikeValue($v1,$v2,$v3,$t1,$t3);
        # MEMO: Die Werte in der Tabelle sind um Faktor 2 zu groß,
        # daher multiplizieren wir $v mit 2.
        $self->floatIs($v*2,$arr[$i]->[4],5);
    }

    return;
}

# -----------------------------------------------------------------------------

package main;
Prty::Math::Test->runTests;

# eof
