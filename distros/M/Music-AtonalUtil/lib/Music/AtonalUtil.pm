# -*- Perl -*-
#
# Code for atonal music analysis and composition (and a certain
# accumulation of somewhat related utility code, in the best fashion of
# that kitchen drawer).

package Music::AtonalUtil;

use 5.010;
use strict;
use warnings;

# as Math::Combinatorics does not preserve input order in return values
use Algorithm::Combinatorics qw/combinations/;
use Carp qw/croak/;
use List::Util qw/shuffle/;
use Scalar::Util qw/looks_like_number refaddr/;

our $VERSION = '1.15';

my $DEG_IN_SCALE = 12;

# Forte Number to prime form mapping. These are mostly in agreement with
# Appendix 2, Table II in "Basic Atonal Theory" (rahn1980) by John Rahn
# (p.140-143), and also against Appendix 1 in "The Structure of Atonal
# Music" (forte1973) by Allen Forte (p.179-181), though Rahn and Forte use
# different methods and thus calculate different prime forms in a few
# cases. See t/forte2pcs2forte.t for tests of these against what
# prime_form() calculates. This code uses the Rahn method (though still
# calls them "Forte Numbers" instead of the perhaps more appropriate
# "Rahn Number").
#
# By mostly, my calculation disagrees with rahn1980 for 7-Z18, 7-20, and
# 8-26 (by eyeball inspection). These three look to be typos in
# rahn1980, as in each case Rahn used the Forte form.
#
# sorting is to align with the table in rahn1980
our %FORTE2PCS = (
    # trichords (complement nonachords)
    '3-1'  => [ 0, 1, 2 ],
    '3-2'  => [ 0, 1, 3 ],
    '3-3'  => [ 0, 1, 4 ],
    '3-4'  => [ 0, 1, 5 ],
    '3-5'  => [ 0, 1, 6 ],
    '3-6'  => [ 0, 2, 4 ],
    '3-7'  => [ 0, 2, 5 ],
    '3-8'  => [ 0, 2, 6 ],
    '3-9'  => [ 0, 2, 7 ],
    '3-10' => [ 0, 3, 6 ],
    '3-11' => [ 0, 3, 7 ],
    '3-12' => [ 0, 4, 8 ],
    # nonachords (trichords)
    '9-1'  => [ 0, 1, 2, 3, 4, 5, 6, 7, 8 ],
    '9-2'  => [ 0, 1, 2, 3, 4, 5, 6, 7, 9 ],
    '9-3'  => [ 0, 1, 2, 3, 4, 5, 6, 8, 9 ],
    '9-4'  => [ 0, 1, 2, 3, 4, 5, 7, 8, 9 ],
    '9-5'  => [ 0, 1, 2, 3, 4, 6, 7, 8, 9 ],
    '9-6'  => [ 0, 1, 2, 3, 4, 5, 6, 8, 10 ],
    '9-7'  => [ 0, 1, 2, 3, 4, 5, 7, 8, 10 ],
    '9-8'  => [ 0, 1, 2, 3, 4, 6, 7, 8, 10 ],
    '9-9'  => [ 0, 1, 2, 3, 5, 6, 7, 8, 10 ],
    '9-10' => [ 0, 1, 2, 3, 4, 6, 7, 9, 10 ],
    '9-11' => [ 0, 1, 2, 3, 5, 6, 7, 9, 10 ],
    '9-12' => [ 0, 1, 2, 4, 5, 6, 8, 9, 10 ],
    # tetrachords (octachords)
    '4-1'   => [ 0, 1, 2, 3 ],
    '4-2'   => [ 0, 1, 2, 4 ],
    '4-4'   => [ 0, 1, 2, 5 ],
    '4-5'   => [ 0, 1, 2, 6 ],
    '4-6'   => [ 0, 1, 2, 7 ],
    '4-3'   => [ 0, 1, 3, 4 ],
    '4-11'  => [ 0, 1, 3, 5 ],
    '4-13'  => [ 0, 1, 3, 6 ],
    '4-Z29' => [ 0, 1, 3, 7 ],
    '4-7'   => [ 0, 1, 4, 5 ],
    '4-Z15' => [ 0, 1, 4, 6 ],
    '4-18'  => [ 0, 1, 4, 7 ],
    '4-19'  => [ 0, 1, 4, 8 ],
    '4-8'   => [ 0, 1, 5, 6 ],
    '4-16'  => [ 0, 1, 5, 7 ],
    '4-20'  => [ 0, 1, 5, 8 ],
    '4-9'   => [ 0, 1, 6, 7 ],
    '4-10'  => [ 0, 2, 3, 5 ],
    '4-12'  => [ 0, 2, 3, 6 ],
    '4-14'  => [ 0, 2, 3, 7 ],
    '4-21'  => [ 0, 2, 4, 6 ],
    '4-22'  => [ 0, 2, 4, 7 ],
    '4-24'  => [ 0, 2, 4, 8 ],
    '4-23'  => [ 0, 2, 5, 7 ],
    '4-27'  => [ 0, 2, 5, 8 ],
    '4-25'  => [ 0, 2, 6, 8 ],
    '4-17'  => [ 0, 3, 4, 7 ],
    '4-26'  => [ 0, 3, 5, 8 ],
    '4-28'  => [ 0, 3, 6, 9 ],
    # octachords (tetrachords)
    '8-1'   => [ 0, 1, 2, 3, 4, 5, 6, 7 ],
    '8-2'   => [ 0, 1, 2, 3, 4, 5, 6, 8 ],
    '8-4'   => [ 0, 1, 2, 3, 4, 5, 7, 8 ],
    '8-5'   => [ 0, 1, 2, 3, 4, 6, 7, 8 ],
    '8-6'   => [ 0, 1, 2, 3, 5, 6, 7, 8 ],
    '8-3'   => [ 0, 1, 2, 3, 4, 5, 6, 9 ],
    '8-11'  => [ 0, 1, 2, 3, 4, 5, 7, 9 ],
    '8-13'  => [ 0, 1, 2, 3, 4, 6, 7, 9 ],
    '8-Z29' => [ 0, 1, 2, 3, 5, 6, 7, 9 ],
    '8-7'   => [ 0, 1, 2, 3, 4, 5, 8, 9 ],
    '8-Z15' => [ 0, 1, 2, 3, 4, 6, 8, 9 ],
    '8-18'  => [ 0, 1, 2, 3, 5, 6, 8, 9 ],
    '8-19'  => [ 0, 1, 2, 4, 5, 6, 8, 9 ],
    '8-8'   => [ 0, 1, 2, 3, 4, 7, 8, 9 ],
    '8-16'  => [ 0, 1, 2, 3, 5, 7, 8, 9 ],
    '8-20'  => [ 0, 1, 2, 4, 5, 7, 8, 9 ],
    '8-9'   => [ 0, 1, 2, 3, 6, 7, 8, 9 ],
    '8-10'  => [ 0, 2, 3, 4, 5, 6, 7, 9 ],
    '8-12'  => [ 0, 1, 3, 4, 5, 6, 7, 9 ],
    '8-14'  => [ 0, 1, 2, 4, 5, 6, 7, 9 ],
    '8-21'  => [ 0, 1, 2, 3, 4, 6, 8, 10 ],
    '8-22'  => [ 0, 1, 2, 3, 5, 6, 8, 10 ],
    '8-24'  => [ 0, 1, 2, 4, 5, 6, 8, 10 ],
    '8-23'  => [ 0, 1, 2, 3, 5, 7, 8, 10 ],
    '8-27'  => [ 0, 1, 2, 4, 5, 7, 8, 10 ],
    '8-25'  => [ 0, 1, 2, 4, 6, 7, 8, 10 ],
    '8-17'  => [ 0, 1, 3, 4, 5, 6, 8, 9 ],
    '8-26'  => [ 0, 1, 3, 4, 5, 7, 8, 10 ],
    # '8-26'  => [ 0, 1, 2, 4, 5, 7, 9, 10 ], # rahn1980
    '8-28' => [ 0, 1, 3, 4, 6, 7, 9, 10 ],
    # pentachords (septachords)
    '5-1'   => [ 0, 1, 2, 3, 4 ],
    '5-2'   => [ 0, 1, 2, 3, 5 ],
    '5-4'   => [ 0, 1, 2, 3, 6 ],
    '5-5'   => [ 0, 1, 2, 3, 7 ],
    '5-3'   => [ 0, 1, 2, 4, 5 ],
    '5-9'   => [ 0, 1, 2, 4, 6 ],
    '5-Z36' => [ 0, 1, 2, 4, 7 ],
    '5-13'  => [ 0, 1, 2, 4, 8 ],
    '5-6'   => [ 0, 1, 2, 5, 6 ],
    '5-14'  => [ 0, 1, 2, 5, 7 ],
    '5-Z38' => [ 0, 1, 2, 5, 8 ],
    '5-7'   => [ 0, 1, 2, 6, 7 ],
    '5-15'  => [ 0, 1, 2, 6, 8 ],
    '5-10'  => [ 0, 1, 3, 4, 6 ],
    '5-16'  => [ 0, 1, 3, 4, 7 ],
    '5-Z17' => [ 0, 1, 3, 4, 8 ],
    '5-Z12' => [ 0, 1, 3, 5, 6 ],
    '5-24'  => [ 0, 1, 3, 5, 7 ],
    '5-27'  => [ 0, 1, 3, 5, 8 ],
    '5-19'  => [ 0, 1, 3, 6, 7 ],
    '5-29'  => [ 0, 1, 3, 6, 8 ],
    '5-31'  => [ 0, 1, 3, 6, 9 ],
    '5-Z18' => [ 0, 1, 4, 5, 7 ],
    '5-21'  => [ 0, 1, 4, 5, 8 ],
    '5-30'  => [ 0, 1, 4, 6, 8 ],
    '5-32'  => [ 0, 1, 4, 6, 9 ],
    '5-22'  => [ 0, 1, 4, 7, 8 ],
    '5-20'  => [ 0, 1, 5, 6, 8 ],    # 0,1,3,7,8 forte1973
    '5-8'   => [ 0, 2, 3, 4, 6 ],
    '5-11'  => [ 0, 2, 3, 4, 7 ],
    '5-23'  => [ 0, 2, 3, 5, 7 ],
    '5-25'  => [ 0, 2, 3, 5, 8 ],
    '5-28'  => [ 0, 2, 3, 6, 8 ],
    '5-26'  => [ 0, 2, 4, 5, 8 ],
    '5-33'  => [ 0, 2, 4, 6, 8 ],
    '5-34'  => [ 0, 2, 4, 6, 9 ],
    '5-35'  => [ 0, 2, 4, 7, 9 ],
    '5-Z37' => [ 0, 3, 4, 5, 8 ],
    # septachords (pentachords)
    '7-1'   => [ 0, 1, 2, 3, 4, 5, 6 ],
    '7-2'   => [ 0, 1, 2, 3, 4, 5, 7 ],
    '7-4'   => [ 0, 1, 2, 3, 4, 6, 7 ],
    '7-5'   => [ 0, 1, 2, 3, 5, 6, 7 ],
    '7-3'   => [ 0, 1, 2, 3, 4, 5, 8 ],
    '7-9'   => [ 0, 1, 2, 3, 4, 6, 8 ],
    '7-Z36' => [ 0, 1, 2, 3, 5, 6, 8 ],
    '7-13'  => [ 0, 1, 2, 4, 5, 6, 8 ],
    '7-6'   => [ 0, 1, 2, 3, 4, 7, 8 ],
    '7-14'  => [ 0, 1, 2, 3, 5, 7, 8 ],
    '7-Z38' => [ 0, 1, 2, 4, 5, 7, 8 ],
    '7-7'   => [ 0, 1, 2, 3, 6, 7, 8 ],
    '7-15'  => [ 0, 1, 2, 4, 6, 7, 8 ],
    '7-10'  => [ 0, 1, 2, 3, 4, 6, 9 ],
    '7-16'  => [ 0, 1, 2, 3, 5, 6, 9 ],
    '7-Z17' => [ 0, 1, 2, 4, 5, 6, 9 ],
    '7-Z12' => [ 0, 1, 2, 3, 4, 7, 9 ],
    '7-24'  => [ 0, 1, 2, 3, 5, 7, 9 ],
    '7-27'  => [ 0, 1, 2, 4, 5, 7, 9 ],
    '7-19'  => [ 0, 1, 2, 3, 6, 7, 9 ],
    '7-29'  => [ 0, 1, 2, 4, 6, 7, 9 ],
    '7-31'  => [ 0, 1, 3, 4, 6, 7, 9 ],
    '7-Z18' => [ 0, 1, 4, 5, 6, 7, 9 ],    # 0,1,2,3,5,8,9 forte1973
               # '7-Z18' => [ 0, 1, 2, 3, 5, 8, 9 ], # rahn1980
    '7-21' => [ 0, 1, 2, 4, 5, 8, 9 ],
    '7-30' => [ 0, 1, 2, 4, 6, 8, 9 ],
    '7-32' => [ 0, 1, 3, 4, 6, 8, 9 ],
    '7-22' => [ 0, 1, 2, 5, 6, 8, 9 ],
    '7-20' => [ 0, 1, 2, 5, 6, 7, 9 ],    # 0,1,2,4,7,8,9 forte1973
               # '7-20'  => [ 0, 1, 2, 4, 7, 8, 9 ], # rahn1980
    '7-8'   => [ 0, 2, 3, 4, 5, 6, 8 ],
    '7-11'  => [ 0, 1, 3, 4, 5, 6, 8 ],
    '7-23'  => [ 0, 2, 3, 4, 5, 7, 9 ],
    '7-25'  => [ 0, 2, 3, 4, 6, 7, 9 ],
    '7-28'  => [ 0, 1, 3, 5, 6, 7, 9 ],
    '7-26'  => [ 0, 1, 3, 4, 5, 7, 9 ],
    '7-33'  => [ 0, 1, 2, 4, 6, 8, 10 ],
    '7-34'  => [ 0, 1, 3, 4, 6, 8, 10 ],
    '7-35'  => [ 0, 1, 3, 5, 6, 8, 10 ],
    '7-Z37' => [ 0, 1, 3, 4, 5, 7, 8 ],
    # hexachords
    '6-1'   => [ 0, 1, 2, 3, 4, 5 ],
    '6-2'   => [ 0, 1, 2, 3, 4, 6 ],
    '6-Z36' => [ 0, 1, 2, 3, 4, 7 ],
    '6-Z3'  => [ 0, 1, 2, 3, 4, 7 ],    # 0,1,2,3,5,6 forte1973
    '6-Z37' => [ 0, 1, 2, 3, 4, 8 ],
    '6-Z4'  => [ 0, 1, 2, 3, 4, 8 ],    # 0,1,2,4,5,6 forte1973
    '6-9'   => [ 0, 1, 2, 3, 5, 7 ],
    '6-Z40' => [ 0, 1, 2, 3, 5, 8 ],
    '6-Z11' => [ 0, 1, 2, 3, 5, 8 ],    # 0,1,2,4,5,7 forte1973
    '6-5'   => [ 0, 1, 2, 3, 6, 7 ],
    '6-Z41' => [ 0, 1, 2, 3, 6, 8 ],
    '6-Z12' => [ 0, 1, 2, 3, 6, 8 ],    # 0,1,2,4,6,7 forte1973
    '6-Z42' => [ 0, 1, 2, 3, 6, 9 ],
    '6-Z13' => [ 0, 1, 2, 3, 6, 9 ],    # 0,1,3,4,6,7 forte1973
    '6-Z38' => [ 0, 1, 2, 3, 7, 8 ],
    '6-Z6'  => [ 0, 1, 2, 3, 7, 8 ],    # 0,1,3,5,6,7 forte1973
    '6-15'  => [ 0, 1, 2, 4, 5, 8 ],
    '6-22'  => [ 0, 1, 2, 4, 6, 8 ],
    '6-Z46' => [ 0, 1, 2, 4, 6, 9 ],
    '6-Z24' => [ 0, 1, 2, 4, 6, 9 ],    # 0,1,3,4,6,8 forte1973
    '6-Z17' => [ 0, 1, 2, 4, 7, 8 ],
    '6-Z43' => [ 0, 1, 2, 4, 7, 8 ],    # 0,1,2,5,6,8 forte1973
    '6-Z47' => [ 0, 1, 2, 4, 7, 9 ],
    '6-Z25' => [ 0, 1, 2, 4, 7, 9 ],    # 0,1,3,5,6,8 forte1973
    '6-Z44' => [ 0, 1, 2, 5, 6, 9 ],
    '6-Z19' => [ 0, 1, 2, 5, 6, 9 ],    # 0,1,3,4,7,8 forte1973
    '6-18'  => [ 0, 1, 2, 5, 7, 8 ],
    '6-Z48' => [ 0, 1, 2, 5, 7, 9 ],
    '6-Z26' => [ 0, 1, 2, 5, 7, 9 ],    # 0,1,3,5,7,8 forte1973
    '6-7'   => [ 0, 1, 2, 6, 7, 8 ],
    '6-Z10' => [ 0, 1, 3, 4, 5, 7 ],
    '6-Z39' => [ 0, 1, 3, 4, 5, 7 ],    # 0,2,3,4,5,8 forte1973
    '6-14'  => [ 0, 1, 3, 4, 5, 8 ],
    '6-27'  => [ 0, 1, 3, 4, 6, 9 ],
    '6-Z49' => [ 0, 1, 3, 4, 7, 9 ],
    '6-Z28' => [ 0, 1, 3, 4, 7, 9 ],    # 0,1,3,5,6,9 forte1973
    '6-34'  => [ 0, 1, 3, 5, 7, 9 ],
    '6-31'  => [ 0, 1, 4, 5, 7, 9 ],    # 0,1,3,5,8,9 forte1973
    '6-30'  => [ 0, 1, 3, 6, 7, 9 ],
    '6-Z29' => [ 0, 2, 3, 6, 7, 9 ],    # 0,1,3,6,8,9 forte1973
    '6-Z50' => [ 0, 2, 3, 6, 7, 9 ],    # 0,1,4,6,7,9 forte1973
    '6-16'  => [ 0, 1, 4, 5, 6, 8 ],
    '6-20'  => [ 0, 1, 4, 5, 8, 9 ],
    '6-8'   => [ 0, 2, 3, 4, 5, 7 ],
    '6-21'  => [ 0, 2, 3, 4, 6, 8 ],
    '6-Z45' => [ 0, 2, 3, 4, 6, 9 ],
    '6-Z23' => [ 0, 2, 3, 4, 6, 9 ],    # 0,2,3,5,6,8 forte1973
    '6-33'  => [ 0, 2, 3, 5, 7, 9 ],
    '6-32'  => [ 0, 2, 4, 5, 7, 9 ],
    '6-35'  => [ 0, 2, 4, 6, 8, 10 ],
);

