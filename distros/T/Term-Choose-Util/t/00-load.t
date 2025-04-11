use 5.10.1;
use strict;
use warnings;
use Test::More tests => 1;


BEGIN {
    use_ok( 'Term::Choose::Util' ) || print "Bail out!\n";
}

diag( "Testing Term::Choose::Util $Term::Choose::Util::VERSION, Perl $], $^X" );
