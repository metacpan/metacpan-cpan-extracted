#!/usr/bin/perl

use strict;
use warnings;

use lib 't';
use Ogre::TestBase qw(floats_close_enough);
use Test::More tests => 3;


BEGIN {
    use_ok('Ogre');
    use_ok('Ogre::ConfigFile');
}


my $test = 'new():';
my $c = Ogre::ConfigFile->new();
isa_ok($c, 'Ogre::ConfigFile');


# load