# Hexchords here are problematic on account of mutual complementary sets
# (different Forte Numbers for the same pitch set).
# TODO review and use what Rahn lists as first in table on p.142-3.
# TODO Rahn puts 6-Z36 and 6-Z3 together, but my code is producing
# two different prime forms for those...
#
# sorting is to align with the table in rahn1980
our %PCS2FORTE = (
    # trichords (complement nonachords)
    '0,1,2'              => '3-1',
    '0,1,3'              => '3-2',
    '0,1,4'              => '3-3',
    '0,1,5'              => '3-4',
    '0,1,6'              => '3-5',
    '0,2,4'              => '3-6',
    '0,2,5'              => '3-7',
    '0,2,6'              => '3-8',
    '0,2,7'              => '3-9',
    '0,3,6'              => '3-10',
    '0,3,7'              => '3-11',
    '0,4,8'              => '3-12',
    # nonachords (trichords)
    '0,1,2,3,4,5,6,7,8'  => '9-1',
    '0,1,2,3,4,5,6,7,9'  => '9-2',
    '0,1,2,3,4,5,6,8,9'  => '9-3',
    '0,1,2,3,4,5,7,8,9'  => '9-4',
    '0,1,2,3,4,6,7,8,9'  => '9-5',
    '0,1,2,3,4,5,6,8,10' => '9-6',
    '0,1,2,3,4,5,7,8,10' => '9-7',
    '0,1,2,3,4,6,7,8,10' => '9-8',
    '0,1,2,3,5,6,7,8,10' => '9-9',
    '0,1,2,3,4,6,7,9,10' => '9-10',
    '0,1,2,3,5,6,7,9,10' => '9-11',
    '0,1,2,4,5,6,8,9,10' => '9-12',
    # tetrachords (octachords)
    '0,1,2,3'            => '4-1',
    '0,1,2,4'            => '4-2',
    '0,1,2,5'            => '4-4',
    '0,1,2,6'            => '4-5',
    '0,1,2,7'            => '4-6',
    '0,1,3,4'            => '4-3',
    '0,1,3,5'            => '4-11',
    '0,1,3,6'            => '4-13',
    '0,1,3,7'            => '4-Z29',
    '0,1,4,5'            => '4-7',
    '0,1,4,6'            => '4-Z15',
    '0,1,4,7'            => '4-18',
    '0,1,4,8'            => '4-19',
    '0,1,5,6'            => '4-8',
    '0,1,5,7'            => '4-16',
    '0,1,5,8'            => '4-20',
    '0,1,6,7'            => '4-9',
    '0,2,3,5'            => '4-10',
    '0,2,3,6'            => '4-12',
    '0,2,3,7'            => '4-14',
    '0,2,4,6'            => '4-21',
    '0,2,4,7'            => '4-22',
    '0,2,4,8'            => '4-24',
    '0,2,5,7'            => '4-23',
    '0,2,5,8'            => '4-27',
    '0,2,6,8'            => '4-25',
    '0,3,4,7'            => '4-17',
    '0,3,5,8'            => '4-26',
    '0,3,6,9'            => '4-28',
    # octachords (tetrachords)
    '0,1,2,3,4,5,6,7'    => '8-1',
    '0,1,2,3,4,5,6,8'    => '8-2',
    '0,1,2,3,4,5,7,8'    => '8-4',
    '0,1,2,3,4,6,7,8'    => '8-5',
    '0,1,2,3,5,6,7,8'    => '8-6',
    '0,1,2,3,4,5,6,9'    => '8-3',
    '0,1,2,3,4,5,7,9'    => '8-11',
    '0,1,2,3,4,6,7,9'    => '8-13',
    '0,1,2,3,5,6,7,9'    => '8-Z29',
    '0,1,2,3,4,5,8,9'    => '8-7',
    '0,1,2,3,4,6,8,9'    => '8-Z15',
    '0,1,2,3,5,6,8,9'    => '8-18',
    '0,1,2,4,5,6,8,9'    => '8-19',
    '0,1,2,3,4,7,8,9'    => '8-8',
    '0,1,2,3,5,7,8,9'    => '8-16',
    '0,1,2,4,5,7,8,9'    => '8-20',
    '0,1,2,3,6,7,8,9'    => '8-9',
    '0,2,3,4,5,6,7,9'    => '8-10',
    '0,1,3,4,5,6,7,9'    => '8-12',
    '0,1,2,4,5,6,7,9'    => '8-14',
    '0,1,2,3,4,6,8,10'   => '8-21',
    '0,1,2,3,5,6,8,10'   => '8-22',
    '0,1,2,4,5,6,8,10'   => '8-24',
    '0,1,2,3,5,7,8,10'   => '8-23',
    '0,1,2,4,5,7,8,10'   => '8-27',
    '0,1,2,4,6,7,8,10'   => '8-25',
    '0,1,3,4,5,6,8,9'    => '8-17',
    '0,1,3,4,5,7,8,10'   => '8-26', # buggy in rahn1980
    '0,1,3,4,6,7,9,10'   => '8-28',
    # pentachords (septachords)
    '0,1,2,3,4'          => '5-1',
    '0,1,2,3,5'          => '5-2',
    '0,1,2,3,6'          => '5-4',
    '0,1,2,3,7'          => '5-5',
    '0,1,2,4,5'          => '5-3',
    '0,1,2,4,6'          => '5-9',
    '0,1,2,4,7'          => '5-Z36',
    '0,1,2,4,8'          => '5-13',
    '0,1,2,5,6'          => '5-6',
    '0,1,2,5,7'          => '5-14',
    '0,1,2,5,8'          => '5-Z38',
    '0,1,2,6,7'          => '5-7',
    '0,1,2,6,8'          => '5-15',
    '0,1,3,4,6'          => '5-10',
    '0,1,3,4,7'          => '5-16',
    '0,1,3,4,8'          => '5-Z17',
    '0,1,3,5,6'          => '5-Z12',
    '0,1,3,5,7'          => '5-24',
    '0,1,3,5,8'          => '5-27',
    '0,1,3,6,7'          => '5-19',
    '0,1,3,6,8'          => '5-29',
    '0,1,3,6,9'          => '5-31',
    '0,1,4,5,7'          => '5-Z18',
    '0,1,4,5,8'          => '5-21',
    '0,1,4,6,8'          => '5-30',
    '0,1,4,6,9'          => '5-32',
    '0,1,4,7,8'          => '5-22',
    '0,1,5,6,8'          => '5-20',
    '0,2,3,4,6'          => '5-8',
    '0,2,3,4,7'          => '5-11',
    '0,2,3,5,7'          => '5-23',
    '0,2,3,5,8'          => '5-25',
    '0,2,3,6,8'          => '5-28',
    '0,2,4,5,8'          => '5-26',
    '0,2,4,6,8'          => '5-33',
    '0,2,4,6,9'          => '5-34',
    '0,2,4,7,9'          => '5-35',
    '0,3,4,5,8'          => '5-Z37',
    # septachords (pentachords)
    '0,1,2,3,4,5,6'      => '7-1',
    '0,1,2,3,4,5,7'      => '7-2',
    '0,1,2,3,4,6,7'      => '7-4',
    '0,1,2,3,5,6,7'      => '7-5',
    '0,1,2,3,4,5,8'      => '7-3',
    '0,1,2,3,4,6,8'      => '7-9',
    '0,1,2,3,5,6,8'      => '7-Z36',
    '0,1,2,4,5,6,8'      => '7-13',
    '0,1,2,3,4,7,8'      => '7-6',
    '0,1,2,3,5,7,8'      => '7-14',
    '0,1,2,4,5,7,8'      => '7-Z38',
    '0,1,2,3,6,7,8'      => '7-7',
    '0,1,2,4,6,7,8'      => '7-15',
    '0,1,2,3,4,6,9'      => '7-10',
    '0,1,2,3,5,6,9'      => '7-16',
    '0,1,2,4,5,6,9'      => '7-Z17',
    '0,1,2,3,4,7,9'      => '7-Z12',
    '0,1,2,3,5,7,9'      => '7-24',
    '0,1,2,4,5,7,9'      => '7-27',
    '0,1,2,3,6,7,9'      => '7-19',
    '0,1,2,4,6,7,9'      => '7-29',
    '0,1,3,4,6,7,9'      => '7-31',
    '0,1,4,5,6,7,9'      => '7-Z18', # buggy in rahn1980
    '0,1,2,4,5,8,9'      => '7-21',
    '0,1,2,4,6,8,9'      => '7-30',
    '0,1,3,4,6,8,9'      => '7-32',
    '0,1,2,5,6,8,9'      => '7-22',
    '0,1,2,5,6,7,9'      => '7-20', # buggy in rahn1980
    '0,2,3,4,5,6,8'      => '7-8',
    '0,1,3,4,5,6,8'      => '7-11',
    '0,2,3,4,5,7,9'      => '7-23',
    '0,2,3,4,6,7,9'      => '7-25',
    '0,1,3,5,6,7,9'      => '7-28',
    '0,1,3,4,5,7,9'      => '7-26',
    '0,1,2,4,6,8,10'     => '7-33',
    '0,1,3,4,6,8,10'     => '7-34',
    '0,1,3,5,6,8,10'     => '7-35',
    '0,1,3,4,5,7,8'      => '7-Z37',
    # hexachords, by first column and then sparse 2nd column
    '0,1,2,3,4,5'        => '6-1',
    '0,1,2,3,4,6'        => '6-2',
    '0,1,2,3,4,7'        => '6-Z36',
    '0,1,2,3,4,8'        => '6-Z37',
    '0,1,2,3,5,7'        => '6-9',
    '0,1,2,3,5,8'        => '6-Z40',
    '0,1,2,3,6,7'        => '6-5',
    '0,1,2,3,6,8'        => '6-Z41',
    '0,1,2,3,6,9'        => '6-Z42',
    '0,1,2,3,7,8'        => '6-Z38',
    '0,1,2,4,5,8'        => '6-15',
    '0,1,2,4,6,8'        => '6-22',
    '0,1,2,4,6,9'        => '6-Z46',
    '0,1,2,4,7,8'        => '6-Z17',
    '0,1,2,4,7,9'        => '6-Z47',
    '0,1,2,5,6,9'        => '6-Z44',
    '0,1,2,5,7,8'        => '6-18',
    '0,1,2,5,7,9'        => '6-Z48',
    '0,1,2,6,7,8'        => '6-7',
    '0,1,3,4,5,7'        => '6-Z10',
    '0,1,3,4,5,8'        => '6-14',
    '0,1,3,4,6,9'        => '6-27',
    '0,1,3,4,7,9'        => '6-Z49',
    '0,1,3,5,7,9'        => '6-34',
    '0,1,4,5,7,9'        => '6-31',
    '0,1,3,6,7,9'        => '6-30',
    '0,2,3,6,7,9'        => '6-Z29',
    '0,1,4,5,6,8'        => '6-16',
    '0,1,4,5,8,9'        => '6-20',
    '0,2,3,4,5,7'        => '6-8',
    '0,2,3,4,6,8'        => '6-21',
    '0,2,3,4,6,9'        => '6-Z45',
    '0,2,3,5,7,9'        => '6-33',
    '0,2,4,5,7,9'        => '6-32',
    '0,2,4,6,8,10'       => '6-35',
    '0,1,2,3,5,6'        => '6-Z3',
    '0,1,2,4,5,6'        => '6-Z4',
    '0,1,2,4,5,7'        => '6-Z11',
    '0,1,2,4,6,7'        => '6-Z12',
    '0,1,3,4,6,7'        => '6-Z13',
    '0,1,2,5,6,7'        => '6-Z6',
    '0,1,3,4,6,8'        => '6-Z24',
    '0,1,2,5,6,8'        => '6-Z43',
    '0,1,3,5,6,8'        => '6-Z25',
    '0,1,3,4,7,8'        => '6-Z19',
    '0,1,3,5,7,8'        => '6-Z26',
    '0,2,3,4,5,8'        => '6-Z39',
    '0,1,3,5,6,9'        => '6-Z28',
    '0,1,4,6,7,9'        => '6-Z50',
    '0,2,3,5,6,8'        => '6-Z23',
);

