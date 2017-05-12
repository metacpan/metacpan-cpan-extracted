#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'SQL::Yapp' ) || print "Bail out!\n";
}

diag( "Testing SQL::Yapp $SQL::Yapp::VERSION, Perl $], $^X" );
