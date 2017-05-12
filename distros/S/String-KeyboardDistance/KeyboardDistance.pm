package String::KeyboardDistance;

require 5.005_62;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

=head1 NAME

String::KeyboardDistance - String Comparison Algorithm

=head1 SYNOPSIS

  use String::KeyboardDistance qw(:all);
  my $s1 = 'Apple';
  my $s2 = 'Wople';

  # compute a match probability
  my $pr = qwerty_keyboard_distance_match('Apple','Wople');

  # find the keyboard distance between two strings
  my $dst = qwerty_keyboard_distance('IBM','HAL');

  # find the keyboard distance between two characters
  $dst = qwerty_char_distance('a','v');

  print "maximum distance: $qwerty_max_distance\n";

=head1 DESCRIPTION

This module implmements a version of keyboard distance for fuzzy 
string matching.  Keyboard distance is a measure of the physical 
distance between two keys on a keyboard.  For example, 'g' has a 
distance of 1 from the keys 'r', 't', 'y', 'f', 'h', 'v', 'b', 
and 'n'.  Immediate diagonals (like ''r, 'y', 'v', and 'n') are 
considered to have a distance of 1 instead of 1.414 to help to
prevent horizontal/vertical bias.

A match probability between two strings is computed from the total 
distances between corresponding characters divided by the length of the 
longer string multiplied by the maximum distance between the two furthest
keys on the keyboard.

The functions in this module use a simple grid of keys.  For the qwerty
mapping, the grid is similar to the following:

  | 0   1   2   3   4   5   6   7   8   9   10  11  12  13
