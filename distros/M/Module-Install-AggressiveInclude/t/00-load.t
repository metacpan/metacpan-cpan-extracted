#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Module::Install::AggressiveInclude' ) || print "Bail out!
";
}

diag( "Testing Module::Install::AggressiveInclude $Module::Install::AggressiveInclude::VERSION, Perl $], $^X" );
