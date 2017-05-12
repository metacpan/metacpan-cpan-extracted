#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'QMake::Project' ) || print "Bail out!\n";
}

diag( "Testing QMake::Project $QMake::Project::VERSION, Perl $], $^X" );
