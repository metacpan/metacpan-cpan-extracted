#!perl -w
$|++;

use strict;
use Test::More tests => 128;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex::Util ':all';
use Number::Range::Regex::Util::inf ':all';

# make sure overloaded <=>, <, <=, ==, !=, >=, > work as expected
my @order = ( neg_inf, -1, 0, 1, pos_inf );
foreach my $l_pos (0..$#order) {
  foreach my $r_pos (0..$#order) {
    # don't short circuit based on == which we are testing now
    next if ($l_pos == 1 || $l_pos == 2 || $l_pos == 3) &&
            ($r_pos == 1 || $r_pos == 2 || $r_pos == 3);
    my ($l, $r) = ($order[$l_pos], $order[$r_pos]);
    my $expected = $l_pos <=> $r_pos;
    is( _cmp($l, $r), $expected, "_cmp($l, $r)" );
    is( $l <=> $r, $expected, "$l <=> $r" );
    if($expected == 1) {
      is( $l == $r?1:0, 0, "$l == $r" );
      is( $l != $r?1:0, 1, "$l != $r" );
      is( $l >  $r?1:0, 1, "$l > $r" );
      is( $l >= $r?1:0, 1, "$l >= $r" );
      is( $l <= $r?1:0, 0, "$l <= $r" );
      is( $l <  $r?1:0, 0, "$l < $r" );
    } elsif($expected == -1) {
      is( $l == $r?1:0, 0, "$l == $r" );
      is( $l != $r?1:0, 1, "$l != $r" );
      is( $l >  $r?1:0, 0, "$l > $r" );
      is( $l >= $r?1:0, 0, "$l >= $r" );
      is( $l <= $r?1:0, 1, "$l <= $r" );
      is( $l <  $r?1:0, 1, "$l < $r" );
    } else { # $expected == 0
      is( $l == $r?1:0, 1, "$l == $r" );
      is( $l != $r?1:0, 0, "$l != $r" );
      is( $l >  $r?1:0, 0, "$l > $r" );
      is( $l >= $r?1:0, 1, "$l >= $r" );
      is( $l <= $r?1:0, 1, "$l <= $r" );
      is( $l <  $r?1:0, 0, "$l < $r" );
    }
  }
}

# note: option_mangler, multi_union, has_re_overloading tested elsewhere
