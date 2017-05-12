#!perl

use strict;
use warnings;

use Test::More;    # plan is down at bottom
use Test::Exception;

eval 'use Test::Differences';    # display convenience
my $deeply = $@ ? \&is_deeply : \&eq_or_diff;

BEGIN { use_ok('Music::NeoRiemannianTonnetz') }

my $Nrt = Music::NeoRiemannianTonnetz->new;
isa_ok( $Nrt, 'Music::NeoRiemannianTonnetz' );

taskify_tokens();
techno();
transform_3_11();
transform_4_27();

sub taskify_tokens {
  my $tasks = $Nrt->taskify_tokens('P');
  is( scalar @$tasks, 1, 'single step task count' );
  ok( ref $tasks->[0][1] eq 'CODE', 'task is code ref' );

  $tasks = $Nrt->taskify_tokens('N');    # should expand to RLP
  is( scalar @$tasks, 3, 'three step task count' );
  is( scalar( grep { ref $_->[1] eq 'CODE' ? 1 : () } @$tasks ),
    3, 'three little code refs' );
}

sub techno {
  my @techno           = (qw/tonn tz/) x 8;
  my @even_more_techno = (qw/tonn tz/) x 32;

  $deeply->( [ $Nrt->techno ],    \@techno,           'tonn tz' );
  $deeply->( [ $Nrt->techno(4) ], \@even_more_techno, 'even more tonn tz' );
}

sub transform_3_11 {
  # flip minor|major traids
  my $pset = $Nrt->transform( 'P', [ 60, 63, 67 ] );
  $deeply->( $pset, [ 60, 64, 67 ], 'P - minor triad to major' );
  $pset = $Nrt->transform( 'P', $pset );
  $deeply->( $pset, [ 60, 63, 67 ], 'P - major triad to minor' );

  # should be a no-op, repeated P just toggle the 3rd back and forth
  $deeply->(
    $Nrt->transform( 'PPPP', [ 57, 60, 64 ] ),
    [ 57, 60, 64 ],
    'PPPP toggle'
  );

  # unsupported pitch set (for now)
  dies_ok( sub { $Nrt->transform( 'P', [ 0, 1, 2 ] ) } );

  $deeply->(
    $Nrt->transform( 'R', [ 57, 60, 64 ] ),
    [ 55, 60, 64 ],
    'R - A minor to C major'
  );
  $deeply->(
    $Nrt->transform( 'R', [ 60, 64, 67 ] ),
    [ 60, 64, 69 ],
    'R - C major to A minor'
  );

  $deeply->(
    $Nrt->transform( 'L', [ 57, 60, 64 ] ),
    [ 57, 60, 65 ],
    'L - A minor to F major'
  );
  $deeply->(
    $Nrt->transform( 'L', [ 60, 64, 67 ] ),
    [ 59, 64, 67 ],
    'L - C major to E minor'
  );

  $deeply->(
    $Nrt->transform( 'N', [ 57, 60, 64 ] ),
    [ 56, 59, 64 ],
    'N - A minor to E major'
  );
  $deeply->(
    $Nrt->transform( 'N', [ 60, 64, 67 ] ),
    [ 60, 65, 68 ],
    'N - C major to F minor'
  );

  $deeply->(
    $Nrt->transform( 'RLP', [ 57, 60, 64 ] ),
    [ 56, 59, 64 ],
    'RLP - A minor to E major'
  );

  $deeply->(
    $Nrt->transform( 'S', [ 60, 64, 67 ] ),
    [ 61, 64, 68 ],
    'S - C major to C# minor'
  );
  $deeply->(
    $Nrt->transform( 'S', [ 61, 64, 68 ] ),
    [ 60, 64, 67 ],
    'S - C# minor to C major'
  );

  $deeply->(
    $Nrt->transform( 'H', [ 60, 64, 67 ] ),
    [ 59, 63, 68 ],
    'H - C major to Ab minor'
  );
  $deeply->(
    $Nrt->transform( 'H', [ 59, 63, 68 ] ),
    [ 60, 64, 67 ],
    'H - Ab minor to C major'
  );
}

sub transform_4_27 {
  # Via table in [Childs 1998] p.186
  $deeply->(
    $Nrt->transform( 'S23', [ 65, 69, 72, 75 ] ),
    [ 65, 68, 71, 75 ],
    'S23 - F+ to F-'
  );
  $deeply->(
    $Nrt->transform( 'S32', [ 65, 69, 72, 75 ] ),
    [ 66, 69, 72, 76 ],
    'S32 - F+ to F#-'
  );
  $deeply->(
    $Nrt->transform( 'S34', [ 65, 69, 72, 75 ] ),
    [ 66, 70, 72, 75 ],
    'S34 - F+ to C-'
  );
  $deeply->(
    $Nrt->transform( 'S43', [ 65, 69, 72, 75 ] ),
    [ 65, 69, 71, 74 ],
    'S43 - F+ to B-'
  );
  $deeply->(
    $Nrt->transform( 'S56', [ 65, 69, 72, 75 ] ),
    [ 65, 68, 72, 74 ],
    'S56 - F+ to D-'
  );
  $deeply->(
    $Nrt->transform( 'S65', [ 65, 69, 72, 75 ] ),
    [ 66, 69, 73, 75 ],
    'S65 - F+ to D#-'
  );
  $deeply->(
    $Nrt->transform( 'C32', [ 65, 69, 72, 75 ] ),
    [ 66, 69, 72, 74 ],
    'C32 - F+ to D+'
  );
  $deeply->(
    $Nrt->transform( 'C34', [ 65, 69, 72, 75 ] ),
    [ 66, 68, 72, 75 ],
    'C34 - F+ to Ab+'
  );
  $deeply->(
    $Nrt->transform( 'C65', [ 65, 69, 72, 75 ] ),
    [ 66, 69, 71, 75 ],
    'C65 - F+ to B+'
  );

  $deeply->(
    $Nrt->transform( 'S23', [ 65, 68, 71, 75 ] ),
    [ 65, 69, 72, 75 ],
    'S23 - F- to F+'
  );
  $deeply->(
    $Nrt->transform( 'S32', [ 65, 68, 71, 75 ] ),
    [ 64, 68, 71, 74 ],
    'S32 - F- to E+'
  );
  $deeply->(
    $Nrt->transform( 'S34', [ 65, 68, 71, 75 ] ),
    [ 65, 68, 70, 74 ],
    'S34 - F- to Bb+'
  );
  $deeply->(
    $Nrt->transform( 'S43', [ 65, 68, 71, 75 ] ),
    [ 66, 69, 71, 75 ],
    'S43 - F- to B+'
  );
  $deeply->(
    $Nrt->transform( 'S56', [ 65, 68, 71, 75 ] ),
    [ 66, 68, 72, 75 ],
    'S56 - F- to Ab+'
  );
  $deeply->(
    $Nrt->transform( 'S65', [ 65, 68, 71, 75 ] ),
    [ 65, 67, 71, 74 ],
    'S65 - F- to G+'
  );
  $deeply->(
    $Nrt->transform( 'C32', [ 65, 68, 71, 75 ] ),
    [ 66, 68, 71, 74 ],
    'C32 - F- to G#-'
  );
  $deeply->(
    $Nrt->transform( 'C34', [ 65, 68, 71, 75 ] ),
    [ 65, 68, 72, 74 ],
    'C34 - F- to D-'
  );
  $deeply->(
    $Nrt->transform( 'C65', [ 65, 68, 71, 75 ] ),
    [ 65, 69, 71, 74 ],
    'C65 - F- to B-'
  );
}

plan tests => 41;
