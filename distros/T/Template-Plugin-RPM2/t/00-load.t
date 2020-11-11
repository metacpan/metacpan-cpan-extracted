use strict;
use warnings;

use Test::More;

BEGIN {
	use_ok( 'Template::Plugin::RPM2' );
}

diag( "Testing Template::Plugin::RPM2 $Template::Plugin::RPM2::VERSION, Perl $], $^X" );

done_testing();
