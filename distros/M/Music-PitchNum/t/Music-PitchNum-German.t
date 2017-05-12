#!perl
#
# Music::PitchNum::German notation tests

use strict;
use warnings;

use Test::Most;    # plan is down at bottom

package Assay;
use Moo;
with('Music::PitchNum::German');

package main;
my $the = Assay->new;

##############################################################################
#
# pitchname

is( $the->pitchname(34), q{b,,} );
is( $the->pitchname(46), q{b,} );
is( $the->pitchname(58), q{b} );
is( $the->pitchname(70), q{b'} );
is( $the->pitchname(69), q{a'} );
is( $the->pitchname(72), q{c''} );
is( $the->pitchname(71), q{h'} );
is( $the->pitchname(95), q{h'''} );

# ... except lilypond 2.18.2 with \language "deutsch" blows up if "ees" or
# "aes" are specified; need to ensure these are just "es" and "as". This
# behavior can be reviewed with App::MusicTools installed via something like:
#
#   echo c cis ces d dis des e eis es f fes fis g ges gis a ais as b h his | ly-fu --language=deutsch --silent --open
is( $the->pitchname(68), q{as'} );
is( $the->pitchname(63), q{es'} );

dies_ok( sub { $the->pitchname('tar') }, 'pitch that is not pitch' );

##############################################################################
#
# pitchnum

is( $the->pitchnum(q{b,,}),  34 );
is( $the->pitchnum(q{b,}),   46 );
is( $the->pitchnum(q{b}),    58 );
is( $the->pitchnum(q{b'}),   70 );
is( $the->pitchnum(q{a'}),   69 );
is( $the->pitchnum(q{c''}),  72 );
is( $the->pitchnum(q{h'}),   71 );
is( $the->pitchnum(q{h'''}), 95 );

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

is( $the->pitchname(46, ignore_octave => 1), q{b} );
is( $the->pitchname(58, ignore_octave => 1), q{b} );
is( $the->pitchname(70, ignore_octave => 1), q{b} );

plan tests => 30;
