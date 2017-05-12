#!perl
#
# Music::PitchNum tests

use strict;
use warnings;

use Test::Most;    # plan is down at bottom

package Assay;
use Moo;
with('Music::PitchNum');

package main;
my $the = Assay->new;

##############################################################################
#
# pitchname

# number in, ASPN out
is( $the->pitchname(59),  'B3' );
is( $the->pitchname(60),  'C4' );
is( $the->pitchname(61),  'C#4' );
is( $the->pitchname(103), 'G7' );
is( $the->pitchname(12),  'C0' );

# something of a stretch, use a before() or after() or otherwise limit the
# pitch ranges if the results need to stay within the typical range of human
# hearing or the like (also, such odd numbers did catch a bug).
is( $the->pitchname(0),    'C-1' );
is( $the->pitchname(-7),   'F-2' );
is( $the->pitchname(-11),  'C#-2' );
is( $the->pitchname(-12),  'C-2' );
is( $the->pitchname(-13),  'B-3' );
is( $the->pitchname(-614), 'A#-53' );
is( $the->pitchname(252),  'C20' );

dies_ok( sub { $the->pitchname('prisoner') }, 'number not a name' );

##############################################################################
#
# pitchnum

# ASPN
is( $the->pitchnum(q{B3}),  59 );
is( $the->pitchnum(q{C4}),  60 );
is( $the->pitchnum(q{D4}),  62 );
is( $the->pitchnum(q{D4b}), 61 );

is( $the->pitchnum('A#-53'), -614 );
is( $the->pitchnum('C20'),   252 );

# Helmholtz as seen in lilypond (the original Helmholtz apparently had sub- and
# superscripts that are not at all practical on the command line).
is( $the->pitchnum(q{b}),  59 );
is( $the->pitchnum(q{c'}), 60 );
is( $the->pitchnum(q{d'}), 62 );

# English multiple C notation for those silly chaps, but only for Upper Case
# note letters.
is( $the->pitchnum(q{CC}),  36 );
is( $the->pitchnum(q{CCC}), 24 );
# just plain silly but as documented
is( $the->pitchnum(q{CCC''4}), 24 );

# Lotsa different accidental forms (regional specifics)
is( $the->pitchnum(q{cis'}),     61 );
is( $the->pitchnum(q{ciss'}),    61 );
is( $the->pitchnum(q{Csharp4}),  61 );
is( $the->pitchnum(q{Cs4}),      61 );
is( $the->pitchnum(q{C#4}),      61 );
is( $the->pitchnum(q{Ck4}),      61 );
is( $the->pitchnum(q{des'}),     61 );
is( $the->pitchnum(q{dess'}),    61 );
is( $the->pitchnum(q{Dflat4}),   61 );
is( $the->pitchnum(q{Df4}),      61 );
is( $the->pitchnum(q{Db4}),      61 );
is( $the->pitchnum(q{deses'}),   60 );
is( $the->pitchnum(q{dessess'}), 60 );
is( $the->pitchnum(q{cississ'}), 62 );

# cross boundary fun
is( $the->pitchnum(q{bisis}),      61 );
is( $the->pitchnum(q{Cflatflat4}), 58 );

# cannot use 'prisoner' as why that's a quite valid E3 note
is( $the->pitchnum(':('), undef );

# though it is a handy test as it did catch a bug in the lexer (other
# implementations doubtless should be stricter about this sort of thing)
is( $the->pitchnum('prisoner'), 52 );

# ... and now I'm curious about other lexer edge cases. Idea! You could throw
# the words of a sentence or whatnot at this method, and get back doubtless
# horrible musical material to work with.
is( $the->pitchnum(q{XbX}),     59 );
is( $the->pitchnum(q{XcX'X}),   60 );
is( $the->pitchnum(q{XCXkX4X}), 61 );

# and pass-through(-ish) on numbers
is( $the->pitchnum(48),   48 );
is( $the->pitchnum(12.3), 12 );

##############################################################################
#
# sorry, octave

is( $the->pitchname(0, ignore_octave => 1),  'C' );
is( $the->pitchname(-7, ignore_octave => 1), 'F' );

plan tests => 50;
