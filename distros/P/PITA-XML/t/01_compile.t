#!/usr/bin/perl

# Compile-testing for PITA::XML

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 24;

ok( $] > 5.006, 'Perl version is 5.004 or newer' );

use_ok( 'PITA::XML' );

foreach ( qw{Storable File Report Install Request Platform Guest Command Test SAXParser SAXDriver} ) {
	my $c = "PITA::XML::$_";
	ok( $c->VERSION, "$c is loaded" );
	is( $PITA::XML::VERSION, $c->VERSION,
		"$c \$VERSION matches main \$VERSION" );
}
