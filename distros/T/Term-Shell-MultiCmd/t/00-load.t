#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Term::Shell::MultiCmd' ) || print "Bail out!
";
}

diag( "Testing Term::Shell::MultiCmd $Term::Shell::MultiCmd::VERSION, Perl $], $^X" );
