use 5.008003;
use strict;
use warnings;
use Test::More tests => 1;


BEGIN {
    use_ok( 'Term::TablePrint' ) || print "Bail out!\n";
}

diag( "Testing Term::TablePrint $Term::TablePrint::VERSION, Perl $], $^X" );
