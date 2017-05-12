#!/usr/bin/perl

use strict;
use warnings;

use Math::Trig;

use lib 't';
use Ogre::TestBase qw(floats_close_enough);
use Test::More tests => 17;


BEGIN {
    use_ok('Ogre');
    use_ok('Ogre::Radian');
}


my $test = 'new():';
my $r = Ogre::Radian->new();
isa_ok($r, 'Ogre::Radian');
ok(floats_close_enough($r->valueRadians, 0), "$test valueRadians == 0");
ok(floats_close_enough($r->valueDegrees, 0), "$test valueDegrees == 0");


$test = 'new(pi)';
my $rPi = Ogre::Radian->new(pi);
isa_ok($rPi, 'Ogre::Radian');
ok(floats_close_enough($rPi->valueRadians, pi), "$test valueRadians == pi");
ok(floats_close_enough($rPi->valueDegrees, 180), "$test valueDegrees == 180");


$test = 'new($d)';
my $d = Ogre::Degree->new(0);
my $rd = Ogre::Radian->new($d);
isa_ok($rd, 'Ogre::Radian');
ok(floats_close_enough($rd->valueRadians, 0), "$test valueRadians == 0");
ok(floats_close_enough($rd->valueDegrees, 0), "$test valueDegrees == 0");


$test = '$r == $rd';
ok($r == $rd, $test);

$test = '$r != $rPi';
ok($r != $rPi, $test);

$test = '$r < $rPi';
ok($r < $rPi, $test);

$test = '$rPi > $r';
ok($rPi > $r, $test);

$test = '$r <= $rd';
ok($r <= $rd, $test);

$test = '$r >= $rd';
ok($r >= $rd, $test);

