use 5.008003;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Term::Form' ) or print "Bail out!\n";
}

diag( "Testing Term::Form $Term::Form::VERSION, Perl $], $^X" );
