#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Net::IPAM::Block') || print "Bail out!\n"; }

my $b = Net::IPAM::Block->new('::/0');
ok( $b eq '::/0', 'string overload' );
ok( !!$b,         'bool overload' );

done_testing();
