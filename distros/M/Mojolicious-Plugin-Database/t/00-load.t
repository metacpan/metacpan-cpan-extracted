#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::Database' ) || print "Bail out!
";
}

diag( "Testing Mojolicious::Plugin::Database $Mojolicious::Plugin::Database::VERSION, Perl $], $^X" );
