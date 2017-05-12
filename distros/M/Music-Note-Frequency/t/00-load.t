#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Music::Note::Frequency' ) || print "Bail out!\n";
}

diag( "Testing Music::Note::Frequency $Music::Note::Frequency::VERSION, Perl $], $^X" );
