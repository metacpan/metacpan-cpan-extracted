#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Perlbal::Plugin::ForwardedFor' ) || print "Bail out!\n";
}

diag( "Testing Perlbal::Plugin::ForwardedFor $Perlbal::Plugin::ForwardedFor::VERSION, Perl $], $^X" );
