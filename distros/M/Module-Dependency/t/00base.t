#!/usr/bin/perl -w
# $Id: 00base.t,v 1.2 2002/04/01 11:17:14 piers Exp $
use strict;
use Test;
BEGIN { plan tests => 10; }

use lib qw(./lib ../lib);

# check our modules
use Module::Dependency::Info;
BEGIN { ok( $Module::Dependency::Info::VERSION ) };
use Module::Dependency::Indexer;
BEGIN { ok( $Module::Dependency::Indexer::VERSION ) };
use Module::Dependency::Grapher;
BEGIN { ok( $Module::Dependency::Grapher::VERSION ) };

# check things we _know_ we'll need
use Storable;
BEGIN { ok( 1 ) };
use File::Find;
BEGIN { ok( 1 ) };
use File::Spec;
BEGIN { ok( 1 ) };

BEGIN {
	if ( -d 't') {
		chdir( 't' );
		ok(1);
	} else {
		ok(1);
	}
	require 'dbdump.dd';
	ok( ! $@ );
}

if ( $DB->{'scripts'}->[0] eq 'y.pl' ) {
	ok(1);
} else {
	ok(0);
	die("Could not load the demo database! Most tests will not work");
}

ok( Storable::nstore( $DB, 'dbdump.dat' ) );

# ok, looks like we have an OK environment to do tests in, so let's go...