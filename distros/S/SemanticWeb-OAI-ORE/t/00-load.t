#!perl -T

use Test::More tests => 7;

BEGIN {
	use_ok( 'SemanticWeb::OAI::ORE' );
	use_ok( 'SemanticWeb::OAI::ORE::ReM' );
	use_ok( 'SemanticWeb::OAI::ORE::Model' );
	use_ok( 'SemanticWeb::OAI::ORE::Constant' );
	use_ok( 'SemanticWeb::OAI::ORE::RDFXML' );
	use_ok( 'SemanticWeb::OAI::ORE::N3' );
	use_ok( 'SemanticWeb::OAI::ORE::TriX' );
	#use_ok( 'SemanticWeb::OAI::ORE::Atom' );
	#use_ok( 'SemanticWeb::OAI::ORE::AtomWriter' );
}

diag( "Testing SemanticWeb::OAI::ORE $SemanticWeb::OAI::ORE::VERSION, Perl $], $^X" );
