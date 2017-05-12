#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MooseX::Types::XMLSchema' );
}

diag( "Testing MooseX::Types::XMLSchema $MooseX::Types::XMLSchema::VERSION, Perl $], $^X" );
