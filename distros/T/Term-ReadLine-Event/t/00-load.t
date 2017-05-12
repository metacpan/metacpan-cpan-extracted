#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Term::ReadLine::Event' ) || print "Bail out!\n";
}

diag( "Testing Term::ReadLine::Event $Term::ReadLine::Event::VERSION, Perl $], $^X" );
