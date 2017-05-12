#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use File::Spec::Functions ':ALL';
use Test::More tests => 11;
use Oz;





#####################################################################
# Compiler Tests

SCOPE: {
	my $filename = catfile( qw{ t data hello_world.oz } );
	ok( -f $filename, 'Found hello_world.oz' );
	my $script = Oz::Script->new( $filename );
	isa_ok( $script, 'Oz::Script' );
	my $compiler = Oz::Compiler->new(
		script => $script,
	);
	isa_ok( $compiler, 'Oz::Compiler' );

	# Build the ozf file
	ok( $compiler->make_ozf, '->make_ozf ok' );
	ok( -f $compiler->main_ozf, '->main_ozf exists' );
	SKIP: {
		skip( "Skipping emulator-related failures", 4 );
		ok( $compiler->make_ozi, '->make_ozi ok' );
		ok( $compiler->make_ozm, '->make_ozm ok' );
		ok( -f $compiler->main_ozi, '->main_ozi exists' );
		ok( -f $compiler->main_ozm, '->main_ozm exists' );
	}

	# Execute the program
	my $rv = $compiler->run;
	is( $rv, "Hello World!\n", 'Compiler ->run ok' );

	# Now run the script directly
	my $out = $script->run;
	is( $rv, "Hello World!\n", 'Script ->run ok' );
}
