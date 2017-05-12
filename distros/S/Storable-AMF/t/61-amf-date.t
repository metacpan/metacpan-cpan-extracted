#
# vim: ts=8 et sw=4 sts=4
#===============================================================================
#
#         FILE:  61-amf0-date.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  10/21/2010 03:15:55 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use Test::More qw(no_plan);                      # last test to print
use ExtUtils::testlib;
use Scalar::Util qw(blessed);
use Storable::AMF0 qw(new_amfdate perl_date parse_option);
use Storable::AMF3 ();
use constant OLD_DATE_OPT => parse_option( 'millisecond_date' );

ok( new_amfdate(0), "new_amfdate defined");
ok( blessed new_amfdate(0), "new_amfdate blessed");
is( length Storable::AMF0::freeze( new_amfdate(0) ), 11, "length AMF0 date is 11");
is( length Storable::AMF3::freeze( new_amfdate(0) ), 10, "length AMF0 date is 10");
is( unpack( "H*", Storable::AMF0::freeze(new_amfdate(0))), '0b00000000000000000000', 'freeze AMF0 date(0)',);
is( unpack( "H*", Storable::AMF3::freeze(new_amfdate(0))), '08010000000000000000', 'freeze AMF3 date(0)',);

is( Storable::AMF0::thaw( Storable::AMF0::freeze( new_amfdate(1)), OLD_DATE_OPT), 1000, "Date parse with option AMF0");
is( Storable::AMF3::thaw( Storable::AMF3::freeze( new_amfdate(1)), OLD_DATE_OPT), 1000, "Date parse with option AMF3");

is( Storable::AMF0::thaw( Storable::AMF0::freeze( new_amfdate(1))), 1, "Date parse perlish AMF0");
is( Storable::AMF3::thaw( Storable::AMF3::freeze( new_amfdate(1))), 1, "Date parse perlish AMF3");

my $timestamp = time();
for (0, 1, 100, 100, $timestamp) {
	my $time = gmtime( $_ ) . " GMT";
	is( perl_date( new_amfdate($_)), $_, "perl_date(new_amfdate(.)) for $time");
}


# AMF0
for (0, 1, 100, 100, $timestamp) {
	my $time = gmtime( $_ ) . " GMT";
	my $s = Storable::AMF0::thaw( Storable::AMF0::freeze( new_amfdate( $_ )));
	is( perl_date( $s ), $_, "AMF0 date invariant  for $time");
}

# AMF3
for (0, 1, 100, 100, $timestamp) {
	my $time = gmtime( $_ ) . " GMT";
	my $s = Storable::AMF3::thaw( Storable::AMF3::freeze( new_amfdate( $_ )));
	is( perl_date( $s ), $_, "AMF3 date invariant  for $time");
}
