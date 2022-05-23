#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Moo;
plan tests => 1;

BEGIN {
    use_ok( 'MooX::Keyword' ) || print "Bail out!\n";
}

diag( "Testing MooX::Keyword $MooX::Keyword::VERSION, Perl $], $^X" );