# NOTE may need [AB]? at end for what I call "half prime" forms, as
# wikipedia has switched to using that form.
my $FORTE_NUMBER_RE = qr/[3-9]-[zZ]?\d{1,2}/;

########################################################################
#
# SUBROUTINES

# Utility method for check_melody - takes melody, a list of pitches,
# optionally how many notes (beyond that of pitches to audit) to check,
# and a code reference that will accept a selection of the melody and
# return something that will be tested against the list of pitches
# (second argument) for equality: true if match, false if not (and then
# a bunch of references containing what failed).
sub _apply_melody_rule {
    my ( $self, $melody, $check_set, $note_count, $code, $flag_sort ) = @_;
    $flag_sort //= 0;

    # make equal to the set if less than the set. no high value test as
    # loop will abort if note_count exceeds the length of melody, below.
    $note_count //= 0;
    $note_count = @$check_set if $note_count < @$check_set;

    # rule is too large for the melody, skip
    return 1, {} if @$check_set > @$melody;

    for my $i ( 0 .. @$melody - @$check_set ) {
        my @selection = @{$melody}[ $i .. $i + @$check_set - 1 ];

        my $sel_audit = $code->( $self, \@selection );
        @$sel_audit = sort { $a <=> $b } @$sel_audit if $flag_sort;
        if ( "@$sel_audit" eq "@$check_set" ) {
            return 0, { index => $i, selection => \@selection };
        }

        if ( $note_count > @$check_set ) {
            for my $count ( @$check_set + 1 .. $note_count ) {
                last if $i + $count - 1 > $#$melody;

                @selection = @{$melody}[ $i .. $i + $count - 1 ];
                my $iter = combinations( \@selection, scalar @$check_set );

                while ( my $subsel = $iter->next ) {
                    $sel_audit = $code->( $self, $subsel );
                    @$sel_audit = sort { $a <=> $b } @$sel_audit if $flag_sort;
                    if ( "@$sel_audit" eq "@$check_set" ) {
                        return 0, { context => \@selection, index => $i, selection => $subsel };
                    }
                }
            }
        }
    }

    return 1, {};
}

