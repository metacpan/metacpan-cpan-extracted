#!perl

use strict;
use warnings;

use Test::More tests => 12;

eval 'use Test::Differences';    # display convenience
my $deeply = $@ ? \&is_deeply : \&eq_or_diff;

BEGIN { use_ok('Music::Chord::Positions') }

my $mcp = Music::Chord::Positions->new;
isa_ok( $mcp, 'Music::Chord::Positions' );

is( $mcp->scale_degrees, 12, 'expect 12 degrees in scale by default' );

can_ok( 'Music::Chord::Positions',
  qw/chord_inv chord_pos chords2voices scale_degrees/ );

########################################################################
#
# chord_inv tests

# 5th should generate 1st and 2nd inversions
my $inversions = $mcp->chord_inv( [ 0, 4, 7 ] );
$deeply->(
  $inversions,
  [ [ 4, 7, 12 ], [ 7, 12, 16 ] ],
  'all inversions of 5th'
);

# 7th - 1st, 2nd, and 3rd inversions
$inversions = $mcp->chord_inv( [ 0, 4, 7, 11 ] );
$deeply->(
  $inversions,
  [ [ 4, 7, 11, 12 ], [ 7, 11, 12, 16 ], [ 11, 12, 16, 19 ] ],
  'all inversions of 7th'
);

$inversions = $mcp->chord_inv( [ 0, 4, 7, 11 ], inv_num => 1 );
$deeply->( $inversions, [ 4, 7, 11, 12 ], 'first inversion of 7th' );

$inversions = $mcp->chord_inv( [ 0, 4, 7, 10, 13 ], pitch_norm => 1 );
$deeply->(
  $inversions,
  [ [ 4,  7,  10, 13, 24 ],
    [ 7,  10, 13, 24, 28 ],
    [ 10, 13, 24, 28, 31 ],
    [ 1,  12, 16, 19, 22 ]
  ],
  'inversions with pitch_norm'
);

########################################################################
#
# chord_pos tests

# TODO not sure what normal is for voicings and default parameters :/
# use mcp2ly and inspect scores by hand, deal with any oddities or need
# for new parameters as necessary.

########################################################################
#
# chords2voices tests

$deeply->(
  $mcp->chords2voices( [ [qw/1 2 3/], [qw/1 2 3/] ] ),
  [ [qw/3 3/], [qw/2 2/], [qw/1 1/] ],
  'chord to voice switch'
);
$deeply->(
  $mcp->chords2voices( [ [qw/1 2 3/] ] ),
  [ [qw/1 2 3/] ],
  'nothing for chords2voices to do'
);

########################################################################
#
# scale_deg test

$mcp->scale_degrees(3);
is( $mcp->scale_degrees, 3, 'set scale degrees by method' );

my $mcp17 = Music::Chord::Positions->new( DEG_IN_SCALE => 17 );
is( $mcp17->scale_degrees, 17, 'set scale degrees by constructors' );
