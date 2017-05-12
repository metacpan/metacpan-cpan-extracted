#!/usr/bin/perl -w
# $Id: 01info.t,v 1.2 2002/04/01 11:17:14 piers Exp $
use strict;
use lib qw(./lib ../lib);
use Test;
use Module::Dependency::Info;
BEGIN { plan tests => 24; }

BEGIN {
	if ( -d 't') {
		chdir( 't' );
	}
	ok(1);
}

unless ( -f 'dbdump.dat' ) {
	for (2..24) { ok(1); }
	warn( "You need to run all the tests in order! dbdump.dat not found, so skipping tests!" );
	exit;
}

Module::Dependency::Info::setIndex( 'wibble' );
eval {
	ok( ! Module::Dependency::Info::retrieveIndex );
};
Module::Dependency::Info::setIndex( 'dbdump.dat' );
ok( Module::Dependency::Info::retrieveIndex );

ok( @{ Module::Dependency::Info::allItems() } == 12 );
ok( Module::Dependency::Info::allScripts()->[1] eq 'x.pl' );

my $i = Module::Dependency::Info::getItem('d');
ok( $i->{'filename'} eq '/home/piers/src/dependency/t/u/d.pm' );
ok( $i->{'package'} eq 'd' );
ok( $i->{'depended_upon_by'}->[2] eq 'c' );
ok( $i->{'depends_on'}->[3] eq 'h' );

ok( Module::Dependency::Info::getFilename('f') eq '/home/piers/src/dependency/t/u/f.pm');
ok( Module::Dependency::Info::getChildren('f')->[0] eq 'strict');
ok( Module::Dependency::Info::getParents('f')->[0] eq 'd');

ok( Module::Dependency::Info::dropIndex() );
ok( ! defined( $Module::Dependency::Info::UNIFIED ) );

# implicit load - only need one test
ok( Module::Dependency::Info::getParents('f')->[0] eq 'd');

# test relationship()
#*Module::Dependency::Info::TRACE = sub { my $msg = shift; print ">>>$msg<<<\n"; };
ok( ! defined( Module::Dependency::Info::relationship('floop', 'b') ) );
ok( Module::Dependency::Info::relationship('a', 'j') eq 'NONE' );
ok( Module::Dependency::Info::relationship('j', 'a') eq 'NONE' );
ok( Module::Dependency::Info::relationship('b', 'h') eq 'CHILD' );
ok( Module::Dependency::Info::relationship('h', 'b') eq 'PARENT' );
ok( Module::Dependency::Info::relationship('b', 'e') eq 'CIRCULAR' );

# bad data
ok( ! defined( Module::Dependency::Info::getItem('floop') ) );
ok( ! defined( Module::Dependency::Info::getFilename('floop') ) );
ok( ! defined( Module::Dependency::Info::getChildren('floop') ) );
ok( ! defined( Module::Dependency::Info::getParents('floop') ) );

# right, that's tested the Info programmatic interface