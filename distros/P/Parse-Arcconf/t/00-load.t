#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Parse::Arcconf' ) || print "Bail out!
";
}

diag( "Testing Parse::Arcconf $Parse::Arcconf::VERSION, Perl $], $^X" );
