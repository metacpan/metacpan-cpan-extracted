#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'MooX::Keyword::Random' ) || print "Bail out!\n";
}

diag( "Testing MooX::Keyword::Random $MooX::Keyword::Random::VERSION, Perl $], $^X" );
