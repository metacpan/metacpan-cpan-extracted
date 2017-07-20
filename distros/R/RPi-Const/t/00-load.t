#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RPi::Const' ) || print "Bail out!\n";
}

diag( "Testing RPi::Const $RPi::Const::VERSION, Perl $], $^X" );
