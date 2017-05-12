#!/usr/bin/perl

use strict;
use warnings;

use lib 't';
use Ogre::TestBase qw(floats_close_enough);
use Test::More tests => 34;


BEGIN {
    use_ok('Ogre');
    use_ok('Ogre::Vector2');
}


my $test = 'new():';
# xxx: ->new() doesn't seem to actually initialize to 0...
my $v = Ogre::Vector2->new(0, 0);
isa_ok($v, 'Ogre::Vector2');
ok(floats_close_enough($v->x, 0), "$test x == 0");
ok(floats_close_enough($v->y, 0), "$test y == 0");
ok(floats_close_enough($v->length, 0), "$test length");
ok($v->isZeroLength, "$test isZeroLength");


$test = 'new(2):';
my $v1 = Ogre::Vector2->new(2);
isa_ok($v1, 'Ogre::Vector2');
ok(floats_close_enough($v1->x, 2), "$test x == 2");
ok(floats_close_enough($v1->y, 2), "$test y == 2");
ok(floats_close_enough($v1->length, sqrt(2*2+2*2)), "$test length");
ok(floats_close_enough($v1->squaredLength, 2*2+2*2), "$test squaredLength");


$test = 'new(-2,-2):';
my $v2 = Ogre::Vector2->new(-2,-2);
isa_ok($v2, 'Ogre::Vector2');
ok(floats_close_enough($v2->x, -2), "$test x == -2");
ok(floats_close_enough($v2->y, -2), "$test y == -2");
ok(floats_close_enough($v2->length, sqrt(2*2+2*2)), "$test length");
ok(floats_close_enough($v2->squaredLength, 2*2+2*2), "$test squaredLength");


ok(floats_close_enough($v1->dotProduct($v2), -2*2+-2*2), "$test dotProduct");
ok(floats_close_enough($v1->crossProduct($v2), 2*-2-(-2*2)), "$test crossProduct");


$test = 'new(3,0):';
my $v3x = Ogre::Vector2->new(3, 0);
isa_ok($v3x, 'Ogre::Vector2');
ok(floats_close_enough($v3x->x, 3), "$test x == 3");
ok(floats_close_enough($v3x->y, 0), "$test y == 0");

$test = 'normalised:';
$v3x->normalise();
ok(floats_close_enough($v3x->x, 1), "$test x == 1");
ok(floats_close_enough($v3x->y, 0), "$test y == 0");
ok(! $v3x->isZeroLength, "$test not isZeroLength");


$test = 'makeCeil($v1):';
$v3x->makeCeil($v1);
ok(floats_close_enough($v3x->x, 2), "$test x == 2");
ok(floats_close_enough($v3x->y, 2), "$test y == 2");

$test = 'makeFloor($v2):';
$v3x->makeFloor($v2);
ok(floats_close_enough($v3x->x, -2), "$test x == -2");
ok(floats_close_enough($v3x->y, -2), "$test y == -2");


SKIP: {
    skip "overloaded operators not implemented yet", 5;

    ok($v3x == $v2, '$v3x == $v2');
    ok($v3x != $v1, '$v3x != $v1');
    ok($v3x < $v1, '$v3x < $v1');
    ok($v1 > $v3x, '$v1 > $v3x');

    my $negv3x = - $v3x;
    ok($v3x->x == -$negv3x->x, '- $v3x');
}
