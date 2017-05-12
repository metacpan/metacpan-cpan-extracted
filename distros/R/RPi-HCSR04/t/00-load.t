use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RPi::HCSR04' ) || print "Bail out!\n";
}

diag( "Testing RPi::HCSR04 $RPi::HCSR04::VERSION, Perl $], $^X" );
