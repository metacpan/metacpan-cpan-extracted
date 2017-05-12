#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::SugarCRM' ) || print "Bail out!
";
}

diag( "Testing Net::SugarCRM $Net::SugarCRM::VERSION, Perl $], $^X" );
