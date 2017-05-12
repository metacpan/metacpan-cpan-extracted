#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Module::Version' ) || print "Bail out!
";
}

diag( "Testing Module::Version $Module::Version::VERSION, Perl $], $^X" );
