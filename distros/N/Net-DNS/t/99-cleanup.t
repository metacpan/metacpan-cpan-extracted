#!/usr/bin/perl
# $Id: 99-cleanup.t 1815 2020-10-14 21:55:18Z willem $ -*-perl-*-
#

use strict;
use warnings;

use Test::More;
plan tests => 1;

diag("Cleaning");

unlink("t/online.disabled") if ( -e "t/online.disabled" );
unlink("t/IPv6.disabled")   if ( -e "t/IPv6.disabled" );

ok( 1, "Dummy" );


