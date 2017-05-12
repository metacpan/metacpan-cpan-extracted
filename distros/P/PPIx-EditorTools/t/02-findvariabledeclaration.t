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

use PPIx::EditorTools::FindVariableDeclaration;

my $code = <<'END_OF_CODE';
package TestPackage;
use strict;
use warnings;
my $x=1;
$x++;
END_OF_CODE

my $declaration;

# Test finding variable declaration when on the variable
$declaration = PPIx::EditorTools::FindVariableDeclaration->new->find(
	code   => $code,
	line   => 5,
	column => 2,
);
isa_ok( $declaration,          'PPIx::EditorTools::ReturnObject' );
isa_ok( $declaration->element, 'PPI::Statement::Variable' );
location_is( $declaration->element, [ 4, 1, 1 ], 'simple scalar' );

# Test finding variable declaration when on declaration itself
$declaration = PPIx::EditorTools::FindVariableDeclaration->new->find(
	code   => $code,
	line   => 4,
	column => 4,
);
isa_ok( $declaration,          'PPIx::EditorTools::ReturnObject' );
isa_ok( $declaration->element, 'PPI::Statement::Variable' );
location_is( $declaration->element, [ 4, 1, 1 ], 'simple scalar' );

# Helper function
sub location_is {
	my ( $element, $location, $desc ) = @_;

	my $elem_loc = $element->location;
	$elem_loc = [ @$elem_loc[ 0 .. 2 ] ] if @$elem_loc > 3;
	is_deeply( $elem_loc, $location, $desc );
}