# Like interval class content (ICC) but instead only calculates adjacent
# intervals. -- "The Geometry of Musical Rhythm", G.T. Toussaint.
# (Perhaps more suitable for rhythm as the adjacent intervals there are
# probably more audible than some harmonic between inner voices.)
sub adjacent_interval_content {
    my $self = shift;
    my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

    my %seen;
    my @nset = sort { $a <=> $b } grep { !$seen{$_}++ } @$pset;
    croak 'pitch set must contain at least two elements' if @nset < 2;

    my %aic;
    for my $i ( 1 .. $#nset ) {
        $aic{ ( $nset[$i] - $nset[ $i - 1 ] ) % $self->{_DEG_IN_SCALE} }++;
    }
    # and the wrap-around adjacent interval
    if ( @nset > 2 ) {
        $aic{ ( $nset[0] + $self->{_DEG_IN_SCALE} - $nset[-1] )
              % $self->{_DEG_IN_SCALE} }++;
    }

    my @aiv;
    for my $ics ( 1 .. int( $self->{_DEG_IN_SCALE} / 2 ) ) {
        push @aiv, $aic{$ics} || 0;
    }

    return wantarray ? ( \@aiv, \%aic ) : \@aiv;
}

# Utility, converts a scale_degrees-bit number into a pitch set.
#            7   3  0
# 137 -> 000010001001 -> [0,3,7]
sub bits2pcs {
    my ( $self, $bs ) = @_;

    my @pset;
    for my $p ( 0 .. $self->{_DEG_IN_SCALE} - 1 ) {
        push @pset, $p if $bs & ( 1 << $p );
    }
    return \@pset;
}

# Audits a sequence of pitches for suitability, per various checks
# passed in via the params hash (based on Smith-Brindle Reginald's
# "Serial Composition" discussion of atonal melody construction).
sub check_melody {
    my $self   = shift;
    my $params = shift;
    my $melody = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

    my $rules_applied = 0;

    my ( %intervals, @intervals );
    for my $i ( 1 .. $#$melody ) {
        my $ival = abs $melody->[$i] - $melody->[ $i - 1 ];
        $intervals{$ival}++;
        push @intervals, $ival;
    }

    if ( exists $params->{dup_interval_limit} ) {
        for my $icount ( values %intervals ) {
            if ( $icount >= $params->{dup_interval_limit} ) {
                return wantarray ? ( 0, "dup_interval_limit" ) : 0;
            }
        }
        $rules_applied++;
    }

    for my $ruleset ( @{ $params->{exclude_interval} || [] } ) {
        croak "no interval set in exclude_interval rule"
          if not exists $ruleset->{iset}
          or ref $ruleset->{iset} ne 'ARRAY';
        next if @{ $ruleset->{iset} } > @intervals;

        # check (magnitude of the) intervals of the melody. code ref just
        # returns the literal intervals to compare against what is in the
        # iset. (other options might be to ICC the intervals, or fold them
        # into a single register, etc. but that would take more coding.)
        my ( $ret, $results ) = $self->_apply_melody_rule(
            \@intervals, $ruleset->{iset}, $ruleset->{in},
            sub { [ @{ $_[1] } ] },
            $ruleset->{sort} ? 1 : 0
        );
        if ( $ret != 1 ) {
            return wantarray ? ( 0, "exclude_interval", $results ) : 0;
        }
        $rules_applied++;
    }

    for my $ps_ref ( [qw/exclude_prime prime_form/],
        [qw/exclude_half_prime half_prime_form/] ) {
        my $ps_rule   = $ps_ref->[0];
        my $ps_method = $ps_ref->[1];

        for my $ruleset ( @{ $params->{$ps_rule} || [] } ) {
            croak "no pitch set in $ps_rule rule"
              if not exists $ruleset->{ps}
              or ref $ruleset->{ps} ne 'ARRAY';

            # for intervals code, not necessary for pitch set operations, all of
            # which sort the pitches as part of the calculations involved
            delete $ruleset->{sort};

            # excludes from *any* subset for the given subset magnitudes of the
            # parent pitch set
            for my $ss_mag ( @{ $ruleset->{subsets} || [] } ) {
                croak "subset must be of lesser magnitude than pitch set"
                  if $ss_mag >= @{ $ruleset->{ps} };
                my $in_ss = $ruleset->{in} // 0;
                $in_ss = @{ $ruleset->{ps} }
                  if $in_ss < @{ $ruleset->{ps} };
                # except scale down to fit smaller subset pitch set
                $in_ss -= @{ $ruleset->{ps} } - $ss_mag;

                next if $in_ss > @$melody;

                my $all_subpsets = $self->subsets( $ss_mag, $ruleset->{ps} );
                my %seen_s_pset;
                for my $s_pset (@$all_subpsets) {
                    my $s_prime = $self->$ps_method($s_pset);
                    next if $seen_s_pset{"@$s_prime"}++;
                    my ( $ret, $results ) =
                      $self->_apply_melody_rule( $melody, $s_prime,
                        $in_ss, sub { $_[0]->$ps_method( $_[1] ) } );
                    if ( $ret != 1 ) {
                        return wantarray ? ( 0, $ps_rule, $results ) : 0;
                    }
                }
                $rules_applied++;
            }

            my ( $ret, $results ) =
              $self->_apply_melody_rule( $melody, $ruleset->{ps}, $ruleset->{in},
                sub { $_[0]->$ps_method( $_[1] ) } );
            if ( $ret != 1 ) {
                return wantarray ? ( 0, $ps_rule, $results ) : 0;
            }

            $rules_applied++;
        }
    }

    if ( $rules_applied == 0 ) {
        return wantarray ? ( 0, "no rules applied" ) : 0;
    }
    return wantarray ? ( 1, "ok" ) : 1;
}

sub circular_permute {
    my $self = shift;
    my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];
    croak 'pitch set must contain something' if !@$pset;

    my @perms;
    for my $i ( 0 .. $#$pset ) {
        for my $j ( 0 .. $#$pset ) {
            $perms[$i][$j] = $pset->[ ( $i + $j ) % @$pset ];
        }
    }
    return \@perms;
}

sub complement {
    my $self = shift;
    my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

    my %seen;
    @seen{@$pset} = ();
    return [ grep { !exists $seen{$_} } 0 .. $self->{_DEG_IN_SCALE} - 1 ];
}

sub fnums { \%FORTE2PCS }

sub forte_number_re {
    return $FORTE_NUMBER_RE;
}

sub forte2pcs {
    my ( $self, $forte_number ) = @_;
    return $FORTE2PCS{ uc $forte_number };
}

# simple wrapper around check_melody to create something to work with,
# depending on the params.
sub gen_melody {
    my ( $self, %params ) = @_;

    my $attempts = 1000;    # enough for Helen, enough for us
    my $max_interval = $params{melody_max_interval} || 16;    # tessitura of a 10th
    delete $params{melody_max_interval};

    if ( !keys %params ) {
        # based on Reginald's ideas (insofar as those can be represented by
        # the rules system I've cobbled together)
        %params = (
            exclude_half_prime => [
                { ps => [ 0, 4, 5 ] },    # leading tone/tonic/dominant
            ],
            exclude_interval => [
                { iset => [ 5, 5 ], },    # adjacent fourths ("cadential basses")
            ],
            exclude_prime => [
                { ps => [ 0, 3, 7 ], in => 4 },    # major or minor triad, any guise
                { ps => [ 0, 2, 5, 8 ], },         # 7th, any guise, exact
                { ps => [ 0, 2, 4, 6 ], in => 5 }, # whole tone formation
                        # 7-35 (major/minor scale) but also excluding from all 5-x or
                        # 6-x subsets of said set
                { ps => [ 0, 1, 3, 5, 6, 8, 10 ], subsets => [ 6, 5 ] },
            ],
        );
    }

    my $got_melody = 0;
    my @melody;
    eval {
        ATTEMPT: while ( $attempts-- > 0 ) {
            my %seen;
            my @pitches = 0 .. $self->{_DEG_IN_SCALE} - 1;
            @melody = splice @pitches, rand @pitches, 1;
            $seen{ $melody[0] } = 1;
            my $melody_low  = $melody[0];
            my $melody_high = $melody[0];

            while (@pitches) {
                my @potential = grep {
                    my $base_pitch = $_ % 12;
                    my $ret        = 0;
                    for my $p (@pitches) {
                        if ( $base_pitch == $p ) { $ret = 1; last }
                    }
                    $ret
                } $melody_high - $max_interval .. $melody_low + $max_interval;
                my $choice      = $potential[ rand @potential ];
                my $base_choice = $choice % 12;
                @pitches = grep $_ != $base_choice, @pitches;
                push @melody, $choice;

                $melody_low  = $choice if $choice < $melody_low;
                $melody_high = $choice if $choice > $melody_high;
            }

            # but negative pitches are awkward for various reasons
            if ( $melody_low < 0 ) {
                $melody_low = abs $melody_low;
                $_ += $melody_low for @melody;
            }

            ( $got_melody, my $msg ) = $self->check_melody( \%params, \@melody );
            next ATTEMPT if $got_melody != 1;

            last;
        }
    };
    croak $@ if $@;
    croak "could not generate a melody" unless $got_melody;

    return \@melody;
}

