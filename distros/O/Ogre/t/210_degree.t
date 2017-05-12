#!/usr/bin/perl

use strict;
use warnings;

use Math::Trig;

use lib 't';
use Ogre::TestBase qw(floats_close_enough);
use Test::More tests => 17;


BEGIN {
    use_ok('Ogre');
    use_ok('Ogre::Degree');
}


my $test = 'new():';
my $d = Ogre::Degree->new();
isa_ok($d, 'Ogre::Degree');
ok(floats_close_enough($d->valueDegrees, 0), "$test valueDegrees == 0");
ok(floats_close_enough($d->valueRadians, 0), "$test valueRadians == 0");


$test = 'new(180)';
my $d180 = Ogre::Degree->new(180);
isa_ok($d180, 'Ogre::Degree');
ok(floats_close_enough($d180->valueDegrees, 180), "$test valueDegrees == 180");
ok(floats_close_enough($d180->valueRadians, pi), "$test valueRadians == pi");


$test = 'new($r)';
my $r = Ogre::Radian->new(0);
my $dr = Ogre::Degree->new($r);
isa_ok($dr, 'Ogre::Degree');
ok(floats_close_enough($dr->valueDegrees, 0), "$test valueDegrees == 0");
ok(floats_close_enough($dr->valueRadians, 0), "$test valueRadians == 0");


$test = '$d == $dr';
ok($d == $dr, $test);

$test = '$d != $d180';
ok($d != $d180, $test);

$test = '$d < $d180';
ok($d < $d180, $test);

$test = '$d180 > $d';
ok($d180 > $d, $test);

$test = '$d <= $dr';
ok($d <= $dr, $test);

$test = '$d >= $dr';
ok($d >= $dr, $test);

