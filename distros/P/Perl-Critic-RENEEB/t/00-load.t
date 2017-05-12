#!perl -T

use strict;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Perl::Critic::RENEEB' );
}


diag( "Testing Perl::Critic::RENEEB $Perl::Critic::RENEEB::VERSION, Perl $], $^X" );
