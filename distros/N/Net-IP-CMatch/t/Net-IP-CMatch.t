#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw($Bin);

use Test::More tests => 4;

################# test 1 (should succeed) #######################
BEGIN { use_ok('Net::IP::CMatch') };

my $match;

################# test 2 (should fail) #######################

$match = match_ip( qw( 207.175.219.202 10.0.0.0/8 99.99.99 ) );
ok( ! $match, "check non-match" );

################# test 3 (should succeed) #######################

$match = match_ip( qw( 207.175.219.202 10.0.0.0/8
                       192.168.0.0/16 207.175.219.200/29 ) );
ok( $match, "check match" );

################# test 4 (should succeed) #######################

my @ips = split / /, '10.0.0.0/8 192.168.0.0/16 207.175.219.200/29';
$match = match_ip( "'207.175.219.202xxx'", @ips );
ok( $match, "check another match" );
