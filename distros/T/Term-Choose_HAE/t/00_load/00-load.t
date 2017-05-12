use 5.010001;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Term::Choose_HAE' ) || print "Bail out!\n";
}

diag( "Testing Term::Choose_HAE $Term::Choose_HAE::VERSION, Perl $], $^X" );
