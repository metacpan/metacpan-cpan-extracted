#!perl 

use Test::More tests => 1;

BEGIN {
    use_ok( 'MySQL::Util' ) || print "Bail out!
";
}

diag( "Testing MySQL::Util $MySQL::Util::VERSION, Perl $], $^X" );
