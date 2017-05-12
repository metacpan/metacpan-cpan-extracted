#!perl

use Test::More tests => 3;

BEGIN {
	use_ok('OWL::Simple::Parser') || print "Bail out!";
	use_ok('OWL::Simple::Class')  || print "Bail out!";
	use_ok('OWL::Simple::OBOWriter')  || print "Bail out!";
}

diag("Testing OWL::Simple::Parser $OWL::Simple::Parser::VERSION, Perl $], $^X");
