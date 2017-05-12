#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ModPerl::ParamBuilder' );
}

diag( "Testing ModPerl::ParamBuilder $ModPerl::ParamBuilder::VERSION, Perl $], $^X" );
