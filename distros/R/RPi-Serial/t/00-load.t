use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RPi::Serial' ) || print "Bail out!\n";
}

diag( "Testing RPi::Serial $RPi::Serial::VERSION, Perl $], $^X" );
