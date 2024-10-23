#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '1.04';

plan tests => 1;

BEGIN {
    use_ok( 'String::Random::Regexp::regxstring' ) || print "Bail out!\n";
}

diag( "Testing String::Random::Regexp::regxstring $String::Random::Regexp::regxstring::VERSION, Perl $], $^X" );
