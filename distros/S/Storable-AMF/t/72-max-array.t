#
# vim: ts=8 et sw=4 sts=4
#===============================================================================
#
#         FILE:  72-max-array.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  04/10/2011 09:07:01 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0;

use Test::More 'no_plan';                      # last test to print

my $z = Storable::AMF0::freeze( [1,2,4] );
substr $z, 2, 1, "0";
my ($obj) = Storable::AMF0::thaw( $z );
ok( $@=~m/ARRAY_TOO/, "Array too big" );



