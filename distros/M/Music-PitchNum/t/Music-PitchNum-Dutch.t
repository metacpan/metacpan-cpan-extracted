#!perl
#
# Music::PitchNum::Dutch notation tests

use strict;
use warnings;

use Test::Most;    # plan is down at bottom

package Assay;
use Moo;
with('Music::PitchNum::Dutch');

package main;
my $the = Assay->new;

##############################################################################
#
# pitchname

is( $the->pitchname(34), q{bes,,} );
is( $the->pitchname(46), q{bes,} );
is( $the->pitchname(58), q{bes} );
is( $the->pitchname(70), q{bes'} );
is( $the->pitchname(69), q{a'} );
is( $the->pitchname(72), q{c''} );
is( $the->pitchname(71), q{b'} );
is( $the->pitchname(95), q{b'''} );

# nederlands in lilypond supports the as/es form, though this module
# instead always outputs these as "aes" and "ees"
is( $the->pitchname(68), q{aes'} );
is( $the->pitchname(63), q{ees'} );

dies_ok( sub { $the->pitchname('mook') }, 'pitch that is not pitch' );

##############################################################################
#
# pitchnum

is( $the->pitchnum(q{bes,,}), 34 );
is( $the->pitchnum(q{bes,}),  46 );
is( $the->pitchnum(q{bes}),   58 );
is( $the->pitchnum(q{a'}),    69 );
is( $the->pitchnum(q{bes'}),  70 );
is( $the->pitchnum(q{b'}),    71 );
is( $the->pitchnum(q{c''}),   72 );
is( $the->pitchnum(q{b'''}),  95 );

# accidentals
is( $the->pitchnum(q{cis''}),   73 );
is( $the->pitchnum(q{cisis''}), 74 );
is( $the->pitchnum(q{des''}),   73 );
is( $the->pitchnum(q{deses''}), 72 );

# and more accidentals
is( $the->pitchnum(q{as'}),  68 );
is( $the->pitchnum(q{es''}), 75 );

# and yet more accidentals
is( $the->pitchnum(q{ases'}),  67 );
is( $the->pitchnum(q{eses''}), 74 );

# TODO really should not be matching this sort of thing, gets parsed
# as c -> 48
#is( $the->pitchnum(q{cs'}),    undef );

##############################################################################
#
# sorry, octave

is( $the->pitchname(46, ignore_octave => 1), q{bes} );
is( $the->pitchname(58, ignore_octave => 1), q{bes} );
is( $the->pitchname(70, ignore_octave => 1), q{bes} );

plan tests => 30;
