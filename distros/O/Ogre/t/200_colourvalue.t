#!/usr/bin/perl

use strict;
use warnings;

use lib 't';
use Ogre::TestBase qw(floats_close_enough);
use Test::More tests => 19;


BEGIN {
    use_ok('Ogre');
    use_ok('Ogre::ColourValue');
}


my $test = 'new():';
my $c = Ogre::ColourValue->new();
isa_ok($c, 'Ogre::ColourValue');
ok(floats_close_enough($c->r, 1), "$test r == 1");
ok(floats_close_enough($c->g, 1), "$test g == 1");
ok(floats_close_enough($c->b, 1), "$test b == 1");
ok(floats_close_enough($c->a, 1), "$test a == 1");


$test = 'new(0.1, 0.2, 0.3):';
my $c3 = Ogre::ColourValue->new(0.1, 0.2, 0.3);
isa_ok($c, 'Ogre::ColourValue');
ok(floats_close_enough($c3->r, 0.1), "$test r == 0.1");
ok(floats_close_enough($c3->g, 0.2), "$test g == 0.2");
ok(floats_close_enough($c3->b, 0.3), "$test b == 0.3");
ok(floats_close_enough($c3->a, 1), "$test a == 1");


$test = 'new(0.1, 0.2, 0.3, 0.4):';
my $c4 = Ogre::ColourValue->new(0.1, 0.2, 0.3, 0.4);
isa_ok($c, 'Ogre::ColourValue');
ok(floats_close_enough($c4->r, 0.1), "$test r == 0.1");
ok(floats_close_enough($c4->g, 0.2), "$test g == 0.2");
ok(floats_close_enough($c4->b, 0.3), "$test b == 0.3");
ok(floats_close_enough($c4->a, 0.4), "$test a == 0.4");


$test = '$c3 != $c4';
ok($c3 != $c4, $test);

$test = '$c == 1,1,1,1';
ok($c == Ogre::ColourValue->new(1,1,1,1), $test);

