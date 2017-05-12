#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Perlbal::Plugin::ExpandSSL' ) || print "Bail out!\n";
}

diag( "Testing Perlbal::Plugin::ExpandSSL $Perlbal::Plugin::ExpandSSL::VERSION, Perl $], $^X" );
