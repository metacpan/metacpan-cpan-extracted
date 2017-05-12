#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Template::ExpandHash' ) || print "Bail out!\n";
}

diag( "Testing Template::ExpandHash $Template::ExpandHash::VERSION, Perl $], $^X" );
