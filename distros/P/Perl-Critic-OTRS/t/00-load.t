#!perl -T

use strict;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Perl::Critic::OTRS' );
}


diag( "Testing Perl::Critic::OTRS $Perl::Critic::OTRS::VERSION, Perl $], $^X" );
