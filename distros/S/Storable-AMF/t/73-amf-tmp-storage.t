#
# vim: ts=8 et sw=4 sts=4
#===============================================================================
#
#         FILE:  73-amf-tmp-storage.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  06/03/2011 11:45:31 AM
#     REVISION:  ---
#===============================================================================
use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF qw(freeze3 thaw3 freeze0 thaw0 deparse_amf0 deparse_amf3 );
use Test::More no_plan => ();                      # last test to print

my $x = [ 1 , 2, 4];
my $y = [ 'yes' ];
my $test1  = [$y, $x, $y, $x];
my $test2  = [$x, $y, $x, $y];
my $ff_obj0_0= freeze0( $test1 );
my $ff_obj1_0= freeze0( $test2 );


my $ff_obj0_3= freeze3( $test1 );
my $ff_obj1_3= freeze3( $test2 );

my $storage = Storable::AMF0::amf_tmp_storage();



is_deeply( thaw3( $ff_obj0_3, $storage ), $test1);
is_deeply( thaw3( $ff_obj1_3, $storage ), $test2);

is_deeply( thaw0( $ff_obj0_0, $storage ), $test1);
is_deeply( thaw0( $ff_obj1_0, $storage ), $test2);

is_deeply( scalar deparse_amf3( $ff_obj0_3, $storage ), $test1);
is_deeply( scalar deparse_amf3( $ff_obj1_3, $storage ), $test2);

is_deeply( scalar deparse_amf0( $ff_obj0_0, $storage ), $test1);
is_deeply( scalar deparse_amf0( $ff_obj1_0, $storage ), $test2);
