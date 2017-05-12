#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Plack::App::CLI' ) || print "Bail out!\n";
}

diag( "Testing Plack::App::CLI $Plack::App::CLI::VERSION, Perl $], $^X" );
