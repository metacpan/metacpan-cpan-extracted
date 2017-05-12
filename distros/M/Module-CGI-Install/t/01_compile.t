#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::Script;

# Is the perl version new enough
ok( $] >= 5.005, 'Perl version is new enough' );

# Load the module
use_ok( 'Module::CGI::Install' );

# Compile-test the script
script_compiles_ok( 'script/cgi_install' );
