#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::Mongodb' ) || print "Bail out!
";
}

diag( "Testing Mojolicious::Plugin::Mongodb $Mojolicious::Plugin::Mongodb::VERSION, Perl $], $^X" );
