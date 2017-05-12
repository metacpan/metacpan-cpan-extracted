#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Rapid7::NeXpose::API' ) || print "Bail out!
";
}

diag( "Testing Rapid7::NeXpose::API $Rapid7::NeXpose::API::VERSION, Perl $], $^X" );
