#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MooseX::Types::Time::Piece' ) || print "Bail out!\n";
}

diag( "Testing MooseX::Types::Time::Piece $MooseX::Types::Time::Piece::VERSION, Perl $], $^X" );
