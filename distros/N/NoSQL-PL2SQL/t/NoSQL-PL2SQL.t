# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl NoSQL-PL2SQL.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6 ;

BEGIN { 
	use_ok('Scalar::Util') ;
	use_ok('XML::Parser::Nodes') ;
	use_ok('NoSQL::PL2SQL::Node') ;
	use_ok('NoSQL::PL2SQL::Perldata') ;
	use_ok('NoSQL::PL2SQL::Object') ;
	use_ok('NoSQL::PL2SQL') ;
	};

#########################

1
