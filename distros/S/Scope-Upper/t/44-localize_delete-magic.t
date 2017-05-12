#!perl

use strict;
use warnings;

use Scope::Upper qw<localize_delete UP HERE>;

use Test::More tests => 9;

our $deleted;

{
 package Scope::Upper::Test::TiedArray;

 sub TIEARRAY { bless [], $_[0] }
 sub STORE { $_[0]->[$_[1]] = $_[2] }
 sub FETCH { $_[0]->[$_[1]] }
 sub CLEAR { @{$_[0]} = (); }
 sub FETCHSIZE { scalar @{$_[0]} }
 sub DELETE { ++$main::deleted; delete $_[0]->[$_[1]] }
 sub EXTEND {}

 our $NEGATIVE_INDICES = 0;
}

our @a;

{
 local @a;
 tie @a, 'Scope::Upper::Test::TiedArray';
 @a = (5 .. 7);
 local $a[4] = 9;
 is $deleted, undef, 'localize_delete @tied_array, $existent => HERE [not deleted]';
 {
  localize_delete '@a', 4 => HERE;
  is $deleted, 1, 'localize_delete @tied_array, $existent => HERE [deleted]';
  is_deeply \@a, [ 5 .. 7 ], 'localize_delete @tied_array, $existent => HERE [ok]';
 }
 is_deeply \@a, [ 5 .. 7, undef, 9 ], 'localize_elem @incomplete_tied_array, $nonexistent, 12 => HERE [end]';
 is $deleted, 1, 'localize_delete @tied_array, $existent => HERE [not more deleted]';
}

{
 local @a;
 tie @a, 'Scope::Upper::Test::TiedArray';
 @a = (4 .. 6);
 local $a[4] = 7;
 {
  localize_delete '@main::a', -1 => HERE;
  is_deeply \@a, [ 4 .. 6 ], 'localize_delete @tied_array, $existent_neg => HERE [ok]';
 }
 is_deeply \@a, [ 4 .. 6, undef, 7 ], 'localize_delete @tied_array, $existent_neg => HERE [end]';
}

SKIP:
{
 skip '$NEGATIVE_INDICES has no special meaning on 5.8.0 and older' => 2
                                                            if "$]" < 5.008_001;
 local $Scope::Upper::Test::TiedArray::NEGATIVE_INDICES = 1;
 local @a;
 tie @a, 'Scope::Upper::Test::TiedArray';
 @a = (4 .. 6);
 local $a[4] = 7;
 {
  localize_delete '@main::a', -1 => HERE;
  is_deeply \@a, [ 4 .. 6 ], 'localize_delete @tied_array_wo_neg, $existent_neg => HERE [ok]';
 }
 is_deeply \@a, [ 4, 5, 7 ], 'localize_delete @tied_array_wo_neg, $existent_neg => HERE [end]';
}
