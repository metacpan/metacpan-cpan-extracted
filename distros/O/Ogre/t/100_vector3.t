#!/usr/bin/perl

use strict;
use warnings;

use lib 't';
use Ogre::TestBase qw(floats_close_enough);
use Test::More tests => 45;


BEGIN {
    use_ok('Ogre');
    use_ok('Ogre::Vector3');
}


my $test = 'new():';
# xxx: ->new() doesn't seem to actually initialize to 0...
my $v = Ogre::Vector3->new(0, 0, 0);
isa_ok($v, 'Ogre::Vector3');
ok(floats_close_enough($v->x, 0), "$test x == 0");
ok(floats_close_enough($v->y, 0), "$test y == 0");
ok(floats_close_enough($v->z, 0), "$test z == 0");
ok(floats_close_enough($v->length, 0), "$test length");
ok($v->isZeroLength, "$test isZeroLength");


$test = 'new(2):';
my $v1 = Ogre::Vector3->new(2);
isa_ok($v1, 'Ogre::Vector3');
ok(floats_close_enough($v1->x, 2), "$test x == 2");
ok(floats_close_enough($v1->y, 2), "$test y == 2");
ok(floats_close_enough($v1->z, 2), "$test z == 2");
ok(floats_close_enough($v1->length, sqrt(2*2+2*2+2*2)), "$test length");
ok(floats_close_enough($v1->squaredLength, 2*2+2*2+2*2), "$test squaredLength");


$test = 'new(-2,-2,-2):';
my $v3 = Ogre::Vector3->new(-2,-2,-2);
isa_ok($v3, 'Ogre::Vector3');
ok(floats_close_enough($v3->x, -2), "$test x == -2");
ok(floats_close_enough($v3->y, -2), "$test y == -2");
ok(floats_close_enough($v3->z, -2), "$test z == -2");
ok(floats_close_enough($v3->length, sqrt(2*2+2*2+2*2)), "$test length");
ok(floats_close_enough($v3->squaredLength, 2*2+2*2+2*2), "$test squaredLength");
ok($v3->positionEquals(Ogre::Vector3->new(-2,-2,-2)), "$test positionEquals");
ok($v3->positionCloses(Ogre::Vector3->new(-2,-2,-2)), "$test positionCloses");


$test = 'v, v3:';
ok(floats_close_enough($v->distance($v3), $v3->length), "$test distance");
$test = 'v1, v3:';
ok(floats_close_enough($v1->squaredDistance($v3), 4*4+4*4+4*4), "$test squaredDistance");

ok(floats_close_enough($v1->dotProduct($v3), -2*2+-2*2+-2*2), "$test dotProduct");
ok(floats_close_enough($v1->absDotProduct($v3), abs(-2*2+-2*2+-2*2)), "$test absDotProduct");


$test = 'new(3,0,0):';
my $v3x = Ogre::Vector3->new(3, 0, 0);
isa_ok($v3x, 'Ogre::Vector3');
ok(floats_close_enough($v3x->x, 3), "$test x == 3");
ok(floats_close_enough($v3x->y, 0), "$test y == 0");
ok(floats_close_enough($v3x->z, 0), "$test z == 0");

$test = 'normalised:';
$v3x->normalise();
ok(floats_close_enough($v3x->x, 1), "$test x == 1");
ok(floats_close_enough($v3x->y, 0), "$test y == 0");
ok(floats_close_enough($v3x->z, 0), "$test z == 0");
ok(! $v3x->isZeroLength, "$test not isZeroLength");

$test = 'makeCeil($v1):';
$v3x->makeCeil($v1);
ok(floats_close_enough($v3x->x, 2), "$test x == 2");
ok(floats_close_enough($v3x->y, 2), "$test y == 2");
ok(floats_close_enough($v3x->z, 2), "$test z == 2");

$test = 'makeFloor($v3):';
$v3x->makeFloor($v3);
ok(floats_close_enough($v3x->x, -2), "$test x == -2");
ok(floats_close_enough($v3x->y, -2), "$test y == -2");
ok(floats_close_enough($v3x->z, -2), "$test z == -2");

ok($v3x == $v3, '$v3x == $v3');
ok($v3x != $v1, '$v3x != $v1');
ok($v3x < $v1, '$v3x < $v1');
ok($v1 > $v3x, '$v1 > $v3x');

my $negv3x = - $v3x;
ok($v3x->x == -$negv3x->x, '- $v3x');
