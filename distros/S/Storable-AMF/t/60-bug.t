#
# vim: ts=8 et sw=4 sts=4
#===============================================================================
#
#         FILE:  60-bug.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Grishaev Anatoliy (ga), zua.zuz@toh.ru
#      COMPANY:  Adeptus, Russia
#      VERSION:  1.0
#      CREATED:  10/28/09 12:41:11
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use Test::More 'no_plan';                      # last test to print
use Scalar::Util qw(reftype blessed weaken);
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw);
my $s = freeze( '' );
use Data::Dumper;
$Data::Dumper::Useqq = 1;
is( thaw($s), '', 'freeze thaw ok');



