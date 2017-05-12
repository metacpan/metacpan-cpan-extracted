#!/usr/bin/perl

use strict;
use warnings;

use lib 't';
use Ogre::TestBase qw(floats_close_enough);
use Test::More tests => 21;


BEGIN {
    use_ok('Ogre');
    use_ok('Ogre::Plane');
    use_ok('Ogre::Vector3');
}


my $vx = Ogre::Vector3->new(1, 0, 0);
my $v2 = Ogre::Vector3->new(2, 0, 0);
my $v3 = Ogre::Vector3->new(2, 1, 0);


my $test = 'new()';
my $p0 = Ogre::Plane->new();
isa_ok($p0, 'Ogre::Plane');
is($p0->d, 0, "$test d == 0");
isa_ok($p0->normal, 'Ogre::Vector3');
is($p0->normal->length, 0, "$test: length == 0");


$test = 'new(Vector3, Real)';
my $pvr = Ogre::Plane->new($vx, 10);
isa_ok($pvr, 'Ogre::Plane');
is($pvr->d, -10, "$test d == -10");
isa_ok($pvr->normal, 'Ogre::Vector3');
is($pvr->normal->length, 1, "$test: length == 1");


$test = 'new(Vector3, Vector3)';
my $pvv = Ogre::Plane->new($vx, $vx);
isa_ok($pvv, 'Ogre::Plane');
is($pvv->d, -1, "$test d == -1");
isa_ok($pvv->normal, 'Ogre::Vector3');
is($pvv->normal->length, 1, "$test: length == 1");


$test = 'new(Vector3, Vector3, Vector3)';
my $pvvv = Ogre::Plane->new($vx, $v2, $v3);
isa_ok($pvvv, 'Ogre::Plane');
# XXX: I don't know what this should be, it gives '-0'
# is($pvvv->d, -0, "$test d == -0");
isa_ok($pvvv->normal, 'Ogre::Vector3');
is($pvvv->normal->length, 1, "$test: length == 1");


$test = 'new(Plane)';
my $pp = Ogre::Plane->new($pvvv);
isa_ok($pp, 'Ogre::Plane');
# XXX: I don't know what this should be, it gives '-0'
# is($pp->d, -0, "$test d == -0");
isa_ok($pp->normal, 'Ogre::Vector3');
is($pp->normal->length, 1, "$test: length == 1");
