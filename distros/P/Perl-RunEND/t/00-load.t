#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 2;

ok( $] >= 5.006, "perl version ok" );
use_ok( 'Perl::RunEND' );

#BEGIN {
#    use_ok( 'Perl::RunEND' ) || print "Bail out!\n";
#}

#diag( "Testing Perl::RunEND $Perl::RunEND::VERSION, Perl $], $^X" );
