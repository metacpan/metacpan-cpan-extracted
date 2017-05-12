#!/usr/bin/perl

use strict;
use warnings;

use lib 't';
use Ogre::TestBase qw(floats_close_enough);
use Test::More tests => 3;


BEGIN {
    use_ok('Ogre');
    use_ok('Ogre::Root');
}


my $test = 'new():';
my $r = Ogre::Root->new();
isa_ok($r, 'Ogre::Root');


#$test = 'new(p)';
#my $r1 = Ogre::Root->new('plugins.cfg');
#isa_ok($r1, 'Ogre::Root');
