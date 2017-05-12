#!perl
#
# Music::PitchNum::ASPN notation tests

use strict;
use warnings;

use Test::Most;    # plan is down at bottom

package Assay;
use Moo;
with('Music::PitchNum::ASPN');

package main;
my $the = Assay->new;

##############################################################################
#
# pitchname

is( $the->pitchname(-3),  'A-2' );
is( $the->pitchname(69),  'A4' );
is( $the->pitchname(105), 'A7' );

is( $the->pitchname(82), 'A#5' );

dies_ok( sub { $the->pitchname('black') }, '#000000' );

##############################################################################
#
# pitchnum

is( $the->pitchnum('A-2'), -3 );
is( $the->pitchnum('A4'),  69 );
is( $the->pitchnum('A7'),  105 );

is( $the->pitchnum('C#5'), 73 );

# whoops, should *not* parse
is( $the->pitchnum('Bb4'), undef );

##############################################################################
#
# sorry, octave

is( $the->pitchname(-3, ignore_octave => 1),  'A' );
is( $the->pitchname(69, ignore_octave => 1),  'A' );

plan tests => 12;
