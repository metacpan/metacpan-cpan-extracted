#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 13;
use File::Spec::Functions ':ALL';
use SQL::Script;
use t::lib::MockDBI;

my $simple = catfile( 't', 'data', 'simple.sql' );
ok( -f $simple, "$simple exists" );





#####################################################################
# Create and work with simple scripts

SCOPE: {
	# Create the object
	my $script = SQL::Script->new;
	isa_ok( $script, 'SQL::Script' );
	is( $script->split_by, ";\n", '->split_by default ok' );
	is_deeply( [ $script->statements ], [], '->statements returns empty list by default' );
	is( scalar($script->statements), 0, 'scalar ->statements returns 0' );

	# Read a script
	ok( $script->read($simple), '->read ok' );
	is_deeply( [ $script->statements ], [
		"create table foo ( id integer not null primary key, foo varchar(32) )",
		"insert foo values ( 1, 'Hello World\\n' )",
	], '->statements returns two statements' );
	is( scalar($script->statements), 2, '->statements ok' );

	# Execute it
	my $dbh = t::lib::MockDBI->new;
	ok( $script->run($dbh), '->run returns true' );
	is_deeply( [ @t::lib::MockDBI::SQL ], [
		[ "create table foo ( id integer not null primary key, foo varchar(32) )" ],
		[ "insert foo values ( 1, 'Hello World\\n' )" ],
	], '->run executed two statements' );
}





######################################################################
# Prepopulated

SCOPE: {
	my $script = SQL::Script->new(
		statements => [
			'Hello', 'World!'
		],
	);
	isa_ok( $script, 'SQL::Script' );
	is( scalar($script->statements), 2, '->statements ok' );
	is_deeply( [ $script->statements ], [ 'Hello', 'World!' ], '->statements ok' );
}
