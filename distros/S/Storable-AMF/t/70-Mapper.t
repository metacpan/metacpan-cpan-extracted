#
# vim: ts=8 et sw=4 sts=4
#===============================================================================
#
#         FILE:  79-mapper.t
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Grishayev Anatoliy (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  01/24/2011 02:51:59 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use Test::More 'no_plan';                      # last test to print
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw parse_option);
use Storable::AMF::Mapper;

can_ok( 'Storable::AMF::Mapper', 'new' );
is( Storable::AMF::Mapper->new( to_amf=> 0), parse_option( 'prefer_number' ));
is( Storable::AMF::Mapper->new( to_amf=> 1), 128 + parse_option( 'prefer_number' ));







