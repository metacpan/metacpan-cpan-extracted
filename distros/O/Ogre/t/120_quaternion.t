#!/usr/bin/perl

use strict;
use warnings;

use Math::Trig;

use lib 't';
use Ogre::TestBase qw(floats_close_enough);
use Test::More tests => 14;


BEGIN {
    use_ok('Ogre');
    use_ok('Ogre::Degree');
    use_ok('Ogre::Quaternion');
    use_ok('Ogre::Radian');
    use_ok('Ogre::Vector3');
}


my $test = 'new():';
my $q = Ogre::Quaternion->new();
isa_ok($q, 'Ogre::Quaternion');


my $q4 = Ogre::Quaternion->new(5,4,3,2);
isa_ok($q4, 'Ogre::Quaternion');


my $qq = Ogre::Quaternion->new($q4);
isa_ok($qq, 'Ogre::Quaternion');


# (Matrix3)


my $r = Ogre::Radian->new(pi);
my $v = Ogre::Vector3->new(2,3,4);
my $qrv = Ogre::Quaternion->new($r, $v);
isa_ok($qrv, 'Ogre::Quaternion');


my $d = Ogre::Degree->new(180);
my $qdv = Ogre::Quaternion->new($d, $v);
isa_ok($qdv, 'Ogre::Quaternion');


my $vx = Ogre::Vector3->new(1,0,0);
my $vy = Ogre::Vector3->new(0,1,0);
my $vz = Ogre::Vector3->new(0,0,1);
my $qvvv = Ogre::Quaternion->new($vx, $vy, $vz);
isa_ok($qvvv, 'Ogre::Quaternion');


# my $q0 = Ogre::Quaternion->new();
# Note: I've not been able to get == to work
#ok($q0 == $q, '$q0 == $q');

ok($qrv != $q, '$qrv != $q');


my $qy = Ogre::Quaternion->new(0,0,0,1);
my $vq = $qy * $vx;
isa_ok($vq, 'Ogre::Vector3');
ok(floats_close_enough($vq->x, -1), "mult q*v: v.x == -1");
