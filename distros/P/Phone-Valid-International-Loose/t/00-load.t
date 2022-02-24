#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Phone::Valid::International::Loose' ) || print "Bail out!\n";
}

diag( "Testing Phone::Valid::International::Loose $Phone::Valid::International::Loose::VERSION, Perl $], $^X" );
