#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Term::Colormap' ) || print "Bail out!\n";
}

diag( "Testing Term::Colormap $Term::Colormap::VERSION, Perl $], $^X" );
