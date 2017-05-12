#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RPi::LCD' ) || print "Bail out!\n";
}

diag( "Testing RPi::LCD $RPi::LCD::VERSION, Perl $], $^X" );
