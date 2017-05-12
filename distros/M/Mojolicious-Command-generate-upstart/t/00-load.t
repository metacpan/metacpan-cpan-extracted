#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Command::generate::upstart' ) || print "Bail out!
";
}

diag( "Testing Mojolicious::Command::generate::upstart $Mojolicious::Command::generate::upstart::VERSION, Perl $], $^X" );
