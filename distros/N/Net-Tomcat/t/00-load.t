#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Tomcat' ) || print "Bail out!\n";
}

diag( "Testing Net::Tomcat $Net::Tomcat::VERSION, Perl $], $^X" );
