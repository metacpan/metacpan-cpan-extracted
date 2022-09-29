#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    require_ok( 'Subs::Trace' ) || print "Bail out!\n";
}

diag( "Testing Subs::Trace $Subs::Trace::VERSION, Perl $], $^X" );
