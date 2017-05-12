#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::OpenSRS::Email_APP' ) || print "Bail out!
";
}

diag( "Testing Net::OpenSRS::Email_APP $Net::OpenSRS::Email_APP::VERSION, Perl $], $^X" );
