#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Moo' ) || print "Bail out!\n";
    use_ok( 'MooX::ValidateSubs' ) || print "Bail out!\n";
}

diag( "Testing MooX::ValidateSubs $MooX::ValidateSubs::VERSION, Perl $], $^X" );
