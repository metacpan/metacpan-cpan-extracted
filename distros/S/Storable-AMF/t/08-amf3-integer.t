#===============================================================================
#
#         FILE:  08-amf3-integer.t
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Grishayev Anatoliy (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  04/29/2011 02:08:43 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use Test::More 'no_plan';                      # last test to print
# vim: ts=8 et sw=4 sts=4
use ExtUtils::testlib;
use Storable::AMF qw(freeze3 thaw3);
sub MARKER_INT(){ 4; }
sub MARKER_DOUBLE(){ 5; }

#print int( 1<<30), "\n",0x3fffffff, "\n";

integer_range_error( int( 2**30 ) );
integer_range_error( int( 2**29 ) );
integer_range_error( int( -2**29 ) );
integer_range_error( int( -2**28-1 ) );

ok_integer(  int(2**28) -1 , "bf ff ff ff" );
ok_integer(  int(2**28) -2 , "bf ff ff fe" );
ok_integer(  - int(2**28),         "c0 80 80 00" );
ok_integer(  - int(2**28) + 1,     "c0 80 80 01" );

ok_integer(  int(0) , "00" );
ok_integer(  int(1) , "01" );
ok_integer(  int(127) , "7f" );
ok_integer(  int(128) , "8100" );
ok_integer(  int(129) , "8101" );


ok_integer(  int(2**14-1) , "ff7f" );
ok_integer(  int(2**14+0) , "818000" );
ok_integer(  int(2**14+1) , "818001" );


ok_integer(  int(2**14-1) , "ff7f" );
ok_integer(  int(2**14+0) , "818000" );
ok_integer(  int(2**14+1) , "818001" );

ok_integer(  int(2**14+127) ,"81807f" );
ok_integer(  int(2**14+128) , "818100" );
ok_integer(  int(2**14+129) , "818101" );


ok_integer(  int(2**14+16383) , "81ff7f" );
ok_integer(  int(2**14+16384) , "828000" );
ok_integer(  int(2**14+16385) , "828001" );
##########################################

ok_integer(  int(2**21-1)     , "ff ff 7f" );
ok_integer(  int(2**21+0)     , "80 c0 80 00" );
ok_integer(  int(2**21+1)     , "80 c0 80 01" );
ok_integer(  int(2**21+128)   , "80 c0 80 80" );
ok_integer(  int(2**21+255)   , "80 c0 80 ff" );
ok_integer(  int(2**21+256)   , "80 c0 81 00" );

ok_integer(  int(2**21+32767) , "80 c0 ff ff" );

ok_integer(  int(2**21+32768) , "80 c1 80 00" );
ok_integer(  int(2**21+32769) , "80 c1 80 01" );

ok_integer(  int(2**22-1) , "80 ff ff ff" );
ok_integer(  int(2**22+0) , "81 80 80 00" );
ok_integer(  int(2**22+1) , "81 80 80 01" );

ok_integer(  int(2**22 + 2**22 - 1) , "81 ff ff ff" );
ok_integer(  int(2**22 + 2**22 + 0) , "82 80 80 00" );
ok_integer(  int(2**22 + 2**22 + 1) , "82 80 80 01" );
ok_integer( int( 3986389 ),           "80  f9  d3  d5");

# and etc 

ok_integer(  int(-1),   "ff ff ff ff" );
ok_integer(  int(-2),   "ff ff ff fe" );
ok_integer(  int(-128), "ff ff ff 80" );
ok_integer(  int(-255), "ff ff ff 01" );
ok_integer(  int(-256), "ff ff ff 00" );

ok_integer(  int(-32768+1), "ff ff 80 01" );
ok_integer(  int(-32768+0), "ff ff 80 00" );
ok_integer(  int(-32768-1), "ff fe ff ff" );
ok_integer(  int(-32768-128), "ff fe ff 80" );
ok_integer(  int(-32768-256), "ff fe ff 00" );

# data represented 
#

is_type( int(1), MARKER_INT, "1 is int");
is_type( 1.0, MARKER_DOUBLE, "1 is double");

is_type( int( 2**28-1 ), MARKER_INT, "2**28 -1 is int" );
is_type( int( 2**28 ), MARKER_DOUBLE, "2**28 is double" );

is_type( int( -2**28 ), MARKER_INT, "-2**28  is int" );
is_type( int( -2**28 -1), MARKER_DOUBLE, "-2**28 -1 is double" );
exit;

sub present{
	my ($int) = @_;
	print "$int = ", thaw3( freeze3( $_[0] )), "\n";
}
sub is_double{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
}
sub is_type{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
	my $s = freeze3( $_[0] );
	if ( defined $s && ord( $s ) == $_[1] ){
		ok(1, $_[2] );
	}
	else {
		print STDERR Dumper( defined $s, $@ );
		ok(0, $_[2]);
	}
}

sub integer_range_error{
    use Carp;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    local $@;
    my $s =  Storable::AMF3::_test_freeze_integer( $_[0]) ;
    ok( !defined($s) && $@, " '$_[0]'");
}

sub ok_integer{
    use Carp;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    local $@;
	my $int_value = $_[0];
	my $freezed_int = $_[1]; $freezed_int=~s/\s//g;

    my $s = Storable::AMF3::_test_freeze_integer( $_[0]);
	if ( defined $s && !$@ ){
		is( unpack( "H*", $s), $freezed_int, "fr integer( $int_value, $_[1] )");
	}
	else {
		ok( '', "fr ok_integer($int_value)");		
	}

	my $raw_int = pack "H*",, $freezed_int;
	my $int = Storable::AMF3::_test_thaw_integer( $raw_int );
	if ( defined $int && ! $@ ){
		is( $int, $int_value, "th ok_integer( $int_value, $_[1] )");
	}
	else {
		ok( '', "th ok_integer($int_value)");
	}

}




