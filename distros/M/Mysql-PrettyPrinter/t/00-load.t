#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mysql::PrettyPrinter' ) || print "Bail out!
";
}

diag( "Testing Mysql::PrettyPrinter $Mysql::PrettyPrinter::VERSION, Perl $], $^X" );
