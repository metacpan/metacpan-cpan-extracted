#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Table::Simple' ) || print "Bail out!
";
}

diag( "Testing Table::Simple $Table::Simple::VERSION, Perl $], $^X" );
