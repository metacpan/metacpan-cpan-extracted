#!perl
#
# Test whether can reproduce Schoenberg's allowed close and open
# position chords via this module (which by default generates more
# voicings than he allowed).
#
# (Standard deviation of the pitch sets, after the fundamental is
# removed, is almost a good approximation for allowed voicings,
# though there are a few oddities that do not fit with what
# Schoenberg allows for.)

use strict;
use warnings;

use Test::More tests => 1;

eval 'use Test::Differences';    # display convenience
my $deeply = $@ ? \&is_deeply : \&eq_or_diff;

use Music::Chord::Positions;

# From "Theory of Harmony", p.37. All are close position, excepting the
# final three.
my %scho_allowed = (
  '0 4 7 12'    => undef,
  '0 7 12 16'   => undef,
  '0 12 16 19'  => undef,
  '0 16 19 24'  => undef,
  '12 16 19 24' => undef,
  '0 19 24 28'  => undef,
  '12 19 24 28' => undef,
  '0 7 16 24'   => undef,
  '0 12 19 28'  => undef,
  '0 16 24 31'  => undef,
);

my $mcp    = Music::Chord::Positions->new;
my $chords = $mcp->chord_pos(
  [qw/0 4 7/],
  allow_transpositions => 1,     # as SATB can transpose up
  no_partial_closed    => 1,     # exclude half open/closed positions
  pitch_max            => -1,    # avoids 36 in Soprano
  voice_count          => 4,     # SATB
);

# Ranges of voices relative to C3 as 0 so can see if any of the pitches
# are out of line.
#
# Bass (-8) -5 to 11 (14)
# Tenor (0) 2 to 19 (23)
# Alto (7) 9 to 24 (28)
# Soprano (12) 14 to 29 (33)
#
# With the limited ranges, many chords excluded; at extremes listed by
# S. only the 12 24 28 31 pitch set is excluded. (non-C-based chords
# would be more likely to run into limits) - so really depends on the
# abilities of the vocalists: maybe the tenor can hit that high C,
# maybe they can't.
#my @ranges = (
#  { min => -5, max => 14 },
#  { min => 0,  max => 23 },
#  { min => 7,  max => 28 },
#  { min => 12, max => 33 },
#);
#
#for my $ps (@$chords) {
#  for my $i ( 0 .. $#$ps ) {
#    if ( $ps->[$i] < $ranges[$i]->{min} or $ps->[$i] > $ranges[$i]->{max} ) {
#      diag "out of range: @$ps";
#    }
#  }
#}

my %results;
@results{ map { "@$_" } @$chords } = ();

# NOTE - this one transposition of (allowed) 0 12 16 19, excluded due to
# problem of human voices singing it, or that Schoenberg just missed it?
delete $results{"12 24 28 31"};

$deeply->( \%results, \%scho_allowed, 'just Schoenberg allowed voicings' );
