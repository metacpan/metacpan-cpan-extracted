#!perl
#
# Music::PitchNum::ABC notation tests

use strict;
use warnings;

use Test::Most;    # plan is down at bottom

package Assay;
use Moo;
with('Music::PitchNum::ABC');

package main;
my $the = Assay->new;

##############################################################################
#
# pitchname

is( $the->pitchname(-3),  'A,,,,,,' );
is( $the->pitchname(33),  'A,,,' );
is( $the->pitchname(45),  'A,,' );
is( $the->pitchname(57),  'A,' );
is( $the->pitchname(69),  'A' );
is( $the->pitchname(81),  'a' );
is( $the->pitchname(93),  q{a'} );
is( $the->pitchname(105), q{a''} );

is( $the->pitchname(82), '^a' );

dies_ok( sub { $the->pitchname('curve ball') }, 'not a pitch' );

##############################################################################
#
# pitchnum

is( $the->pitchnum('A,,,'), 33 );
is( $the->pitchnum('A,,'),  45 );
is( $the->pitchnum('A,'),   57 );
is( $the->pitchnum('A'),    69 );
is( $the->pitchnum('a'),    81 );
is( $the->pitchnum(q{a'}),  93 );
is( $the->pitchnum(q{a''}), 105 );

# accidentals
is( $the->pitchnum('^c'),  73 );
is( $the->pitchnum('^^c'), 74 );
is( $the->pitchnum('_d'),  73 );
is( $the->pitchnum('__d'), 72 );

##############################################################################
#
# sorry, octave

# ABC unlike the others changes the note depending on the octave, though
# for not-octave I'm going with upper case because that's what ASPN uses
# by default.
is( $the->pitchname(-3, ignore_octave => 1),  'A' );
is( $the->pitchname(81, ignore_octave => 1),  'A' );

plan tests => 23;
