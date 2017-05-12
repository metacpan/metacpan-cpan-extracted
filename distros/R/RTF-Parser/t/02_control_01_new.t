#!/usr/bin/perl

# We're checking that RTF::Control's new method gives us
#	back an RTF::Control object...

use strict;
use warnings;

use RTF::Control;
use Test::More tests => 1;

my $object = RTF::Control->new();

isa_ok( $object, 'RTF::Control' );