# copied from Music::NeoRiemannianTonnetz 'normalize', see perldocs
# for differences between this and prime_form and normal_form
sub half_prime_form {
    my $self = shift;
    my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

    croak 'pitch set must contain something' if !@$pset;

    my %origmap;
    for my $p (@$pset) {
        push @{ $origmap{ $p % $self->{_DEG_IN_SCALE} } }, $p;
    }
    if ( keys %origmap == 1 ) {
        return wantarray ? ( keys %origmap, \%origmap ) : keys %origmap;
    }
    my @nset = sort { $a <=> $b } keys %origmap;

    my @equivs;
    for my $i ( 0 .. $#nset ) {
        for my $j ( 0 .. $#nset ) {
            $equivs[$i][$j] = $nset[ ( $i + $j ) % @nset ];
        }
    }
    my @order = reverse 1 .. $#nset;

    my @normal;
    for my $i (@order) {
        my $min_span = $self->{_DEG_IN_SCALE};
        my @min_span_idx;

        for my $eidx ( 0 .. $#equivs ) {
            my $span =
              ( $equivs[$eidx][$i] - $equivs[$eidx][0] ) % $self->{_DEG_IN_SCALE};
            if ( $span < $min_span ) {
                $min_span     = $span;
                @min_span_idx = $eidx;
            } elsif ( $span == $min_span ) {
                push @min_span_idx, $eidx;
            }
        }

        if ( @min_span_idx == 1 ) {
            @normal = @{ $equivs[ $min_span_idx[0] ] };
            last;
        } else {
            @equivs = @equivs[@min_span_idx];
        }
    }

    if ( !@normal ) {
        # nothing unique, pick lowest starting pitch, which is first index
        # by virtue of the numeric sort performed above.
        @normal = @{ $equivs[0] };
    }

    # but must map <b dis fis> (and anything else not <c e g>) so b is 0,
    # dis 4, etc. and also update the original pitch mapping - this is
    # the major addition to the otherwise stock normal_form code.
    if ( $normal[0] != 0 ) {
        my $trans = $self->{_DEG_IN_SCALE} - $normal[0];
        my %newmap;
        for my $i (@normal) {
            my $prev = $i;
            $i = ( $i + $trans ) % $self->{_DEG_IN_SCALE};
            $newmap{$i} = $origmap{$prev};
        }
        %origmap = %newmap;
    }

    return wantarray ? ( \@normal, \%origmap ) : \@normal;
}

sub interval_class_content {
    my $self = shift;
    my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

    my %seen;
    my @nset = sort { $a <=> $b } grep { !$seen{$_}++ } @$pset;
    croak 'pitch set must contain at least two elements' if @nset < 2;

    my %icc;
    for my $i ( 1 .. $#nset ) {
        for my $j ( 0 .. $i - 1 ) {
            $icc{
                $self->pitch2intervalclass(
                    ( $nset[$i] - $nset[$j] ) % $self->{_DEG_IN_SCALE}
                )
            }++;
        }
    }

    my @icv;
    for my $ics ( 1 .. int( $self->{_DEG_IN_SCALE} / 2 ) ) {
        push @icv, $icc{$ics} || 0;
    }

    return wantarray ? ( \@icv, \%icc ) : \@icv;
}

sub intervals2pcs {
    my $self        = shift;
    my $start_pitch = shift;
    my $iset        = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];
    croak 'interval set must contain something' if !@$iset;

    $start_pitch //= 0;
    $start_pitch = int $start_pitch;

    my @pset = $start_pitch;
    for my $i (@$iset) {
        push @pset, ( $pset[-1] + $i ) % $self->{_DEG_IN_SCALE};
    }

    return \@pset;
}

sub invariance_matrix {
    my $self = shift;
    my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];
    croak 'pitch set must contain something' if !@$pset;

    my @ivm;
    for my $i ( 0 .. $#$pset ) {
        for my $j ( 0 .. $#$pset ) {
            $ivm[$i][$j] = ( $pset->[$i] + $pset->[$j] ) % $self->{_DEG_IN_SCALE};
        }
    }

    return \@ivm;
}

sub invert {
    my $self = shift;
    my $axis = shift;
    my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];
    croak 'pitch set must contain something' if !@$pset;

    $axis //= 0;
    $axis = int $axis;

    my @inverse = @$pset;
    for my $p (@inverse) {
        $p = ( $axis - $p ) % $self->{_DEG_IN_SCALE};
    }

    return \@inverse;
}

# Utility routine to get the last few elements of a list (but never more
# than the whole list, etc).
sub lastn {
    my ( $self, $pset, $n ) = @_;
    croak 'cannot get elements of nothing'
      if !defined $pset
      or ref $pset ne 'ARRAY';

    return unless @$pset;

    $n //= $self->{_lastn};
    croak 'n of lastn must be number' unless looks_like_number $n;

    my $len = @$pset;
    $len = $n if $len > $n;
    $len *= -1;
    return @{$pset}[ $len .. -1 ];
}

sub mininterval {
    my ( $self, $from, $to ) = @_;
    my $dir = 1;

    croak 'from pitch must be a number' unless looks_like_number $from;
    croak 'to pitch must be a number'   unless looks_like_number $to;

    $from %= $self->{_DEG_IN_SCALE};
    $to   %= $self->{_DEG_IN_SCALE};

    if ( $from > $to ) {
        ( $from, $to ) = ( $to, $from );
        $dir = -1;
    }
    my $interval = $to - $from;
    if ( $interval > $self->{_DEG_IN_SCALE} / 2 ) {
        $dir *= -1;
        $from += $self->{_DEG_IN_SCALE};
        $interval = $from - $to;
    }

    return $interval * $dir;
}

sub multiply {
    my $self   = shift;
    my $factor = shift;
    my $pset   = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];
    croak 'pitch set must contain something' if !@$pset;

    $factor //= 1;
    $factor = int $factor;

    return [ map { my $p = $_ * $factor % $self->{_DEG_IN_SCALE}; $p } @$pset ];
}

# Utility methods for get/check/reset of each element in turn of a given
# array reference, with wrap-around. Handy if pulling sequential
# elements off a list, but have much code between the successive calls.
{
    my %seen;

    # get the iterator value for a ref
    sub geti {
        my ( $self, $ref ) = @_;
        return $seen{ refaddr $ref} || 0;
    }

    # nexti(\@array) - returns subsequent elements of array on each
    # successive call
    sub nexti {
        my ( $self, $ref ) = @_;
        $seen{ refaddr $ref} ||= 0;
        $ref->[ ++$seen{ refaddr $ref} % @$ref ];
    }

    # reseti(\@array) - resets counter
    sub reseti {
        my ( $self, $ref ) = @_;
        $seen{ refaddr $ref} = 0;
    }

    # set the iterator for a ref
    sub seti {
        my ( $self, $ref, $i ) = @_;
        croak 'iterator must be number'
          unless looks_like_number($i);
        $seen{ refaddr $ref} = $i;
    }

    # returns current element, but does not advance pointer
    sub whati {
        my ( $self, $ref ) = @_;
        $seen{ refaddr $ref} ||= 0;
        $ref->[ $seen{ refaddr $ref} % @$ref ];
    }
}

