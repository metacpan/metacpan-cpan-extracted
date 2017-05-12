#===============================================================================
# vim: ts=8 et sw=4 sts=4
#
#         FILE:  71-amf-plus-marker.t
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Grishayev Anatoliy (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  04/08/2011 01:56:58 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More 'no_plan';                      # last test to print
use ExtUtils::testlib;
use Storable::AMF;
my $index;

$index = 0;
for my $pobj ( 1, "abc", [], {} ){

	my $buf = chr( 17 ) . Storable::AMF3::freeze( $pobj );
	() = Storable::AMF0::thaw( $buf );
	ok( !$@ , "amfplus - thaw ( $index )|".($@||''));

	() = Storable::AMF0::deparse_amf( $buf );
	ok( !$@ , "amfplus - deparse_amf ( $index )|".($@||''));

}
continue {
	++$index;
}





