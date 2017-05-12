#!/usr/bin/perl
# vim: ft=perl ts=4 shiftwidth=4 softtabstop=4 expandtab
# space2tab: ok
#===============================================================================
#
#         FILE:  74-devel-api.t
#
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Anatoliy Grishaev (), grian@cpan.org
#      CREATED:  02/19/2015 08:34:10 PM
#  DESCRIPTION:  ---
#
#===============================================================================
use strict;
use warnings;
use Test::More no_plan => ();                      # last test to print
use ExtUtils::testlib;
use Storable::AMF qw(freeze0 freeze3 thaw0_sv);
use Storable::AMF3;

my $s;
$s = freeze0( { a=> 1, b=>2, c=>3} );
$s = freeze0( { 0 => 1 , asdf=> 'asdf' });

my $storage = Storable::AMF0::amf_tmp_storage();
my $hash = {};

for (0..4)
{
    thaw0_sv( $s =>  $hash , 0);
}
ok(1, "finished");





