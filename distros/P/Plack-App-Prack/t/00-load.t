#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Plack::App::Prack' ) || print "Bail out!
";
}

diag( "Testing Plack::App::Prack $Plack::App::Prack::VERSION, Perl $], $^X" );
