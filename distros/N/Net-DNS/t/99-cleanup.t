#!/usr/bin/perl
# $Id: 99-cleanup.t 1880 2022-10-04 13:42:34Z willem $ -*-perl-*-
#

use strict;
use warnings;

use Test::More;
plan tests => 1;

diag("Cleaning");

unlink("t/online.disabled") if ( -e "t/online.disabled" );
unlink("t/IPv6.disabled")   if ( -e "t/IPv6.disabled" );

ok( 1, "Dummy" );


exit;
