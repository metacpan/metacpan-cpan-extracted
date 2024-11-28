use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Perlmazing' ) || print "Bail out!\n";
}

diag( "Testing Perlmazing $Perlmazing::VERSION, Perl $], $^X" );

