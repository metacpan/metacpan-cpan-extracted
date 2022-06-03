#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'MooX::Keyword::Field' ) || print "Bail out!\n";
}

diag( "Testing MooX::Keyword::Field $MooX::Keyword::Field::VERSION, Perl $], $^X" );
