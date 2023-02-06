#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'MooX::Keyword::Chain' ) || print "Bail out!\n";
}

diag( "Testing MooX::Keyword::Chain $MooX::Keyword::Chain::VERSION, Perl $], $^X" );