sub new {
    my ( $class, %param ) = @_;
    my $self = {};

    $self->{_DEG_IN_SCALE} = int( $param{DEG_IN_SCALE} // $DEG_IN_SCALE );
    if ( $self->{_DEG_IN_SCALE} < 2 ) {
        croak 'degrees in scale must be greater than one';
    }

    if ( exists $param{lastn} ) {
        croak 'lastn must be number'
          unless looks_like_number $param{lastn};
        $self->{_lastn} = $param{lastn};
    } else {
        $self->{_lastn} = 2;
    }

    # XXX packing not implemented beyond "right" method (via www.mta.ca docs)
    $self->{_packing} = $param{PACKING} // 'right';

    bless $self, $class;
    return $self;
}

sub normal_form {
    my $self = shift;
    my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

    croak 'pitch set must contain something' if !@$pset;

    my %origmap;
    for my $p (@$pset) {
        push @{ $origmap{ $p % $self->{_DEG_IN_SCALE} } }, $p;
    }
    if ( keys %origmap == 1 ) {
        return wantarray ? ( [ keys %origmap ], \%origmap ) : [ keys %origmap ];
    }
    my @nset = sort { $a <=> $b } keys %origmap;

    my $equivs = $self->circular_permute( \@nset );
    my @order  = 1 .. $#nset;
    if ( $self->{_packing} eq 'right' ) {
        @order = reverse @order;
    } elsif ( $self->{_packing} eq 'left' ) {
        # XXX not sure about this, www.mta.ca instructions not totally
        # clear on the Forte method, and the 7-Z18 (0234589) form
        # listed there reduces to (0123589). So, blow up until can
        # figure that out.
        #      unshift @order, pop @order;
        # Also, the inclusion of http://en.wikipedia.org/wiki/Forte_number
        # plus a prime_form call on those pitch sets shows no changes caused
        # by the default 'right' packing method, so sticking with it until
        # learn otherwise. (In hindsight, the right packing method is that
        # of rahn1980, so sticking with that...)
        die 'left packing method not yet implemented (sorry)';
    } else {
        croak 'unknown packing method (try the "right" one)';
    }

    my @normal;
    for my $i (@order) {
        my $min_span = $self->{_DEG_IN_SCALE};
        my @min_span_idx;

        for my $eidx ( 0 .. $#$equivs ) {
            my $span =
              ( $equivs->[$eidx][$i] - $equivs->[$eidx][0] ) % $self->{_DEG_IN_SCALE};
            if ( $span < $min_span ) {
                $min_span     = $span;
                @min_span_idx = $eidx;
            } elsif ( $span == $min_span ) {
                push @min_span_idx, $eidx;
            }
        }

        if ( @min_span_idx == 1 ) {
            @normal = @{ $equivs->[ $min_span_idx[0] ] };
            last;
        } else {
            @$equivs = @{$equivs}[@min_span_idx];
        }
    }

    if ( !@normal ) {
        # nothing unique, pick lowest starting pitch, which is first index
        # by virtue of the numeric sort performed above.
        @normal = @{ $equivs->[0] };
    }

    $_ += 0 for @normal;    # KLUGE avoid Test::Differences seeing '4' vs. 4

    return wantarray ? ( \@normal, \%origmap ) : \@normal;
}

# Utility, converts a pitch set into a scale_degrees-bit number:
#                7   3  0
# [0,3,7] -> 000010001001 -> 137
sub pcs2bits {
    my $self = shift;
    my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

    croak 'pitch set must contain something' if !@$pset;

    my $bs = 0;
    for my $p ( map $_ % $self->{_DEG_IN_SCALE}, @$pset ) {
        $bs |= 1 << $p;
    }
    return $bs;
}

sub pcs2forte {
    my $self = shift;
    my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

    croak 'pitch set must contain something' if !@$pset;

    return $PCS2FORTE{ join ',', @{ $self->prime_form($pset) } };
}

sub pcs2intervals {
    my $self = shift;
    my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

    croak 'pitch set must contain at least two elements' if @$pset < 2;

    my @intervals;
    for my $i ( 1 .. $#{$pset} ) {
        push @intervals, $pset->[$i] - $pset->[ $i - 1 ];
    }

    return \@intervals;
}

sub pcs2str {
    my $self = shift;
    croak 'must supply a pitch set' if !defined $_[0];

    my $str;
    if ( ref $_[0] eq 'ARRAY' ) {
        $str = '[' . join( ',', @{ $_[0] } ) . ']';
    } elsif ( $_[0] =~ m/,/ ) {
        $str = '[' . $_[0] . ']';
    } else {
        $str = '[' . join( ',', @_ ) . ']';
    }
    return $str;
}

sub pitch2intervalclass {
    my ( $self, $pitch ) = @_;

    # ensure member of the tone system, otherwise strange results
    $pitch %= $self->{_DEG_IN_SCALE};

    return $pitch > int( $self->{_DEG_IN_SCALE} / 2 )
      ? $self->{_DEG_IN_SCALE} - $pitch
      : $pitch;
}

# XXX tracking of original pitches would be nice, though complicated, as
# ->invert would need to be modified or a non-modulating version used
sub prime_form {
    my $self = shift;
    my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

    croak 'pitch set must contain something' if !@$pset;

    my @forms = scalar $self->normal_form($pset);
    push @forms, scalar $self->normal_form( $self->invert( 0, $forms[0] ) );

    for my $set (@forms) {
        $set = $self->transpose( $self->{_DEG_IN_SCALE} - $set->[0], $set )
          if $set->[0] != 0;
    }

    my @prime;
    if ( "@{$forms[0]}" eq "@{$forms[1]}" ) {
        @prime = @{ $forms[0] };
    } else {
        # look for most compact to the left
        my @sums = ( 0, 0 );
      PITCH:
        for my $i ( 0 .. $#$pset ) {
            for my $j ( 0 .. 1 ) {
                $sums[$j] += $forms[$j][$i];
            }
            if ( $sums[0] < $sums[1] ) {
                @prime = @{ $forms[0] };
                last PITCH;
            } elsif ( $sums[0] > $sums[1] ) {
                @prime = @{ $forms[1] };
                last PITCH;
            }
        }
    }

    return \@prime;
}

# Utility, "mirrors" a pitch to be within supplied min/max values as
# appropriate for how many times the pitch "reflects" back within those
# limits, which will depend on which limit is broken and by how much.
sub reflect_pitch {
    my ( $self, $v, $min, $max ) = @_;
    croak 'pitch must be a number' if !looks_like_number $v;
    croak 'limits must be numbers and min less than max'
      if !looks_like_number $min
      or !looks_like_number $max
      or $min >= $max;
    return $v if $v <= $max and $v >= $min;

    my ( @origins, $overshoot, $direction );
    if ( $v > $max ) {
        @origins   = ( $max, $min );
        $overshoot = abs( $v - $max );
        $direction = -1;
    } else {
        @origins   = ( $min, $max );
        $overshoot = abs( $min - $v );
        $direction = 1;
    }
    my $range    = abs( $max - $min );
    my $register = int( $overshoot / $range );
    if ( $register % 2 == 1 ) {
        @origins = reverse @origins;
        $direction *= -1;
    }
    my $remainder = $overshoot % $range;

    return $origins[0] + $remainder * $direction;
}

sub retrograde {
    my $self = shift;
    my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

    croak 'pitch set must contain something' if !@$pset;

    return [ reverse @$pset ];
}

sub rotate {
    my $self = shift;
    my $r    = shift;
    my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

    croak 'rotate value must be integer'
      if !defined $r
      or $r !~ /^-?\d+$/;
    croak 'pitch set must contain something' if !@$pset;

    my @rot;
    if ( $r == 0 ) {
        @rot = @$pset;
    } else {
        for my $i ( 0 .. $#$pset ) {
            $rot[$i] = $pset->[ ( $i - $r ) % @$pset ];
        }
    }

    return \@rot;
}

# Utility method to rotate a list to a named element (for example "gis"
# in a list of note names, see my etude no.2 for results of heavy use of
# such rotations).
sub rotateto {
    my $self = shift;
    my $what = shift;
    my $dir  = shift;
    my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

    croak 'nothing to search on' unless defined $what;
    croak 'nothing to rotate on' if !@$pset;

    my @idx = 0 .. $#$pset;

    $dir //= 1;
    @idx = reverse @idx if $dir < 0;

    for my $i (@idx) {
        next unless $pset->[$i] eq $what;
        return $self->rotate( -$i, $pset );
    }
    croak "no such element $what";
}

# XXX probably should disallow changing this on the fly, esp. if allow
# method chaining, as it could throw off results in wacky ways.
sub scale_degrees {
    my ( $self, $dis ) = @_;
    if ( defined $dis ) {
        croak 'scale degrees value must be positive integer greater than 1'
          if !defined $dis
          or $dis !~ /^\d+$/
          or $dis < 2;
        $self->{_DEG_IN_SCALE} = $dis;
    }
    return $self->{_DEG_IN_SCALE};
}

sub set_complex {
    my $self = shift;
    my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

    croak 'pitch set must contain something' if !@$pset;

    my $iset = $self->invert( 0, $pset );
    my $dis = $self->scale_degrees;

    my @plex = $pset;
    for my $i ( 1 .. $#$pset ) {
        for my $j ( 0 .. $#$pset ) {
            if ( $j == 0 ) {
                $plex[$i][0] = $iset->[$i];
            } else {
                $plex[$i][$j] = ( $pset->[$j] + $iset->[$i] ) % $dis;
            }
        }
    }

    return \@plex;
}

sub subsets {
    my $self = shift;
    my $len  = shift;
    my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

    my %seen;
    my @nset =
      map { my $p = $_ % $self->{_DEG_IN_SCALE}; !$seen{$p}++ ? $p : () } @$pset;
    croak 'pitch set must contain two or more unique pitches' if @nset < 2;

    if ( defined $len ) {
        croak 'length must be less than size of pitch set (but not zero)'
          if $len >= @nset
          or $len == 0;
        if ( $len < 0 ) {
            $len = @nset + $len;
            croak 'negative length exceeds magnitude of pitch set' if $len < 1;
        }
    } else {
        $len = @nset - 1;
    }

    return [ combinations( \@nset, $len ) ];
}

sub tcis {
    my $self = shift;
    my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

    croak 'pitch set must contain something' if !@$pset;

    my %seen;
    @seen{@$pset} = ();

    my @tcis;
    for my $i ( 0 .. $self->{_DEG_IN_SCALE} - 1 ) {
        $tcis[$i] = 0;
        for my $p ( @{ $self->transpose_invert( $i, 0, $pset ) } ) {
            $tcis[$i]++
              if exists $seen{$p};
        }
    }
    return \@tcis;
}

sub tcs {
    my $self = shift;
    my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

    croak 'pitch set must contain something' if !@$pset;

    my %seen;
    @seen{@$pset} = ();

    my @tcs = scalar @$pset;
    for my $i ( 1 .. $self->{_DEG_IN_SCALE} - 1 ) {
        $tcs[$i] = 0;
        for my $p ( @{ $self->transpose( $i, $pset ) } ) {
            $tcs[$i]++
              if exists $seen{$p};
        }
    }
    return \@tcs;
}

sub transpose {
    my $self = shift;
    my $t    = shift;
    my @tset = ref $_[0] eq 'ARRAY' ? @{ $_[0] } : @_;

    croak 'transpose value not set' if !defined $t;
    croak 'pitch set must contain something' if !@tset;

    $t = int $t;
    for my $p (@tset) {
        $p = ( $p + $t ) % $self->{_DEG_IN_SCALE};
    }
    return \@tset;
}

sub transpose_invert {
    my $self = shift;
    my $t    = shift;
    my $axis = shift;
    my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

    croak 'transpose value not set' if !defined $t;
    croak 'pitch set must contain something' if !@$pset;

    $axis //= 0;
    my $tset = $self->invert( $axis, $pset );

    $t = int $t;
    for my $p (@$tset) {
        $p = ( $p + $t ) % $self->{_DEG_IN_SCALE};
    }
    return $tset;
}

sub variances {
    my ( $self, $pset1, $pset2 ) = @_;

    croak 'pitch set must be array ref' unless ref $pset1 eq 'ARRAY';
    croak 'pitch set must contain something' if !@$pset1;
    croak 'pitch set must be array ref' unless ref $pset2 eq 'ARRAY';
    croak 'pitch set must contain something' if !@$pset2;

    my ( @union, @intersection, @difference, %count );
    for my $p ( @$pset1, @$pset2 ) {
        $count{$p}++;
    }
    for my $p ( sort { $a <=> $b } keys %count ) {
        push @union, $p;
        push @{ $count{$p} > 1 ? \@intersection : \@difference }, $p;
    }
    return wantarray ? ( \@intersection, \@difference, \@union ) : \@intersection;
}

sub zrelation {
    my ( $self, $pset1, $pset2 ) = @_;

    croak 'pitch set must be array ref' unless ref $pset1 eq 'ARRAY';
    croak 'pitch set must contain something' if !@$pset1;
    croak 'pitch set must be array ref' unless ref $pset2 eq 'ARRAY';
    croak 'pitch set must contain something' if !@$pset2;

    my @ic_vecs;
    for my $ps ( $pset1, $pset2 ) {
        push @ic_vecs, scalar $self->interval_class_content($ps);
    }
    return ( "@{$ic_vecs[0]}" eq "@{$ic_vecs[1]}" ) ? 1 : 0;
}

1;
__END__

=head1 NAME

Music::AtonalUtil - atonal music analysis and composition

=head1 SYNOPSIS

  use Music::AtonalUtil ();
  my $atu = Music::AtonalUtil->new;

  my $nf = $atu->normal_form([0,3,7]);
  my $pf = $atu->prime_form(0, 4, 7);
  ...

Though see below for the (many) other methods.

=head1 DESCRIPTION

This module contains a variety of routines for atonal music composition
and analysis (plus a bunch of somewhat related routines). See the
methods below, the test suite, and the C<atonal-util> command line
interface in L<App::MusicTools> for pointers on usage.

This module follows the Rahn method of prime form calculation (as
opposed to the Forte method). The prime numbers have been audited
against Rahn's "Basic Atonal Theory".

=head1 CONSTRUCTOR

By default, a 12-tone system is assumed. Input values are mapped to
reside inside this space where necessary. Most methods accept a pitch
set (an array reference consisting of a list of pitch numbers, or just a
list of such numbers), and most return an array reference containing the
results. Some sanity checking is done on the input, which may cause the
code to B<croak> if something is awry.

=head2 B<new> I<parameter_pairs ...>

The degrees in the scale can be adjusted via:

  Music::AtonalUtil->new(DEG_IN_SCALE => 17);

or some other positive integer greater than one, to use a non-12-tone
basis for subsequent method calls. This value can be set or inspected
via the B<scale_degrees> method. B<Note that while non-12-tone systems
are in theory supported, they have not much been tested.> Rhythmic
analysis overlaps with various routines available; this is a practical
use for a different number of "scale" degrees.

=head1 METHODS

=head2 B<adjacent_interval_content> I<pitch_set>

A modified form of B<interval_class_content> that only calculates
adjacent interval counts for the given pitch set. Return values same as
for B<interval_class_content> method.

This method suits rhythmic analysis, see L</"RHYTHM">.

=head2 B<bits2pcs> I<number>

Converts a number into a I<pitch_set>, and returns said set as an array
reference. Performs opposite role of the B<pcs2bits> method. Will not
consider bits beyond B<scale_degrees> in the input number.

=head2 B<check_melody> I<params ref>, I<pitch_set>

Given a set of parameters and a melody (an array reference of pitch
numbers), returns false if the melody fails any of the rules present in
the parameters, or true otherwise. See B<gen_melody> for one method of
melody generation. The return value in scalar context will be a boolean;
in list context, the boolean will be followed by a rule name and then
depending on the rule possible a third return value, an hash reference
containing details of what failed where.

Parameters (at least one must be specified, doubtless more):

=over 4

=item I<dup_interval_limit> => I<count>

Rejects the melody if there are a number of intervals equal to or
greater than the specified I<count>.

=item I<exclude_interval> => [ I<list of hashes> ... ]

Rejects the melody should it contain specified patterns of intervals.
Only the magnitude of the interval is considered, and not the direction.
An example, whose ending in rising fourths would be unacceptable in a
strict atonal context:

  $atu->check_melody(
    [qw/60 64 57 59 60 57 65 64 62 67 72/],
    exclude_interval => [
      { iset => [ 5, 5 ], }, # adjacent fourths ("cadential basses")
    ],
  );

In addition to the I<iset> interval array reference, an I<in> value can
specify in how many intervals (above that of the I<iset>) to search for
the specified intervals. The following would look for two perfect
fourths, optionally with some other interval between them:

      { iset => [ 5, 5 ], in => 3 },

Intervals in any order may be considered by adding the I<sort> flag, and
then numbering the intervals to match from low to high:

      { iset => [ 1, 2, 3 ], sort => 1 },

=item I<exclude_half_prime> => [ I<list of hashes> ... ]

Rejects the melody should it contain notes comprising the specified so-
called "half prime" form. The I<ps> value pitch set must be in
B<half_prime_form>. Otherwise identical to I<exclude_prime>.

=item I<exclude_prime> => [ I<list of hashes> ... ]

Rejects the melody should it contain notes comprising the specified
prime forms. The I<ps> value pitch set must be in B<prime_form>.

  exclude_prime => [
    { ps => [ 0, 3, 7 ], in => 4 }, # major or minor triad, any guise
    { ps => [ 0, 2, 5, 8 ], },         # 7th, any guise, exact
    { ps => [ 0, 2, 4, 6 ], in => 5 }, # whole tone formation
  ],

Additionally, a I<subsets> key can be used to apply the rule to any
subset prime form pitch set of the input pitch set. For example, to
exclude 5 or 6 note subsets of the 7-35 pitch set:

  exclude_prime => [ {
    in => 8,                  # in 8 (or 7 or 6) note groups
    subsets => [ 5, 6 ],
    ps => [ 0, 1, 3, 5, 6, 8, 10 ],   # 7-35 (major/minor scale)
  }, ],

This method probably should not be used for smaller subsets than five,
as sets like 7-35 or larger have many subsets in the 4-x (13 prime form
subsets, to be exact) or smaller range, and with the prime form
conflation of multiple other "half prime" sets, well more pitches than
one might expect can match the rule.

=back

=head2 B<circular_permute> I<pitch_set>

Takes a pitch set (array reference to list of pitches or just a
list of such), and returns an array reference of pitch set
references as follows:

  $atu->circular_permute([1,2,3]);   # [[1,2,3],[2,3,1],[3,1,2]]

This is used by the B<normal_form> method, internally. This permutation
is identical to inversions in tonal theory, but is different from the
B<invert> method offered by this module. See also B<rotate> to rotate a
pitch set by a particular amount, or B<rotateto> to search for something
to rotate to.

=head2 B<complement> I<pitch_set>

Returns the pitches of the scale degrees not set in the passed pitch set
(an array reference to list of pitches or just a list of such).

  $atu->complement([1,2,3]);    # [0,4,5,6,7,8,9,10,11]

Calling B<prime_form> on the result will find the abstract complement of
the original set, whatever that means.

=head2 B<fnums>

Returns hash reference of which keys are Forte Numbers and values are
array references to the corresponding pitch sets. This reference should
perhaps not be fiddled with, unless the fiddler desires different
results from the B<forte2pcs> and B<pcs2forte> calls.

=head2 B<forte_number_re>

Returns a regular expression capable of matching a Forte Number.

=head2 B<forte2pcs> I<forte_number>

Given a Forte Number (such as C<6-z44> or C<6-Z44>), returns the
corresponding pitch set as an array reference, or C<undef> if an unknown
Forte Number is supplied.

=head2 B<gen_melody> I<params> ...

Generates a random 12-tone series, feeds that to B<check_melody>, tries
for a number of times until a suitable melody can be returned as an
array reference. May throw an exception if something goes awry or the
rules did not permit a melody. The 12-tone series will remain within a
single register, so the generation of melodies with 9ths or 10ths is
not possible via this method.

See B<check_melody> for documentation on the parameters; setting these
is mandatory. B<gen_melody> offers one additional parameter to set the
tessitura of the melody (in semitones; default is a 10th):

  $atu->gen_melody( melody_max_interval => 11, ... );

The L<Music::VoiceGen> module offers an alternate means of
generating melodies.

=head2 B<half_prime_form> I<pitch_set>

Returns what I call the "half prime" form of a pitch set; in scalar
context returns an array reference to the resulting pitch set, while in
list context returns an array reference and a subsequent hash reference
containing a mapping of pitch set numbers to the original pitches (as
also done by B<normal_form>).

An example with the Major and minor triads should illustrate the
differences between B<half_prime_form>, B<normal_form>, and
B<prime_form>, using C<lilypond> note names for the input and pitch
numbers for the resulting output:

  normal form <d f a>   = 2,5,9   # D minor
  normal form <d fis a> = 2,6,9   # D Major
  normal form <e g b>   = 4,7,11  # E minor
  normal form <e gis b> = 4,8,11  # E Major

  halfp form  <d f a>   = 0,3,7
  halfp form  <d fis a> = 0,4,7
  halfp form  <e g b>   = 0,3,7
  halfp form  <e gis b> = 0,4,7

  prime form  <d f a>   = 0,3,7
  prime form  <d fis a> = 0,3,7
  prime form  <e g b>   = 0,3,7
  prime form  <e gis b> = 0,3,7

Note that some pitch sets have no "half prime form" distinct from the
prime form; this distinction influences what the
L<Music::NeoRiemannianTonnetz> module can do with the pitch set, for
example (see C<eg/nrt-study-setclass> of that module).

The "half prime form" name is my invention; I have no idea if there is
another term for this calculation in music theory literature. The
wikipedia "list of pitch class sets" as of 2015 distinguishes C<3-5A>
from C<3-5B>, which would correspond to the half prime form this module
will calculate, while B<prime_form> would only find C<3-5> for any
member of that set.

=head2 B<interval_class_content> I<pitch_set>

Given a pitch set with at least two elements, returns an array reference
(and in list context also a hash reference) representing the
interval-class vector information. Pitch sets with similar ic content
tend to sound the same (see also B<zrelation>).

This vector is also known as a pitch-class interval (PIC) vector or
absolute pitch-class interval (APIC) vector:

L<https://en.wikipedia.org/wiki/Interval_vector>

Uses include an indication of invariance under transposition; see also the
B<invariants> mode of C<atonal-util> of L<App::MusicTools> for the display of
invariant pitches. It also has uses in rhythmic analysis (see works by e.g.
Godfried T. Toussaint).

=head2 B<intervals2pcs> I<start_pitch>, I<interval_set>

Given a starting pitch (set to C<0> if unsure) and an interval set (a
list of intervals or array reference of such), converts those intervals
into a pitch set, returned as an array reference.

=head2 B<invariance_matrix> I<pitch_set>

Returns reference to an array of references that comprise the invariance
under Transpose(N)Inversion operations on the given pitch set. Probably
easier to use the B<invariants> mode of C<atonal-util> of
L<App::MusicTools>, unless you know what you are doing.

=head2 B<invert> I<axis>, I<pitch_set>

Inverts the given pitch set, within the degrees in scale. Set the
I<axis> to C<0> if unsure. Returns resulting pitch set as an array
reference. Some examples or styles assume rotation with an axis of C<6>,
for example:

L<https://en.wikipedia.org/wiki/Set_%28music%29#Serial>

Has the "retrograde-inverse transposition" of C<0 11 3> becoming C<4 8
7>. This can be reproduced via:

  my $p = $atu->retrograde(0,11,3);
  $p = $atu->invert(6, $p);
  $p = $atu->transpose(1, $p);

=head2 B<lastn> I<array_ref>, I<n>

Utility method. Returns the last N elements of the supplied array
reference, or the entire list if N exceeds the number of elements
available. Returns nothing if the array reference is empty, but
otherwise will throw an exception if something is awry.

=head2 B<mininterval> I<from>, I<to>

Returns the minimum interval including sign between the given pitch numbers
within the confines of the B<scale_degrees>; that is, C to F would be five, F
to C negative five, B to C one, and C to B negative one.

=head2 B<multiply> I<factor>, I<pitch_set>

Multiplies the supplied pitch set by the given factor, modulates the
results by the B<scale_degrees> setting, and returns the results as an
array reference.

=head2 B<nexti> I<array ref>

Utility method. Returns the next item from the supplied array reference.
Loops around to the beginning of the list if the bounds of the array are
exceeded. Caches the index for subsequent lookups. Part of the B<geti>,
B<nexti>, B<reseti>, B<seti>, and B<whati> set of routines, which are
documented here:

=over 4

=item B<geti> I<array ref>

Returns current position in array (which may be larger than the number
of elements in the list, as the routines modulate the iterator down as
necessary to fit the reference).

=item B<reseti> I<array ref>

Sets the iterator to zero for the given array reference.

=item B<seti> I<array ref>, I<index>

Sets the iterator to the given value.

=item B<whati> I<array ref>

Returns the value of what is currently pointed at in the array
reference. Does not advance the index.

=back

=head2 B<normal_form> I<pitch_set>

Returns two values in list context; first, the normal form of the passed
pitch set as an array reference, and secondly, a hash reference linking
the normal form values to array references containing the input pitch
numbers those normal form values represent. An example may clarify:

  my ($ps, $lookup) = $atu->normal_form(60, 64, 67, 72); # c' e' g' c''

=over

=item *

C<$ps> is C<[0,4,7]>, as C<60> and C<72> are equivalent pitches, so both
get mapped to C<0>.

=item *

C<$lookup> contains hash keys C<0>, C<4>, and C<7>, where C<4> points to
an array reference containing C<64>, C<7> to an array reference
containing C<67>, and C<0> an array reference containing both C<60> and
C<72>. This allows software to answer "what original pitches of
the input are X" type questions.

=back

Use C<scalar> context or the following to select just the normal form
array reference:

  my $just_the_nf_thanks = ($atu->normal_form(...))[0];

The "packed from the right" method outlined in the www.mta.ca link
(L</"SEE ALSO">) is employed, so may return different normal forms than
the Allen Forte method. There is stub code for the Allen Forte method in
this module, though I lack enough information to verify if that code is
correct. The Forte Numbers on Wikipedia match that of the www.mta.ca
link method.

See also B<half_prime_form> and B<prime_form>.

=head2 B<pcs2bits> I<pitch_set>

Converts a I<pitch_set> into a B<scale_degrees>-bit number.

                 7   3  0
  [0,3,7] -> 000010001001 -> 137

These can be inspected via C<printf>, and the usual bit operations
applied as desired.

  my $mask = $atu->pcs2bits(0,3,7);
  sprintf '%012b', $mask;           # 000010001001

  if ( $mask == ( $atu->pcs2bits($other_pset) & $mask ) ) {
    # $other_pset has all the same bits on as $mask does
    ...
  }

=head2 B<pcs2forte> I<pitch_set>

Given a pitch set, returns the Forte Number of that set. The Forte
Numbers use uppercase C<Z>, for example C<6-Z44>. C<undef> will be
returned if no Forte Number exists for the pitch set.

=head2 B<pcs2intervals> I<pitch_set>

Given a pitch set of at least two elements, returns the list of
intervals between those pitch elements. This list is returned as an
array reference.

=head2 B<pcs2str> I<pitch_set>

Given a pitch set (or string with commas in it) returns the pitch set as
a string in C<[0,1,2]> form.

  $atu->pcs2str([0,3,7])   # "[0,3,7]"
  $atu->pcs2str(0,3,7)     # "[0,3,7]"
  $atu->pcs2str("0,3,7")   # "[0,3,7]"

=head2 B<pitch2intervalclass> I<pitch>

Returns the interval class a given pitch belongs to (0 is 0, 11 maps
down to 1, 10 down to 2, ... and 6 is 6 for the standard 12 tone
system). Used internally by the B<interval_class_content> method.

=head2 B<prime_form> I<pitch_set>

Returns the prime form of a given pitch set (via B<normal_form> and
various other operations on the passed pitch set) as an array reference.

See also B<half_prime_form> and B<normal_form>.

=head2 B<reflect_pitch> I<pitch>, I<min>, I<max>

Utility method. Constrains the supplied pitch to reside within the
supplied minimum and maximum limits, by "reflecting" the pitch back off
the limits. For example, given the min and max limits of 6 and 12:

  pitch  ... 10 11 12 13 14 15 16 17 18 19 20 21 ...
  result ... 10 11 12 11 10  9  8  7  6  7  8  9 ...

This may be of use in a L<Music::LilyPondUtil> C<*_pitch_hook> function
to keep the notes within a certain range (modulus math, by contrast,
produces a sawtooth pattern with occasional leaps).

=head2 B<retrograde> I<pitch_set>

Fancy term for the C<reverse> of a list. Returns reference to array of
said reversed list.

=head2 B<rotate> I<rotate_by>, I<pitch_set>

Rotates the pitch set by the integer supplied as the first argument. Returns an
array reference of the resulting pitch set. (B<circular_permute> performs all
the possible rotations for a pitch set.)

=head2 B<rotateto> I<what>, I<dir>, I<pitch_set>

Utility method. Rotates (via B<rotate>) a given array reference to the
desired element I<what> (using string comparisons). Returns an array
reference of the thus rotated set. Throws an exception if anything goes
wrong with the input or search.

I<what> is searched for from the first element and subsequent elements,
assuming a positive I<dir> value. Set a negative I<dir> to invert the
direction of the search.

=head2 B<scale_degrees> I<optional_integer>

Without arguments, returns the number of scale degrees (12 by default).
If passed a positive integer greater than two, sets the scale degrees to
that. Note that changing this will change the results from almost all
the methods this module offers, and has not (much) been tested.

=head2 B<set_complex> I<pitch_set>

Computes the set complex, or a 2D array with the pitch set as the column
headers, pitch set inversion as the row headers, and the combination of
those two for the intersection of the row and column headers. Returns
reference to the resulting array of arrays.

Ideally the first pitch of the input pitch set should be 0 (so the input
may need reduction to B<prime_form> first).

=head2 B<subsets> I<length>, I<pitch_set>

Returns the subsets of a given pitch set as an array of array refs.
I<length> should be C<-1> to select for pitch sets of one element less,
or a positive value of a magnitude less than the pitch set to return the
subsets of a specific magnitude.

  $atu->subsets(-1, [0,3,7])  # different ways to say same thing
  $atu->subsets( 2, [0,3,7])

The input set will be modulated to the B<scale_degrees> limit, and any
duplicate pitches excluded before the subsets are generated. The return
sets might be further reduced by the caller via B<half_prime_form> or
B<prime_form> or some other method to (sometimes) effect an even greater
reduction in the number of subsets. However, by default, no such
reduction is done by this method, beyond initial input set sanitization.

=head2 B<tcs> I<pitch_set>

Returns array reference consisting of the transposition common-tone
structure (TCS) for the given pitch set, that is, for each of the
possible transposition operations under the B<scale_degrees> in
question, how many common tones there are with the original set.

=head2 B<tcis> I<pitch_set>

Like B<tcs>, except uses B<transpose_invert> instead of just
B<transpose>.

=head2 B<transpose> I<transpose_by>, I<pitch_set>

Transposes the given pitch set by the given integer value in
I<transpose_by>. Returns the result as an array reference.

=head2 B<transpose_invert> I<transpose_by>, I<axis>, I<pitch_set>

Performs B<invert> on given pitch set (set I<axis> to C<0> if unsure),
then transposition as per B<transpose>. Returns the result as an array
reference.

=head2 B<variances> I<pitch_set1>, I<pitch_set2>

Given two pitch sets, in scalar context returns the shared notes of
those two pitch sets as an array reference. In list context, returns the
shared notes (intersection), difference, and union as array references.

=head2 B<zrelation> I<pitch_set1>, I<pitch_set2>

Given two pitch sets, returns true if the two sets share the same
B<interval_class_content>, false if not.

=head1 RHYTHM

Rhythmic analysis might begin with:

  Music::AtonalUtil->new(DEG_IN_SCALE => 16);

Assuming 16 beats in a measure, as per the Godfried Toussaint article (L</"SEE
ALSO">), the "clave Son" rhythm that in lilypond might run something like C<c8.
c16 r8 c8 r8 c8 c4> could be represented using the "onset-coordinate vector"
notation of C<(0,3,6,10,12)> and perhaps passed to such routines as
B<interval_class_content> for subsequent analysis. For example, a measure of
evenness (the sum of the interval arc-lengths) can be obtained via:

  use Music::AtonalUtil ();
  my $atu = Music::AtonalUtil->new( DEG_IN_SCALE => 16 );

  my $ics = ( $atu->interval_class_content( 0, 3, 6, 10, 12 ) )[1];
  my $sum = 0;
  for my $k ( keys %$ics ) {
    $sum += $k * $ics->{$k};
  }

See C<atonal-util> of L<App::MusicTools> for B<beats2set> and B<set2beats>, for
beat pattern to "pitch" set conversions.

=head1 CHANGES

Version 1.0 reordered and otherwise mucked around with calling
conventions (mostly to allow either an array reference or a list of
values for pitch sets), but not the return values. Except for
B<normal_form>, which obtained additional return values, so you can
figure out which of the input pitches map to what (a feature handy for
L<Music::NeoRiemannianTonnetz> related operations, or so I hope).

Otherwise I generally try not to break the interface. Except when I do.

=head1 BUGS

=head2 Reporting Bugs

If the bug is in the latest version, send a report to the author.
Patches that fix problems or add new features are welcome.

L<http://github.com/thrig/Music-AtonalUtil>

=head2 Known Issues

Poor naming conventions, vague and conflicting standards of music
theory, plus any mistakes in understanding of music theory or coding by
the author.

=head1 SEE ALSO

=over 4

=item *

"Basic Atonal Theory" by John Rahn.

  @book{rahn1980,
    title={Basic Atonal Theory},
    author={John Rahn},
    year=1980,
    publisher={Longman},
    ISBN="0-582-28117-2",
  }

=item *

"Computational geometric aspects of rhythm, melody, and voice-leading" by
Godfried Toussaint (and other rhythm articles by the same).

=item *

"The Geometry of Musical Rhythm" by Godfried T. Toussaint.

=item *

Musimathics, Vol. 1, p.311-317 by Gareth Loy.

=item *

L<http://www.mta.ca/faculty/arts-letters/music/pc-set_project/pc-set_new/>

=item *

"Review of Basic Atonal Theory", David H. Smyth. Perspectives of New
Music, Vol. 22, No. 1/2 (Autumn, 1983 - Summer, 1984). pp. 549-555.
L<http://www.jstor.org/stable/832965>

=item *

"Serial Composition" by Smith-Brindle Reginald.

=item *

"The Structure of Atonal Music" by Allen Forte.

  @book{forte1973,
    title={The Structure of Atonal Music},
    author={Allen Forte},
    year=1973,
    publisher={Yale University Press},
    ISBN="978-0-300-02120-2",
  }

=back

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2016 by Jeremy Mates

This module is free software; you can redistribute it and/or modify it
under the Artistic License (2.0).

=cut