--+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
0 | ` | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0 | - | = |   |
1 |   | q | w | e | r | t | y | u | i | o | p | [ | ] | \ |
2 |   | a | s | d | f | g | h | j | k | l | ; | ' |   |   |
3 |   | z | x | c | v | b | n | m | , | . | / |   |   |   |
--+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

The grids for both qwerty and dvorak are based on PC style keyboards.
Shifted characters have the same coordinates (a and A, 6 and ^).

=head2 EXPORT

This module exports no symbols by default.  The following functions 
are available for export through EXPORT_OK:

  build_qwerty_map
  max_qwerty_distance
  qwerty_char_distance
  qwerty_keyboard_distance
  qwerty_keyboard_distance_match

  build_dvorak_map
  max_dvorak_distance
  dvorak_char_distance
  dvorak_keyboard_distance
  dvorak_keyboard_distance_match

  grid_distance

The following varialbes are availalbe for export through EXPORT_OK:

  @qwerty_grid 
  $qwerty_map
  $qwerty_max_distance

  @dvorak_grid 
  $dvorak_map
  $dvorak_max_distance

Additionaly, this module supports the following export tags:

  :Functions - import all functions
  :Variables - import all variables
  :all       - import both functions and variables

=cut

our @EXP_SUBS = qw(
  build_qwerty_map
  max_qwerty_distance
  qwerty_char_distance
  qwerty_keyboard_distance
  qwerty_keyboard_distance_match

  build_dvorak_map
  max_dvorak_distance
  dvorak_char_distance
  dvorak_keyboard_distance
  dvorak_keyboard_distance_match

  grid_distance
);

our @EXP_VARS = qw(
  @qwerty_grid 
  $qwerty_map
  $qwerty_max_distance

  @dvorak_grid 
  $dvorak_map
  $dvorak_max_distance
);

our %EXPORT_TAGS = ( 
  'all' => [ @EXP_SUBS, @EXP_VARS ],
  'Functions' => \@EXP_SUBS,
  'Variables' => \@EXP_VARS,
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '1.00';

our @qwerty_grid = (
    [[ split(//,q{`1234567890-= }) ],[ split(//,q{~!@#$%^&*()_+ })]],
    [[ split(//,q{ qwertyuiop[]\\})],[ split(//,q( QWERTYUIOP{}|))]],
    [[ split(//,q{ asdfghjkl;' })  ],[ split(//,q{ ASDFGHJKL:"  })]],
    [[ split(//,q{ zxcvbnm,./  })  ],[ split(//,q{ ZXCVBNM<>?   })]],
);
our $qwerty_map          = build_qwerty_map();
our $qwerty_max_distance = max_qwerty_distance();

our @dvorak_grid = (
    [[ split(//,q{`1234567890[] }) ],[ split(//,q"~!@#$%^&*(){} ")]],
    [[ split(//,q{ ',.pyfgcrl/=\\})],[ split(//,q{ "<>PYFGCRL?+|})]],
    [[ split(//,q{ aoeuidhtns-  }) ],[ split(//,q{ AOEUIDHTNS_  })]],
    [[ split(//,q{ ;qjkxbmwvz   }) ],[ split(//,q{ :QJKXBMWVZ   })]],
);
our $dvorak_map          = build_dvorak_map();
our $dvorak_max_distance = max_dvorak_distance();


=head1 API REFERENCE


=head2 build_qwerty_map

  param:  array reference to receive the map [optional]
  return: the map (array reference)

This function builds a map of each character to its corresponding
location on the keyboard.  The location is derived by looking at the 
keyboard as a simple grid in which the location of keys on the keyboard
are considereed to be the same as their shifted values.  The following
keys are considered to have the same location:

  1 and !
  r and r
  / and ?

The map is an array, where the index is the value returned by chr() for
the character at that location.  The value is an array ref describing 
the location of the character on the keyboard.  The first element is the
y position, the second is the x, and the third represents the shift value
(0 for non-shifted, 1 for shifted).  All non-keyable characters, including
tabs and spaces, will have undef values in the map, meaning they have no
point on the grid.  These non-key characterss should be considered to be 
the maximum distance away from any other character except themselves.

The map is constructed at run-time from the @qwerty_grid package global,
and cached in the $qwerty_map package global.

=cut

sub build_qwerty_map
{
  my $map = shift||[];
  my($i,$j);
  for($i = 0; $i < @qwerty_grid; ++$i) {
    for($j = 0; $j < @{$qwerty_grid[$i][0]}; ++$j) {
      next unless defined $qwerty_grid[$i][0][$j];
      next if ' ' eq $qwerty_grid[$i][0][$j];
      #      print "building map0: $i,$j: ",$qwerty_grid[$i][0][$j],':',
      #  ord($qwerty_grid[$i][0][$j]),"\n";
      $map->[ord $qwerty_grid[$i][0][$j]] = [$i,$j,0];
    }
    for($j = 0; $j < @{$qwerty_grid[$i][1]}; ++$j) {
      next unless defined $qwerty_grid[$i][1][$j];
      next if ' ' eq $qwerty_grid[$i][1][$j];
      #print "building map1: $i,$j: ",$qwerty_grid[$i][1][$j],':',
      #  ord($qwerty_grid[$i][1][$j]),"\n";
      $map->[ord $qwerty_grid[$i][1][$j]] = [$i,$j,1];
    }
  }
  return $map;
}

=head2 build_dvorak_map

  param:  array reference to receive the map [optional]
  return: the map (array reference)

This function is identical to build_qwerty_map, with the exception
that it builds a map for dvorak keyboards, and the map is constructed 
from the @dvorak_grid package global, and cached in the $dvorak_map 
package global.

=cut

sub build_dvorak_map
{
  my $map = shift||[];
  my($i,$j);
  for($i = 0; $i < @dvorak_grid; ++$i) {
    for($j = 0; $j < @{$dvorak_grid[$i][0]}; ++$j) {
      next unless defined $dvorak_grid[$i][0][$j];
      next if ' ' eq $dvorak_grid[$i][0][$j];
      #      print "building map0: $i,$j: ",$dvorak_grid[$i][0][$j],':',
      #  ord($dvorak_grid[$i][0][$j]),"\n";
      $map->[ord $dvorak_grid[$i][0][$j]] = [$i,$j,0];
    }
    for($j = 0; $j < @{$dvorak_grid[$i][1]}; ++$j) {
      next unless defined $dvorak_grid[$i][1][$j];
      next if ' ' eq $dvorak_grid[$i][1][$j];
      #print "building map1: $i,$j: ",$dvorak_grid[$i][1][$j],':',
      #  ord($dvorak_grid[$i][1][$j]),"\n";
      $map->[ord $dvorak_grid[$i][1][$j]] = [$i,$j,1];
    }
  }
  return $map;
}

=head2 max_qwerty_distance

  return: maximum distance

This function dynamicly computes the maximum distance between 
keys in the qwerty map.  The maximum key distance is stored in
the $qwerty_max_distance package global.

=cut

sub max_qwerty_distance
{
  my $max = 0;
  for(my $i = 0; $i < @$qwerty_map; ++$i) {
    next unless $qwerty_map->[$i];
    for(my $j = 0; $j < @$qwerty_map; ++$j) {
      next unless $qwerty_map->[$j];
      next if $i == $j;
      my $dst = qwerty_char_distance(chr($i),chr($j));
      $max = $dst if $dst > $max;
    }
  }
  return $max;
}

=head2 max_dvorak_distance

  return: maximum distance

This function dynamicly computes the maximum distance between 
keys in the dvorak map.  The maximum key distance is stored in
the $dvorak_max_distance package global.

=cut

sub max_dvorak_distance
{
  my $max = 0;
  for(my $i = 0; $i < @$dvorak_map; ++$i) {
    next unless $dvorak_map->[$i];
    for(my $j = 0; $j < @$dvorak_map; ++$j) {
      next unless $dvorak_map->[$j];
      next if $i == $j;
      my $dst = dvorak_char_distance(chr($i),chr($j));
      $max = $dst if $dst > $max;
    }
  }
  return $max;
}

=head2 qwerty_char_distance

  param:   char 1
  param:   char 2
  return:  distance

This function computes the distance between the two characters passed
on a qwerty keyboard.

=cut

sub qwerty_char_distance
{
  return 0 if $_[0] eq $_[1]; # return 0 if same, regardless of map
  # if either of the chars are not in the map, return the max distance
  return $qwerty_max_distance unless $qwerty_map->[ord $_[0]];
  return $qwerty_max_distance unless $qwerty_map->[ord $_[1]];
  return grid_distance(
    @{$qwerty_map->[ord $_[0]]}[0,1],
    @{$qwerty_map->[ord $_[1]]}[0,1],
  );
}

=head2 dvorak_char_distance

  param:   char 1
  param:   char 2
  return:  distance

This function computes the distance between the two characters passed
on a dvorak keyboard.

=cut

sub dvorak_char_distance
{
  return 0 if $_[0] eq $_[1]; # return 0 if same, regardless of map
  # if either of the chars are not in the map, return the max distance
  return $dvorak_max_distance unless $dvorak_map->[ord $_[0]];
  return $dvorak_max_distance unless $dvorak_map->[ord $_[1]];
  return grid_distance(
    @{$dvorak_map->[ord $_[0]]}[0,1],
    @{$dvorak_map->[ord $_[1]]}[0,1],
  );
}

=head2 grid_distance

  param:  x1 - point 1's x coordinate
  param:  y1 - point 1's y coordinate
  param:  x2 - point 2's x coordinate
  param:  y2 - point 2's y coordinate
  return: distance between points

This function returns the distance between two points.  If the two 
points have an x distance of 1, and a y distance of 1, then they
are considered to be a distance of 1 apart.  This is meant to help
prevent horizontal/vertical bias in the distancing function.  Otherwise 
we use the following formula:

  sqrt( (x1 - x2)**2 + (y1 - y2)**2 );

=cut

sub grid_distance
{
  return 0 if($_[0] == $_[2] && $_[1] == $_[3]); # points are same
  return 1 if(abs($_[0] - $_[2]) == 1 && abs($_[1] - $_[3]) == 1); # same as 1
  sqrt(($_[0] - $_[2])**2 + ($_[1] - $_[3])**2);
}

=head2 qwerty_keyboard_distance

  param:  string1
  param:  string2
  return: distance

Returns the sum of the distances between corresponding characters
in the two strings.  If one string is longer than the other the 
remaining characters are counted as having the same value as the
maximum distance.

=cut

sub qwerty_keyboard_distance
{
  my($s1,$s2) = @_;
  my($l1,$l2) = (length($s1),length($s2));
  my $short   = $l1 < $l2 ? $s1 : $s2;
  my $long    = $l1 < $l2 ? $s2 : $s1;
  my $ls      = $l1 < $l2 ? $l1 : $l2;
  my $ll      = $l1 < $l2 ? $l2 : $l1;

  my $tot = 0;
  my $i;
  for($i = 0; $i < $ls; ++$i) {
    #print "calling distance(",substr($short,$i,1),',',$long,$i,1,")\n";
    $tot += abs(qwerty_char_distance(substr($short,$i,1),substr($long,$i,1)));
  }

  while($i < $ll) {
    $tot += $qwerty_max_distance;
    ++$i;
  }

  return $tot;
}

=head2 qwerty_keyboard_distance_match

  param:  string1
  param:  string2
  return: probability of match

The probability of a match is:

  Pr = 1 - ( D / (L * M) )

Where D is the distance between the two strings, L is the length of
the longer string, and M is the maximum character distance.

=cut

sub qwerty_keyboard_distance_match
{
  my($s1,$s2) = @_;
  my($l1,$l2) = (length($s1),length($s2));
  my $ls      = $l1 < $l2 ? $l1 : $l2;
  my $ll      = $l1 < $l2 ? $l2 : $l1;
  my $dst = qwerty_keyboard_distance($s1,$s2);
  return (1 - ($dst/($ll*$qwerty_max_distance)));
}

=head2 dvorak_keyboard_distance

  param:  string1
  param:  string2
  return: distance

Returns the sum of the distances between corresponding characters
in the two strings.  If one string is longer than the other the 
remaining characters are counted as having the same value as the
maximum distance.

=cut

sub dvorak_keyboard_distance
{
  my($s1,$s2) = @_;
  my($l1,$l2) = (length($s1),length($s2));
  my $short   = $l1 < $l2 ? $s1 : $s2;
  my $long    = $l1 < $l2 ? $s2 : $s1;
  my $ls      = $l1 < $l2 ? $l1 : $l2;
  my $ll      = $l1 < $l2 ? $l2 : $l1;

  my $tot     = 0;
  my $i = 0;
  for($i = 0; $i < $ls; ++$i) {
    #print "calling distance(",substr($short,$i,1),',',$long,$i,1,")\n";
    $tot += abs(dvorak_char_distance(substr($short,$i,1),substr($long,$i,1)));
  }

  while($i < $ll) {
    $tot += $dvorak_max_distance;
    ++$i;
  }
  return $tot;
}

=head2 dvorak_keyboard_distance_match

  param:  string1
  param:  string2
  return: probability of match

The probability of a match is computed in the same way as
for qwerty_keyboard_distance_match().

=cut

sub dvorak_keyboard_distance_match
{
  my($s1,$s2) = @_;
  my($l1,$l2) = (length($s1),length($s2));
  my $ls      = $l1 < $l2 ? $l1 : $l2;
  my $ll      = $l1 < $l2 ? $l2 : $l1;
  my $dst     = dvorak_keyboard_distance($s1,$s2);
  return 1 - ($dst/($ll*$dvorak_max_distance));
}

1;
__END__

=head1 BUGS

The grids are specific to US style PC keyboards.  It is possible to 
substitue and use your own keyboard maps, but it's not well documented.
Also, even US keyboards differ, for instance, in where they have the 
backslash and pipe characters.  The grids in this module assume that 
it's in the last position of the second row.

The space and tab keys are ignored entierly.  Whitespace is irrelevant 
for the most common use of this module (for the author at least), which 
is matching words or names.

Numbers are distanced from their locations at the top of the keyboard.
It should be an option to perform a keyboard distance using only the 
numeric keypad.

If one string is a substring of the other (abstained vs stained), 
the matching could be improved by either starting at the substring
offset, or by prepending spaces onto the front of the shorter string
so it matched the substring offset.

Currently the maps, and the max lengths are computed dynamicly.  
The module would load faster if these were hard coded data.

It should be possible to speed up the qwerty_char_distance and 
dvorak_char_distance functions by caching (for example, by 
using the Memoize module).

=head1 AUTHOR

 Kyle R. Burton 
 krburton@cpan.org
 kburton@hmsonline.com
 HMS
 625 Ridge Pike
 Building E
 Suite 400
 Conshohocken, PA 19428

=head1 SEE ALSO

perl(1).  String::Approx.  Text::DoubleMetaphone.  String::Similarity.

=cut

