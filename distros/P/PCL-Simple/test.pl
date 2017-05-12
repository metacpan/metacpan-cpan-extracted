# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
BEGIN { plan tests => 6 };
use PCL::Simple qw( PCL_pre PCL_post );
ok(1); # If we made it this far, we're ok.

#########################

# check the result of passing various combinations of parameters
# to PCL_pre

ok
(
    (
      PCL_pre( qw/ -w 132 -lpp 66 / )
      eq
      "\e%-12345X\eE\e&l1X\e&l0S\e&l2A\e&l0O\e(8U\e(s0P\e(s18.75H\e&l7.2727C\e(s3B\e&a9L\e&a140M"
    )
    ? 1
    : 0
); 

ok
(
    (
      PCL_pre( qw/ -w 200 -lpp 45 -s 1 -c 2 / )
      eq
      "\e%-12345X\eE\e&l2X\e&l1S\e&l2A\e&l0O\e(8U\e(s0P\e(s28.25H\e&l10.6667C\e(s3B\e&a13L\e&a212M"
    )
    ? 1
    : 0
);

ok
(
    (
      PCL_pre( qw/ -w 60 -lpp 30 -o landscape -s 2 / )
      eq
      "\e%-12345X\eE\e&l1X\e&l2S\e&l2A\e&l1O\e(8U\e(s0P\e(s6.04H\e&l11.6129C\e(s3B\e&a2L\e&a62M\e&l3E\e&l30F"
    )
    ? 1
    : 0
);

ok
(
    (
      PCL_pre( qw/ -w 40 -lpp 7 -o landscape -ms com-10 / )      
      eq
      "\e%-12345X\eE\e&l1X\e&l0S\e&l81A\e&l1O\e(8U\e(s0P\e(s4.84H\e&l18.7500C\e(s3B\e&a2L\e&a42M\e&l2E\e&l7F"
    )
    ? 1
    : 0
);


# ensure PCL_post is working correctly
ok( "\eE\e%-12345X" eq PCL_post() ? 1 : 0);

