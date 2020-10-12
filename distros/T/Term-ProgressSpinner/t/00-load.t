#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Term::ProgressSpinner' ) || print "Bail out!\n";
}

diag( "Testing Term::ProgressSpinner $Term::ProgressSpinner::VERSION, Perl $], $^X" );
