#!perl -T

use strict;
use Test::More tests => 1;

BEGIN {
	use_ok( 'Module::Build::PM_Filter' );
}

diag( "Testing Module::Build::PM_Filter $Module::Build::PM_Filter::VERSION, Perl $], $^X" );
