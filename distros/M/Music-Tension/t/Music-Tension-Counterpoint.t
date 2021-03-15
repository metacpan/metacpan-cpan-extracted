#!perl

use strict;
use warnings;
use Test::Most tests => 40;
my $deeply = \&eq_or_diff;

use constant { DISS => 0, CONS => 1 };

use Music::Tension::Counterpoint;
my $cpt = Music::Tension::Counterpoint->new;

dies_ok { Music::Tension::Counterpoint->new( tensions => undef ) }
qr/hash reference/;
dies_ok { Music::Tension::Counterpoint->new( tensions => [] ) }
qr/hash reference/;
dies_ok { Music::Tension::Counterpoint->new( tensions => {} ) }
qr/all intervals/;

dies_ok { Music::Tension::Counterpoint->new( interior => undef ) }
qr/hash reference/;
dies_ok { Music::Tension::Counterpoint->new( interior => [] ) }
qr/hash reference/;
dies_ok { Music::Tension::Counterpoint->new( interior => {} ) }
qr/all intervals/;

# ->offset_tensions (from Music::Tension)
my @ret = $cpt->offset_tensions( [qw/62 65 64 62/], [qw/69 72 71 69/] );
$deeply->(
    \@ret,
    [ [ CONS, CONS, CONS, CONS ], [ CONS, CONS, CONS ], [ DISS, DISS ], [CONS], ]
);
# this is probably a reason why Fux picked the above subject
$deeply->(
    [ $cpt->usable_offsets( [qw/62 65 64 62/], [qw/69 72 71 69/] ) ],
    [ 1, 3 ]
);
# and not these
$deeply->(
    [ $cpt->usable_offsets( [qw/66 66 66/], [qw/60 72 60/] ) ],
    [ ]
);

# ->pitches
is( $cpt->pitches( 0,  6 ),  DISS );
is( $cpt->pitches( 0,  7 ),  CONS );
is( $cpt->pitches( 69, 74 ), DISS );
is( $cpt->pitches( 74, 69 ), DISS );

# default special treatment of intervals larger (or equal to) an octave
is( $cpt->pitches( 0,       12 ),      CONS );
is( $cpt->pitches( 0,       12 + 6 ),  CONS );
is( $cpt->pitches( 69,      74 + 12 ), CONS );
is( $cpt->pitches( 74 + 12, 69 ),      CONS );

dies_ok { $cpt->pitches } qr/two pitches/;
dies_ok { $cpt->pitches(42) } qr/two pitches/;
dies_ok { $cpt->pitches( "xa", 42 ) } qr/integers/;
dies_ok { $cpt->pitches( 42,   "xa" ) } qr/integers/;

# ->vertical
is( $cpt->vertical( [qw/60 64 67 72/] ), CONS );
is( $cpt->vertical( [qw/72 60 64 67/] ), CONS );
# root to tritone is bad
is( $cpt->vertical( [ 0, 6, 7 ] ), DISS );
is( $cpt->vertical( [ 7, 6, 0 ] ), DISS );
# interior tritone ok
is( $cpt->vertical( [ 50, 65, 71 ] ), CONS );
is( $cpt->vertical( [ 50, 65, 83 ] ), CONS );
# interior voice special cases
is( $cpt->vertical( [qw/60 64 67 72 76/] ), CONS );
is( $cpt->vertical( [qw/60 64 87/] ),       CONS );

dies_ok { $cpt->vertical } qr/array ref/;
dies_ok { $cpt->vertical( {} ) } qr/array ref/;
dies_ok { $cpt->vertical( [] ) } qr/multiple/;

# alternate defaults
my $melody = Music::Tension::Counterpoint->new(
    big_dissonance => 0,
    octave_allow   => 0,
    tensions       => {
        0   => CONS,    # repeated notes
        1   => CONS,    # minor second
        2   => CONS,    # major second
        3   => CONS,    # minor third
        4   => CONS,    # major third
        5   => CONS,    # fourth
        6   => CONS,    # the evil, evil tritone
        7   => CONS,    # fifth
        8   => CONS,    # minor sixth
        9   => DISS,    # major sixth
        10  => DISS,    # minor seventh
        11  => DISS,    # major seventh
        -1  => CONS,
        -2  => CONS,
        -3  => CONS,
        -4  => CONS,
        -5  => CONS,
        -6  => CONS,
        -7  => CONS,
        -8  => DISS,    # no minor sixth leaps down
        -9  => DISS,
        -10 => DISS,
        -11 => DISS,
    }
);
is( $melody->pitches( 0,  0 ),       CONS );
is( $melody->pitches( 0,  12 ),      DISS );    # octave_allow => 0
is( $melody->pitches( 0,  12 + 10 ), DISS );    # big_dissonance => 0
is( $melody->pitches( 60, 68 ),      CONS );    # minor 6th leap up
is( $melody->pitches( 68, 60 ),      DISS );    # "     "   "    down

is( $melody->vertical( [ 60, 64, 76 ] ), DISS );    # octave_allow => 0
is( $melody->vertical( [ 50, 65, 83 ] ), DISS );    # big_dissonance => 0

# interior tritone not ok
my $alt = Music::Tension::Counterpoint->new(
    interior => {
        0  => CONS,                                 # unison
        1  => DISS,                                 # minor 2nd
        2  => DISS,                                 # major 2nd
        3  => CONS,                                 # minor 3rd
        4  => CONS,                                 # major 3rd
        5  => CONS,                                 # perfect fourth
        6  => DISS,                                 # the evil, evil tritone
        7  => CONS,                                 # fifth
        8  => CONS,                                 # minor 6th
        9  => CONS,                                 # major 6th
        10 => DISS,                                 # minor 7th
        11 => DISS,                                 # major 7th
    },
);
is( $alt->vertical( [ 50, 65, 71 ] ), DISS );
