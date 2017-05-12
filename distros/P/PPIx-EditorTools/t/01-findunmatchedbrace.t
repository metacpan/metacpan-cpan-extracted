#!/usr/bin/perl

use strict;

BEGIN {
	$^W = 1;
}

use Test::More;
use Test::Differences;
use PPI;

BEGIN {
	if ( $PPI::VERSION =~ /_/ ) {
		plan skip_all => "Need released version of PPI. You have $PPI::VERSION";
		exit 0;
	}
}

plan tests => 6;

use PPIx::EditorTools::FindUnmatchedBrace;

my $brace =
	PPIx::EditorTools::FindUnmatchedBrace->new->find(
	code => "package TestPackage;\nuse strict;\nuse warnings;\nsub x { 1;\n" );

isa_ok( $brace,          'PPIx::EditorTools::ReturnObject' );
isa_ok( $brace->element, 'PPI::Structure::Block' );
location_is( $brace->element, [ 4, 7, 7 ], 'unclosed sub' );

$brace = PPIx::EditorTools::FindUnmatchedBrace->new->find( code => "package TestPackage;\nfor my \$x (1..2) { 1;\n" );

isa_ok( $brace,          'PPIx::EditorTools::ReturnObject' );
isa_ok( $brace->element, 'PPI::Structure::Block' );
location_is( $brace->element, [ 2, 18, 18 ], 'unclosed for block' );

sub location_is {
	my ( $element, $location, $desc ) = @_;

	my $elem_loc = $element->location;
	$elem_loc = [ @$elem_loc[ 0 .. 2 ] ] if @$elem_loc > 3;
	is_deeply( $elem_loc, $location, $desc );
}

