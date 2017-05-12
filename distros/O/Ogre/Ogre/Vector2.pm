package Ogre::Vector2;

use strict;
use warnings;


# xxx: this should be in XS, but I can't get it to work
use overload
  '==' => \&vec2_eq_xs,
  '!=' => \&vec2_ne_xs,
  '<' => \&vec2_lt_xs,
  '>' => \&vec2_gt_xs,
  '+' => \&vec2_plus_xs,
  '-' => \&vec2_minus_xs,
  '*' => \&vec2_mult_xs,
  '/' => \&vec2_div_xs,
  '0+' => sub { $_[0] },
  'neg' => \&vec2_neg_xs,
  ;


1;

__END__
