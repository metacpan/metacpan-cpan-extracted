#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::Script;

ok( $] >= 5.006, 'Perl version is new enough' );

use_ok( 'Perl::Shell' );

script_compiles( 'blib/script/perlcmd' );
