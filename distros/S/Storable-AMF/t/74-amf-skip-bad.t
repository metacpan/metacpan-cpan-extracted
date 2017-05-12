#
# vim: ts=8 et sw=4 sts=4
#===============================================================================
#
#         FILE:  74-amf-skip-bad.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  10/13/2011 10:30:12 PM
#     REVISION:  ---
#===============================================================================
use strict;
use Test::More no_plan => ();                      # last test to print
use ExtUtils::testlib;
use Storable::AMF qw(freeze0 freeze3 thaw0 thaw3);

sub t0 { thaw0(do { my $s= freeze0( $_[0], 512 ); print STDERR $@ if $@; $s});}
sub t3 { thaw3 freeze3( $_[0], 512 );}
is( t0( sub {} ), undef, "sub (0)"); 
is( t3( sub {} ), undef, "sub (3)"); 


is( t0( *STDERR ), undef, "glob (0)"); 
is( t3( *STDERR ), undef, "glob (3)"); 

is( t0( \*STDERR ), undef, "ref-glob (0)"); 
is( t3( \*STDERR ), undef, "ref-glob (3)"); 



