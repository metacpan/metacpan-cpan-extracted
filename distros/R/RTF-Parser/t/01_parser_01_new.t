#!/usr/bin/perl

use strict;
use warnings;

use RTF::Parser;
use Test::More tests => 2;

my $object = RTF::Parser->new();

isa_ok( $object, 'RTF::Parser' );

package RTF::SubClassTest;
@RTF::SubClassTest::ISA = ('RTF::Parser');

package main;

# Check we can be subclassed

my $sub_object = RTF::SubClassTest->new();

isa_ok( $sub_object, 'RTF::SubClassTest' );
